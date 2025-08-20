#!/usr/bin/env python3
"""
Simplified Evaluation Repository with Upsert Logic
Works with the simplified schema design
"""

from typing import List, Dict, Any, Optional
from datetime import datetime
from sqlalchemy import func
from sqlalchemy.orm import Session

# This will work after migration
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from database.tables import (
    SQLFile, Quest, Evaluation, Analysis, Recommendation, SQLPattern
)
from config import EvaluationConfig

class SimplifiedEvaluationRepository:
    def __init__(self, session: Session):
        self.session = session
        self.config = EvaluationConfig()
    
    def upsert_evaluation(self, evaluation_data: Dict[str, Any]) -> Optional[Evaluation]:
        """
        UPSERT: Insert or update evaluation for a SQL file
        Only keeps current state, no history
        """
        try:
            sql_file_path = evaluation_data.get('file_path')
            if not sql_file_path:
                raise ValueError("file_path is required")
            
            # Get SQL file
            sql_file = self.session.query(SQLFile).filter(
                SQLFile.file_path == sql_file_path
            ).first()
            
            if not sql_file:
                raise ValueError(f"SQL file not found: {sql_file_path}")
            
            # UPSERT evaluation
            evaluation = self.session.query(Evaluation).filter(
                Evaluation.sql_file_id == sql_file.id
            ).first()
            
            # Extract assessment data
            assessment = evaluation_data.get('llm_analysis', {}).get('assessment', {})
            execution = evaluation_data.get('execution', {})
            
            if evaluation:
                # UPDATE existing evaluation
                evaluation.quest_id = sql_file.subcategory.quest_id
                evaluation.evaluator_model = evaluation_data.get('evaluator_model', self.config.model_name)
                evaluation.last_evaluated = datetime.now()
                evaluation.overall_assessment = assessment.get('overall_assessment', 'UNKNOWN')
                evaluation.numeric_score = assessment.get('score', 1)
                evaluation.letter_grade = assessment.get('grade', 'F')
                evaluation.execution_success = execution.get('success', False)
                evaluation.execution_time_ms = execution.get('execution_time_ms', 0)
                evaluation.output_lines = execution.get('output_lines', 0)
                evaluation.result_sets = execution.get('result_sets', 0)
                evaluation.rows_affected = execution.get('rows_affected', 0)
                evaluation.error_count = execution.get('error_count', 0)
                evaluation.warning_count = execution.get('warning_count', 0)
                evaluation.execution_output = execution.get('output', '')
                
                print(f"🔄 Updated evaluation for: {sql_file.filename}")
            else:
                # INSERT new evaluation
                evaluation = Evaluation(
                    sql_file_id=sql_file.id,
                    quest_id=sql_file.subcategory.quest_id,
                    evaluator_model=evaluation_data.get('evaluator_model', self.config.model_name),
                    overall_assessment=assessment.get('overall_assessment', 'UNKNOWN'),
                    numeric_score=assessment.get('score', 1),
                    letter_grade=assessment.get('grade', 'F'),
                    execution_success=execution.get('success', False),
                    execution_time_ms=execution.get('execution_time_ms', 0),
                    output_lines=execution.get('output_lines', 0),
                    result_sets=execution.get('result_sets', 0),
                    rows_affected=execution.get('rows_affected', 0),
                    error_count=execution.get('error_count', 0),
                    warning_count=execution.get('warning_count', 0),
                    execution_output=execution.get('output', '')
                )
                self.session.add(evaluation)
                print(f"✅ Created evaluation for: {sql_file.filename}")
            
            self.session.flush()  # Get evaluation ID
            
            # UPSERT combined analysis
            self._upsert_analysis(evaluation, evaluation_data)
            
            # UPSERT recommendations 
            self._upsert_recommendations(evaluation, evaluation_data)
            
            self.session.commit()
            return evaluation
            
        except Exception as e:
            self.session.rollback()
            print(f"❌ Error upserting evaluation: {e}")
            return None
    
    def _upsert_analysis(self, evaluation: Evaluation, evaluation_data: Dict[str, Any]):
        """Upsert combined technical + educational analysis"""
        
        # Get existing analysis or create new
        analysis = self.session.query(Analysis).filter(
            Analysis.evaluation_id == evaluation.id
        ).first()
        
        # Extract analysis data
        tech_analysis = evaluation_data.get('llm_analysis', {}).get('technical_analysis', {})
        edu_analysis = evaluation_data.get('llm_analysis', {}).get('educational_analysis', {})
        
        # Calculate combined scores
        technical_score = self._calculate_technical_score(tech_analysis)
        educational_score = self._calculate_educational_score(edu_analysis)
        
        # Extract detected patterns from intent
        detected_patterns = evaluation_data.get('intent', {}).get('sql_patterns', [])
        pattern_quality = self._assess_pattern_quality(detected_patterns, tech_analysis)
        
        if analysis:
            # UPDATE existing analysis
            analysis.syntax_correctness = tech_analysis.get('syntax_correctness', '')
            analysis.logical_structure = tech_analysis.get('logical_structure', '')
            analysis.code_quality = tech_analysis.get('code_quality', '')
            analysis.performance_notes = tech_analysis.get('performance_notes', '')
            analysis.best_practices_adherence = tech_analysis.get('best_practices_adherence', '')
            analysis.learning_value = edu_analysis.get('learning_value', '')
            analysis.difficulty_level = edu_analysis.get('difficulty_level', 'Beginner')
            analysis.estimated_time_minutes = self._extract_time_from_text(edu_analysis.get('time_estimate', ''))
            analysis.prerequisite_knowledge = str(edu_analysis.get('prerequisites', []))
            analysis.learning_objectives = evaluation_data.get('enhanced_intent', {}).get('detailed_purpose', '')
            analysis.real_world_applicability = evaluation_data.get('enhanced_intent', {}).get('real_world_applicability', '')
            analysis.technical_score = technical_score
            analysis.educational_score = educational_score
            analysis.detected_patterns = detected_patterns
            analysis.pattern_quality = pattern_quality
            analysis.updated_at = datetime.now()
        else:
            # INSERT new analysis
            analysis = Analysis(
                evaluation_id=evaluation.id,
                syntax_correctness=tech_analysis.get('syntax_correctness', ''),
                logical_structure=tech_analysis.get('logical_structure', ''),
                code_quality=tech_analysis.get('code_quality', ''),
                performance_notes=tech_analysis.get('performance_notes', ''),
                best_practices_adherence=tech_analysis.get('best_practices_adherence', ''),
                learning_value=edu_analysis.get('learning_value', ''),
                difficulty_level=edu_analysis.get('difficulty_level', 'Beginner'),
                estimated_time_minutes=self._extract_time_from_text(edu_analysis.get('time_estimate', '')),
                prerequisite_knowledge=str(edu_analysis.get('prerequisites', [])),
                learning_objectives=evaluation_data.get('enhanced_intent', {}).get('detailed_purpose', ''),
                real_world_applicability=evaluation_data.get('enhanced_intent', {}).get('real_world_applicability', ''),
                technical_score=technical_score,
                educational_score=educational_score,
                detected_patterns=detected_patterns,
                pattern_quality=pattern_quality
            )
            self.session.add(analysis)
    
    def _upsert_recommendations(self, evaluation: Evaluation, evaluation_data: Dict[str, Any]):
        """Upsert recommendations (clear and recreate for simplicity)"""
        
        # Clear existing recommendations
        self.session.query(Recommendation).filter(
            Recommendation.evaluation_id == evaluation.id
        ).delete()
        
        # Add new recommendations
        recommendations = evaluation_data.get('llm_analysis', {}).get('recommendations', [])
        for rec_text in recommendations:
            if rec_text and rec_text.strip():  # Skip empty recommendations
                recommendation = Recommendation(
                    evaluation_id=evaluation.id,
                    category=self._categorize_recommendation(rec_text),
                    priority='Medium',  # Default priority - could be enhanced with AI analysis
                    recommendation_text=rec_text.strip(),
                    implementation_effort='Medium',
                    expected_impact='Medium'
                )
                self.session.add(recommendation)
    
    def _calculate_technical_score(self, tech_analysis: Dict[str, Any]) -> int:
        """Calculate combined technical score from analysis"""
        scores = []
        for field in ['syntax_correctness', 'logical_structure', 'code_quality', 'performance_notes']:
            score = self._extract_score_from_text(tech_analysis.get(field, ''))
            scores.append(score)
        return int(sum(scores) / len(scores)) if scores else 5
    
    def _calculate_educational_score(self, edu_analysis: Dict[str, Any]) -> int:
        """Calculate combined educational score from analysis"""
        scores = []
        for field in ['learning_value']:
            score = self._extract_score_from_text(edu_analysis.get(field, ''))
            scores.append(score)
        return int(sum(scores) / len(scores)) if scores else 5
    
    def _assess_pattern_quality(self, patterns: List[str], tech_analysis: Dict[str, Any]) -> str:
        """Assess overall quality of pattern usage"""
        if not patterns:
            return 'None'
        
        # Simple heuristic based on technical analysis
        overall_quality = tech_analysis.get('code_quality', '').lower()
        if 'excellent' in overall_quality or 'outstanding' in overall_quality:
            return 'Excellent'
        elif 'good' in overall_quality or 'correct' in overall_quality:
            return 'Good'
        elif 'fair' in overall_quality or 'adequate' in overall_quality:
            return 'Fair'
        else:
            return 'Poor'
    
    def _extract_score_from_text(self, text: str) -> float:
        """Extract numeric score from text analysis"""
        if not text:
            return 5.0
        
        import re
        number_match = re.search(r'(\d+\.?\d*)', text)
        if number_match:
            score = float(number_match.group(1))
            if score > 10:
                score = score / 10
            return min(10.0, max(0.0, score))
        
        # Qualitative assessment mapping
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
        
        return 5.0
    
    def _extract_time_from_text(self, text: str) -> int:
        """Extract time estimate in minutes"""
        if not text:
            return 10
        
        import re
        time_match = re.search(r'(\d+)\s*(?:min|minute)', text.lower())
        if time_match:
            return int(time_match.group(1))
        
        return 10  # Default
    
    def _categorize_recommendation(self, text: str) -> str:
        """Categorize recommendation based on content"""
        text_lower = text.lower()
        if any(word in text_lower for word in ['performance', 'speed', 'optimization', 'index']):
            return 'Performance'
        elif any(word in text_lower for word in ['syntax', 'grammar', 'format']):
            return 'Syntax'
        elif any(word in text_lower for word in ['best practice', 'convention', 'standard']):
            return 'Best Practices'
        elif any(word in text_lower for word in ['security', 'injection', 'vulnerability']):
            return 'Security'
        else:
            return 'General'
    
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
            analysis = self.session.query(Analysis).filter(
                Analysis.evaluation_id == evaluation.id
            ).first()
            
            recommendations = self.session.query(Recommendation).filter(
                Recommendation.evaluation_id == evaluation.id
            ).all()
            
            return {
                'evaluation': evaluation,
                'analysis': analysis,
                'recommendations': recommendations,
                'file': sql_file,
                'quest': evaluation.quest
            }
            
        except Exception as e:
            print(f"❌ Error getting current evaluation: {e}")
            return None
    
    def get_dashboard_summary(self) -> Dict[str, Any]:
        """Get simplified dashboard summary"""
        try:
            # Overall stats
            total_files = self.session.query(SQLFile).count()
            evaluated_files = self.session.query(Evaluation).count()
            
            # Score distribution
            score_stats = self.session.query(
                func.count(Evaluation.id).label('total'),
                func.avg(Evaluation.numeric_score).label('avg_score'),
                func.count(func.nullif(Evaluation.overall_assessment != 'PASS', False)).label('pass_count')
            ).first()
            
            # Quest performance
            quest_performance = self.session.query(
                Quest.name,
                Quest.display_name,
                func.count(Evaluation.id).label('evaluations'),
                func.avg(Evaluation.numeric_score).label('avg_score'),
                func.sum(func.case([(Evaluation.overall_assessment == 'PASS', 1)], else_=0)).label('pass_count')
            ).join(Evaluation).group_by(Quest.id, Quest.name, Quest.display_name).all()
            
            # Recent recommendations
            recent_recommendations = self.session.query(
                Recommendation.category,
                func.count(Recommendation.id).label('count')
            ).filter(
                Recommendation.created_at >= datetime.now().replace(hour=0, minute=0, second=0)
            ).group_by(Recommendation.category).all()
            
            return {
                'overview': {
                    'total_files': total_files,
                    'evaluated_files': evaluated_files,
                    'coverage_percent': round((evaluated_files / total_files) * 100, 1) if total_files > 0 else 0,
                    'average_score': round(float(score_stats.avg_score), 2) if score_stats.avg_score else 0,
                    'pass_rate': round((score_stats.pass_count / score_stats.total) * 100, 1) if score_stats.total > 0 else 0
                },
                'quest_performance': [
                    {
                        'quest': row.name,
                        'display_name': row.display_name,
                        'evaluations': row.evaluations,
                        'avg_score': round(float(row.avg_score), 2) if row.avg_score else 0,
                        'pass_rate': round((row.pass_count / row.evaluations) * 100, 1) if row.evaluations > 0 else 0
                    }
                    for row in quest_performance
                ],
                'recommendation_categories': [
                    {'category': row.category, 'count': row.count}
                    for row in recent_recommendations
                ]
            }
            
        except Exception as e:
            print(f"❌ Error generating dashboard summary: {e}")
            return {'error': str(e)}
