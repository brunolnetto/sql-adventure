"""
Unified difficulty calculation module for SQL Adventure.
Contains all strategies, constants, and helpers. Import this from discovery.py and other modules.
"""

import statistics
from pathlib import Path
from typing import List, Tuple, Dict, Any
from collections import Counter
from enum import Enum

# Difficulty level constants
LEVEL_KEYWORDS = {
    'beginner': ['beginner', '🟢', 'green'],
    'intermediate': ['intermediate', '🟡', 'yellow'],
    'advanced': ['advanced', '🟠', 'orange'],
    'expert': ['expert', '🔴', 'red']
}
LEVEL_ORDER = {level.capitalize(): idx for idx, level in enumerate(LEVEL_KEYWORDS, start=1)}
ORDER_LEVEL = {v: k for k, v in LEVEL_ORDER.items()}

class DifficultyStrategy(Enum):
    SIMPLE_AVERAGE = "simple_average"
    MODAL = "modal"
    WEIGHTED_COMPLEXITY = "weighted_complexity"
    PERCENTILE_75 = "percentile_75"
    PERCENTILE_90 = "percentile_90"
    PROGRESSION_BASED = "progression_based"
    ADAPTIVE = "adaptive"

# Helper to parse header level

def parse_header_level(raw: str) -> str:
    text = raw.lower()
    for level, keywords in LEVEL_KEYWORDS.items():
        if any(k in text for k in keywords):
            return level.capitalize()
    return None

# Main difficulty calculation

def determine_quest_difficulty(
    quest_dir: Path,
    default: str = 'Intermediate',
    strategy: DifficultyStrategy = DifficultyStrategy.ADAPTIVE,
    infer_difficulty=None,
    discover_subcategories_from_filesystem=None,
    MetadataExtractor=None
) -> str:
    """
    Unified quest difficulty determination with multiple strategies.
    Args:
        quest_dir: Path to quest directory
        default: Default difficulty if calculation fails
        strategy: Calculation strategy to use
        infer_difficulty: Function to infer difficulty from a file
        discover_subcategories_from_filesystem: Function to discover subcategories
        MetadataExtractor: Optional for global header override
    Returns:
        Difficulty level string
    """
    # 1) Always check for global override first
    if MetadataExtractor:
        for sql_file in quest_dir.rglob('*.sql'):
            try:
                meta = MetadataExtractor.parse_header(
                    sql_file.read_text(encoding='utf-8', errors='ignore')
                )
                if 'difficulty' in meta:
                    lvl = parse_header_level(meta['difficulty'])
                    if lvl:
                        return lvl
            except Exception:
                continue
    # 2) Collect all difficulty data
    difficulty_data = collect_difficulty_data(quest_dir, default, infer_difficulty, discover_subcategories_from_filesystem)
    if not difficulty_data['levels']:
        return default
    # 3) Apply selected strategy
    if strategy == DifficultyStrategy.ADAPTIVE:
        strategy = choose_adaptive_strategy(difficulty_data)
    return apply_difficulty_strategy(difficulty_data, strategy, default)

def collect_difficulty_data(quest_dir: Path, default: str, infer_difficulty, discover_subcategories_from_filesystem) -> Dict[str, Any]:
    data = {
        'levels': [],
        'level_strings': [],
        'subcategory_data': [],
        'file_count': 0,
        'subcategory_count': 0
    }
    subcats = discover_subcategories_from_filesystem(quest_dir, quest_dir.name)
    data['subcategory_count'] = len(subcats)
    for sub_name, _, _, order in subcats:
        sub_dir = quest_dir / sub_name
        sub_levels = []
        sub_level_strings = []
        for sql_file in sub_dir.rglob('*.sql'):
            data['file_count'] += 1
            lvl_str = infer_difficulty(sql_file, default)
            level_score = LEVEL_ORDER.get(lvl_str, LEVEL_ORDER[default])
            data['levels'].append(level_score)
            data['level_strings'].append(lvl_str)
            sub_levels.append(level_score)
            sub_level_strings.append(lvl_str)
        if sub_levels:
            data['subcategory_data'].append({
                'name': sub_name,
                'order': order,
                'levels': sub_levels,
                'level_strings': sub_level_strings,
                'avg_level': statistics.mean(sub_levels)
            })
    return data

def choose_adaptive_strategy(difficulty_data: Dict[str, Any]) -> DifficultyStrategy:
    file_count = difficulty_data['file_count']
    subcategory_count = difficulty_data['subcategory_count']
    levels = difficulty_data['levels']
    if file_count <= 5:
        return DifficultyStrategy.MODAL
    if len(levels) > 2:
        variance = statistics.variance(levels)
        if variance > 1.5:
            return DifficultyStrategy.MODAL
    if subcategory_count >= 4:
        subcat_data = difficulty_data['subcategory_data']
        if len(subcat_data) >= 2:
            first_avg = subcat_data[0]['avg_level']
            last_avg = subcat_data[-1]['avg_level']
            if last_avg > first_avg + 0.5:
                return DifficultyStrategy.PROGRESSION_BASED
    if file_count > 10:
        return DifficultyStrategy.WEIGHTED_COMPLEXITY
    return DifficultyStrategy.SIMPLE_AVERAGE

def apply_difficulty_strategy(
    difficulty_data: Dict[str, Any], 
    strategy: DifficultyStrategy, 
    default: str
) -> str:
    levels = difficulty_data['levels']
    level_strings = difficulty_data['level_strings']
    if strategy == DifficultyStrategy.SIMPLE_AVERAGE:
        avg = statistics.mean(levels)
        quest_value = round(avg)
        return ORDER_LEVEL.get(quest_value, default)
    elif strategy == DifficultyStrategy.MODAL:
        level_counts = Counter(level_strings)
        modal_level = level_counts.most_common(1)[0][0]
        return modal_level
    elif strategy == DifficultyStrategy.PERCENTILE_75:
        if len(levels) == 1:
            return level_strings[0]
        percentile_score = statistics.quantiles(levels, n=4)[2]
        quest_value = round(percentile_score)
        return ORDER_LEVEL.get(quest_value, default)
    elif strategy == DifficultyStrategy.PERCENTILE_90:
        if len(levels) == 1:
            return level_strings[0]
        percentile_score = statistics.quantiles(levels, n=10)[8]
        quest_value = round(percentile_score)
        return ORDER_LEVEL.get(quest_value, default)
    elif strategy == DifficultyStrategy.WEIGHTED_COMPLEXITY:
        weighted_sum = 0
        total_weight = 0
        for level in levels:
            weight = 1.0
            if level == max(levels) and levels.count(level) == 1:
                weight = 0.5
            elif level == min(levels) and levels.count(level) == 1:
                weight = 0.7
            weighted_sum += level * weight
            total_weight += weight
        weighted_avg = weighted_sum / total_weight
        quest_value = round(weighted_avg)
        return ORDER_LEVEL.get(quest_value, default)
    elif strategy == DifficultyStrategy.PROGRESSION_BASED:
        subcategory_data = difficulty_data['subcategory_data']
        if not subcategory_data:
            return ORDER_LEVEL.get(round(statistics.mean(levels)), default)
        sorted_subcats = sorted(subcategory_data, key=lambda x: x['order'])
        weighted_scores = []
        for i, subcat in enumerate(sorted_subcats):
            weight = 1.0 + (i / (len(sorted_subcats) - 1)) * 0.5
            weighted_scores.append(subcat['avg_level'] * weight)
        progression_avg = statistics.mean(weighted_scores)
        quest_value = round(progression_avg)
        return ORDER_LEVEL.get(quest_value, default)
    else:
        avg = statistics.mean(levels)
        quest_value = round(avg)
        return ORDER_LEVEL.get(quest_value, default)

# Numeric score wrappers

def get_quest_difficulty_score(
    quest_dir: Path,
    default: str = 'Intermediate',
    strategy: DifficultyStrategy = DifficultyStrategy.ADAPTIVE,
    infer_difficulty=None,
    discover_subcategories_from_filesystem=None,
    MetadataExtractor=None
) -> float:
    label = determine_quest_difficulty(
        quest_dir, default, strategy,
        infer_difficulty=infer_difficulty,
        discover_subcategories_from_filesystem=discover_subcategories_from_filesystem,
        MetadataExtractor=MetadataExtractor
    )
    return float(LEVEL_ORDER.get(label, LEVEL_ORDER[default]))
