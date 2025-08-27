#!/usr/bin/env python3
"""
Simplified Database Schema for SQL Adventure AI Evaluator
Focus: Current state evaluation with upsert logic, minimal complexity
"""

from datetime import datetime
from typing import List, Optional
from sqlalchemy import (
    Column, Integer, String, Text, DateTime, Boolean, Float, 
    ForeignKey, UniqueConstraint, Index, CheckConstraint
)
from sqlalchemy.orm import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import JSON, UUID
import uuid

EvaluationBase = declarative_base()

# Core hierarchy tables (keep as-is, they work well)
class Quest(EvaluationBase):
    """Quest information"""
    __tablename__ = 'quests'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(100), unique=True, nullable=False)
    display_name = Column(String(200), nullable=False)
    description = Column(Text)
    difficulty_level = Column(String(20), nullable=False)
    order_index = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=datetime.now)
    
    # Relationships
    subcategories = relationship("Subcategory", back_populates="quest", cascade="all, delete-orphan")
    evaluations = relationship("Evaluation", back_populates="quest")
    
    __table_args__ = (
        CheckConstraint("difficulty_level IN ('Beginner', 'Intermediate', 'Advanced', 'Expert')", name='valid_difficulty'),
        Index('idx_quest_name', 'name'),
    )

class Subcategory(EvaluationBase):
    """Quest subcategories"""
    __tablename__ = 'subcategories'
    
    id = Column(Integer, primary_key=True)
    quest_id = Column(Integer, ForeignKey('quests.id'), nullable=False)
    name = Column(String(100), nullable=False)
    display_name = Column(String(200), nullable=False)
    description = Column(Text)
    difficulty_level = Column(String(20), nullable=False)
    order_index = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=datetime.now)
    
    # Relationships
    quest = relationship("Quest", back_populates="subcategories")
    sql_files = relationship("SQLFile", back_populates="subcategory", cascade="all, delete-orphan")
    
    __table_args__ = (
        UniqueConstraint('quest_id', 'name', name='unique_subcategory_per_quest'),
        CheckConstraint("difficulty_level IN ('Beginner', 'Intermediate', 'Advanced', 'Expert')", name='valid_subcategory_difficulty'),
        Index('idx_subcategory_quest', 'quest_id'),
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
    content_hash = Column(String(64))  # For change detection
    created_at = Column(DateTime, default=datetime.now)
    last_modified = Column(DateTime, default=datetime.now, onupdate=datetime.now)
    
    # Relationships
    subcategory = relationship("Subcategory", back_populates="sql_files")
    evaluation = relationship("Evaluation", back_populates="sql_file", uselist=False, cascade="all, delete-orphan")
    
    __table_args__ = (
        Index('idx_sql_file_path', 'file_path'),
        Index('idx_sql_file_subcategory', 'subcategory_id'),
    )

# NORMALIZED: Clean evaluation table focused on core assessment
class Evaluation(EvaluationBase):
    """Core evaluation record for each SQL file (UPSERT model)"""
    __tablename__ = 'evaluations'
    
    id = Column(Integer, primary_key=True)
    sql_file_id = Column(Integer, ForeignKey('sql_files.id'), nullable=False, unique=True)  # ONE evaluation per file
    quest_id = Column(Integer, ForeignKey('quests.id'), nullable=False)
    
    # Evaluation metadata
    evaluator_model = Column(String(50), default='gpt-4o-mini')
    last_evaluated = Column(DateTime, default=datetime.now, onupdate=datetime.now)
    
    # Overall assessment
    overall_assessment = Column(String(20), nullable=False)  # PASS, FAIL, NEEDS_REVIEW
    numeric_score = Column(Integer, nullable=False)  # 1-10
    letter_grade = Column(String(2), nullable=False)  # A, B, C, D, F
    
    # Detected patterns as JSONB (simplified from junction table)
    detected_patterns = Column(JSON)  # [{"name": "table_creation", "confidence": 0.9, "quality": "Good"}, ...]
    
    # Relationships
    sql_file = relationship("SQLFile", back_populates="evaluation")
    quest = relationship("Quest", back_populates="evaluations")
    execution_metadata = relationship("ExecutionMetadata", back_populates="evaluation", uselist=False, cascade="all, delete-orphan")
    analysis = relationship("Analysis", back_populates="evaluation", uselist=False, cascade="all, delete-orphan")
    recommendations = relationship("Recommendation", back_populates="evaluation", cascade="all, delete-orphan")
    
    __table_args__ = (
        CheckConstraint("overall_assessment IN ('PASS', 'FAIL', 'NEEDS_REVIEW')", name='valid_assessment'),
        CheckConstraint("numeric_score >= 1 AND numeric_score <= 10", name='valid_score'),
        CheckConstraint("letter_grade IN ('A', 'B', 'C', 'D', 'F', 'A+', 'A-', 'B+', 'B-', 'C+', 'C-', 'D+', 'D-')", name='valid_grade'),
        Index('idx_evaluation_file', 'sql_file_id'),
        Index('idx_evaluation_quest', 'quest_id'),
        Index('idx_evaluation_last_evaluated', 'last_evaluated'),
        Index('idx_evaluation_assessment', 'overall_assessment'),
    )

# SEPARATED: Execution metadata in its own table
class ExecutionMetadata(EvaluationBase):
    """SQL execution results and performance metrics"""
    __tablename__ = 'execution_metadata'
    
    id = Column(Integer, primary_key=True)
    evaluation_id = Column(Integer, ForeignKey('evaluations.id'), nullable=False, unique=True)
    
    # Execution results
    execution_success = Column(Boolean, nullable=False, default=False)
    execution_time_ms = Column(Integer)
    output_lines = Column(Integer, default=0)
    result_sets = Column(Integer, default=0)
    rows_affected = Column(Integer, default=0)
    error_count = Column(Integer, default=0)
    warning_count = Column(Integer, default=0)
    execution_output = Column(Text)  # Store current output for quick access
    
    created_at = Column(DateTime, default=datetime.now)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)
    
    # Relationships
    evaluation = relationship("Evaluation", back_populates="execution_metadata")
    
    __table_args__ = (
        Index('idx_execution_evaluation', 'evaluation_id'),
        Index('idx_execution_success', 'execution_success'),
    )

# ENHANCED: Analysis with proper reasoning structure
class Analysis(EvaluationBase):
    """Comprehensive analysis with technical and educational reasoning"""
    __tablename__ = 'analyses'
    
    id = Column(Integer, primary_key=True)
    evaluation_id = Column(Integer, ForeignKey('evaluations.id'), nullable=False, unique=True)
    
    # Overall assessment
    overall_feedback = Column(Text)  # Combined technical + educational feedback
    difficulty_level = Column(String(20), nullable=False)
    estimated_time_minutes = Column(Integer)
    
    # Technical reasoning and scoring
    technical_score = Column(Integer, nullable=False)    # 1-10 (overall technical quality)
    technical_reasoning = Column(Text, nullable=False)   # Detailed technical analysis
    
    # Educational reasoning and scoring  
    educational_score = Column(Integer, nullable=False)  # 1-10 (learning value)
    educational_reasoning = Column(Text, nullable=False) # Detailed educational analysis
    
    created_at = Column(DateTime, default=datetime.now)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)
    
    # Relationships
    evaluation = relationship("Evaluation", back_populates="analysis")
    
    __table_args__ = (
        CheckConstraint("difficulty_level IN ('Beginner', 'Intermediate', 'Advanced', 'Expert')", name='valid_difficulty'),
        CheckConstraint("technical_score >= 1 AND technical_score <= 10", name='valid_technical_score'),
        CheckConstraint("educational_score >= 1 AND educational_score <= 10", name='valid_educational_score'),
        CheckConstraint("estimated_time_minutes > 0", name='valid_time_estimate'),
    )

# REMOVED: EvaluationPattern junction table (replaced with JSONB in Evaluation)
# Pattern data will be stored as: detected_patterns = [{"name": "table_creation", "confidence": 0.9, "quality": "Good"}, ...]

# KEEP: Recommendations for Copilot learning
class Recommendation(EvaluationBase):
    """AI-generated recommendations for improvement (for Copilot learning)"""
    __tablename__ = 'recommendations'
    
    id = Column(Integer, primary_key=True)
    evaluation_id = Column(Integer, ForeignKey('evaluations.id'), nullable=False)
    
    category = Column(String(50), nullable=False)  # Performance, Syntax, Best Practices, etc.
    priority = Column(String(10), nullable=False)  # High, Medium, Low
    recommendation_text = Column(Text, nullable=False)
    implementation_effort = Column(String(20))  # Low, Medium, High
    expected_impact = Column(String(20))  # High, Medium, Low
    
    created_at = Column(DateTime, default=datetime.now)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)
    
    # Relationships
    evaluation = relationship("Evaluation", back_populates="recommendations")
    
    __table_args__ = (
        CheckConstraint("priority IN ('High', 'Medium', 'Low')", name='valid_priority'),
        CheckConstraint("implementation_effort IN ('Low', 'Medium', 'High')", name='valid_effort'),
        CheckConstraint("expected_impact IN ('High', 'Medium', 'Low')", name='valid_impact'),
        Index('idx_recommendation_evaluation', 'evaluation_id'),
        Index('idx_recommendation_priority', 'priority'),
        Index('idx_recommendation_category', 'category'),
    )

# ENHANCED: Pattern catalog with regex patterns and examples
class SQLPattern(EvaluationBase):
    """Enhanced catalog of SQL patterns with regex patterns and examples"""
    __tablename__ = 'sql_patterns'

    id = Column(Integer, primary_key=True)
    name = Column(String(100), unique=True, nullable=False)
    display_name = Column(String(200), nullable=False)
    description = Column(Text)
    category = Column(String(50), nullable=False)  # DDL, DML, DQL, DCL, TCL, ANALYTICS, JSON, RECURSIVE
    complexity_level = Column(String(20), nullable=False)

    # Fields for pattern matching and examples
    regex_pattern = Column(String(500))  # Regular expression for pattern detection
    base_description = Column(Text)      # Base description for the pattern
    examples = Column(JSON)              # List of example SQL statements
    usage_count = Column(Integer, default=0)  # How many times pattern is detected

    # Metadata
    created_at = Column(DateTime, default=datetime.now)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)

    __table_args__ = (
        CheckConstraint("category IN ('DDL', 'DML', 'DQL', 'DCL', 'TCL', 'ANALYTICS', 'JSON', 'RECURSIVE')", name='valid_pattern_category'),
        CheckConstraint("complexity_level IN ('Basic', 'Intermediate', 'Advanced', 'Expert')", name='valid_pattern_complexity'),
        Index('idx_pattern_category', 'category'),
        Index('idx_pattern_complexity', 'complexity_level'),
        Index('idx_pattern_usage', 'usage_count'),
    )
