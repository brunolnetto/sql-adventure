"""
Discovery module for SQL Adventure
Scans filesystem for quests, subcategories, and SQL patterns
Returns structured data for database sync or evaluation
"""

import os
import re
import statistics
from pathlib import Path
from typing import List, Dict, Tuple, Any

# Regex pattern for parsing SQL comment headers
HEADER_PATTERN = re.compile(r"^--\s*(?P<key>\w+):\s*(?P<value>.+)$", re.IGNORECASE)


# Import difficulty logic from unified module
from .difficulty import (
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


def discover_subcategories_from_filesystem(quest_dir: Path, quest_name: str) -> List[Tuple[str, str, str, str, int]]:
    """Discover subcategories within a quest directory (wrapper for parallel/sequential execution)"""
    import asyncio

    try:
        # Check if we're already in an event loop
        loop = asyncio.get_running_loop()
        # If we're in an event loop, use sequential processing to avoid nested event loops
        print("🔄 Event loop detected, using sequential processing for subcategories")
        return _discover_subcategories_sequential(quest_dir, quest_name)
    except RuntimeError:
        # No event loop running, we can use asyncio.run for parallel processing
        try:
            print("⚡ No event loop, using parallel processing for subcategories")
            return asyncio.run(discover_subcategories_parallel(quest_dir, quest_name))
        except Exception as e:
            print(f"⚠️  Parallel processing failed: {e}, falling back to sequential")
            return _discover_subcategories_sequential(quest_dir, quest_name)


def _discover_subcategories_sequential(quest_dir: Path, quest_name: str) -> List[Tuple[str, str, str, str, int]]:
    """Sequential fallback for subcategory discovery"""
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

        # Generate description using AI summarization with timeout
        try:
            # Check if AI should be disabled
            if os.getenv("DISABLE_AI_SUMMARIZATION", "false").lower() == "true":
                print(f"🤖 AI summarization disabled, using fallback for subcategory: {subcategory_name}")
                raise Exception("AI disabled by environment variable")

            from .summarizers import generate_subcategory_description

            import signal
            from contextlib import contextmanager

            @contextmanager
            def timeout_context(seconds: int):
                def timeout_handler(signum, frame):
                    raise TimeoutError(f"AI description timed out after {seconds} seconds")

                signal.signal(signal.SIGALRM, timeout_handler)
                signal.alarm(seconds)
                try:
                    yield
                finally:
                    signal.alarm(0)

            print(f"🤖 Generating AI description for subcategory: {subcategory_name}")
            with timeout_context(20):  # 20 second timeout for subcategory AI calls
                description = generate_subcategory_description(subcategory_dir)
            print(f"✅ AI description generated for subcategory: {subcategory_name}")

        except TimeoutError:
            print(f"⏰ AI description timed out for subcategory: {subcategory_name}, using fallback")
            description = f"Training exercises focused on {display_name.lower()}"
        except Exception as e:
            print(f"⚠️  Error generating description for {subcategory_name}: {e}")
            # Fallback description
            description = f"Training exercises focused on {display_name.lower()}"

        subcategories.append((subcategory_name, display_name, difficulty_level, description, subcategory_number))

    return subcategories


async def discover_subcategories_parallel(quest_dir: Path, quest_name: str) -> List[Tuple[str, str, str, str, int]]:
    """Discover subcategories with parallel AI description generation"""
    import asyncio
    from concurrent.futures import ThreadPoolExecutor

    subcategories = []

    # Find all subcategory directories
    subcategory_dirs = [d for d in quest_dir.iterdir() if d.is_dir() and re.match(r'^\d+-', d.name)]
    subcategory_dirs.sort(key=lambda x: int(x.name.split('-')[0]))

    # Prepare subcategory data without AI descriptions first
    subcat_data = []
    for subcategory_dir in subcategory_dirs:
        subcategory_name = subcategory_dir.name
        subcategory_number = int(subcategory_name.split('-')[0])
        display_name = ' '.join(word.capitalize() for word in subcategory_name.split('-')[1:])
        difficulty_level = determine_subcategory_difficulty(subcategory_dir)

        subcat_data.append((subcategory_dir, subcategory_name, display_name, difficulty_level, subcategory_number))

    # Check if AI is disabled
    disable_ai = os.getenv("DISABLE_AI_SUMMARIZATION", "false").lower() == "true"
    if disable_ai:
        print("🤖 AI summarization disabled, using fallback descriptions")
        for subcat_dir, subcat_name, display_name, difficulty_level, subcategory_number in subcat_data:
            description = f"Training exercises focused on {display_name.lower()}"
            subcategories.append((subcat_name, display_name, difficulty_level, description, subcategory_number))
        return subcategories

    # Generate AI descriptions in parallel
    print(f"🤖 Generating AI descriptions for {len(subcat_data)} subcategories in parallel...")

    async def generate_single_description(subcat_info):
        subcat_dir, subcat_name, display_name, difficulty_level, subcategory_number = subcat_info

        try:
            from .summarizers import generate_subcategory_description

            # Use asyncio.to_thread for running sync AI calls in parallel
            description = await asyncio.to_thread(generate_subcategory_description, subcat_dir)
            print(f"✅ AI description generated for subcategory: {subcat_name}")
            return (subcat_name, display_name, difficulty_level, description, subcategory_number)

        except Exception as e:
            print(f"⚠️  Error generating description for {subcat_name}: {e}")
            description = f"Training exercises focused on {display_name.lower()}"
            return (subcat_name, display_name, difficulty_level, description, subcategory_number)

    # Run all AI calls in parallel
    tasks = [generate_single_description(subcat_info) for subcat_info in subcat_data]
    results = await asyncio.gather(*tasks, return_exceptions=True)

    # Process results
    for result in results:
        if isinstance(result, Exception):
            print(f"⚠️  Parallel processing error: {result}")
            continue
        subcategories.append(result)

    print(f"✅ Completed parallel AI description generation for {len(subcategories)} subcategories")
    return subcategories
async def discover_quests_parallel(quests_dir: Path) -> List[Dict[str, Any]]:
    """Discover all quests with parallel AI description generation"""
    import asyncio
    from .summarizers import generate_quest_description

    quests_data = []

    if not quests_dir.exists():
        print(f"⚠️  Quests directory not found: {quests_dir}")
        return quests_data

    # Prepare quest data without AI descriptions first
    quest_info_list = []
    for quest_index, quest_path in enumerate(sorted(quests_dir.iterdir())):
        if quest_path.is_dir() and not quest_path.name.startswith('.'):
            quest_name = quest_path.name
            quest_title = quest_name.replace('-', ' ').title()

            # Discover subcategories (using parallel processing)
            subcategories_tuples = await discover_subcategories_parallel(quest_path, quest_name)

            # Convert subcategory tuples to the format expected by repository
            subcategories_list = []
            for sub_index, (sub_name, sub_display, sub_difficulty, sub_description, _) in enumerate(subcategories_tuples):
                subcategories_list.append((sub_name, sub_display, sub_difficulty, sub_description, sub_index))

            # Determine quest difficulty based on subcategories
            difficulty = determine_quest_difficulty(quest_path)

            quest_info_list.append((quest_index, quest_name, quest_title, subcategories_list, difficulty, subcategories_tuples))

    # Check if AI is disabled
    disable_ai = os.getenv("DISABLE_AI_SUMMARIZATION", "false").lower() == "true"
    if disable_ai:
        print("🤖 AI summarization disabled, using fallback descriptions")
        for quest_index, quest_name, quest_title, subcategories_list, difficulty, _ in quest_info_list:
            description = f"SQL {quest_name.replace('-', ' ')} exercises and concepts"
            quest_data = {
                'name': quest_name,
                'display_name': quest_title,
                'description': description,
                'difficulty_level': difficulty,
                'order_index': quest_index,
                'subcategories': subcategories_list
            }
            quests_data.append(quest_data)
        return quests_data

    # Generate AI descriptions in parallel
    print(f"🤖 Generating AI descriptions for {len(quest_info_list)} quests in parallel...")

    async def generate_single_quest_description(quest_info):
        quest_index, quest_name, quest_title, subcategories_list, difficulty, subcategories_tuples = quest_info

        try:
            # Use asyncio.to_thread for running sync AI calls in parallel
            description = await asyncio.to_thread(generate_quest_description, quest_name, subcategories_tuples)
            print(f"✅ AI description generated for: {quest_name}")

            return {
                'name': quest_name,
                'display_name': quest_title,
                'description': description,
                'difficulty_level': difficulty,
                'order_index': quest_index,
                'subcategories': subcategories_list
            }

        except Exception as e:
            print(f"⚠️  AI description failed for quest {quest_name}: {e}, using fallback")
            description = f"SQL {quest_name.replace('-', ' ')} exercises and concepts"

            return {
                'name': quest_name,
                'display_name': quest_title,
                'description': description,
                'difficulty_level': difficulty,
                'order_index': quest_index,
                'subcategories': subcategories_list
            }

    # Run all AI calls in parallel
    tasks = [generate_single_quest_description(quest_info) for quest_info in quest_info_list]
    results = await asyncio.gather(*tasks, return_exceptions=True)

    # Process results
    for result in results:
        if isinstance(result, Exception):
            print(f"⚠️  Parallel processing error: {result}")
            continue
        quests_data.append(result)

    print(f"✅ Completed parallel AI description generation for {len(quests_data)} quests")
    return quests_data


# =============================================================================
# UNIFIED PATTERN DEFINITIONS
# =============================================================================

# Import patterns from the single source of truth
try:
    # Try relative import first (when used as part of package)
    from ..database.pattern_data import SQL_PATTERNS
except ImportError:
    # Fall back to absolute import (when run directly)
    import sys
    from pathlib import Path
    evaluator_dir = Path(__file__).parent.parent
    if str(evaluator_dir) not in sys.path:
        sys.path.insert(0, str(evaluator_dir))
    from database.pattern_data import SQL_PATTERNS

# Convert pattern_data.py format to discovery.py format
PATTERN_DEFINITIONS = {}
for pattern in SQL_PATTERNS:
    PATTERN_DEFINITIONS[pattern['name']] = {
        'display_name': pattern['display_name'],
        'category': pattern['category'],
        'complexity': pattern['complexity_level'],  # Convert field name
        'regex': pattern['regex_pattern'],          # Convert field name
        'base_description': pattern['base_description'],
        'examples': pattern['examples']
    }

def detect_sql_patterns(sql_content: str) -> List[Tuple[str, str, str, str, str]]:
    """Detect SQL patterns in the given SQL content using unified definitions"""
    patterns_data = []
    content_upper = sql_content.upper()

    for pattern_name, pattern_info in PATTERN_DEFINITIONS.items():
        if re.search(pattern_info['regex'], content_upper, re.IGNORECASE):
            patterns_data.append((
                pattern_name,
                pattern_info['display_name'],
                pattern_info['category'],
                pattern_info['complexity'],
                pattern_info['regex']
            ))

    return patterns_data

def discover_sql_patterns_from_filesystem() -> List[Tuple[str, str, str, str, str]]:
    """Discover SQL patterns by analyzing actual SQL files using unified definitions"""
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
            pattern_info = PATTERN_DEFINITIONS[pattern_name]
            patterns_data.append((
                pattern_name,
                pattern_info['display_name'],
                pattern_info['category'],
                pattern_info['complexity'],
                pattern_info['regex']
            ))
            print(f"🔍 Discovered pattern: {pattern_info['display_name']} (used in {usage_count} files)")

    return patterns_data


def discover_quests_from_filesystem(quests_dir: Path) -> List[Dict[str, Any]]:
    """
    Discover all quests from the filesystem (wrapper for parallel/sequential execution)
    
    Args:
        quests_dir: Path to the quests directory
        
    Returns:
        List of dictionaries with quest data for repository persistence
    """
    import asyncio

    try:
        # Check if we're already in an event loop
        loop = asyncio.get_running_loop()
        # If we're in an event loop, use sequential processing to avoid nested event loops
        print("🔄 Event loop detected, using sequential processing for quests")
        return _discover_quests_sequential(quests_dir)
    except RuntimeError:
        # No event loop running, we can use asyncio.run for parallel processing
        try:
            print("⚡ No event loop, using parallel processing for quests")
            return asyncio.run(discover_quests_parallel(quests_dir))
        except Exception as e:
            print(f"⚠️  Parallel processing failed: {e}, falling back to sequential")
            return _discover_quests_sequential(quests_dir)


def _discover_quests_sequential(quests_dir: Path) -> List[Dict[str, Any]]:
    """
    Sequential fallback for quest discovery (original implementation)
    
    Args:
        quests_dir: Path to the quests directory
        
    Returns:
        List of dictionaries with quest data for repository persistence
    """
    from .summarizers import generate_quest_description
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
            
            # Generate AI-powered quest description with timeout
            try:
                # Check if AI should be disabled
                if os.getenv("DISABLE_AI_SUMMARIZATION", "false").lower() == "true":
                    print(f"🤖 AI summarization disabled, using fallback for quest: {quest_name}")
                    raise Exception("AI disabled by environment variable")
                
                import signal
                from contextlib import contextmanager
                
                @contextmanager
                def timeout_context(seconds: int):
                    def timeout_handler(signum, frame):
                        raise TimeoutError(f"AI description timed out after {seconds} seconds")
                    
                    signal.signal(signal.SIGALRM, timeout_handler)
                    signal.alarm(seconds)
                    try:
                        yield
                    finally:
                        signal.alarm(0)
                
                print(f"🤖 Generating AI description for quest: {quest_name}")
                with timeout_context(30):  # 30 second timeout for AI calls
                    description = generate_quest_description(quest_name, subcategories_tuples)
                print(f"✅ AI description generated for: {quest_name}")
                
            except TimeoutError:
                print(f"⏰ AI description timed out for quest: {quest_name}, using fallback")
                description = f"SQL {quest_name.replace('-', ' ')} exercises and concepts"
            except Exception as e:
                print(f"⚠️  AI description failed for quest {quest_name}: {e}, using fallback")
                description = f"SQL {quest_name.replace('-', ' ')} exercises and concepts"
            
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
# PATTERN DISCOVERY
# =============================================================================

async def generate_sql_patterns() -> List[Tuple[str, str, str, str, str]]:
    """Generate enhanced SQL patterns with AI-powered descriptions using unified definitions"""
    import asyncio

    patterns = []
    from utils.summarizers import generate_sql_pattern_description

    for pattern_name, pattern_info in PATTERN_DEFINITIONS.items():
        print(f"⌛ Generating pattern: {pattern_name}")

        # Create context for AI analysis
        context = {
            'base_description': pattern_info['base_description'],
            'examples': pattern_info['examples'][:2],  # Use first 2 examples
            'category': pattern_info['category'],
            'complexity': pattern_info['complexity']
        }

        ai_description = await generate_sql_pattern_description(pattern_name, context)

        patterns.append((
            pattern_name,
            pattern_info['display_name'],
            ai_description,
            pattern_info['category'],
            pattern_info['complexity']
        ))

        # Small delay to avoid rate limiting
        await asyncio.sleep(0.1)

    return patterns


# =============================================================================
# HELPER FUNCTIONS FOR PATTERN DEFINITIONS
# =============================================================================

def get_pattern_info(pattern_name: str) -> Dict[str, Any]:
    """Get complete pattern information by name"""
    return PATTERN_DEFINITIONS.get(pattern_name, {})

def get_pattern_regex(pattern_name: str) -> str:
    """Get regex pattern for a specific pattern name"""
    pattern_info = get_pattern_info(pattern_name)
    return pattern_info.get('regex', '')

def get_pattern_display_name(pattern_name: str) -> str:
    """Get display name for a specific pattern name"""
    pattern_info = get_pattern_info(pattern_name)
    return pattern_info.get('display_name', pattern_name.replace('_', ' ').title())

def get_pattern_category(pattern_name: str) -> str:
    """Get category for a specific pattern name"""
    pattern_info = get_pattern_info(pattern_name)
    return pattern_info.get('category', 'DQL')

def get_pattern_complexity(pattern_name: str) -> str:
    """Get complexity level for a specific pattern name"""
    pattern_info = get_pattern_info(pattern_name)
    return pattern_info.get('complexity', 'Intermediate')

def get_pattern_description(pattern_name: str) -> str:
    """Get base description for a specific pattern name"""
    pattern_info = get_pattern_info(pattern_name)
    return pattern_info.get('base_description', '')

def get_pattern_examples(pattern_name: str) -> List[str]:
    """Get examples for a specific pattern name"""
    pattern_info = get_pattern_info(pattern_name)
    return pattern_info.get('examples', [])

def list_all_patterns() -> List[str]:
    """Get list of all available pattern names"""
    return list(PATTERN_DEFINITIONS.keys())

def get_patterns_by_category(category: str) -> List[str]:
    """Get all pattern names for a specific category"""
    return [name for name, info in PATTERN_DEFINITIONS.items()
            if info['category'] == category]

def get_patterns_by_complexity(complexity: str) -> List[str]:
    """Get all pattern names for a specific complexity level"""
    return [name for name, info in PATTERN_DEFINITIONS.items()
            if info['complexity'] == complexity]
