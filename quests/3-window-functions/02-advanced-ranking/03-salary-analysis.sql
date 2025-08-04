-- =====================================================
<<<<<<< HEAD
-- Window Functions: Complex Salary Analysis with Multiple Functions
-- =====================================================

-- PURPOSE: Demonstrate complex salary analysis using multiple window functions for
--          comprehensive business analytics including distributions, equity analysis,
--          and performance correlation across departments and experience levels
-- LEARNING OUTCOMES: Students will understand how to combine multiple window functions
--                    for comprehensive salary analysis, including percentile calculations,
--                    equity analysis, and performance correlation patterns
-- EXPECTED RESULTS:
-- 1. Multiple percentile functions applied to salary distribution analysis
-- 2. Salary bands created using NTILE with distribution analysis
-- 3. Statistical measures calculated for salary distributions by department
-- 4. Salary equity analysis across departments and experience levels
-- 5. Department performance analysis with salary correlation metrics
-- 6. Comprehensive salary report with multiple ranking and analysis dimensions
-- DIFFICULTY: 🔴 Advanced (15-30 min)
-- CONCEPTS: Multiple window functions, PERCENT_RANK(), NTILE(), salary distributions, equity analysis, performance correlation, statistical measures

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS employee_salaries CASCADE;
DROP TABLE IF EXISTS salary_history CASCADE;
DROP TABLE IF EXISTS performance_metrics CASCADE;
DROP TABLE IF EXISTS department_budgets CASCADE;

-- Create employee salaries table
CREATE TABLE employee_salaries (
    employee_id INT PRIMARY KEY,
    name VARCHAR(100),
    department VARCHAR(50),
    position VARCHAR(50),
    salary DECIMAL(10,2),
    years_experience INT,
    education_level VARCHAR(20),
=======
-- Window Functions: Advanced Salary Analysis
-- =====================================================

<<<<<<<< HEAD:quests/window-functions/01-basic-ranking/03-percent-rank.sql
-- PURPOSE: Demonstrate PERCENT_RANK() and NTILE() functions for percentile
--          calculations and creating equal-sized groups for salary analysis
-- LEARNING OUTCOMES: Students will understand how to use PERCENT_RANK() for
--                    percentile calculations and NTILE() for creating equal-sized
--                    groups for salary analysis and performance tiers
-- EXPECTED RESULTS:
-- 1. PERCENT_RANK() calculates percentile ranks for salary distribution
-- 2. NTILE() creates salary quartiles and quintiles
-- 3. Department-based percentile analysis
-- 4. Performance tiers based on percentile ranks
-- 5. Salary bands created using NTILE
-- 6. Top performers identified by percentile
-- 7. Salary equity analysis using percentiles
-- 8. Multiple percentile functions compared
-- 9. Salary distribution analysis across departments
-- 10. Market positioning analysis using percentiles
-- DIFFICULTY: 🟡 Intermediate (10-20 min)
-- CONCEPTS: PERCENT_RANK(), NTILE(), PARTITION BY, percentile calculations, salary analysis, performance tiers, equity analysis
========
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
>>>>>>>> 4e036c9 (feat(quests) improve quest queries):quests/window-functions/02-advanced-ranking/03-salary-analysis.sql

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS employee_salaries CASCADE;

-- Create sample employee salaries table
CREATE TABLE employee_salaries (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100),
    department VARCHAR(50),
    salary DECIMAL(10,2),
>>>>>>> 4e036c9 (feat(quests) improve quest queries)
    hire_date DATE
);

-- Insert sample data
INSERT INTO employee_salaries VALUES
<<<<<<< HEAD
(1, 'Alice Johnson', 'Engineering', 'Senior Developer', 85000, 5, 'Masters', '2019-03-15'),
(2, 'Bob Smith', 'Engineering', 'Junior Developer', 65000, 2, 'Bachelors', '2022-01-10'),
(3, 'Carol Davis', 'Engineering', 'Lead Developer', 95000, 7, 'Masters', '2017-06-20'),
(4, 'David Wilson', 'Sales', 'Sales Manager', 75000, 4, 'Bachelors', '2020-02-28'),
(5, 'Eve Brown', 'Sales', 'Sales Representative', 55000, 1, 'Bachelors', '2023-04-12'),
(6, 'Frank Miller', 'Sales', 'Senior Sales Rep', 70000, 3, 'Bachelors', '2021-08-05'),
(7, 'Grace Taylor', 'Marketing', 'Marketing Director', 90000, 6, 'Masters', '2018-11-30'),
(8, 'Henry Anderson', 'Marketing', 'Marketing Specialist', 60000, 2, 'Bachelors', '2022-03-22'),
(9, 'Ivy Martinez', 'Marketing', 'Senior Specialist', 75000, 4, 'Masters', '2020-07-14'),
(10, 'Jack Garcia', 'Engineering', 'Architect', 110000, 8, 'PhD', '2016-09-08),
(11, 'Kate Wilson', 'Engineering', 'Developer', 70000, 3, 'Bachelors', '2021-01-15),
(12, 'Liam Brown', 'Sales', 'Sales Director', 95000, 7, 'Masters', '2017-12-03),
(13, 'Mia Davis', 'Marketing', 'Marketing Manager', 80000, 5, 'Bachelors', '2019-05-18),
(14, 'Noah Johnson', 'Engineering', 'Senior Developer', 88000, 6, 'Masters', '2018-02-25),
(15, 'Olivia Smith', 'Sales', 'Sales Representative', 58000, 2, 'Bachelors', '2022-06-10);

-- Example 1: Multiple Percentile Functions
-- Analyze salary distribution using different percentile functions
SELECT 
    employee_id,
    name,
    department,
    salary,
    years_experience,
    ROUND(PERCENT_RANK() OVER (ORDER BY salary) * 100, 2) as salary_percentile,
    NTILE(4) OVER (ORDER BY salary) as salary_quartile,
    ROUND(PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) * 100, 2) as dept_percentile,
    CASE 
        WHEN PERCENT_RANK() OVER (ORDER BY salary) >= 0.8 THEN 'Top 20%'
        WHEN PERCENT_RANK() OVER (ORDER BY salary) >= 0.6 THEN 'Top 40%'
        WHEN PERCENT_RANK() OVER (ORDER BY salary) >= 0.4 THEN 'Top 60%'
        WHEN PERCENT_RANK() OVER (ORDER BY salary) >= 0.2 THEN 'Top 80%'
        ELSE 'Bottom 20%'
    END as overall_tier
FROM employee_salaries
ORDER BY salary DESC;

-- Example 2: Salary Bands with NTILE
-- Create salary bands and analyze distribution
SELECT 
    employee_id,
    name,
    department,
    salary,
    NTILE(5) OVER (ORDER BY salary) as salary_band,
    CASE 
        WHEN NTILE(5) OVER (ORDER BY salary) = 1 THEN 'Band 1 (Lowest 20%)'
        WHEN NTILE(5) OVER (ORDER BY salary) = 2 THEN 'Band 2 (20-40%)'
        WHEN NTILE(5) OVER (ORDER BY salary) = 3 THEN 'Band 3 (40-60%)'
        WHEN NTILE(5) OVER (ORDER BY salary) = 4 THEN 'Band 4 (60-80%)'
        ELSE 'Band 5 (Highest 20%)'
    END as band_description,
    ROUND(AVG(salary) OVER (PARTITION BY NTILE(5) OVER (ORDER BY salary)), 2) as band_avg_salary
FROM employee_salaries
ORDER BY salary DESC;

-- Example 3: Salary Distribution Analysis
-- Analyze salary distribution with statistical measures
=======
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
-- Example 1: Multiple Percentile Functions
-- =====================================================

-- Compare different percentile functions
SELECT 
    employee_name,
    department,
    salary,
    ROUND((PERCENT_RANK() OVER (ORDER BY salary))::NUMERIC, 3) as overall_percent_rank,
    ROUND((PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary))::NUMERIC, 3) as dept_percent_rank,
    NTILE(5) OVER (ORDER BY salary) as salary_quintile,
    NTILE(10) OVER (ORDER BY salary) as salary_decile
FROM employee_salaries
ORDER BY salary;

-- =====================================================
-- Example 2: Salary Bands with NTILE
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
-- Example 3: Salary Distribution Analysis
-- =====================================================

-- Analyze salary distribution across departments
>>>>>>> 4e036c9 (feat(quests) improve quest queries)
SELECT 
    department,
    COUNT(*) as employee_count,
    ROUND(AVG(salary), 2) as avg_salary,
    ROUND(MIN(salary), 2) as min_salary,
    ROUND(MAX(salary), 2) as max_salary,
<<<<<<< HEAD
    ROUND(STDDEV(salary), 2) as salary_stddev,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary), 2) as median_salary,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY salary), 2) as q1_salary,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY salary), 2) as q3_salary
=======
    ROUND(
        PERCENT_RANK() OVER (ORDER BY AVG(salary)) * 100, 1
    ) as dept_percentile_rank
>>>>>>> 4e036c9 (feat(quests) improve quest queries)
FROM employee_salaries
GROUP BY department
ORDER BY avg_salary DESC;

<<<<<<< HEAD
-- Create salary history table
CREATE TABLE salary_history (
    employee_id INT,
    year INT,
    salary DECIMAL(10,2),
    performance_rating DECIMAL(3,2)
);

-- Insert sample data
INSERT INTO salary_history VALUES
(1, 2020, 75000, 4.2),
(1, 2021, 78000, 4.5),
(1, 2022, 82000, 4.3),
(1, 2023, 85000, 4.7),
(2, 2022, 60000, 3.8),
(2, 2023, 65000, 4.1),
(3, 2020, 85000, 4.6),
(3, 2021, 88000, 4.8),
(3, 2022, 92000, 4.7),
(3, 2023, 95000, 4.9),
(4, 2020, 65000, 4.0),
(4, 2021, 68000, 4.2),
(4, 2022, 72000, 4.4),
(4, 2023, 75000, 4.3);

-- Example 4: Salary Equity Analysis
-- Analyze salary equity across departments and experience levels
WITH salary_analysis AS (
    SELECT 
        es.employee_id,
        es.name,
        es.department,
        es.salary,
        es.years_experience,
        es.education_level,
        ROUND(AVG(es.salary) OVER (PARTITION BY es.department), 2) as dept_avg_salary,
        ROUND(AVG(es.salary) OVER (PARTITION BY es.years_experience), 2) as exp_avg_salary,
        ROUND(AVG(es.salary) OVER (PARTITION BY es.education_level), 2) as edu_avg_salary
    FROM employee_salaries es
)
SELECT 
    employee_id,
    name,
    department,
    salary,
    years_experience,
    education_level,
    dept_avg_salary,
    exp_avg_salary,
    edu_avg_salary,
    ROUND((salary - dept_avg_salary) / dept_avg_salary * 100, 2) as dept_deviation_pct,
    ROUND((salary - exp_avg_salary) / exp_avg_salary * 100, 2) as exp_deviation_pct,
    CASE 
        WHEN salary > dept_avg_salary * 1.1 THEN 'Above Department Average'
        WHEN salary < dept_avg_salary * 0.9 THEN 'Below Department Average'
        ELSE 'At Department Average'
    END as dept_comparison
FROM salary_analysis
ORDER BY department, salary DESC;

-- Example 5: Department Performance Analysis
-- Analyze department performance and salary correlation
SELECT 
    department,
    COUNT(*) as employee_count,
    ROUND(AVG(salary), 2) as avg_salary,
    ROUND(AVG(years_experience), 2) as avg_experience,
    ROUND(AVG(salary) / AVG(years_experience), 2) as salary_per_year_exp,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY salary) - 
          PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY salary), 2) as salary_range,
    CASE 
        WHEN AVG(salary) > (SELECT AVG(salary) FROM employee_salaries) THEN 'Above Company Average'
        ELSE 'Below Company Average'
    END as company_comparison
FROM employee_salaries
GROUP BY department
ORDER BY avg_salary DESC;

-- Example 6: Comprehensive Salary Report
-- Create a comprehensive salary analysis report
WITH comprehensive_analysis AS (
    SELECT 
        es.employee_id,
        es.name,
        es.department,
        es.position,
        es.salary,
        es.years_experience,
        es.education_level,
        ROUND(PERCENT_RANK() OVER (ORDER BY es.salary) * 100, 2) as overall_percentile,
        ROUND(PERCENT_RANK() OVER (PARTITION BY es.department ORDER BY es.salary) * 100, 2) as dept_percentile,
        ROUND(PERCENT_RANK() OVER (PARTITION BY es.years_experience ORDER BY es.salary) * 100, 2) as exp_percentile,
        NTILE(4) OVER (ORDER BY es.salary) as salary_quartile,
        ROUND(AVG(es.salary) OVER (PARTITION BY es.department), 2) as dept_avg,
        ROUND(AVG(es.salary) OVER (PARTITION BY es.years_experience), 2) as exp_avg
    FROM employee_salaries es
)
SELECT 
    employee_id,
    name,
    department,
    position,
    salary,
    years_experience,
    education_level,
    overall_percentile,
    dept_percentile,
    exp_percentile,
    CASE 
        WHEN salary_quartile = 1 THEN 'Q1 (Lowest 25%)'
        WHEN salary_quartile = 2 THEN 'Q2 (25-50%)'
        WHEN salary_quartile = 3 THEN 'Q3 (50-75%)'
        ELSE 'Q4 (Highest 25%)'
    END as salary_quartile_desc,
    dept_avg,
    exp_avg,
    ROUND((salary - dept_avg) / dept_avg * 100, 2) as dept_deviation_pct,
    CASE 
        WHEN overall_percentile >= 80 AND dept_percentile >= 75 THEN 'High Performer'
        WHEN overall_percentile >= 60 AND dept_percentile >= 50 THEN 'Good Performer'
        WHEN overall_percentile >= 40 AND dept_percentile >= 25 THEN 'Average Performer'
        ELSE 'Needs Improvement'
    END as performance_category
FROM comprehensive_analysis
ORDER BY overall_percentile DESC;

-- Clean up
DROP TABLE IF EXISTS employee_salaries CASCADE;
DROP TABLE IF EXISTS salary_history CASCADE;
DROP TABLE IF EXISTS performance_metrics CASCADE;
DROP TABLE IF EXISTS department_budgets CASCADE; 
=======
-- =====================================================
-- Example 4: Salary Equity Analysis
-- =====================================================

-- Analyze salary equity using percentiles
SELECT 
    employee_name,
    department,
    salary,
    ROUND((PERCENT_RANK() OVER (ORDER BY salary) * 100)::NUMERIC, 1) as overall_percentile,
    ROUND((PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) * 100)::NUMERIC, 1) as dept_percentile,
    CASE 
        WHEN PERCENT_RANK() OVER (ORDER BY salary) > PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) + 0.1
        THEN 'Above Market'
        WHEN PERCENT_RANK() OVER (ORDER BY salary) < PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) - 0.1
        THEN 'Below Market'
        ELSE 'Market Rate'
    END as salary_positioning
FROM employee_salaries
ORDER BY department, salary;

-- =====================================================
-- Example 5: Department Performance Analysis
-- =====================================================

-- Analyze department performance using multiple metrics
WITH dept_analysis AS (
    SELECT 
        department,
        COUNT(*) as employee_count,
        ROUND(AVG(salary), 2) as avg_salary,
        ROUND(STDDEV(salary), 2) as salary_stddev,
        ROUND(MIN(salary), 2) as min_salary,
        ROUND(MAX(salary), 2) as max_salary
    FROM employee_salaries
    GROUP BY department
)
SELECT 
    department,
    employee_count,
    avg_salary,
    salary_stddev,
    min_salary,
    max_salary,
    ROUND((PERCENT_RANK() OVER (ORDER BY avg_salary)) * 100, 1) as avg_salary_percentile,
    ROUND((PERCENT_RANK() OVER (ORDER BY salary_stddev)) * 100, 1) as variability_percentile,
    CASE 
        WHEN PERCENT_RANK() OVER (ORDER BY avg_salary) >= 0.8 THEN 'High Paying'
        WHEN PERCENT_RANK() OVER (ORDER BY avg_salary) >= 0.6 THEN 'Above Average'
        WHEN PERCENT_RANK() OVER (ORDER BY avg_salary) >= 0.4 THEN 'Average'
        WHEN PERCENT_RANK() OVER (ORDER BY avg_salary) >= 0.2 THEN 'Below Average'
        ELSE 'Low Paying'
    END as pay_level
FROM dept_analysis
ORDER BY avg_salary DESC;

-- =====================================================
-- Example 6: Comprehensive Salary Report
-- =====================================================

-- Generate comprehensive salary analysis report
SELECT 
    employee_name,
    department,
    salary,
    -- Overall positioning
    ROUND((PERCENT_RANK() OVER (ORDER BY salary) * 100)::NUMERIC, 1) as overall_percentile,
    -- Department positioning
    ROUND((PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) * 100)::NUMERIC, 1) as dept_percentile,
    -- Salary band
    NTILE(5) OVER (ORDER BY salary) as salary_band,
    -- Performance tier
    CASE 
        WHEN PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) >= 0.8 THEN 'Top Performer'
        WHEN PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) >= 0.6 THEN 'High Performer'
        WHEN PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) >= 0.4 THEN 'Average Performer'
        WHEN PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) >= 0.2 THEN 'Below Average'
        ELSE 'Needs Improvement'
    END as performance_tier,
    -- Market positioning
    CASE 
        WHEN PERCENT_RANK() OVER (ORDER BY salary) > PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) + 0.1
        THEN 'Above Market'
        WHEN PERCENT_RANK() OVER (ORDER BY salary) < PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) - 0.1
        THEN 'Below Market'
        ELSE 'Market Rate'
    END as market_positioning
FROM employee_salaries
ORDER BY department, salary DESC;

-- Clean up
DROP TABLE IF EXISTS employee_salaries CASCADE; 
>>>>>>> 4e036c9 (feat(quests) improve quest queries)
