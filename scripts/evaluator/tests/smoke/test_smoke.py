"""
Smoke tests - quick health checks for the system
"""
import pytest
from pathlib import Path
import sys

# Add evaluator root to path
evaluator_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(evaluator_root))


class TestSmoke:
    """Quick smoke tests to verify basic functionality"""
    
    def test_imports_work(self):
        """Test that basic imports work without errors"""
        try:
            from core.evaluators import SQLEvaluator
            from core.models import LLMAnalysis, Assessment
            from config import EvaluationConfig
            print("✅ All core imports successful")
        except ImportError as e:
            pytest.fail(f"Import failed: {e}")
    
    def test_configuration_loads(self):
        """Test that configuration can be loaded"""
        try:
            from config import EvaluationConfig
            config = EvaluationConfig()
            assert config.model_name is not None
            print(f"✅ Configuration loaded: {config.model_name}")
        except Exception as e:
            pytest.fail(f"Configuration loading failed: {e}")
    
    def test_sample_sql_file_exists(self):
        """Test that we have a sample SQL file to work with"""
        # Go up from evaluator to project root (scripts/evaluator -> scripts -> project)
        project_root = evaluator_root.parent.parent
        quests_dir = project_root / "quests"
        sample_file = quests_dir / "1-data-modeling" / "00-basic-concepts" / "01-basic-table-creation.sql"
        
        assert quests_dir.exists(), f"Quests directory not found: {quests_dir}"
        assert sample_file.exists(), f"Sample SQL file not found: {sample_file}"
        print(f"✅ Sample SQL file exists: {sample_file}")
    
    def test_database_connection_possible(self):
        """Test that database connection configuration is valid"""
        try:
            from database.manager import DatabaseManager
            from database.tables import EvaluationBase
            
            # Just test that we can create the manager (don't actually connect)
            db_manager = DatabaseManager(EvaluationBase, database_type="evaluator")
            assert db_manager is not None
            print("✅ Database manager can be created")
        except Exception as e:
            pytest.fail(f"Database configuration failed: {e}")
    
    @pytest.mark.asyncio
    async def test_evaluator_creation(self):
        """Test that SQLEvaluator can be created"""
        try:
            from core.evaluators import SQLEvaluator
            evaluator = SQLEvaluator()
            assert evaluator is not None
            print("✅ SQLEvaluator created successfully")
        except Exception as e:
            pytest.fail(f"SQLEvaluator creation failed: {e}")
    
    def test_quest_discovery_works(self):
        """Test that quest discovery can find quests"""
        try:
            from utils.discovery import discover_quests_from_filesystem
            
            # Go up from evaluator to project root (scripts/evaluator -> scripts -> project)
            project_root = evaluator_root.parent.parent
            quests_dir = project_root / "quests"
            
            if quests_dir.exists():
                quests = discover_quests_from_filesystem(quests_dir)
                assert len(quests) > 0, "No quests discovered"
                print(f"✅ Quest discovery found {len(quests)} quests")
            else:
                print("⚠️ Quests directory not found, skipping quest discovery test")
        except Exception as e:
            pytest.fail(f"Quest discovery failed: {e}")


if __name__ == "__main__":
    """Run smoke tests directly"""
    import asyncio
    
    print("🔥 Running SQL Adventure Smoke Tests")
    print("=" * 50)
    
    test = TestSmoke()
    
    try:
        test.test_imports_work()
        test.test_configuration_loads() 
        test.test_sample_sql_file_exists()
        test.test_database_connection_possible()
        test.test_quest_discovery_works()
        
        # Run async test
        asyncio.run(test.test_evaluator_creation())
        
        print("\n🎉 All smoke tests passed!")
        
    except Exception as e:
        print(f"\n❌ Smoke test failed: {e}")
        exit(1)
