-- =====================================================
-- Window Functions: PERCENT_RANK and NTILE
-- =====================================================

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS employee_salaries CASCADE;

-- Create sample employee salaries table
CREATE TABLE employee_salaries (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100),
    department VARCHAR(50),
    salary DECIMAL(10,2),
    hire_date DATE
);

-- Insert sample data
INSERT INTO employee_salaries VALUES
(1, 'Alice Johnson', 'Engineering', 85000.00, '2020-01-15'),
(2, 'Bob Smith', 'Marketing', 65000.00, '2019-03-20'),
(3, 'Carol Davis', 'Engineering', 92000.00, '2018-07-10'),
(4, 'David Wilson', 'Sales', 75000.00, '2021-02-28'),
(5, 'Eve Brown', 'Engineering', 88000.00, '2020-11-05'),
(6, 'Frank Miller', 'Marketing', 62000.00, '2022-01-10'),
(7, 'Grace Lee', 'Sales', 78000.00, '2019-09-15'),
(8, 'Henry Taylor', 'Engineering', 95000.00, '2017-12-01'),
(9, 'Ivy Chen', 'Marketing', 68000.00, '2021-06-20'),
(10, 'Jack Anderson', 'Sales', 72000.00, '2020-08-12'),
(11, 'Kate Williams', 'Engineering', 87000.00, '2021-04-03'),
(12, 'Liam Garcia', 'Marketing', 63000.00, '2022-03-15');

-- =====================================================
-- Example 1: Basic PERCENT_RANK
-- =====================================================

-- Show percentile ranks for all employees
SELECT 
    employee_name,
    department,
    salary,
    ROUND(PERCENT_RANK() OVER (ORDER BY salary), 3) as percent_rank,
    ROUND(PERCENT_RANK() OVER (ORDER BY salary) * 100, 1) as percentile
FROM employee_salaries
ORDER BY salary;

-- =====================================================
-- Example 2: PERCENT_RANK by Department
-- =====================================================

-- Show percentile ranks within each department
SELECT 
    employee_name,
    department,
    salary,
    ROUND(PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary), 3) as dept_percent_rank,
    ROUND(PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) * 100, 1) as dept_percentile
FROM employee_salaries
ORDER BY department, salary;

-- =====================================================
-- Example 3: NTILE for Salary Quartiles
-- =====================================================

-- Divide employees into salary quartiles
SELECT 
    employee_name,
    department,
    salary,
    NTILE(4) OVER (ORDER BY salary) as salary_quartile,
    CASE NTILE(4) OVER (ORDER BY salary)
        WHEN 1 THEN 'Q1 (Lowest 25%)'
        WHEN 2 THEN 'Q2 (25-50%)'
        WHEN 3 THEN 'Q3 (50-75%)'
        WHEN 4 THEN 'Q4 (Highest 25%)'
    END as quartile_description
FROM employee_salaries
ORDER BY salary;

-- =====================================================
-- Example 4: NTILE by Department
-- =====================================================

-- Divide employees into tertiles (3 groups) within each department
SELECT 
    employee_name,
    department,
    salary,
    NTILE(3) OVER (PARTITION BY department ORDER BY salary) as dept_tertile,
    CASE NTILE(3) OVER (PARTITION BY department ORDER BY salary)
        WHEN 1 THEN 'Bottom Third'
        WHEN 2 THEN 'Middle Third'
        WHEN 3 THEN 'Top Third'
    END as tertile_description
FROM employee_salaries
ORDER BY department, salary;

-- =====================================================
-- Example 5: Multiple Percentile Functions
-- =====================================================

-- Compare different percentile functions
SELECT 
    employee_name,
    department,
    salary,
    ROUND(PERCENT_RANK() OVER (ORDER BY salary), 3) as overall_percent_rank,
    ROUND(PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary), 3) as dept_percent_rank,
    NTILE(5) OVER (ORDER BY salary) as salary_quintile,
    NTILE(10) OVER (ORDER BY salary) as salary_decile
FROM employee_salaries
ORDER BY salary;

-- =====================================================
-- Example 6: Salary Bands with NTILE
-- =====================================================

-- Create salary bands using NTILE
WITH salary_bands AS (
    SELECT 
        employee_name,
        department,
        salary,
        NTILE(5) OVER (ORDER BY salary) as salary_band
    FROM employee_salaries
)
SELECT 
    employee_name,
    department,
    salary,
    salary_band,
    CASE salary_band
        WHEN 1 THEN 'Band 1: $62K - $68K'
        WHEN 2 THEN 'Band 2: $68K - $78K'
        WHEN 3 THEN 'Band 3: $78K - $87K'
        WHEN 4 THEN 'Band 4: $87K - $92K'
        WHEN 5 THEN 'Band 5: $92K - $95K'
    END as band_description
FROM salary_bands
ORDER BY salary;

-- =====================================================
-- Example 7: Performance Tiers
-- =====================================================

-- Create performance tiers based on salary percentiles
SELECT 
    employee_name,
    department,
    salary,
    ROUND(PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) * 100, 1) as dept_percentile,
    CASE 
        WHEN PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) >= 0.8 THEN 'Top Performer'
        WHEN PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) >= 0.6 THEN 'High Performer'
        WHEN PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) >= 0.4 THEN 'Average Performer'
        WHEN PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) >= 0.2 THEN 'Below Average'
        ELSE 'Needs Improvement'
    END as performance_tier
FROM employee_salaries
ORDER BY department, salary DESC;

-- =====================================================
-- Example 8: Salary Distribution Analysis
-- =====================================================

-- Analyze salary distribution across departments
SELECT 
    department,
    COUNT(*) as employee_count,
    ROUND(AVG(salary), 2) as avg_salary,
    ROUND(MIN(salary), 2) as min_salary,
    ROUND(MAX(salary), 2) as max_salary,
    ROUND(
        PERCENT_RANK() OVER (ORDER BY AVG(salary)) * 100, 1
    ) as dept_percentile_rank
FROM employee_salaries
GROUP BY department
ORDER BY avg_salary DESC;

-- =====================================================
-- Example 9: Top Performers by Percentile
-- =====================================================

-- Find top 20% performers in each department
WITH ranked_employees AS (
    SELECT 
        employee_name,
        department,
        salary,
        PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary DESC) as performance_rank
    FROM employee_salaries
)
SELECT 
    employee_name,
    department,
    salary,
    ROUND(performance_rank * 100, 1) as performance_percentile
FROM ranked_employees
WHERE performance_rank <= 0.2
ORDER BY department, performance_rank;

-- =====================================================
-- Example 10: Salary Equity Analysis
-- =====================================================

-- Analyze salary equity using percentiles
SELECT 
    employee_name,
    department,
    salary,
    ROUND(PERCENT_RANK() OVER (ORDER BY salary) * 100, 1) as overall_percentile,
    ROUND(PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) * 100, 1) as dept_percentile,
    CASE 
        WHEN PERCENT_RANK() OVER (ORDER BY salary) > PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) + 0.1
        THEN 'Above Market'
        WHEN PERCENT_RANK() OVER (ORDER BY salary) < PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) - 0.1
        THEN 'Below Market'
        ELSE 'Market Rate'
    END as salary_positioning
FROM employee_salaries
ORDER BY department, salary;

-- Clean up
DROP TABLE IF EXISTS employee_salaries CASCADE; 