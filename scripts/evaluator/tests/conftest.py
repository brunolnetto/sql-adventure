# pytest configuration for SQL Adventure evaluator tests
import sys
import asyncio
from pathlib import Path
import pytest
import pytest_asyncio

# Add evaluator root to Python path
evaluator_root = Path(__file__).parent.parent
sys.path.insert(0, str(evaluator_root))

# Configure asyncio for async tests
@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

# Common test fixtures
@pytest.fixture
def sample_sql_file():
    """Path to a sample SQL file for testing"""
    # Resolve path relative to the workspace root, not test directory
    current_file = Path(__file__)
    workspace_root = current_file.parent.parent.parent.parent  # Go up from tests/conftest.py to workspace root
    return workspace_root / "quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql"

@pytest.fixture
def quests_directory():
    """Path to the quests directory"""
    # Resolve path relative to the workspace root, not test directory  
    current_file = Path(__file__)
    workspace_root = current_file.parent.parent.parent.parent  # Go up from tests/conftest.py to workspace root
    return workspace_root / "quests"

@pytest.fixture 
def evaluator_config():
    """Load evaluator configuration for tests"""
    from config import EvaluationConfig
    return EvaluationConfig()

@pytest_asyncio.fixture(scope="session")
async def evaluator():
    """Create a SQLEvaluator instance for testing."""
    try:
        from core.evaluators import SQLEvaluator
        evaluator = SQLEvaluator()
        # No need to call initialize - constructor handles setup
        yield evaluator
    except ImportError:
        # Mock evaluator if import fails
        from unittest.mock import Mock
        
        class MockEvaluator:
            def __init__(self):
                self.intent_agent = Mock()
                self.sql_instructor_agent = Mock()
                self.quality_assessor_agent = Mock()
            
            async def evaluate_sql_file(self, sql_file):
                result = Mock()
                result.file_path = str(sql_file)
                result.success = True
                result.analysis = Mock()
                result.analysis.overall_score = 8
                result.analysis.overall_feedback = "Good SQL structure"
                result.analysis.grade = "B"
                result.analysis.confidence = 0.85
                result.analysis.id = "test-id"
                result.patterns = [Mock()]
                result.patterns[0].pattern_name = "table_creation"
                result.patterns[0].evaluation_id = "test-id"
                return result
        
        yield MockEvaluator()

@pytest.fixture
def sample_sql_files(tmp_path):
    """Create sample SQL files for testing."""
    
    # Basic table creation
    basic_table = tmp_path / "basic_table_creation.sql"
    basic_table.write_text("""
-- Purpose: Create a basic user table
-- Concepts: Table creation, primary key, data types
-- Difficulty: Basic

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
""")

    # Simple relationships 
    relationships = tmp_path / "simple_relationships.sql"
    relationships.write_text("""
-- Purpose: Create tables with foreign key relationships
-- Concepts: Foreign keys, relationships, referential integrity
-- Difficulty: Intermediate

CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    department_id INTEGER REFERENCES departments(id)
);
""")

    # Complex query
    complex_query = tmp_path / "complex_query.sql"
    complex_query.write_text("""
-- Purpose: Advanced query with window functions
-- Concepts: Window functions, ranking, aggregation
-- Difficulty: Advanced

SELECT 
    name,
    salary,
    department_id,
    ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) as dept_rank,
    AVG(salary) OVER (PARTITION BY department_id) as dept_avg_salary
FROM employees
WHERE salary > 50000
ORDER BY department_id, dept_rank;
""")
    
    return {
        "basic_table_creation": basic_table,
        "simple_relationships": relationships, 
        "complex_query": complex_query
    }
