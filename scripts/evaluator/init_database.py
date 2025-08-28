#!/usr/bin/env python3
"""
Optimized Database Initialization Script
High-performance initialization with batch processing and parallel AI calls
"""

import os
import sys
from pathlib import Path
import asyncio
import time
from concurrent.futures import ThreadPoolExecutor
from typing import List, Dict, Any, Tuple

# Add evaluator directory to path
evaluator_dir = Path(__file__).parent
sys.path.insert(0, str(evaluator_dir))

# Load environment
try:
    from config.env_loader import load_evaluator_env
    load_evaluator_env()
except ImportError:
    print("⚠️  Environment loader not available, using system environment")

from database.manager import DatabaseManager
from database.tables import (
    EvaluationBase, Quest, Subcategory, SQLFile, SQLPattern,
)
from sqlalchemy import text
from utils.discovery import discover_quests
from repositories.quest_repository import QuestRepository
from repositories.sql_file_repository import SQLFileRepository
from repositories.sql_pattern_repository import SQLPatternRepository
from utils.pattern_data import SQL_PATTERNS

def cleanup_database_connections():
    """Fast database connection cleanup using SQLAlchemy"""
    try:
        print("🧹 Cleaning up existing database connections...")

        # Use SQLAlchemy for faster connection management
        temp_manager = DatabaseManager(EvaluationBase, database_type="evaluator")
        with temp_manager.engine.connect() as conn:
            # PostgreSQL-specific: terminate other connections to this database
            conn.execute(text("""
                SELECT pg_terminate_backend(pid)
                FROM pg_stat_activity
                WHERE datname = current_database()
                AND pid <> pg_backend_pid()
                AND state = 'idle in transaction'
            """))
            conn.commit()

        print("✅ Database connections cleaned up")
        temp_manager.engine.dispose()

    except Exception as e:
        print(f"⚠️  Connection cleanup failed: {e}")
        print("   Continuing with initialization anyway...")


async def batch_process_sql_files_async(sql_file_repo, sql_files: List[Path], batch_size: int = 20) -> Tuple[int, int]:
    """Process SQL files in parallel batches for much better performance"""
    sql_files_added = 0
    sql_files_skipped = 0

    # Process files in parallel batches
    for i in range(0, len(sql_files), batch_size):
        batch = sql_files[i:i + batch_size]
        batch_start = time.time()

        print(f"   🔄 Processing batch {i//batch_size + 1}/{(len(sql_files) + batch_size - 1)//batch_size} ({len(batch)} files)...")

        # Create tasks for parallel processing
        tasks = []
        for sql_file_path in batch:
            try:
                relative_path = str(sql_file_path)
                tasks.append(process_single_sql_file(sql_file_repo, relative_path))
            except Exception as e:
                sql_files_skipped += 1
                print(f"❌ Error with {sql_file_path}: {e}")

        # Execute batch in parallel
        if tasks:
            try:
                results = await asyncio.gather(*tasks, return_exceptions=True)
                for result in results:
                    if isinstance(result, Exception):
                        sql_files_skipped += 1
                        print(f"❌ Batch processing error: {result}")
                    else:
                        sql_files_added += 1
            except Exception as e:
                print(f"⚠️  Batch execution error: {e}")
                sql_files_skipped += len(tasks)

        batch_time = time.time() - batch_start
        print(f"   ✅ Batch completed in {batch_time:.2f}s ({batch_time/len(batch):.2f}s per file)")

    return sql_files_added, sql_files_skipped


async def process_single_sql_file(sql_file_repo, file_path: str):
    """Process a single SQL file asynchronously"""
    try:
        # Get or create the SQL file record (this will trigger AI analysis)
        sql_file = await sql_file_repo.get_or_create(file_path)
        return sql_file is not None
    except Exception as e:
        print(f"❌ Error processing {file_path}: {e}")
        raise


async def generate_patterns_fast() -> List[Tuple[str, str, str, str, str, str, str, List[str]]]:
    """Generate patterns using static data instead of AI calls for faster initialization"""
    print("⚡ Using pre-computed patterns for fast initialization...")

    patterns = []
    for pattern in SQL_PATTERNS:
        patterns.append((
            pattern['name'],
            pattern['display_name'],
            pattern['description'],
            pattern['category'],
            pattern['complexity_level'],
            pattern['regex_pattern'],
            pattern['base_description'],
            pattern['examples']
        ))

    print(f"✅ Loaded {len(patterns)} patterns from cache")
    return patterns


def optimize_schema_operations(engine):
    """Optimize schema operations for better performance"""
    print("🔄 Optimizing database schema operations...")

    # Disable foreign key checks temporarily for faster drops
    with engine.connect() as conn:
        try:
            # PostgreSQL optimizations
            conn.execute(text("SET CONSTRAINTS ALL DEFERRED"))
            conn.execute(text("SET session_replication_role = 'replica'"))
            conn.commit()
        except:
            pass  # Ignore if not supported

    return engine


def _drop_analytics_views(engine):
    """Drop analytics views that depend on tables before dropping tables"""
    views_to_drop = [
        'evaluation_summary',
        'recommendations_dashboard', 
        'recommendations_grouped',
        'quest_performance',
        'pattern_analysis',
        'file_progress'
    ]
    
    try:
        with engine.connect() as conn:
            for view in views_to_drop:
                try:
                    conn.execute(text(f"DROP VIEW IF EXISTS {view} CASCADE"))
                    print(f"   🗑️  Dropped view: {view}")
                except Exception as e:
                    print(f"   ⚠️  Could not drop view {view}: {e}")
            conn.commit()
    except Exception as e:
        print(f"   ⚠️  Error dropping views: {e}")


async def main():
    """Optimized main initialization with performance enhancements"""
    start_time = time.time()
    print("🚀 Starting optimized database initialization...")

    # Check if AI is disabled for faster initialization
    disable_ai = os.getenv("DISABLE_AI_SUMMARIZATION", "false").lower() == "true"
    if disable_ai:
        print("🤖 AI summarization is DISABLED (fast mode)")
    else:
        print("🧠 With AI-enhanced quest descriptions (may be slower)")

    # Fast connection cleanup
    cleanup_database_connections()

    # Change to repository root
    original_cwd = os.getcwd()
    repo_root = Path(__file__).parent.parent.parent
    os.chdir(repo_root)

    try:
        # Initialize database
        db_manager = DatabaseManager(EvaluationBase, database_type="evaluator")
        print("✅ Database connection established")

        # Fast connectivity test
        print("🔍 Testing database connectivity...")
        try:
            with db_manager.engine.connect() as conn:
                result = conn.execute(text("SELECT 1"))
                if result.fetchone():
                    print("✅ Database connection test successful")
                else:
                    print("❌ Database connection test failed")
                    return False
        except Exception as e:
            print(f"❌ Database connectivity test failed: {e}")
            return False

        # Optimized schema operations
        print("🔄 Recreating database schema...")
        try:
            schema_start = time.time()

            # Optimize engine for bulk operations
            optimized_engine = optimize_schema_operations(db_manager.engine)

            # Fast schema recreation without complex timeout handling
            print("   📉 Dropping existing views...")
            _drop_analytics_views(optimized_engine)
            print("   ✅ Views dropped successfully")
            
            print("   📉 Dropping existing tables...")
            EvaluationBase.metadata.drop_all(optimized_engine, checkfirst=True)
            print("   ✅ Tables dropped successfully")

            print("   📈 Creating new tables...")
            EvaluationBase.metadata.create_all(optimized_engine)
            print("   ✅ Tables created successfully")

            schema_time = time.time() - schema_start
            print(f"   ⏱️  Schema operations completed in {schema_time:.2f}s")
        except Exception as e:
            print(f"❌ Schema recreation failed: {e}")
            return False

        session = db_manager.SessionLocal()

        try:
            # 1. Fast quest discovery
            print("📝 Discovering quests...")
            quest_start = time.time()
            quests_dir = Path("quests")

            if not quests_dir.exists():
                print(f"❌ Quests directory not found: {quests_dir.absolute()}")
                return False

            # Discover quests from filesystem
            print("🔍 Discovering quests from filesystem...")
            quests_data = discover_quests(quests_dir)
            if not quests_data:
                print("⚠️  No quests discovered")
                return False

            quest_repo = QuestRepository(session)
            quest_repo.upsert(quests_data)
            session.commit()

            quest_time = time.time() - quest_start
            print(f"✅ Processed {len(quests_data)} quests in {quest_time:.2f}s")

            # 2. Batch SQL file processing
            print("📄 Creating SQL file records...")
            sql_start = time.time()
            sql_file_repo = SQLFileRepository(session)

            # Collect all SQL files first
            sql_files = list(quests_dir.rglob("*.sql"))
            print(f"   📊 Found {len(sql_files)} SQL files to process")

            # Batch process SQL files in parallel with larger batches
            sql_files_added, sql_files_skipped = await batch_process_sql_files_async(
                sql_file_repo, sql_files, batch_size=25  # Larger batches for maximum throughput
            )

            session.commit()

            sql_time = time.time() - sql_start
            print(f"✅ Added {sql_files_added} SQL files, skipped {sql_files_skipped} in {sql_time:.2f}s")

            # 3. Fast pattern loading
            print("🎯 Loading SQL patterns...")
            pattern_start = time.time()

            pattern_repo = SQLPatternRepository(session)

            # Use fast static pattern loading instead of AI generation
            patterns = await generate_patterns_fast()
            pattern_repo.upsert(patterns)
            session.commit()

            pattern_time = time.time() - pattern_start
            print(f"✅ Loaded {len(patterns)} patterns in {pattern_time:.2f}s")

            # Final summary with performance metrics
            quest_count = session.query(Quest).count()
            subcategory_count = session.query(Subcategory).count()
            sql_file_count = session.query(SQLFile).count()
            sql_pattern_count = session.query(SQLPattern).count()

            total_time = time.time() - start_time

            print("\n📊 Database Summary:")
            print(f"   - {quest_count} quests with descriptions")
            print(f"   - {subcategory_count} subcategories")
            print(f"   - {sql_file_count} SQL files")
            print(f"   - {sql_pattern_count} SQL Patterns")

            print("\n⚡ Performance Metrics:")
            print(f"   - Total time: {total_time:.2f}s")
            print(f"   - Schema: {schema_time:.2f}s")
            print(f"   - Quests: {quest_time:.2f}s")
            print(f"   - SQL files: {sql_time:.2f}s")
            print(f"   - Patterns: {pattern_time:.2f}s")

            print("\n✅ Database initialization completed!")

        except Exception as e:
            print(f"❌ Initialization failed: {e}")
            return False
        finally:
            session.close()

    except Exception as e:
        print(f"❌ Initialization failed: {e}")
        return False
    finally:
        os.chdir(original_cwd)

    return True

if __name__ == "__main__":
    try:
        success = asyncio.run(main())
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n⏹️  Initialization interrupted by user")
        print("💡 You can restart the initialization by running this script again")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error during initialization: {e}")
        print("💡 Check the database connection and try again")
        sys.exit(1)