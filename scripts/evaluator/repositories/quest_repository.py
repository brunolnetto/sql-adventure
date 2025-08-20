from typing import List, Dict, Any

from repositories.base_repository import BaseRepository
from database.tables import Quest, Subcategory

class QuestRepository(BaseRepository[Quest]):
    def __init__(self, session):
        super().__init__(session, Quest)

    def find_by_name(self, name: str):
        return self.session.query(Quest).filter(Quest.name == name).one_or_none()
    
    def upsert(self, quests_data: List[Dict[str, Any]]):
        """Initialize quest and subcategory data from discovered data"""
        for quest_data in quests_data:
            # Check if quest exists
            existing_quest = self.session.query(Quest).filter_by(name=quest_data['name']).first()
            if not existing_quest:
                quest = Quest(
                    name=quest_data['name'],
                    display_name=quest_data['display_name'],
                    description=quest_data['description'],
                    difficulty_level=quest_data['difficulty_level'],
                    order_index=quest_data['order_index']
                )
                self.session.add(quest)
                self.session.flush()  # Get the quest ID
                
                # Add subcategories
                for sub_name, sub_display, sub_difficulty, sub_description, sub_order in quest_data['subcategories']:
                    subcategory = Subcategory(
                        quest_id=quest.id,
                        name=sub_name,
                        display_name=sub_display,
                        description=sub_description,
                        difficulty_level=sub_difficulty,
                        order_index=sub_order
                    )
                    self.session.add(subcategory)
                
                print(f"✅ Added quest: {quest_data['display_name']}")