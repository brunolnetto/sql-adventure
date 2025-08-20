# GitHub Copilot Instructions for SQL Adventure

## Project Architecture

**SQL Adventure** is a hybrid shell/Python system for evaluating SQL learning exercises with AI-powered assessment and separated database architecture.

### Key Components
- `quests/`: SQL exercises organized by topic (5 quests: data-modeling, performance-tuning, window-functions, json-operations, recursive-cte)
- `scripts/evaluator/`: Python evaluation system with modular agents and dual-database persistence
- `docs/`: Learning paths, cheatsheets, and validation guides

## Development Workflows

### Primary Interface: Task Runner
```bash
# Unified command interface (preferred approach)
scripts/task_runner.sh evaluate quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql
scripts/task_runner.sh evaluate quests/1-data-modeling  # Full quest
scripts/task_runner.sh setup     # Interactive configuration wizard
scripts/task_runner.sh init-db   # Database initialization
scripts/task_runner.sh test      # Run test suite

# Direct Python calls (legacy, still supported)
python3 scripts/evaluator/run_evaluation.py quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql
```

### Alternative Interface: Justfile
```bash
# Modern task runner with just
just eval quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql
just eval-quest 1-data-modeling  # Quest by number
just setup && just init-db        # Chain commands
```

### Docker Setup
```bash
# Start PostgreSQL instance (hosts both databases)
docker-compose up -d postgres

# Access pgAdmin at localhost:8080
docker-compose up -d pgadmin
```

### Database Architecture (Critical)
**Two Separate Databases:**
- `sql_adventure_evaluator`: Metadata storage with `EvaluationBase` schema (analyses, patterns, results)
- `sql_adventure_quests`: Execution sandbox with no persistent schema (clean slate for each SQL execution)

**Environment Separation:**
- Root `.env`: Quest database configuration for Docker/main project
- `scripts/evaluator/.env`: Complete evaluator configuration with both database connections

### Test Organization (Recently Restructured)
```bash
# Test structure follows standard patterns
scripts/evaluator/tests/
├── smoke/      # Basic system health checks (6 tests)
├── unit/       # Isolated component tests  
├── integration/ # Full pipeline tests
├── conftest.py # Shared test configuration
└── helpers.py  # Test utilities with dual format support

# Run specific test categories
python3 -m pytest scripts/evaluator/tests/smoke/ -v      # Quick health check
python3 -m pytest scripts/evaluator/tests/unit/ -v       # Component tests
python3 -m pytest scripts/evaluator/tests/integration/ -v # End-to-end tests
scripts/task_runner.sh test  # Run all tests via task runner
```

## Project-Specific Patterns

### Database Manager Design (Separation of Concerns)
```python
# System Logic (Generic)
class DatabaseManager:
    def drop_all_tables(self) -> int:  # Returns count, no domain logic
        
# Domain Logic (Evaluator-specific)  
class SQLEvaluator:
    def _cleanup_execution_sandbox(self):  # Business rules and messaging
        tables_dropped = self.sql_execution_manager.drop_all_tables()
```

### Dual Database Managers
```python
# Evaluator database: stores evaluation metadata with proper schema
self.db_manager = DatabaseManager(EvaluationBase, database_type="evaluator")

# Quests database: execution sandbox only, no schema needed
self.sql_execution_manager = DatabaseManager(None, database_type="quests")
```

### Environment Loading (Singleton Pattern)
```python
# Smart environment loader handles calls from project root
load_evaluator_env()  # Only loads once, searches multiple paths
```

### Model Structure (Simplified Schema)
```python
# Simplified from separate TechnicalAnalysis/EducationalAnalysis
class Analysis(EvaluationBase):
    # Unified analysis with JSON fields for flexibility
    overall_feedback: Text
    detected_patterns: JSON  # Array of pattern names
    
# Normalized pattern relationships
class EvaluationPattern(EvaluationBase):
    evaluation_id: ForeignKey
    pattern_id: ForeignKey  # Junction table pattern
```

## Integration Points

### Database Schema Evolution
- **Before**: 12 tables with over-denormalized structure
- **After**: 8 tables with normalized patterns via junction table
- **Pattern Detection**: JSON arrays → Normalized `evaluation_patterns` table

### Agent Architecture (Pydantic AI)
- **Intent Agent**: Educational purpose analysis (`core/agents.py`)
- **SQL Instructor Agent**: Technical and pedagogical assessment  
- **Quality Assessor Agent**: Final scoring with recommendations
- All agents use `pydantic_ai.Agent` with structured outputs

### Discovery System
- **Filesystem-based Quest Discovery**: Auto-discovers quests from `quests/` directory structure
- **Metadata Extraction**: Parses SQL comment headers for difficulty, concepts, purpose
- **Pattern Detection**: Identifies SQL patterns (table_creation, joins, window_functions, etc.)
- **No Hardcoded Mappings**: System adapts to quest structure changes automatically

### Test Infrastructure (100% Pass Rate)
- **Enhanced TestHelpers**: Support both dict and Pydantic model formats
- **Pydantic Compatibility**: All deprecation warnings resolved with `model_config` pattern
- **Organized Structure**: Proper smoke/unit/integration test separation
- **Dual Format Support**: Handles legacy dict results and modern Pydantic models

### Execution Sandbox Cleanup
```python
# Domain logic: Clean sandbox before each SQL file execution
self._cleanup_execution_sandbox()  # Drops all tables from quests DB
```

## Code Conventions

### Environment Configuration
```python
# Evaluator-specific config (scripts/evaluator/.env)
EVALUATOR_DB_NAME=sql_adventure_evaluator  # Metadata storage
QUESTS_DB_NAME=sql_adventure_quests        # Execution sandbox

# Root config (.env) - quest database only
POSTGRES_DB=sql_adventure_quests           # Docker/main project focus
```

### Import Patterns
```python
# Use absolute imports for config and shared modules
from config.env_loader import load_evaluator_env
from database.manager import DatabaseManager

# Relative imports within same package
from .models import EvaluationResult
```

### Error Handling & Logging
- Emoji-based status: `📋`, `✅`, `🧹`, `⚠️`, `❌` 
- Partial result capture: Continue pipeline with error flags
- Context logging: Include agent_id, file_path in error messages

### Async/Await Patterns
- Use async for AI agent calls and database operations
- Connection pooling with `asyncpg` for SQL execution
- Session management with SQLAlchemy for persistence

### Type Hints & Pydantic Patterns
```python
# Use Annotated for Pydantic field constraints
score: Annotated[int, Field(ge=1, le=10)]
confidence: Annotated[float, Field(ge=0, le=1)]

# Modern Pydantic configuration (v2+ style)
class MyModel(BaseModel):
    model_config = ConfigDict(
        arbitrary_types_allowed=True,
        str_strip_whitespace=True
    )
    # NOT: class Config: ... (deprecated)
```

## Key Architectural Decisions

### Why Database Separation?
- **Metadata Isolation**: Evaluation results separate from execution environment
- **Clean Execution**: Each SQL file starts with fresh sandbox
- **Security**: Prevent SQL exercises from affecting evaluation data
- **Performance**: No schema overhead in execution sandbox

### Why Singleton Environment Loading?
- Prevent triple loading: `run_evaluation.py` → `config.py` → `init_database.py`
- Smart path resolution: Works from project root or evaluator directory

## Key Files for Reference
- Pipeline: `scripts/evaluator/core/evaluators.py`
- Database Separation: `scripts/evaluator/database/manager.py`
- Schema: `scripts/evaluator/database/tables.py`
- Environment: `scripts/evaluator/config/env_loader.py`
- Agent Architecture: `scripts/evaluator/core/agents.py`
