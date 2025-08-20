#!/usr/bin/env python3
"""
Fast Database Initialization Script (No AI calls)
Creates the evaluator database quickly with static content for development
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
    print("⚠️  ProjectFolderConfig not available, using default settings")
    # Fallback configuration
    class ProjectFolderConfig:
        quest_discovery_root = "../../quests"

def get_static_sql_patterns():
    """Get static SQL patterns without AI calls"""
    return [
        {"name": "table_creation", "display_name": "Table Creation", "description": "Basic table creation with data types and constraints", "category": "DDL", "complexity_level": "Basic"},
        {"name": "index_creation", "display_name": "Index Creation", "description": "Index creation for performance optimization", "category": "DDL", "complexity_level": "Intermediate"},
        {"name": "constraint_definition", "display_name": "Constraint Definition", "description": "Defining constraints for data integrity", "category": "DDL", "complexity_level": "Intermediate"},
        {"name": "view_creation", "display_name": "View Creation", "description": "Creating views for data abstraction", "category": "DDL", "complexity_level": "Intermediate"},
        {"name": "data_insertion", "display_name": "Data Insertion", "description": "Inserting data into tables", "category": "DML", "complexity_level": "Basic"},
        {"name": "data_update", "display_name": "Data Update", "description": "Updating existing data", "category": "DML", "complexity_level": "Basic"},
        {"name": "simple_select", "display_name": "Simple Select", "description": "Basic SELECT queries", "category": "DQL", "complexity_level": "Basic"},
        {"name": "join_operations", "display_name": "Join Operations", "description": "JOIN operations between tables", "category": "DQL", "complexity_level": "Intermediate"},
        {"name": "aggregation", "display_name": "Aggregation", "description": "GROUP BY and aggregate functions", "category": "DQL", "complexity_level": "Intermediate"},
        {"name": "window_functions", "display_name": "Window Functions", "description": "Window functions for analytics", "category": "ANALYTICS", "complexity_level": "Advanced"},
        {"name": "common_table_expressions", "display_name": "Common Table Expressions", "description": "CTEs for complex queries", "category": "DQL", "complexity_level": "Advanced"},
        {"name": "recursive_cte", "display_name": "Recursive CTE", "description": "Recursive CTEs for hierarchical data", "category": "RECURSIVE", "complexity_level": "Expert"},
        {"name": "json_parsing", "display_name": "JSON Parsing", "description": "Parsing JSON data in SQL", "category": "JSON", "complexity_level": "Intermediate"},
        {"name": "json_aggregation", "display_name": "JSON Aggregation", "description": "Aggregating JSON data", "category": "JSON", "complexity_level": "Advanced"},
        {"name": "explain_plan", "display_name": "Explain Plan", "description": "Query execution plan analysis", "category": "DQL", "complexity_level": "Advanced"},
        {"name": "index_usage", "display_name": "Index Usage", "description": "Analyzing index usage", "category": "DDL", "complexity_level": "Advanced"},
        {"name": "query_optimization", "display_name": "Query Optimization", "description": "Query optimization techniques", "category": "DQL", "complexity_level": "Expert"},
        {"name": "partitioning", "display_name": "Partitioning", "description": "Table partitioning strategies", "category": "DDL", "complexity_level": "Expert"},
        {"name": "temporal_queries", "display_name": "Temporal Queries", "description": "Time-based query operations", "category": "DQL", "complexity_level": "Intermediate"},
        {"name": "array_operations", "display_name": "Array Operations", "description": "Array operations in SQL", "category": "DQL", "complexity_level": "Advanced"},
        {"name": "full_text_search", "display_name": "Full Text Search", "description": "Full-text search capabilities", "category": "DQL", "complexity_level": "Expert"},
        {"name": "geospatial", "display_name": "Geospatial", "description": "Geospatial data operations", "category": "DQL", "complexity_level": "Expert"}
    ]

def get_static_subcategory_description(subcategory_name: str) -> str:
    """Get static description for subcategory without AI call"""
    descriptions = {
        "00-basic-concepts": "Foundational concepts for beginners",
        "01-normalization-patterns": "Database normalization techniques and patterns",
        "02-denormalization-strategies": "Strategic denormalization for performance",
        "03-schema-design-principles": "Principles of effective schema design",
        "04-real-world-applications": "Practical real-world database applications",
        "01-query-optimization": "Query optimization strategies and techniques",
        "02-indexing-strategies": "Index design and optimization",
        "03-execution-plans": "Query execution plan analysis",
        "04-performance-monitoring": "Performance monitoring and tuning",
        "05-expert-techniques": "Advanced performance optimization techniques",
        "01-basic-ranking": "Basic window function ranking",
        "02-advanced-ranking": "Advanced ranking and analytical functions",
        "03-aggregation-windows": "Window-based aggregation operations",
        "04-partitioned-analytics": "Partitioned analytics with window functions",
        "05-advanced-patterns": "Advanced window function patterns",
        "01-basic-json": "Basic JSON operations in SQL",
        "02-json-queries": "Advanced JSON querying techniques",
        "03-real-world-applications": "Real-world JSON data applications",
        "04-advanced-patterns": "Advanced JSON manipulation patterns",
        "01-hierarchical-graph-traversal": "Hierarchical and graph traversal with recursive CTEs",
        "02-iteration-loops": "Iteration and loop patterns",
        "03-path-finding-analysis": "Path finding and analysis algorithms",
        "04-data-transformation-parsing": "Data transformation and parsing",
        "05-simulation-state-machines": "Simulation and state machine modeling",
        "06-data-repair-healing": "Data repair and healing techniques",
        "07-mathematical-theoretical": "Mathematical and theoretical applications"
    }
    return descriptions.get(subcategory_name, f"SQL exercises for {subcategory_name}")

async def fast_init_database():
    """Fast database initialization without AI calls"""
    print("🚀 Fast Database Initialization (No AI)")
    
    # Database creation
    print("📦 Creating databases...")
    evaluator_conn_str = get_evaluator_connection_string()
    quests_conn_str = get_quests_connection_string()
    
    # Create databases if they don't exist
    await create_database_if_not_exists("sql_adventure_evaluator", evaluator_conn_str)
    await create_database_if_not_exists("sql_adventure_quests", quests_conn_str)
    
    # Connect to evaluator database
    print("✅ Database connection established: sql_adventure_evaluator (metadata)")
    db_manager = DatabaseManager(EvaluationBase, database_type="evaluator")
    
    # Recreate schema
    print("🔄 Recreating database schema...")
    
    # Drop all views first to avoid dependency issues
    try:
        with db_manager.engine.connect() as conn:
            # Get all views in the current schema and drop them
            result = conn.execute(text("""
                SELECT table_name 
                FROM information_schema.views 
                WHERE table_schema = 'public'
            """))
            views = [row[0] for row in result.fetchall()]
            
            for view_name in views:
                conn.execute(text(f"DROP VIEW IF EXISTS {view_name} CASCADE"))
                print(f"🗑️  Dropped view: {view_name}")
            
            conn.commit()
    except Exception as e:
        print(f"⚠️  Note during view cleanup: {e}")
    
    # Now drop and create tables
    EvaluationBase.metadata.drop_all(db_manager.engine)
    EvaluationBase.metadata.create_all(db_manager.engine)
    
    # Create session
    Session = sessionmaker(bind=db_manager.engine)
    session = Session()
    
    try:
        # 1. Add SQL patterns (static)
        print("📋 Adding SQL patterns (static)...")
        static_patterns = get_static_sql_patterns()
        for pattern_data in static_patterns:
            pattern = SQLPattern(
                name=pattern_data["name"],
                display_name=pattern_data["display_name"],
                description=pattern_data["description"],
                category=pattern_data["category"],
                complexity_level=pattern_data["complexity_level"]
            )
            session.add(pattern)
        session.commit()
        print(f"✅ Added {len(static_patterns)} SQL patterns")
        
        # 2. Discover and add quests
        print("🎯 Discovering quests from filesystem...")
        # Point to the actual quests directory in the project root
        quest_root = Path(evaluator_dir) / "../../quests"
        
        if not quest_root.exists():
            print(f"⚠️  Quest directory not found: {quest_root}")
            return
            
        discovered_quests = discover_quests_from_filesystem(quest_root)
        
        for quest_index, quest_data in enumerate(discovered_quests, 1):
            # Create a Path object for the quest directory to determine difficulty
            quest_dir = quest_root / quest_data["name"]
            difficulty = determine_quest_difficulty(quest_dir)
            quest = Quest(
                name=quest_data["name"],
                display_name=quest_data["name"].replace("-", " ").title(),
                description=f"Quest focusing on {quest_data['name'].lower()}",
                difficulty_level=difficulty,
                order_index=quest_index
            )
            session.add(quest)
            session.flush()
            
            # Add subcategories
            for subcat_index, subcat_tuple in enumerate(quest_data["subcategories"], 1):
                # Extract from tuple: (sub_name, sub_display, sub_difficulty, sub_description, _)
                subcat_name = subcat_tuple[0]
                subcat_display = subcat_tuple[1] if len(subcat_tuple) > 1 else subcat_name.replace("-", " ").title()
                description = get_static_subcategory_description(subcat_name)
                subcategory = Subcategory(
                    quest_id=quest.id,
                    name=subcat_name,
                    display_name=subcat_display,
                    description=description,
                    difficulty_level=difficulty,
                    order_index=subcat_index
                )
                session.add(subcategory)
            
            print(f"✅ Added quest: {quest.name}")
        
        session.commit()
        
        # 3. Catalog SQL files by discovering them from filesystem
        print("📁 Cataloguing SQL files...")
        from database.tables import SQLFile
        
        file_count = 0
        for quest_data in discovered_quests:
            quest = session.query(Quest).filter(Quest.name == quest_data["name"]).first()
            quest_dir = quest_root / quest_data["name"]
            
            # Discover SQL files in this quest directory
            for sql_file_path in quest_dir.rglob("*.sql"):
                # Get relative path from quest root
                relative_path = sql_file_path.relative_to(quest_root)
                
                # Find the subcategory this file belongs to
                subcategory_name = sql_file_path.parent.name
                subcategory = session.query(Subcategory).filter(
                    Subcategory.quest_id == quest.id,
                    Subcategory.name == subcategory_name
                ).first()
                
                if subcategory:
                    # Create SQL file record directly
                    sql_file = SQLFile(
                        file_path=str(relative_path),
                        filename=sql_file_path.name,
                        display_name=sql_file_path.name.replace('.sql', '').replace('-', ' ').title(),
                        subcategory_id=subcategory.id,
                        content_hash=""  # Empty for now
                    )
                    session.add(sql_file)
                    file_count += 1
                else:
                    print(f"⚠️  No subcategory found for {subcategory_name}")
        
        session.commit()
        print(f"✅ Successfully catalogued {file_count} SQL files")
        
        # 4. Create analytics views
        print("🔧 Creating analytics views...")
        from reporting.mart import AnalyticsViewManager
        analytics_view_manager = AnalyticsViewManager(db_manager.engine)
        analytics_view_manager.create_analytics_views()
        print("✅ Analytics views created")
        
        print("🎉 Fast database initialization completed!")
        print(f"📊 Database contains:")
        print(f"   - {len(discovered_quests)} quests")
        print(f"   - {len(static_patterns)} SQL patterns")
        print(f"   - {file_count} SQL files")
        
    except Exception as e:
        session.rollback()
        raise e
    finally:
        session.close()

async def create_database_if_not_exists(db_name: str, conn_str: str):
    """Create database if it doesn't exist"""
    base_conn_str = conn_str.rsplit('/', 1)[0] + '/postgres'
    engine = create_engine(base_conn_str)
    
    with engine.connect() as conn:
        conn.execute(text("COMMIT"))
        result = conn.execute(text(f"SELECT 1 FROM pg_database WHERE datname = '{db_name}'"))
        if not result.fetchone():
            conn.execute(text(f"CREATE DATABASE {db_name}"))
            print(f"📦 Created database: {db_name}")
        else:
            print(f"📦 Database already exists: {db_name}")
    
    engine.dispose()

async def main():
    """Main function"""
    await fast_init_database()

if __name__ == "__main__":
    asyncio.run(main())
