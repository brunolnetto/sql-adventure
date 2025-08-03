-- =====================================================
-- Performance Tuning: Execution Plan Analysis
-- =====================================================
-- 
-- PURPOSE: Demonstrate execution plan analysis techniques in PostgreSQL
--          for understanding query performance and optimization opportunities
-- LEARNING OUTCOMES:
--   - Read and interpret execution plans
--   - Identify performance bottlenecks in queries
--   - Understand different scan types and join methods
--   - Analyze plan costs and timing
--   - Optimize queries based on plan analysis
-- EXPECTED RESULTS: Analyze and optimize queries using execution plans
-- DIFFICULTY: 🔴 Advanced (15-20 min)
-- CONCEPTS: Execution plans, query analysis, performance bottlenecks, scan types, join methods

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS employee_projects CASCADE;

-- Create departments table
CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(100),
    location VARCHAR(100),
    budget DECIMAL(12,2)
);

-- Create employees table
CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    salary DECIMAL(10,2),
    hire_date DATE,
    dept_id INT REFERENCES departments(dept_id),
    manager_id INT REFERENCES employees(emp_id)
);

-- Create projects table
CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    start_date DATE,
    end_date DATE,
    budget DECIMAL(12,2),
    status VARCHAR(20)
);

-- Create employee_projects junction table
CREATE TABLE employee_projects (
    emp_id INT REFERENCES employees(emp_id),
    project_id INT REFERENCES projects(project_id),
    role VARCHAR(50),
    hours_worked INT,
    PRIMARY KEY (emp_id, project_id)
);

-- Insert sample data
INSERT INTO departments (dept_name, location, budget) VALUES
('Engineering', 'New York', 500000.00),
('Marketing', 'Los Angeles', 300000.00),
('Sales', 'Chicago', 400000.00),
('HR', 'Boston', 200000.00);

INSERT INTO employees (first_name, last_name, email, salary, hire_date, dept_id, manager_id) VALUES
('John', 'Smith', 'john.smith@company.com', 75000.00, '2020-01-15', 1, NULL),
('Sarah', 'Johnson', 'sarah.johnson@company.com', 65000.00, '2020-02-20', 2, NULL),
('Mike', 'Davis', 'mike.davis@company.com', 80000.00, '2020-03-10', 1, 1),
('Lisa', 'Wilson', 'lisa.wilson@company.com', 70000.00, '2020-04-05', 3, NULL),
('David', 'Brown', 'david.brown@company.com', 85000.00, '2020-05-12', 1, 1),
('Emma', 'Taylor', 'emma.taylor@company.com', 60000.00, '2020-06-01', 2, 2),
('James', 'Anderson', 'james.anderson@company.com', 90000.00, '2020-07-15', 1, 1);

INSERT INTO projects (project_name, start_date, end_date, budget, status) VALUES
('Website Redesign', '2024-01-01', '2024-06-30', 100000.00, 'active'),
('Mobile App Development', '2024-02-01', '2024-08-31', 150000.00, 'active'),
('Marketing Campaign', '2024-03-01', '2024-05-31', 50000.00, 'completed'),
('Database Migration', '2024-04-01', '2024-07-31', 75000.00, 'active');

INSERT INTO employee_projects (emp_id, project_id, role, hours_worked) VALUES
(1, 1, 'Project Manager', 120),
(3, 1, 'Developer', 200),
(5, 1, 'Designer', 150),
(1, 2, 'Project Manager', 80),
(3, 2, 'Developer', 300),
(7, 2, 'Developer', 250),
(2, 3, 'Marketing Lead', 100),
(6, 3, 'Content Creator', 80),
(1, 4, 'Project Manager', 60),
(5, 4, 'Database Admin', 180);

-- Example 1: Basic Execution Plan Analysis
-- Analyze a simple query execution plan
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT e.first_name, e.last_name, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 70000;

-- Example 2: Index vs Sequential Scan Comparison
-- Compare performance with and without indexes
-- First, show plan without index
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT emp_id, first_name, last_name, salary
FROM employees
WHERE salary BETWEEN 60000 AND 80000;

-- Create index and show improved plan
CREATE INDEX idx_employees_salary ON employees(salary);

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT emp_id, first_name, last_name, salary
FROM employees
WHERE salary BETWEEN 60000 AND 80000;

-- Example 3: Join Method Analysis
-- Analyze different join methods
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT e.first_name, e.last_name, p.project_name, ep.role
FROM employees e
JOIN employee_projects ep ON e.emp_id = ep.emp_id
JOIN projects p ON ep.project_id = p.project_id
WHERE e.dept_id = 1 AND p.status = 'active';

-- Example 4: Subquery vs JOIN Performance
-- Compare subquery and JOIN approaches
-- Subquery approach
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT d.dept_name, 
       (SELECT COUNT(*) FROM employees e WHERE e.dept_id = d.dept_id) as emp_count
FROM departments d;

-- JOIN approach
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT d.dept_name, COUNT(e.emp_id) as emp_count
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

-- Example 5: Aggregation Performance Analysis
-- Analyze aggregation query performance
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT d.dept_name,
       AVG(e.salary) as avg_salary,
       COUNT(e.emp_id) as employee_count,
       SUM(ep.hours_worked) as total_hours
FROM departments d
JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN employee_projects ep ON e.emp_id = ep.emp_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 65000;

-- Example 6: Complex Query Plan Analysis
-- Analyze a complex query with multiple joins and conditions
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    e.first_name,
    e.last_name,
    d.dept_name,
    p.project_name,
    ep.role,
    ep.hours_worked,
    ROUND(ep.hours_worked * e.salary / 2080, 2) as project_cost
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
JOIN employee_projects ep ON e.emp_id = ep.emp_id
JOIN projects p ON ep.project_id = p.project_id
WHERE e.salary > 70000 
  AND p.status = 'active'
  AND ep.hours_worked > 100
ORDER BY project_cost DESC;

-- Clean up
DROP TABLE IF EXISTS employee_projects CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE; 