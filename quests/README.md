# SQL Adventure Quests 🚀

Master advanced SQL concepts through hands-on examples and real-world scenarios.

## 🎯 What You'll Learn

Each quest focuses on specific SQL features and patterns, providing comprehensive examples from basic concepts to advanced applications. All examples are **idempotent** (safe to run multiple times) and include realistic data scenarios.

<<<<<<< HEAD
A comprehensive collection of **31 practical examples** demonstrating Recursive Common Table Expressions (CTEs) in SQL.
=======
## 📊 Available Quests

### 🪟 [Window Functions](./window-functions/)

Master the power of window functions for advanced data analytics and reporting in SQL.

**Features:**
- 🐳 **Docker-ready** with PostgreSQL and pgAdmin
- 📚 **4 categories** covering all window function use cases
- 🔄 **Idempotent examples** that can be run multiple times safely
- 🎯 **Real-world scenarios** from business analytics to data science

**Quick Start:**
```bash
# From the root directory
docker-compose up -d

# Then explore the window functions quest
cd window-functions
```

**Access:**
- pgAdmin: http://localhost:8080 (admin@sql-adventure.com / admin)
- PostgreSQL: localhost:5433

**Categories:**
1. **Basic Ranking** - ROW_NUMBER(), RANK(), DENSE_RANK(), PERCENT_RANK()
2. **Aggregation Windows** - Running totals, moving averages, cumulative sums
3. **Partitioned Analytics** - Category-based analysis, customer segmentation, performance comparison
4. **Advanced Patterns** - Lead/Lag analysis, gap detection, trend identification

### 🔄 [Recursive CTE Examples](./recursive-cte/)

A comprehensive collection of **29 practical examples** demonstrating Recursive Common Table Expressions (CTEs) in SQL.
>>>>>>> 4e036c9 (feat(quests) improve quest queries)

**Features:**
- 🐳 **Docker-ready** with PostgreSQL and pgAdmin
- 📚 **8 categories** covering all recursive CTE use cases
- 🔄 **Idempotent examples** that can be run multiple times safely
- 🎯 **Real-world scenarios** from hierarchical data to mathematical sequences

**Difficulty Distribution:**
- 🟢 **Beginner (5-10 min):** 8 examples (25.8%)
- 🟡 **Intermediate (10-20 min):** 10 examples (32.3%)
- 🔴 **Advanced (15-30 min):** 9 examples (29.0%)
- ⚫ **Expert (30-45 min):** 4 examples (12.9%)

**Quick Start:**
```bash
# From the root directory
docker-compose up -d

# Then explore the recursive CTE quest
cd recursive-cte
```

**Access:**
- pgAdmin: http://localhost:8080 (admin@sql-adventure.com / admin)
- PostgreSQL: localhost:5433

**Categories:**
1. **Hierarchical & Graph Traversal** - Employee hierarchies, BOM, category trees
2. **Iteration & Loop Emulation** - Number series, Fibonacci, date sequences
3. **Path-Finding & Analysis** - Shortest path, topological sort, cycle detection
4. **Data Transformation & Parsing** - String splitting, transitive closure, JSON parsing
5. **Simulation & State Machines** - Inventory simulation, game simulation
6. **Data Repair & Self-Healing** - Sequence gaps, forward fill, interval coalescing
7. **Mathematical & Theoretical** - Fibonacci, prime numbers, permutations
8. **Bonus Quirky Examples** - Work streaks, password generation, spiral matrices

<<<<<<< HEAD
### 🪟 [Window Functions Examples](./window-functions/)

A comprehensive collection of **94 practical examples** demonstrating Window Functions in SQL.

**Features:**
- 🐳 **Docker-ready** with PostgreSQL and pgAdmin
- 📚 **5 categories** covering all window function use cases
- 🔄 **Idempotent examples** that can be run multiple times safely
- 🎯 **Real-world scenarios** from ranking to advanced analytics

**Difficulty Distribution:**
- 🟢 **Beginner (5-10 min):** 10 examples (10.6%)
- 🟡 **Intermediate (10-20 min):** 46 examples (48.9%)
- 🔴 **Advanced (15-30 min):** 18 examples (19.1%)
- ⚫ **Expert (30-45 min):** 20 examples (21.3%)

**Categories:**
1. **Basic Ranking** - ROW_NUMBER, RANK, DENSE_RANK, PERCENT_RANK (20 examples)
2. **Advanced Ranking** - NTILE, percentile analysis, salary analysis (14 examples)
3. **Aggregation Windows** - Running totals, moving averages, cumulative sums (20 examples)
4. **Partitioned Analytics** - Category-based analysis, customer segmentation (20 examples)
5. **Advanced Patterns** - Lead/Lag analysis, gap detection, trend analysis (20 examples)

## 📊 Quest Difficulty Comparison

### **Overall Statistics:**
| Quest | Total Examples | Categories | Files | Completion |
|-------|---------------|------------|-------|------------|
| **Recursive CTE** | 31 examples | 8 categories | 31 files | ✅ 100% Complete |
| **Window Functions** | 94 examples | 5 categories | 15 files | ✅ 100% Complete |

### **Difficulty by Category:**

| Category | 🟢 | 🟡 | 🔴 | ⚫ | Total |
|----------|----|----|----|----|-------|
| **Recursive CTE** |
| Hierarchical & Graph Traversal | 2 | 3 | 2 | 0 | 7 |
| Iteration & Loop Emulation | 4 | 3 | 0 | 0 | 7 |
| Path-Finding & Analysis | 0 | 0 | 1 | 2 | 3 |
| Data Transformation & Parsing | 1 | 0 | 2 | 0 | 3 |
| Simulation & State Machines | 0 | 0 | 1 | 1 | 2 |
| Data Repair & Self-Healing | 1 | 1 | 1 | 0 | 3 |
| Mathematical & Theoretical | 0 | 1 | 1 | 1 | 3 |
| Bonus Quirky Examples | 0 | 2 | 1 | 0 | 3 |
| **Window Functions** |
| Basic Ranking | 10 | 10 | 0 | 0 | 20 |
| Advanced Ranking | 0 | 8 | 6 | 0 | 14 |
| Aggregation Windows | 0 | 20 | 0 | 0 | 20 |
| Partitioned Analytics | 0 | 8 | 12 | 0 | 20 |
| Advanced Patterns | 0 | 0 | 0 | 20 | 20 |

### **Time Estimates:**
- 🟢 **Beginner**: 5-10 min
- 🟡 **Intermediate**: 10-20 min  
- 🔴 **Advanced**: 15-30 min
- ⚫ **Expert**: 30-45 min
=======
## 🎮 Getting Started

### **Prerequisites**
- Docker and Docker Compose installed
- Basic SQL knowledge (SELECT, FROM, WHERE, ORDER BY)
- Understanding of GROUP BY and aggregate functions

### **1. Start the Environment**
```bash
# Clone the repository
git clone <repository-url>
cd sql-adventure

# Start PostgreSQL and pgAdmin
docker-compose up -d

# Check if services are running
docker-compose ps
```

### **2. Access the Services**
- **pgAdmin**: http://localhost:8080
  - Email: `admin@sql-adventure.com`
  - Password: `admin`
- **PostgreSQL**: `localhost:5433`
  - Database: `sql_adventure_db`
  - Username: `postgres`
  - Password: `postgres`

### **3. Run Examples**
```bash
# Run all examples for a specific quest
./scripts/run-examples.sh quest window-functions
./scripts/run-examples.sh quest recursive-cte

# Run specific categories
./scripts/run-examples.sh quest window-functions basic-ranking
./scripts/run-examples.sh quest recursive-cte hierarchical-graph-traversal
```

## 📊 Difficulty Level Evaluation

### **Difficulty Scale:**
- 🟢 **Beginner** - Basic concepts and simple patterns (5-15 min)
- 🟡 **Intermediate** - Moderate complexity and multiple concepts (10-25 min)
- 🔴 **Advanced** - Complex algorithms and edge cases (15-45 min)
- ⚫ **Expert** - Theoretical concepts and optimization challenges (30-60 min)

### **📈 Difficulty Distribution by Examples:**

#### **Window Functions Quest:**
- 🟢 **Beginner**: 16 examples (**18.2%**) - Perfect starting point for new learners
- 🟡 **Intermediate**: 20 examples (**22.7%**) - Building complexity and real-world applications
- 🔴 **Advanced**: 26 examples (**29.5%**) - Complex patterns and performance considerations
- ⚫ **Expert**: 22 examples (**25.0%**) - Cutting-edge techniques and optimization

#### **Recursive CTE Quest:**
- 🟢 **Beginner**: 7 examples (**24.1%**) - Foundation concepts and educational patterns
- 🟡 **Intermediate**: 9 examples (**31.0%**) - Building complexity with legitimate use cases
- 🔴 **Advanced**: 9 examples (**31.0%**) - Complex algorithms and real-world applications
- ⚫ **Expert**: 4 examples (**13.8%**) - Advanced theoretical concepts and optimization

### **🎯 Difficulty Percentage Guide:**
- **10-25%**: Perfect for beginners - focus on understanding basic concepts
- **30-60%**: Ideal for intermediate learners - build confidence with real applications
- **65-85%**: Advanced learners - tackle complex patterns and optimization
- **90-100%**: Expert level - master cutting-edge techniques and performance tuning

**📚 Progression Strategy**: Aim to complete examples within 10-15% of your current comfort level for optimal learning progression.

## 🏢 Real-World Applications

### **Business Analytics**
- **Sales ranking** - Top performers by region/category
- **Customer segmentation** - RFM analysis and scoring
- **Performance tracking** - Employee/product rankings
- **Financial reporting** - Running totals and trends

### **Data Science**
- **Time series analysis** - Moving averages and trends
- **Statistical analysis** - Percentiles and distributions
- **Anomaly detection** - Outlier identification
- **Predictive modeling** - Feature engineering

### **Reporting & BI**
- **Executive dashboards** - KPI tracking and rankings
- **Operational reports** - Daily/weekly/monthly summaries
- **Comparative analysis** - Period-over-period comparisons
- **Trend analysis** - Growth and decline patterns

## 🤝 Contributing

We welcome contributions to expand the SQL Adventure quests! Please ensure:

- **Examples are idempotent** (safe to run multiple times)
- **Include clear comments** explaining the concepts
- **Use realistic data** that demonstrates real-world scenarios
- **Follow the difficulty rating system**
- **Test thoroughly** before submitting
- **Keep files focused** with 3-4 examples per file
- **Maintain clear learning progression** between files

## 📚 Further Reading

- [PostgreSQL Documentation](https://www.postgresql.org/docs/current/)
- [SQL Server Documentation](https://docs.microsoft.com/en-us/sql/sql-server/)
- [Oracle Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/)
>>>>>>> 4e036c9 (feat(quests) improve quest queries)

---

*Ready to master SQL? Start with the [Window Functions quest](./window-functions/) or [Recursive CTE Examples](./recursive-cte/)! 🚀* 