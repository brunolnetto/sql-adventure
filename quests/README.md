# SQL Adventure Quests

This directory contains various SQL learning quests and examples.

## Available Quests

### 🚀 [Recursive CTE Examples](./recursive-cte/)

A comprehensive collection of **26 practical examples** demonstrating Recursive Common Table Expressions (CTEs) in SQL.

**Features:**
- 🐳 **Docker-ready** with PostgreSQL and pgAdmin
- 📚 **8 categories** covering all recursive CTE use cases
- 🔄 **Idempotent examples** that can be run multiple times safely
- 🎯 **Real-world scenarios** from hierarchical data to mathematical sequences

**Difficulty Distribution:**
- 🟢 **Beginner (5-10 min):** 7 examples (26.9%)
- 🟡 **Intermediate (10-20 min):** 8 examples (30.8%)
- 🔴 **Advanced (15-30 min):** 7 examples (26.9%)
- ⚫ **Expert (30-45 min):** 4 examples (15.4%)

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

A comprehensive collection of **26+ practical examples** demonstrating Window Functions in SQL.

**Features:**
- 🐳 **Docker-ready** with PostgreSQL and pgAdmin
- 📚 **5 categories** covering all window function use cases
- 🔄 **Idempotent examples** that can be run multiple times safely
- 🎯 **Real-world scenarios** from ranking to advanced analytics

**Current Status:**
- ✅ **2 files with standardized difficulty headers**
- 🔄 **24+ files need difficulty header standardization**
- 📊 **Difficulty percentages will be updated once all files are standardized**

**Note:** The window functions quest has many examples but needs standardization of difficulty headers and time estimates to match the recursive CTE quest format.

---

*More quests coming soon! 🎉* 