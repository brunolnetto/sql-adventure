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

class DatabaseManager:
    def __init__(self, base, connection_string: Optional[str] = None):
        self.connection_string = connection_string
        self.base = base
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
            self.base.metadata.create_all(bind=self.engine)
            print("✅ Enhanced database connection established")
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
            'statement_details': []
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
                        result = await conn.fetch(stmt)
                        count = len(result)
                        if count > 0:
                            summary['result_sets'] += 1
                            if self.detailed:
                                detail['rows_returned'] = count
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
                        if self.detailed:
                            detail['rows_returned'] = len(rows)
                    else:
                        affected = result.rowcount or 0
                        summary['rows_affected'] += affected
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
        return summary


def _init_detail(index: int, stmt: str, detailed: bool) -> Dict[str, Any]:
    if not detailed:
        return {}
    return {'index': index, 'statement': stmt.strip()[:80]}

def _elapsed_ms(start: datetime) -> int:
    return int((datetime.now() - start).total_seconds() * 1000)

def _safe_split_sql(content: str) -> List[str]:
    # Naive split, can be replaced with sqlparse for more robust behavior
    return [s.strip() for s in content.split(';') if s.strip()]
