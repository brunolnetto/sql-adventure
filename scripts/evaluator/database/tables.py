#!/usr/bin/env python3
"""
Normalized Database Models for SQL Adventure AI Evaluator
Designed with proper relationships and database best practices
"""

from datetime import datetime
from typing import List, Optional
from sqlalchemy import (
    Column, Integer, String, Text, DateTime, Boolean, Float, 
    ForeignKey, UniqueConstraint, Index, CheckConstraint
)
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship, Session
from sqlalchemy.dialects.postgresql import JSON, UUID
import uuid

EvaluationBase = declarative_base()

class Quest(EvaluationBase):
    """Normalized quest information"""
    __tablename__ = 'quests'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100), unique=True, nullable=False)
    display_name = Column(String(200), nullable=False)
    difficulty_level = Column(String(20), nullable=False)
    order_index = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    subcategories = relationship("Subcategory", back_populates="quest", cascade="all, delete-orphan")
    evaluations = relationship("Evaluation", back_populates="quest")
    
    # Constraints
    __table_args__ = (
        CheckConstraint("difficulty_level IN ('Beginner', 'Intermediate', 'Advanced', 'Expert')", name='valid_difficulty'),
        Index('idx_quest_name', 'name'),
        Index('idx_quest_order', 'order_index'),
    )

class Subcategory(EvaluationBase):
    """Quest subcategories (e.g., 00-basic-concepts, 01-normalization-patterns)"""
    __tablename__ = 'subcategories'
    
    id = Column(Integer, primary_key=True)
    quest_id = Column(Integer, ForeignKey('quests.id'), nullable=False)
    name = Column(String(100), nullable=False)
    display_name = Column(String(200), nullable=False)
    description = Column(Text)
    difficulty_level = Column(String(20), nullable=False)
    order_index = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
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

class SQLFile(EvaluationBase):
    """Individual SQL files with metadata"""
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
    
    # File content hash for change detection
    content_hash = Column(String(64))
    
    # Relationships
    subcategory = relationship("Subcategory", back_populates="sql_files")
    evaluations = relationship("Evaluation", back_populates="sql_file", cascade="all, delete-orphan")
    sql_patterns = relationship("SQLFilePattern", back_populates="sql_file", cascade="all, delete-orphan")
    
    # Constraints
    __table_args__ = (
        Index('idx_sql_file_path', 'file_path'),
        Index('idx_sql_file_subcategory', 'subcategory_id'),
        Index('idx_sql_file_hash', 'content_hash'),
    )

class SQLPattern(EvaluationBase):
    """Catalog of SQL patterns that can be detected"""
    __tablename__ = 'sql_patterns'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100), unique=True, nullable=False)
    display_name = Column(String(200), nullable=False)
    description = Column(Text)
    category = Column(String(50), nullable=False)  # DDL, DML, DQL, etc.
    complexity_level = Column(String(20), nullable=False)
    detection_regex = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    file_patterns = relationship("SQLFilePattern", back_populates="pattern")
    evaluation_patterns = relationship("EvaluationPattern", back_populates="pattern")
    
    # Constraints
    __table_args__ = (
        CheckConstraint("category IN ('DDL', 'DML', 'DQL', 'DCL', 'TCL', 'ANALYTICS', 'JSON', 'RECURSIVE')", name='valid_pattern_category'),
        CheckConstraint("complexity_level IN ('Basic', 'Intermediate', 'Advanced', 'Expert')", name='valid_pattern_complexity'),
        Index('idx_pattern_category', 'category'),
        Index('idx_pattern_complexity', 'complexity_level'),
    )

class SQLFilePattern(EvaluationBase):
    """Many-to-many relationship between SQL files and patterns"""
    __tablename__ = 'sql_file_patterns'
    
    id = Column(Integer, primary_key=True)
    sql_file_id = Column(Integer, ForeignKey('sql_files.id'), nullable=False)
    pattern_id = Column(Integer, ForeignKey('sql_patterns.id'), nullable=False)
    confidence_score = Column(Float, nullable=False, default=1.0)
    detected_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    sql_file = relationship("SQLFile", back_populates="sql_patterns")
    pattern = relationship("SQLPattern", back_populates="file_patterns")
    
    # Constraints
    __table_args__ = (
        UniqueConstraint('sql_file_id', 'pattern_id', name='unique_file_pattern'),
        CheckConstraint("confidence_score >= 0.0 AND confidence_score <= 1.0", name='valid_confidence'),
        Index('idx_file_pattern_file', 'sql_file_id'),
        Index('idx_file_pattern_pattern', 'pattern_id'),
    )

class Evaluation(EvaluationBase):
    """Main evaluation results table"""
    __tablename__ = 'evaluations'
    
    id = Column(Integer, primary_key=True)
    evaluation_uuid = Column(UUID(as_uuid=True), default=uuid.uuid4, unique=True, nullable=False)
    sql_file_id = Column(Integer, ForeignKey('sql_files.id'), nullable=False)
    quest_id = Column(Integer, ForeignKey('quests.id'), nullable=False)
    
    # Evaluation metadata
    evaluator_model = Column(String(50), default='gpt-4o-mini')
    evaluation_date = Column(DateTime, default=datetime.utcnow)
    
    # Overall assessment
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
    
    # Relationships
    sql_file = relationship("SQLFile", back_populates="evaluations")
    quest = relationship("Quest", back_populates="evaluations")
    technical_analysis = relationship("TechnicalAnalysis", back_populates="evaluation", uselist=False, cascade="all, delete-orphan")
    educational_analysis = relationship("EducationalAnalysis", back_populates="evaluation", uselist=False, cascade="all, delete-orphan")
    execution_details = relationship("ExecutionDetail", back_populates="evaluation", cascade="all, delete-orphan")
    evaluation_patterns = relationship("EvaluationPattern", back_populates="evaluation", cascade="all, delete-orphan")
    recommendations = relationship("Recommendation", back_populates="evaluation", cascade="all, delete-orphan")
    
    # Constraints
    __table_args__ = (
        CheckConstraint("overall_assessment IN ('PASS', 'FAIL', 'NEEDS_REVIEW')", name='valid_assessment'),
        CheckConstraint("numeric_score >= 1 AND numeric_score <= 10", name='valid_score'),
        CheckConstraint("letter_grade IN ('A', 'B', 'C', 'D', 'F', 'A+', 'A-', 'B+', 'B-', 'C+', 'C-', 'D+', 'D-')", name='valid_grade'),
        Index('idx_evaluation_file', 'sql_file_id'),
        Index('idx_evaluation_quest', 'quest_id'),
        Index('idx_evaluation_date', 'evaluation_date'),
        Index('idx_evaluation_score', 'numeric_score'),
        Index('idx_evaluation_assessment', 'overall_assessment'),
    )

class TechnicalAnalysis(EvaluationBase):
    """Detailed technical analysis of SQL code"""
    __tablename__ = 'technical_analyses'
    
    id = Column(Integer, primary_key=True)
    evaluation_id = Column(Integer, ForeignKey('evaluations.id'), nullable=False, unique=True)
    
    syntax_correctness = Column(Text)
    logical_structure = Column(Text)
    code_quality = Column(Text)
    performance_notes = Column(Text)
    maintainability = Column(Text)
    best_practices_adherence = Column(Text)
    
    # Scoring breakdown
    syntax_score = Column(Integer)  # 1-10
    logic_score = Column(Integer)   # 1-10
    quality_score = Column(Integer) # 1-10
    performance_score = Column(Integer) # 1-10
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    evaluation = relationship("Evaluation", back_populates="technical_analysis")
    
    # Constraints
    __table_args__ = (
        CheckConstraint("syntax_score >= 1 AND syntax_score <= 10", name='valid_syntax_score'),
        CheckConstraint("logic_score >= 1 AND logic_score <= 10", name='valid_logic_score'),
        CheckConstraint("quality_score >= 1 AND quality_score <= 10", name='valid_quality_score'),
        CheckConstraint("performance_score >= 1 AND performance_score <= 10", name='valid_performance_score'),
    )

class EducationalAnalysis(EvaluationBase):
    """Educational value analysis"""
    __tablename__ = 'educational_analyses'
    
    id = Column(Integer, primary_key=True)
    evaluation_id = Column(Integer, ForeignKey('evaluations.id'), nullable=False, unique=True)
    
    learning_value = Column(Text)
    difficulty_level = Column(String(20), nullable=False)
    estimated_time_minutes = Column(Integer)
    prerequisite_knowledge = Column(Text)
    learning_objectives = Column(Text)
    real_world_applicability = Column(Text)
    
    # Educational scoring
    clarity_score = Column(Integer)      # 1-10
    relevance_score = Column(Integer)    # 1-10
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    evaluation = relationship("Evaluation", back_populates="educational_analysis")
    
    # Constraints
    __table_args__ = (
        CheckConstraint("difficulty_level IN ('Beginner', 'Intermediate', 'Advanced', 'Expert')", name='valid_edu_difficulty'),
        CheckConstraint("clarity_score >= 1 AND clarity_score <= 10", name='valid_clarity_score'),
        CheckConstraint("relevance_score >= 1 AND relevance_score <= 10", name='valid_relevance_score'),
        CheckConstraint("engagement_score >= 1 AND engagement_score <= 10", name='valid_engagement_score'),
        CheckConstraint("progression_score >= 1 AND progression_score <= 10", name='valid_progression_score'),
        CheckConstraint("estimated_time_minutes > 0", name='valid_time_estimate'),
    )

class ExecutionDetail(EvaluationBase):
    """Detailed execution information for each SQL statement"""
    __tablename__ = 'execution_details'
    
    id = Column(Integer, primary_key=True)
    evaluation_id = Column(Integer, ForeignKey('evaluations.id'), nullable=False)
    
    statement_order = Column(Integer, nullable=False)
    sql_statement = Column(Text, nullable=False)
    execution_success = Column(Boolean, nullable=False)
    execution_time_ms = Column(Integer)
    rows_affected = Column(Integer, default=0)
    rows_returned = Column(Integer, default=0)
    error_message = Column(Text)
    warning_message = Column(Text)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    evaluation = relationship("Evaluation", back_populates="execution_details")
    
    # Constraints
    __table_args__ = (
        Index('idx_execution_evaluation', 'evaluation_id'),
        Index('idx_execution_order', 'evaluation_id', 'statement_order'),
    )

class EvaluationPattern(EvaluationBase):
    """Patterns detected in specific evaluations"""
    __tablename__ = 'evaluation_patterns'
    
    id = Column(Integer, primary_key=True)
    evaluation_id = Column(Integer, ForeignKey('evaluations.id'), nullable=False)
    pattern_id = Column(Integer, ForeignKey('sql_patterns.id'), nullable=False)
    
    confidence_score = Column(Float, nullable=False)
    usage_quality = Column(String(20))  # Excellent, Good, Fair, Poor
    notes = Column(Text)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    evaluation = relationship("Evaluation", back_populates="evaluation_patterns")
    pattern = relationship("SQLPattern", back_populates="evaluation_patterns")
    
    # Constraints
    __table_args__ = (
        UniqueConstraint('evaluation_id', 'pattern_id', name='unique_evaluation_pattern'),
        CheckConstraint("confidence_score >= 0.0 AND confidence_score <= 1.0", name='valid_eval_confidence'),
        CheckConstraint("usage_quality IN ('Excellent', 'Good', 'Fair', 'Poor')", name='valid_usage_quality'),
        Index('idx_eval_pattern_evaluation', 'evaluation_id'),
        Index('idx_eval_pattern_pattern', 'pattern_id'),
    )

class Recommendation(EvaluationBase):
    """AI-generated recommendations for improvement"""
    __tablename__ = 'recommendations'
    
    id = Column(Integer, primary_key=True)
    evaluation_id = Column(Integer, ForeignKey('evaluations.id'), nullable=False)
    
    category = Column(String(50), nullable=False)  # Performance, Syntax, Best Practices, etc.
    priority = Column(String(10), nullable=False)  # High, Medium, Low
    recommendation_text = Column(Text, nullable=False)
    implementation_effort = Column(String(20))  # Easy, Medium, Hard
    expected_impact = Column(String(20))  # High, Medium, Low
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    evaluation = relationship("Evaluation", back_populates="recommendations")
    
    # Constraints
    __table_args__ = (
        CheckConstraint("priority IN ('High', 'Medium', 'Low')", name='valid_priority'),
        CheckConstraint("implementation_effort IN ('Easy', 'Medium', 'Hard')", name='valid_effort'),
        CheckConstraint("expected_impact IN ('High', 'Medium', 'Low')", name='valid_impact'),
        Index('idx_recommendation_evaluation', 'evaluation_id'),
        Index('idx_recommendation_priority', 'priority'),
        Index('idx_recommendation_category', 'category'),
    )

class EvaluationSession(EvaluationBase):
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
    
    # Constraints
    __table_args__ = (
        Index('idx_session_date', 'started_at'),
        Index('idx_session_status', 'completed_at'),
    )
