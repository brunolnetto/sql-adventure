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

from database.utils import get_connection_string
from database.manager import DatabaseManager

# Add the evaluator directory to Python path
evaluator_dir = Path(__file__).parent
sys.path.insert(0, str(evaluator_dir))

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from models import Base, Quest, Subcategory, SQLPattern
from discovery import (
    discover_sql_patterns_from_filesystem,
    discover_quests_from_filesystem,
    determine_quest_difficulty,
)
from config import ProjectFolderConfig
from tables import EvaluationBase
from repositories.pattern_repository import SQLPatternRepository
from repositories.quest_repository import QuestRepository
from utils.analytics_views import AnalyticsViewManager
from database.utils import get_connection_string
from utils.analytics import AnalyticsViewManager

def generate_quest_description(quest_name: str, subcategories: List[Tuple[str, str, str, int]]) -> str:
    """Generate quest description based on subcategories"""
    quest_keywords = {
        'data-modeling': 'Database design principles, normalization patterns, and schema optimization',
        'performance-tuning': 'Query optimization, indexing strategies, and performance analysis',
        'window-functions': 'Advanced analytics and ranking operations using window functions',
        'json-operations': 'Working with JSON data in PostgreSQL',
        'recursive-cte': 'Hierarchical data and recursive queries',
        'stored-procedures': 'Database programming with stored procedures and functions',
        'triggers': 'Automated database actions with triggers',
        'transactions': 'Data consistency and transaction management'
    }
    
    # Extract quest type from name
    quest_type = '-'.join(quest_name.split('-')[1:])
    
    if quest_type in quest_keywords:
        return quest_keywords[quest_type]
    
    # Fallback: generate description from subcategories
    subcategory_names = [display_name for _, display_name, _, _ in subcategories]
    return f"Comprehensive coverage of {', '.join(subcategory_names[:3])} and related concepts"

def main():
    """Main initialization function"""
    print("🚀 Initializing SQL Adventure Evaluator Database")
    print("🔍 Using discovery features to avoid hardcoded maintenance...")
    
    try:
        # Get connection string
        database_name = os.getenv('DB_NAME', 'sql_adventure_db')
        
        connection_string = get_connection_string(database=database_name)
        database_manager = DatabaseManager(EvaluationBase, connection_string)
        
        print(f"📡 Using connection: {connection_string.split('@')[1]}")
        
        # Discover and initialize quest data
        print("📚 Discovering quests from filesystem...")
        quests_dir  = Path("quests")
        quests_data = discover_quests_from_filesystem(quests_dir)
        quest_repo = QuestRepository(db_manager.session)
        init_quest_data(quests_data)
        
        # Discover and initialize pattern data
        print("🔍 Discovering SQL patterns from filesystem...")
        patterns_data = discover_sql_patterns_from_filesystem()
        pattern_repo = SQLPatternRepository(db_manager.session)
        pattern_repo.upsert(patterns_data)
        
        print("🗃️ Creating database views...")
        analytics_view_manager = AnalyticsViewManager(db_manager)
        analytics_view_manager.create_analytics_views()
        
        print("✅ Database initialization completed successfully!")
        print("\n📊 Database contains:")
        print(f"   - {len(quests_data)} quests with subcategories")
        print(f"   - {len(patterns_data)} SQL patterns")
        print("   - Evaluation tables (ready for data)")
        print("   - Analytics views (ready for queries)")
        print("\n🎉 System is now maintenance-free and auto-discovering!")
        
    except Exception as e:
        print(f"❌ Database initialization failed: {e}")
        return False
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 