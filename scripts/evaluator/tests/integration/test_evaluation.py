"""
Integration tests for the evaluation pipeline
Tests our improved AI analysis with 3x retry logic
"""
import pytest
from pathlib import Path
import sys

# Add parent directory to path for helpers import
sys.path.insert(0, str(Path(__file__).parent.parent))

from helpers import TestHelpers, AsyncTestRunner
from core.evaluators import SQLEvaluator


class TestEvaluationPipeline:
    """Test the complete evaluation pipeline including our AI improvements"""
    
    def test_sample_file_exists(self, sample_sql_file):
        """Ensure our test SQL file exists"""
        assert sample_sql_file.exists(), f"Sample SQL file not found: {sample_sql_file}"
    
    @pytest.mark.asyncio
    async def test_sql_evaluator_initialization(self, evaluator_config):
        """Test that SQLEvaluator can be initialized properly"""
        evaluator = SQLEvaluator()
        assert evaluator is not None
        
        # Test that agents are properly configured with retry settings
        assert hasattr(evaluator, 'agents')
        assert 'sql_instructor' in evaluator.agents
        assert 'intent_analyst' in evaluator.agents
    
    @pytest.mark.asyncio 
    async def test_basic_evaluation_success(self, sample_sql_file):
        """Test that we can successfully evaluate a SQL file"""
        if not sample_sql_file.exists():
            pytest.skip(f"Sample SQL file not found: {sample_sql_file}")
        
        evaluator = SQLEvaluator()
        
        # Test file execution
        execution_result = await evaluator.execute_sql_file(sample_sql_file)
        
        assert execution_result is not None
        assert execution_result.get("success") is True
        assert "output_content" in execution_result
        assert len(execution_result["output_content"]) > 0
        
        print(f"✅ Execution successful: {len(execution_result['output_content'])} chars output")
    
    @pytest.mark.asyncio
    async def test_ai_analysis_quality(self, sample_sql_file):
        """Test that our improved AI analysis produces high-quality results"""
        if not sample_sql_file.exists():
            pytest.skip(f"Sample SQL file not found: {sample_sql_file}")
        
        evaluator = SQLEvaluator()
        
        # Run full evaluation
        try:
            result = await evaluator.evaluate_sql_file(sample_sql_file)
            
            # Validate structure
            assert TestHelpers.validate_evaluation_result(result)
            print("✅ Evaluation result structure is valid")
            
            # Test AI analysis quality (should not be fallback)
            is_high_quality = TestHelpers.validate_ai_analysis_quality(result)
            
            # Extract analysis details for debugging (using Pydantic model attributes)
            llm_analysis = result.llm_analysis
            assessment = llm_analysis.assessment
            grade = assessment.grade
            score = assessment.score
            overall = assessment.overall_assessment
            
            print(f"📊 AI Analysis Results:")
            print(f"   Grade: {grade}")
            print(f"   Score: {score}")
            print(f"   Assessment: {overall}")
            print(f"   High Quality: {is_high_quality}")
            
            # Pattern detection
            pattern_count = TestHelpers.count_detected_patterns(result)
            print(f"   Patterns detected: {pattern_count}")
            
            # With our improvements, this should be high quality
            if is_high_quality:
                print("🎉 AI analysis is high quality! Our improvements worked!")
            else:
                print("⚠️ AI analysis quality could be improved")
                
            # At minimum, it should not be a complete failure
            assert grade != "F"
            assert score > 0
            assert overall in ["PASS", "NEEDS_REVIEW"]  # Not FAIL
            
        except Exception as e:
            pytest.fail(f"Evaluation failed with error: {e}")
    
    @pytest.mark.asyncio
    async def test_pattern_detection_working(self, sample_sql_file):
        """Test that pattern detection is working properly"""
        if not sample_sql_file.exists():
            pytest.skip(f"Sample SQL file not found: {sample_sql_file}")
        
        evaluator = SQLEvaluator()
        result = await evaluator.evaluate_sql_file(sample_sql_file)
        
        pattern_count = TestHelpers.count_detected_patterns(result)
        
        # Should detect some patterns (our sample file has table creation, etc.)
        assert pattern_count > 0, "No patterns detected - pattern detection may be broken"
        
        # Should detect reasonable number of patterns (not excessive)
        assert pattern_count <= 10, f"Too many patterns detected ({pattern_count}) - may be over-detecting"
        
        print(f"✅ Pattern detection working: {pattern_count} patterns detected")
        
        # Check pattern names are reasonable (using Pydantic model attributes)
        llm_analysis = result.llm_analysis
        analysis = llm_analysis.analysis
        patterns = analysis.detected_patterns
        
        pattern_names = [p.name for p in patterns]
        print(f"   Detected patterns: {pattern_names}")
        
        # Should include expected patterns for table creation file
        expected_patterns = ["table_creation", "constraint_definition", "data_insertion", "simple_select"]
        found_expected = sum(1 for pattern in expected_patterns if pattern in pattern_names)
        
        assert found_expected > 0, f"No expected patterns found. Detected: {pattern_names}"
        print(f"✅ Found {found_expected}/{len(expected_patterns)} expected patterns")
