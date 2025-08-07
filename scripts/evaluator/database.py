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
from urllib.parse import quote_plus

from sqlalchemy import create_engine, text, func, and_, or_
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.exc import SQLAlchemyError

from models import (
    Base, Quest, Subcategory, SQLFile, SQLPattern, SQLFilePattern,
    Evaluation, TechnicalAnalysis, EducationalAnalysis, ExecutionDetail,
    EvaluationPattern, Recommendation
)

class DatabaseManager:
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
        """Get database connection string from environment and URL-escape credentials"""
        host = os.getenv('DB_HOST', 'localhost')
        port = os.getenv('DB_PORT', '5432')
        user = quote_plus(os.getenv('DB_USER', 'postgres'))
        password = quote_plus(os.getenv('DB_PASSWORD', 'postgres'))
        
        if separate_db:
            database = os.getenv('EVALUATOR_DB_NAME', 'sql_adventure_db')
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
                conn.execute(text("COMMIT"))  # ensure we are outside of TX block

                db_name = self.connection_string.split('/')[-1]

                # Existence check (safe parameter binding)
                exists_q = text("SELECT 1 FROM pg_database WHERE datname = :dbname").bindparams(dbname=db_name)
                result = conn.execute(exists_q)

                if not result.fetchone():
                    # NOTE: Postgres does not allow database identifiers as bind-params; quote safely
                    safe_db = db_name.replace('"', '')  # basic sanitisation
                    conn.execute(text(f'CREATE DATABASE "{safe_db}"'))
                    print(f"✅ Created evaluator database: {safe_db}")
            
            temp_engine.dispose()
            
        except Exception as e:
            print(f"⚠️  Could not ensure database exists: {e}")
    
    def _initialize_data(self):
        """Seed database using dynamic discovery. Safe to run multiple times (idempotent)."""
        if not self.SessionLocal:
            return

        # Import here to avoid circular deps
        from init_database import (
            discover_quests_from_filesystem,
            discover_sql_patterns_from_filesystem,
        )

        try:
            session = self.SessionLocal()

            quests_data = discover_quests_from_filesystem()
            self._upsert_quests(session, quests_data)

            patterns_data = discover_sql_patterns_from_filesystem()
            self._upsert_patterns(session, patterns_data)

            session.commit()

        except Exception as e:
            session.rollback()
            print(f"❌ Failed to initialize data: {e}")
            raise

        finally:
            session.close()

    # ------------------------------------------------------------------
    # Dynamic upsert helpers
    # ------------------------------------------------------------------
    def _upsert_quests(self, session: Session, quests_data: List[Dict[str, Any]]):
        """Insert or update quests & subcategories from discovered dataset."""
        for quest_data in quests_data:
            subcategories = quest_data.pop('subcategories', [])

            quest = session.query(Quest).filter_by(name=quest_data['name']).first()
            if not quest:
                quest = Quest(**quest_data)
                session.add(quest)
                session.flush()
            else:
                for k, v in quest_data.items():
                    setattr(quest, k, v)

            # Upsert subcategories
            for sub_name, sub_display, sub_difficulty, sub_order in subcategories:
                subcat = session.query(Subcategory).filter_by(
                    quest_id=quest.id,
                    name=sub_name
                ).first()

                if not subcat:
                    subcat = Subcategory(
                        quest_id=quest.id,
                        name=sub_name,
                        display_name=sub_display,
                        difficulty_level=sub_difficulty,
                        order_index=sub_order,
                    )
                    session.add(subcat)
                else:
                    subcat.display_name = sub_display
                    subcat.difficulty_level = sub_difficulty
                    subcat.order_index = sub_order

    def _upsert_patterns(self, session: Session, patterns_data: List[Tuple[str, str, str, str, str]]):
        """Insert or update SQL pattern catalogue."""
        for pattern_name, display_name, category, complexity, regex in patterns_data:
            pattern = session.query(SQLPattern).filter_by(name=pattern_name).first()
            if not pattern:
                pattern = SQLPattern(
                    name=pattern_name,
                    display_name=display_name,
                    category=category,
                    complexity_level=complexity,
                    detection_regex=regex,
                )
                session.add(pattern)
            else:
                pattern.display_name = display_name
                pattern.category = category
                pattern.complexity_level = complexity
                pattern.detection_regex = regex
    
    def get_or_create_sql_file(self, file_path: str) -> Optional[SQLFile]:
        """Return a SQLFile row, inserting/updating metadata as required."""
        if not self.SessionLocal:
            return None

        try:
            session = self.SessionLocal()

            file_hash = self._calculate_file_hash(file_path)
            sql_file = session.query(SQLFile).filter(SQLFile.file_path == file_path).first()

            if sql_file:
                # If the hash changed we need to refresh metadata & patterns
                if sql_file.content_hash != file_hash:
                    sql_file.content_hash = file_hash
                    sql_file.last_modified = datetime.utcnow()

                    # Clear existing associations
                    session.query(SQLFilePattern).filter_by(sql_file_id=sql_file.id).delete()
                    self._detect_and_associate_patterns(session, sql_file, file_path)

                session.commit()
                return sql_file

            # New file – derive quest & subcategory
            path_obj = Path(file_path)
            filename = path_obj.name

            quest_name = None
            subcategory_name = None

            import re as _re
            for idx, part in enumerate(path_obj.parts):
                if _re.match(r'^\d+-', part):
                    quest_name = part
                    if idx + 1 < len(path_obj.parts):
                        subcategory_name = path_obj.parts[idx + 1]
                    break

            if not quest_name or not subcategory_name:
                raise ValueError(f"Could not determine quest/subcategory for file path: {file_path}")

            quest = session.query(Quest).filter_by(name=quest_name).first()
            if not quest:
                raise ValueError(f"Quest '{quest_name}' not found in DB. Seed first.")

            subcategory = session.query(Subcategory).filter(
                and_(Subcategory.quest_id == quest.id, Subcategory.name == subcategory_name)
            ).first()

            if not subcategory:
                raise ValueError(f"Subcategory '{subcategory_name}' not found for quest '{quest_name}'")

            sql_file = SQLFile(
                subcategory_id=subcategory.id,
                filename=filename,
                file_path=file_path,
                display_name=self._generate_display_name(filename),
                content_hash=file_hash,
            )

            session.add(sql_file)
            session.flush()  # Get id for associations

            self._detect_and_associate_patterns(session, sql_file, file_path)

            session.commit()
            return sql_file

        except Exception as e:
            print(f"❌ Error creating/updating SQL file record: {e}")
            raise

        finally:
            if 'session' in locals():
                session.close()
    
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

            # Split into individual statements (basic splitter; does not account for PL/pgSQL)
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

            # Use single connection/transaction for entire file for consistency & performance
            with self.engine.begin() as conn:
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
                        result = conn.execute(text(statement))

                        stmt_end = datetime.now()
                        stmt_result['execution_time_ms'] = int((stmt_end - stmt_start).total_seconds() * 1000)
                        stmt_result['success'] = True

                        if result.returns_rows:
                            rows = result.fetchall()
                            stmt_result['rows_returned'] = len(rows)
                            results['result_sets'] += 1
                            results['raw_output'] += f"Statement {i+1}: {len(rows)} rows returned\n"
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
    
    def save_evaluation_with_session(self, session: Session, evaluation_data: Dict[str, Any], sql_file: SQLFile) -> Optional[Evaluation]:
        """Save evaluation using an existing session (for better session management)"""
        try:
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
                    prerequisite_knowledge=', '.join(edu_analysis.get('prerequisites', [])),
                    clarity_score=self._extract_score_from_text(edu_analysis.get('learning_value', '')),
                    relevance_score=8,  # Default reasonable score
                    engagement_score=7,  # Default reasonable score
                    progression_score=6   # Default reasonable score
                )
                session.add(educational)
            
            # Save recommendations
            recommendations = evaluation_data.get('llm_analysis', {}).get('recommendations', [])
            for i, rec_text in enumerate(recommendations):
                recommendation = Recommendation(
                    evaluation_id=evaluation.id,
                    category=self._categorize_recommendation(rec_text),
                    priority='Medium',
                    recommendation_text=rec_text,
                    implementation_effort='Medium',
                    expected_impact='Medium'
                )
                session.add(recommendation)
            
            return evaluation
            
        except Exception as e:
            print(f"❌ Error saving evaluation with session: {e}")
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