from .base_repository import BaseRepository
from tables import Evaluation, ExecutionDetail, EvaluationPattern, Recommendation

from config import EvaluationConfig

class EvaluationRepository(BaseRepository[Evaluation]):
    def __init__(self, session):
        super().__init__(session, Evaluation)

    def add_from_data(self, sql_file_id: int, evaluation_data: dict):
        try:
            # Create main evaluation record
            evaluation = Evaluation(
                sql_file_id=sql_file.id,
                quest_id=sql_file.subcategory.quest_id,
                evaluator_model=evaluation_data.get('evaluator_model', EvaluationConfig().model_name),
                overall_assessment=evaluation_data.get('llm_analysis', {}).get('assessment', {}).get('overall_assessment', 'UNKNOWN'),
                numeric_score=evaluation_data.get('llm_analysis', {}).get('assessment', {}).get('score', 1),
                letter_grade=evaluation_data.get('llm_analysis', {}).get('assessment', {}).get('grade', 'F'),
                execution_success=evaluation_data.get('execution', {}).get('success', False),
                execution_time_ms=evaluation_data.get('execution', {}).get('execution_time_ms', 0),
                output_lines=evaluation_data.get('execution', {}).get('output_lines', 0),
                result_sets=evaluation_data.get('execution', {}).get('result_sets', 0),
                rows_affected=evaluation_data.get('execution', {}).get('rows_affected', 0),
                error_count=evaluation_data.get('execution', {}).get('error_count', 0),
                warning_count=evaluation_data.get('execution', {}).get('warning_count', 0)
            )
            self.session.add(evaluation)
            self.session.flush()

            # Save technical analysis
            tech_analysis = evaluation_data.get('llm_analysis', {}).get('technical_analysis', {})
            if tech_analysis:
                technical = TechnicalAnalysis(
                    evaluation_id=evaluation.id,
                    syntax_correctness=tech_analysis.get('syntax_correctness', ''),
                    logical_structure=tech_analysis.get('logical_structure', ''),
                    code_quality=tech_analysis.get('code_quality', ''),
                    performance_notes=tech_analysis.get('performance_notes', ''),
                    syntax_score=self._extract_score_from_text(tech_analysis.get('syntax_correctness', '')),
                    logic_score=self._extract_score_from_text(tech_analysis.get('logical_structure', '')),
                    quality_score=self._extract_score_from_text(tech_analysis.get('code_quality', '')),
                    performance_score=self._extract_score_from_text(tech_analysis.get('performance_notes', ''))
                )
                session.add(technical)
                
            # Save educational analysis
            edu_analysis = evaluation_data.get('llm_analysis', {}).get('educational_analysis', {})
            if edu_analysis:
                educational = EducationalAnalysis(
                    evaluation_id=evaluation.id,
                    learning_value=edu_analysis.get('learning_value', ''),
                    difficulty_level=edu_analysis.get('difficulty_level', 'Beginner'),
                    estimated_time_minutes=self._extract_time_from_text(edu_analysis.get('time_estimate', '')),
                    prerequisite_knowledge=str(edu_analysis.get('prerequisites', [])),
                    learning_objectives=evaluation_data.get('enhanced_intent', {}).get('detailed_purpose', ''),
                    real_world_applicability=evaluation_data.get('enhanced_intent', {}).get('real_world_applicability', ''),
                    clarity_score=self._extract_score_from_text(edu_analysis.get('learning_value', ''))
                )
                session.add(educational)
            
            # Save execution details
            stmt_results = evaluation_data.get('execution', {}).get('statement_results', [])
            for stmt_data in stmt_results:
                execution_detail = ExecutionDetail(
                    evaluation_id=evaluation.id,
                    statement_order=stmt_data.get('order', 0),
                    sql_statement=stmt_data.get('statement', ''),
                    execution_success=stmt_data.get('success', False),
                    execution_time_ms=stmt_data.get('execution_time_ms', 0),
                    rows_affected=stmt_data.get('rows_affected', 0),
                    rows_returned=stmt_data.get('rows_returned', 0),
                    error_message=stmt_data.get('error_message'),
                    warning_message=stmt_data.get('warning_message')
                )
                session.add(execution_detail)
            
            # Save pattern evaluations
            detected_patterns = evaluation_data.get('intent', {}).get('sql_patterns', [])
            for pattern_name in detected_patterns:
                pattern = session.query(SQLPattern).filter(SQLPattern.name == pattern_name).first()
                if pattern:
                    eval_pattern = EvaluationPattern(
                        evaluation_id=evaluation.id,
                        pattern_id=pattern.id,
                        confidence_score=0.8,  # Default confidence
                        usage_quality='Good'   # Default quality assessment
                    )
                    session.add(eval_pattern)
            
            # Save recommendations
            recommendations = evaluation_data.get('llm_analysis', {}).get('recommendations', [])
            for rec_text in recommendations:
                recommendation = Recommendation(
                    evaluation_id=evaluation.id,
                    category=self._categorize_recommendation(rec_text),
                    priority='Medium',  # Default priority
                    recommendation_text=rec_text,
                    implementation_effort='Medium',
                    expected_impact='Medium'
                )
                session.add(recommendation)
            
            self.session.commit()
            print(f"✅ Enhanced evaluation saved: {sql_file.filename}")
            self.session.close()
            return evaluation
        except Exception as e:
            self.session.rollback()
            print(f"❌ Error saving enhanced evaluation: {e}")
            self.session.close()
            return None
        
    
    def get_evaluation_analytics(self, quest_name: Optional[str] = None, 
                               days: int = 30) -> Dict[str, Any]:
        """Get comprehensive evaluation analytics"""        
        try:            
            # Base query
            query = self.session.query(Evaluation)
            if quest_name:
                quest = self.session.query(Quest).filter(Quest.name == quest_name).first()
                if quest:
                    query = query.filter(Evaluation.quest_id == quest.id)
            
            # Date filter
            cutoff_date = datetime.now() - timedelta(days=days)
            query = query.filter(Evaluation.evaluation_date >= cutoff_date)
            
            evaluations = query.all()
            
            if not evaluations:
                return {'message': 'No evaluations found for the specified criteria'}
            
            # Calculate analytics
            total_evaluations = len(evaluations)
            successful_evals = len([e for e in evaluations if e.execution_success])
            avg_score = sum(e.numeric_score for e in evaluations) / total_evaluations
            
            # Score distribution
            score_distribution = {}
            for evaluation in evaluations:
                grade = evaluation.letter_grade
                score_distribution[grade] = score_distribution.get(grade, 0) + 1
            
            # Quest performance
            quest_performance = {}
            for evaluation in evaluations:
                quest_name = evaluation.quest.name
                if quest_name not in quest_performance:
                    quest_performance[quest_name] = {
                        'total': 0,
                        'successful': 0,
                        'avg_score': 0,
                        'scores': []
                    }
                quest_performance[quest_name]['total'] += 1
                quest_performance[quest_name]['scores'].append(eval.numeric_score)
                if evaluation.execution_success:
                    quest_performance[quest_name]['successful'] += 1
            
            # Calculate averages
            for quest_data in quest_performance.values():
                quest_data['avg_score'] = sum(quest_data['scores']) / len(quest_data['scores'])
                quest_data['success_rate'] = quest_data['successful'] / quest_data['total'] * 100
                del quest_data['scores']  # Remove raw scores
            
            # Pattern analysis
            pattern_usage = self.session.query(
                SQLPattern.name,
                SQLPattern.display_name,
                func.count(EvaluationPattern.id).label('usage_count'),
                func.avg(EvaluationPattern.confidence_score).label('avg_confidence')
            ).join(EvaluationPattern).join(Evaluation).filter(
                Evaluation.evaluation_date >= cutoff_date
            ).group_by(SQLPattern.id, SQLPattern.name, SQLPattern.display_name).all()
            
            self.session.close()
            
            return {
                'summary': {
                    'total_evaluations': total_evaluations,
                    'successful_evaluations': successful_evals,
                    'success_rate': round(successful_evals / total_evaluations * 100, 2),
                    'average_score': round(avg_score, 2),
                    'period_days': days
                },
                'score_distribution': score_distribution,
                'quest_performance': quest_performance,
                'pattern_usage': [
                    {
                        'pattern': row.name,
                        'display_name': row.display_name,
                        'usage_count': row.usage_count,
                        'avg_confidence': round(float(row.avg_confidence), 2)
                    }
                    for row in pattern_usage
                ]
            }
            
        except Exception as e:
            print(f"❌ Error generating analytics: {e}")
            return {'error': str(e)}
    
    def get_file_evaluation_history(self, file_path: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Get evaluation history for a specific file"""
        try:          
            sql_file = self.session.query(SQLFile).filter(SQLFile.file_path == file_path).first()
            if not sql_file:
                return []
            
            evaluations = self.session.query(Evaluation).filter(
                Evaluation.sql_file_id == sql_file.id
            ).order_by(Evaluation.evaluation_date.desc()).limit(limit).all()
            
            results = []
            for eval in evaluations:
                results.append({
                    'evaluation_id': eval.id,
                    'evaluation_uuid': str(eval.evaluation_uuid),
                    'evaluation_date': eval.evaluation_date.isoformat(),
                    'overall_assessment': eval.overall_assessment,
                    'numeric_score': eval.numeric_score,
                    'letter_grade': eval.letter_grade,
                    'execution_success': eval.execution_success,
                    'execution_time_ms': eval.execution_time_ms,
                    'evaluator_model': eval.evaluator_model
                })
            
            self.session.close()
            return results
            
        except Exception as e:
            print(f"❌ Error retrieving file evaluation history: {e}")
            return []