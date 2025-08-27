-- Data Modeling Quest: Data Integrity
-- PURPOSE: Demonstrate data integrity principles, constraints, triggers, and validation
-- DIFFICULTY: 🟡 Intermediate (15-20 min)
-- CONCEPTS: Data integrity, constraints, triggers, validation, business rules

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

-- Function to validate employee hierarchy
CREATE OR REPLACE FUNCTION VALIDATE_EMPLOYEE_HIERARCHY()
RETURNS TRIGGER AS $$
BEGIN
    -- Prevent circular references
    IF NEW.manager_id = NEW.employee_id THEN
        RAISE EXCEPTION 'Employee cannot be their own manager';
    END IF;
    
    -- Check if manager exists and is active
    IF NEW.manager_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM employees WHERE employee_id = NEW.manager_id AND status = 'active') THEN
            RAISE EXCEPTION 'Manager must be an active employee';
        END IF;
    END IF;
    
    -- Check hierarchy depth (max 5 levels)
    IF NEW.manager_id IS NOT NULL THEN
        WITH RECURSIVE hierarchy_check AS (
            SELECT employee_id, manager_id, 1 as level
            FROM employees
            WHERE employee_id = NEW.manager_id
            
            UNION ALL
            
            SELECT e.employee_id, e.manager_id, hc.level + 1
            FROM employees e
            JOIN hierarchy_check hc ON e.employee_id = hc.manager_id
            WHERE hc.level < 5
        )
        SELECT level INTO NEW.level
        FROM hierarchy_check
        WHERE manager_id IS NULL;
        
        IF NEW.level > 5 THEN
            RAISE EXCEPTION 'Hierarchy depth cannot exceed 5 levels';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for employee hierarchy validation
CREATE TRIGGER trigger_validate_employee_hierarchy
BEFORE INSERT OR UPDATE ON employees
FOR EACH ROW EXECUTE FUNCTION VALIDATE_EMPLOYEE_HIERARCHY();

-- Example 3: Data Validation Triggers
-- Demonstrate comprehensive data validation

-- Function to validate project assignments
CREATE OR REPLACE FUNCTION VALIDATE_PROJECT_ASSIGNMENT()
RETURNS TRIGGER AS $$
DECLARE
    total_hours DECIMAL(4,2);
    project_status VARCHAR(20);
    employee_status VARCHAR(20);
    annual_salary DECIMAL(10,2);
    max_hourly_rate DECIMAL(8,2);
BEGIN
    -- Check if project is active
    SELECT status INTO project_status
    FROM projects
    WHERE project_id = NEW.project_id;
    
    IF project_status != 'active' THEN
        RAISE EXCEPTION 'Cannot assign employee to inactive project';
    END IF;
    
    -- Check if employee is active
    SELECT status INTO employee_status
    FROM employees
    WHERE employee_id = NEW.employee_id;
    
    IF employee_status != 'active' THEN
        RAISE EXCEPTION 'Cannot assign inactive employee to project';
    END IF;
    
    -- Check total hours per week (max 60 hours)
    SELECT COALESCE(SUM(hours_per_week), 0) INTO total_hours
    FROM employee_projects
    WHERE employee_id = NEW.employee_id
    AND (end_date IS NULL OR end_date >= CURRENT_DATE)
    AND (project_id != NEW.project_id OR TG_OP = 'UPDATE');
    
    IF (total_hours + NEW.hours_per_week) > 60 THEN
        RAISE EXCEPTION 'Total hours per week cannot exceed 60 (current: %, new: %)', total_hours, NEW.hours_per_week;
    END IF;
    
    -- Validate hourly rate against employee salary
    IF NEW.hourly_rate > 0 THEN
        SELECT salary INTO annual_salary
        FROM employees
        WHERE employee_id = NEW.employee_id;
        
        -- Assume 2080 hours per year (40 hours/week * 52 weeks)
        max_hourly_rate := annual_salary / 2080;
        
        IF NEW.hourly_rate > max_hourly_rate * 1.5 THEN
            RAISE EXCEPTION 'Hourly rate (%) exceeds reasonable limit (%)', NEW.hourly_rate, max_hourly_rate * 1.5;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for project assignment validation
CREATE TRIGGER trigger_validate_project_assignment
BEFORE INSERT OR UPDATE ON employee_projects
FOR EACH ROW EXECUTE FUNCTION VALIDATE_PROJECT_ASSIGNMENT();

-- Example 4: Audit Trail and Change Tracking
-- Demonstrate audit trail functionality

-- Create audit table
CREATE TABLE employee_audit (
    audit_id BIGSERIAL PRIMARY KEY,
    employee_id INT NOT NULL,
    change_type VARCHAR(20) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    changed_by VARCHAR(100) DEFAULT CURRENT_USER,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    old_values JSONB,
    new_values JSONB
);

-- Function to create audit trail
CREATE OR REPLACE FUNCTION AUDIT_EMPLOYEE_CHANGES()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO employee_audit (employee_id, change_type, new_values)
        VALUES (NEW.employee_id, 'INSERT', to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO employee_audit (employee_id, change_type, old_values, new_values)
        VALUES (NEW.employee_id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO employee_audit (employee_id, change_type, old_values)
        VALUES (OLD.employee_id, 'DELETE', to_jsonb(OLD));
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create audit trigger
CREATE TRIGGER trigger_audit_employee_changes
AFTER INSERT OR UPDATE OR DELETE ON employees
FOR EACH ROW EXECUTE FUNCTION AUDIT_EMPLOYEE_CHANGES();

-- Example 5: Data Integrity Validation Queries
-- Demonstrate how to validate data integrity

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

-- Test the validation triggers
-- Note: The following INSERT statements are commented out to avoid execution errors
-- They would normally demonstrate constraint violations but require specific table states

-- Test audit trail
UPDATE employees
SET salary = salary * 1.05
WHERE employee_id = 1;

-- View audit trail
SELECT
    ea.employee_id,
    ea.change_type,
    ea.changed_by,
    ea.changed_at,
    ea.old_values,
    ea.new_values,
    e.first_name || ' ' || e.last_name AS employee_name
FROM employee_audit AS ea
INNER JOIN employees AS e ON ea.employee_id = e.employee_id
ORDER BY ea.changed_at DESC;

-- Example 6: Business Rule Enforcement
-- Demonstrate complex business rules

-- Function to enforce budget constraints
CREATE OR REPLACE FUNCTION ENFORCE_BUDGET_CONSTRAINTS()
RETURNS TRIGGER AS $$
DECLARE
    department_budget DECIMAL(12,2);
    current_spending DECIMAL(12,2);
    project_cost DECIMAL(12,2);
BEGIN
    -- Get department budget
    SELECT budget INTO department_budget
    FROM departments
    WHERE department_id = NEW.department_id;
    
    -- Calculate current spending on active projects
    SELECT COALESCE(SUM(budget), 0) INTO current_spending
    FROM projects
    WHERE department_id = NEW.department_id 
    AND status = 'active'
    AND project_id != COALESCE(NEW.project_id, 0);
    
    -- Calculate project cost (including employee costs)
    SELECT COALESCE(SUM(ep.hours_per_week * ep.hourly_rate * 52), 0) INTO project_cost
    FROM employee_projects ep
    WHERE ep.project_id = NEW.project_id
    AND (ep.end_date IS NULL OR ep.end_date >= CURRENT_DATE);
    
    -- Check if total spending exceeds budget
    IF (current_spending + NEW.budget + project_cost) > department_budget THEN
        RAISE EXCEPTION 'Project budget would exceed department budget. Available: %, Required: %', 
            department_budget - current_spending, NEW.budget + project_cost;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for budget enforcement
CREATE TRIGGER trigger_enforce_budget_constraints
BEFORE INSERT OR UPDATE ON projects
FOR EACH ROW EXECUTE FUNCTION ENFORCE_BUDGET_CONSTRAINTS();

-- Clean up
DROP TABLE IF EXISTS employee_audit CASCADE;
DROP TABLE IF EXISTS employee_projects CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP VIEW IF EXISTS employee_hierarchy CASCADE;
DROP FUNCTION IF EXISTS validate_employee_hierarchy() CASCADE;
DROP FUNCTION IF EXISTS validate_project_assignment() CASCADE;
DROP FUNCTION IF EXISTS audit_employee_changes() CASCADE;
DROP FUNCTION IF EXISTS enforce_budget_constraints() CASCADE;
