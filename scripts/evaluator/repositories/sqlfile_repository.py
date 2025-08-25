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

    def _normalize_path(self, file_path: str) -> str:
        """Normalize file path to relative format for consistent database storage"""
        path_str = str(file_path)
        
        # Convert absolute paths to relative
        if 'quests/' in path_str:
            # Extract everything from 'quests/' onwards
            relative_path = path_str[path_str.find('quests/'):]
            return relative_path
        
        # If already relative, ensure it starts properly
        if path_str.startswith('/'):
            return path_str[1:]  # Remove leading slash
        
        return path_str

    def get_or_create(self, file_path: str) -> Optional[SQLFile]:
        """Get existing SQL file record or create new one"""
        try:
            # Normalize the path for consistent lookup and storage
            normalized_path = self._normalize_path(file_path)
            
            # Check if file already exists using normalized path
            sql_file = self.session \
                .query(SQLFile)\
                .filter(SQLFile.file_path == normalized_path).first()
            
            if sql_file:
                # Update last_modified and content hash if file exists
                sql_file.last_modified = datetime.now()
                # Update content hash if file has changed
                new_hash = self._calculate_hash(file_path)  # Use original path for file reading
                if new_hash and new_hash != sql_file.content_hash:
                    sql_file.content_hash = new_hash
                self.session.commit()
                return sql_file
            
            # Create new file record
            path_obj = Path(normalized_path)  # Use normalized path for parsing
            filename = path_obj.name
            
            # Extract quest and subcategory from normalized path
            parts = path_obj.parts
            if len(parts) >= 3:
                quest_name = parts[-3]  # e.g., '1-data-modeling'
                subcategory_name = parts[-2]  # e.g., '00-basic-concepts'
                
                # Find quest and subcategory
                quest = self.session.query(Quest).filter(Quest.name == quest_name).first()
                if quest:
                    subcategory_conjunction = and_(Subcategory.quest_id == quest.id, Subcategory.name == subcategory_name)
                    subcategory = self.session.query(Subcategory).filter(subcategory_conjunction).first()
                    
                    if subcategory:
                        # Calculate content hash using original file path
                        content_hash = self._calculate_hash(file_path)
                        
                        sql_file = SQLFile(
                            subcategory_id=subcategory.id,
                            filename=filename,
                            file_path=normalized_path,  # Store normalized path
                            display_name=self._generate_display_name(filename),
                            content_hash=content_hash
                        )
                        
                        self.session.add(sql_file)
                        self.session.commit()
                        
                        # Detect and associate patterns using original file path
                        self._detect_and_associate_patterns(sql_file, file_path)
                        
                        self.session.commit()
                        print(f"✅ Created SQL file record: {normalized_path}")
                        return sql_file
                    else:
                        print(f"⚠️  Subcategory not found: {subcategory_name} in quest {quest_name}")
                else:
                    print(f"⚠️  Quest not found: {quest_name}")
            else:
                print(f"⚠️  Invalid path structure: {normalized_path} (needs quest/subcategory/file.sql)")
            
            return None

        except Exception as e:
            print(f"⚠️  Error getting or creating SQL file {file_path}: {e}")
            self.session.rollback()
            return None

    def get_by_path(self, file_path: str) -> Optional[SQLFile]:
        """Get existing SQL file record by path (normalizes path automatically)"""
        try:
            # Normalize the path for consistent lookup
            normalized_path = self._normalize_path(file_path)
            
            sql_file = self.session.query(SQLFile).filter(SQLFile.file_path == normalized_path).first()
            return sql_file
        except Exception as e:
            print(f"⚠️  Error getting SQL file by path: {e}")
            return None
    
    def upsert_by_path(self, file_path: str) -> Optional[SQLFile]:
        """Upsert SQL file record - create if doesn't exist, update if it does"""
        return self.get_or_create(file_path)