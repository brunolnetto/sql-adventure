from typing import List, Tuple
from sqlalchemy.orm import Session
from database.tables import SQLPattern
from repositories.base_repository import BaseRepository

class SQLPatternRepository(BaseRepository[SQLPattern]):
    def __init__(self, session: Session):
        """
        Repository for managing SQL patterns in the database.
        :param session: SQLAlchemy session object
        """
        super().__init__(session, SQLPattern)

    def upsert(self, patterns_data: List[Tuple[str, str, str, str, str]]):
        """Initialize SQL pattern catalog from discovered data"""
        for pattern_name, display_name, category, complexity, regex in patterns_data:
            existing_pattern = self.session.query(SQLPattern).filter_by(name=pattern_name).first()
            if not existing_pattern:
                pattern = SQLPattern(
                    name=pattern_name,
                    display_name=display_name,
                    category=category,
                    complexity_level=complexity,
                    description=f"Pattern for {display_name}"  # Use description instead of regex
                )
                self.session.add(pattern)
                print(f"✅ Added pattern: {display_name}")
