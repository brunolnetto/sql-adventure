-- Performance Tuning Quest: Query Planning Basics
-- PURPOSE: Demonstrate fundamental query planning concepts for beginners
-- DIFFICULTY: 🟢 Beginner (5-10 min)
-- CONCEPTS: EXPLAIN, query plans, basic optimization, execution analysis

-- Example 1: Understanding EXPLAIN
-- Demonstrate using EXPLAIN to understand query execution

-- Create sample tables
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    department VARCHAR(50),
    salary DECIMAL(10,2),
    hire_date DATE,
    manager_id INT
);

CREATE TABLE departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(100),
    location VARCHAR(100),
    budget DECIMAL(12,2)
);

-- Insert sample data
INSERT INTO departments VALUES
(1, 'Engineering', 'Building A', 1000000.00),
(2, 'Marketing', 'Building B', 500000.00),
(3, 'Sales', 'Building C', 750000.00);

INSERT INTO employees VALUES
(1, 'John', 'Doe', 'john.doe@company.com', 'Engineering', 75000.00, '2023-01-15', NULL),
(2, 'Jane', 'Smith', 'jane.smith@company.com', 'Marketing', 65000.00, '2023-02-20', 1),
(3, 'Bob', 'Wilson', 'bob.wilson@company.com', 'Sales', 70000.00, '2023-03-10', 1),
(4, 'Alice', 'Johnson', 'alice.johnson@company.com', 'Engineering', 80000.00, '2023-04-05', 2),
(5, 'Charlie', 'Brown', 'charlie.brown@company.com', 'Marketing', 60000.00, '2023-05-12', 2);

-- Create indexes
CREATE INDEX idx_employees_department ON employees(department);
CREATE INDEX idx_employees_salary ON employees(salary);

-- Example 2: Basic EXPLAIN Analysis
-- Demonstrate analyzing simple query plans

-- Simple query with EXPLAIN
EXPLAIN SELECT * FROM employees WHERE department = 'Engineering';

-- Query with JOIN and EXPLAIN
EXPLAIN SELECT 
    e.first_name,
    e.last_name,
    e.salary,
    d.department_name
FROM employees e
JOIN departments d ON e.department = d.department_name
WHERE e.salary > 70000;

-- Example 3: EXPLAIN ANALYZE
-- Demonstrate using EXPLAIN ANALYZE for detailed analysis

-- Query with EXPLAIN ANALYZE
EXPLAIN (ANALYZE, BUFFERS) 
SELECT 
    department,
    COUNT(*) as employee_count,
    AVG(salary) as avg_salary
FROM employees
GROUP BY department
ORDER BY avg_salary DESC;

-- Example 4: Comparing Query Plans
-- Demonstrate comparing different query approaches

-- Query 1: Without index
EXPLAIN SELECT * FROM employees WHERE salary > 70000;

-- Query 2: With index
EXPLAIN SELECT * FROM employees WHERE department = 'Engineering';

-- Query 3: Complex query
EXPLAIN SELECT 
    e.first_name,
    e.last_name,
    e.salary,
    d.department_name,
    d.budget
FROM employees e
JOIN departments d ON e.department = d.department_name
WHERE e.salary > 65000
  AND d.budget > 600000
ORDER BY e.salary DESC;

-- Example 5: Understanding Plan Components
-- Demonstrate understanding different plan operations

-- Sequential Scan
EXPLAIN SELECT * FROM employees;

-- Index Scan
EXPLAIN SELECT * FROM employees WHERE employee_id = 1;

-- Index Only Scan
EXPLAIN SELECT employee_id, department FROM employees WHERE department = 'Engineering';

-- Hash Join
EXPLAIN SELECT 
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e
JOIN departments d ON e.department = d.department_name;

-- Example 6: Performance Comparison
-- Demonstrate comparing query performance

-- Slow query (no index on salary range)
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM employees 
WHERE salary BETWEEN 60000 AND 80000;

-- Fast query (using indexed column)
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM employees 
WHERE department = 'Engineering';

-- Example 7: Optimization Tips
-- Demonstrate basic optimization techniques

-- POOR: Using function in WHERE clause
EXPLAIN SELECT * FROM employees WHERE UPPER(department) = 'ENGINEERING';

-- BETTER: Direct comparison
EXPLAIN SELECT * FROM employees WHERE department = 'Engineering';

-- POOR: Selecting all columns
EXPLAIN SELECT * FROM employees WHERE department = 'Engineering';

-- BETTER: Selecting only needed columns
EXPLAIN SELECT first_name, last_name, salary FROM employees WHERE department = 'Engineering';

-- Example 8: Reading EXPLAIN Output
-- Demonstrate interpreting EXPLAIN results

-- Query with detailed EXPLAIN
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) 
SELECT 
    e.first_name,
    e.last_name,
    e.salary,
    d.department_name
FROM employees e
JOIN departments d ON e.department = d.department_name
WHERE e.salary > 70000
ORDER BY e.salary DESC;

-- Key metrics to look for:
-- - Planning time
-- - Execution time
-- - Rows returned vs rows scanned
-- - Buffer usage
-- - Index usage

-- Clean up
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE; 