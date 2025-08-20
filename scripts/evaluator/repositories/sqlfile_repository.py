from pathlib import Path
import hashlib
from typing import Optional
from datetime import datetime
from sqlalchemy import and_

from database.tables import SQLFile, Quest, Subcategory
from repositories.base_repository import BaseRepository
from database.tables import SQLPattern  # Keep for basic reference

class SQLFileRepository(BaseRepository[SQLFile]):
    def __init__(self, session):
        super().__init__(session, SQLFile)
    
    def _detect_and_associate_patterns(self, sql_file: SQLFile, file_path: str):
        """Simplified: No automatic pattern detection - patterns detected by AI during evaluation"""
        try:
            with open(file_path, 'r') as f:
                content = f.read()
            
            # Simplified: No automatic pattern detection
            # Patterns will be detected during evaluation by AI agents
            print(f"   ✅ SQL file processed: {sql_file.filename}")
            
        except Exception as e:
            print(f"   ❌ Error processing SQL file: {e}")
    
    def _generate_display_name(self, filename: str) -> str:
        """Generate human-readable display name from filename"""
        name = filename.replace('.sql', '').replace('-', ' ').replace('_', ' ')
        return ' '.join(word.capitalize() for word in name.split())
    
    def _calculate_hash(self, file_path: str) -> str:
        """Calculate SHA-256 hash of file content"""
        try:
            with open(file_path, 'rb') as f:
                content = f.read()
                return hashlib.sha256(content).hexdigest()
        except Exception:
            return ""

    def get_or_create(self, file_path: str) -> Optional[SQLFile]:
        """Get existing SQL file record or create new one"""
        try:            
            # Check if file already exists
            sql_file = self.session \
                .query(SQLFile)\
                .filter(SQLFile.file_path == file_path).first()
            
            if sql_file:
                # Update last_modified
                sql_file.last_modified = datetime.now()
                self.session.commit()
                return sql_file
            
            # Create new file record
            path_obj = Path(file_path)
            filename = path_obj.name
            
            # Extract quest and subcategory from path
            parts = path_obj.parts
            if len(parts) >= 3:
                quest_name = parts[-3]
                subcategory_name = parts[-2]
                
                # Find quest and subcategory
                quest = self.session.query(Quest).filter(Quest.name == quest_name).first()
                if quest:
                    subcategory_conjunction=and_(Subcategory.quest_id == quest.id, Subcategory.name == subcategory_name)
                    subcategory = self.session.query(Subcategory).filter(subcategory_conjunction).first()
                    
                    if subcategory:
                        # Calculate content hash
                        content_hash = self._calculate_hash(file_path)
                        
                        sql_file = SQLFile(
                            subcategory_id=subcategory.id,
                            filename=filename,
                            file_path=file_path,
                            display_name=self._generate_display_name(filename),
                            content_hash=content_hash
                        )
                        
                        self.session.add(sql_file)
                        self.session.commit()
                        
                        # Detect and associate patterns
                        self._detect_and_associate_patterns(sql_file, file_path)
                        
                        self.session.commit()
                        return sql_file
            
            return None

        except Exception as e:
            print(f"⚠️  Error getting or creating SQL file: {e}")
            return None

    def get_by_path(self, file_path: str) -> Optional[SQLFile]:
        """Get existing SQL file record by path (converts absolute to relative if needed)"""
        try:
            # Convert absolute path to relative if needed
            if file_path.startswith('/'):
                # Extract relative path from absolute path
                # Look for 'quests/' in the path
                if 'quests/' in file_path:
                    relative_path = file_path[file_path.find('quests/'):]
                else:
                    relative_path = file_path
            else:
                relative_path = file_path
            
            sql_file = self.session.query(SQLFile).filter(SQLFile.file_path == relative_path).first()
            return sql_file
        except Exception as e:
            print(f"⚠️  Error getting SQL file by path: {e}")
            return None