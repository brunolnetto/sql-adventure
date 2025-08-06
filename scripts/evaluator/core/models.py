#!/usr/bin/env python3
"""
Flexible and Extensible Database Models for SQL Adventure AI Evaluator
Designed for efficiency, extensibility, and maintainability
"""

from datetime import datetime
from typing import List, Optional, Dict, Any
from sqlalchemy import (
    Column, Integer, String, Text, DateTime, Boolean, Float, 
    ForeignKey, UniqueConstraint, Index, CheckConstraint
)
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship, Session
from sqlalchemy.dialects.postgresql import JSON, UUID
import uuid

Base = declarative_base()

class Quest(Base):
    """Quest information with flexible metadata"""
    __tablename__ = 'quests'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100), unique=True, nullable=False)
    display_name = Column(String(200), nullable=False)
    description = Column(Text)
    difficulty_level = Column(String(20), nullable=False)
    order_index = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Flexible metadata storage
    quest_metadata = Column(JSON, default=dict)  # For extensible quest properties
    
    # Relationships
    subcategories = relationship("Subcategory", back_populates="quest", cascade="all, delete-orphan")
    evaluations = relationship("Evaluation", back_populates="quest")
    
    # Constraints
    __table_args__ = (
        CheckConstraint("difficulty_level IN ('Beginner', 'Intermediate', 'Advanced', 'Expert')", name='valid_difficulty'),
        Index('idx_quest_name', 'name'),
        Index('idx_quest_order', 'order_index'),
    )

class Subcategory(Base):
    """Quest subcategories with flexible structure"""
    __tablename__ = 'subcategories'
    
    id = Column(Integer, primary_key=True)
    quest_id = Column(Integer, ForeignKey('quests.id'), nullable=False)
    name = Column(String(100), nullable=False)
    display_name = Column(String(200), nullable=False)
    description = Column(Text)
    difficulty_level = Column(String(20), nullable=False)
    order_index = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Flexible metadata storage
    subcategory_metadata = Column(JSON, default=dict)  # For extensible subcategory properties
    
    # Relationships
    quest = relationship("Quest", back_populates="subcategories")
    sql_files = relationship("SQLFile", back_populates="subcategory", cascade="all, delete-orphan")
    
    # Constraints
    __table_args__ = (
        UniqueConstraint('quest_id', 'name', name='unique_subcategory_per_quest'),
        CheckConstraint("difficulty_level IN ('Beginner', 'Intermediate', 'Advanced', 'Expert')", name='valid_subcategory_difficulty'),
        Index('idx_subcategory_quest', 'quest_id'),
        Index('idx_subcategory_order', 'quest_id', 'order_index'),
    )

class SQLFile(Base):
    """SQL files with flexible metadata and content tracking"""
    __tablename__ = 'sql_files'
    
    id = Column(Integer, primary_key=True)
    subcategory_id = Column(Integer, ForeignKey('subcategories.id'), nullable=False)
    filename = Column(String(200), nullable=False)
    file_path = Column(String(500), nullable=False, unique=True)
    display_name = Column(String(200))
    description = Column(Text)
    estimated_time_minutes = Column(Integer)
    created_at = Column(DateTime, default=datetime.utcnow)
    last_modified = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Content tracking
    content_hash = Column(String(64))  # For change detection
    file_size = Column(Integer)  # File size in bytes
    
    # Flexible metadata storage
    file_metadata = Column(JSON, default=dict)  # For extensible file properties
    
    # Relationships
    subcategory = relationship("Subcategory", back_populates="sql_files")
    evaluations = relationship("Evaluation", back_populates="sql_file", cascade="all, delete-orphan")
    
    # Constraints
    __table_args__ = (
        Index('idx_sql_file_path', 'file_path'),
        Index('idx_sql_file_subcategory', 'subcategory_id'),
        Index('idx_sql_file_hash', 'content_hash'),
    )

class SQLPattern(Base):
    """Flexible SQL pattern catalog"""
    __tablename__ = 'sql_patterns'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100), unique=True, nullable=False)
    display_name = Column(String(200), nullable=False)
    description = Column(Text)
    category = Column(String(50), nullable=False)  # DDL, DML, DQL, etc.
    complexity_level = Column(String(20), nullable=False)
    detection_regex = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Flexible pattern configuration
    pattern_config = Column(JSON, default=dict)  # For extensible pattern properties
    
    # Relationships
    evaluation_patterns = relationship("EvaluationPattern", back_populates="pattern")
    
    # Constraints
    __table_args__ = (
        CheckConstraint("complexity_level IN ('Beginner', 'Intermediate', 'Advanced', 'Expert')", name='valid_pattern_complexity'),
        Index('idx_pattern_category', 'category'),
        Index('idx_pattern_complexity', 'complexity_level'),
    )

class Evaluation(Base):
    """Main evaluation results with flexible structure"""
    __tablename__ = 'evaluations'
    
    id = Column(Integer, primary_key=True)
    evaluation_uuid = Column(UUID(as_uuid=True), default=uuid.uuid4, unique=True, nullable=False)
    sql_file_id = Column(Integer, ForeignKey('sql_files.id'), nullable=False)
    quest_id = Column(Integer, ForeignKey('quests.id'), nullable=False)
    
    # Evaluation metadata
    evaluation_version = Column(String(20), default='2.0')
    evaluator_model = Column(String(50), default='gpt-4o-mini')
    evaluation_date = Column(DateTime, default=datetime.utcnow)
    
    # Core assessment (required fields)
    overall_assessment = Column(String(20), nullable=False)  # PASS, FAIL, NEEDS_REVIEW
    numeric_score = Column(Integer, nullable=False)  # 1-10
    letter_grade = Column(String(2), nullable=False)  # A, B, C, D, F
    
    # Execution results
    execution_success = Column(Boolean, nullable=False, default=False)
    execution_time_ms = Column(Integer)
    output_lines = Column(Integer, default=0)
    result_sets = Column(Integer, default=0)
    rows_affected = Column(Integer, default=0)
    error_count = Column(Integer, default=0)
    warning_count = Column(Integer, default=0)
    
    # Flexible analysis storage
    technical_analysis = Column(JSON, default=dict)  # Technical assessment
    educational_analysis = Column(JSON, default=dict)  # Educational assessment
    execution_details = Column(JSON, default=dict)  # Detailed execution info
    detected_patterns = Column(JSON, default=dict)  # Pattern detection results
    recommendations = Column(JSON, default=dict)  # AI recommendations
    evaluation_metadata = Column(JSON, default=dict)  # Additional metadata
    
    # Relationships
    sql_file = relationship("SQLFile", back_populates="evaluations")
    quest = relationship("Quest", back_populates="evaluations")
    evaluation_patterns = relationship("EvaluationPattern", back_populates="evaluation", cascade="all, delete-orphan")
    
    # Constraints
    __table_args__ = (
        CheckConstraint("overall_assessment IN ('PASS', 'FAIL', 'NEEDS_REVIEW')", name='valid_assessment'),
        CheckConstraint("numeric_score BETWEEN 1 AND 10", name='valid_score'),
        CheckConstraint("letter_grade IN ('A', 'B', 'C', 'D', 'F')", name='valid_grade'),
        Index('idx_evaluation_file', 'sql_file_id'),
        Index('idx_evaluation_quest', 'quest_id'),
        Index('idx_evaluation_date', 'evaluation_date'),
        Index('idx_evaluation_score', 'numeric_score'),
    )

class EvaluationPattern(Base):
    """Patterns detected in evaluations"""
    __tablename__ = 'evaluation_patterns'
    
    id = Column(Integer, primary_key=True)
    evaluation_id = Column(Integer, ForeignKey('evaluations.id'), nullable=False)
    pattern_id = Column(Integer, ForeignKey('sql_patterns.id'), nullable=False)
    
    confidence_score = Column(Float, nullable=False)
    usage_quality = Column(String(20))  # Excellent, Good, Fair, Poor
    notes = Column(Text)
    
    # Flexible pattern metadata
    pattern_metadata = Column(JSON, default=dict)  # For extensible pattern properties
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    evaluation = relationship("Evaluation", back_populates="evaluation_patterns")
    pattern = relationship("SQLPattern", back_populates="evaluation_patterns")
    
    # Constraints
    __table_args__ = (
        CheckConstraint("confidence_score BETWEEN 0.0 AND 1.0", name='valid_confidence'),
        CheckConstraint("usage_quality IN ('Excellent', 'Good', 'Fair', 'Poor')", name='valid_usage_quality'),
        UniqueConstraint('evaluation_id', 'pattern_id', name='unique_evaluation_pattern'),
        Index('idx_eval_pattern_evaluation', 'evaluation_id'),
        Index('idx_eval_pattern_pattern', 'pattern_id'),
    )

class EvaluationSession(Base):
    """Track evaluation sessions for batch processing"""
    __tablename__ = 'evaluation_sessions'
    
    id = Column(Integer, primary_key=True)
    session_uuid = Column(UUID(as_uuid=True), default=uuid.uuid4, unique=True, nullable=False)
    
    started_at = Column(DateTime, default=datetime.utcnow)
    completed_at = Column(DateTime)
    total_files = Column(Integer, default=0)
    successful_evaluations = Column(Integer, default=0)
    failed_evaluations = Column(Integer, default=0)
    
    evaluator_version = Column(String(20))
    configuration = Column(JSON)  # Store session configuration
    
    # Flexible session metadata
    session_metadata = Column(JSON, default=dict)  # For extensible session properties
    
    # Constraints
    __table_args__ = (
        Index('idx_session_started', 'started_at'),
        Index('idx_session_completed', 'completed_at'),
    )

# Utility functions for working with flexible models
class ModelUtils:
    """Utility functions for working with the flexible model system"""
    
    @staticmethod
    def get_metadata_value(model_instance, key: str, default=None):
        """Get a value from the metadata JSON field"""
        if hasattr(model_instance, 'metadata') and model_instance.metadata:
            return model_instance.metadata.get(key, default)
        return default
    
    @staticmethod
    def set_metadata_value(model_instance, key: str, value: Any):
        """Set a value in the metadata JSON field"""
        if not hasattr(model_instance, 'metadata'):
            model_instance.metadata = {}
        model_instance.metadata[key] = value
    
    @staticmethod
    def update_metadata(model_instance, updates: Dict[str, Any]):
        """Update multiple metadata values"""
        if not hasattr(model_instance, 'metadata'):
            model_instance.metadata = {}
        model_instance.metadata.update(updates)
    
    @staticmethod
    def get_json_field_value(model_instance, field_name: str, key: str, default=None):
        """Get a value from a JSON field"""
        field_value = getattr(model_instance, field_name, {})
        if isinstance(field_value, dict):
            return field_value.get(key, default)
        return default
    
    @staticmethod
    def set_json_field_value(model_instance, field_name: str, key: str, value: Any):
        """Set a value in a JSON field"""
        field_value = getattr(model_instance, field_name, {})
        if not isinstance(field_value, dict):
            field_value = {}
        field_value[key] = value
        setattr(model_instance, field_name, field_value)

# Migration helper for upgrading from old schema
class MigrationHelper:
    """Helper for migrating from the old specific schema to the new flexible schema"""
    
    @staticmethod
    def migrate_evaluation_data(old_evaluation_data: Dict[str, Any]) -> Dict[str, Any]:
        """Migrate old evaluation data to new flexible format"""
        new_data = {
            'evaluation_uuid': old_evaluation_data.get('evaluation_uuid'),
            'sql_file_id': old_evaluation_data.get('sql_file_id'),
            'quest_id': old_evaluation_data.get('quest_id'),
            'evaluation_version': old_evaluation_data.get('evaluation_version', '2.0'),
            'evaluator_model': old_evaluation_data.get('evaluator_model', 'gpt-4o-mini'),
            'evaluation_date': old_evaluation_data.get('evaluation_date'),
            'overall_assessment': old_evaluation_data.get('overall_assessment'),
            'numeric_score': old_evaluation_data.get('numeric_score'),
            'letter_grade': old_evaluation_data.get('letter_grade'),
            'execution_success': old_evaluation_data.get('execution_success'),
            'execution_time_ms': old_evaluation_data.get('execution_time_ms'),
            'output_lines': old_evaluation_data.get('output_lines'),
            'result_sets': old_evaluation_data.get('result_sets'),
            'rows_affected': old_evaluation_data.get('rows_affected'),
            'error_count': old_evaluation_data.get('error_count'),
            'warning_count': old_evaluation_data.get('warning_count'),
        }
        
        # Migrate technical analysis
        if 'technical_analysis' in old_evaluation_data:
            tech_analysis = old_evaluation_data['technical_analysis']
            new_data['technical_analysis'] = {
                'syntax_correctness': tech_analysis.get('syntax_correctness'),
                'logical_structure': tech_analysis.get('logical_structure'),
                'code_quality': tech_analysis.get('code_quality'),
                'performance_notes': tech_analysis.get('performance_notes'),
                'maintainability': tech_analysis.get('maintainability'),
                'best_practices_adherence': tech_analysis.get('best_practices_adherence'),
                'scores': {
                    'syntax_score': tech_analysis.get('syntax_score'),
                    'logic_score': tech_analysis.get('logic_score'),
                    'quality_score': tech_analysis.get('quality_score'),
                    'performance_score': tech_analysis.get('performance_score'),
                }
            }
        
        # Migrate educational analysis
        if 'educational_analysis' in old_evaluation_data:
            edu_analysis = old_evaluation_data['educational_analysis']
            new_data['educational_analysis'] = {
                'learning_value': edu_analysis.get('learning_value'),
                'difficulty_level': edu_analysis.get('difficulty_level'),
                'estimated_time_minutes': edu_analysis.get('estimated_time_minutes'),
                'prerequisite_knowledge': edu_analysis.get('prerequisite_knowledge'),
                'learning_objectives': edu_analysis.get('learning_objectives'),
                'real_world_applicability': edu_analysis.get('real_world_applicability'),
                'scores': {
                    'clarity_score': edu_analysis.get('clarity_score'),
                    'relevance_score': edu_analysis.get('relevance_score'),
                    'engagement_score': edu_analysis.get('engagement_score'),
                    'progression_score': edu_analysis.get('progression_score'),
                }
            }
        
        # Migrate execution details
        if 'execution_details' in old_evaluation_data:
            new_data['execution_details'] = old_evaluation_data['execution_details']
        
        # Migrate recommendations
        if 'recommendations' in old_evaluation_data:
            new_data['recommendations'] = old_evaluation_data['recommendations']
        
        return new_data