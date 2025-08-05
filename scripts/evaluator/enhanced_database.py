#!/usr/bin/env python3
"""
Enhanced Database Manager for SQL Adventure AI Evaluator
Uses normalized schema with proper relationships and analytics
"""

import os
import hashlib
import asyncio
from typing import Optional, Dict, Any, List, Tuple
from datetime import datetime, timedelta
from pathlib import Path

from sqlalchemy import create_engine, text, func, and_, or_
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.exc import SQLAlchemyError, IntegrityError
from sqlalchemy.dialects.postgresql import insert

from .models import (
    Base, Quest, Subcategory, SQLFile, SQLPattern, SQLFilePattern,
    Evaluation, TechnicalAnalysis, EducationalAnalysis, ExecutionDetail,
    EvaluationPattern, Recommendation, EvaluationSession
)

class EnhancedDatabaseManager:
    """Enhanced database manager with normalized schema and analytics"""
    
    def __init__(self, connection_string: Optional[str] = None, separate_db: bool = True):
        """
        Initialize database manager
        
        Args:
            connection_string: Database connection string
            separate_db: Whether to use a separate database for evaluations
        """
        self.connection_string = connection_string or self._get_connection_string(separate_db)
        self.engine = None
        self.SessionLocal = None
        self.separate_db = separate_db
        self._setup_engine()
        self._initialize_data()
    
    def _get_connection_string(self, separate_db: bool = True) -> str:
        """Get database connection string from environment"""
        host = os.getenv('DB_HOST', 'localhost')
        port = os.getenv('DB_PORT', '5432')
        user = os.getenv('DB_USER', 'postgres')
        password = os.getenv('DB_PASSWORD', 'postgres')
        
        if separate_db:
            database = os.getenv('EVALUATOR_DB_NAME', 'sql_adventure_evaluator')
        else:
            database = os.getenv('DB_NAME', 'sql_adventure_db')
        
        return f"postgresql://{user}:{password}@{host}:{port}/{database}"
    
    def _setup_engine(self):
        """Setup SQLAlchemy engine and session"""
        try:
            self.engine = create_engine(
                self.connection_string,
                pool_size=10,
                max_overflow=20,
                pool_pre_ping=True,
                echo=False  # Set to True for SQL debugging
            )
            self.SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
            
            # Create database if it doesn't exist (for separate database)
            if self.separate_db:
                self._ensure_database_exists()
            
            # Create all tables
            Base.metadata.create_all(bind=self.engine)
            print("✅ Enhanced database connection established")
            
        except Exception as e:
            print(f"❌ Database connection failed: {e}")
            self.engine = None
            self.SessionLocal = None
    
    def _ensure_database_exists(self):
        """Ensure the evaluator database exists"""
        try:
            # Connect to default postgres database to create evaluator database
            base_connection = self.connection_string.rsplit('/', 1)[0] + '/postgres'
            temp_engine = create_engine(base_connection)
            
            with temp_engine.connect() as conn:
                conn.execute(text("COMMIT"))  # End any existing transaction
                
                # Check if database exists
                db_name = self.connection_string.split('/')[-1]
                result = conn.execute(text(
                    f"SELECT 1 FROM pg_database WHERE datname = '{db_name}'"
                ))
                
                if not result.fetchone():
                    conn.execute(text(f"CREATE DATABASE {db_name}"))
                    print(f"✅ Created evaluator database: {db_name}")
            
            temp_engine.dispose()
            
        except Exception as e:
            print(f"⚠️  Could not ensure database exists: {e}")
    
    def _initialize_data(self):
        """Initialize reference data (quests, subcategories, patterns)"""
        if not self.SessionLocal:
            return
        
        try:
            session = self.SessionLocal()
            
            # Initialize quests if not exists
            if session.query(Quest).count() == 0:
                self._init_quest_data(session)
            
            # Initialize SQL patterns if not exists
            if session.query(SQLPattern).count() == 0:
                self._init_pattern_data(session)
            
            session.commit()
            session.close()
            
        except Exception as e:
            print(f"⚠️  Error initializing reference data: {e}")
            session.rollback()
            session.close()
    
    def _init_quest_data(self, session: Session):
        """Initialize quest and subcategory data"""
        quests_data = [
            {
                'name': '1-data-modeling',
                'display_name': 'Data Modeling',
                'description': 'Database design principles, normalization patterns, and schema optimization',
                'difficulty_level': 'Beginner',
                'order_index': 1,
                'subcategories': [
                    ('00-basic-concepts', 'Basic Concepts', 'Beginner', 0),
                    ('01-normalization-patterns', 'Normalization Patterns', 'Intermediate', 1),
                    ('02-denormalization-strategies', 'Denormalization Strategies', 'Advanced', 2),
                    ('03-schema-design-principles', 'Schema Design Principles', 'Intermediate', 3),
                    ('04-real-world-applications', 'Real World Applications', 'Advanced', 4),
                ]
            },
            {
                'name': '2-performance-tuning',
                'display_name': 'Performance Tuning',
                'description': 'Query optimization, indexing strategies, and performance analysis',
                'difficulty_level': 'Intermediate',
                'order_index': 2,
                'subcategories': [
                    ('00-indexing-basics', 'Indexing Basics', 'Beginner', 0),
                    ('01-query-optimization', 'Query Optimization', 'Intermediate', 1),
                    ('02-execution-plans', 'Execution Plans', 'Advanced', 2),
                    ('03-advanced-techniques', 'Advanced Techniques', 'Expert', 3),
                ]
            },
            {
                'name': '3-window-functions',
                'display_name': 'Window Functions',
                'description': 'Advanced analytics and ranking operations using window functions',
                'difficulty_level': 'Advanced',
                'order_index': 3,
                'subcategories': [
                    ('00-ranking-functions', 'Ranking Functions', 'Intermediate', 0),
                    ('01-aggregate-functions', 'Aggregate Functions', 'Intermediate', 1),
                    ('02-navigation-functions', 'Navigation Functions', 'Advanced', 2),
                    ('03-complex-analytics', 'Complex Analytics', 'Expert', 3),
                ]
            },
            {
                'name': '4-json-operations',
                'display_name': 'JSON Operations',
                'description': 'Modern PostgreSQL JSON features and operations',
                'difficulty_level': 'Advanced',
                'order_index': 4,
                'subcategories': [
                    ('00-json-basics', 'JSON Basics', 'Intermediate', 0),
                    ('01-json-queries', 'JSON Queries', 'Advanced', 1),
                    ('02-json-aggregation', 'JSON Aggregation', 'Advanced', 2),
                    ('03-json-indexing', 'JSON Indexing', 'Expert', 3),
                ]
            },
            {
                'name': '5-recursive-cte',
                'display_name': 'Recursive CTEs',
                'description': 'Hierarchical data and recursive query patterns',
                'difficulty_level': 'Expert',
                'order_index': 5,
                'subcategories': [
                    ('00-cte-basics', 'CTE Basics', 'Intermediate', 0),
                    ('01-simple-recursion', 'Simple Recursion', 'Advanced', 1),
                    ('02-complex-hierarchies', 'Complex Hierarchies', 'Expert', 2),
                    ('03-advanced-patterns', 'Advanced Patterns', 'Expert', 3),
                ]
            }
        ]
        
        for quest_data in quests_data:
            subcategories_data = quest_data.pop('subcategories')
            
            quest = Quest(**quest_data)
            session.add(quest)
            session.flush()  # Get the quest ID
            
            for subcat_name, subcat_display, subcat_difficulty, subcat_order in subcategories_data:
                subcategory = Subcategory(
                    quest_id=quest.id,
                    name=subcat_name,
                    display_name=subcat_display,
                    difficulty_level=subcat_difficulty,
                    order_index=subcat_order
                )
                session.add(subcategory)
    
    def _init_pattern_data(self, session: Session):
        """Initialize SQL pattern definitions"""
        patterns_data = [
            # DDL Patterns
            ('table_creation', 'Table Creation', 'CREATE TABLE statements', 'DDL', 'Basic', r'CREATE\s+TABLE'),
            ('table_alteration', 'Table Alteration', 'ALTER TABLE statements', 'DDL', 'Intermediate', r'ALTER\s+TABLE'),
            ('index_creation', 'Index Creation', 'CREATE INDEX statements', 'DDL', 'Intermediate', r'CREATE\s+INDEX'),
            ('view_creation', 'View Creation', 'CREATE VIEW statements', 'DDL', 'Intermediate', r'CREATE\s+VIEW'),
            
            # DML Patterns
            ('data_insertion', 'Data Insertion', 'INSERT INTO statements', 'DML', 'Basic', r'INSERT\s+INTO'),
            ('data_update', 'Data Update', 'UPDATE statements', 'DML', 'Basic', r'UPDATE\s+\w+\s+SET'),
            ('data_deletion', 'Data Deletion', 'DELETE statements', 'DML', 'Basic', r'DELETE\s+FROM'),
            ('bulk_operations', 'Bulk Operations', 'Bulk insert/update operations', 'DML', 'Intermediate', r'VALUES\s*\(.*\),\s*\('),
            
            # DQL Patterns
            ('basic_select', 'Basic Select', 'Simple SELECT statements', 'DQL', 'Basic', r'SELECT\s+\*?\s+FROM'),
            ('complex_select', 'Complex Select', 'Complex SELECT with multiple clauses', 'DQL', 'Intermediate', r'SELECT.*WHERE.*ORDER BY'),
            ('subqueries', 'Subqueries', 'Nested SELECT statements', 'DQL', 'Intermediate', r'SELECT.*\(.*SELECT'),
            ('joins', 'Table Joins', 'JOIN operations', 'DQL', 'Intermediate', r'(INNER|LEFT|RIGHT|FULL)\s+JOIN'),
            
            # Aggregation and Analytics
            ('grouping', 'Grouping', 'GROUP BY operations', 'DQL', 'Intermediate', r'GROUP\s+BY'),
            ('aggregation', 'Aggregation', 'Aggregate functions', 'ANALYTICS', 'Intermediate', r'(COUNT|SUM|AVG|MIN|MAX)\s*\('),
            ('window_functions', 'Window Functions', 'Window function operations', 'ANALYTICS', 'Advanced', r'OVER\s*\('),
            ('ranking', 'Ranking Functions', 'ROW_NUMBER, RANK, DENSE_RANK', 'ANALYTICS', 'Advanced', r'(ROW_NUMBER|RANK|DENSE_RANK)\s*\('),
            
            # Advanced Patterns
            ('cte_basic', 'Common Table Expressions', 'WITH clauses', 'DQL', 'Advanced', r'WITH\s+\w+\s+AS'),
            ('recursive_cte', 'Recursive CTEs', 'Recursive WITH clauses', 'RECURSIVE', 'Expert', r'WITH\s+RECURSIVE'),
            ('json_operations', 'JSON Operations', 'JSON functions and operators', 'JSON', 'Advanced', r'(JSON_|->|->|#>|#>>|\?\||\?&)'),
            ('json_path', 'JSON Path', 'JSON path expressions', 'JSON', 'Expert', r'jsonb_path_'),
            
            # Performance Patterns
            ('explain_analyze', 'Query Analysis', 'EXPLAIN ANALYZE statements', 'DCL', 'Intermediate', r'EXPLAIN\s+(ANALYZE\s+)?'),
            ('index_hints', 'Index Hints', 'Index usage hints', 'DCL', 'Advanced', r'USING\s+INDEX'),
            
            # Transaction Control
            ('transactions', 'Transactions', 'BEGIN/COMMIT/ROLLBACK', 'TCL', 'Basic', r'(BEGIN|COMMIT|ROLLBACK)'),
            ('savepoints', 'Savepoints', 'SAVEPOINT operations', 'TCL', 'Intermediate', r'SAVEPOINT'),
        ]
        
        for name, display_name, description, category, complexity, regex in patterns_data:
            pattern = SQLPattern(
                name=name,
                display_name=display_name,
                description=description,
                category=category,
                complexity_level=complexity,
                detection_regex=regex
            )
            session.add(pattern)
    
    def get_or_create_sql_file(self, file_path: str) -> Optional[SQLFile]:
        """Get existing SQL file record or create new one"""
        if not self.SessionLocal:
            return None
        
        try:
            session = self.SessionLocal()
            
            # Check if file already exists
            sql_file = session.query(SQLFile).filter(SQLFile.file_path == file_path).first()
            
            if sql_file:
                # Update last_modified
                sql_file.last_modified = datetime.utcnow()
                session.commit()
                session.close()
                return sql_file
            
            # Create new file record
            path_obj = Path(file_path)
            filename = path_obj.name
            
            # Extract quest and subcategory from path
            parts = path_obj.parts
            if len(parts) >= 3 and parts[-3].startswith(('1-', '2-', '3-', '4-', '5-')):
                quest_name = parts[-3]
                subcategory_name = parts[-2]
                
                # Find quest and subcategory
                quest = session.query(Quest).filter(Quest.name == quest_name).first()
                if quest:
                    subcategory = session.query(Subcategory).filter(
                        and_(Subcategory.quest_id == quest.id, Subcategory.name == subcategory_name)
                    ).first()
                    
                    if subcategory:
                        # Calculate content hash
                        content_hash = self._calculate_file_hash(file_path)
                        
                        sql_file = SQLFile(
                            subcategory_id=subcategory.id,
                            filename=filename,
                            file_path=file_path,
                            display_name=self._generate_display_name(filename),
                            content_hash=content_hash
                        )
                        
                        session.add(sql_file)
                        session.commit()
                        
                        # Detect and associate patterns
                        self._detect_and_associate_patterns(session, sql_file, file_path)
                        
                        session.commit()
                        session.close()
                        return sql_file
            
            session.close()
            return None
            
        except Exception as e:
            print(f"❌ Error creating SQL file record: {e}")
            session.rollback()
            session.close()
            return None
    
    def _calculate_file_hash(self, file_path: str) -> str:
        """Calculate SHA-256 hash of file content"""
        try:
            with open(file_path, 'rb') as f:
                content = f.read()
                return hashlib.sha256(content).hexdigest()
        except Exception:
            return ""
    
    def _generate_display_name(self, filename: str) -> str:
        """Generate human-readable display name from filename"""
        name = filename.replace('.sql', '').replace('-', ' ').replace('_', ' ')
        return ' '.join(word.capitalize() for word in name.split())
    
    def _detect_and_associate_patterns(self, session: Session, sql_file: SQLFile, file_path: str):
        """Detect SQL patterns in file and create associations"""
        try:
            with open(file_path, 'r') as f:
                content = f.read().upper()
            
            patterns = session.query(SQLPattern).all()
            
            for pattern in patterns:
                if pattern.detection_regex:
                    import re
                    if re.search(pattern.detection_regex, content, re.IGNORECASE | re.MULTILINE):
                        # Check if association already exists
                        existing = session.query(SQLFilePattern).filter(
                            and_(
                                SQLFilePattern.sql_file_id == sql_file.id,
                                SQLFilePattern.pattern_id == pattern.id
                            )
                        ).first()
                        
                        if not existing:
                            file_pattern = SQLFilePattern(
                                sql_file_id=sql_file.id,
                                pattern_id=pattern.id,
                                confidence_score=0.9  # Basic regex detection confidence
                            )
                            session.add(file_pattern)
        
        except Exception as e:
            print(f"⚠️  Error detecting patterns: {e}")
    
    async def execute_sql_file(self, file_path: str) -> Dict[str, Any]:
        """Execute SQL file and capture detailed results"""
        try:
            # Read SQL content
            with open(file_path, 'r') as f:
                sql_content = f.read()
            
            # Split into individual statements
            statements = [stmt.strip() for stmt in sql_content.split(';') if stmt.strip()]
            
            results = {
                'success': True,
                'execution_time_ms': 0,
                'output_lines': 0,
                'result_sets': 0,
                'rows_affected': 0,
                'error_count': 0,
                'warning_count': 0,
                'raw_output': '',
                'statement_results': []
            }
            
            start_time = datetime.now()
            
            # Execute each statement
            for i, statement in enumerate(statements):
                if not statement:
                    continue
                
                stmt_start = datetime.now()
                stmt_result = {
                    'order': i + 1,
                    'statement': statement,
                    'success': False,
                    'execution_time_ms': 0,
                    'rows_affected': 0,
                    'rows_returned': 0,
                    'error_message': None,
                    'warning_message': None
                }
                
                try:
                    with self.engine.connect() as conn:
                        result = conn.execute(text(statement))
                        conn.commit()
                        
                        stmt_end = datetime.now()
                        stmt_result['execution_time_ms'] = int((stmt_end - stmt_start).total_seconds() * 1000)
                        stmt_result['success'] = True
                        
                        # Capture output
                        if result.returns_rows:
                            rows = result.fetchall()
                            stmt_result['rows_returned'] = len(rows)
                            results['result_sets'] += 1
                            results['raw_output'] += f"Statement {i+1}: {len(rows)} rows returned\n"
                            
                            # Limit output for performance
                            for row in rows[:5]:
                                results['raw_output'] += str(row) + "\n"
                            if len(rows) > 5:
                                results['raw_output'] += f"... and {len(rows) - 5} more rows\n"
                        else:
                            stmt_result['rows_affected'] = result.rowcount if hasattr(result, 'rowcount') else 0
                            results['rows_affected'] += stmt_result['rows_affected']
                            results['raw_output'] += f"Statement {i+1}: {stmt_result['rows_affected']} rows affected\n"
                        
                except SQLAlchemyError as e:
                    stmt_end = datetime.now()
                    stmt_result['execution_time_ms'] = int((stmt_end - stmt_start).total_seconds() * 1000)
                    stmt_result['error_message'] = str(e)
                    results['error_count'] += 1
                    results['success'] = False
                    results['raw_output'] += f"Statement {i+1}: ERROR - {str(e)}\n"
                
                results['statement_results'].append(stmt_result)
            
            end_time = datetime.now()
            results['execution_time_ms'] = int((end_time - start_time).total_seconds() * 1000)
            results['output_lines'] = len(results['raw_output'].split('\n'))
            
            return results
            
        except Exception as e:
            return {
                'success': False,
                'execution_time_ms': 0,
                'output_lines': 0,
                'result_sets': 0,
                'rows_affected': 0,
                'error_count': 1,
                'warning_count': 0,
                'raw_output': f"Error executing SQL file: {e}",
                'statement_results': []
            }
    
    def save_evaluation(self, evaluation_data: Dict[str, Any], sql_file: SQLFile) -> Optional[Evaluation]:
        """Save comprehensive evaluation result to normalized database"""
        if not self.SessionLocal:
            return None
        
        try:
            session = self.SessionLocal()
            
            # Create main evaluation record
            evaluation = Evaluation(
                sql_file_id=sql_file.id,
                quest_id=sql_file.subcategory.quest_id,
                evaluation_version='2.0',
                evaluator_model=evaluation_data.get('evaluator_model', 'gpt-4o-mini'),
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
            
            session.add(evaluation)
            session.flush()  # Get evaluation ID
            
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
                    clarity_score=self._extract_score_from_text(edu_analysis.get('learning_value', '')),
                    relevance_score=8,  # Default for now
                    engagement_score=7,  # Default for now
                    progression_score=8   # Default for now
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
            
            session.commit()
            print(f"✅ Enhanced evaluation saved: {sql_file.filename}")
            session.close()
            return evaluation
            
        except Exception as e:
            print(f"❌ Error saving enhanced evaluation: {e}")
            session.rollback()
            session.close()
            return None
    
    def _extract_score_from_text(self, text: str) -> int:
        """Extract numeric score from analysis text"""
        import re
        # Look for patterns like "8/10", "score: 8", "8 out of 10"
        patterns = [
            r'(\d+)/10',
            r'score:?\s*(\d+)',
            r'(\d+)\s*out\s*of\s*10',
            r'rating:?\s*(\d+)'
        ]
        
        for pattern in patterns:
            match = re.search(pattern, text.lower())
            if match:
                score = int(match.group(1))
                return max(1, min(10, score))  # Clamp to 1-10 range
        
        return 5  # Default score
    
    def _extract_time_from_text(self, text: str) -> int:
        """Extract time estimate in minutes from text"""
        import re
        patterns = [
            r'(\d+)\s*min',
            r'(\d+)\s*minutes?',
            r'(\d+)\s*hrs?\s*(\d+)\s*min',  # "2 hrs 30 min"
            r'(\d+)\s*hours?'
        ]
        
        for pattern in patterns:
            match = re.search(pattern, text.lower())
            if match:
                if len(match.groups()) == 2:  # Hours and minutes
                    hours = int(match.group(1))
                    minutes = int(match.group(2))
                    return hours * 60 + minutes
                else:
                    value = int(match.group(1))
                    if 'hour' in text.lower():
                        return value * 60
                    else:
                        return value
        
        return 15  # Default 15 minutes
    
    def _categorize_recommendation(self, rec_text: str) -> str:
        """Categorize recommendation based on content"""
        text_lower = rec_text.lower()
        
        if any(word in text_lower for word in ['performance', 'optimize', 'index', 'query plan']):
            return 'Performance'
        elif any(word in text_lower for word in ['syntax', 'format', 'style', 'convention']):
            return 'Syntax'
        elif any(word in text_lower for word in ['best practice', 'standard', 'guideline']):
            return 'Best Practices'
        elif any(word in text_lower for word in ['security', 'injection', 'privilege']):
            return 'Security'
        elif any(word in text_lower for word in ['maintainability', 'readable', 'documentation']):
            return 'Maintainability'
        else:
            return 'General'
    
    def get_evaluation_analytics(self, quest_name: Optional[str] = None, 
                               days: int = 30) -> Dict[str, Any]:
        """Get comprehensive evaluation analytics"""
        if not self.SessionLocal:
            return {}
        
        try:
            session = self.SessionLocal()
            
            # Base query
            query = session.query(Evaluation)
            if quest_name:
                quest = session.query(Quest).filter(Quest.name == quest_name).first()
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
            for eval in evaluations:
                grade = eval.letter_grade
                score_distribution[grade] = score_distribution.get(grade, 0) + 1
            
            # Quest performance
            quest_performance = {}
            for eval in evaluations:
                quest_name = eval.quest.name
                if quest_name not in quest_performance:
                    quest_performance[quest_name] = {
                        'total': 0,
                        'successful': 0,
                        'avg_score': 0,
                        'scores': []
                    }
                quest_performance[quest_name]['total'] += 1
                quest_performance[quest_name]['scores'].append(eval.numeric_score)
                if eval.execution_success:
                    quest_performance[quest_name]['successful'] += 1
            
            # Calculate averages
            for quest_data in quest_performance.values():
                quest_data['avg_score'] = sum(quest_data['scores']) / len(quest_data['scores'])
                quest_data['success_rate'] = quest_data['successful'] / quest_data['total'] * 100
                del quest_data['scores']  # Remove raw scores
            
            # Pattern analysis
            pattern_usage = session.query(
                SQLPattern.name,
                SQLPattern.display_name,
                func.count(EvaluationPattern.id).label('usage_count'),
                func.avg(EvaluationPattern.confidence_score).label('avg_confidence')
            ).join(EvaluationPattern).join(Evaluation).filter(
                Evaluation.evaluation_date >= cutoff_date
            ).group_by(SQLPattern.id, SQLPattern.name, SQLPattern.display_name).all()
            
            session.close()
            
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
        if not self.SessionLocal:
            return []
        
        try:
            session = self.SessionLocal()
            
            sql_file = session.query(SQLFile).filter(SQLFile.file_path == file_path).first()
            if not sql_file:
                return []
            
            evaluations = session.query(Evaluation).filter(
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
            
            session.close()
            return results
            
        except Exception as e:
            print(f"❌ Error retrieving file evaluation history: {e}")
            return []