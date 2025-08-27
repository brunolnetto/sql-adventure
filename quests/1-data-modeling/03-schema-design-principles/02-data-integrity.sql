-- Data Modeling Quest: Data Integrity
-- PURPOSE: Demonstrate data integrity principles, constraints, triggers, and validation
-- DIFFICULTY: 🟡 Intermediate (15-20 min)
-- CONCEPTS: Data integrity, constraints, triggers, validation, business rules

-- Clean up any existing tables from previous runs
DROP TABLE IF EXISTS employee_projects CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP VIEW IF EXISTS employee_hierarchy CASCADE;

-- Example 1: Comprehensive Data Integrity Constraints
-- Demonstrate various types of constraints for data integrity

CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    employee_number VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    hire_date DATE NOT NULL DEFAULT CURRENT_DATE,
    salary DECIMAL(10, 2) NOT NULL CHECK (salary > 0),
    manager_id INT REFERENCES employees (employee_id),
    department_id INT,
    status VARCHAR(20) DEFAULT 'active' CHECK (
        status IN ('active', 'inactive', 'terminated', 'retired')
    ),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(100) UNIQUE NOT NULL,
    department_code VARCHAR(10) UNIQUE NOT NULL,
    manager_id INT REFERENCES employees (employee_id),
    budget DECIMAL(12, 2) CHECK (budget >= 0),
    location VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE projects (
    project_id INT PRIMARY KEY,
    project_name VARCHAR(200) NOT NULL,
    project_code VARCHAR(20) UNIQUE NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE,
    budget DECIMAL(12, 2) CHECK (budget > 0),
    status VARCHAR(20) DEFAULT 'active' CHECK (
        status IN ('active', 'completed', 'cancelled', 'on-hold')
    ),
    manager_id INT REFERENCES employees (employee_id),
    department_id INT REFERENCES departments (department_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_project_dates CHECK (
        end_date IS NULL OR end_date >= start_date
    )
);

CREATE TABLE employee_projects (
    employee_id INT REFERENCES employees (employee_id),
    project_id INT REFERENCES projects (project_id),
    role VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE,
    hours_per_week DECIMAL(4, 2) CHECK (
        hours_per_week > 0 AND hours_per_week <= 168
    ),
    hourly_rate DECIMAL(8, 2) CHECK (hourly_rate >= 0),
    PRIMARY KEY (employee_id, project_id, role),
    CONSTRAINT valid_assignment_dates CHECK (
        end_date IS NULL OR end_date >= start_date
    )
);

-- Insert sample data
INSERT INTO departments VALUES
(1, 'Engineering', 'ENG', NULL, 1000000.00, 'Building A, Floor 2'),
(2, 'Marketing', 'MKT', NULL, 500000.00, 'Building B, Floor 1'),
(3, 'Finance', 'FIN', NULL, 300000.00, 'Building A, Floor 1');

INSERT INTO employees VALUES
(
    1,
    'EMP001',
    'John',
    'Smith',
    'john.smith@company.com',
    '555-1001',
    '2020-01-15',
    75000.00,
    NULL,
    1,
    'active'
),
(
    2,
    'EMP002',
    'Sarah',
    'Johnson',
    'sarah.johnson@company.com',
    '555-1002',
    '2020-03-20',
    65000.00,
    1,
    1,
    'active'
),
(
    3,
    'EMP003',
    'Michael',
    'Brown',
    'michael.brown@company.com',
    '555-1003',
    '2021-06-10',
    80000.00,
    1,
    2,
    'active'
),
(
    4,
    'EMP004',
    'Lisa',
    'Davis',
    'lisa.davis@company.com',
    '555-1004',
    '2021-08-05',
    70000.00,
    3,
    3,
    'active'
);

-- Update departments with managers
UPDATE departments SET manager_id = 1
WHERE department_id = 1;
UPDATE departments SET manager_id = 3
WHERE department_id = 2;
UPDATE departments SET manager_id = 4
WHERE department_id = 3;

INSERT INTO projects VALUES
(
    1,
    'Database Migration',
    'DB-MIG-2024',
    'Migrate legacy system to PostgreSQL',
    '2024-01-01',
    '2024-06-30',
    150000.00,
    'active',
    1,
    1
),
(
    2,
    'Website Redesign',
    'WEB-RED-2024',
    'Redesign company website',
    '2024-02-01',
    '2024-08-31',
    200000.00,
    'active',
    3,
    2
),
(
    3,
    'Financial System Upgrade',
    'FIN-UPG-2024',
    'Upgrade financial reporting system',
    '2024-03-01',
    '2024-12-31',
    300000.00,
    'active',
    4,
    3
);

INSERT INTO employee_projects VALUES
(1, 1, 'Project Manager', '2024-01-01', '2024-06-30', 40.0, 45.00),
(2, 1, 'Developer', '2024-01-01', '2024-06-30', 35.0, 35.00),
(3, 2, 'Project Manager', '2024-02-01', '2024-08-31', 40.0, 50.00),
(4, 3, 'Project Manager', '2024-03-01', '2024-12-31', 40.0, 45.00);

-- Example 2: Advanced Constraints and Business Rules
-- Demonstrate complex business rules using constraints

-- Add foreign key constraint for employees.department_id
ALTER TABLE employees ADD CONSTRAINT fk_employees_department
FOREIGN KEY (department_id) REFERENCES departments (department_id);

-- Create a view for employee hierarchy validation
CREATE VIEW employee_hierarchy AS
WITH RECURSIVE emp_hierarchy AS (
    -- Base case: employees without managers (top level)
    SELECT
        employee_id,
        first_name,
        last_name,
        manager_id,
        0 AS level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive case: employees with managers
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        eh.level + 1
    FROM employees AS e
    INNER JOIN emp_hierarchy AS eh ON e.manager_id = eh.employee_id
    WHERE eh.level < 10 -- Prevent infinite recursion
)

SELECT * FROM emp_hierarchy;

-- Example 2: Data Integrity through CHECK Constraints and Validation
-- Demonstrate data integrity using CHECK constraints and basic validation

-- Note: For production use, you would implement triggers and functions to
-- automatically validate data integrity rules. Here we demonstrate the concepts
-- through CHECK constraints and manual validation.

-- Test the constraints with sample data
INSERT INTO employees VALUES
(1, 'EMP001', 'John', 'Doe', 'john.doe@company.com', '555-0101', '2020-01-15', 75000.00, null, 1, 'active')
ON CONFLICT (employee_id) DO NOTHING;

INSERT INTO employees VALUES
(2, 'EMP002', 'Jane', 'Smith', 'jane.smith@company.com', '555-0102', '2020-02-01', 80000.00, 1, 1, 'active')
ON CONFLICT (employee_id) DO NOTHING;

INSERT INTO employees VALUES
(3, 'EMP003', 'Bob', 'Johnson', 'bob.johnson@company.com', '555-0103', '2020-03-01', 70000.00, 1, 2, 'active')
ON CONFLICT (employee_id) DO NOTHING;

INSERT INTO departments VALUES
(1, 'Engineering', 'ENG', 2, 500000.00, 'Building A')
ON CONFLICT (department_id) DO NOTHING;

INSERT INTO departments VALUES
(2, 'Marketing', 'MKT', 3, 300000.00, 'Building B')
ON CONFLICT (department_id) DO NOTHING;;

INSERT INTO projects VALUES
(1, 'Website Redesign', 'WEB-RED-2024', 'Complete website overhaul', '2024-01-01', '2024-06-30', 150000.00, 'active', 2, 1)
ON CONFLICT (project_id) DO NOTHING;

INSERT INTO projects VALUES
(2, 'Mobile App Development', 'MOBILE-2024', 'Native mobile application', '2024-02-01', '2024-08-31', 200000.00, 'active', 3, 1)
ON CONFLICT (project_id) DO NOTHING;;

-- Example 3: Data Integrity Validation
-- Demonstrate data integrity validation through queries

-- Check for data integrity violations
SELECT
    'Employees without departments' AS issue,
    COUNT(*) AS count
FROM employees
WHERE department_id IS NULL AND status = 'active'
UNION ALL
SELECT
    'Departments without managers' AS issue,
    COUNT(*) AS count
FROM departments
WHERE manager_id IS NULL
UNION ALL
SELECT
    'Projects without managers' AS issue,
    COUNT(*) AS count
FROM projects
WHERE manager_id IS NULL AND status = 'active'
UNION ALL
SELECT
    'Invalid project dates' AS issue,
    COUNT(*) AS count
FROM projects
WHERE end_date < start_date;

-- Example 4: Business Rule Validation
-- Demonstrate business rule validation through queries

-- Validate salary ranges by department
SELECT
    d.department_name,
    COUNT(e.employee_id) AS employee_count,
    MIN(e.salary) AS min_salary,
    MAX(e.salary) AS max_salary,
    ROUND(AVG(e.salary), 2) AS avg_salary
FROM departments AS d
LEFT JOIN employees AS e ON d.department_id = e.department_id AND e.status = 'active'
GROUP BY d.department_id, d.department_name
ORDER BY avg_salary DESC;

-- Check for data integrity violations
SELECT
    'Employees without departments' AS issue,
    COUNT(*) AS count
FROM employees
WHERE department_id IS NULL AND status = 'active'
UNION ALL
SELECT
    'Departments without managers' AS issue,
    COUNT(*) AS count
FROM departments
WHERE manager_id IS NULL
UNION ALL
SELECT
    'Projects without managers' AS issue,
    COUNT(*) AS count
FROM projects
WHERE manager_id IS NULL AND status = 'active'
UNION ALL
SELECT
    'Invalid project dates' AS issue,
    COUNT(*) AS count
FROM projects
WHERE end_date < start_date
UNION ALL
SELECT
    'Overworked employees' AS issue,
    COUNT(DISTINCT ep.employee_id) AS count
FROM employee_projects AS ep
WHERE ep.end_date IS NULL OR ep.end_date >= CURRENT_DATE
GROUP BY ep.employee_id
HAVING SUM(ep.hours_per_week) > 60;

-- Validate salary ranges by department
SELECT
    d.department_name,
    COUNT(e.employee_id) AS employee_count,
    MIN(e.salary) AS min_salary,
    MAX(e.salary) AS max_salary,
    ROUND(AVG(e.salary), 2) AS avg_salary,
    CASE
        WHEN
            MAX(e.salary) - MIN(e.salary) > AVG(e.salary) * 2
            THEN 'High variance'
        WHEN
            MAX(e.salary) - MIN(e.salary) > AVG(e.salary)
            THEN 'Medium variance'
        ELSE 'Low variance'
    END AS salary_variance
FROM departments AS d
LEFT JOIN
    employees AS e
    ON d.department_id = e.department_id AND e.status = 'active'
GROUP BY d.department_id, d.department_name
ORDER BY avg_salary DESC;

-- Test the constraints
-- Note: For production use, you would implement triggers and functions to
-- automatically validate data integrity rules. Here we demonstrate the concepts
-- through CHECK constraints and manual validation.

-- Example 4: Business Rule Validation
-- Demonstrate business rule validation through queries

-- Validate salary ranges by department
SELECT
    d.department_name,
    COUNT(e.employee_id) AS employee_count,
    MIN(e.salary) AS min_salary,
    MAX(e.salary) AS max_salary,
    ROUND(AVG(e.salary), 2) AS avg_salary
FROM departments AS d
LEFT JOIN employees AS e ON d.department_id = e.department_id AND e.status = 'active'
GROUP BY d.department_id, d.department_name
ORDER BY avg_salary DESC;

-- Clean up
DROP TABLE IF EXISTS employee_projects CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP VIEW IF EXISTS employee_hierarchy CASCADE;
