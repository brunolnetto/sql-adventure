"""
Discovery module for SQL Adventure
Scans filesystem for quests, subcategories, and SQL patterns
Returns structured data for database sync or evaluation
"""

import os
import re
import hashlib
from pathlib import Path
from typing import List, Dict, Tuple, Any, Optional

# Regex pattern for parsing SQL comment headers
HEADER_PATTERN = re.compile(r"^--\s*(?P<key>\w+):\s*(?P<value>.+)$", re.IGNORECASE)


class MetadataExtractor:
    """Extract metadata from SQL file headers."""

    @staticmethod
    def parse_header(content: str) -> Dict[str, str]:
        """Parse SQL comment headers into a dictionary."""
        metadata = {}
        lines = content.splitlines()

        for line in lines:
            line = line.strip()
            if not line.startswith('--'):
                break  # Stop at first non-comment line

            match = HEADER_PATTERN.match(line)
            if match:
                key = match.group('key').lower()
                value = match.group('value').strip()
                metadata[key] = value

        return metadata

    @staticmethod
    def extract_patterns(content: str) -> List[str]:
        """Extract SQL patterns from content."""
        patterns = []
        content_lower = content.lower()

        # Basic pattern detection
        if 'select' in content_lower:
            patterns.append('SELECT')
        if 'join' in content_lower:
            patterns.append('JOIN')
        if 'group by' in content_lower:
            patterns.append('GROUP BY')
        if 'window' in content_lower or 'over' in content_lower:
            patterns.append('Window Functions')
        if 'with' in content_lower and 'as' in content_lower:
            patterns.append('CTE')
        if 'json' in content_lower:
            patterns.append('JSON Operations')
        if 'recursive' in content_lower:
            patterns.append('Recursive CTE')

        return patterns

    @staticmethod
    def get_content_hash(content: str) -> str:
        """Generate SHA256 hash of content."""
        return hashlib.sha256(content.encode('utf-8')).hexdigest()

    @staticmethod
    def count_significant_lines(content: str) -> int:
        """Count lines that contain actual SQL code (excluding comments)."""
        return len([
            line for line in content.splitlines()
            if line.strip() and not line.strip().startswith('--')
        ])

    @staticmethod
    def estimate_time_from_difficulty(difficulty: str) -> int:
        """Estimate completion time based on difficulty level."""
        difficulty_lower = difficulty.lower()

        # Extract time from patterns like "(10-15 min)" or "(20 min)"
        time_pattern = r'\((\d+)-(\d+)\s*min\)'
        match = re.search(time_pattern, difficulty, re.IGNORECASE)
        if match:
            min_time = int(match.group(1))
            max_time = int(match.group(2))
            return (min_time + max_time) // 2

        single_time_pattern = r'\((\d+)\s*min\)'
        match = re.search(single_time_pattern, difficulty, re.IGNORECASE)
        if match:
            return int(match.group(1))

        # Fallback based on difficulty level
        if 'beginner' in difficulty_lower or '🟢' in difficulty:
            return 8
        elif 'intermediate' in difficulty_lower or '🟡' in difficulty:
            return 15
        elif 'advanced' in difficulty_lower or '🟠' in difficulty:
            return 25
        elif 'expert' in difficulty_lower or '🔴' in difficulty:
            return 35
        else:
            return 15


def discover_sql_file_context(file_path: Path) -> Optional[Dict[str, Any]]:
    """
    Get rich context for a single SQL file.

    Returns:
        Dictionary with file metadata, patterns, and analysis
    """
    try:
        content = file_path.read_text(encoding='utf-8', errors='ignore')
        metadata = MetadataExtractor.parse_header(content)
        patterns = MetadataExtractor.extract_patterns(content)

        return {
            'file_path': file_path,
            'filename': file_path.name,
            'content': content,
            'metadata': metadata,
            'patterns': patterns,
            'purpose': metadata.get('purpose', ''),
            'concepts': metadata.get('concepts', ''),
            'difficulty': metadata.get('difficulty', ''),
            'estimated_time_minutes': MetadataExtractor.estimate_time_from_difficulty(
                metadata.get('difficulty', '')
            ),
            'content_hash': MetadataExtractor.get_content_hash(content),
            'significant_lines': MetadataExtractor.count_significant_lines(content),
            'content_length': len(content)
        }

    except Exception as e:
        print(f"⚠️  Error reading {file_path}: {e}")
        return None


def discover_subcategory_context(subcategory_path: Path) -> Dict[str, Any]:
    """
    Get rich context for a subcategory with aggregated file information.

    Returns:
        Dictionary with subcategory metadata and file summaries
    """
    subcategory_name = subcategory_path.name
    display_name = ' '.join(word.capitalize() for word in subcategory_name.split('-')[1:])

    # Collect all SQL files
    sql_files = []
    concept_coverage = set()
    pattern_coverage = set()
    total_estimated_time = 0

    for sql_file in sorted(subcategory_path.glob('*.sql')):
        file_context = discover_sql_file_context(sql_file)
        if file_context:
            sql_files.append(file_context)

            # Aggregate concepts
            if file_context['concepts']:
                concepts = [c.strip() for c in file_context['concepts'].split(',')]
                concept_coverage.update(concepts)

            # Aggregate patterns
            pattern_coverage.update(file_context['patterns'])

            # Sum time estimates
            total_estimated_time += file_context['estimated_time_minutes']

    return {
        'subcategory_path': subcategory_path,
        'subcategory_name': subcategory_name,
        'display_name': display_name,
        'sql_files': sql_files,
        'file_count': len(sql_files),
        'total_estimated_time': total_estimated_time,
        'concept_coverage': sorted(list(concept_coverage)),
        'pattern_coverage': sorted(list(pattern_coverage))
    }


def discover_quest_context(quest_path: Path) -> Dict[str, Any]:
    """
    Get rich context for a quest with aggregated subcategory information.

    Returns:
        Dictionary with quest metadata and subcategory summaries
    """
    quest_name = quest_path.name
    display_name = quest_name.replace('-', ' ').title()

    # Collect all subcategories
    subcategories = []
    concept_coverage = set()
    pattern_coverage = set()
    total_estimated_time = 0
    total_files = 0

    for sub_dir in sorted(quest_path.iterdir()):
        if sub_dir.is_dir() and re.match(r'^\d+-', sub_dir.name):
            sub_context = discover_subcategory_context(sub_dir)
            subcategories.append(sub_context)

            # Aggregate data
            concept_coverage.update(sub_context['concept_coverage'])
            pattern_coverage.update(sub_context['pattern_coverage'])
            total_estimated_time += sub_context['total_estimated_time']
            total_files += sub_context['file_count']

    return {
        'quest_path': quest_path,
        'quest_name': quest_name,
        'display_name': display_name,
        'subcategories': subcategories,
        'subcategory_count': len(subcategories),
        'total_files': total_files,
        'total_estimated_time': total_estimated_time,
        'concept_coverage': sorted(list(concept_coverage)),
        'pattern_coverage': sorted(list(pattern_coverage))
    }


def discover_quests(base_path: Path) -> List[Dict[str, Any]]:
    """
    Discover all quests in the quests directory.

    Returns:
        List of quest dictionaries with metadata
    """
    quests = []

    # Look for numbered directories (1-data-modeling, 2-performance-tuning, etc.)
    for quest_dir in sorted(base_path.iterdir()):
        if quest_dir.is_dir() and re.match(r'^\d+-', quest_dir.name):
            quest_context = discover_quest_context(quest_dir)
            quests.append(quest_context)

    return quests


def get_quest_structure(base_path: Path) -> Dict[str, Any]:
    """
    Get the complete quest structure with all metadata.

    Returns:
        Dictionary containing quests, subcategories, and files
    """
    return {
        'quests': discover_quests(base_path),
        'total_quests': len(discover_quests(base_path)),
        'base_path': base_path
    }


def find_sql_file_by_path(quests_path: Path, relative_path: str) -> Optional[Dict[str, Any]]:
    """
    Find a specific SQL file by its relative path.

    Args:
        quests_path: Base quests directory
        relative_path: Relative path like "1-data-modeling/00-basic-concepts/01-basic-table-creation.sql"

    Returns:
        File context dictionary or None if not found
    """
    full_path = quests_path / relative_path

    if not full_path.exists() or not full_path.is_file():
        return None

    return discover_sql_file_context(full_path)
