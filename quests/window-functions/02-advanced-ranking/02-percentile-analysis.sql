-- =====================================================
-- Window Functions: Percentile Analysis with PERCENT_RANK
-- =====================================================

<<<<<<< HEAD
-- PURPOSE: Demonstrate percentile calculations and ranking using PERCENT_RANK function
--          for identifying top performers and analyzing performance distributions
-- LEARNING OUTCOMES: Students will understand how to use PERCENT_RANK() for
--                    percentile calculations, identifying top performers, and
--                    analyzing performance distributions across different groups
-- EXPECTED RESULTS:
-- 1. Percentile ranks calculated for sales performance across regions
-- 2. Regional percentile analysis with performance tier classification
-- 3. Student performance tiers based on percentile ranks within subjects
-- 4. Top performers identified using percentile-based criteria
-- 5. Performance distribution analysis with percentile insights
-- DIFFICULTY: 🟡 Intermediate (10-20 min)
-- CONCEPTS: PERCENT_RANK(), percentile analysis, performance tiers, distribution analysis, top performer identification

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS sales_performance CASCADE;
DROP TABLE IF EXISTS student_grades CASCADE;
DROP TABLE IF EXISTS employee_metrics CASCADE;
DROP TABLE IF EXISTS product_ratings CASCADE;

-- Create sales performance table
CREATE TABLE sales_performance (
    salesperson_id INT PRIMARY KEY,
    name VARCHAR(100),
    region VARCHAR(50),
    monthly_sales DECIMAL(10,2),
    customer_count INT,
    avg_order_value DECIMAL(8,2)
);

-- Insert sample data
INSERT INTO sales_performance VALUES
(1, 'Alice Johnson', 'North', 45000.00, 45, 1000.00),
(2, 'Bob Smith', 'North', 52000.00, 52, 1000.00),
(3, 'Carol Davis', 'South', 38000.00, 38, 1000.00),
(4, 'David Wilson', 'South', 61000.00, 61, 1000.00),
(5, 'Eve Brown', 'East', 49000.00, 49, 1000.00),
(6, 'Frank Miller', 'East', 43000.00, 43, 1000.00),
(7, 'Grace Taylor', 'West', 55000.00, 55, 1000.00),
(8, 'Henry Anderson', 'West', 47000.00, 47, 1000.00),
(9, 'Ivy Martinez', 'North', 39000.00, 39, 1000.00),
(10, 'Jack Garcia', 'South', 58000.00, 58, 1000.00);

-- Example 1: Basic PERCENT_RANK
-- Calculate percentile rank for each salesperson based on monthly sales
SELECT 
    salesperson_id,
    name,
    region,
    monthly_sales,
    ROUND(PERCENT_RANK() OVER (ORDER BY monthly_sales) * 100, 2) as percentile_rank,
    CASE 
        WHEN PERCENT_RANK() OVER (ORDER BY monthly_sales) >= 0.8 THEN 'Top 20%'
        WHEN PERCENT_RANK() OVER (ORDER BY monthly_sales) >= 0.6 THEN 'Top 40%'
        WHEN PERCENT_RANK() OVER (ORDER BY monthly_sales) >= 0.4 THEN 'Top 60%'
        WHEN PERCENT_RANK() OVER (ORDER BY monthly_sales) >= 0.2 THEN 'Top 80%'
        ELSE 'Bottom 20%'
    END as performance_tier
FROM sales_performance
ORDER BY monthly_sales DESC;

-- Example 2: PERCENT_RANK by Department
-- Calculate percentile rank within each region
SELECT 
    salesperson_id,
    name,
    region,
    monthly_sales,
    ROUND(PERCENT_RANK() OVER (PARTITION BY region ORDER BY monthly_sales) * 100, 2) as regional_percentile,
    ROUND(PERCENT_RANK() OVER (ORDER BY monthly_sales) * 100, 2) as overall_percentile,
    CASE 
        WHEN PERCENT_RANK() OVER (PARTITION BY region ORDER BY monthly_sales) >= 0.75 THEN 'Regional Top 25%'
        WHEN PERCENT_RANK() OVER (PARTITION BY region ORDER BY monthly_sales) >= 0.5 THEN 'Regional Top 50%'
        ELSE 'Regional Bottom 50%'
    END as regional_tier
FROM sales_performance
ORDER BY region, monthly_sales DESC;

-- Create student grades table
CREATE TABLE student_grades (
    student_id INT PRIMARY KEY,
    name VARCHAR(100),
    subject VARCHAR(50),
    grade DECIMAL(5,2),
    class_size INT
);

-- Insert sample data
INSERT INTO student_grades VALUES
(1, 'Alex', 'Math', 92.5, 30),
(2, 'Beth', 'Math', 88.0, 30),
(3, 'Chris', 'Math', 95.5, 30),
(4, 'Dana', 'Math', 85.0, 30),
(5, 'Evan', 'Math', 91.0, 30),
(6, 'Fiona', 'Science', 89.5, 25),
(7, 'George', 'Science', 87.0, 25),
(8, 'Helen', 'Science', 93.5, 25),
(9, 'Ian', 'Science', 86.5, 25),
(10, 'Julia', 'Science', 90.0, 25);

-- Example 3: Performance Tiers Based on Percentiles
-- Create performance tiers using percentile ranks
SELECT 
    student_id,
    name,
    subject,
    grade,
    ROUND(PERCENT_RANK() OVER (PARTITION BY subject ORDER BY grade) * 100, 2) as subject_percentile,
    CASE 
        WHEN PERCENT_RANK() OVER (PARTITION BY subject ORDER BY grade) >= 0.9 THEN 'A+ (Top 10%)'
        WHEN PERCENT_RANK() OVER (PARTITION BY subject ORDER BY grade) >= 0.8 THEN 'A (Top 20%)'
        WHEN PERCENT_RANK() OVER (PARTITION BY subject ORDER BY grade) >= 0.7 THEN 'B+ (Top 30%)'
        WHEN PERCENT_RANK() OVER (PARTITION BY subject ORDER BY grade) >= 0.6 THEN 'B (Top 40%)'
        WHEN PERCENT_RANK() OVER (PARTITION BY subject ORDER BY grade) >= 0.5 THEN 'C+ (Top 50%)'
        ELSE 'C or Below'
    END as letter_grade
FROM student_grades
ORDER BY subject, grade DESC;

-- Create employee metrics table
CREATE TABLE employee_metrics (
    employee_id INT PRIMARY KEY,
    name VARCHAR(100),
    department VARCHAR(50),
    productivity_score DECIMAL(5,2),
    quality_score DECIMAL(5,2),
    teamwork_score DECIMAL(5,2)
);

-- Insert sample data
INSERT INTO employee_metrics VALUES
(1, 'Alice', 'Engineering', 8.5, 9.2, 8.8),
(2, 'Bob', 'Engineering', 9.1, 8.7, 9.0),
(3, 'Carol', 'Engineering', 7.8, 9.5, 8.2),
(4, 'David', 'Engineering', 9.3, 8.9, 8.6),
(5, 'Eve', 'Engineering', 8.9, 9.1, 8.4),
(6, 'Frank', 'Sales', 8.2, 8.8, 9.1),
(7, 'Grace', 'Sales', 9.0, 8.5, 8.9),
(8, 'Henry', 'Sales', 8.7, 9.0, 8.7),
(9, 'Ivy', 'Sales', 8.4, 8.6, 9.2),
(10, 'Jack', 'Sales', 9.2, 8.9, 8.5);

-- Example 4: Top Performers by Percentile
-- Identify top 25% performers based on overall score
WITH employee_scores AS (
    SELECT 
        employee_id,
        name,
        department,
        productivity_score,
        quality_score,
        teamwork_score,
        (productivity_score + quality_score + teamwork_score) / 3 as overall_score
    FROM employee_metrics
)
SELECT 
    employee_id,
    name,
    department,
    overall_score,
    ROUND(PERCENT_RANK() OVER (ORDER BY overall_score DESC) * 100, 2) as percentile_rank,
    CASE 
        WHEN PERCENT_RANK() OVER (ORDER BY overall_score DESC) <= 0.25 THEN 'Top 25% Performer'
        WHEN PERCENT_RANK() OVER (ORDER BY overall_score DESC) <= 0.5 THEN 'Top 50% Performer'
        WHEN PERCENT_RANK() OVER (ORDER BY overall_score DESC) <= 0.75 THEN 'Top 75% Performer'
        ELSE 'Bottom 25%'
    END as performance_category
FROM employee_scores
ORDER BY overall_score DESC;

-- Clean up
DROP TABLE IF EXISTS sales_performance CASCADE;
DROP TABLE IF EXISTS student_grades CASCADE;
DROP TABLE IF EXISTS employee_metrics CASCADE;
DROP TABLE IF EXISTS product_ratings CASCADE; 
=======
-- PURPOSE: Demonstrate PERCENT_RANK function for percentile analysis
--          and understanding relative positioning in datasets
-- LEARNING OUTCOMES: Students will understand how to use PERCENT_RANK
--                    for percentile calculations and relative positioning
-- EXPECTED RESULTS:
-- 1. Basic PERCENT_RANK calculations
-- 2. Percentile analysis by groups
-- 3. Understanding relative positioning
-- 4. Performance tier classification
-- DIFFICULTY: 🟡 Intermediate (10-20 min)
-- CONCEPTS: PERCENT_RANK(), percentile analysis, relative positioning

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
    ROUND((PERCENT_RANK() OVER (ORDER BY salary))::NUMERIC, 3) as percent_rank,
    ROUND((PERCENT_RANK() OVER (ORDER BY salary) * 100)::NUMERIC, 1) as percentile
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
    ROUND((PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary))::NUMERIC, 3) as dept_percent_rank,
    ROUND((PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) * 100)::NUMERIC, 1) as dept_percentile
FROM employee_salaries
ORDER BY department, salary;

-- =====================================================
-- Example 3: Performance Tiers Based on Percentiles
-- =====================================================

-- Create performance tiers based on salary percentiles
SELECT 
    employee_name,
    department,
    salary,
    ROUND((PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) * 100)::NUMERIC, 1) as dept_percentile,
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
-- Example 4: Top Performers by Percentile
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

-- Clean up
DROP TABLE IF EXISTS employee_salaries CASCADE; 
>>>>>>> 4e036c9 (feat(quests) improve quest queries)
