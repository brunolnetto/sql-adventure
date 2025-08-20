#!/usr/bin/env python3
"""
Subcategory Repository for AI Enhancement
"""

from typing import List, Optional
from sqlalchemy.orm import Session

from repositories.base_repository import BaseRepository
from database.tables import Subcategory

class SubcategoryRepository(BaseRepository[Subcategory]):
    def __init__(self, session: Session):
        super().__init__(session, Subcategory)

    def find_by_quest_and_name(self, quest_id: int, name: str) -> Optional[Subcategory]:
        """Find subcategory by quest ID and name"""
        return self.session.query(Subcategory).filter(
            Subcategory.quest_id == quest_id,
            Subcategory.name == name
        ).first()

    def get_subcategories_without_description(self) -> List[Subcategory]:
        """Get all subcategories that need AI-generated descriptions"""
        return self.session.query(Subcategory).filter(
            Subcategory.description.is_(None)
        ).all()

    def update_description_and_time(self, subcategory_id: int, description: str, estimated_time: int):
        """Update subcategory with AI-generated description and time estimate"""
        subcategory = self.session.query(Subcategory).filter(
            Subcategory.id == subcategory_id
        ).first()
        
        if subcategory:
            subcategory.description = description
            if hasattr(subcategory, 'estimated_time_minutes'):
                subcategory.estimated_time_minutes = estimated_time
            self.session.commit()
            return True
        return False

    def get_all_with_quest_info(self) -> List[Subcategory]:
        """Get all subcategories with their quest information for AI analysis"""
        return self.session.query(Subcategory).join(Subcategory.quest).all()
