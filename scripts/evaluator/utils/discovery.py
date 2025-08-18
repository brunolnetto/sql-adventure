"""
Discovery module for SQL Adventure
Scans filesystem for quests, subcategories, and SQL patterns
Returns structured data for database sync or evaluation
"""

import re
from pathlib import Path
from typing import List, Dict, Tuple, Any

HEADER_PATTERN = re.compile(r"^--\s*(?P<key>\w+):\s*(?P<value>.+)$", re.IGNORECASE)

class MetadataExtractor:
    """Extrai metadados do cabeçalho de comentários SQL."""

    @staticmethod
    def parse_header(sql_content: str, delimiter: str) -> Dict[str, str]:
        metadata: Dict[str, str] = {}
        for line in sql_content.splitlines():
            match = HEADER_PATTERN.match(line)
            if not match:
                # headers estão no início; interrompa ao encontrar primeira linha de código
                if not line.strip().startswith("--"): break
                continue
            key = match.group("key").strip().lower()
            value = match.group("value").strip()
            metadata[key] = value
        return metadata


# Map normalized labels to canonical levels
LEVEL_KEYWORDS = {
    'beginner': ['beginner', '🟢', 'green'],
    'intermediate': ['intermediate', '🟡', 'yellow'],
    'advanced': ['advanced', '🔴', 'red'],
    'expert': ['expert', '⚫', 'black']
}

LEVEL_ORDER = {level.capitalize(): idx for idx, level in enumerate(LEVEL_KEYWORDS, start=1)}
ORDER_LEVEL = {v: k for k, v in LEVEL_ORDER.items()}

def parse_header_level(raw: str) -> str:
    """
    Normalize a raw difficulty string from header into one of the four levels.
    """
    text = raw.lower()
    for level, keywords in LEVEL_KEYWORDS.items():
        if any(k in text for k in keywords):
            return level.capitalize()

    # Fallback if numeric time estimate found
    if re.search(r"\d+\s*-\s*\d+\s*min", text):
        # assume short indicates beginner
        return 'Beginner'
    return None

def determine_quest_difficulty(
    quest_dir: Path,
    default: str = 'Intermediate'
) -> str:
    """
    Determine a quest's difficulty by:
    1) Checking for any SQL header override under the quest directory.
    2) Otherwise, aggregating per-file difficulties across subcategories.
    """
    # 1) Global header override
    for sql_file in quest_dir.rglob('*.sql'):
        try:
            meta = MetadataExtractor.parse_header(sql_file.read_text())
            if 'difficulty' in meta:
                normalized = parse_header_level(meta['difficulty'])
                if normalized:
                    return normalized
        except Exception:
            continue

    # 2) Aggregate subcategory/file difficulties
    subcats: List[Tuple[str, str, str, int]] = discover_subcategories_from_filesystem(quest_dir, quest_dir.name)
    levels: List[int] = []
    for sub_name, _, _, _ in subcats:
        sub_dir = quest_dir / sub_name
        for sql_file in sub_dir.rglob('*.sql'):
            lvl_str = infer_difficulty(sql_file, default)
            levels.append(LEVEL_ORDER.get(lvl_str, LEVEL_ORDER[default]))

    if not levels:
        return default
    avg = sum(levels) / len(levels)
    quest_value = int(avg + 0.5)
    return ORDER_LEVEL.get(quest_value, default)

def infer_difficulty(
    sql_file_path: Path, default: str = 'Intermediate'
) -> str:
    """
    Infer difficulty from a single SQL file's header.

    1) Parse the file header for a 'DIFFICULTY:' line.
    2) Normalize and return if valid.
    3) Otherwise return the default.
    """
    try:
        content = sql_file_path.read_text(encoding='utf-8', errors='ignore')
        metadata: Dict[str, str] = MetadataExtractor.parse_header(content)
        if 'difficulty' in metadata:
            normalized = parse_header_level(metadata['difficulty'])
            if normalized:
                return normalized
    except Exception:
        pass

    # If no valid difficulty found, return default
    return default

HEADER_PATTERN = re.compile(r"^--\s*(?P<key>\w+):\s*(?P<value>.+)$", re.IGNORECASE)


# Map normalized labels to canonical levels
LEVEL_KEYWORDS = {
    'beginner': ['beginner', '🟢', 'green'],
    'intermediate': ['intermediate', '🟡', 'yellow'],
    'advanced': ['advanced', '🟠', 'orange'],
    'expert': ['expert', '🔴', 'red']
}

LEVEL_ORDER = {
    level.capitalize(): idx 
    for idx, level in enumerate(LEVEL_KEYWORDS, start=1)
}
ORDER_LEVEL = {v: k for k, v in LEVEL_ORDER.items()}

def parse_header_level(raw: str) -> str:
    """
    Normalize a raw difficulty string from header into one of the four levels.
    """
    text = raw.lower()
    for level, keywords in LEVEL_KEYWORDS.items():
        if any(k in text for k in keywords):
            return level.capitalize()

    return None

def determine_quest_difficulty(
    quest_dir: Path,
    default: str = 'Intermediate'
) -> str:
    """
    Determine a quest's difficulty by:
      1) Global header override: any SQL with DIFFICULTY header under quest_dir.
      2) Aggregate per-file difficulties across its subcategories.
    """
    # 1) Global override
    for sql_file in quest_dir.rglob('*.sql'):
        try:
            meta = MetadataExtractor.parse_header(sql_file.read_text(encoding='utf-8', errors='ignore'))
            if 'difficulty' in meta:
                lvl = parse_header_level(meta['difficulty'])
                if lvl:
                    return lvl
        except Exception:
            continue

    # 2) Aggregate from subcategories
    subcats: List[Tuple[str, str, str, int]] = discover_subcategories_from_filesystem(quest_dir, quest_dir.name)
    levels: List[int] = []
    for sub_name, _, _, _ in subcats:
        sub_dir = quest_dir / sub_name
        for sql_file in sub_dir.rglob('*.sql'):
            lvl_str = infer_difficulty(sql_file, default)
            levels.append(LEVEL_ORDER.get(lvl_str, LEVEL_ORDER[default]))

    if not levels:
        return default

    avg = sum(levels) / len(levels)
    quest_value = int(avg + 0.5)
    return ORDER_LEVEL.get(quest_value, default)

def determine_subcategory_difficulty(
    subcategory_path: Path, default: str = 'Intermediate'
) -> str:
    return infer_difficulty(subcategory_path, default)

def determine_subcategory_difficulty(
    subcategory_path: Path, default: str = 'Intermediate'
) -> str:
    return infer_difficulty(subcategory_path, default)

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

def discover_quests_from_filesystem(quests_dir: Path) -> List[Dict[str, Any]]:
    """Discover quests and subcategories from the quests directory"""
    quests_data = []
    
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
        subcategories = discover_subcategories_from_filesystem(quest_dir, quest_name)
        
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

def discover_subcategories_from_filesystem(quest_dir: Path, quest_name: str) -> List[Tuple[str, str, str, int]]:
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

# Pattern definitions with regex patterns
PatternType = Tuple[str, str, str, str]  # (display_name, category, complexity, regex)

PATTERN_DEFINITIONS: PatternType = {
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

def detect_sql_patterns(sql_content: str) -> PatternType:
    """Detect SQL patterns in the given SQL content"""
    patterns_data = []
    content_upper = sql_content.upper()

    for pattern_name, (display_name, category, complexity, regex) in PATTERN_DEFINITIONS.items():
        if re.search(regex, content_upper, re.IGNORECASE):
            patterns_data.append((pattern_name, display_name, category, complexity, regex))

    return patterns_data

def discover_sql_patterns_from_filesystem() -> :
    """Discover SQL patterns by analyzing actual SQL files"""
    patterns_data = []
    quests_dir = Path("quests")

    if not quests_dir.exists():
        print(f"⚠️  Quests directory not found: {quests_dir}")
        return patterns_data

    sql_files = list(quests_dir.rglob("*.sql"))
    pattern_usage = {pattern_name: 0 for pattern_name in PATTERN_DEFINITIONS.keys()}

    for sql_file in sql_files:
        try:
            content = sql_file.read_text(encoding='utf-8', errors='ignore')
            matched_patterns = detect_sql_patterns(content)
            for pattern_name, *_ in matched_patterns:
                pattern_usage[pattern_name] += 1
        except Exception as e:
            print(f"⚠️  Error reading {sql_file}: {e}")

    for pattern_name, usage_count in pattern_usage.items():
        if usage_count > 0:
            display_name, category, complexity, regex = PATTERN_DEFINITIONS[pattern_name]
            patterns_data.append((pattern_name, display_name, category, complexity, regex))
            print(f"🔍 Discovered pattern: {display_name} (used in {usage_count} files)")

    return patterns_data
