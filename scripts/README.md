# 🚀 SQL Adventure Scripts

This directory contains the **unified evaluation system** for SQL Adventure, combining shell script wrappers with a powerful Python backend.

## 📁 **Directory Structure**

```
scripts/
├── 📄 README.md                    # This file
├── 📄 print-utils.sh               # Shell utility functions
├── 📄 validate.sh                  # Main validation script (Python backend)
├── 📄 run-examples.sh              # Examples runner (Python backend)
├── 📄 commit.sh                    # Git workflow helper
├── 📄 evaluate.py                  # Python CLI wrapper
├── 📄 test_migration.py            # Migration validation tests
├── 📄 init-db.sh                   # Database initialization
├── 📄 postgresql.conf              # PostgreSQL configuration
├── 📄 pgadmin-servers.json         # PgAdmin configuration
├── 📂 evaluator/                   # Python evaluation system
│   ├── 📄 main.py                  # Main CLI entry point
│   ├── 📄 batch_evaluate.py        # Batch evaluation system
│   ├── 📂 core/                    # Core evaluation components
│   │   ├── 📄 ai_evaluator.py      # AI-powered evaluation
│   │   ├── 📄 database_manager.py  # Unified database manager
│   │   ├── 📄 validation.py        # SQL validation system
│   │   ├── 📄 config.py            # Configuration management
│   │   ├── 📄 models.py            # Data models
│   │   └── 📄 quest_discovery.py   # Dynamic quest discovery
│   ├── 📂 utils/                   # Utility components
│   │   ├── 📄 migration.py         # Database migration tools
│   │   └── 📄 analytics_views.py   # Analytics and reporting
│   ├── 📂 tests/                   # Test suite
│   └── 📂 docs/                    # Documentation
└── 📄 MIGRATION_*.md               # Migration documentation
```

## 🎯 **Architecture Overview**

### **Hybrid Approach: Shell + Python**
- **Shell Scripts**: User-friendly wrappers with backward compatibility
- **Python Backend**: Powerful evaluation engine with AI capabilities
- **Unified Interface**: Consistent experience across all entry points

### **Key Components**

#### **1. Shell Script Wrappers**
- `validate.sh` - Main validation and evaluation
- `run-examples.sh` - SQL execution and testing
- `commit.sh` - Git workflow automation
- `print-utils.sh` - Consistent formatting utilities

#### **2. Python Evaluation System**
- **AI-Powered Analysis**: GPT-4 integration for intelligent evaluation
- **Dynamic Quest Discovery**: Automatic quest metadata extraction
- **Flexible Database**: JSON-based models for extensibility
- **Batch Processing**: Efficient evaluation of multiple files

#### **3. Unified Database Manager**
- **Single Source of Truth**: One database manager for all operations
- **Dynamic Initialization**: Automatic setup and configuration
- **Health Monitoring**: Built-in diagnostics and validation

## 🚀 **Quick Start**

### **1. Basic Validation**
```bash
# Validate a single SQL file
./scripts/validate.sh validate quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql

# Validate an entire quest
./scripts/validate.sh validate quests/1-data-modeling
```

### **2. AI Evaluation**
```bash
# Run AI evaluation on a quest
./scripts/validate.sh evaluate quests/1-data-modeling

# Run with custom options
./scripts/validate.sh evaluate quests/1-data-modeling --batch-size 5 --verbose
```

### **3. SQL Execution**
```bash
# Execute SQL examples
./scripts/run-examples.sh examples quests/1-data-modeling

# Execute with validation
./scripts/run-examples.sh examples quests/1-data-modeling --validate
```

### **4. Python Direct Usage**
```bash
# Use Python CLI directly
python scripts/evaluate.py validate quests/1-data-modeling
python scripts/evaluate.py evaluate quests/1-data-modeling --ai
```

## 🔧 **Configuration**

### **Environment Variables**
```bash
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=sql_adventure_db

# AI Configuration
OPENAI_API_KEY=your_api_key_here
EVALUATOR_MODEL=gpt-4o-mini

# Evaluation Settings
MAX_PARALLEL_EVAL=3
EXECUTION_TIMEOUT=30
ENABLE_AI_ANALYSIS=true
```

### **Configuration File**
Create `evaluator_config.json` for persistent settings:
```json
{
  "database": {
    "host": "localhost",
    "port": 5432,
    "user": "postgres",
    "password": "postgres",
    "database": "sql_adventure_evaluator"
  },
  "ai": {
    "model": "gpt-4o-mini",
    "temperature": 0.2,
    "timeout": 60
  },
  "evaluation": {
    "max_parallel_evaluations": 3,
    "execution_timeout": 30,
    "enable_ai_analysis": true
  }
}
```

## 📊 **Available Modes**

### **Validation Modes**
- `validate` - SQL syntax and semantic validation
- `evaluate` - AI-powered comprehensive evaluation
- `examples` - Execute SQL examples
- `report` - Generate evaluation reports
- `consistency` - Check file consistency
- `performance` - Performance optimization tests

### **Report Formats**
- `json` - Machine-readable JSON output
- `html` - Interactive HTML reports
- `markdown` - Documentation-friendly markdown

## 🎯 **Best Practices**

### **1. Shell Script Usage**
- Use shell scripts for quick, interactive operations
- Leverage backward compatibility for existing workflows
- Take advantage of built-in error handling and formatting

### **2. Python Direct Usage**
- Use Python CLI for advanced features and automation
- Leverage batch processing for large-scale evaluation
- Customize configuration for specific needs

### **3. Database Management**
- Let the system auto-initialize the database
- Use health checks to verify system status
- Monitor evaluation history and analytics

### **4. AI Evaluation**
- Set up proper API keys for AI features
- Use appropriate batch sizes for your use case
- Review AI recommendations for learning insights

## 🔍 **Troubleshooting**

### **Common Issues**

#### **1. Missing Dependencies**
```bash
# Install Python dependencies
pip install -r scripts/evaluator/requirements.txt

# Check shell script permissions
chmod +x scripts/*.sh
```

#### **2. Database Connection Issues**
```bash
# Test database connection
./scripts/run-examples.sh test-connection

# Initialize database
./scripts/init-db.sh
```

#### **3. AI Evaluation Issues**
```bash
# Check API key
echo $OPENAI_API_KEY

# Test AI connection
python scripts/evaluate.py evaluate test.sql --verbose
```

### **Debug Mode**
```bash
# Enable debug logging
export DEBUG_MODE=true
export LOG_LEVEL=DEBUG

# Run with verbose output
./scripts/validate.sh validate quests/1-data-modeling --verbose
```

## 📈 **Performance**

### **Optimization Tips**
- Use batch processing for multiple files
- Adjust parallel evaluation limits based on system resources
- Enable caching for repeated evaluations
- Use appropriate AI models for your use case

### **Benchmarks**
- **Single File**: ~2-5 seconds
- **Quest (15 files)**: ~30-60 seconds
- **Full System (80 files)**: ~2-3 minutes

## 🔮 **Future Enhancements**

### **Planned Features**
- **Real-time AI Feedback**: Live evaluation during development
- **Advanced Analytics**: Machine learning insights
- **Cloud Integration**: Containerized deployment
- **API Endpoints**: REST API for external tools

### **Extensibility**
- **Custom Validators**: Plugin system for custom rules
- **AI Model Support**: Multiple AI provider integration
- **Database Backends**: Support for other databases
- **Reporting**: Custom report templates

## 📚 **Documentation**

### **Detailed Guides**
- [Migration Guide](MIGRATION_SUMMARY.md) - Complete migration documentation
- [Database Consolidation](evaluator/DATABASE_CONSOLIDATION.md) - Database architecture
- [Improvements](evaluator/IMPROVEMENTS.md) - System enhancements
- [Structure](evaluator/STRUCTURE.md) - Code organization

### **API Reference**
- [Python CLI](evaluator/main.py) - Main CLI interface
- [Database Manager](evaluator/core/database_manager.py) - Database operations
- [AI Evaluator](evaluator/core/ai_evaluator.py) - AI evaluation system
- [Validation](evaluator/core/validation.py) - SQL validation

## 🤝 **Contributing**

### **Development Setup**
```bash
# Clone and setup
git clone <repository>
cd sql-adventure/scripts

# Install dependencies
pip install -r evaluator/requirements.txt

# Run tests
python test_migration.py
```

### **Code Standards**
- Follow PEP 8 for Python code
- Use consistent shell script formatting
- Maintain backward compatibility
- Add comprehensive tests

---

**🎉 The SQL Adventure evaluation system provides a modern, powerful, and maintainable solution for SQL learning and assessment!** 