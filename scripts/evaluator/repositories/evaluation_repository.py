#!/usr/bin/env python3
"""
Enhanced Evaluation Repository for normalized schema with reasoning
Handles the new structure: Evaluation + ExecutionMetadata + Analysis with reasoning
"""

import re
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from sqlalchemy import func
from sqlalchemy.orm import Session

from repositories.base_repository import BaseRepository
from database.tables import (
    SQLFile, Quest, Evaluation, ExecutionMetadata, Analysis, 
    Recommendation, SQLPattern
)
from config import EvaluationConfig

class EvaluationRepository(BaseRepository[Evaluation]):
    def __init__(self, session: Session):
        super().__init__(session, Evaluation)
        self.config = EvaluationConfig()
    
    def upsert_evaluation(self, evaluation_data: Dict[str, Any], execution_metadata: Optional[Dict[str, Any]] = None) -> Optional[Evaluation]:
        """
        UPSERT: Insert or update evaluation with normalized structure
        Handles: Evaluation + ExecutionMetadata + Analysis + Recommendations
        """
        try:
            sql_file_path = evaluation_data.get('file_path')
            if not sql_file_path:
                print(f"❌ No file_path in evaluation data")
                return None
            
            # Get SQL file
            sql_file = self.session.query(SQLFile).filter(
                SQLFile.file_path == sql_file_path
            ).first()
            
            if not sql_file:
                print(f"❌ SQL file not found: {sql_file_path}")
                return None
            
            # Extract data from evaluation structure
            assessment = evaluation_data.get('llm_analysis', {}).get('assessment', {})
            analysis_data = evaluation_data.get('llm_analysis', {}).get('analysis', {})
            execution = evaluation_data.get('execution', {})
            recommendations = evaluation_data.get('llm_analysis', {}).get('recommendations', [])
            
            # UPSERT main evaluation record
            evaluation = self.session.query(Evaluation).filter(
                Evaluation.sql_file_id == sql_file.id
            ).first()
            
            # Convert pattern detections to JSONB format
            detected_patterns = []
            pattern_data = analysis_data.get('detected_patterns', [])
            
            if pattern_data:
                if isinstance(pattern_data, list):
                    detected_patterns = pattern_data
                else:
                    detected_patterns = [str(pattern_data)]
            
            if evaluation:
                # Update existing evaluation
                evaluation.overall_assessment = assessment.get('overall_assessment', 'NEEDS_REVIEW')
                evaluation.letter_grade = assessment.get('grade', 'C')
                evaluation.numeric_score = self._safe_float(assessment.get('score', 5))
                evaluation.detected_patterns = detected_patterns
                evaluation.last_evaluated = datetime.now()
            else:
                # Create new evaluation
                evaluation = Evaluation(
                    sql_file_id=sql_file.id,
                    quest_id=sql_file.subcategory.quest_id,
                    overall_assessment=assessment.get('overall_assessment', 'NEEDS_REVIEW'),
                    letter_grade=assessment.get('grade', 'C'),
                    numeric_score=self._safe_float(assessment.get('score', 5)),
                    detected_patterns=detected_patterns,
                    evaluator_model=self.config.model_name,
                    last_evaluated=datetime.now()
                )
                self.session.add(evaluation)
            
            self.session.flush()  # Get evaluation ID
            
            # UPSERT execution metadata
            exec_metadata = self.session.query(ExecutionMetadata).filter(
                ExecutionMetadata.evaluation_id == evaluation.id
            ).first()
            
            # Use provided execution_metadata or extract from evaluation_data
            exec_data = execution_metadata or execution
            
            if exec_metadata:
                # Update existing execution metadata
                exec_metadata.execution_success = exec_data.get('execution_success', True)
                exec_metadata.execution_time_ms = exec_data.get('execution_time_ms')
                exec_metadata.output_lines = exec_data.get('output_lines', 0)
                exec_metadata.result_sets = exec_data.get('result_sets', 0)
                exec_metadata.error_count = exec_data.get('error_count', 0)
                exec_metadata.warning_count = exec_data.get('warning_count', 0)
                exec_metadata.execution_output = exec_data.get('execution_output', '')
                exec_metadata.updated_at = datetime.now()
            else:
                # Create new execution metadata
                exec_metadata = ExecutionMetadata(
                    evaluation_id=evaluation.id,
                    execution_success=exec_data.get('execution_success', True),
                    execution_time_ms=exec_data.get('execution_time_ms'),
                    output_lines=exec_data.get('output_lines', 0),
                    result_sets=exec_data.get('result_sets', 0),
                    error_count=exec_data.get('error_count', 0),
                    warning_count=exec_data.get('warning_count', 0),
                    execution_output=exec_data.get('execution_output', '')
                )
                self.session.add(exec_metadata)
            
            # UPSERT analysis with reasoning
            analysis = self.session.query(Analysis).filter(
                Analysis.evaluation_id == evaluation.id
            ).first()
            
            # Extract reasoning data
            technical_reasoning = analysis_data.get('technical_reasoning', {})
            educational_reasoning = analysis_data.get('educational_reasoning', {})
            
            # Extract time estimate and convert to minutes
            time_estimate = analysis_data.get('time_estimate', '10 min')
            estimated_minutes = self._parse_time_estimate(time_estimate)
            
            if analysis:
                # Update existing analysis
                analysis.overall_feedback = analysis_data.get('overall_feedback', 'Analysis completed')
                analysis.difficulty_level = analysis_data.get('difficulty_level', 'Intermediate')
                analysis.estimated_time_minutes = estimated_minutes
                analysis.technical_score = self._safe_float(technical_reasoning.get('score', 5))
                analysis.technical_reasoning = technical_reasoning.get('explanation', 'No technical analysis provided')
                analysis.educational_score = self._safe_float(educational_reasoning.get('score', 5))
                analysis.educational_reasoning = educational_reasoning.get('explanation', 'No educational analysis provided')
                analysis.updated_at = datetime.now()
            else:
                # Create new analysis
                analysis = Analysis(
                    evaluation_id=evaluation.id,
                    overall_feedback=analysis_data.get('overall_feedback', 'Analysis completed'),
                    difficulty_level=analysis_data.get('difficulty_level', 'Intermediate'),
                    estimated_time_minutes=estimated_minutes,
                    technical_score=self._safe_float(technical_reasoning.get('score', 5)),
                    technical_reasoning=technical_reasoning.get('explanation', 'No technical analysis provided'),
                    educational_score=self._safe_float(educational_reasoning.get('score', 5)),
                    educational_reasoning=educational_reasoning.get('explanation', 'No educational analysis provided')
                )
                self.session.add(analysis)
            
            # Handle recommendations (replace all)
            # Delete existing recommendations
            self.session.query(Recommendation).filter(
                Recommendation.evaluation_id == evaluation.id
            ).delete()
            
            # Add new recommendations
            for rec_data in recommendations:
                if isinstance(rec_data, dict):
                    rec_text = rec_data.get('recommendation_text', str(rec_data))
                    priority = rec_data.get('priority', 'Medium')
                    effort = rec_data.get('implementation_effort', 'Medium')
                elif isinstance(rec_data, str):
                    rec_text = rec_data
                    priority = 'Medium'
                    effort = 'Medium'
                else:
                    rec_text = str(rec_data)
                    priority = 'Medium'
                    effort = 'Medium'
                
                if rec_text and rec_text.strip():
                    recommendation = Recommendation(
                        evaluation_id=evaluation.id,
                        recommendation_text=rec_text,
                        priority=self._normalize_priority(priority),
                        implementation_effort=self._normalize_effort(effort),
                        category=self._categorize_recommendation(rec_text)
                    )
                    self.session.add(recommendation)
            
            self.session.commit()
            return evaluation
            
        except Exception as e:
            self.session.rollback()
            print(f"❌ Error upserting evaluation: {e}")
            raise
    
    def _safe_float(self, value: Any) -> float:
        """Safely convert value to float with default"""
        try:
            if isinstance(value, (int, float)):
                return float(value)
            elif isinstance(value, str):
                # Try to extract number from string
                number_match = re.search(r'(\d+\.?\d*)', value)
                if number_match:
                    return float(number_match.group(1))
            return 5.0  # Default score
        except:
            return 5.0
    
    def _parse_time_estimate(self, time_str: str) -> int:
        """Parse time estimate string to minutes"""
        try:
            # Extract numbers from time string
            numbers = re.findall(r'\d+', str(time_str))
            if numbers:
                return int(numbers[0])  # Take first number found
            return 10  # Default fallback
        except:
            return 10
    
    def _normalize_priority(self, priority: str) -> str:
        """Normalize priority to valid constraint values"""
        priority_lower = priority.lower() if priority else 'medium'
        
        if priority_lower in ['low', 'minor']:
            return 'Low'
        elif priority_lower in ['high', 'critical', 'important']:
            return 'High'
        else:
            return 'Medium'
    
    def _normalize_effort(self, effort: str) -> str:
        """Normalize implementation effort to valid constraint values"""
        effort_lower = effort.lower() if effort else 'medium'
        
        if effort_lower in ['low', 'easy', 'simple']:
            return 'Low'
        elif effort_lower in ['high', 'hard', 'difficult', 'complex']:
            return 'High'
        else:
            return 'Medium'
    
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
    
    def get_evaluation_with_details(self, sql_file_path: str) -> Optional[Dict[str, Any]]:
        """Get complete evaluation details for a SQL file"""
        
        sql_file = self.session.query(SQLFile).filter(
            SQLFile.file_path == sql_file_path
        ).first()
        
        if not sql_file:
            return None
            
        evaluation = self.session.query(Evaluation).filter(
            Evaluation.sql_file_id == sql_file.id
        ).first()
        
        if not evaluation:
            return None
        
        # Get related data
        exec_metadata = self.session.query(ExecutionMetadata).filter(
            ExecutionMetadata.evaluation_id == evaluation.id
        ).first()
        
        analysis = self.session.query(Analysis).filter(
            Analysis.evaluation_id == evaluation.id
        ).first()
        
        recommendations = self.session.query(Recommendation).filter(
            Recommendation.evaluation_id == evaluation.id
        ).all()
        
        return {
            'evaluation': evaluation,
            'execution_metadata': exec_metadata,
            'analysis': analysis,
            'recommendations': recommendations,
            'sql_file': sql_file
        }
    
    def get_quest_summary_statistics(self, quest_id: int) -> Dict[str, Any]:
        """Get summary statistics for a quest"""
        
        query = self.session.query(
            func.count(Evaluation.id).label('total_evaluations'),
            func.avg(Evaluation.numeric_score).label('avg_score'),
            func.count(Evaluation.id).filter(Evaluation.overall_assessment == 'PASS').label('pass_count'),
            func.count(Evaluation.id).filter(Evaluation.overall_assessment == 'FAIL').label('fail_count'),
            func.count(Evaluation.id).filter(Evaluation.overall_assessment == 'NEEDS_REVIEW').label('review_count')
        ).filter(Evaluation.quest_id == quest_id)
        
        result = query.first()
        
        # Get technical and educational score averages
        tech_edu_query = self.session.query(
            func.avg(Analysis.technical_score).label('avg_technical'),
            func.avg(Analysis.educational_score).label('avg_educational')
        ).join(Evaluation).filter(Evaluation.quest_id == quest_id)
        
        tech_edu_result = tech_edu_query.first()
        
        return {
            'total_evaluations': result.total_evaluations or 0,
            'average_score': float(result.avg_score or 0),
            'pass_count': result.pass_count or 0,
            'fail_count': result.fail_count or 0,
            'review_count': result.review_count or 0,
            'average_technical_score': float(tech_edu_result.avg_technical or 0),
            'average_educational_score': float(tech_edu_result.avg_educational or 0)
        }
    
    def get_recent_evaluations(self, limit: int = 10) -> List[Dict[str, Any]]:
        """Get recent evaluations with summary info"""
        
        evaluations = self.session.query(Evaluation).join(SQLFile).order_by(Evaluation.last_evaluated.desc()).limit(limit).all()
        
        results = []
        for evaluation in evaluations:
            analysis = self.session.query(Analysis).filter(
                Analysis.evaluation_id == evaluation.id
            ).first()

            results.append({
                'file_path': evaluation.sql_file.file_path,
                'filename': evaluation.sql_file.filename,
                'quest_name': evaluation.quest.name,
                'overall_assessment': evaluation.overall_assessment,
                'letter_grade': evaluation.letter_grade,
                'numeric_score': evaluation.numeric_score,
                'technical_score': analysis.technical_score if analysis else None,
                'educational_score': analysis.educational_score if analysis else None,
                'last_evaluated': evaluation.last_evaluated
            })
        
        return results

    # Legacy compatibility methods
    def add_from_data(self, sql_file_id: int, evaluation_data: dict) -> Evaluation:
        """Legacy method for compatibility - delegates to upsert_evaluation"""
        return self.upsert_evaluation(evaluation_data)
    
    def get_current_evaluation(self, file_path: str) -> Optional[Dict[str, Any]]:
        """Get current evaluation state for a file (legacy compatibility)"""
        return self.get_evaluation_with_details(file_path)
    
    def add_from_data(self, sql_file_id: int, evaluation_data: dict) -> Evaluation:
        """
        Legacy method for compatibility - delegates to upsert_evaluation
        
        Args:
            sql_file_id: ID of the SQL file being evaluated (not used, path extracted from data)
            evaluation_data: Dictionary containing evaluation results
            
        Returns:
            Created/Updated Evaluation entity
        """
        return self.upsert_evaluation(evaluation_data)
    
    def get_current_evaluation(self, file_path: str) -> Optional[Dict[str, Any]]:
        """Get current evaluation state for a file"""
        try:
            sql_file = self.session.query(SQLFile).filter(
                SQLFile.file_path == file_path
            ).first()
            
            if not sql_file:
                return None
            
            evaluation = self.session.query(Evaluation).filter(
                Evaluation.sql_file_id == sql_file.id
            ).first()
            
            if not evaluation:
                return None
            
            # Get related data
            recommendations = self.session.query(Recommendation).filter(
                Recommendation.evaluation_id == evaluation.id
            ).all()
            
            return {
                'evaluation': evaluation,
                'recommendations': recommendations,
                'file': sql_file,
                'quest': evaluation.quest
            }
            
        except Exception as e:
            print(f"❌ Error getting current evaluation: {e}")
            return None
    
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
    
    def _normalize_effort(self, effort: str) -> str:
        """Normalize implementation effort to valid constraint values"""
        effort_lower = effort.lower() if effort else 'medium'
        
        if effort_lower in ['low', 'easy', 'simple']:
            return 'Low'
        elif effort_lower in ['high', 'hard', 'difficult', 'complex']:
            return 'High'
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