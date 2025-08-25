"""
Discovery module for SQL Adventure
Scans filesystem for quests, subcategories, and SQL patterns
Returns structured data for database sync or evaluation
"""

import re
import statistics
from pathlib import Path
from typing import List, Dict, Tuple, Any

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
    subcats: List[Tuple[str, str, str, str, int]] = discover_subcategories_from_filesystem(quest_dir, quest_dir.name)
    levels: List[int] = []
    for sub_name, _, _, _, _ in subcats:
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
    for sub_name, _, _, _, _ in subcats:
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
    """Determine subcategory difficulty from its SQL files."""
    if not subcategory_path.is_dir():
        return default
    
    # Collect difficulty levels from all SQL files in the subcategory
    difficulty_levels = []
    for sql_file in subcategory_path.glob('*.sql'):
        file_difficulty = infer_difficulty(sql_file, default)
        level_score = LEVEL_ORDER.get(file_difficulty, LEVEL_ORDER[default])
        difficulty_levels.append(level_score)
    
    if not difficulty_levels:
        return default
    
    # Use the most common difficulty, or average if tied
    import statistics
    avg_level = statistics.mean(difficulty_levels)
    
    # Map back to difficulty string
    for level_name, level_value in LEVEL_ORDER.items():
        if abs(level_value - avg_level) < 0.5:
            return level_name
    
    return default

def generate_quest_description(quest_name: str, subcategories: List[Tuple[str, str, str, str, int]]) -> str:
    """
    Generate quest description using AI agent if available, fallback to content-based method otherwise.
    """
    try:
        from utils.summarizers import generate_quest_description_ai, generate_quest_description_fallback
        import asyncio
        
        # Aggregate all quest content into a single text
        aggregated_content = f"Quest: {quest_name}\n"
        
        # Add subcategory information
        if subcategories:
            aggregated_content += "Subcategories:\n"
            for sub_name, display_name, difficulty, description, order in subcategories:
                aggregated_content += f"- {display_name} ({difficulty}): {description}\n"
        
        # Try AI description first
        try:
            # Try to get existing event loop, create new one if needed
            try:
                loop = asyncio.get_event_loop()
                if loop.is_running():
                    # If loop is already running, use fallback
                    return generate_quest_description_fallback(aggregated_content)
            except RuntimeError:
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
            
            description = loop.run_until_complete(generate_quest_description_ai(aggregated_content))
            return description
        except Exception as e:
            print(f"⚠️  AI quest description failed: {e}")
            # Fallback to simple description
            return generate_quest_description_fallback(aggregated_content)
            
    except Exception:
        # Final fallback to previous content-based method
        if not subcategories:
            quest_type = '-'.join(quest_name.split('-')[1:])
            return f"SQL {quest_type.replace('-', ' ')} exercises and concepts"
        subcategory_names = [display_name for _, display_name, _, _, _ in subcategories]
        if len(subcategory_names) == 1:
            return f"Focused training on {subcategory_names[0].lower()}"
        elif len(subcategory_names) <= 3:
            return f"Comprehensive coverage of {', '.join(subcategory_names).lower()}"
        else:
            primary_topics = subcategory_names[:2]
            remaining_count = len(subcategory_names) - 2
            return f"In-depth exploration of {', '.join(primary_topics).lower()} and {remaining_count} additional topics"


def discover_subcategories_from_filesystem(quest_dir: Path, quest_name: str) -> List[Tuple[str, str, str, str, int]]:
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
        
        # Determine difficulty based on SQL files in subcategory
        difficulty_level = determine_subcategory_difficulty(subcategory_dir)
        
        # Generate description using AI summarization
        try:
            from utils.summarizers import generate_subcategory_description
            description = generate_subcategory_description(subcategory_dir)
        except Exception as e:
            print(f"⚠️  Error generating description for {subcategory_name}: {e}")
            # Fallback description
            description = f"Training exercises focused on {display_name.lower()}"
        
        subcategories.append((subcategory_name, display_name, difficulty_level, description, subcategory_number))
    
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
            for sub_index, (sub_name, sub_display, sub_difficulty, sub_description, _) in enumerate(subcategories_tuples):
                subcategories_list.append((sub_name, sub_display, sub_difficulty, sub_description, sub_index))
            
            # Determine quest difficulty based on subcategories
            difficulty = determine_quest_difficulty(quest_path)
            
            # Generate AI-powered quest description (temporarily using fallback for testing)
            # description = generate_quest_description(quest_name, subcategories_tuples)
            description = f"Master {quest_title.lower()} through interactive exercises: from fundamental concepts to advanced techniques and real-world applications."
            
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


# =============================================================================
# ENHANCED PATTERN DISCOVERY WITH AI DESCRIPTIONS
# =============================================================================

async def generate_enhanced_sql_patterns() -> List[Dict[str, Any]]:
    """Generate enhanced SQL patterns with AI-powered descriptions"""
    import asyncio
    from core.agents import pattern_description_agent
    
    # Enhanced pattern definitions with context for AI analysis
    pattern_contexts = {
        'table_creation': {
            'base_description': 'CREATE TABLE statements with column definitions, data types, and constraints',
            'examples': ['CREATE TABLE users (id INT PRIMARY KEY, name VARCHAR(50))', 'CREATE TABLE products (product_id SERIAL, price DECIMAL(10,2))'],
            'category': 'DDL',
            'complexity': 'Basic'
        },
        'index_creation': {
            'base_description': 'CREATE INDEX statements for query performance optimization',
            'examples': ['CREATE INDEX idx_user_email ON users(email)', 'CREATE UNIQUE INDEX idx_product_sku ON products(sku)'],
            'category': 'DDL', 
            'complexity': 'Intermediate'
        },
        'constraint_definition': {
            'base_description': 'Table constraints including PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK, NOT NULL',
            'examples': ['ALTER TABLE orders ADD CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES customers(id)', 'CHECK (price > 0)'],
            'category': 'DDL',
            'complexity': 'Intermediate'
        },
        'view_creation': {
            'base_description': 'CREATE VIEW statements for virtual tables and data abstraction',
            'examples': ['CREATE VIEW active_users AS SELECT * FROM users WHERE is_active = true', 'CREATE OR REPLACE VIEW customer_summary AS...'],
            'category': 'DDL',
            'complexity': 'Intermediate'
        },
        'data_insertion': {
            'base_description': 'INSERT INTO statements for adding new records to tables',
            'examples': ['INSERT INTO users (name, email) VALUES (\'John\', \'john@email.com\')', 'INSERT INTO products SELECT * FROM temp_products'],
            'category': 'DML',
            'complexity': 'Basic'
        },
        'data_update': {
            'base_description': 'UPDATE statements for modifying existing records',
            'examples': ['UPDATE users SET email = \'new@email.com\' WHERE id = 1', 'UPDATE products SET price = price * 1.1 WHERE category = \'electronics\''],
            'category': 'DML',
            'complexity': 'Basic'
        },
        'simple_select': {
            'base_description': 'Basic SELECT statements with WHERE, ORDER BY, LIMIT clauses',
            'examples': ['SELECT name, email FROM users WHERE is_active = true', 'SELECT * FROM products ORDER BY price DESC LIMIT 10'],
            'category': 'DQL',
            'complexity': 'Basic'
        },
        'join_operations': {
            'base_description': 'INNER, LEFT, RIGHT, FULL OUTER, and CROSS JOIN operations',
            'examples': ['SELECT u.name, o.total FROM users u JOIN orders o ON u.id = o.user_id', 'LEFT JOIN products p ON oi.product_id = p.id'],
            'category': 'DQL',
            'complexity': 'Intermediate'
        },
        'aggregation': {
            'base_description': 'GROUP BY, HAVING, and aggregate functions (COUNT, SUM, AVG, MAX, MIN)',
            'examples': ['SELECT category, AVG(price) FROM products GROUP BY category', 'SELECT user_id, COUNT(*) FROM orders GROUP BY user_id HAVING COUNT(*) > 5'],
            'category': 'DQL',
            'complexity': 'Intermediate'
        },
        'window_functions': {
            'base_description': 'OVER clause with ROW_NUMBER, RANK, LEAD, LAG, and partition operations',
            'examples': ['SELECT name, salary, ROW_NUMBER() OVER (ORDER BY salary DESC) FROM employees', 'LAG(price) OVER (PARTITION BY category ORDER BY date)'],
            'category': 'ANALYTICS',
            'complexity': 'Advanced'
        },
        'common_table_expressions': {
            'base_description': 'WITH clauses for temporary named result sets and query organization',
            'examples': ['WITH high_value_customers AS (SELECT user_id FROM orders GROUP BY user_id HAVING SUM(total) > 1000)', 'WITH RECURSIVE...'],
            'category': 'DQL',
            'complexity': 'Advanced'
        },
        'recursive_cte': {
            'base_description': 'WITH RECURSIVE for hierarchical data traversal and graph operations',
            'examples': ['WITH RECURSIVE employee_hierarchy AS (SELECT id, name, manager_id FROM employees WHERE manager_id IS NULL UNION...)', 'WITH RECURSIVE path_finder...'],
            'category': 'RECURSIVE',
            'complexity': 'Expert'
        },
        'json_parsing': {
            'base_description': 'JSON operators (->, ->>, #>, #>>) for extracting data from JSON columns',
            'examples': ['SELECT data->>\'name\' FROM users WHERE data->\'age\' > \'25\'', 'SELECT jsonb_extract_path(config, \'database\', \'host\') FROM settings'],
            'category': 'JSON',
            'complexity': 'Intermediate'
        },
        'json_aggregation': {
            'base_description': 'JSON_AGG, JSON_OBJECT_AGG for converting relational data to JSON format',
            'examples': ['SELECT JSON_AGG(name) FROM users', 'SELECT JSON_OBJECT_AGG(id, name) FROM products'],
            'category': 'JSON',
            'complexity': 'Advanced'
        },
        'explain_plan': {
            'base_description': 'EXPLAIN and EXPLAIN ANALYZE for query performance analysis',
            'examples': ['EXPLAIN SELECT * FROM users WHERE email = \'test@example.com\'', 'EXPLAIN (ANALYZE, BUFFERS) SELECT...'],
            'category': 'ANALYTICS',
            'complexity': 'Advanced'
        },
        'index_usage': {
            'base_description': 'Query optimization techniques using indexes effectively',
            'examples': ['SELECT * FROM products WHERE category = \'electronics\' -- uses idx_products_category', 'WHERE date_created >= \'2024-01-01\' -- uses idx_products_date'],
            'category': 'ANALYTICS',
            'complexity': 'Advanced'
        },
        'query_optimization': {
            'base_description': 'Performance tuning through query rewriting and optimization techniques',
            'examples': ['EXISTS vs IN performance comparisons', 'Subquery to JOIN conversions for better performance'],
            'category': 'ANALYTICS',
            'complexity': 'Expert'
        },
        'partitioning': {
            'base_description': 'Table partitioning for large dataset management and performance',
            'examples': ['CREATE TABLE orders_2024 PARTITION OF orders FOR VALUES FROM (\'2024-01-01\') TO (\'2025-01-01\')', 'PARTITION BY RANGE (date_created)'],
            'category': 'DDL',
            'complexity': 'Expert'
        },
        'temporal_queries': {
            'base_description': 'Date and time operations, intervals, and temporal data analysis',
            'examples': ['SELECT * FROM orders WHERE created_at >= CURRENT_DATE - INTERVAL \'30 days\'', 'DATE_TRUNC(\'month\', order_date)'],
            'category': 'DQL',
            'complexity': 'Intermediate'
        },
        'array_operations': {
            'base_description': 'PostgreSQL array data type operations: creation, indexing, searching, and aggregation',
            'examples': ['SELECT * FROM products WHERE tags @> ARRAY[\'electronics\', \'mobile\']', 'SELECT UNNEST(string_to_array(categories, \',\')) as category FROM products'],
            'category': 'ANALYTICS',
            'complexity': 'Advanced'
        },
        'full_text_search': {
            'base_description': 'PostgreSQL full-text search with tsvector, tsquery, and ranking',
            'examples': ['SELECT * FROM articles WHERE to_tsvector(title || \' \' || content) @@ to_tsquery(\'database & optimization\')', 'CREATE INDEX idx_articles_search ON articles USING gin(to_tsvector(\'english\', title || \' \' || content))'],
            'category': 'ANALYTICS',
            'complexity': 'Expert'
        },
        'geospatial': {
            'base_description': 'PostGIS spatial queries for geographic data analysis and location-based operations',
            'examples': ['SELECT * FROM stores WHERE ST_DWithin(location, ST_Point(-122.4194, 37.7749), 1000)', 'SELECT ST_Area(ST_Transform(geometry, 3857)) FROM parcels'],
            'category': 'ANALYTICS',
            'complexity': 'Expert'
        }
    }
    
    enhanced_patterns = []
    
    for pattern_name, context in pattern_contexts.items():
        print(f"🧠 Generating AI description for pattern: {pattern_name}")
        
        # Create prompt for AI analysis
        prompt = f"""
        Analyze this SQL pattern and create an educational description:
        
        Pattern: {pattern_name.replace('_', ' ').title()}
        Technical Description: {context['base_description']}
        Examples: {'; '.join(context['examples'][:2])}
        Category: {context['category']}
        Complexity: {context['complexity']}
        
        Create a comprehensive description that explains:
        1. What this pattern accomplishes
        2. When developers should use it
        3. Its practical value in real applications
        
        Keep it concise but educational (2-3 sentences).
        """
        
        try:
            result = await pattern_description_agent.run(prompt)
            ai_description = result.data if hasattr(result, 'data') else str(result)
        except Exception as e:
            print(f"⚠️  AI generation failed for {pattern_name}: {e}")
            ai_description = context['base_description']
        
        enhanced_patterns.append({
            'name': pattern_name,
            'display_name': pattern_name.replace('_', ' ').title(),
            'description': ai_description,
            'category': context['category'],
            'complexity_level': context['complexity']
        })
        
        # Small delay to avoid rate limiting
        await asyncio.sleep(0.1)
    
    return enhanced_patterns
