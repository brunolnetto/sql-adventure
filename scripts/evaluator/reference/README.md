# Reference: Advanced Evaluator Assets

This folder contains advanced, over-engineered, or legacy files from the SQL Adventure AI Evaluator. They are preserved for their embedded value and as a resource for future refactoring or feature expansion.

## File Summaries & Value

### ai_evaluator.py
- **What:** Pydantic-AI agent-based evaluator with structured models and advanced educational/technical analysis.
- **Value:**
  - Pydantic models for type-safe, extensible results
  - Agent orchestration for LLM prompts
  - Educational/technical split and recommendations logic
- **Extraction Points:**
  - Pydantic models and agent logic can be ported to the main evaluator for richer output.

### config.py
- **What:** Dataclass-based configuration management with validation, logging, and environment integration.
- **Value:**
  - Robust config pattern for maintainability
  - Validation and sample config generation
- **Extraction Points:**
  - Dataclass config pattern for future refactoring

### migration.py
- **What:** Migration, backup, and analytics view creation for legacy data.
- **Value:**
  - Automated migration/backup logic
  - Analytics view creation
- **Extraction Points:**
  - Analytics view creation logic (if not already in analytics_views.py)

### validation.py
- **What:** Full validation framework for SQL files and evaluation data, with scoring and QA.
- **Value:**
  - Validation dataclasses and scoring logic
  - Database integrity checks
- **Extraction Points:**
  - Validation dataclasses and QA logic for future quality assurance modules

### database.py
- **What:** Older database manager, now superseded by enhanced_database.py.
- **Value:**
  - Async SQL execution patterns
- **Extraction Points:**
  - Reference for async execution, if needed for performance

---

**Note:**
- All files here are for reference only and are not imported by the current pipeline.
- Any future integration should ensure compatibility with the normalized schema in `models.py` and the current evaluator logic.