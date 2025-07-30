# Recursive CTE Examples: A Comprehensive Guide

This repository contains practical examples of Recursive Common Table Expressions (CTEs) in SQL, demonstrating their versatility beyond just hierarchical data traversal.

## 📚 Overview

Recursive CTEs are a powerful SQL feature that allows you to perform iterative operations directly in SQL. While they're commonly associated with hierarchical data, they can be used for much more - from mathematical computations to data transformation and simulation.

## 🐳 Quick Start with Docker

### Prerequisites
- Docker and Docker Compose installed
- Git (to clone this repository)

### 1. Clone and Setup
```bash
git clone <repository-url>
cd quests/recursive-cte
```

### 2. Configure Environment (Optional)
```bash
# From the root directory, copy the example environment file
cp ../env.example ../.env

# Edit .env if you want to customize settings
nano ../.env
```

### 3. Start the Services
```bash
# From the root directory, start PostgreSQL and pgAdmin
cd ..
docker-compose up -d

# Check if services are running
docker-compose ps
```

### 4. Access the Services
- **pgAdmin**: http://localhost:8080
  - Email: `admin@sql-adventure.com`
  - Password: `admin`
- **PostgreSQL**: `localhost:5433`
  - Database: `sql_adventure_db`
  - Username: `postgres`
  - Password: `postgres`

### 5. View Examples
Once connected to pgAdmin, you can:
1. Navigate to the "Recursive CTE Database" server
2. Browse the individual example files in the category folders
3. Browse the logs in `/workspace/logs/` for execution results

### 6. Run Examples (Optional)
You can also run examples from the command line:
```bash
# From the root directory
./scripts/run-examples.sh list recursive-cte                    # List all examples
./scripts/run-examples.sh quest recursive-cte                   # Run all examples
./scripts/run-examples.sh quest recursive-cte hierarchical      # Run specific category
```

## 🗂️ File Structure

The examples are organized into 8 categories, each containing individual example files that are **idempotent** (can be run multiple times safely):

### 1. **Hierarchical & Graph Traversal** (`01-hierarchical-graph-traversal/`)
- `01-employee-hierarchy.sql` - Organization charts and employee hierarchies
- `02-bill-of-materials.sql` - Bill of Materials (BOM) with cost calculations
- `03-category-tree.sql` - Category trees and nested structures
- `04-graph-reachability.sql` - Graph reachability analysis
- `05-dependency-resolution.sql` - Dependency resolution (like package managers)
- `06-filesystem-hierarchy.sql` - Filesystem hierarchy traversal
- `07-family-tree.sql` - Family tree and ancestor relationships

### 2. **Iteration & Loop Emulation** (`02-iteration-loops/`)
- `01-number-series.sql` - Number series generation (1 to N, even numbers)
- `02-date-series.sql` - Date series and business day calculations
- `03-fibonacci-sequence.sql` - Fibonacci sequence generation
- `04-collatz-sequence.sql` - Collatz sequence calculation
- `05-base-conversion.sql` - Base conversions (decimal to binary)
- `06-factorial-calculation.sql` - Factorial calculations
- `07-running-total.sql` - Running totals and cumulative sums

### 3. **Path-Finding & Analysis** (`03-path-finding-analysis/`)
- `01-shortest-path.sql` - Shortest path algorithms (BFS-style)
- `02-topological-sort.sql` - Topological sorting for task dependencies
- `03-cycle-detection.sql` - Cycle detection in graphs

### 4. **Data Transformation & Parsing** (`04-data-transformation-parsing/`)
- `01-string-splitting.sql` - String splitting and parsing
- `02-transitive-closure.sql` - Transitive closure calculations
- `03-json-parsing.sql` - JSON-like structure parsing

### 5. **Simulation & State Machines** (`05-simulation-state-machines/`)
- `01-inventory-simulation.sql` - Inventory management simulation
- `02-game-simulation.sql` - Game simulation (Tic-tac-toe)

### 6. **Data Repair & Self-Healing** (`06-data-repair-healing/`)
- `01-sequence-gaps.sql` - Filling gaps in sequences
- `02-forward-fill-nulls.sql` - Forward/backward filling of NULLs
- `03-interval-coalescing.sql` - Merging overlapping intervals

### 7. **Mathematical & Theoretical** (`07-mathematical-theoretical/`)
- `01-fibonacci-sequence.sql` - Fibonacci sequence generation
- `02-prime-numbers.sql` - Prime number generation
- `03-permutation-generation.sql` - Permutation generation

### 8. **Bonus Quirky Examples** (`08-bonus-quirky-examples/`)
- `01-work-streak.sql` - Longest work streak analysis
- `02-password-generator.sql` - Password pattern generation
- `03-spiral-matrix.sql` - Spiral matrix generation

## 🔧 Running Examples

### Option 1: Docker (Recommended)
```bash
# Start the environment
docker-compose up -d

# Run examples using the script
./scripts/run-examples.sh quest recursive-cte
```

### Option 2: Manual Execution
```bash
# Connect to PostgreSQL
psql -h localhost -p 5433 -U postgres -d sql_adventure_db

# Run individual examples
\i quests/recursive-cte/01-hierarchical-graph-traversal/01-employee-hierarchy.sql
```

### Option 3: Using the Master Script
```bash
# Run all examples at once
psql -h localhost -p 5433 -U postgres -d sql_adventure_db -f quests/recursive-cte/run-all-examples.sql
```

## 🎯 Key Concepts

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

## 📊 Performance Considerations

- **Limit recursion depth** to prevent infinite loops
- **Use appropriate indexes** on join columns
- **Monitor query execution plans** for large datasets
- **Consider materialized views** for frequently accessed hierarchies

## 🐛 Troubleshooting

### Common Issues
1. **Infinite recursion**: Add proper termination conditions
2. **Performance problems**: Check indexes and query plans
3. **Memory issues**: Limit result set size with LIMIT clauses

### Debugging Tips
- Use `EXPLAIN ANALYZE` to understand query performance
- Add intermediate SELECT statements to inspect CTE results
- Use `\timing` in psql to measure execution time

## 📚 Further Reading

- [PostgreSQL Documentation - WITH Queries](https://www.postgresql.org/docs/current/queries-with.html)
- [SQL Server Documentation - Recursive CTEs](https://docs.microsoft.com/en-us/sql/t-sql/queries/with-common-table-expression-transact-sql)
- [Oracle Documentation - Hierarchical Queries](https://docs.oracle.com/en/database/oracle/oracle-database/19/sqlrf/Hierarchical-Queries.html)

## 🤝 Contributing

Feel free to contribute additional examples or improvements to existing ones. Please ensure all examples are:
- **Idempotent** (can be run multiple times safely)
- **Well-documented** with clear comments
- **Realistic** with practical use cases
- **Tested** and verified to work correctly

---

*Happy SQL Adventuring! 🚀* 