#!/usr/bin/env python3
"""
Unified Database Manager for SQL Adventure AI Evaluator
Consolidates all database functionality into a single, clean implementation
"""

import os
import hashlib
import asyncio
from typing import Optional, Dict, Any, List, Tuple
from datetime import datetime, timedelta
from pathlib import Path

from sqlalchemy import create_engine, text, func, and_, or_, inspect
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.exc import SQLAlchemyError, IntegrityError, OperationalError
from sqlalchemy.dialects.postgresql import insert

from .models import (
    Base, Quest, Subcategory, SQLFile, SQLPattern, 
    Evaluation, EvaluationPattern, EvaluationSession, ModelUtils
)
from .config import get_config

class DatabaseManager:
    """Unified database manager with flexible models and quest discovery"""
    
    def __init__(self, config=None, connection_string: Optional[str] = None):
        """
        Initialize database manager
        
        Args:
            config: Configuration object
            connection_string: Optional database connection string
        """
        self.config = config or get_config()
        self.connection_string = connection_string or self._get_connection_string()
        self.engine = None
        self.SessionLocal = None
        self.initialized = False
        
        # Setup engine and session
        self._setup_engine()
    
    def _get_connection_string(self) -> str:
        """Get database connection string from configuration"""
        db_config = self.config.database
        return f"postgresql://{db_config.user}:{db_config.password}@{db_config.host}:{db_config.port}/{db_config.database}"
    
    def _setup_engine(self):
        """Setup SQLAlchemy engine and session"""
        try:
            self.engine = create_engine(
                self.connection_string,
                pool_size=self.config.database.pool_size,
                max_overflow=self.config.database.max_overflow,
                pool_pre_ping=self.config.database.pool_pre_ping,
                pool_recycle=self.config.database.pool_recycle,
                echo=self.config.database.echo_sql
            )
            self.SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
            print("✅ Database connection established")
            
        except Exception as e:
            print(f"❌ Database connection failed: {e}")
            self.engine = None
            self.SessionLocal = None
    
    def initialize(self, force_recreate: bool = False) -> bool:
        """Initialize the database system"""
        try:
            print("🔧 Initializing database...")
            
            # Ensure database exists
            if not self._ensure_database_exists():
                return False
            
            # Create tables
            if not self._create_tables(force_recreate):
                return False
            
            # Initialize reference data
            if not self._initialize_reference_data():
                return False
            
            # Verify initialization
            if not self._verify_initialization():
                return False
            
            self.initialized = True
            print("✅ Database initialization completed successfully!")
            return True
            
        except Exception as e:
            print(f"❌ Database initialization failed: {e}")
            return False
    
    def _ensure_database_exists(self) -> bool:
        """Ensure the evaluator database exists"""
        try:
            # Connect to default postgres database to create evaluator database
            base_connection = self._get_connection_string(use_main_db=True)
            temp_engine = create_engine(base_connection)
            
            with temp_engine.connect() as conn:
                conn.execute(text("COMMIT"))  # End any existing transaction
                
                # Check if database exists
                db_name = self.config.database.database
                result = conn.execute(text(
                    f"SELECT 1 FROM pg_database WHERE datname = '{db_name}'"
                ))
                
                if not result.fetchone():
                    conn.execute(text(f"CREATE DATABASE {db_name}"))
                    print(f"✅ Created evaluator database: {db_name}")
                else:
                    print(f"✅ Evaluator database already exists: {db_name}")
            
            temp_engine.dispose()
            return True
            
        except Exception as e:
            print(f"⚠️  Could not ensure database exists: {e}")
            return False
    
    def _get_connection_string(self, use_main_db: bool = False) -> str:
        """Get database connection string"""
        db_config = self.config.database
        db_name = db_config.main_database if use_main_db else db_config.database
        return f"postgresql://{db_config.user}:{db_config.password}@{db_config.host}:{db_config.port}/{db_name}"
    
    def _create_tables(self, force_recreate: bool = False) -> bool:
        """Create all database tables"""
        try:
            if force_recreate:
                print("🗑️  Dropping existing tables...")
                Base.metadata.drop_all(self.engine)
            
            print("📋 Creating database tables...")
            Base.metadata.create_all(self.engine)
            print("✅ Database tables created successfully!")
            return True
            
        except Exception as e:
            print(f"❌ Failed to create tables: {e}")
            return False
    
    def _initialize_reference_data(self) -> bool:
        """Initialize reference data (quests, subcategories, patterns)"""
        try:
            if not self.SessionLocal:
                return False
            
            session = self.SessionLocal()
            
            # Initialize quests if not exists
            if session.query(Quest).count() == 0:
                print("📚 Initializing quest data...")
                self._init_quest_data(session)
            
            # Initialize SQL patterns if not exists
            if session.query(SQLPattern).count() == 0:
                print("🔍 Initializing SQL patterns...")
                self._init_pattern_data(session)
            
            session.commit()
            session.close()
            print("✅ Reference data initialized successfully!")
            return True
            
        except Exception as e:
            print(f"❌ Failed to initialize reference data: {e}")
            if session:
                session.rollback()
                session.close()
            return False
    
    def _init_quest_data(self, session: Session):
        """Initialize quest and subcategory data using dynamic discovery"""
        try:
            # Import quest discovery
            from .quest_discovery import QuestDiscoveryManager
            
            # Initialize quest discovery manager
            quests_dir = self.config.evaluation.quests_directory
            manager = QuestDiscoveryManager(quests_dir)
            
            # Discover quests from file system
            quests = manager.discover_and_validate()
            
            if not quests:
                print("⚠️  No quests discovered, using fallback data")
                quests_data = self._get_fallback_quest_data()
            else:
                # Convert discovered quests to database format
                quests_data = manager.get_quests_for_database(quests)
                print(f"✅ Discovered {len(quests_data)} quests from file system")
            
        except Exception as e:
            print(f"⚠️  Quest discovery failed: {e}, using fallback data")
            quests_data = self._get_fallback_quest_data()
        
        for quest_data in quests_data:
            subcategories = quest_data.pop('subcategories')
            
            quest = Quest(
                name=quest_data['name'],
                display_name=quest_data['display_name'],
                description=quest_data['description'],
                difficulty_level=quest_data['difficulty_level'],
                order_index=quest_data['order_index'],
                metadata=quest_data['metadata']
            )
            session.add(quest)
            session.flush()  # Get the quest ID
            
            for sub_name, sub_display, sub_difficulty, sub_order in subcategories:
                subcategory = Subcategory(
                    quest_id=quest.id,
                    name=sub_name,
                    display_name=sub_display,
                    description=f"Subcategory for {sub_display}",
                    difficulty_level=sub_difficulty,
                    order_index=sub_order,
                    metadata={
                        'parent_quest': quest.name,
                        'estimated_duration_minutes': 30
                    }
                )
                session.add(subcategory)
    
    def _get_fallback_quest_data(self) -> List[Dict[str, Any]]:
        """Get fallback quest data when discovery fails"""
        return [
            {
                'name': '1-data-modeling',
                'display_name': 'Data Modeling',
                'description': 'Database design principles, normalization patterns, and schema optimization',
                'difficulty_level': 'Beginner',
                'order_index': 1,
                'metadata': {
                    'category': 'fundamentals',
                    'estimated_duration_hours': 4,
                    'prerequisites': ['basic SQL knowledge'],
                    'source': 'fallback'
                },
                'subcategories': [
                    ('00-basic-concepts', 'Basic Concepts', 'Beginner', 0),
                    ('01-normalization-patterns', 'Normalization Patterns', 'Intermediate', 1),
                ]
            }
        ]
    
    def _init_pattern_data(self, session: Session):
        """Initialize SQL pattern catalog"""
        patterns_data = [
            # DDL Patterns
            ('table_creation', 'Table Creation', 'DDL', 'Beginner', 'CREATE TABLE'),
            ('table_modification', 'Table Modification', 'DDL', 'Intermediate', 'ALTER TABLE'),
            ('table_deletion', 'Table Deletion', 'DDL', 'Beginner', 'DROP TABLE'),
            ('index_creation', 'Index Creation', 'DDL', 'Intermediate', 'CREATE INDEX'),
            ('index_deletion', 'Index Deletion', 'DDL', 'Intermediate', 'DROP INDEX'),
            
            # DML Patterns
            ('data_insertion', 'Data Insertion', 'DML', 'Beginner', 'INSERT INTO'),
            ('data_update', 'Data Update', 'DML', 'Intermediate', 'UPDATE.*SET'),
            ('data_deletion', 'Data Deletion', 'DML', 'Intermediate', 'DELETE FROM'),
            
            # DQL Patterns
            ('data_querying', 'Data Querying', 'DQL', 'Beginner', 'SELECT.*FROM'),
            ('filtering', 'Filtering', 'DQL', 'Beginner', 'WHERE'),
            ('joining', 'Joining', 'DQL', 'Intermediate', 'JOIN'),
            ('aggregation', 'Aggregation', 'DQL', 'Intermediate', 'GROUP BY'),
            ('sorting', 'Sorting', 'DQL', 'Beginner', 'ORDER BY'),
            ('limiting', 'Limiting', 'DQL', 'Beginner', 'LIMIT'),
            ('distinct_operation', 'Distinct Operation', 'DQL', 'Beginner', 'DISTINCT'),
            ('group_filtering', 'Group Filtering', 'DQL', 'Intermediate', 'HAVING'),
            ('pagination', 'Pagination', 'DQL', 'Intermediate', 'OFFSET'),
            
            # Advanced Patterns
            ('common_table_expression', 'Common Table Expression', 'ADVANCED', 'Advanced', 'WITH.*AS'),
            ('recursive_cte', 'Recursive CTE', 'ADVANCED', 'Expert', 'WITH RECURSIVE'),
            ('window_functions', 'Window Functions', 'ADVANCED', 'Advanced', 'OVER\\('),
            ('json_operations', 'JSON Operations', 'ADVANCED', 'Advanced', 'JSON_'),
            ('existence_check', 'Existence Check', 'ADVANCED', 'Intermediate', 'EXISTS|NOT EXISTS'),
            ('membership_check', 'Membership Check', 'ADVANCED', 'Intermediate', 'IN|NOT IN'),
            ('set_operations', 'Set Operations', 'ADVANCED', 'Advanced', 'UNION|INTERSECT|EXCEPT'),
            ('conditional_logic', 'Conditional Logic', 'ADVANCED', 'Intermediate', 'CASE.*WHEN'),
            
            # Constraints
            ('primary_key', 'Primary Key', 'CONSTRAINT', 'Beginner', 'PRIMARY KEY'),
            ('foreign_key', 'Foreign Key', 'CONSTRAINT', 'Intermediate', 'FOREIGN KEY'),
            ('unique_constraint', 'Unique Constraint', 'CONSTRAINT', 'Intermediate', 'UNIQUE'),
            ('check_constraint', 'Check Constraint', 'CONSTRAINT', 'Advanced', 'CHECK'),
            ('not_null_constraint', 'Not Null Constraint', 'CONSTRAINT', 'Beginner', 'NOT NULL'),
            
            # Performance
            ('performance_analysis', 'Performance Analysis', 'PERFORMANCE', 'Advanced', 'EXPLAIN|ANALYZE'),
            ('maintenance', 'Maintenance', 'PERFORMANCE', 'Expert', 'VACUUM|REINDEX'),
        ]
        
        for pattern_name, display_name, category, complexity, regex in patterns_data:
            pattern = SQLPattern(
                name=pattern_name,
                display_name=display_name,
                description=f"Pattern for {display_name}",
                category=category,
                complexity_level=complexity,
                detection_regex=regex,
                config={
                    'detection_method': 'regex',
                    'confidence_threshold': 0.7,
                    'category': category.lower()
                }
            )
            session.add(pattern)
    
    def _verify_initialization(self) -> bool:
        """Verify that database initialization was successful"""
        try:
            if not self.SessionLocal:
                return False
            
            session = self.SessionLocal()
            
            # Check tables exist
            inspector = inspect(self.engine)
            required_tables = ['quests', 'subcategories', 'sql_files', 'sql_patterns', 'evaluations', 'evaluation_patterns', 'evaluation_sessions']
            
            existing_tables = inspector.get_table_names()
            missing_tables = [table for table in required_tables if table not in existing_tables]
            
            if missing_tables:
                print(f"❌ Missing tables: {missing_tables}")
                return False
            
            # Check reference data
            quest_count = session.query(Quest).count()
            pattern_count = session.query(SQLPattern).count()
            
            if quest_count == 0:
                print("❌ No quests found in database")
                return False
            
            if pattern_count == 0:
                print("❌ No SQL patterns found in database")
                return False
            
            print(f"✅ Verification passed: {quest_count} quests, {pattern_count} patterns")
            session.close()
            return True
            
        except Exception as e:
            print(f"❌ Verification failed: {e}")
            return False
    
    def get_session(self) -> Optional[Session]:
        """Get a database session"""
        if not self.SessionLocal:
            return None
        return self.SessionLocal()
    
    def close(self):
        """Close database connections"""
        if self.engine:
            self.engine.dispose()
    
    def check_health(self) -> Dict[str, Any]:
        """Check database health and status"""
        try:
            if not self.initialized:
                return {
                    'status': 'not_initialized',
                    'healthy': False,
                    'message': 'Database not initialized'
                }
            
            session = self.get_session()
            if not session:
                return {
                    'status': 'no_session',
                    'healthy': False,
                    'message': 'Cannot create database session'
                }
            
            # Test basic operations
            quest_count = session.query(Quest).count()
            pattern_count = session.query(SQLPattern).count()
            
            session.close()
            
            return {
                'status': 'healthy',
                'healthy': True,
                'message': 'Database is healthy',
                'quests': quest_count,
                'patterns': pattern_count,
                'initialized': self.initialized
            }
            
        except Exception as e:
            return {
                'status': 'error',
                'healthy': False,
                'message': f'Database health check failed: {e}',
                'initialized': self.initialized
            }
    
    # SQL Execution Methods
    async def execute_sql_file(self, file_path: str) -> Dict[str, Any]:
        """Execute SQL file and capture results"""
        try:
            # Read SQL content
            sql_content = Path(file_path).read_text()
            
            # Basic execution simulation (replace with actual execution)
            result = {
                'success': True,
                'output_lines': len(sql_content.split('\n')),
                'result_sets': sql_content.upper().count('SELECT'),
                'rows_affected': sql_content.upper().count('INSERT') + sql_content.upper().count('UPDATE') + sql_content.upper().count('DELETE'),
                'error_count': 0,
                'warning_count': 0,
                'execution_time_ms': 100,
                'raw_output': f"Executed {len(sql_content)} characters of SQL"
            }
            
            return result
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'output_lines': 0,
                'result_sets': 0,
                'rows_affected': 0,
                'error_count': 1,
                'warning_count': 0,
                'execution_time_ms': 0
            }
    
    # Evaluation Methods
    async def save_evaluation(self, evaluation_data: Dict[str, Any], sql_file_path: str) -> bool:
        """Save evaluation result to database"""
        try:
            session = self.get_session()
            if not session:
                return False
            
            # Create evaluation record
            evaluation = Evaluation(
                evaluation_uuid=evaluation_data.get('evaluation_uuid'),
                sql_file_id=1,  # TODO: Get actual SQL file ID
                quest_id=1,     # TODO: Get actual quest ID
                evaluation_version=evaluation_data.get('evaluation_version', '2.0'),
                evaluator_model=evaluation_data.get('evaluator_model', 'gpt-4o-mini'),
                evaluation_date=evaluation_data.get('evaluation_date', datetime.now()),
                overall_assessment=evaluation_data.get('overall_assessment', 'PASS'),
                numeric_score=evaluation_data.get('numeric_score', 8),
                letter_grade=evaluation_data.get('letter_grade', 'B'),
                execution_success=evaluation_data.get('execution_success', True),
                execution_time_ms=evaluation_data.get('execution_time_ms', 0),
                output_lines=evaluation_data.get('output_lines', 0),
                result_sets=evaluation_data.get('result_sets', 0),
                rows_affected=evaluation_data.get('rows_affected', 0),
                error_count=evaluation_data.get('error_count', 0),
                warning_count=evaluation_data.get('warning_count', 0),
                technical_analysis=evaluation_data.get('technical_analysis', {}),
                educational_analysis=evaluation_data.get('educational_analysis', {}),
                execution_details=evaluation_data.get('execution_details', {}),
                detected_patterns=evaluation_data.get('detected_patterns', {}),
                recommendations=evaluation_data.get('recommendations', []),
                metadata=evaluation_data.get('metadata', {})
            )
            
            session.add(evaluation)
            session.commit()
            session.close()
            
            return True
            
        except Exception as e:
            print(f"❌ Error saving evaluation: {e}")
            if session:
                session.rollback()
                session.close()
            return False
    
    def get_evaluation_history(self, quest_name: Optional[str] = None, limit: int = 10) -> List[Dict[str, Any]]:
        """Get evaluation history from database"""
        try:
            session = self.get_session()
            if not session:
                return []
            
            query = session.query(Evaluation)
            if quest_name:
                query = query.join(Quest).filter(Quest.name == quest_name)
            
            evaluations = query.order_by(Evaluation.evaluation_date.desc()).limit(limit).all()
            
            result = []
            for eval in evaluations:
                result.append({
                    'id': eval.id,
                    'evaluation_date': eval.evaluation_date.isoformat(),
                    'overall_assessment': eval.overall_assessment,
                    'numeric_score': eval.numeric_score,
                    'letter_grade': eval.letter_grade,
                    'evaluator_model': eval.evaluator_model
                })
            
            session.close()
            return result
            
        except Exception as e:
            print(f"❌ Error getting evaluation history: {e}")
            return []

async def main():
    """Test the unified database manager"""
    print("🔧 Testing Unified Database Manager")
    print("=" * 50)
    
    try:
        # Initialize database manager
        config = get_config()
        db_manager = DatabaseManager(config)
        
        # Initialize database
        if db_manager.initialize():
            print("✅ Database initialization successful!")
            
            # Check health
            health = db_manager.check_health()
            print(f"🏥 Database health: {health['status']}")
            
            if health['healthy']:
                print(f"📊 Database stats: {health['quests']} quests, {health['patterns']} patterns")
        else:
            print("❌ Database initialization failed!")
            return 1
        
        db_manager.close()
        return 0
        
    except Exception as e:
        print(f"❌ Database manager test failed: {e}")
        return 1

if __name__ == "__main__":
    exit_code = asyncio.run(main())
    import sys
    sys.exit(exit_code) 