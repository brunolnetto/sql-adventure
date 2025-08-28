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
            # Extract quest information from discovery data
            quest_name = quest_data['quest_name']
            display_name = quest_data['display_name']
            
            # Generate description from available data
            description = f"Quest covering {quest_data['subcategory_count']} subcategories with {quest_data['total_files']} SQL files. Estimated time: {quest_data['total_estimated_time']} minutes."
            
            # Extract order index from quest name (e.g., "1-data-modeling" -> 1)
            import re
            order_match = re.match(r'^(\d+)-', quest_name)
            order_index = int(order_match.group(1)) if order_match else 0
            
            # Determine difficulty level based on quest name or default to intermediate
            difficulty_level = "Intermediate"  # Default
            if "basic" in quest_name.lower() or "1-" in quest_name:
                difficulty_level = "Beginner"
            elif "advanced" in quest_name.lower():
                difficulty_level = "Advanced"
            
            # Check if quest exists
            existing_quest = self.session.query(Quest).filter_by(name=quest_name).first()
            
            if existing_quest:
                # Update existing quest with new description
                updated = False
                if existing_quest.description != description:
                    existing_quest.description = description
                    updated = True
                if existing_quest.difficulty_level != difficulty_level:
                    existing_quest.difficulty_level = difficulty_level
                    updated = True
                if existing_quest.order_index != order_index:
                    existing_quest.order_index = order_index
                    updated = True
                
                if updated:
                    print(f"📝 Updated quest: {display_name}")
                else:
                    print(f"ℹ️  Quest unchanged: {display_name}")
                quest = existing_quest
            else:
                # Create new quest
                quest = Quest(
                    name=quest_name,
                    display_name=display_name,
                    description=description,
                    difficulty_level=difficulty_level,
                    order_index=order_index
                )
                self.session.add(quest)
                self.session.flush()  # Get the quest ID
                print(f"✅ Added quest: {display_name}")
                
            # Handle subcategories
            for sub_data in quest_data['subcategories']:
                sub_name = sub_data['subcategory_name']
                sub_display = sub_data['display_name']
                
                # Generate subcategory description
                sub_description = f"Subcategory with {sub_data['file_count']} SQL files covering concepts: {', '.join(sub_data['concept_coverage'][:3])}{'...' if len(sub_data['concept_coverage']) > 3 else ''}"
                
                # Determine subcategory difficulty
                sub_difficulty = difficulty_level  # Inherit from quest
                
                # Extract subcategory order
                sub_order_match = re.match(r'^(\d+)-', sub_name)
                sub_order = int(sub_order_match.group(1)) if sub_order_match else 0
                
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
                    if existing_subcategory.order_index != sub_order:
                        existing_subcategory.order_index = sub_order
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