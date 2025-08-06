#!/usr/bin/env python3
"""
Database ORM for SQL Adventure Evaluator
Handles SQL execution and result storage
"""

import os
import asyncio
from typing import Optional, Dict, Any, List
from datetime import datetime

from sqlalchemy import create_engine, text, MetaData, Table, Column, Integer, String, Text, DateTime, Boolean, Float
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import SQLAlchemyError
import asyncpg

Base = declarative_base()

class EvaluationRecord(Base):
    """Database model for storing evaluation results"""
    __tablename__ = 'evaluations'
    
    id = Column(Integer, primary_key=True)
    file_path = Column(String(500), nullable=False)
    quest_name = Column(String(100), nullable=False)
    filename = Column(String(200), nullable=False)
    generated_at = Column(DateTime, default=datetime.utcnow)
    
    # Basic evaluation data
    overall_assessment = Column(String(50), nullable=False)
    score = Column(Integer, nullable=False)
    grade = Column(String(10), nullable=False)
    
    # Technical analysis
    syntax_correctness = Column(Text)
    logical_structure = Column(Text)
    code_quality = Column(Text)
    performance_notes = Column(Text)
    
    # Educational analysis
    learning_value = Column(Text)
    difficulty_level = Column(String(50))
    time_estimate = Column(String(100))
    prerequisites = Column(Text)  # JSON string
    
    # Execution results
    execution_success = Column(Boolean, default=True)
    output_lines = Column(Integer, default=0)
    errors = Column(Integer, default=0)
    warnings = Column(Integer, default=0)
    result_sets = Column(Integer, default=0)
    raw_output = Column(Text)
    
    # SQL patterns
    sql_patterns = Column(Text)  # JSON string
    
    # Recommendations
    recommendations = Column(Text)  # JSON string
    
    # Full analysis (JSON)
    full_analysis = Column(Text)  # Complete JSON analysis

class DatabaseManager:
    """Manages database connections and operations"""
    
    def __init__(self, connection_string: Optional[str] = None):
        self.connection_string = connection_string or self._get_default_connection()
        self.engine = None
        self.SessionLocal = None
        self._setup_engine()
    
    def _get_default_connection(self) -> str:
        """Get default database connection string from environment"""
        host = os.getenv('DB_HOST', 'localhost')
        port = os.getenv('DB_PORT', '5432')
        user = os.getenv('DB_USER', 'postgres')
        password = os.getenv('DB_PASSWORD', 'postgres')
        database = os.getenv('DB_NAME', 'sql_adventure_db')
        
        return f"postgresql://{user}:{password}@{host}:{port}/{database}"
    
    def _setup_engine(self):
        """Setup SQLAlchemy engine and session"""
        try:
            self.engine = create_engine(self.connection_string)
            self.SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
            
            # Create tables
            Base.metadata.create_all(bind=self.engine)
            print("✅ Database connection established")
        except Exception as e:
            print(f"❌ Database connection failed: {e}")
            self.engine = None
            self.SessionLocal = None
    
    async def execute_sql_file(self, file_path: str) -> Dict[str, Any]:
        """Execute SQL file and capture results"""
        try:
            # Read SQL content
            with open(file_path, 'r') as f:
                sql_content = f.read()
            
            # Split into individual statements
            statements = [stmt.strip() for stmt in sql_content.split(';') if stmt.strip()]
            
            results = {
                'success': True,
                'output_lines': 0,
                'errors': 0,
                'warnings': 0,
                'result_sets': 0,
                'raw_output': '',
                'statements': []
            }
            
            # Execute each statement
            for i, statement in enumerate(statements):
                if not statement:
                    continue
                    
                try:
                    with self.engine.connect() as conn:
                        result = conn.execute(text(statement))
                        conn.commit()
                        
                        # Capture output
                        if result.returns_rows:
                            rows = result.fetchall()
                            results['result_sets'] += 1
                            results['raw_output'] += f"Statement {i+1}: {len(rows)} rows returned\n"
                            for row in rows[:5]:  # Limit output
                                results['raw_output'] += str(row) + "\n"
                        else:
                            results['raw_output'] += f"Statement {i+1}: {result.rowcount} rows affected\n"
                        
                        results['statements'].append({
                            'statement': statement,
                            'success': True,
                            'rowcount': result.rowcount if hasattr(result, 'rowcount') else 0
                        })
                        
                except SQLAlchemyError as e:
                    results['errors'] += 1
                    results['raw_output'] += f"Statement {i+1}: ERROR - {str(e)}\n"
                    results['statements'].append({
                        'statement': statement,
                        'success': False,
                        'error': str(e)
                    })
            
            results['output_lines'] = len(results['raw_output'].split('\n'))
            return results
            
        except Exception as e:
            return {
                'success': False,
                'output_lines': 0,
                'errors': 1,
                'warnings': 0,
                'result_sets': 0,
                'raw_output': f"Error executing SQL file: {e}",
                'statements': []
            }
    
    def save_evaluation(self, evaluation_data: Dict[str, Any]) -> bool:
        """Save evaluation result to database"""
        if not self.SessionLocal:
            print("❌ Database not connected")
            return False
        
        try:
            session = self.SessionLocal()
            
            # Create evaluation record
            record = EvaluationRecord(
                file_path=evaluation_data.get('metadata', {}).get('full_path', ''),
                quest_name=evaluation_data.get('metadata', {}).get('quest', ''),
                filename=evaluation_data.get('metadata', {}).get('file', ''),
                generated_at=datetime.fromisoformat(evaluation_data.get('metadata', {}).get('generated', datetime.now().isoformat())),
                
                # Basic evaluation
                overall_assessment=evaluation_data.get('llm_analysis', {}).get('assessment', {}).get('overall_assessment', 'UNKNOWN'),
                score=evaluation_data.get('llm_analysis', {}).get('assessment', {}).get('score', 0),
                grade=evaluation_data.get('llm_analysis', {}).get('assessment', {}).get('grade', 'F'),
                
                # Technical analysis
                syntax_correctness=evaluation_data.get('llm_analysis', {}).get('technical_analysis', {}).get('syntax_correctness', ''),
                logical_structure=evaluation_data.get('llm_analysis', {}).get('technical_analysis', {}).get('logical_structure', ''),
                code_quality=evaluation_data.get('llm_analysis', {}).get('technical_analysis', {}).get('code_quality', ''),
                performance_notes=evaluation_data.get('llm_analysis', {}).get('technical_analysis', {}).get('performance_notes', ''),
                
                # Educational analysis
                learning_value=evaluation_data.get('llm_analysis', {}).get('educational_analysis', {}).get('learning_value', ''),
                difficulty_level=evaluation_data.get('llm_analysis', {}).get('educational_analysis', {}).get('difficulty_level', ''),
                time_estimate=evaluation_data.get('llm_analysis', {}).get('educational_analysis', {}).get('time_estimate', ''),
                prerequisites=str(evaluation_data.get('llm_analysis', {}).get('educational_analysis', {}).get('prerequisites', [])),
                
                # Execution results
                execution_success=evaluation_data.get('execution', {}).get('success', False),
                output_lines=evaluation_data.get('execution', {}).get('output_lines', 0),
                errors=evaluation_data.get('execution', {}).get('errors', 0),
                warnings=evaluation_data.get('execution', {}).get('warnings', 0),
                result_sets=evaluation_data.get('execution', {}).get('result_sets', 0),
                raw_output=evaluation_data.get('execution', {}).get('raw_output', ''),
                
                # SQL patterns
                sql_patterns=str(evaluation_data.get('intent', {}).get('sql_patterns', [])),
                
                # Recommendations
                recommendations=str(evaluation_data.get('llm_analysis', {}).get('recommendations', [])),
                
                # Full analysis
                full_analysis=str(evaluation_data)
            )
            
            session.add(record)
            session.commit()
            session.close()
            
            print(f"✅ Evaluation saved to database: {record.filename}")
            return True
            
        except Exception as e:
            print(f"❌ Error saving evaluation to database: {e}")
            if session:
                session.rollback()
                session.close()
            return False
    
    def get_evaluation_history(self, quest_name: Optional[str] = None, limit: int = 10) -> List[Dict[str, Any]]:
        """Get evaluation history from database"""
        if not self.SessionLocal:
            return []
        
        try:
            session = self.SessionLocal()
            
            query = session.query(EvaluationRecord)
            if quest_name:
                query = query.filter(EvaluationRecord.quest_name == quest_name)
            
            records = query.order_by(EvaluationRecord.generated_at.desc()).limit(limit).all()
            
            results = []
            for record in records:
                results.append({
                    'id': record.id,
                    'file_path': record.file_path,
                    'quest_name': record.quest_name,
                    'filename': record.filename,
                    'generated_at': record.generated_at.isoformat(),
                    'overall_assessment': record.overall_assessment,
                    'score': record.score,
                    'grade': record.grade,
                    'difficulty_level': record.difficulty_level,
                    'execution_success': record.execution_success,
                    'errors': record.errors
                })
            
            session.close()
            return results
            
        except Exception as e:
            print(f"❌ Error retrieving evaluation history: {e}")
            return []
    
    def get_evaluation_stats(self) -> Dict[str, Any]:
        """Get evaluation statistics"""
        if not self.SessionLocal:
            return {}
        
        try:
            session = self.SessionLocal()
            
            total_evaluations = session.query(EvaluationRecord).count()
            successful_evaluations = session.query(EvaluationRecord).filter(EvaluationRecord.execution_success == True).count()
            failed_evaluations = session.query(EvaluationRecord).filter(EvaluationRecord.execution_success == False).count()
            
            # Average scores by quest
            quest_stats = {}
            quests = session.query(EvaluationRecord.quest_name).distinct().all()
            
            for quest in quests:
                quest_name = quest[0]
                avg_score = session.query(EvaluationRecord.score).filter(
                    EvaluationRecord.quest_name == quest_name
                ).all()
                
                if avg_score:
                    avg_score = sum(score[0] for score in avg_score) / len(avg_score)
                    quest_stats[quest_name] = {
                        'average_score': round(avg_score, 2),
                        'total_files': len(avg_score)
                    }
            
            session.close()
            
            return {
                'total_evaluations': total_evaluations,
                'successful_evaluations': successful_evaluations,
                'failed_evaluations': failed_evaluations,
                'success_rate': round(successful_evaluations / total_evaluations * 100, 2) if total_evaluations > 0 else 0,
                'quest_stats': quest_stats
            }
            
        except Exception as e:
            print(f"❌ Error retrieving evaluation stats: {e}")
            return {} 