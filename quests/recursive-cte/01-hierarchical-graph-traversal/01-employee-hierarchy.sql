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

-- Clean up
DROP TABLE IF EXISTS employees CASCADE; 