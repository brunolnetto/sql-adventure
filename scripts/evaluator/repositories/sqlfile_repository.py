from .base_repository import BaseRepository
from tables import SQLFile
from pathlib import Path
import hashlib

class SQLFileRepository(BaseRepository[SQLFile]):
    def __init__(self, session):
        super().__init__(session, SQLFile)
    
    def _detect_and_associate_patterns(self, sql_file: SQLFile, file_path: str):
        """Detect SQL patterns in file and create associations"""
        try:
            with open(file_path, 'r') as f:
                content = f.read().upper()
            
            patterns = self.session.query(SQLPattern).all()
            
            for pattern in patterns:
                if pattern.detection_regex:
                    import re
                    if re.search(pattern.detection_regex, content, re.IGNORECASE | re.MULTILINE):
                        # Check if association already exists
                        existing = self.session.query(SQLFilePattern).filter(
                            and_(
                                SQLFilePattern.sql_file_id == sql_file.id,
                                SQLFilePattern.pattern_id == pattern.id
                            )
                        ).first()
                        
                        if not existing:
                            file_pattern = SQLFilePattern(
                                sql_file_id=sql_file.id,
                                pattern_id=pattern.id,
                                confidence_score=0.9  # Basic regex detection confidence
                            )
                            session.add(file_pattern)
        
        except Exception as e:
            print(f"⚠️  Error detecting patterns: {e}")
    
    @staticmethod
    def _generate_display_name(self, filename: str) -> str:
        """Generate human-readable display name from filename"""
        name = filename.replace('.sql', '').replace('-', ' ').replace('_', ' ')
        return ' '.join(word.capitalize() for word in name.split())
    
    @staticmethod
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
            sql_file = self.session.query(SQLFile).filter(SQLFile.file_path == file_path).first()
            
            if sql_file:
                # Update last_modified
                sql_file.last_modified = datetime.utcnow()
                self.session.commit()
                self.session.close()
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
                        content_hash = self._calculate_file_hash(file_path)
                        
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
                        self._detect_and_associate_patterns(session, sql_file, file_path)
                        
                        self.session.commit()
                        self.session.close()
                        return sql_file
            
            self.session.close()
            return None

