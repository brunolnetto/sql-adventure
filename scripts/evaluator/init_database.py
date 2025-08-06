#!/usr/bin/env python3
"""
Standalone Database Initialization Script
Creates the evaluator database and all tables automatically
Uses discovery features to avoid hardcoded maintenance
"""

import os
import sys
import re
from urllib.parse import quote_plus
from pathlib import Path
from typing import List, Dict, Any, Tuple

# Add the evaluator directory to Python path
evaluator_dir = Path(__file__).parent
sys.path.insert(0, str(evaluator_dir))

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from models import Base, Quest, Subcategory, SQLPattern

def get_connection_string(separate_db: bool = True) -> str:
    """Get database connection string from environment"""
    host = os.getenv('DB_HOST', 'localhost')
    port = os.getenv('DB_PORT', '5432')
    user = quote_plus(os.getenv('DB_USER', 'postgres'))
    password = quote_plus(os.getenv('DB_PASSWORD', 'postgres'))
    
    if separate_db:
        database = os.getenv('EVALUATOR_DB_NAME', 'sql_adventure_db')
    else:
        database = os.getenv('DB_NAME', 'sql_adventure_db')
    
    return f"postgresql://{user}:{password}@{host}:{port}/{database}"

def ensure_database_exists(connection_string: str):
    """Ensure the evaluator database exists"""
    try:
        # Connect to default postgres database to create evaluator database
        base_connection = connection_string.rsplit('/', 1)[0] + '/postgres'
        temp_engine = create_engine(base_connection)
        
        with temp_engine.connect() as conn:
            conn.execute(text("COMMIT"))  # End any existing transaction
            
            # Check if database exists
            db_name = connection_string.split('/')[-1]
            result = conn.execute(text("SELECT 1 FROM pg_database WHERE datname = :dbname").bindparams(dbname=db_name))
            
            if not result.fetchone():
                safe_db = db_name.replace('"', '')
                conn.execute(text(f'CREATE DATABASE "{safe_db}"'))
                print(f"✅ Created evaluator database: {safe_db}")
            else:
                print(f"✅ Evaluator database already exists: {db_name}")
        
        temp_engine.dispose()
        
    except Exception as e:
        print(f"⚠️  Could not ensure database exists: {e}")

def discover_quests_from_filesystem() -> List[Dict[str, Any]]:
    """Discover quests and subcategories from the quests directory"""
    quests_data = []
    quests_dir = Path("quests")
    
    if not quests_dir.exists():
        print(f"⚠️  Quests directory not found: {quests_dir}")
        return quests_data
    
    # Find all quest directories (e.g., 1-data-modeling, 2-performance-tuning)
    quest_dirs = [d for d in quests_dir.iterdir() if d.is_dir() and re.match(r'^\d+-', d.name)]
    quest_dirs.sort(key=lambda x: int(x.name.split('-')[0]))
    
    for quest_dir in quest_dirs:
        quest_name = quest_dir.name
        quest_number = int(quest_name.split('-')[0])
        
        # Extract display name from directory name
        display_name = ' '.join(word.capitalize() for word in quest_name.split('-')[1:])
        
        # Determine difficulty based on quest number and content
        difficulty_level = determine_quest_difficulty(quest_dir)
        
        # Discover subcategories
        subcategories = discover_subcategories(quest_dir, quest_name)
        
        quest_data = {
            'name': quest_name,
            'display_name': display_name,
            'description': generate_quest_description(quest_name, subcategories),
            'difficulty_level': difficulty_level,
            'order_index': quest_number,
            'subcategories': subcategories
        }
        
        quests_data.append(quest_data)
        print(f"🔍 Discovered quest: {display_name} ({len(subcategories)} subcategories)")
    
    return quests_data

def discover_subcategories(quest_dir: Path, quest_name: str) -> List[Tuple[str, str, str, int]]:
    """Discover subcategories within a quest directory"""
    subcategories = []
    
    # Find all subcategory directories (e.g., 00-basic-concepts, 01-normalization-patterns)
    subcategory_dirs = [d for d in quest_dir.iterdir() if d.is_dir() and re.match(r'^\d+-', d.name)]
    subcategory_dirs.sort(key=lambda x: int(x.name.split('-')[0]))
    
    for subcategory_dir in subcategory_dirs:
        subcategory_name = subcategory_dir.name
        subcategory_number = int(subcategory_name.split('-')[0])
        
        # Extract display name
        display_name = ' '.join(word.capitalize() for word in subcategory_name.split('-')[1:])
        
        # Determine difficulty based on subcategory name and content
        difficulty_level = determine_subcategory_difficulty(subcategory_dir, subcategory_name)
        
        subcategories.append((subcategory_name, display_name, difficulty_level, subcategory_number))
    
    return subcategories

def determine_quest_difficulty(quest_dir: Path) -> str:
    """Determine quest difficulty based on content analysis"""
    quest_name = quest_dir.name.lower()
    
    # Analyze subcategory names for difficulty indicators
    subcategory_names = [d.name.lower() for d in quest_dir.iterdir() if d.is_dir()]
    
    # Count SQL files to estimate complexity
    sql_file_count = len(list(quest_dir.rglob("*.sql")))
    
    # Difficulty mapping based on quest name patterns
    if any(word in quest_name for word in ['basic', 'fundamental', 'intro']):
        return 'Beginner'
    elif any(word in quest_name for word in ['advanced', 'expert', 'complex']):
        return 'Expert'
    elif any(word in quest_name for word in ['performance', 'optimization', 'tuning']):
        return 'Intermediate'
    elif any(word in quest_name for word in ['window', 'json', 'recursive']):
        return 'Advanced'
    elif sql_file_count > 20:  # High file count suggests complexity
        return 'Advanced'
    else:
        return 'Intermediate'

def determine_subcategory_difficulty(subcategory_dir: Path, subcategory_name: str) -> str:
    """Determine subcategory difficulty based on name and content"""
    name_lower = subcategory_name.lower()
    
    # Difficulty indicators in subcategory names
    if any(word in name_lower for word in ['basic', 'fundamental', 'intro', '00-']):
        return 'Beginner'
    elif any(word in name_lower for word in ['advanced', 'expert', 'complex']):
        return 'Expert'
    elif any(word in name_lower for word in ['optimization', 'tuning', 'performance']):
        return 'Intermediate'
    elif any(word in name_lower for word in ['window', 'json', 'recursive', 'cte']):
        return 'Advanced'
    else:
        return 'Intermediate'

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

def discover_sql_patterns_from_filesystem() -> List[Tuple[str, str, str, str, str]]:
    """Discover SQL patterns by analyzing actual SQL files"""
    patterns_data = []
    quests_dir = Path("quests")
    
    if not quests_dir.exists():
        print(f"⚠️  Quests directory not found: {quests_dir}")
        return patterns_data
    
    # Collect all SQL files
    sql_files = list(quests_dir.rglob("*.sql"))
    
    # Pattern definitions with regex patterns
    pattern_definitions = {
        # DDL Patterns
        'table_creation': ('Table Creation', 'DDL', 'Basic', r'CREATE\s+TABLE'),
        'index_creation': ('Index Creation', 'DDL', 'Intermediate', r'CREATE\s+(UNIQUE\s+)?INDEX'),
        'constraint_definition': ('Constraint Definition', 'DDL', 'Intermediate', r'CONSTRAINT|PRIMARY\s+KEY|FOREIGN\s+KEY|UNIQUE|CHECK'),
        'view_creation': ('View Creation', 'DDL', 'Intermediate', r'CREATE\s+(OR\s+REPLACE\s+)?VIEW'),
        'schema_creation': ('Schema Creation', 'DDL', 'Intermediate', r'CREATE\s+SCHEMA'),
        
        # DML Patterns
        'data_insertion': ('Data Insertion', 'DML', 'Basic', r'INSERT\s+INTO'),
        'data_update': ('Data Update', 'DML', 'Basic', r'UPDATE\s+'),
        'data_deletion': ('Data Deletion', 'DML', 'Basic', r'DELETE\s+FROM'),
        'data_upsert': ('Data Upsert', 'DML', 'Intermediate', r'INSERT\s+.*ON\s+CONFLICT|MERGE\s+INTO'),
        
        # DQL Patterns
        'simple_select': ('Simple SELECT', 'DQL', 'Basic', r'SELECT\s+.*FROM'),
        'joins': ('JOIN Operations', 'DQL', 'Intermediate', r'(INNER|LEFT|RIGHT|FULL|CROSS)\s+JOIN'),
        'aggregation': ('Aggregation', 'DQL', 'Intermediate', r'GROUP\s+BY|HAVING'),
        'subqueries': ('Subqueries', 'DQL', 'Advanced', r'SELECT\s+.*SELECT'),
        'window_functions': ('Window Functions', 'DQL', 'Advanced', r'OVER\s*\('),
        'cte': ('Common Table Expressions', 'DQL', 'Advanced', r'WITH\s+'),
        'recursive_cte': ('Recursive CTE', 'DQL', 'Expert', r'WITH\s+RECURSIVE'),
        
        # Performance Patterns
        'explain_plan': ('EXPLAIN Plan', 'DQL', 'Intermediate', r'EXPLAIN'),
        'index_usage': ('Index Usage', 'DQL', 'Intermediate', r'INDEX|USING\s+INDEX'),
        'query_optimization': ('Query Optimization', 'DQL', 'Advanced', r'OPTIMIZATION|HINT'),
        'partitioning': ('Partitioning', 'DQL', 'Expert', r'PARTITION'),
        
        # JSON Patterns
        'json_parsing': ('JSON Parsing', 'JSON', 'Intermediate', r'->|->>|#>>|#>'),
        'json_aggregation': ('JSON Aggregation', 'JSON', 'Advanced', r'JSON_|json_'),
        'json_construction': ('JSON Construction', 'JSON', 'Intermediate', r'TO_JSON|JSON_BUILD'),
        
        # Advanced Patterns
        'full_text_search': ('Full Text Search', 'DQL', 'Advanced', r'@@|to_tsvector|to_tsquery'),
        'array_operations': ('Array Operations', 'DQL', 'Intermediate', r'ARRAY|unnest|array_'),
        'temporal_queries': ('Temporal Queries', 'DQL', 'Intermediate', r'INTERVAL|DATE_TRUNC|EXTRACT'),
        'geospatial': ('Geospatial', 'DQL', 'Expert', r'ST_|geometry|geography'),
    }
    
    # Analyze SQL files to detect pattern usage
    pattern_usage = {pattern_name: 0 for pattern_name in pattern_definitions.keys()}
    
    for sql_file in sql_files:
        try:
            content = sql_file.read_text(encoding='utf-8', errors='ignore')
            content_upper = content.upper()
            
            for pattern_name, (display_name, category, complexity, regex) in pattern_definitions.items():
                if re.search(regex, content_upper, re.IGNORECASE):
                    pattern_usage[pattern_name] += 1
        except Exception as e:
            print(f"⚠️  Error reading {sql_file}: {e}")
    
    # Create patterns that are actually used
    for pattern_name, usage_count in pattern_usage.items():
        if usage_count > 0:  # Only include patterns that are actually used
            display_name, category, complexity, regex = pattern_definitions[pattern_name]
            patterns_data.append((pattern_name, display_name, category, complexity, regex))
            print(f"🔍 Discovered pattern: {display_name} (used in {usage_count} files)")
    
    return patterns_data

def init_quest_data(session, quests_data: List[Dict[str, Any]]):
    """Initialize quest and subcategory data from discovered data"""
    for quest_data in quests_data:
        # Check if quest exists
        existing_quest = session.query(Quest).filter_by(name=quest_data['name']).first()
        if not existing_quest:
            quest = Quest(
                name=quest_data['name'],
                display_name=quest_data['display_name'],
                description=quest_data['description'],
                difficulty_level=quest_data['difficulty_level'],
                order_index=quest_data['order_index']
            )
            session.add(quest)
            session.flush()  # Get the quest ID
            
            # Add subcategories
            for sub_name, sub_display, sub_difficulty, sub_order in quest_data['subcategories']:
                subcategory = Subcategory(
                    quest_id=quest.id,
                    name=sub_name,
                    display_name=sub_display,
                    difficulty_level=sub_difficulty,
                    order_index=sub_order
                )
                session.add(subcategory)
            
            print(f"✅ Added quest: {quest_data['display_name']}")

def init_pattern_data(session, patterns_data: List[Tuple[str, str, str, str, str]]):
    """Initialize SQL pattern catalog from discovered data"""
    for pattern_name, display_name, category, complexity, regex in patterns_data:
        existing_pattern = session.query(SQLPattern).filter_by(name=pattern_name).first()
        if not existing_pattern:
            pattern = SQLPattern(
                name=pattern_name,
                display_name=display_name,
                category=category,
                complexity_level=complexity,
                detection_regex=regex
            )
            session.add(pattern)
            print(f"✅ Added pattern: {display_name}")

def main():
    """Main initialization function"""
    print("🚀 Initializing SQL Adventure Evaluator Database")
    print("🔍 Using discovery features to avoid hardcoded maintenance...")
    
    try:
        # Get connection string
        connection_string = get_connection_string(separate_db=True)
        print(f"📡 Using connection: {connection_string.split('@')[1]}")
        
        # Ensure database exists
        ensure_database_exists(connection_string)
        
        # Create engine and tables
        engine = create_engine(connection_string, echo=False)
        Base.metadata.create_all(bind=engine)
        print("✅ Database tables created")
        
        # Initialize session
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        session = SessionLocal()
        
        # Discover and initialize quest data
        print("📚 Discovering quests from filesystem...")
        quests_data = discover_quests_from_filesystem()
        init_quest_data(session, quests_data)
        
        # Discover and initialize pattern data
        print("🔍 Discovering SQL patterns from filesystem...")
        patterns_data = discover_sql_patterns_from_filesystem()
        init_pattern_data(session, patterns_data)
        
        # Commit changes
        session.commit()
        session.close()
        
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