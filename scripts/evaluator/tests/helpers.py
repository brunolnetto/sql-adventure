"""
Common test utilities and helpers for SQL Adventure evaluator tests
"""
import asyncio
from pathlib import Path
from typing import Dict, Any, List, Optional, Union


class TestHelpers:
    """Common test helper functions"""
    
    @staticmethod
    def get_project_root() -> Path:
        """Get the project root directory"""
        return Path(__file__).parent.parent.parent.parent
    
    @staticmethod
    def get_evaluator_root() -> Path:
        """Get the evaluator root directory"""
        return Path(__file__).parent.parent
    
    @staticmethod
    def get_quests_dir() -> Path:
        """Get the quests directory"""
        return TestHelpers.get_project_root() / "quests"
    
    @staticmethod
    def get_sample_sql_file() -> Path:
        """Get a reliable sample SQL file for testing"""
        return TestHelpers.get_quests_dir() / "1-data-modeling" / "00-basic-concepts" / "01-basic-table-creation.sql"
    
    @staticmethod
    def validate_evaluation_result(result: Union[Dict[str, Any], Any]) -> bool:
        """Validate that an evaluation result has the expected structure"""
        # Handle both dict and Pydantic model formats
        if hasattr(result, 'metadata'):
            # Pydantic model - check attributes exist
            required_attrs = ["metadata", "execution", "intent", "llm_analysis", "evaluated_at"]
            return all(hasattr(result, attr) for attr in required_attrs)
        else:
            # Dictionary format 
            required_fields = ["metadata", "execution", "intent", "llm_analysis", "evaluated_at"]
            return all(field in result for field in required_fields)
    
    @staticmethod
    def validate_ai_analysis_quality(result: Union[Dict[str, Any], Any]) -> bool:
        """Check if AI analysis shows good quality (not fallback)"""
        # Handle both dict and Pydantic model formats
        if hasattr(result, 'llm_analysis'):
            # Pydantic model
            assessment = result.llm_analysis.assessment
            grade = assessment.grade
            score = assessment.score
            overall_assessment = assessment.overall_assessment
        else:
            # Dictionary format
            llm_analysis = result.get("llm_analysis", {})
            assessment = llm_analysis.get("assessment", {})
            grade = assessment.get("grade", "F")
            score = assessment.get("score", 0)
            overall_assessment = assessment.get("overall_assessment", "FAIL")
        
        # Good quality indicators
        return (
            grade in ["A", "B"] and 
            score >= 7 and 
            overall_assessment == "PASS"
        )
    
    @staticmethod
    def count_detected_patterns(result: Union[Dict[str, Any], Any]) -> int:
        """Count the number of detected patterns in the result"""
        # Handle both dict and Pydantic model formats
        if hasattr(result, 'llm_analysis'):
            # Pydantic model
            patterns = result.llm_analysis.analysis.detected_patterns
        else:
            # Dictionary format
            llm_analysis = result.get("llm_analysis", {})
            analysis = llm_analysis.get("analysis", {})
            patterns = analysis.get("detected_patterns", [])
        return len(patterns)


class AsyncTestRunner:
    """Helper for running async functions in tests"""
    
    @staticmethod
    def run(coro):
        """Run an async coroutine in a test"""
        return asyncio.run(coro)


class MockData:
    """Mock data for testing"""
    
    @staticmethod
    def get_sample_sql_content() -> str:
        """Get sample SQL content for testing"""
        return """
-- Test SQL: Basic Table Creation
-- PURPOSE: Test table creation concepts
-- DIFFICULTY: 🟢 Beginner (5 min)
-- CONCEPTS: Table creation, data types

CREATE TABLE test_users (
    id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE
);

INSERT INTO test_users VALUES (1, 'Test User', 'test@example.com');
SELECT * FROM test_users;
DROP TABLE test_users;
"""
    
    @staticmethod
    def get_expected_patterns() -> List[str]:
        """Get expected SQL patterns for the sample content"""
        return ["table_creation", "constraint_definition", "data_insertion", "simple_select"]


# Additional helper functions for integration tests
def create_test_sql_file(tmp_path, content):
    """Create a temporary SQL file with given content."""
    sql_file = tmp_path / "test.sql"
    sql_file.write_text(content)
    return sql_file


def validate_analysis_structure(analysis):
    """Validate that an analysis object has the expected structure."""
    assert analysis is not None
    assert hasattr(analysis, 'overall_score')
    assert hasattr(analysis, 'overall_feedback')
    assert hasattr(analysis, 'grade')
    assert hasattr(analysis, 'confidence')
    
    # Validate score range
    assert 1 <= analysis.overall_score <= 10
    
    # Validate grade
    assert analysis.grade in ['A', 'B', 'C', 'D', 'F']
    
    # Validate confidence
    assert 0.0 <= analysis.confidence <= 1.0
    
    # Validate feedback exists
    assert analysis.overall_feedback is not None
    assert len(analysis.overall_feedback) > 0


def validate_pattern_detection(patterns, expected_patterns=None):
    """Validate pattern detection results."""
    assert patterns is not None
    assert isinstance(patterns, list)
    
    if expected_patterns:
        detected_pattern_names = [p.pattern_name for p in patterns]
        for expected in expected_patterns:
            assert expected in detected_pattern_names, f"Expected pattern '{expected}' not found"


def validate_score_range(score, min_score=1, max_score=10):
    """Validate that a score is within the expected range."""
    assert isinstance(score, (int, float))
    assert min_score <= score <= max_score
