#!/usr/bin/env python3
"""
Standalone Database Initialization Script
Creates the evaluator database and all tables automatically
Uses discovery features to avoid hardcoded maintenance
"""

import os
import sys
import re
from pathlib import Path
from typing import List, Dict, Any, Tuple

from database.utils import get_evaluator_connection_string, get_quests_connection_string
from database.manager import DatabaseManager

# Add the evaluator directory to Python path
evaluator_dir = Path(__file__).parent
sys.path.insert(0, str(evaluator_dir))

# Load evaluator environment variables first
import sys
import os
from pathlib import Path

# Add evaluator directory to path
sys.path.insert(0, str(Path(__file__).parent))

# Import environment loader directly
try:
    from config.env_loader import load_evaluator_env, validate_config
    load_evaluator_env()
except ImportError:
    print("⚠️  Environment loader not available, using system environment")

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from database.tables import Quest, Subcategory, SQLPattern, EvaluationBase
from utils.discovery import (
    discover_sql_patterns_from_filesystem,
    discover_quests_from_filesystem,
    determine_quest_difficulty,
)

# Import ProjectFolderConfig from parent config
try:
    from config import ProjectFolderConfig
except ImportError:
    # Fallback - import from the parent config.py file directly
    import importlib.util
    config_path = Path(__file__).parent / "config.py"
    spec = importlib.util.spec_from_file_location("config", config_path)
    config_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(config_module)
    ProjectFolderConfig = config_module.ProjectFolderConfig
from repositories.pattern_repository import SQLPatternRepository
from repositories.quest_repository import QuestRepository
from reporting.mart import AnalyticsViewManager


def create_databases():
    """Create both evaluator and quests databases if they don't exist"""
    import psycopg2
    from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
    
    # Get database names
    evaluator_db = os.getenv('EVALUATOR_DB_NAME', 'sql_adventure_evaluator')
    quests_db = os.getenv('QUESTS_DB_NAME', 'sql_adventure_quests')
    
    # Connect to postgres database to create our databases
    conn_params = {
        'host': os.getenv('EVALUATOR_DB_HOST', 'localhost'),
        'port': os.getenv('EVALUATOR_DB_PORT', '5432'),
        'user': os.getenv('EVALUATOR_DB_USER', 'postgres'),
        'password': os.getenv('EVALUATOR_DB_PASSWORD', 'postgres'),
        'database': 'postgres'  # Connect to postgres database to create others
    }
    
    conn = psycopg2.connect(**conn_params)
    conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
    cur = conn.cursor()
    
    # Create evaluator database
    cur.execute("SELECT 1 FROM pg_catalog.pg_database WHERE datname = %s", (evaluator_db,))
    if not cur.fetchone():
        print(f"📦 Creating evaluator database: {evaluator_db}")
        cur.execute(f'CREATE DATABASE "{evaluator_db}"')
    else:
        print(f"📦 Evaluator database already exists: {evaluator_db}")
    
    # Create quests database
    cur.execute("SELECT 1 FROM pg_catalog.pg_database WHERE datname = %s", (quests_db,))
    if not cur.fetchone():
        print(f"📦 Creating quests database: {quests_db}")
        cur.execute(f'CREATE DATABASE "{quests_db}"')
    else:
        print(f"📦 Quests database already exists: {quests_db}")
    
    cur.close()
    conn.close()


def main():
    """Main initialization function"""
    print("🚀 Initializing SQL Adventure Evaluator Database")
    print("🔍 Using discovery features to avoid hardcoded maintenance...")
    
    # Change to repository root for quest discovery
    original_cwd = os.getcwd()
    repo_root = Path(__file__).parent.parent.parent  # Go up to repository root
    os.chdir(repo_root)
    
    try:
        # Create databases first
        create_databases()
        
        # Get connection string for evaluator database
        connection_string = get_evaluator_connection_string()
        print(f"📡 Using evaluator database: {connection_string.split('@')[1]}")
        
        # Initialize evaluator database manager
        db_manager = DatabaseManager(EvaluationBase, database_type="evaluator")
        print("✅ Enhanced database connection established")
        
        # Drop and recreate all tables to ensure schema is up to date
        print("🔄 Recreating database schema...")
        
        # First drop views that might depend on tables
        try:
            with db_manager.engine.connect() as conn:
                conn.execute(text("DROP VIEW IF EXISTS evaluation_summary CASCADE"))
                conn.execute(text("DROP VIEW IF EXISTS quest_performance CASCADE"))
                conn.execute(text("DROP VIEW IF EXISTS pattern_analysis CASCADE"))
                conn.execute(text("DROP VIEW IF EXISTS file_progress CASCADE"))
                conn.execute(text("DROP VIEW IF EXISTS recommendations_dashboard CASCADE"))
                conn.commit()
        except Exception as e:
            print(f"📝 Note: Views cleanup: {e}")
        
        # Then drop and recreate tables
        EvaluationBase.metadata.drop_all(db_manager.engine, checkfirst=True)
        EvaluationBase.metadata.create_all(db_manager.engine)
        
        # Create a session for database operations
        session = db_manager.SessionLocal()
        
        try:
            # Discover and initialize quest data
            print("📚 Discovering quests from filesystem...")
            quests_dir = Path("quests")  # Now relative to repository root
            quests_data = discover_quests_from_filesystem(quests_dir)
            quest_repo = QuestRepository(session)
            quest_repo.upsert(quests_data)
        
            # Discover and initialize pattern data
            print("🔍 Discovering SQL patterns from filesystem...")
            patterns_data = discover_sql_patterns_from_filesystem()
            pattern_repo = SQLPatternRepository(session)
            pattern_repo.upsert(patterns_data)
            
            # Discover and initialize SQL files
            print("📁 Discovering and cataloguing SQL files...")
            sql_files_added = 0
            from repositories.sqlfile_repository import SQLFileRepository
            sql_file_repo = SQLFileRepository(session)
            
            quests_dir = Path("quests")
            for sql_file_path in quests_dir.rglob("*.sql"):
                try:
                    sql_file = sql_file_repo.get_or_create(str(sql_file_path))
                    if sql_file:
                        sql_files_added += 1
                        print(f"📄 Added SQL file: {sql_file_path.name}")
                except Exception as e:
                    print(f"⚠️  Error adding SQL file {sql_file_path}: {e}")
            
            print(f"✅ Successfully catalogued {sql_files_added} SQL files")
            
            # Commit the session
            session.commit()
            
        except Exception as e:
            session.rollback()
            raise e
        finally:
            session.close()
        
        print("🗃️ Creating database views...")
        analytics_view_manager = AnalyticsViewManager(db_manager)
        analytics_view_manager.create_analytics_views()
        
        print("✅ Database initialization completed successfully!")
        print("\n📊 Database contains:")
        print(f"   - {len(quests_data)} quests with subcategories")
        print(f"   - {len(patterns_data)} SQL patterns")
        print(f"   - {sql_files_added} SQL files catalogued and ready for evaluation")
        print("   - Evaluation tables (ready for data)")
        print("   - Analytics views (ready for queries)")
        print("\n🎉 System is now maintenance-free and auto-discovering!")
        
    except Exception as e:
        print(f"❌ Database initialization failed: {e}")
        return False
    finally:
        # Restore original working directory
        os.chdir(original_cwd)
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 