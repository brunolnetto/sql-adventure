# SQL Adventure AI Evaluator

A clean, organized Python-based evaluation system for SQL Adventure.

## 📁 Structure

```
evaluator/
├── main.py              # Main CLI entry point
├── requirements.txt     # Python dependencies
├── core/               # Core evaluation components
│   ├── ai_evaluator.py    # AI-powered evaluation
│   ├── validation.py      # SQL validation system
│   ├── config.py          # Configuration management
│   ├── enhanced_database.py # Database integration
│   └── models.py          # Data models
├── utils/              # Utility components
│   ├── migration.py       # Database migration tools
│   ├── analytics_views.py # Analytics and reporting
│   └── database.py        # Basic database operations
├── tests/              # Test suite
│   ├── test_evaluation.py
│   └── test_evaluator.py
└── docs/               # Documentation
    ├── README.md
    └── MIGRATION.md
```

## 🚀 Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Set environment variables
export OPENAI_API_KEY="your-key"
export DB_HOST="localhost"
export DB_USER="postgres"
export DB_PASSWORD="postgres"

# Run evaluation
python main.py evaluate quests/1-data-modeling
```

## 📋 Usage

```bash
# Validate SQL files
python main.py validate quests/1-data-modeling

# Run AI evaluation
python main.py evaluate quests/1-data-modeling

# Execute examples
python main.py examples quests/1-data-modeling

# Generate reports
python main.py report json quests/1-data-modeling
```

## 🔧 Configuration

The system uses environment variables for configuration:

```bash
# Required
OPENAI_API_KEY=your-openai-api-key
DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=postgres

# Optional
EVALUATOR_DB_NAME=sql_adventure_evaluator
EVALUATOR_MODEL=gpt-4o-mini
MAX_PARALLEL_EVAL=3
```

## 📊 Features

- **AI-Powered Analysis**: Comprehensive SQL evaluation using GPT-4o-mini
- **Advanced Validation**: SQL syntax and semantic validation
- **Database Integration**: Normalized schema with analytics
- **Parallel Processing**: Async execution for better performance
- **Rich Reporting**: Multiple output formats (JSON, HTML, Markdown)

## 🧪 Testing

```bash
# Run test suite
python3 ../test_migration.py

# Run individual tests
python -m pytest tests/
```

## 📚 Documentation

- **Migration Guide**: `docs/MIGRATION.md`
- **API Documentation**: `docs/README.md`
- **Quick Reference**: `../QUICK_REFERENCE.md` 