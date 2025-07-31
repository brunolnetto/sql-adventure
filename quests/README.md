# SQL Adventure Quests

This directory contains various SQL learning quests and examples.

## Available Quests

### 🚀 [Recursive CTE Examples](./recursive-cte/)

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
- pgAdmin: http://localhost:8080 (admin@recursive-cte.com / admin)
- PostgreSQL: localhost:5432

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

---

*More quests coming soon! 🎉* 