from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from sqlalchemy import func

from repositories.base_repository import BaseRepository
from database.tables import (
    SQLFile,
    Quest,
    Evaluation, 
    Recommendation,
    Analysis,  # Simplified combined analysis table
    SQLPattern,
    EvaluationPattern  # Junction table for evaluation-pattern relationships
)

from config import EvaluationConfig

class EvaluationRepository(BaseRepository[Evaluation]):
    def __init__(self, session):
        super().__init__(session, Evaluation)
    
    def _extract_score_from_text(self, text: str) -> float:
        """Extract a numeric score from text, returning a default if not found"""
        if not text:
            return 5.0
        
        # Look for patterns like "score: 8", "8/10", "grade: B" etc.
        import re
        
        # Try to find direct numbers
        number_match = re.search(r'(\d+\.?\d*)', text)
        if number_match:
            score = float(number_match.group(1))
            # Normalize to 0-10 scale if needed
            if score > 10:
                score = score / 10
            return min(10.0, max(0.0, score))
        
        # Convert qualitative assessments to scores
        text_lower = text.lower()
        if any(word in text_lower for word in ['excellent', 'perfect', 'outstanding']):
            return 9.0
        elif any(word in text_lower for word in ['good', 'correct', 'high']):
            return 7.0
        elif any(word in text_lower for word in ['fair', 'adequate', 'medium']):
            return 6.0
        elif any(word in text_lower for word in ['poor', 'low', 'incorrect']):
            return 4.0
        elif any(word in text_lower for word in ['failed', 'error', 'wrong']):
            return 2.0
        
        return 5.0  # Default neutral score

    def _extract_time_from_text(self, text: str) -> int:
        """Extract time estimate in minutes from text"""
        if not text:
            return 10  # Default 10 minutes
        
        import re
        
        # Look for patterns like "5-10 min", "15 minutes", "1 hour"
        time_match = re.search(r'(\d+)[-\s]*(\d+)?\s*(min|minute|hour)', text.lower())
        if time_match:
            time_val = int(time_match.group(1))
            if 'hour' in time_match.group(3):
                time_val *= 60  # Convert hours to minutes
            return time_val
        
        # Look for just numbers with context
        number_match = re.search(r'(\d+)', text)
        if number_match:
            return int(number_match.group(1))
        
        return 10  # Default fallback

    def add_from_data(self, sql_file_id: int, evaluation_data: dict) -> Evaluation:
        """
        Add evaluation data to the database.
        
        Note: This method does not commit the session. The caller is responsible
        for committing or rolling back the transaction.
        
        Args:
            sql_file_id: ID of the SQL file being evaluated
            evaluation_data: Dictionary containing evaluation results
            
        Returns:
            Created Evaluation entity
            
        Raises:
            Exception: If database operation fails (session will be rolled back by caller)
        """
        try:
            # Retrieve sql_file from database
            sql_file: SQLFile = self.session.query(SQLFile).filter(SQLFile.id == sql_file_id).first()
            if not sql_file:
                raise ValueError(f"SQL file with ID {sql_file_id} not found")
                
            # Create main evaluation record
            # Create or update evaluation (UPSERT logic)
            evaluation = self.session.query(Evaluation).filter(Evaluation.sql_file_id == sql_file_id).first()
            
            if not evaluation:
                evaluation = Evaluation(
                    sql_file_id=sql_file_id,
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
            else:
                # Update existing evaluation
                evaluation.last_evaluated = datetime.now()
                evaluation.overall_assessment = evaluation_data.get('llm_analysis', {}).get('assessment', {}).get('overall_assessment', 'UNKNOWN')
                evaluation.numeric_score = evaluation_data.get('llm_analysis', {}).get('assessment', {}).get('score', 1)
                evaluation.letter_grade = evaluation_data.get('llm_analysis', {}).get('assessment', {}).get('grade', 'F')
                evaluation.execution_success = evaluation_data.get('execution', {}).get('success', False)
                evaluation.execution_time_ms = evaluation_data.get('execution', {}).get('execution_time_ms', 0)
                evaluation.output_lines = evaluation_data.get('execution', {}).get('output_lines', 0)
                evaluation.result_sets = evaluation_data.get('execution', {}).get('result_sets', 0)
                evaluation.rows_affected = evaluation_data.get('execution', {}).get('rows_affected', 0)
                evaluation.error_count = evaluation_data.get('execution', {}).get('error_count', 0)
                evaluation.warning_count = evaluation_data.get('execution', {}).get('warning_count', 0)
                
            self.session.flush()  # Get the ID without committing

            # Create or update simplified analysis
            analysis = self.session.query(Analysis).filter(Analysis.evaluation_id == evaluation.id).first()
            
            # Extract simplified analysis data
            llm_analysis = evaluation_data.get('llm_analysis', {})
            simplified_analysis = llm_analysis.get('analysis', {}) if 'analysis' in llm_analysis else {}
            
            # Build combined feedback from LLM analysis
            combined_feedback = simplified_analysis.get('overall_feedback', '')
            if not combined_feedback:
                # Fallback: combine separate technical/educational if they exist
                tech_analysis = llm_analysis.get('technical_analysis', {})
                edu_analysis = llm_analysis.get('educational_analysis', {})
                combined_feedback = f"Technical: {tech_analysis.get('code_quality', 'Good')}. Educational: {edu_analysis.get('learning_value', 'High value')}."
            
            if not analysis:
                analysis = Analysis(
                    evaluation_id=evaluation.id,
                    overall_feedback=combined_feedback,
                    difficulty_level=simplified_analysis.get('difficulty_level', 'Beginner'),
                    estimated_time_minutes=self._extract_time_from_text(simplified_analysis.get('time_estimate', '10 min')),
                    technical_score=simplified_analysis.get('technical_score', evaluation_data.get('llm_analysis', {}).get('assessment', {}).get('score', 7)),
                    educational_score=simplified_analysis.get('educational_score', evaluation_data.get('llm_analysis', {}).get('assessment', {}).get('score', 7))
                )
                self.session.add(analysis)
            else:
                # Update existing analysis
                analysis.overall_feedback = combined_feedback
                analysis.difficulty_level = simplified_analysis.get('difficulty_level', 'Beginner')
                analysis.estimated_time_minutes = self._extract_time_from_text(simplified_analysis.get('time_estimate', '10 min'))
                analysis.technical_score = simplified_analysis.get('technical_score', evaluation_data.get('llm_analysis', {}).get('assessment', {}).get('score', 7))
                analysis.educational_score = simplified_analysis.get('educational_score', evaluation_data.get('llm_analysis', {}).get('assessment', {}).get('score', 7))
                analysis.updated_at = datetime.now()
            
            self.session.flush()  # Get analysis ID
            
            # Handle detected patterns - create evaluation_pattern relationships
            detected_patterns = simplified_analysis.get('detected_patterns', [])
            if detected_patterns:
                # Remove existing pattern relationships for this evaluation
                self.session.query(EvaluationPattern).filter(
                    EvaluationPattern.evaluation_id == evaluation.id
                ).delete()
                
                # Add new pattern relationships
                for pattern_name in detected_patterns:
                    # Find pattern by name
                    pattern = self.session.query(SQLPattern).filter(
                        SQLPattern.name == pattern_name
                    ).first()
                    
                    if pattern:
                        eval_pattern = EvaluationPattern(
                            evaluation_id=evaluation.id,
                            pattern_id=pattern.id,
                            confidence_score=0.9,  # High confidence from LLM
                            usage_quality='Good'
                        )
                        self.session.add(eval_pattern)
                analysis.updated_at = datetime.now()
                
            # Clear existing recommendations and save new ones
            self.session.query(Recommendation).filter(Recommendation.evaluation_id == evaluation.id).delete()
            
            # Save recommendations BEFORE returning
            recommendations = evaluation_data.get('llm_analysis', {}).get('recommendations', [])
            for rec_data in recommendations:
                if isinstance(rec_data, dict):
                    # Handle structured recommendation data
                    recommendation = Recommendation(
                        evaluation_id=evaluation.id,
                        category=self._categorize_recommendation(rec_data.get('recommendation_text', '')),
                        priority=rec_data.get('priority', 'Medium'),
                        recommendation_text=rec_data.get('recommendation_text', ''),
                        implementation_effort=self._normalize_effort(rec_data.get('implementation_effort', 'Medium')),
                        expected_impact=self._normalize_impact(rec_data.get('expected_impact', 'Medium'))
                    )
                else:
                    # Handle simple string recommendation
                    recommendation = Recommendation(
                        evaluation_id=evaluation.id,
                        category=self._categorize_recommendation(str(rec_data)),
                        priority='Medium',
                        recommendation_text=str(rec_data),
                        implementation_effort='Medium',
                        expected_impact='Medium'
                    )
                self.session.add(recommendation)
            
            return evaluation
            
        except Exception as e:
            # Log the error but don't rollback here - let the caller handle it
            print(f"❌ Error in add_from_data: {e}")
            raise
        
    
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
            
            # Simplified: No complex pattern analysis since patterns are stored as JSON
            # Could be added later by parsing the detected_patterns JSON field
            
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
                'pattern_usage': []  # Simplified: Empty for now
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
    
    def _categorize_recommendation(self, recommendation_text: str) -> str:
        """Categorize recommendation based on content keywords"""
        text = recommendation_text.lower()
        
        if any(word in text for word in ['performance', 'slow', 'optimize', 'efficient', 'index']):
            return 'Performance'
        elif any(word in text for word in ['syntax', 'error', 'correct', 'format']):
            return 'Syntax'
        elif any(word in text for word in ['practice', 'convention', 'standard', 'style']):
            return 'Best Practices'
        elif any(word in text for word in ['security', 'secure', 'safe', 'injection']):
            return 'Security'
        elif any(word in text for word in ['comment', 'document', 'explain', 'clarity']):
            return 'Documentation'
        else:
            return 'General'
    
    def _normalize_effort(self, effort: str) -> str:
        """Normalize implementation effort to valid constraint values"""
        effort_lower = effort.lower() if effort else 'medium'
        
        if effort_lower in ['low', 'easy', 'simple']:
            return 'Easy'
        elif effort_lower in ['high', 'hard', 'difficult', 'complex']:
            return 'Hard'
        else:
            return 'Medium'
    
    def _normalize_impact(self, impact: str) -> str:
        """Normalize expected impact to valid constraint values"""
        impact_lower = impact.lower() if impact else 'medium'
        
        if impact_lower in ['low', 'small', 'minor']:
            return 'Low'
        elif impact_lower in ['high', 'large', 'major', 'significant']:
            return 'High'
        else:
            return 'Medium'