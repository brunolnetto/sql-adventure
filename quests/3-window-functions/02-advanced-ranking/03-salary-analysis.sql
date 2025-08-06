-- Window Functions: Advanced Salary Analysis
-- =====================================================

-- PURPOSE: Demonstrate advanced salary analysis using multiple window functions
--          including NTILE, PERCENT_RANK, and complex analytical patterns
-- LEARNING OUTCOMES: Students will understand complex salary analysis patterns
--                    including salary bands, equity analysis, and distribution analysis
-- EXPECTED RESULTS:
-- 1. Salary band creation with NTILE
-- 2. Multiple percentile function comparisons
-- 3. Salary distribution analysis
-- 4. Salary equity analysis
-- 5. Department performance analysis
-- DIFFICULTY: 🔴 Advanced (15-30 min)
-- CONCEPTS: NTILE(), PERCENT_RANK(), salary analysis, equity analysis, distribution analysis

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS employee_salaries CASCADE;

-- Create sample employee salaries table
CREATE TABLE employee_salaries (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100),
    department VARCHAR(50),
    salary DECIMAL(10, 2),
    years_experience INT,
    education_level VARCHAR(20),
    hire_date DATE
);

-- Insert sample data
INSERT INTO employee_salaries VALUES
(1, 'Alice Johnson', 'Engineering', 85000, 5, 'Masters', '2019-03-15'),
(2, 'Bob Smith', 'Engineering', 65000, 2, 'Bachelors', '2022-01-10'),
(3, 'Carol Davis', 'Engineering', 95000, 7, 'Masters', '2017-06-20'),
(4, 'David Wilson', 'Sales', 75000, 4, 'Bachelors', '2020-02-28'),
(5, 'Eve Brown', 'Sales', 55000, 1, 'Bachelors', '2023-04-12'),
(6, 'Frank Miller', 'Sales', 70000, 3, 'Bachelors', '2021-08-05'),
(7, 'Grace Taylor', 'Marketing', 90000, 6, 'Masters', '2018-11-30'),
(8, 'Henry Anderson', 'Marketing', 60000, 2, 'Bachelors', '2022-03-22'),
(9, 'Ivy Martinez', 'Marketing', 75000, 4, 'Masters', '2020-07-14'),
(10, 'Jack Garcia', 'Engineering', 110000, 8, 'PhD', '2016-09-08'),
(11, 'Kate Wilson', 'Engineering', 70000, 3, 'Bachelors', '2021-01-15'),
(12, 'Liam Brown', 'Sales', 95000, 7, 'Masters', '2017-12-03'),
(13, 'Mia Davis', 'Marketing', 80000, 5, 'Bachelors', '2019-05-18'),
(14, 'Noah Johnson', 'Engineering', 88000, 6, 'Masters', '2018-02-25'),
(15, 'Olivia Smith', 'Sales', 58000, 2, 'Bachelors', '2022-06-10');

-- Example 1: Multiple Percentile Functions
-- Analyze salary distribution using different percentile functions
SELECT
    employee_id,
    employee_name,
    department,
    salary,
    years_experience,
    ROUND(PERCENT_RANK() OVER (ORDER BY salary) * 100, 2) AS salary_percentile,
    NTILE(4) OVER (ORDER BY salary) AS salary_quartile,
    ROUND(
        PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) * 100, 2
    ) AS dept_percentile,
    CASE
        WHEN PERCENT_RANK() OVER (ORDER BY salary) >= 0.8 THEN 'Top 20%'
        WHEN PERCENT_RANK() OVER (ORDER BY salary) >= 0.6 THEN 'Top 40%'
        WHEN PERCENT_RANK() OVER (ORDER BY salary) >= 0.4 THEN 'Top 60%'
        WHEN PERCENT_RANK() OVER (ORDER BY salary) >= 0.2 THEN 'Top 80%'
        ELSE 'Bottom 20%'
    END AS overall_tier
FROM employee_salaries
ORDER BY salary DESC;

-- Example 2: Salary Bands with NTILE
-- Create salary bands and analyze distribution
SELECT
    employee_id,
    employee_name,
    department,
    salary,
    NTILE(5) OVER (ORDER BY salary) AS salary_quintile,
    NTILE(10) OVER (ORDER BY salary) AS salary_decile,
    CASE
        WHEN NTILE(5) OVER (ORDER BY salary) = 1 THEN 'Lowest 20%'
        WHEN NTILE(5) OVER (ORDER BY salary) = 2 THEN 'Lower 20%'
        WHEN NTILE(5) OVER (ORDER BY salary) = 3 THEN 'Middle 20%'
        WHEN NTILE(5) OVER (ORDER BY salary) = 4 THEN 'Upper 20%'
        ELSE 'Highest 20%'
    END AS salary_band
FROM employee_salaries
ORDER BY salary;

-- Example 3: Department-based Salary Analysis
-- Compare salary distributions across departments
SELECT
    department,
    COUNT(*) AS employee_count,
    ROUND(AVG(salary), 2) AS avg_salary,
    ROUND(MIN(salary), 2) AS min_salary,
    ROUND(MAX(salary), 2) AS max_salary,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary), 2)
        AS median_salary,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY salary), 2) AS q3_salary,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY salary), 2) AS q1_salary
FROM employee_salaries
GROUP BY department
ORDER BY avg_salary DESC;

-- Example 4: Salary Equity Analysis
-- Analyze salary distribution by education level and experience
SELECT
    education_level,
    years_experience,
    COUNT(*) AS employee_count,
    ROUND(AVG(salary), 2) AS avg_salary,
    ROUND(PERCENT_RANK() OVER (ORDER BY AVG(salary)) * 100, 2)
        AS education_experience_percentile,
    NTILE(3) OVER (ORDER BY AVG(salary)) AS salary_tier
FROM employee_salaries
GROUP BY education_level, years_experience
ORDER BY avg_salary DESC;

-- Example 5: Complex Salary Analysis with Multiple Windows
-- Advanced analysis combining multiple window functions
WITH salary_analysis AS (
    SELECT
        employee_id,
        employee_name,
        department,
        salary,
        years_experience,
        education_level,
        -- Overall company percentile
        ROUND(PERCENT_RANK() OVER (ORDER BY salary) * 100, 2)
            AS company_percentile,
        -- Department percentile
        ROUND(
            PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) * 100,
            2
        ) AS dept_percentile,
        -- Experience-based percentile
        ROUND(
            PERCENT_RANK() OVER (PARTITION BY years_experience ORDER BY salary)
            * 100,
            2
        ) AS exp_percentile,
        -- Education-based percentile
        ROUND(
            PERCENT_RANK() OVER (PARTITION BY education_level ORDER BY salary)
            * 100,
            2
        ) AS edu_percentile,
        -- Salary bands
        NTILE(4) OVER (ORDER BY salary) AS salary_quartile,
        NTILE(5) OVER (PARTITION BY department ORDER BY salary) AS dept_quintile
    FROM employee_salaries
)

SELECT
    employee_name,
    department,
    salary,
    years_experience,
    education_level,
    company_percentile,
    dept_percentile,
    exp_percentile,
    edu_percentile,
    salary_quartile,
    dept_quintile,
    CASE
        WHEN
            company_percentile >= 80 AND dept_percentile >= 80
            THEN 'High Performer'
        WHEN
            company_percentile >= 60 AND dept_percentile >= 60
            THEN 'Above Average'
        WHEN company_percentile >= 40 AND dept_percentile >= 40 THEN 'Average'
        WHEN
            company_percentile >= 20 AND dept_percentile >= 20
            THEN 'Below Average'
        ELSE 'Needs Review'
    END AS performance_category
FROM salary_analysis
ORDER BY company_percentile DESC;

-- Example 6: Salary Distribution Analysis
-- Analyze salary distribution patterns
SELECT
    NTILE(10) OVER (ORDER BY salary) AS salary_decile,
    COUNT(*) AS employee_count,
    ROUND(MIN(salary), 2) AS min_salary,
    ROUND(MAX(salary), 2) AS max_salary,
    ROUND(AVG(salary), 2) AS avg_salary,
    ROUND((MAX(salary) - MIN(salary)), 2) AS salary_range
FROM employee_salaries
GROUP BY NTILE(10) OVER (ORDER BY salary)
ORDER BY salary_decile;

-- Example 7: Department Performance Comparison
-- Compare departments using multiple metrics
SELECT
    department,
    COUNT(*) AS total_employees,
    ROUND(AVG(salary), 2) AS avg_salary,
    ROUND(PERCENT_RANK() OVER (ORDER BY AVG(salary)) * 100, 2)
        AS salary_percentile,
    ROUND(AVG(years_experience), 1) AS avg_experience,
    ROUND(PERCENT_RANK() OVER (ORDER BY AVG(years_experience)) * 100, 2)
        AS exp_percentile,
    ROUND(AVG(salary) / AVG(years_experience), 2) AS salary_per_year_experience,
    NTILE(3) OVER (ORDER BY AVG(salary)) AS salary_tier
FROM employee_salaries
GROUP BY department
ORDER BY avg_salary DESC;

-- Example 8: Salary Growth Analysis
-- Analyze salary patterns by hire date (proxy for growth)
SELECT
    EXTRACT(YEAR FROM hire_date) AS hire_year,
    COUNT(*) AS employees_hired,
    ROUND(AVG(salary), 2) AS avg_starting_salary,
    ROUND(PERCENT_RANK() OVER (ORDER BY AVG(salary)) * 100, 2)
        AS year_percentile,
    NTILE(4) OVER (ORDER BY AVG(salary)) AS salary_quartile
FROM employee_salaries
GROUP BY EXTRACT(YEAR FROM hire_date)
ORDER BY hire_year;

-- Clean up
DROP TABLE IF EXISTS employee_salaries CASCADE;
