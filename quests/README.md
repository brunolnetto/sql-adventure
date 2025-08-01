# SQL Adventure Quests 🚀

Master advanced SQL concepts through hands-on examples and real-world scenarios.

## 🎯 What You'll Learn

Each quest focuses on specific SQL features and patterns, providing comprehensive examples from basic concepts to advanced applications. All examples are **idempotent** (safe to run multiple times) and include realistic data scenarios.

### 🔄 [Recursive CTE Examples](./recursive-cte/)

A comprehensive collection of **31 practical examples** demonstrating Recursive Common Table Expressions (CTEs) in SQL.

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

### 🪟 [Window Functions Examples](./window-functions/)

A comprehensive collection of **112 practical examples** demonstrating Window Functions in SQL.

**Features:**
- 🐳 **Docker-ready** with PostgreSQL and pgAdmin
- 📚 **5 categories** covering all window function use cases
- 🔄 **Idempotent examples** that can be run multiple times safely
- 🎯 **Real-world scenarios** from ranking to advanced analytics

**Difficulty Distribution:**
- 🟢 **Beginner (5-10 min):** 2 examples (1.8%)
- 🟡 **Intermediate (10-20 min):** 10 examples (8.9%)
- 🔴 **Advanced (15-30 min):** 8 examples (7.1%)
- ⚫ **Expert (30-45 min):** 3 examples (2.7%)

**Categories:**
1. **Basic Ranking** - ROW_NUMBER, RANK, DENSE_RANK (6 examples)
2. **Advanced Ranking** - NTILE, percentile analysis, salary analysis (14 examples)
3. **Aggregation Windows** - Running totals, moving averages, cumulative sums (20 examples)
4. **Partitioned Analytics** - Category-based analysis, customer segmentation (26 examples)
5. **Advanced Patterns** - Lead/Lag analysis, gap detection, trend analysis (22 examples)

### 🎯 [JSON Operations Examples](./json-operations/)

A comprehensive collection of **12 practical examples** demonstrating JSON operations in PostgreSQL.

### ⚡ [Performance Tuning Examples](./performance-tuning/)

A comprehensive collection of **12 practical examples** demonstrating PostgreSQL performance optimization techniques.

**Features:**
- 🐳 **Docker-ready** with PostgreSQL and pgAdmin
- 📚 **4 categories** covering query optimization to performance monitoring
- 🔄 **Idempotent examples** that can be run multiple times safely
- 🎯 **Real-world scenarios** from production environments

**Difficulty Distribution:**
- 🟢 **Beginner (5-10 min):** 0 examples (0.0%)
- 🟡 **Intermediate (10-15 min):** 6 examples (50.0%)
- 🔴 **Advanced (15-20 min):** 6 examples (50.0%)
- ⚫ **Expert (30-45 min):** 0 examples (0.0%)

**Categories:**
1. **Query Optimization** - Basic optimization, aggregation optimization, subquery optimization (3 examples)
2. **Indexing Strategies** - Basic indexing, advanced indexing (6 examples)
3. **Execution Plans** - Plan analysis (6 examples)
4. **Performance Monitoring** - Monitoring queries (6 examples)

**Features:**
- 🐳 **Docker-ready** with PostgreSQL and pgAdmin
- 📚 **4 categories** covering basic to advanced JSON operations
- 🔄 **Idempotent examples** that can be run multiple times safely
- 🎯 **Real-world scenarios** from API data to performance optimization

**Difficulty Distribution:**
- 🟢 **Beginner (5-10 min):** 3 examples (25.0%)
- 🟡 **Intermediate (10-15 min):** 5 examples (41.7%)
- 🔴 **Advanced (15-20 min):** 4 examples (33.3%)
- ⚫ **Expert (30-45 min):** 0 examples (0.0%)

**Categories:**
1. **Basic JSON** - JSON parsing, generation, validation (3 examples)
2. **JSON Queries** - Nested extraction, array operations, aggregation (3 examples)
3. **Real-world Applications** - API processing, configuration management, log analysis (3 examples)
4. **Advanced Patterns** - Schema validation, transformation, performance optimization (3 examples)

## 📊 Quest Difficulty Comparison

### **Overall Statistics:**
| Quest | Total Examples | Categories | Files | Completion |
|-------|---------------|------------|-------|------------|
| **Recursive CTE** | 31 examples | 8 categories | 31 files | ✅ 100% Complete |
| **Window Functions** | 112 examples | 5 categories | 23 files | ✅ 100% Complete |
| **JSON Operations** | 12 examples | 4 categories | 12 files | ✅ 100% Complete |
| **Performance Tuning** | 12 examples | 4 categories | 4 files | ✅ 100% Complete |

### **Aggregated Difficulty Statistics:**
| Difficulty | Recursive CTE | Window Functions | JSON Operations | Performance Tuning | **Total** | **Percentage** |
|------------|---------------|------------------|-----------------|-------------------|-----------|----------------|
| 🟢 **Beginner** | 8 | 2 | 3 | 0 | **13** | **7.8%** |
| 🟡 **Intermediate** | 10 | 10 | 5 | 6 | **31** | **18.6%** |
| 🔴 **Advanced** | 9 | 8 | 4 | 6 | **27** | **16.2%** |
| ⚫ **Expert** | 4 | 3 | 0 | 0 | **7** | **4.2%** |
| **Total** | **31** | **112** | **12** | **12** | **167** | **100%** |

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
| Basic Ranking | 2 | 0 | 0 | 0 | 2 |
| Advanced Ranking | 0 | 3 | 0 | 0 | 3 |
| Aggregation Windows | 0 | 3 | 0 | 0 | 3 |
| Partitioned Analytics | 0 | 0 | 12 | 0 | 12 |
| Advanced Patterns | 0 | 0 | 0 | 3 | 3 |
| **JSON Operations** |
| Basic JSON | 3 | 0 | 0 | 0 | 3 |
| JSON Queries | 0 | 3 | 0 | 0 | 3 |
| Real-world Applications | 0 | 2 | 1 | 0 | 3 |
| Advanced Patterns | 0 | 1 | 2 | 0 | 3 |

### **Time Estimates:**
- 🟢 **Beginner**: 5-10 min
- 🟡 **Intermediate**: 10-15 min  
- 🔴 **Advanced**: 15-20 min
- ⚫ **Expert**: 30-45 min

### **Learning Progression:**
1. **Start with JSON Operations** (3 beginner examples) - Foundation for modern data handling
2. **Progress to Recursive CTEs** (31 examples) - Master hierarchical and iterative data processing
3. **Advance to Window Functions** (112 examples) - Learn advanced analytics and ranking
4. **Optimize with Performance Tuning** (12 examples) - Master query optimization and performance

---

*Ready to master SQL? Start with the [JSON Operations quest](./json-operations/) for modern data handling, [Recursive CTE Examples](./recursive-cte/) for hierarchical data, [Window Functions](./window-functions/) for advanced analytics, or [Performance Tuning](./performance-tuning/) for optimization! 🚀* 