import os
import hashlib
import asyncio
from typing import Optional, Dict, Any, List, Tuple
from datetime import datetime
from pathlib import Path

import asyncpg
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import SQLAlchemyError
from .utils import get_evaluator_connection_string, get_quests_connection_string

class DatabaseManager:
    def __init__(self, base=None, connection_string: Optional[str] = None, database_type: str = "evaluator"):
        """
        Initialize database manager
        
        Args:
            base: SQLAlchemy base class (None for quests database - execution sandbox only)
            connection_string: Override connection string (optional)
            database_type: "evaluator" for metadata storage, "quests" for SQL execution
        """
        if connection_string:
            self.connection_string = connection_string
        elif database_type == "evaluator":
            self.connection_string = get_evaluator_connection_string()
        elif database_type == "quests":
            self.connection_string = get_quests_connection_string()
        else:
            raise ValueError(f"Invalid database_type: {database_type}")
            
        self.base = base
        self.database_type = database_type
        self.engine = None
        self.SessionLocal = None
        self._db_pool = None
        self.use_pool = os.getenv("USE_ASYNC_POOL", "false").lower() == "true"
        self.atomic = os.getenv("ATOMIC_EXECUTION", "true").lower() == "true"
        self.detailed = os.getenv("DETAILED_LOGGING", "false").lower() == "true"
        self._setup_engine()

    async def _get_db_pool(self):
        if self._db_pool is None:
            self._db_pool = await asyncpg.create_pool(
                dsn=self.connection_string,
                min_size=1,
                max_size=5
            )
        return self._db_pool

    def _setup_engine(self):
        try:
            self.engine = create_engine(
                self.connection_string,
                pool_size=10,
                max_overflow=20,
                pool_pre_ping=True,
                echo=False
            )
            self.SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)

            self._ensure_database_exists()
            
            # Only create tables if base is provided (evaluator database)
            if self.base is not None:
                self.base.metadata.create_all(bind=self.engine)
            
            db_name = self.connection_string.split('/')[-1]
            db_type = "metadata" if self.base is not None else "execution sandbox"
            print(f"✅ Database connection established: {db_name} ({db_type})")
        except Exception as e:
            print(f"❌ Database connection failed: {e}")
            self.engine = None
            self.SessionLocal = None

    def _ensure_database_exists(self):
        try:
            base_connection = self.connection_string.rsplit('/', 1)[0] + '/postgres'
            temp_engine = create_engine(base_connection)
            with temp_engine.connect() as conn:
                conn.execute(text("COMMIT"))
                db_name = self.connection_string.split('/')[-1]
                result = conn.execute(text(f"SELECT 1 FROM pg_database WHERE datname = :db"), {'db': db_name})
                if not result.fetchone():
                    conn.execute(text(f"CREATE DATABASE {db_name}"))
                    print(f"✅ Created evaluator database: {db_name}")
            temp_engine.dispose()
        except Exception as e:
            print(f"⚠️  Could not ensure database exists: {e}")

    def drop_all_tables(self):
        """
        Drop all tables in the current database.
        Generic utility method - caller decides when to use it.
        """
        try:
            with self.engine.connect() as conn:
                # Get all table names in the current database
                result = conn.execute(text("""
                    SELECT tablename 
                    FROM pg_tables 
                    WHERE schemaname = 'public'
                """))
                tables = [row[0] for row in result.fetchall()]
                
                if tables:
                    # Drop all tables (CASCADE to handle dependencies)
                    for table in tables:
                        conn.execute(text(f"DROP TABLE IF EXISTS {table} CASCADE"))
                    conn.commit()
                    return len(tables)
                else:
                    return 0
                    
        except Exception as e:
            print(f"⚠️  Could not drop tables: {e}")
            return 0

    async def execute_sql_file(self, file_path: str) -> Dict[str, Any]:
        with open(file_path, 'r') as f:
            content = f.read()
        return await self._execute_sql(content)

    async def _execute_sql(self, sql_content: str) -> Dict[str, Any]:
        statements = _safe_split_sql(sql_content)
        summary = {
            'success': True,
            'execution_time_ms': 0,
            'statements_run': len(statements),
            'rows_affected': 0,
            'result_sets': 0,
            'errors': 0,
            'warnings': 0,
            'statement_details': [],
            'output_content': []  # Capture actual query results
        }
        start_all = datetime.now()

        if self.use_pool:
            pool = await self._get_db_pool()
            async with pool.acquire() as conn:
                tx = conn.transaction()
                if self.atomic:
                    await tx.start()
                for idx, stmt in enumerate(statements, start=1):
                    detail = _init_detail(idx, stmt, self.detailed)
                    stmt_start = datetime.now() if self.detailed else None
                    try:
                        # Check if this is a SELECT statement (more robust detection)
                        stmt_clean = stmt.strip().upper()
                        is_select = (stmt_clean.startswith('SELECT') or 
                                   ('SELECT' in stmt_clean and stmt_clean.find('SELECT') < stmt_clean.find(';') if ';' in stmt_clean else True))
                        
                        if is_select:
                            try:
                                result = await conn.fetch(stmt)
                                count = len(result)
                                summary['result_sets'] += 1
                                # Capture actual query results for SELECT statements
                                result_text = _format_query_results(stmt, result)
                                summary['output_content'].append(result_text)
                                if self.detailed:
                                    detail['rows_returned'] = count
                            except Exception as select_error:
                                # If SELECT fails, treat as regular statement
                                print(f"⚠️  SELECT execution failed, treating as regular statement: {select_error}")
                                result = await conn.execute(stmt)
                                summary['output_content'].append(f"Statement executed: {stmt.strip()}")
                        else:
                            # For non-SELECT statements, get affected rows count
                            result = await conn.execute(stmt)
                            # Extract affected rows count from result string (format: "INSERT 0 5")
                            affected_rows = 0
                            if hasattr(result, 'split'):
                                parts = result.split()
                                if len(parts) >= 2 and parts[-1].isdigit():
                                    affected_rows = int(parts[-1])
                            summary['rows_affected'] += affected_rows
                            
                            # Show full SQL statement for technical analysis
                            summary['output_content'].append(f"Statement executed: {stmt.strip()}")
                            if affected_rows > 0:
                                summary['output_content'].append(f"Rows affected: {affected_rows}")
                            
                        if self.detailed:
                            detail['execution_time_ms'] = _elapsed_ms(stmt_start)
                            summary['statement_details'].append(detail)
                    except Exception as exc:
                        summary['errors'] += 1
                        summary['success'] = False
                        if self.detailed:
                            detail['error_message'] = str(exc)
                            detail['execution_time_ms'] = _elapsed_ms(stmt_start)
                            summary['statement_details'].append(detail)
                if self.atomic:
                    await (tx.commit() if summary['success'] else tx.rollback())
        else:
            conn = self.engine.connect()
            trans = conn.begin() if self.atomic else None
            for idx, stmt in enumerate(statements, start=1):
                detail = _init_detail(idx, stmt, self.detailed)
                stmt_start = datetime.now() if self.detailed else None
                try:
                    result = conn.execute(text(stmt))
                    if result.returns_rows:
                        rows = result.fetchall()
                        summary['result_sets'] += 1
                        # Capture actual query results for SELECT statements
                        result_text = _format_sync_query_results(stmt, rows, result.keys())
                        summary['output_content'].append(result_text)
                        if self.detailed:
                            detail['rows_returned'] = len(rows)
                    else:
                        affected = result.rowcount or 0
                        summary['rows_affected'] += affected
                        # Show full SQL statement for technical analysis
                        summary['output_content'].append(f"Statement executed: {stmt.strip()}")
                        if affected > 0:
                            summary['output_content'].append(f"Rows affected: {affected}")
                        if self.detailed:
                            detail['rows_affected'] = affected
                    if self.detailed:
                        detail['execution_time_ms'] = _elapsed_ms(stmt_start)
                        summary['statement_details'].append(detail)
                except SQLAlchemyError as sae:
                    summary['errors'] += 1
                    summary['success'] = False
                    if self.detailed:
                        detail['error_message'] = str(sae)
                        detail['execution_time_ms'] = _elapsed_ms(stmt_start)
                        summary['statement_details'].append(detail)
            if self.atomic:
                trans.commit() if summary['success'] else trans.rollback()
            conn.close()

        summary['execution_time_ms'] = int((datetime.now() - start_all).total_seconds() * 1000)
        
        # Format the complete output content
        if summary['output_content']:
            summary['output_content'] = '\n\n'.join(summary['output_content'])
            # Count actual output lines
            summary['output_lines'] = len(summary['output_content'].split('\n'))
        else:
            summary['output_content'] = 'No output generated'
            summary['output_lines'] = 0
            
        return summary


def _format_query_results(stmt: str, result) -> str:
    """Format asyncpg query results for display"""
    if not result:
        return f"Query: {stmt.strip()}\nNo results returned."
    
    # Get column names from the first record
    columns = list(result[0].keys()) if result else []
    
    # Format as a simple table
    output = [f"Query: {stmt.strip()}", ""]
    
    if columns:
        # Header
        header = " | ".join(str(col).ljust(15) for col in columns)
        output.append(header)
        output.append("-" * len(header))
        
        # Rows (limit to first 10 for readability)
        for i, row in enumerate(result[:10]):
            row_data = " | ".join(str(row[col]).ljust(15)[:15] for col in columns)
            output.append(row_data)
            
        if len(result) > 10:
            output.append(f"... and {len(result) - 10} more rows")
            
        output.append(f"\nTotal rows: {len(result)}")
    
    return "\n".join(output)


def _format_sync_query_results(stmt: str, rows, columns) -> str:
    """Format SQLAlchemy query results for display"""
    if not rows:
        return f"Query: {stmt.strip()}\nNo results returned."
    
    # Format as a simple table
    output = [f"Query: {stmt.strip()}", ""]
    
    if columns:
        # Header
        header = " | ".join(str(col).ljust(15) for col in columns)
        output.append(header)
        output.append("-" * len(header))
        
        # Rows (limit to first 10 for readability)
        for i, row in enumerate(rows[:10]):
            row_data = " | ".join(str(val).ljust(15)[:15] for val in row)
            output.append(row_data)
            
        if len(rows) > 10:
            output.append(f"... and {len(rows) - 10} more rows")
            
        output.append(f"\nTotal rows: {len(rows)}")
    
    return "\n".join(output)


def _init_detail(index: int, stmt: str, detailed: bool) -> Dict[str, Any]:
    if not detailed:
        return {}
    return {'index': index, 'statement': stmt.strip()[:80]}

def _elapsed_ms(start: datetime) -> int:
    return int((datetime.now() - start).total_seconds() * 1000)

def _safe_split_sql(content: str) -> List[str]:
    # Naive split, can be replaced with sqlparse for more robust behavior
    return [s.strip() for s in content.split(';') if s.strip()]
