from typing import List, Dict, Any

from repositories.base_repository import BaseRepository
from database.tables import Quest, Subcategory

class QuestRepository(BaseRepository[Quest]):
    def __init__(self, session):
        super().__init__(session, Quest)

    def find_by_name(self, name: str):
        return self.session.query(Quest).filter(Quest.name == name).one_or_none()
    
    def upsert(self, quests_data: List[Dict[str, Any]]):
        """Upsert quest and subcategory data from discovered data"""
        for quest_data in quests_data:
            # Check if quest exists
            existing_quest = self.session.query(Quest).filter_by(name=quest_data['name']).first()
            
            if existing_quest:
                # Update existing quest with new description
                updated = False
                if existing_quest.description != quest_data['description']:
                    existing_quest.description = quest_data['description']
                    updated = True
                if existing_quest.difficulty_level != quest_data['difficulty_level']:
                    existing_quest.difficulty_level = quest_data['difficulty_level']
                    updated = True
                
                if updated:
                    print(f"📝 Updated quest: {quest_data['display_name']}")
                else:
                    print(f"ℹ️  Quest unchanged: {quest_data['display_name']}")
                quest = existing_quest
            else:
                # Create new quest
                quest = Quest(
                    name=quest_data['name'],
                    display_name=quest_data['display_name'],
                    description=quest_data['description'],
                    difficulty_level=quest_data['difficulty_level'],
                    order_index=quest_data['order_index']
                )
                self.session.add(quest)
                self.session.flush()  # Get the quest ID
                print(f"✅ Added quest: {quest_data['display_name']}")
                
            # Handle subcategories
            for sub_name, sub_display, sub_difficulty, sub_description, sub_order in quest_data['subcategories']:
                existing_subcategory = self.session.query(Subcategory).filter_by(
                    quest_id=quest.id,
                    name=sub_name
                ).first()
                
                if existing_subcategory:
                    # Update existing subcategory
                    subcategory_updated = False
                    if existing_subcategory.description != sub_description:
                        existing_subcategory.description = sub_description
                        subcategory_updated = True
                    if existing_subcategory.difficulty_level != sub_difficulty:
                        existing_subcategory.difficulty_level = sub_difficulty
                        subcategory_updated = True
                    
                    if subcategory_updated:
                        print(f"  📝 Updated subcategory: {sub_display}")
                else:
                    # Create new subcategory
                    subcategory = Subcategory(
                        quest_id=quest.id,
                        name=sub_name,
                        display_name=sub_display,
                        description=sub_description,
                        difficulty_level=sub_difficulty,
                        order_index=sub_order
                    )
                    self.session.add(subcategory)
                    print(f"  ✅ Added subcategory: {sub_display}")