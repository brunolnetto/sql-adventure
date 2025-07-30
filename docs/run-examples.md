# Run Examples Script 📊

The `run-examples.sh` script allows you to execute SQL examples from the command line with full output display and automatic configuration loading from `.env` files.

## 🎯 **Features**

- **Full SQL Output** - See all query results and data
- **Complete Row Display** - All rows shown without truncation, even for long tables
- **Verbose/Quiet Modes** - Control output detail level
- **Flexible Execution** - Run individual examples, categories, or entire quests
- **Colored Output** - Easy-to-read status messages
- **Error Handling** - Clear feedback on success/failure
- **Environment Configuration** - Automatic loading from `.env` files
- **Connection Testing** - Verify database connectivity before running examples
- **Configuration Display** - Show current settings

## 🚀 **Usage**

### **Basic Commands**

```bash
# Run all examples in a quest (with SQL output)
./scripts/run-examples.sh quest recursive-cte

# Run a specific category (with SQL output)
./scripts/run-examples.sh quest recursive-cte 01-hierarchical-graph-traversal

# Run a single example (with SQL output)
./scripts/run-examples.sh example quests/recursive-cte/01-hierarchical-graph-traversal/01-employee-hierarchy.sql

# List available quests
./scripts/run-examples.sh list

# List examples in a specific quest
./scripts/run-examples.sh list recursive-cte

# Test database connection
./scripts/run-examples.sh test

# Show current configuration
./scripts/run-examples.sh config
```

### **Output Control**

```bash
# Verbose mode (default) - Shows full SQL output
./scripts/run-examples.sh --verbose quest recursive-cte
./scripts/run-examples.sh -v quest recursive-cte

# Quiet mode - Shows only status messages
./scripts/run-examples.sh --quiet quest recursive-cte
./scripts/run-examples.sh -q quest recursive-cte
```

### **Database Configuration**

The script automatically loads database credentials from the `.env` file. You can override these with command-line options:

```bash
# Custom database settings (overrides .env)
./scripts/run-examples.sh \
  --host localhost \
  --port 5433 \
  --user postgres \
  --database sql_adventure_db \
  --password postgres \
  quest recursive-cte
```

## ⚙️ **Configuration**

### **Environment File (.env)**

The script automatically loads configuration from a `.env` file in the project root. Create one by copying the example:

```bash
# Copy the example configuration
cp env.example .env

# Edit the configuration
nano .env
```

### **Example .env Configuration**
```bash
# PostgreSQL Configuration
POSTGRES_DB=sql_adventure_db
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
HOST_PORT=5432

# pgAdmin Configuration
PGADMIN_EMAIL=admin@sql-adventure.com
PGADMIN_PASSWORD=admin
PGADMIN_PORT=8080
```

### **Configuration Priority**
1. **Command-line options** (highest priority)
2. **Environment variables** (from .env file)
3. **Default values** (fallback)

## 📋 **Output Examples**

### **Configuration Display**
```
[INFO] Loading configuration from .env
Current Configuration:
  Database Host: localhost
  Database Port: 5433
  Database User: postgres
  Database Name: sql_adventure_db
  Password: pos***
  Quests Directory: quests
  Verbose Mode: true
```

### **Connection Test**
```
[INFO] Loading configuration from .env
[INFO] Testing database connection...
[SUCCESS] Database connection successful
```

### **Verbose Mode Output**
```
[INFO] Loading configuration from .env
[INFO] Running quest: recursive-cte, category: 01-hierarchical-graph-traversal
========================================
[INFO] Running: 01-employee-hierarchy.sql
----------------------------------------
-- =====================================================
-- Employee Hierarchy Example
-- =====================================================

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS employees CASCADE;

-- Create sample employee table
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    name VARCHAR(100),
    manager_id INT,
    department VARCHAR(50),
    salary DECIMAL(10,2)
);

-- Insert sample data
INSERT INTO employees VALUES
(1, 'John CEO', NULL, 'Executive', 100000),
(2, 'Alice VP', 1, 'Engineering', 80000),
(3, 'Bob Manager', 2, 'Engineering', 60000),
(4, 'Carol Dev', 3, 'Engineering', 50000),
(5, 'David Dev', 3, 'Engineering', 52000),
(6, 'Eve VP', 1, 'Marketing', 75000),
(7, 'Frank Manager', 6, 'Marketing', 55000),
(8, 'Grace Specialist', 7, 'Marketing', 45000);

-- Find complete hierarchy for each employee
WITH RECURSIVE employee_hierarchy AS (
    -- Base case: employees with no manager (CEO)
    SELECT 
        employee_id,
        name,
        manager_id,
        department,
        salary,
        0 as level,
        CAST(name AS VARCHAR(500)) as hierarchy_path
    FROM employees 
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive case: employees with managers
    SELECT 
        e.employee_id,
        e.name,
        e.manager_id,
        e.department,
        e.salary,
        eh.level + 1,
        CAST(eh.hierarchy_path || ' → ' || e.name AS VARCHAR(500))
    FROM employees e
    INNER JOIN employee_hierarchy eh ON e.manager_id = eh.employee_id
)
SELECT 
    level,
    name,
    department,
    salary,
    hierarchy_path
FROM employee_hierarchy
ORDER BY level, name;

 level |    name     | department  |  salary  |                    hierarchy_path                    
-------+-------------+-------------+----------+----------------------------------------------------
     0 | John CEO    | Executive   | 100000.00| John CEO
     1 | Alice VP    | Engineering |  80000.00| John CEO → Alice VP
     1 | Eve VP      | Marketing   |  75000.00| John CEO → Eve VP
     2 | Bob Manager | Engineering |  60000.00| John CEO → Alice VP → Bob Manager
     2 | Frank Manager| Marketing  |  55000.00| John CEO → Eve VP → Frank Manager
     3 | Carol Dev   | Engineering |  50000.00| John CEO → Alice VP → Bob Manager → Carol Dev
     3 | David Dev   | Engineering |  52000.00| John CEO → Alice VP → Bob Manager → David Dev
     3 | Grace Specialist| Marketing|  45000.00| John CEO → Eve VP → Frank Manager → Grace Specialist

-- Clean up
DROP TABLE IF EXISTS employees CASCADE; 
----------------------------------------
[SUCCESS] Completed: 01-employee-hierarchy.sql

========================================
[SUCCESS] Completed quest: recursive-cte, category: 01-hierarchical-graph-traversal
```

### **PostgreSQL Output Configuration**

The script configures PostgreSQL to display all output without truncation:

- **`\pset pager off`** - Disables the pager, showing all results immediately
- **`\pset format unaligned`** - Uses unaligned format for better readability
- **`\pset fieldsep ' | '`** - Uses pipe separators between columns
- **`\pset null '(null)'`** - Shows null values clearly
- **`\pset tuples_only off`** - Shows column headers and row counts
- **`\pset title on`** - Shows query titles
- **`\pset tableattr 'border=1'`** - Adds borders to tables

This ensures that **all rows are displayed**, even for queries that return hundreds or thousands of results.

### **Quiet Mode Output**
```
[INFO] Loading configuration from .env
[INFO] Running quest: recursive-cte, category: 01-hierarchical-graph-traversal
[SUCCESS] Completed: 01-employee-hierarchy.sql
[SUCCESS] Completed: 02-bill-of-materials.sql
[SUCCESS] Completed: 03-category-tree.sql
[SUCCESS] Completed: 04-graph-reachability.sql
[SUCCESS] Completed: 05-dependency-resolution.sql
[SUCCESS] Completed: 06-filesystem-hierarchy.sql
[SUCCESS] Completed: 07-family-tree.sql
[SUCCESS] Completed quest: recursive-cte, category: 01-hierarchical-graph-traversal
```

## 🔧 **Command Options**

### **Commands**
- `quest <name> [category]` - Run examples in a specific quest
- `list [quest]` - List available quests and examples
- `example <file>` - Run a specific example file
- `test` - Test database connection
- `config` - Show current configuration

### **Options**
- `-h, --host HOST` - Database host (overrides .env)
- `-p, --port PORT` - Database port (overrides .env)
- `-u, --user USER` - Database user (overrides .env)
- `-d, --database DB` - Database name (overrides .env)
- `-w, --password PASS` - Database password (overrides .env)
- `-v, --verbose` - Show SQL output (default: true)
- `-q, --quiet` - Hide SQL output, show only status
- `--help` - Show help message

## 📊 **Use Cases**

### **Initial Setup**
```bash
# 1. Copy environment configuration
cp env.example .env

# 2. Test database connection
./scripts/run-examples.sh test

# 3. Show current configuration
./scripts/run-examples.sh config

# 4. Run examples
./scripts/run-examples.sh quest recursive-cte
```

### **Learning and Debugging**
```bash
# Use verbose mode to see full output and understand what's happening
./scripts/run-examples.sh -v example quests/recursive-cte/01-hierarchical-graph-traversal/01-employee-hierarchy.sql
```

### **Batch Processing**
```bash
# Use quiet mode for running many examples quickly
./scripts/run-examples.sh -q quest recursive-cte
```

### **Testing**
```bash
# Run specific categories to test functionality
./scripts/run-examples.sh quest recursive-cte 02-iteration-loops
```

### **Development**
```bash
# Run individual examples during development
./scripts/run-examples.sh example quests/recursive-cte/01-hierarchical-graph-traversal/01-employee-hierarchy.sql
```

## ⚠️ **Prerequisites**

1. **Docker Containers Running**
   ```bash
   docker-compose up -d
   ```

2. **Environment Configuration**
   ```bash
   # Copy example configuration
   cp env.example .env
   
   # Customize if needed
   nano .env
   ```

3. **Database Access**
   - PostgreSQL must be running and accessible
   - Credentials loaded from .env file
   - Default credentials: postgres/postgres

4. **Script Permissions**
   ```bash
   chmod +x scripts/run-examples.sh
   ```

## 🔍 **Troubleshooting**

### **Common Issues**

**No .env File Found**
```bash
[WARNING] No .env file found, using default values
[INFO] You can copy env.example to .env and customize the settings
```
**Solution**: Copy `env.example` to `.env` and customize as needed.

**Connection Refused**
```bash
[ERROR] Database connection failed
[ERROR] Please check:
[ERROR]   1. Docker containers are running: docker-compose up -d
[ERROR]   2. Database credentials in .env file
[ERROR]   3. Database host and port settings
```
**Solution**: 
```bash
# Check if containers are running
docker-compose ps

# Test connection manually
PGPASSWORD=postgres psql -h localhost -p 5433 -U postgres -d sql_adventure_db -c "SELECT 1;"
```

**Permission Denied**
```bash
# Make script executable
chmod +x scripts/run-examples.sh
```

**File Not Found**
```bash
# Check if example file exists
ls -la quests/recursive-cte/01-hierarchical-graph-traversal/
```

### **Debug Mode**
```bash
# Run with bash debugging
bash -x ./scripts/run-examples.sh quest recursive-cte
```

## 📈 **Performance Tips**

### **For Large Quests**
- Use quiet mode (`-q`) for faster execution
- Run specific categories instead of entire quests
- Monitor database performance during execution

### **For Development**
- Use verbose mode (`-v`) to see detailed output
- Run individual examples for focused testing
- Check error messages for debugging

### **For Production**
- Ensure .env file has correct production credentials
- Use quiet mode for automated scripts
- Test connection before running examples

### **Output Display**
- **Long Tables**: All rows are automatically displayed without truncation
- **Large Results**: The script disables paging to show complete output
- **Format**: Results use pipe-separated format for easy reading
- **Null Values**: Clearly marked as `(null)` for visibility

---

*The run-examples script provides flexible execution with automatic configuration loading and full SQL output visibility! 🚀* 