#!/usr/bin/env python3
"""
System Initialization Script for SQL Adventure AI Evaluator
Sets up database and tests the new flexible system
"""

import sys
import asyncio
from pathlib import Path

# Add the current directory to the path
sys.path.insert(0, str(Path(__file__).parent))

from core.database_manager import DatabaseManager
from core.ai_evaluator import SQLEvaluator
from core.config import get_config

async def initialize_system():
    """Initialize the complete evaluator system"""
    print("🚀 SQL Adventure AI Evaluator - System Initialization")
    print("=" * 60)
    
    try:
        # 1. Load configuration
        print("📋 Loading configuration...")
        config = get_config()
        print(f"   Database: {config.database.database}")
        print(f"   AI Model: {config.ai.model.value}")
        print(f"   Environment: {config.environment}")
        
        # 2. Initialize database
        print("\n🗄️  Initializing database...")
        db_manager = DatabaseManager(config)
        
        if db_manager.initialize():
            print("✅ Database initialized successfully!")
            
            # Check health
            health = db_manager.check_health()
            print(f"🏥 Database health: {health['status']}")
            
            if health['healthy']:
                print(f"📊 Database stats: {health['quests']} quests, {health['patterns']} patterns")
            else:
                print(f"⚠️  Database health issues: {health['message']}")
                return False
        else:
            print("❌ Database initialization failed!")
            return False
        
        # 3. Test AI evaluator
        print("\n🤖 Testing AI evaluator...")
        evaluator = SQLEvaluator(config=config, db_manager=db_manager)
        
        # Test with a sample SQL file
        test_file = Path("../../quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql")
        
        if test_file.exists():
            print(f"🔍 Testing evaluation with: {test_file.name}")
            
            result = await evaluator.evaluate_sql_file(test_file)
            
            print(f"✅ Evaluation completed!")
            print(f"   Assessment: {result.assessment.overall_assessment}")
            print(f"   Score: {result.assessment.score}/10 ({result.assessment.grade})")
            print(f"   Patterns detected: {len(result.patterns.detected_patterns)}")
            print(f"   Evaluation time: {result.metadata.get('evaluation_time_ms', 0)}ms")
            
            # Test database save
            print("\n💾 Testing database save...")
            saved = await evaluator.save_evaluation_to_db(result, str(test_file))
            print(f"   Saved to database: {saved}")
            
            # Test evaluation history
            print("\n📚 Testing evaluation history...")
            history = evaluator.get_evaluation_history(limit=5)
            print(f"   Found {len(history)} recent evaluations")
            
        else:
            print(f"⚠️  Test file not found: {test_file}")
            print("   Skipping evaluation test")
        
        # 4. System summary
        print("\n" + "=" * 60)
        print("🎉 System Initialization Complete!")
        print("=" * 60)
        
        print("✅ Database: Initialized and healthy")
        print("✅ AI Evaluator: Ready for use")
        print("✅ Configuration: Loaded successfully")
        print("✅ Models: Flexible and extensible")
        
        print("\n🚀 The system is ready for use!")
        print("   Use 'python main.py' to start the CLI")
        print("   Use 'python batch_evaluate.py' for batch processing")
        
        return True
        
    except Exception as e:
        print(f"❌ System initialization failed: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    finally:
        # Cleanup
        if 'db_manager' in locals():
            db_manager.close()

async def test_flexible_models():
    """Test the new flexible model system"""
    print("\n🧪 Testing Flexible Models")
    print("-" * 30)
    
    try:
        from core.models import ModelUtils, Quest, Evaluation
        
        # Test metadata utilities
        print("📝 Testing metadata utilities...")
        
        # Create a test quest
        quest = Quest(
            name="test-quest",
            display_name="Test Quest",
            description="Test quest for model validation",
            difficulty_level="Beginner",
            order_index=1
        )
        
        # Test metadata operations
        ModelUtils.set_metadata_value(quest, "category", "test")
        ModelUtils.set_metadata_value(quest, "tags", ["test", "validation"])
        
        category = ModelUtils.get_metadata_value(quest, "category")
        tags = ModelUtils.get_metadata_value(quest, "tags")
        
        print(f"   Category: {category}")
        print(f"   Tags: {tags}")
        
        # Test JSON field operations
        print("📊 Testing JSON field operations...")
        
        evaluation = Evaluation(
            sql_file_id=1,
            quest_id=1,
            overall_assessment="PASS",
            numeric_score=8,
            letter_grade="B"
        )
        
        ModelUtils.set_json_field_value(evaluation, "technical_analysis", "syntax_score", 8)
        ModelUtils.set_json_field_value(evaluation, "technical_analysis", "logic_score", 7)
        
        syntax_score = ModelUtils.get_json_field_value(evaluation, "technical_analysis", "syntax_score")
        logic_score = ModelUtils.get_json_field_value(evaluation, "technical_analysis", "logic_score")
        
        print(f"   Syntax Score: {syntax_score}")
        print(f"   Logic Score: {logic_score}")
        
        print("✅ Flexible models test completed!")
        return True
        
    except Exception as e:
        print(f"❌ Flexible models test failed: {e}")
        return False

async def main():
    """Main initialization function"""
    print("🔧 SQL Adventure AI Evaluator - Complete System Setup")
    print("=" * 70)
    
    success = True
    
    # Initialize system
    if not await initialize_system():
        success = False
    
    # Test flexible models
    if not await test_flexible_models():
        success = False
    
    if success:
        print("\n🎉 All tests passed! System is ready for production use.")
        return 0
    else:
        print("\n❌ Some tests failed. Please check the errors above.")
        return 1

if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code) 