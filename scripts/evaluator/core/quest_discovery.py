#!/usr/bin/env python3
"""
Dynamic Quest Discovery System for SQL Adventure AI Evaluator
Automatically discovers quests from the file system for extensibility
"""

import os
import re
import json
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass
from datetime import datetime

@dataclass
class QuestMetadata:
    """Quest metadata extracted from file system or configuration"""
    name: str
    display_name: str
    description: str
    difficulty_level: str
    order_index: int
    category: str
    estimated_duration_hours: int
    prerequisites: List[str]
    metadata: Dict[str, Any]

@dataclass
class SubcategoryMetadata:
    """Subcategory metadata extracted from file system"""
    name: str
    display_name: str
    description: str
    difficulty_level: str
    order_index: int
    metadata: Dict[str, Any]

class QuestDiscovery:
    """Dynamic quest discovery system"""
    
    def __init__(self, quests_directory: str = "quests"):
        self.quests_directory = Path(quests_directory)
        self.quest_cache = {}
        self.metadata_cache = {}
    
    def discover_quests(self) -> Dict[str, QuestMetadata]:
        """Discover all quests from the file system"""
        quests = {}
        
        if not self.quests_directory.exists():
            print(f"⚠️  Quests directory not found: {self.quests_directory}")
            return quests
        
        # Find all quest directories
        quest_dirs = [d for d in self.quests_directory.iterdir() 
                     if d.is_dir() and self._is_quest_directory(d)]
        
        # Sort by order (extract number from directory name)
        quest_dirs.sort(key=lambda d: self._extract_order_from_name(d.name))
        
        for quest_dir in quest_dirs:
            quest_metadata = self._discover_quest_metadata(quest_dir)
            if quest_metadata:
                quests[quest_metadata.name] = quest_metadata
        
        return quests
    
    def _is_quest_directory(self, directory: Path) -> bool:
        """Check if directory is a quest directory"""
        # Quest directories should match pattern: number-name
        return bool(re.match(r'^\d+-[a-zA-Z0-9-]+$', directory.name))
    
    def _extract_order_from_name(self, name: str) -> int:
        """Extract order index from quest directory name"""
        match = re.match(r'^(\d+)-', name)
        return int(match.group(1)) if match else 999
    
    def _discover_quest_metadata(self, quest_dir: Path) -> Optional[QuestMetadata]:
        """Discover metadata for a specific quest"""
        quest_name = quest_dir.name
        
        # Try to load from quest metadata file
        metadata_file = quest_dir / "quest.json"
        if metadata_file.exists():
            return self._load_quest_metadata_from_file(metadata_file, quest_name)
        
        # Try to load from README or other documentation
        readme_file = quest_dir / "README.md"
        if readme_file.exists():
            return self._extract_quest_metadata_from_readme(readme_file, quest_name)
        
        # Generate metadata from directory structure
        return self._generate_quest_metadata_from_structure(quest_dir, quest_name)
    
    def _load_quest_metadata_from_file(self, metadata_file: Path, quest_name: str) -> QuestMetadata:
        """Load quest metadata from JSON file"""
        try:
            with open(metadata_file, 'r') as f:
                data = json.load(f)
            
            return QuestMetadata(
                name=quest_name,
                display_name=data.get('display_name', self._generate_display_name(quest_name)),
                description=data.get('description', ''),
                difficulty_level=data.get('difficulty_level', 'Beginner'),
                order_index=data.get('order_index', self._extract_order_from_name(quest_name)),
                category=data.get('category', 'general'),
                estimated_duration_hours=data.get('estimated_duration_hours', 4),
                prerequisites=data.get('prerequisites', []),
                metadata=data.get('metadata', {})
            )
        except Exception as e:
            print(f"⚠️  Error loading quest metadata from {metadata_file}: {e}")
            return self._generate_quest_metadata_from_structure(metadata_file.parent, quest_name)
    
    def _extract_quest_metadata_from_readme(self, readme_file: Path, quest_name: str) -> QuestMetadata:
        """Extract quest metadata from README file"""
        try:
            content = readme_file.read_text()
            
            # Extract metadata using regex patterns
            display_name = self._extract_from_readme(content, r'#\s*(.+)', self._generate_display_name(quest_name))
            description = self._extract_from_readme(content, r'##\s*Description\s*\n+(.+)', '')
            difficulty = self._extract_from_readme(content, r'##\s*Difficulty\s*\n+(.+)', 'Beginner')
            category = self._extract_from_readme(content, r'##\s*Category\s*\n+(.+)', 'general')
            
            # Extract prerequisites
            prerequisites = []
            prereq_match = re.search(r'##\s*Prerequisites\s*\n+((?:-|\*)\s*.+\n?)+', content)
            if prereq_match:
                prereq_lines = prereq_match.group(1).split('\n')
                prerequisites = [line.strip('- *').strip() for line in prereq_lines if line.strip()]
            
            return QuestMetadata(
                name=quest_name,
                display_name=display_name,
                description=description,
                difficulty_level=difficulty,
                order_index=self._extract_order_from_name(quest_name),
                category=category,
                estimated_duration_hours=4,
                prerequisites=prerequisites,
                metadata={
                    'source': 'readme',
                    'readme_file': str(readme_file)
                }
            )
        except Exception as e:
            print(f"⚠️  Error extracting metadata from README {readme_file}: {e}")
            return self._generate_quest_metadata_from_structure(readme_file.parent, quest_name)
    
    def _extract_from_readme(self, content: str, pattern: str, default: str) -> str:
        """Extract text from README using regex pattern"""
        match = re.search(pattern, content, re.MULTILINE | re.DOTALL)
        return match.group(1).strip() if match else default
    
    def _generate_quest_metadata_from_structure(self, quest_dir: Path, quest_name: str) -> QuestMetadata:
        """Generate quest metadata from directory structure and content analysis"""
        # Analyze subcategories to determine difficulty and category
        subcategories = self._discover_subcategories(quest_dir)
        
        # Determine difficulty based on subcategory names and content
        difficulty_level = self._determine_quest_difficulty(subcategories)
        
        # Determine category based on quest name and content
        category = self._determine_quest_category(quest_name, subcategories)
        
        # Count SQL files for duration estimation
        sql_file_count = self._count_sql_files(quest_dir)
        estimated_hours = max(1, sql_file_count // 3)  # Rough estimate: 3 files per hour
        
        return QuestMetadata(
            name=quest_name,
            display_name=self._generate_display_name(quest_name),
            description=self._generate_quest_description(quest_name, category),
            difficulty_level=difficulty_level,
            order_index=self._extract_order_from_name(quest_name),
            category=category,
            estimated_duration_hours=estimated_hours,
            prerequisites=self._determine_prerequisites(quest_name, difficulty_level),
            metadata={
                'source': 'auto_generated',
                'sql_file_count': sql_file_count,
                'subcategory_count': len(subcategories),
                'generated_at': datetime.now().isoformat()
            }
        )
    
    def _discover_subcategories(self, quest_dir: Path) -> List[SubcategoryMetadata]:
        """Discover subcategories within a quest"""
        subcategories = []
        
        for subdir in quest_dir.iterdir():
            if subdir.is_dir() and self._is_subcategory_directory(subdir):
                subcategory = self._discover_subcategory_metadata(subdir)
                if subcategory:
                    subcategories.append(subcategory)
        
        # Sort by order index
        subcategories.sort(key=lambda s: s.order_index)
        return subcategories
    
    def _is_subcategory_directory(self, directory: Path) -> bool:
        """Check if directory is a subcategory directory"""
        # Subcategory directories should match pattern: number-name
        return bool(re.match(r'^\d{2}-[a-zA-Z0-9-]+$', directory.name))
    
    def _discover_subcategory_metadata(self, subdir: Path) -> Optional[SubcategoryMetadata]:
        """Discover metadata for a specific subcategory"""
        subcategory_name = subdir.name
        
        # Try to load from metadata file
        metadata_file = subdir / "subcategory.json"
        if metadata_file.exists():
            return self._load_subcategory_metadata_from_file(metadata_file, subcategory_name)
        
        # Generate from structure
        return self._generate_subcategory_metadata_from_structure(subdir, subcategory_name)
    
    def _load_subcategory_metadata_from_file(self, metadata_file: Path, subcategory_name: str) -> SubcategoryMetadata:
        """Load subcategory metadata from JSON file"""
        try:
            with open(metadata_file, 'r') as f:
                data = json.load(f)
            
            return SubcategoryMetadata(
                name=subcategory_name,
                display_name=data.get('display_name', self._generate_display_name(subcategory_name)),
                description=data.get('description', ''),
                difficulty_level=data.get('difficulty_level', 'Beginner'),
                order_index=data.get('order_index', self._extract_order_from_name(subcategory_name)),
                metadata=data.get('metadata', {})
            )
        except Exception as e:
            print(f"⚠️  Error loading subcategory metadata from {metadata_file}: {e}")
            return self._generate_subcategory_metadata_from_structure(metadata_file.parent, subcategory_name)
    
    def _generate_subcategory_metadata_from_structure(self, subdir: Path, subcategory_name: str) -> SubcategoryMetadata:
        """Generate subcategory metadata from directory structure"""
        # Count SQL files
        sql_files = list(subdir.glob("*.sql"))
        
        # Analyze SQL content for difficulty
        difficulty_level = self._analyze_sql_difficulty(sql_files)
        
        return SubcategoryMetadata(
            name=subcategory_name,
            display_name=self._generate_display_name(subcategory_name),
            description=f"Subcategory for {self._generate_display_name(subcategory_name)}",
            difficulty_level=difficulty_level,
            order_index=self._extract_order_from_name(subcategory_name),
            metadata={
                'source': 'auto_generated',
                'sql_file_count': len(sql_files),
                'generated_at': datetime.now().isoformat()
            }
        )
    
    def _analyze_sql_difficulty(self, sql_files: List[Path]) -> str:
        """Analyze SQL files to determine difficulty level"""
        if not sql_files:
            return 'Beginner'
        
        # Analyze a sample of SQL files
        complexity_scores = []
        for sql_file in sql_files[:3]:  # Sample first 3 files
            try:
                content = sql_file.read_text()
                score = self._calculate_sql_complexity(content)
                complexity_scores.append(score)
            except Exception:
                continue
        
        if not complexity_scores:
            return 'Beginner'
        
        avg_score = sum(complexity_scores) / len(complexity_scores)
        
        if avg_score >= 8:
            return 'Expert'
        elif avg_score >= 6:
            return 'Advanced'
        elif avg_score >= 4:
            return 'Intermediate'
        else:
            return 'Beginner'
    
    def _calculate_sql_complexity(self, content: str) -> int:
        """Calculate SQL complexity score (1-10)"""
        score = 1
        
        # Basic patterns
        if 'SELECT' in content.upper():
            score += 1
        if 'WHERE' in content.upper():
            score += 1
        if 'JOIN' in content.upper():
            score += 2
        if 'GROUP BY' in content.upper():
            score += 1
        if 'ORDER BY' in content.upper():
            score += 1
        
        # Advanced patterns
        if 'OVER(' in content.upper():
            score += 3
        if 'WITH' in content.upper() and 'RECURSIVE' in content.upper():
            score += 4
        if 'JSON_' in content.upper():
            score += 2
        if 'UNION' in content.upper():
            score += 2
        if 'EXISTS' in content.upper():
            score += 1
        
        # Constraints
        if 'PRIMARY KEY' in content.upper():
            score += 1
        if 'FOREIGN KEY' in content.upper():
            score += 2
        if 'UNIQUE' in content.upper():
            score += 1
        if 'CHECK' in content.upper():
            score += 2
        
        return min(10, score)
    
    def _determine_quest_difficulty(self, subcategories: List[SubcategoryMetadata]) -> str:
        """Determine quest difficulty based on subcategories"""
        if not subcategories:
            return 'Beginner'
        
        difficulty_scores = {
            'Beginner': 1,
            'Intermediate': 2,
            'Advanced': 3,
            'Expert': 4
        }
        
        total_score = sum(difficulty_scores.get(s.difficulty_level, 1) for s in subcategories)
        avg_score = total_score / len(subcategories)
        
        if avg_score >= 3.5:
            return 'Expert'
        elif avg_score >= 2.5:
            return 'Advanced'
        elif avg_score >= 1.5:
            return 'Intermediate'
        else:
            return 'Beginner'
    
    def _determine_quest_category(self, quest_name: str, subcategories: List[SubcategoryMetadata]) -> str:
        """Determine quest category based on name and content"""
        name_lower = quest_name.lower()
        
        # Category mapping based on quest names
        category_mapping = {
            'data-modeling': 'fundamentals',
            'performance-tuning': 'optimization',
            'window-functions': 'analytics',
            'json-operations': 'modern_features',
            'recursive-cte': 'advanced',
            'indexing': 'optimization',
            'query-optimization': 'optimization',
            'analytics': 'analytics',
            'advanced': 'advanced',
            'basics': 'fundamentals'
        }
        
        for key, category in category_mapping.items():
            if key in name_lower:
                return category
        
        # Default based on difficulty
        if any('advanced' in s.difficulty_level.lower() for s in subcategories):
            return 'advanced'
        elif any('intermediate' in s.difficulty_level.lower() for s in subcategories):
            return 'optimization'
        else:
            return 'fundamentals'
    
    def _count_sql_files(self, quest_dir: Path) -> int:
        """Count SQL files in quest directory"""
        count = 0
        for sql_file in quest_dir.rglob("*.sql"):
            count += 1
        return count
    
    def _determine_prerequisites(self, quest_name: str, difficulty_level: str) -> List[str]:
        """Determine prerequisites based on quest name and difficulty"""
        prerequisites = []
        
        if difficulty_level in ['Intermediate', 'Advanced', 'Expert']:
            prerequisites.append('basic SQL knowledge')
        
        if difficulty_level in ['Advanced', 'Expert']:
            prerequisites.append('intermediate SQL')
        
        if difficulty_level == 'Expert':
            prerequisites.append('advanced SQL concepts')
        
        # Quest-specific prerequisites
        name_lower = quest_name.lower()
        if 'performance' in name_lower or 'tuning' in name_lower:
            prerequisites.append('data modeling')
        if 'window' in name_lower:
            prerequisites.append('performance tuning')
        if 'json' in name_lower:
            prerequisites.append('intermediate SQL')
        if 'recursive' in name_lower:
            prerequisites.append('window functions')
        
        return list(set(prerequisites))  # Remove duplicates
    
    def _generate_display_name(self, name: str) -> str:
        """Generate display name from directory name"""
        # Remove number prefix and convert to title case
        clean_name = re.sub(r'^\d+-', '', name)
        return clean_name.replace('-', ' ').title()
    
    def _generate_quest_description(self, quest_name: str, category: str) -> str:
        """Generate quest description based on name and category"""
        display_name = self._generate_display_name(quest_name)
        
        descriptions = {
            'fundamentals': f'Core {display_name} concepts and principles',
            'optimization': f'{display_name} optimization and performance techniques',
            'analytics': f'Advanced analytics using {display_name}',
            'modern_features': f'Modern PostgreSQL {display_name} features',
            'advanced': f'Advanced {display_name} techniques and patterns'
        }
        
        return descriptions.get(category, f'{display_name} concepts and techniques')
    
    def create_quest_metadata_file(self, quest_dir: Path, quest_metadata: QuestMetadata):
        """Create a quest metadata file for future use"""
        metadata_file = quest_dir / "quest.json"
        
        metadata = {
            'display_name': quest_metadata.display_name,
            'description': quest_metadata.description,
            'difficulty_level': quest_metadata.difficulty_level,
            'order_index': quest_metadata.order_index,
            'category': quest_metadata.category,
            'estimated_duration_hours': quest_metadata.estimated_duration_hours,
            'prerequisites': quest_metadata.prerequisites,
            'metadata': quest_metadata.metadata,
            'generated_at': datetime.now().isoformat()
        }
        
        try:
            with open(metadata_file, 'w') as f:
                json.dump(metadata, f, indent=2)
            print(f"✅ Created quest metadata file: {metadata_file}")
        except Exception as e:
            print(f"⚠️  Error creating quest metadata file: {e}")
    
    def create_subcategory_metadata_file(self, subdir: Path, subcategory_metadata: SubcategoryMetadata):
        """Create a subcategory metadata file for future use"""
        metadata_file = subdir / "subcategory.json"
        
        metadata = {
            'display_name': subcategory_metadata.display_name,
            'description': subcategory_metadata.description,
            'difficulty_level': subcategory_metadata.difficulty_level,
            'order_index': subcategory_metadata.order_index,
            'metadata': subcategory_metadata.metadata,
            'generated_at': datetime.now().isoformat()
        }
        
        try:
            with open(metadata_file, 'w') as f:
                json.dump(metadata, f, indent=2)
            print(f"✅ Created subcategory metadata file: {metadata_file}")
        except Exception as e:
            print(f"⚠️  Error creating subcategory metadata file: {e}")

class QuestDiscoveryManager:
    """Manager for quest discovery operations"""
    
    def __init__(self, quests_directory: str = "quests"):
        self.discovery = QuestDiscovery(quests_directory)
    
    def discover_and_validate(self) -> Dict[str, QuestMetadata]:
        """Discover quests and validate the discovery"""
        print("🔍 Discovering quests from file system...")
        
        quests = self.discovery.discover_quests()
        
        if not quests:
            print("⚠️  No quests discovered!")
            return quests
        
        print(f"✅ Discovered {len(quests)} quests:")
        for name, metadata in quests.items():
            print(f"   📚 {metadata.display_name} ({metadata.difficulty_level}) - {metadata.category}")
        
        return quests
    
    def generate_metadata_files(self, quests: Dict[str, QuestMetadata]):
        """Generate metadata files for discovered quests"""
        print("\n📝 Generating metadata files...")
        
        for quest_name, quest_metadata in quests.items():
            quest_dir = self.discovery.quests_directory / quest_name
            if quest_dir.exists():
                self.discovery.create_quest_metadata_file(quest_dir, quest_metadata)
                
                # Generate subcategory metadata files
                subcategories = self.discovery._discover_subcategories(quest_dir)
                for subcategory in subcategories:
                    subdir = quest_dir / subcategory.name
                    if subdir.exists():
                        self.discovery.create_subcategory_metadata_file(subdir, subcategory)
    
    def get_quests_for_database(self, quests: Dict[str, QuestMetadata]) -> List[Dict[str, Any]]:
        """Convert discovered quests to database format"""
        db_quests = []
        
        for quest_name, quest_metadata in quests.items():
            quest_dir = self.discovery.quests_directory / quest_name
            subcategories = self.discovery._discover_subcategories(quest_dir)
            
            # Convert subcategories to database format
            db_subcategories = []
            for subcategory in subcategories:
                db_subcategories.append((
                    subcategory.name,
                    subcategory.display_name,
                    subcategory.difficulty_level,
                    subcategory.order_index
                ))
            
            db_quests.append({
                'name': quest_metadata.name,
                'display_name': quest_metadata.display_name,
                'description': quest_metadata.description,
                'difficulty_level': quest_metadata.difficulty_level,
                'order_index': quest_metadata.order_index,
                'metadata': quest_metadata.metadata,
                'subcategories': db_subcategories
            })
        
        return db_quests

async def main():
    """Test quest discovery"""
    print("🔍 Testing Quest Discovery System")
    print("=" * 50)
    
    # Initialize discovery manager
    manager = QuestDiscoveryManager("../../quests")
    
    # Discover quests
    quests = manager.discover_and_validate()
    
    if quests:
        # Generate metadata files (optional)
        # manager.generate_metadata_files(quests)
        
        # Convert to database format
        db_quests = manager.get_quests_for_database(quests)
        
        print(f"\n📊 Database-ready quests: {len(db_quests)}")
        for quest in db_quests:
            print(f"   {quest['name']}: {quest['display_name']} ({len(quest['subcategories'])} subcategories)")
    
    return len(quests) > 0

if __name__ == "__main__":
    import asyncio
    success = asyncio.run(main())
    print(f"\n{'✅' if success else '❌'} Quest discovery test {'passed' if success else 'failed'}") 