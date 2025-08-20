# SQL Adventure API Documentation

This directory contains comprehensive API documentation for the SQL Adventure evaluation system.

## Documentation Structure

### Core Components
- **[Agents API](agents.md)** - AI agent interfaces and implementations
- **[Models API](models.md)** - Pydantic data models and validation
- **[Repositories API](repositories.md)** - Database access layer patterns
- **[Configuration API](configuration.md)** - Environment and settings management

### System Integration
- **[Database Schema](database-schema.md)** - Database tables and relationships
- **[Evaluation Pipeline](evaluation-pipeline.md)** - End-to-end processing workflow
- **[Error Handling](error-handling.md)** - Exception patterns and recovery strategies

### Development Reference
- **[Session Management](session-management.md)** - Database session patterns
- **[Testing Patterns](testing-patterns.md)** - Unit and integration test guidelines
- **[Deployment Guide](deployment.md)** - Production deployment instructions

## Quick Reference

### Key Classes
```python
# Core evaluation components
from core.evaluators import SQLEvaluator, QuestEvaluator
from core.agents import IntentAgent, InstructorAgent, QualityAgent
from core.models import EvaluationResult, Intent, LLMAnalysis

# Database access
from repositories.evaluation_repository import EvaluationRepository
from repositories.sql_file_repository import SQLFileRepository
from database.manager import DatabaseManager

# Configuration
from config import EvaluationConfig, ProjectFolderConfig
```

### Environment Setup
```bash
# Required environment variables
export OPENAI_API_KEY="your-openai-key"
export POSTGRES_DB_NAME="sql_adventure"
export DB_HOST="localhost"
export DB_USER="postgres"
export DB_PASSWORD="your-password"
```

## Usage Examples

### Basic Evaluation
```python
from core.evaluators import SQLEvaluator
from config import EvaluationConfig

# Initialize evaluator
config = EvaluationConfig()
evaluator = SQLEvaluator()

# Evaluate a SQL file
result = await evaluator.evaluate_file(Path("quests/1-data-modeling/01-basic-table-creation.sql"))
print(f"Score: {result.llm_analysis.assessment.score}/10")
```

### Database Operations
```python
from database.manager import DatabaseManager
from repositories.evaluation_repository import EvaluationRepository

# Initialize database connection
db_manager = DatabaseManager()
session = db_manager.SessionLocal()

try:
    # Query evaluations
    eval_repo = EvaluationRepository(session)
    evaluations = eval_repo.list(quest_id=1)
    
    # Process results
    for eval in evaluations:
        print(f"{eval.sql_file.filename}: {eval.letter_grade}")
        
    session.commit()
except Exception as e:
    session.rollback()
    raise
finally:
    session.close()
```

## Architecture Overview

The SQL Adventure evaluation system follows a modular architecture with clear separation of concerns:

1. **Agent Layer** - AI-powered analysis using OpenAI API
2. **Model Layer** - Pydantic data validation and serialization
3. **Repository Layer** - Database access with session management
4. **Configuration Layer** - Environment and settings validation

## Contributing

When adding new API components:

1. Document all public methods and classes
2. Include usage examples
3. Specify error conditions and handling
4. Add type hints and validation rules
5. Update this index with new documentation files

## See Also

- [Learning Path Guide](../learning-path.md)
- [AI Evaluation Overview](../ai-evaluation.md)
- [Development Quality Assurance](../development/quality-assurance.md)
