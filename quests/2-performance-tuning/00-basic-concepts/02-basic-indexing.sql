-- Performance Tuning Quest: Basic Indexing
-- PURPOSE: Demonstrate fundamental indexing concepts for beginners
-- DIFFICULTY: 🟢 Beginner (5-10 min)
-- CONCEPTS: Basic indexes, index types, when to use indexes

-- Example 1: Creating Basic Indexes
-- Demonstrate creating indexes on commonly queried columns

-- Create sample tables
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    department VARCHAR(50),
    salary DECIMAL(10, 2),
    hire_date DATE,
    manager_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(100),
    location VARCHAR(100),
    budget DECIMAL(12, 2)
);

-- Insert sample data
INSERT INTO departments VALUES
(1, 'Engineering', 'Building A', 1000000.00),
(2, 'Marketing', 'Building B', 500000.00),
(3, 'Sales', 'Building C', 750000.00);

INSERT INTO employees VALUES
(
    1,
    'John',
    'Doe',
    'john.doe@company.com',
    'Engineering',
    75000.00,
    '2023-01-15',
    NULL
),
(
    2,
    'Jane',
    'Smith',
    'jane.smith@company.com',
    'Marketing',
    65000.00,
    '2023-02-20',
    1
),
(
    3,
    'Bob',
    'Wilson',
    'bob.wilson@company.com',
    'Sales',
    70000.00,
    '2023-03-10',
    1
),
(
    4,
    'Alice',
    'Johnson',
    'alice.johnson@company.com',
    'Engineering',
    80000.00,
    '2023-04-05',
    2
),
(
    5,
    'Charlie',
    'Brown',
    'charlie.brown@company.com',
    'Marketing',
    60000.00,
    '2023-05-12',
    2
);

-- Create indexes on commonly queried columns
CREATE INDEX idx_employees_department ON employees (department);
CREATE INDEX idx_employees_salary ON employees (salary);
CREATE INDEX idx_employees_hire_date ON employees (hire_date);
CREATE INDEX idx_employees_manager ON employees (manager_id);

-- Example 2: Query Performance with Indexes
-- Demonstrate how indexes improve query performance

-- Query that benefits from department index
SELECT
    employee_id,
    first_name,
    last_name,
    salary
FROM employees
WHERE department = 'Engineering';

-- Query that benefits from salary index
SELECT
    employee_id,
    first_name,
    last_name,
    department
FROM employees
WHERE salary > 70000;

-- Query that benefits from hire_date index
SELECT
    employee_id,
    first_name,
    last_name,
    hire_date
FROM employees
WHERE hire_date >= '2023-01-01';

-- Example 3: Composite Indexes
-- Demonstrate creating indexes on multiple columns

-- Create composite index for department + salary queries
CREATE INDEX idx_employees_dept_salary ON employees (department, salary);

-- Query that benefits from composite index
SELECT
    employee_id,
    first_name,
    last_name,
    salary
FROM employees
WHERE department = 'Engineering' AND salary > 70000;

-- Example 4: When NOT to Use Indexes
-- Demonstrate scenarios where indexes are not beneficial

-- Small table - indexes may not help
CREATE TABLE small_table (
    id INT PRIMARY KEY,
    name VARCHAR(50)
);

INSERT INTO small_table VALUES
(1, 'Item 1'),
(2, 'Item 2'),
(3, 'Item 3');

-- For small tables, full table scan might be faster than index lookup
SELECT * FROM small_table
WHERE name = 'Item 2';

-- Example 5: Index Maintenance
-- Demonstrate checking and maintaining indexes

-- Check existing indexes
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename IN ('employees', 'departments')
ORDER BY tablename, indexname;

-- Check index usage statistics
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE tablename IN ('employees', 'departments')
ORDER BY idx_scan DESC;

-- Example 6: Performance Comparison
-- Demonstrate the difference with and without indexes

-- Query without specific index (will use primary key)
SELECT
    employee_id,
    first_name,
    last_name
FROM employees
WHERE employee_id = 1;

-- Query that uses department index
SELECT
    employee_id,
    first_name,
    last_name
FROM employees
WHERE department = 'Engineering';

-- Clean up
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS small_table CASCADE;
