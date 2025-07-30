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
  - Email: `admin@recursive-cte.com`
  - Password: `admin`
- **PostgreSQL**: `localhost:5432`
  - Database: `recursive_cte_db`
  - Username: `postgres`
  - Password: `postgres`

### 5. View Examples
Once connected to pgAdmin, you can:
1. Navigate to the "Recursive CTE Database" server
2. Query `SELECT * FROM example_summary;` to see all available examples
3. Browse the logs in `/workspace/logs/` for execution results

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
- `02-password-generator.sql` - Password generation with patterns
- `03-spiral-matrix.sql` - Spiral matrix generation

## 🚀 Usage Options

### Option 1: Docker (Recommended)
```bash
# From the root directory
cd ..
docker-compose up -d

# View logs
docker-compose logs -f postgres

# Stop services
docker-compose down
```

### Option 2: Direct PostgreSQL Connection
```bash
# Connect to PostgreSQL
psql -h localhost -p 5432 -U postgres -d recursive_cte_db

# Run all examples
\i run-all-examples.sql

# Run specific example
\i 01-hierarchical-graph-traversal/01-employee-hierarchy.sql
```

### Option 3: Individual Examples
```bash
# Run a specific example
psql -h localhost -p 5432 -U postgres -d recursive_cte_db -f 01-hierarchical-graph-traversal/01-employee-hierarchy.sql

# Run all examples in a category
for file in 01-hierarchical-graph-traversal/*.sql; do
    psql -h localhost -p 5432 -U postgres -d recursive_cte_db -f "$file"
done
```

## 🔧 Key Features

### Idempotent Design
- **Self-contained**: Each example creates and drops its own tables
- **Safe to re-run**: Can be executed multiple times without errors
- **No side effects**: Tables are cleaned up after each example
- **Independent**: Examples don't depend on each other

### Containerized Environment
- **PostgreSQL 15**: Latest stable version with all features
- **pgAdmin 4**: Web-based administration tool
- **Automatic Setup**: All examples run automatically on container start
- **Persistent Data**: Database data persists between container restarts
- **Health Checks**: Ensures services are ready before running examples

### Example Structure
Every example follows this pattern:
```sql
-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS table_name CASCADE;

-- Create tables
CREATE TABLE table_name (...);

-- Insert sample data
INSERT INTO table_name VALUES (...);

-- Recursive CTE query
WITH RECURSIVE cte_name AS (
    -- Base case
    SELECT ...
    
    UNION ALL
    
    -- Recursive case
    SELECT ...
)
SELECT ... FROM cte_name;

-- Clean up
DROP TABLE IF EXISTS table_name CASCADE;
```

## 📊 Complete Coverage

This repository provides **31 comprehensive examples** covering all use cases mentioned in the original recursive CTE documentation:

### ✅ **Fully Covered Categories:**

1. **Hierarchical or Graph Traversal** (7 examples)
   - ✅ Organization charts, BOM, category trees, filesystem hierarchy, family trees
   - ✅ Graph reachability, dependency resolution

2. **Iteration and Emulation of Loops** (7 examples)
   - ✅ Number series, date series, Fibonacci, Collatz, base conversions
   - ✅ Factorial, cumulative sums

3. **Path-Finding and Analysis** (3 examples)
   - ✅ Shortest path, topological sort, cycle detection

4. **Data Transformation / Parsing** (3 examples)
   - ✅ String splitting, transitive closure, JSON parsing

5. **Row-by-Row Simulation or State Machines** (2 examples)
   - ✅ Inventory simulation, game simulation

6. **Self-Healing or Data Repair** (3 examples)
   - ✅ Sequence gaps, forward fill NULLs, interval coalescing

7. **Mathematical / Theoretical Uses** (3 examples)
   - ✅ Fibonacci, prime numbers, permutation generation

8. **Bonus Quirky Examples** (3 examples)
   - ✅ Work streak analysis, password generation, spiral matrix

## 📊 Example Highlights

### Hierarchical Data
```sql
-- Employee hierarchy with full paths
WITH RECURSIVE employee_hierarchy AS (
    SELECT employee_id, name, manager_id, 0 as level, name as path
    FROM employees WHERE manager_id IS NULL
    
    UNION ALL
    
    SELECT e.employee_id, e.name, e.manager_id, 
           eh.level + 1, eh.path || ' → ' || e.name
    FROM employees e
    JOIN employee_hierarchy eh ON e.manager_id = eh.employee_id
)
SELECT * FROM employee_hierarchy ORDER BY level, name;
```

### Mathematical Sequences
```sql
-- Fibonacci sequence
WITH RECURSIVE fibonacci AS (
    SELECT 0 as n, 0 as fib_n, 1 as fib_next
    
    UNION ALL
    
    SELECT n + 1, fib_next, fib_n + fib_next
    FROM fibonacci WHERE n < 14
)
SELECT n, fib_n FROM fibonacci ORDER BY n;
```

### Data Transformation
```sql
-- String splitting
WITH RECURSIVE string_split AS (
    SELECT 'apple,banana,cherry' as input, 1 as pos,
           SUBSTRING('apple,banana,cherry' FROM 1 FOR 
                    POSITION(',' IN 'apple,banana,cherry') - 1) as value
    
    UNION ALL
    
    SELECT SUBSTRING(input FROM POSITION(',' IN input) + 1),
           pos + 1,
           SUBSTRING(SUBSTRING(input FROM POSITION(',' IN input) + 1) 
                    FROM 1 FOR POSITION(',' IN SUBSTRING(input FROM POSITION(',' IN input) + 1)) - 1)
    FROM string_split WHERE POSITION(',' IN input) > 0
)
SELECT pos, value FROM string_split WHERE LENGTH(value) > 0;
```

## 🎯 Use Cases by Industry

### Business & Finance
- Organization chart analysis
- Cost rollup calculations
- Workflow automation
- Inventory management

### Technology
- Dependency resolution
- Graph algorithms
- Data pipeline processing
- Configuration management

### Healthcare
- Family tree analysis
- Disease spread modeling
- Treatment pathway analysis
- Medical hierarchy management

### E-commerce
- Category navigation
- Product recommendations
- Inventory forecasting
- Customer relationship chains

## ⚠️ Performance Considerations

1. **Indexing**: Ensure proper indexes on join columns
2. **Limiting Depth**: Use WHERE clauses to limit recursion depth
3. **Alternative Solutions**: Consider procedural languages for complex cases
4. **Testing**: Always test with realistic data volumes

## 🔍 Troubleshooting

### Docker Issues
```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs postgres
docker-compose logs pgadmin

# Restart services
docker-compose restart

# Clean up and start fresh
docker-compose down -v
docker-compose up -d
```

### Database Connection Issues
```bash
# Test connection
psql -h localhost -p 5432 -U postgres -d recursive_cte_db

# Check if database exists
docker exec -it recursive-cte-postgres psql -U postgres -l
```

### Common Issues

1. **Infinite Recursion**: Check termination conditions
2. **Performance**: Add depth limits and proper indexes
3. **Syntax Errors**: Verify database-specific syntax
4. **Memory Issues**: Limit result set sizes

### Database-Specific Notes

- **PostgreSQL**: Full support, best performance
- **SQLite**: Good support, some limitations
- **MySQL**: Limited support (8.0+)
- **SQL Server**: Good support, different syntax
- **Oracle**: Good support, different syntax

## 📖 Further Reading

- [PostgreSQL Recursive CTEs](https://www.postgresql.org/docs/current/queries-with.html)
- [SQLite Recursive CTEs](https://www.sqlite.org/lang_with.html)
- [MySQL Recursive CTEs](https://dev.mysql.com/doc/refman/8.0/en/with.html)

## 🤝 Contributing

Feel free to contribute additional examples or improvements:

1. Fork the repository
2. Add your example with clear documentation
3. Test with multiple database systems
4. Submit a pull request

## 📄 License

This project is open source and available under the MIT License.

---

**Happy SQL Recursion! 🚀** 