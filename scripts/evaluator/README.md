# SQL Adventure AI Evaluator - Enhanced Version 2.0

A comprehensive, production-ready AI evaluation system for the SQL Adventure project, featuring normalized database design, advanced analytics, and robust validation.

## 🚀 Overview

The Enhanced AI Evaluator migrates from the original shell script approach to a modern Python-based system with:

- **Normalized Database Schema** - Proper relationships and data integrity
- **Advanced Analytics** - Comprehensive reporting and insights
- **Robust Validation** - SQL syntax checking and data validation
- **Configuration Management** - Flexible, environment-aware configuration
- **Migration Tools** - Seamless transition from legacy systems

## 📊 Architecture

### Database Design
```
├── quests/                     # Quest metadata
├── subcategories/              # Quest subcategories  
├── sql_files/                  # SQL file registry
├── sql_patterns/               # Pattern definitions
├── evaluations/                # Main evaluation results
├── technical_analyses/         # Technical evaluation details
├── educational_analyses/       # Educational assessment details
├── execution_details/          # Statement-level execution info
├── evaluation_patterns/        # Pattern usage in evaluations
├── recommendations/            # AI-generated recommendations
└── evaluation_sessions/        # Batch processing sessions
```

### Key Features

#### 🎯 Normalized Data Model
- **Proper Relationships** - Foreign keys and referential integrity
- **Pattern Management** - Reusable SQL pattern definitions
- **Hierarchical Structure** - Quest → Subcategory → SQL File
- **Audit Trail** - Complete evaluation history with UUIDs

#### 📈 Advanced Analytics
- **Real-time Dashboards** - Performance metrics and trends
- **Pattern Analysis** - Usage patterns and effectiveness
- **Quality Metrics** - Score distributions and consistency
- **Progress Tracking** - File-level evaluation history

#### ✅ Comprehensive Validation
- **SQL Syntax Validation** - Parse and validate SQL code
- **Data Integrity Checks** - Ensure consistent evaluation data
- **Quality Assurance** - System-wide quality monitoring
- **Performance Analysis** - Identify optimization opportunities

## 🛠️ Installation

### Prerequisites
- Python 3.8+
- PostgreSQL 12+
- OpenAI API key

### Quick Setup

1. **Install Dependencies**
```bash
cd scripts/evaluator
pip install -r requirements.txt
```

2. **Set Environment Variables**
```bash
export OPENAI_API_KEY="your-openai-api-key"
export DB_HOST="localhost"
export DB_USER="postgres"
export DB_PASSWORD="your-password"
export EVALUATOR_DB_NAME="sql_adventure_evaluator"
```

3. **Initialize Configuration**
```bash
python -m migration --action config
```

4. **Run Migration**
```bash
python -m migration --action migrate --verbose
```

## 📋 Configuration

### Configuration File Structure
```json
{
  "config_version": "2.0",
  "environment": "production",
  "database": {
    "host": "localhost",
    "port": 5432,
    "user": "postgres",
    "database": "sql_adventure_evaluator",
    "use_separate_db": true,
    "pool_size": 10
  },
  "ai": {
    "model": "gpt-4o-mini",
    "temperature": 0.2,
    "timeout": 60,
    "max_retries": 3,
    "confidence_threshold": 0.7
  },
  "evaluation": {
    "max_parallel_evaluations": 3,
    "execution_timeout": 30,
    "enable_execution": true,
    "enable_ai_analysis": true,
    "save_to_database": true
  },
  "logging": {
    "level": "INFO",
    "log_to_file": true,
    "log_file": "evaluator.log"
  }
}
```

### Environment Variables
- `OPENAI_API_KEY` - OpenAI API key (required)
- `DB_HOST` - Database host (default: localhost)
- `DB_PORT` - Database port (default: 5432)
- `DB_USER` - Database user (default: postgres)
- `DB_PASSWORD` - Database password
- `EVALUATOR_DB_NAME` - Evaluator database name
- `LOG_LEVEL` - Logging level (DEBUG, INFO, WARNING, ERROR)

## 🔄 Migration Guide

### From Shell Script Evaluator

1. **Create Backup**
```bash
python -m migration --action backup --backup-path ./migration_backup
```

2. **Validate Environment**
```bash
python -m migration --action validate
```

3. **Run Complete Migration**
```bash
python -m migration --action migrate --json-path ./ai-evaluations --verbose
```

4. **Verify Migration**
- Check migration report in `migration_backup/migration_report.md`
- Review validation results
- Test new system with sample evaluations

### Migration Features
- **Automatic Backup** - Creates backup before migration
- **Data Validation** - Validates data during migration
- **Progress Tracking** - Real-time migration progress
- **Error Recovery** - Continues migration despite individual failures
- **Comprehensive Reporting** - Detailed migration summary

## 💻 Usage

### Basic Usage

```python
from scripts.evaluator.ai_evaluator import SQLEvaluator
from scripts.evaluator.enhanced_database import EnhancedDatabaseManager

# Initialize evaluator
evaluator = SQLEvaluator(api_key="your-openai-key")

# Evaluate a single file
result = await evaluator.evaluate_sql_file("quests/1-data-modeling/example.sql")

# Get analytics
analytics = evaluator.db_manager.get_evaluation_analytics()
```

### Advanced Usage

```python
from scripts.evaluator.config import get_config
from scripts.evaluator.validation import ValidationCoordinator
from scripts.evaluator.analytics_views import AnalyticsViewManager

# Load configuration
config = get_config()

# Setup database with analytics
db_manager = EnhancedDatabaseManager()
analytics = AnalyticsViewManager(db_manager)
analytics.create_analytics_views()

# Comprehensive validation
validator = ValidationCoordinator(db_manager)
results = validator.validate_complete_system()
```

### CLI Usage

```bash
# Run complete evaluation
python -m ai_evaluator

# Validate specific file
python -m validation --file quests/1-data-modeling/example.sql

# Generate analytics report
python -m analytics_views --quest 1-data-modeling --days 30

# System health check
python -m migration --action validate
```

## 📊 Analytics & Reporting

### Available Views
- `evaluation_summary` - Complete evaluation overview
- `quest_performance` - Quest-level performance metrics
- `pattern_analysis` - SQL pattern usage analysis
- `file_progress` - File-level progress tracking
- `recommendations_dashboard` - Prioritized recommendations

### Analytics Functions
- `get_quest_statistics()` - Quest performance summary
- `get_pattern_usage_trends()` - Pattern usage over time
- `get_improvement_opportunities()` - Files needing attention

### Dashboard Data
```python
from scripts.evaluator.analytics_views import AnalyticsViewManager

analytics = AnalyticsViewManager(db_manager)
dashboard_data = analytics.get_dashboard_data()

# Access metrics
print(f"Total evaluations: {dashboard_data['summary']['total_evaluations']}")
print(f"Success rate: {dashboard_data['summary']['overall_success_rate']}%")
```

## 🔍 Validation Features

### SQL Validation
- **Syntax Checking** - Parse and validate SQL syntax
- **Semantic Analysis** - Check for logical issues
- **Security Scanning** - Detect dangerous patterns
- **Style Checking** - Enforce coding standards

### Data Validation
- **Schema Validation** - Ensure data structure integrity
- **Business Logic** - Validate scoring consistency
- **Referential Integrity** - Check database relationships
- **Quality Assurance** - System-wide quality metrics

### Example Validation
```python
from scripts.evaluator.validation import ValidationCoordinator

validator = ValidationCoordinator(db_manager)

# Validate SQL file
sql_result = validator.validate_sql_file("example.sql")
print(f"Valid: {sql_result.is_valid}, Score: {sql_result.score}")

# Validate system
system_results = validator.validate_complete_system()
```

## 🏗️ Database Schema

### Core Tables

#### `evaluations` - Main evaluation results
- Primary evaluation data with scores and assessments
- Links to SQL files and quests
- Execution metadata and timing

#### `technical_analyses` - Technical evaluation details
- Syntax, logic, and quality scores
- Performance analysis
- Best practices assessment

#### `educational_analyses` - Educational assessment
- Learning value and difficulty
- Time estimates and prerequisites
- Skill development tracking

#### `execution_details` - Statement-level execution info
- Individual SQL statement results
- Execution times and row counts
- Error and warning details

### Relationship Overview
```sql
quests (1) → (n) subcategories (1) → (n) sql_files (1) → (n) evaluations
sql_patterns (n) ← → (n) sql_files (via sql_file_patterns)
sql_patterns (n) ← → (n) evaluations (via evaluation_patterns)
evaluations (1) → (1) technical_analyses
evaluations (1) → (1) educational_analyses
evaluations (1) → (n) execution_details
evaluations (1) → (n) recommendations
```

## 🎯 Best Practices

### Configuration Management
- Use environment-specific config files
- Keep secrets in environment variables
- Validate configuration before deployment
- Use separate databases for different environments

### Database Operations
- Enable connection pooling for performance
- Use transactions for data consistency
- Implement proper indexing for analytics queries
- Regular backup and maintenance

### Error Handling
- Comprehensive logging at all levels
- Graceful degradation on API failures
- Retry mechanisms for transient errors
- Data validation at all input points

### Performance Optimization
- Batch evaluation processing
- Parallel execution where possible
- Database query optimization
- Caching for repeated operations

## 🔧 Troubleshooting

### Common Issues

#### Migration Fails
```bash
# Check prerequisites
python -m migration --action validate

# Review backup and logs
ls migration_backup/
tail -f evaluator.log
```

#### Database Connection Issues
```bash
# Test connection
python -c "from scripts.evaluator.enhanced_database import EnhancedDatabaseManager; db = EnhancedDatabaseManager(); print('✅ Connected' if db.engine else '❌ Failed')"

# Check configuration
python -c "from scripts.evaluator.config import get_config; print(get_config().database.get_connection_string())"
```

#### API Rate Limits
- Increase `ai.timeout` and `ai.max_retries` in configuration
- Reduce `evaluation.max_parallel_evaluations`
- Monitor usage in logs

### Debug Mode
```bash
export DEBUG_MODE=true
export LOG_LEVEL=DEBUG
python -m ai_evaluator
```

## 📈 Performance Metrics

### Expected Performance
- **SQL File Processing**: ~50-100 files/minute
- **Evaluation Generation**: ~10-20 evaluations/minute (AI-dependent)
- **Database Operations**: ~1000 queries/second
- **Analytics Queries**: ~100ms average response time

### Monitoring
- Monitor database connection pool usage
- Track API response times and rate limits
- Monitor evaluation success rates
- Track data validation scores

## 🤝 Contributing

### Development Setup
```bash
git clone <repository>
cd scripts/evaluator
pip install -r requirements.txt
pip install -e .
```

### Running Tests
```bash
pytest test_evaluator.py -v
pytest test_validation.py -v
```

### Code Quality
```bash
mypy *.py
black *.py
flake8 *.py
```

## 📝 Changelog

### Version 2.0 (Current)
- ✅ Normalized database schema
- ✅ Advanced analytics and reporting
- ✅ Comprehensive validation system
- ✅ Configuration management
- ✅ Migration tools
- ✅ Production-ready architecture

### Version 1.0 (Legacy)
- Basic shell script evaluation
- JSON file output
- Simple database schema
- Limited analytics

## 📄 License

This project is part of the SQL Adventure educational platform. See the main project LICENSE file for details.

## 🙏 Acknowledgments

- PostgreSQL community for excellent database features
- OpenAI for powerful language models
- SQLAlchemy team for robust ORM capabilities
- Pydantic team for data validation framework