#!/usr/bin/env python3
"""
Enhanced Database Initialization Script
Creates the evaluator database with proper content discovery and AI-enhanced descriptions
"""

import os
import sys
from pathlib import Path
import asyncio

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
from utils.discovery import discover_quests_from_filesystem, generate_sql_patterns
from repositories.quest_repository import QuestRepository
from repositories.sqlfile_repository import SQLFileRepository
from repositories.sql_pattern_repository import SQLPatternRepository

async def main():
    """Main initialization with AI-enhanced content"""
    print("🚀 Initializing SQL Adventure Evaluator Database")
    print("🧠 With AI-enhanced quest descriptions...")
    
    # Change to repository root
    original_cwd = os.getcwd()
    repo_root = Path(__file__).parent.parent.parent  # Go up to repository root
    os.chdir(repo_root)
    
    try:
        # Initialize database
        db_manager = DatabaseManager(EvaluationBase, database_type="evaluator")
        print("✅ Database connection established")
        
        # Recreate schema
        print("🔄 Recreating database schema...")
        EvaluationBase.metadata.drop_all(db_manager.engine, checkfirst=True)
        EvaluationBase.metadata.create_all(db_manager.engine)
        
        session = db_manager.SessionLocal()
        
        try:
            # 1. Discover and create quest data with AI descriptions
            print("📝 Discovering quests...")
            quests_dir = Path("quests")
            
            if not quests_dir.exists():
                print(f"❌ Quests directory not found: {quests_dir.absolute()}")
                return False
                
            quests_data = discover_quests_from_filesystem(quests_dir)
            if not quests_data:
                print("⚠️  No quests discovered")
                return False
                
            quest_repo = QuestRepository(session)
            quest_repo.upsert(quests_data)
            session.commit()
            print(f"✅ Processed {len(quests_data)} quests")
            
            # 2. Create SQL file records
            print("📄 Creating SQL file records...")
            sql_file_repo = SQLFileRepository(session)
            
            sql_files_added = 0
            sql_files_skipped = 0
            
            for sql_file_path in quests_dir.rglob("*.sql"):
                try:
                    relative_path = str(sql_file_path)
                    sql_file = sql_file_repo.get_or_create(relative_path)
                    
                    if sql_file:
                        sql_files_added += 1
                    else:
                        sql_files_skipped += 1
                        
                except Exception as e:
                    sql_files_skipped += 1
                    print(f"❌ Error with {sql_file_path}: {e}")
            
            session.commit()
            print(f"✅ Added {sql_files_added} SQL files, skipped {sql_files_skipped}")
            
            pattern_repo = SQLPatternRepository(session)
            patterns = await generate_sql_patterns()
            pattern_repo.upsert(patterns)
            session.commit()
            
            print(f"✅ Added SQL files patterns")
            
            # Final summary
            quest_count = session.query(Quest).count()
            subcategory_count = session.query(Subcategory).count()
            sql_file_count = session.query(SQLFile).count()
            sql_pattern_count = session.query(SQLPattern).count()
            
            print("\n📊 Database Summary:")
            print(f"   - {quest_count} quests with AI descriptions")
            print(f"   - {subcategory_count} subcategories")  
            print(f"   - {sql_file_count} SQL files")
            print(f"   - {sql_pattern_count} SQL Patterns")
            print("\n✅ Database initialization completed!")
            
        finally:
            session.close()
            
    except Exception as e:
        print(f"❌ Initialization failed: {e}")
        return False
    finally:
        os.chdir(original_cwd)
    
    return True

if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)