# SQL Adventure 🚀

A comprehensive collection of SQL learning resources, examples, and interactive quests designed to help developers master SQL from basics to advanced concepts.

## 📚 Overview

SQL Adventure is your journey through the world of SQL, featuring practical examples, real-world scenarios, and hands-on learning experiences. Whether you're a beginner or an experienced developer, you'll find valuable resources to enhance your SQL skills.

## 🎯 What You'll Learn

- **Recursive CTEs** - Master hierarchical data and iterative operations
- **Advanced SQL Patterns** - Learn complex query techniques
- **Performance Optimization** - Write efficient, scalable queries
- **Real-world Applications** - Solve practical business problems
- **Database Design** - Understand data modeling and relationships

## 🗂️ Project Structure

```
sql-adventure/
├── README.md                    # This file
├── docker-compose.yml           # PostgreSQL + pgAdmin setup
├── docker-compose.override.yml  # Development overrides
├── env.example                  # Environment configuration
├── scripts/                     # Utility scripts
│   ├── init-db.sh              # Database initialization
│   ├── run-examples.sh         # Example runner script
│   ├── postgresql.conf         # PostgreSQL configuration
│   └── pgadmin-servers.json    # pgAdmin server config
├── quests/                      # Interactive learning quests
│   ├── README.md               # Quests overview
│   └── recursive-cte/          # Recursive CTE examples
│       ├── README.md           # Comprehensive documentation
│       ├── run-all-examples.sql # Master script to run all examples
│       └── [8 category folders] # 31 SQL examples organized by type
│           ├── 01-hierarchical-graph-traversal/  # 7 examples
│           ├── 02-iteration-loops/               # 7 examples
│           ├── 03-path-finding-analysis/         # 3 examples
│           ├── 04-data-transformation-parsing/   # 3 examples
│           ├── 05-simulation-state-machines/     # 2 examples
│           ├── 06-data-repair-healing/           # 3 examples
│           ├── 07-mathematical-theoretical/      # 3 examples
│           └── 08-bonus-quirky-examples/         # 3 examples
└── [Future directories]        # Planned for expansion
    ├── docs/                   # Documentation (future)
    ├── examples/               # Standalone examples (future)
    ├── challenges/             # SQL challenges (future)
    └── tools/                  # SQL utilities (future)
```

## 🚀 Quick Start

### Prerequisites
- **Docker & Docker Compose** - For containerized environments
- **Git** - To clone and manage the repository
- **Basic SQL knowledge** - Helpful but not required

### Getting Started

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd sql-adventure
   ```

2. **Configure environment (optional)**
   ```bash
   # Copy the example environment file
   cp env.example .env
   
   # Edit .env if you want to customize settings
   nano .env
   ```

3. **Launch the environment**
   ```bash
   # Start PostgreSQL and pgAdmin
   docker-compose up -d
   
   # Access the learning environment
   # pgAdmin: http://localhost:8080
   # PostgreSQL: localhost:5432
   ```

4. **Choose your adventure**
   ```bash
   # Explore available quests
   ls quests/
   
   # Start with Recursive CTEs
   cd quests/recursive-cte
   ```

## 🎮 Available Quests

### 🚀 [Recursive CTE Mastery](./quests/recursive-cte/)

**Status:** ✅ Complete

Master the art of Recursive Common Table Expressions with **31 practical examples** across 8 categories:

- **Hierarchical & Graph Traversal** - Organization charts, BOM, category trees
- **Iteration & Loop Emulation** - Number series, Fibonacci, date sequences  
- **Path-Finding & Analysis** - Shortest path, topological sort, cycle detection
- **Data Transformation & Parsing** - String splitting, transitive closure, JSON parsing
- **Simulation & State Machines** - Inventory simulation, game simulation
- **Data Repair & Self-Healing** - Sequence gaps, forward fill, interval coalescing
- **Mathematical & Theoretical** - Fibonacci, prime numbers, permutations
- **Bonus Quirky Examples** - Work streaks, password generation, spiral matrices

**Features:**
- 🐳 **Docker-ready** environment
- 🔄 **Idempotent examples** (safe to run multiple times)
- 📊 **Real-world scenarios** from various industries
- 🎯 **Complete coverage** of recursive CTE use cases

**Quick Start:**
```bash
# From the root directory
docker-compose up -d

# Then explore the quests
cd quests/recursive-cte
```

---

### 🔮 Coming Soon

- **Window Functions Deep Dive** - Advanced analytics and ranking
- **JSON & JSONB Operations** - Modern PostgreSQL features
- **Performance Tuning Quest** - Query optimization techniques
- **Data Modeling Challenges** - Database design patterns
- **ETL Pipeline Examples** - Data transformation workflows

## 🛠️ Technology Stack

### Core Technologies
- **PostgreSQL 15** - Primary database engine
- **pgAdmin 4** - Web-based administration tool
- **Docker & Docker Compose** - Containerization and orchestration

### Development Tools
- **SQL** - Standard SQL with PostgreSQL extensions
- **Bash** - Automation and utility scripts
- **Markdown** - Documentation and guides

## 📖 Learning Path

### 🥇 Beginner Level
1. **Basic SQL Concepts** - SELECT, INSERT, UPDATE, DELETE
2. **Joins and Relationships** - INNER, LEFT, RIGHT, FULL JOINs
3. **Aggregation Functions** - GROUP BY, HAVING, window functions

### 🥈 Intermediate Level
1. **Recursive CTEs** - Hierarchical data and iterative operations
2. **Advanced Joins** - Self-joins, cross joins, lateral joins
3. **Subqueries** - Correlated and non-correlated subqueries

### 🥉 Advanced Level
1. **Performance Optimization** - Indexing, query planning, optimization
2. **Advanced Patterns** - Pivot tables, running totals, gaps analysis
3. **Database Design** - Normalization, denormalization, data modeling

## 🎯 Use Cases by Industry

### 💼 Business & Finance
- Organization chart analysis
- Cost rollup calculations
- Financial reporting and analytics
- Workflow automation

### 🏥 Healthcare
- Family tree analysis
- Disease spread modeling
- Treatment pathway analysis
- Medical hierarchy management

### 🛒 E-commerce
- Category navigation
- Product recommendations
- Inventory forecasting
- Customer relationship chains

### 🏭 Manufacturing
- Bill of Materials (BOM)
- Supply chain optimization
- Quality control tracking
- Production scheduling

### 💻 Technology
- Dependency resolution
- Graph algorithms
- Data pipeline processing
- Configuration management

## 🔧 Development Setup

### Local Development
```bash
# Clone the repository
git clone <repository-url>
cd sql-adventure

# Configure environment (optional)
cp env.example .env

# Start development environment
docker-compose up -d

# Explore quests
cd quests/recursive-cte
```

### Contributing
1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Make your changes**
4. **Test thoroughly**
5. **Submit a pull request**

## 📊 Project Statistics

- **31 SQL Examples** - Comprehensive recursive CTE coverage
- **8 Categories** - Diverse use cases and scenarios
- **100% Idempotent** - Safe to run multiple times
- **Docker Ready** - Easy setup and deployment
- **Industry Focused** - Real-world business applications

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
- Add tests for new features
- Update documentation

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **PostgreSQL Community** - For the excellent database engine
- **Docker Team** - For containerization technology
- **SQL Community** - For sharing knowledge and best practices

## 📞 Support

- **GitHub Issues** - For bugs and feature requests
- **Documentation** - Check the quest-specific README files
- **Community** - Join our discussions and share your experiences

## 🔮 Roadmap

### Phase 1: Foundation ✅
- [x] Recursive CTE examples
- [x] Docker environment setup
- [x] Comprehensive documentation

### Phase 2: Expansion 🚧
- [ ] Window functions quest
- [ ] JSON operations examples
- [ ] Performance tuning guide
- [ ] Data modeling challenges

### Phase 3: Advanced Features 📋
- [ ] Interactive SQL playground
- [ ] Automated testing framework
- [ ] Performance benchmarking
- [ ] Community challenges

### Phase 4: Ecosystem 📋
- [ ] SQL learning platform
- [ ] Certification program
- [ ] Community features
- [ ] Enterprise solutions

---

**Ready to start your SQL Adventure? Choose a quest and begin your journey! 🚀**

*"The best way to learn SQL is to write SQL."* 