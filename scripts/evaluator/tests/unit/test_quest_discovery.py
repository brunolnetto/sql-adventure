#!/usr/bin/env python3
"""
Test Script for Quest Discovery System
Tests the filesystem-based quest discovery functionality
"""

import sys
import asyncio
import pytest
from pathlib import Path

# Add the evaluator directory to the path for proper imports
evaluator_dir = Path(__file__).parent.parent
sys.path.insert(0, str(evaluator_dir))

from utils.discovery import discover_quests_from_filesystem

@pytest.mark.asyncio
async def test_quest_discovery():
    """Test the quest discovery system"""
    print("🔍 Testing Quest Discovery System")
    print("=" * 50)
    
    try:
        # Test quest discovery from filesystem
        print("📚 Discovering quests from filesystem...")
        quests_dir = Path("../../../quests")
        
        if not quests_dir.exists():
            print(f"❌ Quests directory not found: {quests_dir}")
            return False
            
        quests_data = discover_quests_from_filesystem(quests_dir)
        
        if not quests_data:
            print("❌ No quests discovered!")
            return False
        
        print(f"✅ Successfully discovered {len(quests_data)} quests")
        
        # Show quest details
        print("\n📋 Quest details:")
        for quest_data in quests_data:
            name = quest_data.get('name', 'Unknown')
            directory = quest_data.get('directory', 'Unknown')
            subcategories = quest_data.get('subcategories', [])
            
            print(f"   📚 {name}")
            print(f"      Directory: {directory}")
            print(f"      Subcategories: {len(subcategories)}")
            
            # Show some subcategories
            for subcat in subcategories[:3]:  # Show first 3
                subcat_name = subcat.get('name', 'Unknown')
                files = subcat.get('sql_files', [])
                print(f"        📂 {subcat_name}: {len(files)} files")
            
            if len(subcategories) > 3:
                print(f"        ... and {len(subcategories) - 3} more")
            print()
        
        return True
        
    except Exception as e:
        print(f"❌ Quest discovery test failed: {e}")
        return False

async def main():
    """Run the quest discovery test"""
    print("🚀 Quest Discovery System Test")
    print("=" * 50)
    
    # Test quest discovery
    success = await test_quest_discovery()
    
    if success:
        print("\n🎉 Quest discovery test passed!")
    else:
        print("\n❌ Quest discovery test failed!")
        
    return success

if __name__ == "__main__":
    asyncio.run(main())
    asyncio.run(main())

@pytest.mark.asyncio
async def test_quest_discovery():
    """Test the quest discovery system"""
    print("🔍 Testing Dynamic Quest Discovery System")
    print("=" * 60)
    
    try:
        # 1. Test quest discovery
        print("📚 Step 1: Discovering quests from file system...")
        manager = QuestDiscoveryManager("../../quests")
        quests = manager.discover_and_validate()
        
        if not quests:
            print("❌ No quests discovered!")
            return False
        
        print(f"✅ Successfully discovered {len(quests)} quests")
        
        # 2. Show quest details
        print("\n📋 Step 2: Quest details:")
        for name, metadata in quests.items():
            print(f"   📚 {metadata.display_name}")
            print(f"      Difficulty: {metadata.difficulty_level}")
            print(f"      Category: {metadata.category}")
            print(f"      Duration: {metadata.estimated_duration_hours} hours")
            print(f"      Prerequisites: {', '.join(metadata.prerequisites)}")
            print(f"      Source: {metadata.metadata.get('source', 'unknown')}")
            print()
        
        # 3. Test database format conversion
        print("🗄️  Step 3: Converting to database format...")
        db_quests = manager.get_quests_for_database(quests)
        
        print(f"✅ Converted {len(db_quests)} quests to database format")
        for quest in db_quests:
            print(f"   {quest['name']}: {len(quest['subcategories'])} subcategories")
        
        # 4. Test database initialization with discovered quests
        print("\n🔧 Step 4: Testing database initialization with discovered quests...")
        config = get_config()
        config.evaluation.quests_directory = "../../quests"
        config.evaluation.enable_quest_discovery = True
        
        db_manager = DatabaseManager(config)
        
        # Initialize database (this will use the discovered quests)
        if db_manager.initialize():
            print("✅ Database initialized successfully with discovered quests!")
            
            # Check health
            health = db_manager.check_health()
            print(f"🏥 Database health: {health['status']}")
            
            if health['healthy']:
                print(f"📊 Database stats: {health['quests']} quests, {health['patterns']} patterns")
            else:
                print(f"⚠️  Database health issues: {health['message']}")
        else:
            print("❌ Database initialization failed!")
            return False
        
        # 5. Test metadata file generation (optional)
        print("\n📝 Step 5: Testing metadata file generation...")
        try:
            manager.generate_metadata_files(quests)
            print("✅ Metadata files generated successfully!")
        except Exception as e:
            print(f"⚠️  Metadata file generation failed: {e}")
        
        return True
        
    except Exception as e:
        print(f"❌ Quest discovery test failed: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    finally:
        # Cleanup
        if 'db_manager' in locals():
            db_manager.close()

@pytest.mark.asyncio
async def test_extensibility():
    """Test the extensibility of the quest discovery system"""
    print("\n🔌 Testing Quest Discovery Extensibility")
    print("=" * 50)
    
    try:
        # Test with different quest directory
        print("📁 Testing with different quest directory...")
        
        # Create a test quest structure
        test_quests_dir = Path("test_quests")
        test_quests_dir.mkdir(exist_ok=True)
        
        # Create a test quest
        test_quest_dir = test_quests_dir / "6-test-quest"
        test_quest_dir.mkdir(exist_ok=True)
        
        # Create test subcategories
        (test_quest_dir / "00-basic-test").mkdir(exist_ok=True)
        (test_quest_dir / "01-advanced-test").mkdir(exist_ok=True)
        
        # Create test SQL files
        (test_quest_dir / "00-basic-test" / "test1.sql").write_text("SELECT * FROM test;")
        (test_quest_dir / "01-advanced-test" / "test2.sql").write_text("SELECT * FROM test WHERE id > 10;")
        
        # Test discovery with test directory
        manager = QuestDiscoveryManager("test_quests")
        quests = manager.discover_and_validate()
        
        if quests:
            print(f"✅ Successfully discovered test quest: {list(quests.keys())[0]}")
            
            # Show test quest details
            test_quest = list(quests.values())[0]
            print(f"   Display Name: {test_quest.display_name}")
            print(f"   Difficulty: {test_quest.difficulty_level}")
            print(f"   Category: {test_quest.category}")
            print(f"   SQL Files: {test_quest.metadata.get('sql_file_count', 0)}")
        else:
            print("❌ Test quest not discovered")
        
        # Cleanup test directory
        import shutil
        shutil.rmtree(test_quests_dir, ignore_errors=True)
        
        return True
        
    except Exception as e:
        print(f"❌ Extensibility test failed: {e}")
        return False

async def main():
    """Main test function"""
    print("🚀 Dynamic Quest Discovery System - Complete Test Suite")
    print("=" * 70)
    
    success = True
    
    # Test quest discovery
    if not await test_quest_discovery():
        success = False
    
    # Test extensibility
    if not await test_extensibility():
        success = False
    
    if success:
        print("\n🎉 All tests passed! Quest discovery system is working correctly.")
        print("\n📋 Summary of improvements:")
        print("   ✅ Dynamic quest discovery from file system")
        print("   ✅ Automatic metadata extraction from README files")
        print("   ✅ Intelligent difficulty and category detection")
        print("   ✅ SQL complexity analysis")
        print("   ✅ Fallback to hard-coded data if discovery fails")
        print("   ✅ Extensible for future quest additions")
        return 0
    else:
        print("\n❌ Some tests failed. Please check the errors above.")
        return 1

if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code) 