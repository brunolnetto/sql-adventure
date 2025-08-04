-- =====================================================
-- JSON Operations: JSON Generation
-- =====================================================
-- 
-- PURPOSE: Demonstrate JSON generation techniques in PostgreSQL
--          for creating JSON objects, arrays, and complex structures
--          from relational data and aggregations
-- LEARNING OUTCOMES:
--   - Generate JSON objects from relational data
--   - Create JSON arrays from query results
--   - Build nested JSON structures with aggregations
--   - Combine multiple JSON generation functions
--   - Create complex JSON responses for APIs
-- EXPECTED RESULTS: Generate JSON data from relational structures
-- DIFFICULTY: 🟢 Beginner (5-10 min)
-- CONCEPTS: JSON generation, aggregation, nested structures, API responses

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

-- Create departments table
CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(100),
    location VARCHAR(100)
);

-- Create employees table
CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    salary DECIMAL(10,2),
    dept_id INT REFERENCES departments(dept_id)
);

-- Insert sample data
INSERT INTO departments VALUES
(1, 'Engineering', 'New York'),
(2, 'Marketing', 'Los Angeles'),
(3, 'Sales', 'Chicago');

INSERT INTO employees VALUES
(1, 'John', 'Smith', 'john.smith@company.com', 75000.00, 1),
(2, 'Sarah', 'Johnson', 'sarah.johnson@company.com', 65000.00, 2),
(3, 'Mike', 'Davis', 'mike.davis@company.com', 80000.00, 1),
(4, 'Lisa', 'Wilson', 'lisa.wilson@company.com', 70000.00, 3);

-- Example 1: Basic JSON Object Generation
-- Generate JSON objects from employee data
SELECT 
    emp_id,
    jsonb_build_object(
        'id', emp_id,
        'name', first_name || ' ' || last_name,
        'email', email,
        'salary', salary
    ) as employee_json
FROM employees
ORDER BY emp_id;

-- Example 2: JSON Array Generation
-- Generate JSON arrays from query results
SELECT 
    d.dept_id,
    d.dept_name,
    jsonb_agg(
        jsonb_build_object(
            'id', emp_id,
            'name', first_name || ' ' || last_name,
            'email', email
        )
    ) as employees_array
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY d.dept_id;

-- Example 3: Nested JSON Structure Generation
-- Create complex nested JSON with department and employee data
SELECT 
    jsonb_build_object(
        'department_id', d.dept_id,
        'department_name', d.dept_name,
        'location', d.location,
        'employee_count', COUNT(e.emp_id),
        'employees', jsonb_agg(
            CASE 
                WHEN e.emp_id IS NOT NULL THEN
                    jsonb_build_object(
                        'id', e.emp_id,
                        'name', e.first_name || ' ' || e.last_name,
                        'email', e.email,
                        'salary', e.salary
                    )
                ELSE NULL
            END
        ) FILTER (WHERE e.emp_id IS NOT NULL)
    ) as department_json
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name, d.location
ORDER BY d.dept_id;

-- Example 4: JSON with Aggregated Data
-- Generate JSON with calculated statistics
SELECT 
    d.dept_id,
    d.dept_name,
    jsonb_build_object(
        'department_info', jsonb_build_object(
            'id', d.dept_id,
            'name', d.dept_name,
            'location', d.location
        ),
        'employee_stats', jsonb_build_object(
            'total_employees', COUNT(e.emp_id),
            'avg_salary', ROUND(AVG(e.salary), 2),
            'min_salary', MIN(e.salary),
            'max_salary', MAX(e.salary)
        ),
        'employees', jsonb_agg(
            jsonb_build_object(
                'id', e.emp_id,
                'name', e.first_name || ' ' || e.last_name,
                'salary', e.salary
            )
        ) FILTER (WHERE e.emp_id IS NOT NULL)
    ) as department_summary
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name, d.location
ORDER BY d.dept_id;

-- Clean up
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE; 