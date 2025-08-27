from typing import List, Tuple, Optional
from sqlalchemy.orm import Session

# Import patterns from the single source of truth
try:
    # Try relative import first (when used as part of package)
    from ..database.tables import SQLPattern
    from .base_repository import BaseRepository
except ImportError:
    # Fall back to absolute import (when run directly)
    import sys
    from pathlib import Path
    evaluator_dir = Path(__file__).parent.parent
    if str(evaluator_dir) not in sys.path:
        sys.path.insert(0, str(evaluator_dir))
    from database.tables import SQLPattern
    from repositories.base_repository import BaseRepository

class SQLPatternRepository(BaseRepository[SQLPattern]):
    def __init__(self, session: Session):
        """
        Repository for managing SQL patterns in the database.
        :param session: SQLAlchemy session object
        """
        super().__init__(session, SQLPattern)

    def upsert(self, patterns_data: List[Tuple[str, str, str, str, str, str, str, List[str]]]):
        """Initialize SQL pattern catalog from discovered data with enhanced fields"""
        for pattern_data in patterns_data:
            if len(pattern_data) == 5:
                # Legacy format: (name, display_name, description, category, complexity)
                name, display_name, description, category, complexity = pattern_data
                regex_pattern = None
                base_description = description
                examples = []
            elif len(pattern_data) == 8:
                # Enhanced format: (name, display_name, description, category, complexity, regex, base_desc, examples)
                name, display_name, description, category, complexity, regex_pattern, base_description, examples = pattern_data
            else:
                print(f"⚠️  Invalid pattern data format: {pattern_data}")
                continue

            existing_pattern = self.session.query(SQLPattern).filter_by(name=name).first()
            if not existing_pattern:
                pattern = SQLPattern(
                    name=name,
                    display_name=display_name,
                    description=description,
                    category=category,
                    complexity_level=complexity,
                    regex_pattern=regex_pattern,
                    base_description=base_description,
                    examples=examples,
                    usage_count=0
                )
                self.session.add(pattern)
                print(f"✅ Added pattern: {display_name}")
            else:
                # Update existing pattern with new data
                existing_pattern.display_name = display_name
                existing_pattern.description = description
                existing_pattern.category = category
                existing_pattern.complexity_level = complexity
                if regex_pattern:
                    existing_pattern.regex_pattern = regex_pattern
                if base_description:
                    existing_pattern.base_description = base_description
                if examples:
                    existing_pattern.examples = examples
                print(f"🔄 Updated pattern: {display_name}")

    def update_usage_count(self, pattern_name: str, increment: int = 1):
        """Update the usage count for a pattern"""
        pattern = self.session.query(SQLPattern).filter_by(name=pattern_name).first()
        if pattern:
            pattern.usage_count = (pattern.usage_count or 0) + increment
            print(f"📊 Updated usage count for {pattern_name}: {pattern.usage_count}")

    def get_patterns_by_category(self, category: str) -> List[SQLPattern]:
        """Get all patterns for a specific category"""
        return self.session.query(SQLPattern).filter_by(category=category).all()

    def get_patterns_by_complexity(self, complexity: str) -> List[SQLPattern]:
        """Get all patterns for a specific complexity level"""
        return self.session.query(SQLPattern).filter_by(complexity_level=complexity).all()

    def get_all(self) -> List[SQLPattern]:
        """Get all SQL patterns"""
        return self.list()

    def get_by_name(self, name: str) -> Optional[SQLPattern]:
        """Get a pattern by its name"""
        return self.session.query(SQLPattern).filter_by(name=name).first()
