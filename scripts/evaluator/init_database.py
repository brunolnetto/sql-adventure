#!/usr/bin/env python3
"""
Enhanced Database Initialization Script with AI Features
Creates the evaluator database with AI-generated content and comprehensive features
Uses discovery features to avoid hardcoded maintenance
"""

import asyncio
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
    generate_enhanced_sql_patterns,
)
from utils.summarizers import generate_subcategory_description_ai, estimate_subcategory_time

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
    """Main initialization function with AI enhancements"""
    print("🚀 Initializing Enhanced SQL Adventure Evaluator Database")
    print("🔍 Using discovery features and AI enhancements...")
    
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
            # Run the enhanced initialization
            asyncio.run(enhanced_initialization(session, repo_root))
            
        except Exception as e:
            session.rollback()
            raise e
        finally:
            session.close()
        
        print("�️ Creating enhanced database views...")
        analytics_view_manager = AnalyticsViewManager(db_manager)
        analytics_view_manager.create_analytics_views()
        
        # Final summary
        session = db_manager.SessionLocal()
        try:
            quest_count = session.query(Quest).count()
            subcategory_count = session.query(Subcategory).count()
            pattern_count = session.query(SQLPattern).count()
            
            print("✅ Enhanced database initialization completed successfully!")
            print("\n📊 Database contains:")
            print(f"   - {quest_count} quests with AI-enhanced subcategories")
            print(f"   - {subcategory_count} subcategories with AI descriptions")
            print(f"   - {pattern_count} SQL patterns with educational descriptions")
            print("   - Evaluation tables (ready for AI analysis)")
            print("   - Enhanced analytics views (ready for insights)")
            print("\n🎉 System is now AI-enhanced and maintenance-free!")
            
        finally:
            session.close()
        
    except Exception as e:
        print(f"❌ Database initialization failed: {e}")
        return False
    finally:
        # Restore original working directory
        os.chdir(original_cwd)
    
    return True


async def enhanced_initialization(session, repo_root: Path):
    """Enhanced initialization with AI-generated content"""
    print("🧠 Starting AI-enhanced content generation...")
    
    # 1. Discover and initialize enhanced SQL patterns
    print("🎯 Generating enhanced SQL patterns with AI descriptions...")
    enhanced_patterns = await generate_enhanced_sql_patterns()
    
    for pattern_data in enhanced_patterns:
        pattern = SQLPattern(
            name=pattern_data['name'],
            display_name=pattern_data['display_name'],
            description=pattern_data['description'],
            category=pattern_data['category'],
            complexity_level=pattern_data['complexity_level']
        )
        session.add(pattern)
        print(f"   + {pattern_data['display_name']}: {pattern_data['complexity_level']}")
    
    session.commit()
    print(f"✅ Added {len(enhanced_patterns)} enhanced SQL patterns")
    
    # 2. Discover and initialize quest data with AI enhancements
    print("� Discovering quests from filesystem...")
    quests_dir = Path("quests")  # Now relative to repository root
    quests_data = discover_quests_from_filesystem(quests_dir)
    quest_repo = QuestRepository(session)
    quest_repo.upsert(quests_data)
    
    # 3. Enhance subcategories with AI descriptions
    print("🧠 Generating AI descriptions for subcategories...")
    
    # Import quest and subcategory models for enhanced processing
    from database.tables import Quest, Subcategory
    
    enhanced_count = 0
    for quest in session.query(Quest).all():
        quest_path = quests_dir / quest.name
        
        if quest_path.exists():
            for subcategory_dir in sorted(quest_path.iterdir()):
                if subcategory_dir.is_dir() and re.match(r'^\d+-', subcategory_dir.name):
                    try:
                        print(f"   🧠 Analyzing subcategory: {quest.name}/{subcategory_dir.name}")
                        
                        # Generate AI description and time estimate
                        ai_description = await generate_subcategory_description_ai(subcategory_dir)
                        estimated_time = await estimate_subcategory_time(subcategory_dir)
                        
                        # Find and update subcategory
                        subcategory = session.query(Subcategory).filter(
                            Subcategory.quest_id == quest.id,
                            Subcategory.name == subcategory_dir.name
                        ).first()
                        
                        if subcategory:
                            subcategory.description = ai_description
                            if hasattr(subcategory, 'estimated_time_minutes'):
                                subcategory.estimated_time_minutes = estimated_time
                            enhanced_count += 1
                            print(f"   + {quest.name}/{subcategory_dir.name}: {estimated_time}min - {ai_description[:60]}...")
                        
                    except Exception as e:
                        print(f"   ⚠️ Error enhancing {subcategory_dir.name}: {e}")
    
    session.commit()
    print(f"✅ Enhanced {enhanced_count} subcategory descriptions")
    
    # 4. Discover and initialize SQL files with enhanced metadata
    print("� Cataloguing SQL files with enhanced metadata...")
    sql_files_added = 0
    from repositories.sqlfile_repository import SQLFileRepository
    sql_file_repo = SQLFileRepository(session)
    
    for sql_file_path in quests_dir.rglob("*.sql"):
        try:
            sql_file = sql_file_repo.get_or_create(str(sql_file_path))
            if sql_file:
                # Add time estimation if missing
                if not sql_file.estimated_time_minutes:
                    try:
                        content = sql_file_path.read_text(encoding='utf-8', errors='ignore')
                        lines = len([line for line in content.splitlines() if line.strip() and not line.strip().startswith('--')])
                        estimated_time = max(5, min(45, lines * 2))  # 2 minutes per significant line, 5-45 min range
                        sql_file.estimated_time_minutes = estimated_time
                    except Exception:
                        sql_file.estimated_time_minutes = 10  # Default fallback
                
                sql_files_added += 1
                if sql_files_added <= 5:  # Show first few files
                    print(f"📄 Added SQL file: {sql_file_path.name}")
        except Exception as e:
            print(f"⚠️  Error adding SQL file {sql_file_path}: {e}")
    
    session.commit()
    print(f"✅ Successfully catalogued {sql_files_added} SQL files with enhanced metadata")

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 