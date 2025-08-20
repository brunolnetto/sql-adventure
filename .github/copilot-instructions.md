# GitHub Copilot Instructions for SQL Adventure

## Project Architecture

**SQL Adventure** is a hybrid shell/Python system for evaluating SQL learning exercises with AI-powered assessment.

### Key Components
- `quests/`: SQL exercises organized by topic (5 quests: data-modeling, performance-tuning, window-functions, json-operations, recursive-cte)
- `scripts/evaluator/`: Python evaluation system with modular agents and database persistence
- `docs/`: Learning paths, cheatsheets, and validation guides

## Development Workflows

### Evaluation Pipeline
```bash
# AI-powered evaluation
python scripts/evaluator/run_evaluation.py quests/1-data-modeling

# Database initialization
python scripts/evaluator/init_database.py

# Shell wrapper (legacy compatibility)
scripts/validate.sh quests/1-data-modeling
```

### Database Setup
- PostgreSQL 15 with Docker support
- Use `scripts/init-db.sh` for setup
- Environment: `OPENAI_API_KEY`, `POSTGRES_DB_NAME`, `DB_HOST`, `DB_USER`, `DB_PASSWORD`

## Project-Specific Patterns

### Modular Agent Architecture
- **Intent Agent**: Analyzes educational purpose (`core/agents.py`)
- **SQL Instructor Agent**: Technical and educational analysis
- **Quality Assessor Agent**: Final assessment with recommendations
- All agents use `pydantic_ai.Agent` with structured Pydantic model outputs

### Model Structure
```python
# Aggregate models for pipeline results
class EvaluationResult(BaseModel):
    metadata: Dict[str, Any]
    execution: ExecutionResult
    intent: Intent
    llm_analysis: LLMAnalysis
    evaluated_at: datetime
```

### Repository Pattern
- Base repository with generic CRUD (`repositories/base_repository.py`)
- Specialized repositories for evaluations, SQL files, patterns, quests
- Session management: Always use `try/except/finally` with `session.commit()` and `session.rollback()`

### Error Handling Convention
- Capture partial results with error fields in models
- Log errors with context (agent_id, file_path)
- Continue pipeline when possible, mark incomplete stages
- Use `⚠️`, `❌`, `✅` emojis for consistent logging

## Integration Points

### Database Tables
- `quests` → `subcategories` → `sql_files` → `evaluations`
- SQLAlchemy models in `database/tables.py`
- Pydantic models in `core/models.py`

### Discovery System
- **Agnostic Discovery**: Auto-discovers quests and patterns from filesystem without hardcoded mappings
- **AI-Enhanced Descriptions**: Optional AI-powered quest analysis with fallback to content-based descriptions
- **Metadata Extraction**: SQL comment headers provide difficulty, concepts, and purpose information
- **Pattern Detection**: Regex-based detection of SQL patterns and complexity analysis

### Quest Enhancement Pipeline
```bash
# AI-powered quest description enhancement
python scripts/evaluator/enhance_quests.py

# Fallback-only enhancement (no AI)
python scripts/evaluator/enhance_quests.py --no-database

# Force regeneration of existing descriptions
python scripts/evaluator/enhance_quests.py --force
```

## Code Conventions

### Import Style
```python
# Use absolute imports for config and shared modules
from config import EvaluationConfig
from database.manager import DatabaseManager

# Use relative imports only within the same package
from .models import EvaluationResult
```

### Async/Await
- Use async for AI agent calls and database operations
- Connection pooling with `asyncpg` for SQL execution
- Session management with SQLAlchemy for persistence

### Type Hints
```python
# Use Annotated for Pydantic field constraints
score: Annotated[int, Field(ge=1, le=10)]
confidence: Annotated[float, Field(ge=0, le=1)]
```

## Testing
- Test files in `tests/` directory
- Focus on agent output validation, repository logic, discovery functions
- Mock external dependencies (OpenAI API, database connections)

## Key Files for Reference
- Pipeline: `core/evaluators.py`
- Models: `core/models.py`, `database/tables.py`
- Discovery: `utils/discovery.py`
- Configuration: `config.py`
- Database: `database/manager.py`, `init_database.py`
