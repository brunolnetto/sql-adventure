# 🧭 SQL Adventure

This directory contains comprehensive documentation for the SQL Adventure project.

## 📖 Table of Contents

- [Project Overview](./README.md) - Main project README
- [Learning Path](./docs/learning-path.md) - Complete learning guide with prerequisites and use cases
- [Cheatsheets](./docs/cheatsheets) - Cheatsheets for available quests
- [Run Examples](./docs/run-examples.md) - How to run examples with troubleshooting
- [Output Validation](./docs/output-validation.md) - Validate SQL script outputs against expected results

## 🎯 What You'll Learn

- **Data Modeling** - Understand database design and relationships
- **Performance Tuning** - Write efficient, scalable queries
- **Window Functions** - Advanced analytics and ranking operations
- **JSON Operations** - Modern PostgreSQL data handling
- **Recursive CTEs** - Master hierarchical data and complex iterations
- **Real-world Applications** - Solve practical business problems

## 🚀 Quick Start

### For Interviews & Quick Reference
1. **Start with the [Data Modeling Cheatsheet](./docs/cheatsheets/data-modeling.md)** - Database design patterns
2. **Practice with examples** - Run any of the 80 working examples
3. **Master patterns** - Understand database design, optimization, and analytics

### For Deep Learning
1. **Follow the [Learning Path](./docs/learning-path.md)** - Structured progression from Data Modeling to Recursive CTEs
2. **Explore by category** - Choose your focus area (data modeling, performance tuning, analytics, etc.)
3. **Apply to your industry** - See industry use cases in the Learning Path
4. **Run examples** - Use [Run Examples](./docs/run-examples.md) to execute with full output

## 📊 Project Statistics

- **80 Working Examples** - 100% tested and verified
- **5 Major Quests** - Data Modeling (15) + Performance Tuning (15) + Window Functions (18) + JSON Operations (12) + Recursive CTE (20)
- **100% Idempotent** - Safe to run multiple times
- **Docker Ready** - Easy setup and deployment
- **Industry Focused** - Real-world business applications
- **Conceptual Learning** - Logical progression from foundation to advanced patterns

## 🛠️ Technology Stack

### Core Technologies
- **PostgreSQL 15** - Primary database engine
- **pgAdmin 4** - Web-based administration tool
- **Docker & Docker Compose** - Containerization and orchestration

### Development Tools
- **SQL** - Standard SQL with PostgreSQL extensions
- **Bash** - Automation and utility scripts
- **Markdown** - Documentation and guides

### Scripts
- **`scripts/evaluator/task_runner.sh`** - Unified interface for all operations (setup, evaluation, validation)
- **`scripts/evaluator/setup_wizard.py`** - Interactive configuration setup
- **`scripts/commit.sh`** - Simplified git workflow

## 🚀 Quick Start (Updated)

### 1. Setup (One-time)
```bash
# Interactive setup wizard
./scripts/evaluator/task_runner.sh setup

# Start database
./scripts/evaluator/task_runner.sh docker-up

# Initialize database  
./scripts/evaluator/task_runner.sh init-db
```

### 2. Evaluate SQL Files
```bash
# Evaluate entire quest
./scripts/evaluator/task_runner.sh evaluate quests/1-data-modeling

# Evaluate single file
./scripts/evaluator/task_runner.sh evaluate quests/1-data-modeling/01-basic-table.sql

# Basic validation only
./scripts/evaluator/task_runner.sh basic file.sql
```

### 3. Development
```bash
# Run tests
./scripts/evaluator/task_runner.sh test

# Clean cache
./scripts/evaluator/task_runner.sh clean

# View logs
./scripts/evaluator/task_runner.sh logs
```

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### 🐛 Bug Reports
- Use the GitHub issue tracker
- Provide detailed reproduction steps
- Include environment information

### 💡 Feature Requests
- Describe the feature clearly
- Explain the use case
- Suggest implementation approach

### 📝 Documentation
- Improve existing documentation
- Add new examples
- Create tutorials and guides

### 🔧 Code Contributions
- Follow existing code style
- Use `scripts/evaluator/task_runner.sh basic` for SQL validation
- Use `scripts/commit.sh` for git workflow
- Update documentation

## 📞 Support

- **GitHub Issues** - For bugs and feature requests
- **Documentation** - Check the quest-specific README files
- **Community** - Join our discussions and share your experiences

## 🙏 Acknowledgments

- **PostgreSQL Community** - For the excellent database engine
- **Docker Team** - For containerization technology
- **SQL Community** - For sharing knowledge and best practices
