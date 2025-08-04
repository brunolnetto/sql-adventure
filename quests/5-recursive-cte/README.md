# Recursive CTE Quest 🔄

Master hierarchical data, graph algorithms, and iterative operations with Recursive Common Table Expressions.

## 📊 Overview

- **20 Examples** across 8 categories
- **Difficulty**: Beginner → Expert
- **Status**: ✅ Complete
- **Time**: 5-45 min per example
- **Prerequisites**: All previous quests (Data Modeling + Performance Tuning + Window Functions + JSON Operations)

## 🚀 Quick Start

```bash
# Start environment
docker-compose up -d

# Run all examples
./scripts/run-examples.sh quest recursive-cte

# Run specific category
./scripts/run-examples.sh quest recursive-cte hierarchical-graph-traversal
```

## 📚 Categories

### **01-hierarchical-graph-traversal/** ✅ **Legitimate Use Cases**
- `01-employee-hierarchy.sql` - Organization charts
- `02-bill-of-materials.sql` - BOM with cost calculations
- `03-category-tree.sql` - Category navigation
- `04-graph-reachability.sql` - Graph theory concepts
- `05-dependency-resolution.sql` - Topological sorting
- `06-filesystem-hierarchy.sql` - Path manipulation
- `07-family-tree.sql` - Ancestor relationships

### **02-iteration-loops/** 🎓 **Educational Patterns**
- `01-number-series.sql` - Basic recursion (use `generate_series()` instead)
- `02-date-series.sql` - Date sequences (use `generate_series()` instead)
- `03-fibonacci-sequence.sql` - Mathematical sequences ✅
- `04-collatz-sequence.sql` - Conditional recursion ✅
- `05-base-conversion.sql` - Mathematical operations ✅
- `06-factorial-calculation.sql` - Simple recursion ✅
- `07-running-total.sql` - Accumulation (use window functions instead)

### **03-path-finding-analysis/** ✅ **Legitimate**
- `01-shortest-path.sql` - BFS algorithm implementation
- `02-topological-sort.sql` - Graph theory + cycle detection
- `03-cycle-detection.sql` - Complex graph algorithms

### **04-data-transformation-parsing/** 🎓 **Mixed**
- `01-string-splitting.sql` - String manipulation (use `string_to_array()` instead)
- `02-transitive-closure.sql` - Matrix operations + recursion ✅
- `03-json-parsing.sql` - Complex nested structure parsing ✅

### **05-simulation-state-machines/** ✅ **Legitimate**
- `01-inventory-simulation.sql` - State tracking + business logic
- `02-game-simulation.sql` - Game state management + AI logic

### **06-data-repair-healing/** 🎓 **Mixed**
- `01-sequence-gaps.sql` - Gap detection + filling ✅
- `02-forward-fill-nulls.sql` - Data imputation (use `IGNORE NULLS` instead)
- `03-interval-coalescing.sql` - Complex interval logic ✅

### **07-mathematical-theoretical/** ✅ **Legitimate**
- `01-fibonacci-sequence.sql` - Mathematical sequences
- `02-prime-numbers.sql` - Sieve algorithms
- `03-permutation-generation.sql` - Combinatorial algorithms

### **08-bonus-quirky-examples/** 🎓 **Educational**
- `01-work-streak.sql` - Pattern recognition ✅
- `02-password-generator.sql` - String generation patterns ✅
- `03-spiral-matrix.sql` - Complex coordinate manipulation ✅

## 🎯 Learning Path

### **🟢 Beginner (After All Previous Quests)**
1. `01-number-series.sql` - Basic recursion patterns
2. `01-employee-hierarchy.sql` - Hierarchical traversal
3. `01-string-splitting.sql` - String manipulation
4. `03-category-tree.sql` - Simple tree navigation

### **🟡 Intermediate**
1. `03-fibonacci-sequence.sql` - Mathematical sequences
2. `02-bill-of-materials.sql` - Complex hierarchies
3. `01-sequence-gaps.sql` - Data repair patterns
4. `06-factorial-calculation.sql` - Mathematical recursion

### **🔴 Advanced**
1. `04-graph-reachability.sql` - Graph theory concepts
2. `02-transitive-closure.sql` - Matrix operations
3. `01-inventory-simulation.sql` - State machines
4. `01-shortest-path.sql` - Path-finding algorithms

### **⚫ Expert**
1. `02-topological-sort.sql` - Advanced graph algorithms
2. `03-cycle-detection.sql` - Complex graph analysis
3. `02-game-simulation.sql` - Game state management
4. `03-permutation-generation.sql` - Combinatorial algorithms

## 🔧 Key Concepts

```sql
WITH RECURSIVE cte_name AS (
    -- Base case (non-recursive part)
    SELECT ... FROM table WHERE condition
    
    UNION ALL
    
    -- Recursive case (recursive part)
    SELECT ... FROM table 
    JOIN cte_name ON condition
    WHERE recursive_condition
)
SELECT * FROM cte_name;
```

## ⚠️ Important Note

**Educational vs. Practical Examples:**
- **✅ Legitimate**: Use recursive CTEs for hierarchical data, graph algorithms, mathematical sequences
- **⚠️ Educational**: Learn patterns from "silly" examples, but use simpler alternatives in production
- **🎓 Better Alternatives**: `generate_series()`, window functions, `string_to_array()`, `IGNORE NULLS`

## 🏢 Real-World Applications

- **Business Analytics**: Organization charts, BOM, category management
- **Data Science**: Graph analysis, mathematical modeling, simulation
- **Software Development**: File systems, package management, game development

---

*Ready to master recursive CTEs? Start with [Hierarchical & Graph Traversal](./01-hierarchical-graph-traversal/)! 🚀* 