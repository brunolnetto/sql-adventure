"""
Discovery module for SQL Adventure
Scans filesystem for quests, subcategories, and SQL patterns
Returns structured data for database sync or evaluation
"""

import re
from pathlib import Path
from typing import List, Dict, Tuple, Any

# Regex pattern for parsing SQL comment headers
HEADER_PATTERN = re.compile(r"^--\s*(?P<key>\w+):\s*(?P<value>.+)$", re.IGNORECASE)


# Import difficulty logic from unified module
from utils.difficulty import (
    LEVEL_KEYWORDS,
    LEVEL_ORDER,
    ORDER_LEVEL,
    DifficultyStrategy,
    determine_quest_difficulty,
    parse_header_level
)


class MetadataExtractor:
    """Extract metadata from SQL comment headers."""

    @staticmethod
    def parse_header(sql_content: str, delimiter: str = ":") -> Dict[str, str]:
        metadata: Dict[str, str] = {}
        for line in sql_content.splitlines():
            match = HEADER_PATTERN.match(line)
            if not match:
                # Headers are at the beginning; stop at first code line
                if not line.strip().startswith("--"): 
                    break
                continue
            key = match.group("key").strip().lower()
            value = match.group("value").strip()
            metadata[key] = value
        return metadata



# Use parse_header_level from difficulty.py


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

    # Enhanced difficulty calculation with outlier handling
    import statistics
    from collections import Counter
    
    # Collect level strings for modal analysis
    level_strings = []
    for sub_name, _, _, _ in subcats:
        sub_dir = quest_dir / sub_name
        for sql_file in sub_dir.rglob('*.sql'):
            lvl_str = infer_difficulty(sql_file, default)
            level_strings.append(lvl_str)
    
    # For small quests (<=5 files), use modal approach to avoid outlier bias
    if len(levels) <= 5:
        level_counts = Counter(level_strings)
        return level_counts.most_common(1)[0][0]
    
    # For larger quests, check for high variance (suggests outliers)
    if len(levels) > 2:
        variance = statistics.variance(levels)
        if variance > 1.5:  # High variance indicates outliers present
            level_counts = Counter(level_strings)
            return level_counts.most_common(1)[0][0]
    
    # Standard case: improved average with proper rounding
    avg = statistics.mean(levels)
    quest_value = round(avg)  # Use proper rounding instead of int(avg + 0.5)
    
    # Bounds checking to ensure valid difficulty level
    quest_value = max(1, min(quest_value, len(ORDER_LEVEL)))
    
    return ORDER_LEVEL.get(quest_value, default)


def determine_subcategory_difficulty(
    subcategory_path: Path, default: str = 'Intermediate'
) -> str:
    """Determine subcategory difficulty from its content."""
    return infer_difficulty(subcategory_path, default)

def generate_quest_description(quest_name: str, subcategories: List[Tuple[str, str, str, int]]) -> str:
    """
    Generate quest description using AI agent if available, fallback to content-based method otherwise.
    """
    try:
        from .quest_summary import generate_quest_description_ai, generate_quest_description_fallback
        import asyncio
        
        # Aggregate all quest content into a single text
        aggregated_content = f"Quest: {quest_name}\n"
        
        # Add subcategory information
        if subcategories:
            aggregated_content += "Subcategories:\n"
            for sub_name, display_name, difficulty, order in subcategories:
                aggregated_content += f"- {display_name} ({difficulty})\n"
        
        # Try AI description first
        try:
            loop = asyncio.get_event_loop()
            description = loop.run_until_complete(generate_quest_description_ai(aggregated_content))
            return description
        except Exception:
            # Fallback to simple description
            return generate_quest_description_fallback(aggregated_content)
            
    except Exception:
        # Final fallback to previous content-based method
        if not subcategories:
            quest_type = '-'.join(quest_name.split('-')[1:])
            return f"SQL {quest_type.replace('-', ' ')} exercises and concepts"
        subcategory_names = [display_name for _, display_name, _, _ in subcategories]
        if len(subcategory_names) == 1:
            return f"Focused training on {subcategory_names[0].lower()}"
        elif len(subcategory_names) <= 3:
            return f"Comprehensive coverage of {', '.join(subcategory_names).lower()}"
        else:
            primary_topics = subcategory_names[:2]
            remaining_count = len(subcategory_names) - 2
            return f"In-depth exploration of {', '.join(primary_topics).lower()} and {remaining_count} additional topics"


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
        difficulty_level = determine_subcategory_difficulty(subcategory_dir)
        
        subcategories.append((subcategory_name, display_name, difficulty_level, subcategory_number))
    
    return subcategories


# Pattern definitions with regex patterns
PatternType = Tuple[str, str, str, str]  # (display_name, category, complexity, regex)

PATTERN_DEFINITIONS: Dict[str, PatternType] = {
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

def discover_sql_patterns_from_filesystem() -> List[Tuple[str, str, str, str, str]]:
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


def discover_quests_from_filesystem(quests_dir: Path) -> List[Dict[str, Any]]:
    """
    Discover all quests from the filesystem.
    
    Args:
        quests_dir: Path to the quests directory
        
    Returns:
        List of dictionaries with quest data for repository persistence
    """
    quests_data = []
    
    if not quests_dir.exists():
        print(f"⚠️  Quests directory not found: {quests_dir}")
        return quests_data
    
    # Iterate through quest directories
    for quest_index, quest_path in enumerate(sorted(quests_dir.iterdir())):
        if quest_path.is_dir() and not quest_path.name.startswith('.'):
            quest_name = quest_path.name
            
            # Generate quest title from directory name
            quest_title = quest_name.replace('-', ' ').title()
            
            # Discover subcategories for this quest
            subcategories_tuples = discover_subcategories_from_filesystem(quest_path, quest_name)
            
            # Convert subcategory tuples to the format expected by repository
            subcategories_list = []
            for sub_index, (sub_name, sub_display, sub_difficulty, _) in enumerate(subcategories_tuples):
                subcategories_list.append((sub_name, sub_display, sub_difficulty, sub_index))
            
            # Determine quest difficulty based on subcategories
            difficulty = determine_quest_difficulty(quest_path)
            
            # Generate a basic description for future improvements
            description = f"SQL training focusing on {quest_title.lower()} concepts and techniques."
            
            quest_data = {
                'name': quest_name,
                'display_name': quest_title,
                'description': description,
                'difficulty_level': difficulty,
                'order_index': quest_index,
                'subcategories': subcategories_list
            }
            
            quests_data.append(quest_data)
            print(f"🎯 Discovered quest: {quest_title} ({len(subcategories_list)} subcategories, {difficulty} difficulty)")
    
    return quests_data
