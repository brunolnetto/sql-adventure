# Recursive CTE Quest 🔄

Master the power of Recursive Common Table Expressions (CTEs) for hierarchical data, mathematical sequences, and complex data transformations in SQL.

## 🎯 What You'll Learn

Recursive CTEs are a powerful SQL feature that allows you to perform iterative operations directly in SQL. While they're commonly associated with hierarchical data, they can be used for much more - from mathematical computations to data transformation and simulation.

### **Key Concepts:**
- **Hierarchical traversal** - Employee org charts, family trees, BOM
- **Graph algorithms** - Shortest path, cycle detection, reachability  
- **Mathematical sequences** - Fibonacci, Collatz, prime generation
- **Data transformation** - Nested JSON parsing, complex string operations
- **Simulation & state machines** - Multi-step processes, game states

## ⚠️ **Honest Assessment: Educational vs. Practical Examples**

**Let's be real:** Some of these examples are "silly" because there are simpler ways to accomplish the same tasks. However, they're included for **educational purposes** to help you understand recursive CTE patterns.

### 🎓 **Educational Examples (Learn the Pattern, Use Simpler Alternatives in Practice):**

| Example | Why "Silly" | Better Alternative |
|---------|-------------|-------------------|
| Number Series | `generate_series()` is much simpler | `SELECT generate_series(1, 10)` |
| Date Series | `generate_series()` with dates | `SELECT generate_series(DATE '2024-01-01', DATE '2024-01-31', INTERVAL '1 day')` |
| Running Total | Window functions are more efficient | `SUM(amount) OVER (ORDER BY date_id)` |
| Forward Fill | `IGNORE NULLS` window functions (PostgreSQL 12+) | `FIRST_VALUE(temp) IGNORE NULLS OVER (ORDER BY timestamp)` |
| String Splitting | `string_to_array()` + `unnest()` | `SELECT unnest(string_to_array('a,b,c', ','))` |

### ✅ **Legitimate Examples (Recursive CTE is Actually Appropriate):**

- **Hierarchical Data** - Employee org charts, family trees, BOM
- **Graph Algorithms** - Shortest path, cycle detection, reachability  
- **Mathematical Sequences** - Fibonacci, Collatz, prime generation
- **Complex Data Transformation** - Nested JSON parsing, complex string operations
- **Simulation & State Machines** - Multi-step processes, game states

## 📊 Difficulty Level Evaluation

### **Difficulty Scale:**
- 🟢 **Beginner** - Basic recursive patterns, simple logic (5-10 min)
- 🟡 **Intermediate** - Moderate complexity, multiple concepts (10-20 min)
- 🔴 **Advanced** - Complex algorithms, edge cases, performance considerations (15-30 min)
- ⚫ **Expert** - Theoretical concepts, optimization challenges (30-45 min)

### **Complete Example Difficulty Table:**

| Category | Example | Difficulty | Type | Description |
|----------|---------|------------|------|-------------|
| **Hierarchical & Graph Traversal** | `01-employee-hierarchy.sql` | 🟢 Beginner | ✅ Legitimate | Basic parent-child traversal |
| | `02-bill-of-materials.sql` | 🟡 Intermediate | ✅ Legitimate | Cost calculations + hierarchy |
| | `03-category-tree.sql` | 🟢 Beginner | ✅ Legitimate | Simple tree navigation |
| | `04-graph-reachability.sql` | 🔴 Advanced | ✅ Legitimate | Graph theory concepts |
| | `05-dependency-resolution.sql` | 🔴 Advanced | ✅ Legitimate | Topological sorting logic |
| | `06-filesystem-hierarchy.sql` | 🟡 Intermediate | ✅ Legitimate | Path manipulation |
| | `07-family-tree.sql` | 🟡 Intermediate | ✅ Legitimate | Multiple relationship types |
| **Iteration & Loop Emulation** | `01-number-series.sql` | 🟢 Beginner | ⚠️ Educational | Simple increment pattern |
| | `02-date-series.sql` | 🟢 Beginner | ⚠️ Educational | Date arithmetic |
| | `03-fibonacci-sequence.sql` | 🟡 Intermediate | ✅ Legitimate | Mathematical sequence |
| | `04-collatz-sequence.sql` | 🟡 Intermediate | ✅ Legitimate | Conditional recursion |
| | `05-base-conversion.sql` | 🟡 Intermediate | ✅ Legitimate | Mathematical operations |
| | `06-factorial-calculation.sql` | 🟢 Beginner | ✅ Legitimate | Simple mathematical recursion |
| | `07-running-total.sql` | 🟢 Beginner | ⚠️ Educational | Accumulation pattern |
| **Path-Finding & Analysis** | `01-shortest-path.sql` | 🔴 Advanced | ✅ Legitimate | BFS algorithm implementation |
| | `02-topological-sort.sql` | ⚫ Expert | ✅ Legitimate | Graph theory + cycle detection |
| | `03-cycle-detection.sql` | ⚫ Expert | ✅ Legitimate | Complex graph algorithms |
| **Data Transformation & Parsing** | `01-string-splitting.sql` | 🟢 Beginner | ⚠️ Educational | Basic string manipulation |
| | `02-transitive-closure.sql` | 🔴 Advanced | ✅ Legitimate | Matrix operations + recursion |
| | `03-json-parsing.sql` | 🔴 Advanced | ✅ Legitimate | Complex nested structure parsing |
| **Simulation & State Machines** | `01-inventory-simulation.sql` | 🔴 Advanced | ✅ Legitimate | State tracking + business logic |
| | `02-game-simulation.sql` | ⚫ Expert | ✅ Legitimate | Game state management + AI logic |
| **Data Repair & Self-Healing** | `01-sequence-gaps.sql` | 🟡 Intermediate | ✅ Legitimate | Gap detection + filling |
| | `02-forward-fill-nulls.sql` | 🟢 Beginner | ⚠️ Educational | Simple data imputation |
| | `03-interval-coalescing.sql` | 🔴 Advanced | ✅ Legitimate | Complex interval logic |
| **Mathematical & Theoretical** | `01-fibonacci-sequence.sql` | 🟡 Intermediate | ✅ Legitimate | Mathematical sequence |
| | `02-prime-numbers.sql` | 🔴 Advanced | ✅ Legitimate | Sieve algorithms |
| | `03-permutation-generation.sql` | ⚫ Expert | ✅ Legitimate | Combinatorial algorithms |
| **Bonus Quirky Examples** | `01-work-streak.sql` | 🟡 Intermediate | ✅ Legitimate | Pattern recognition |
| | `02-password-generator.sql` | 🟡 Intermediate | ✅ Legitimate | String generation patterns |
| | `03-spiral-matrix.sql` | 🔴 Advanced | ✅ Legitimate | Complex coordinate manipulation |

## 🚀 Quick Start

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
# Run all recursive CTE examples
./scripts/run-examples.sh quest recursive-cte

# Run specific categories
./scripts/run-examples.sh quest recursive-cte hierarchical-graph-traversal
./scripts/run-examples.sh quest recursive-cte iteration-loops
```

## 📚 Learning Path

### **🟢 Beginner Path (Start Here)**
1. `01-number-series.sql` - Understand basic recursion patterns
2. `01-employee-hierarchy.sql` - Learn hierarchical traversal
3. `01-string-splitting.sql` - Basic string manipulation
4. `03-category-tree.sql` - Simple tree navigation

### **🟡 Intermediate Path**
1. `03-fibonacci-sequence.sql` - Mathematical sequences
2. `02-bill-of-materials.sql` - Complex hierarchies
3. `01-sequence-gaps.sql` - Data repair patterns
4. `06-factorial-calculation.sql` - Mathematical recursion

### **🔴 Advanced Path**
1. `04-graph-reachability.sql` - Graph theory concepts
2. `02-transitive-closure.sql` - Matrix operations
3. `01-inventory-simulation.sql` - State machines
4. `01-shortest-path.sql` - Path-finding algorithms

### **⚫ Expert Path**
1. `02-topological-sort.sql` - Advanced graph algorithms
2. `03-cycle-detection.sql` - Complex graph analysis
3. `02-game-simulation.sql` - Game state management
4. `03-permutation-generation.sql` - Combinatorial algorithms

## 📁 File Organization

The examples are organized into 8 categories, each containing individual example files that are **idempotent** (can be run multiple times safely):

### **01-hierarchical-graph-traversal/** ✅ **Legitimate**
- `01-employee-hierarchy.sql` - Organization charts and employee hierarchies
- `02-bill-of-materials.sql` - Bill of Materials (BOM) with cost calculations
- `03-category-tree.sql` - Category trees and nested structures
- `04-graph-reachability.sql` - Graph reachability analysis
- `05-dependency-resolution.sql` - Dependency resolution (like package managers)
- `06-filesystem-hierarchy.sql` - Filesystem hierarchy traversal
- `07-family-tree.sql` - Family tree and ancestor relationships

### **02-iteration-loops/** 🎓 **Mixed**
- `01-number-series.sql` - Number series generation (1 to N, even numbers) ⚠️ **Use `generate_series()`**
- `02-date-series.sql` - Date series and business day calculations ⚠️ **Use `generate_series()`**
- `03-fibonacci-sequence.sql` - Fibonacci sequence generation ✅ **Legitimate**
- `04-collatz-sequence.sql` - Collatz sequence calculation ✅ **Legitimate**
- `05-base-conversion.sql` - Base conversions (decimal to binary) ✅ **Legitimate**
- `06-factorial-calculation.sql` - Factorial calculations ✅ **Legitimate**
- `07-running-total.sql` - Running totals and cumulative sums ⚠️ **Use window functions**

### **03-path-finding-analysis/** ✅ **Legitimate**
- `01-shortest-path.sql` - Shortest path algorithms (BFS-style)
- `02-topological-sort.sql` - Topological sorting for task dependencies
- `03-cycle-detection.sql` - Cycle detection in graphs

### **04-data-transformation-parsing/** 🎓 **Mixed**
- `01-string-splitting.sql` - String splitting and parsing ⚠️ **Use `string_to_array()` + `unnest()`**
- `02-transitive-closure.sql` - Transitive closure calculations ✅ **Legitimate**
- `03-json-parsing.sql` - JSON-like structure parsing ✅ **Legitimate**

### **05-simulation-state-machines/** ✅ **Legitimate**
- `01-inventory-simulation.sql` - Inventory management simulation
- `02-game-simulation.sql` - Game simulation (Tic-tac-toe)

### **06-data-repair-healing/** 🎓 **Mixed**
- `01-sequence-gaps.sql` - Filling gaps in sequences ✅ **Legitimate**
- `02-forward-fill-nulls.sql` - Forward/backward filling of NULLs ⚠️ **Use `IGNORE NULLS` (PostgreSQL 12+)**
- `03-interval-coalescing.sql` - Merging overlapping intervals ✅ **Legitimate**

### **07-mathematical-theoretical/** ✅ **Legitimate**
- `01-fibonacci-sequence.sql` - Fibonacci sequence generation
- `02-prime-numbers.sql` - Prime number generation
- `03-permutation-generation.sql` - Permutation generation

### **08-bonus-quirky-examples/** 🎓 **Educational**
- `01-work-streak.sql` - Longest work streak analysis ✅ **Legitimate**
- `02-password-generator.sql` - Password pattern generation ✅ **Legitimate**
- `03-spiral-matrix.sql` - Spiral matrix generation ✅ **Legitimate**

## 🔧 Key Concepts

### Recursive CTE Structure
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

### Common Patterns
1. **Hierarchical Traversal**: Navigate parent-child relationships
2. **Iterative Generation**: Create sequences, series, or patterns
3. **Path Finding**: Find shortest paths or all possible paths
4. **Data Transformation**: Parse strings, flatten structures
5. **Simulation**: Model state changes over time

## 🏢 Real-World Applications

### **Business Analytics**
- **Organization charts** - Employee hierarchies and reporting structures
- **Bill of Materials** - Product cost calculations and dependencies
- **Category management** - Nested category trees and navigation
- **Dependency tracking** - Project and task dependencies

### **Data Science**
- **Graph analysis** - Network analysis and path finding
- **Mathematical modeling** - Sequence generation and calculations
- **Data transformation** - Complex parsing and structure manipulation
- **Simulation modeling** - State-based simulations and predictions

### **Software Development**
- **File system navigation** - Directory tree traversal
- **Package management** - Dependency resolution
- **Configuration parsing** - Nested configuration structures
- **Game development** - Game state management and AI

## 📊 Performance Considerations

- **Limit recursion depth** to prevent infinite loops
- **Use appropriate indexes** on join columns
- **Monitor query execution plans** for large datasets
- **Consider materialized views** for frequently accessed hierarchies
- **Use simpler alternatives** when available (see table above)

## 🐛 Troubleshooting

### Common Issues
1. **Infinite recursion**: Add proper termination conditions
2. **Performance problems**: Check indexes and query plans
3. **Memory issues**: Limit result set size with LIMIT clauses
4. **Over-engineering**: Use built-in functions when possible

### Debugging Tips
- Use `EXPLAIN ANALYZE` to understand query performance
- Add intermediate SELECT statements to inspect CTE results
- Use `\timing` in psql to measure execution time
- Consider if a simpler approach exists

## 🤝 Contributing

We welcome contributions to expand the Recursive CTE quest! Please ensure:

- **Examples are idempotent** (safe to run multiple times)
- **Include clear comments** explaining the concepts
- **Use realistic data** that demonstrates real-world scenarios
- **Follow the difficulty rating system**
- **Test thoroughly** before submitting
- **Honestly label** examples as educational vs. practical
- **Keep files focused** with 3-4 examples per file
- **Maintain clear learning progression** between files

## 📚 Further Reading

- [PostgreSQL Documentation - WITH Queries](https://www.postgresql.org/docs/current/queries-with.html)
- [SQL Server Documentation - Recursive CTEs](https://docs.microsoft.com/en-us/sql/t-sql/queries/with-common-table-expression-transact-sql)
- [Oracle Documentation - Hierarchical Queries](https://docs.oracle.com/en/database/oracle/oracle-database/19/sqlrf/Hierarchical-Queries.html)

---

*Ready to master recursive CTEs? Start with the [Hierarchical & Graph Traversal examples](./01-hierarchical-graph-traversal/)! 🚀*

**Remember:** Learn the patterns from the "silly" examples, but use the simpler alternatives in production! 😉 