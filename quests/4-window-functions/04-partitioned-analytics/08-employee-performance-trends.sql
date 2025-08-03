-- =====================================================
-- Window Functions: Employee Performance Trends
-- =====================================================

-- PURPOSE: Demonstrate advanced window functions for employee performance analysis
--          including performance trends, category analysis, and rolling metrics
-- LEARNING OUTCOMES: Students will understand how to use window functions for
--                    employee analytics, category performance, and rolling calculations
-- EXPECTED RESULTS:
-- 1. Employee performance trends over time
-- 2. Category performance analysis
-- 3. Rolling performance metrics
-- DIFFICULTY: 🔴 Advanced (15-30 min)
-- CONCEPTS: LAG functions, PARTITION BY, ROW_NUMBER(), 
--           rolling calculations, performance trends

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS sales_performance CASCADE;
DROP TABLE IF EXISTS employee_performance CASCADE;

-- Create sales performance table
CREATE TABLE sales_performance (
    record_id INT PRIMARY KEY,
    salesperson_id INT,
    salesperson_name VARCHAR(100),
    region VARCHAR(50),
    product_category VARCHAR(50),
    quarter VARCHAR(10),
    year INT,
    sales_amount DECIMAL(10,2),
    units_sold INT,
    commission_rate DECIMAL(5,2)
);

-- Create employee performance table
CREATE TABLE employee_performance (
    record_id INT PRIMARY KEY,
    employee_id INT,
    employee_name VARCHAR(100),
    department VARCHAR(50),
    position VARCHAR(50),
    evaluation_date DATE,
    performance_score DECIMAL(5,2),
    projects_completed INT,
    hours_worked INT
);

-- Insert sample sales performance data
INSERT INTO sales_performance VALUES
-- Q1 2024
(1, 101, 'Alice Johnson', 'North', 'Electronics', 'Q1', 2024, 45000.00, 150, 0.05),
(2, 102, 'Bob Smith', 'South', 'Electronics', 'Q1', 2024, 38000.00, 120, 0.05),
(3, 103, 'Carol Davis', 'East', 'Electronics', 'Q1', 2024, 52000.00, 180, 0.05),
(4, 104, 'David Wilson', 'West', 'Electronics', 'Q1', 2024, 41000.00, 140, 0.05),
(5, 101, 'Alice Johnson', 'North', 'Clothing', 'Q1', 2024, 28000.00, 200, 0.04),
(6, 102, 'Bob Smith', 'South', 'Clothing', 'Q1', 2024, 32000.00, 220, 0.04),
(7, 103, 'Carol Davis', 'East', 'Clothing', 'Q1', 2024, 25000.00, 180, 0.04),
(8, 104, 'David Wilson', 'West', 'Clothing', 'Q1', 2024, 35000.00, 250, 0.04),

-- Q2 2024
(9, 101, 'Alice Johnson', 'North', 'Electronics', 'Q2', 2024, 48000.00, 160, 0.05),
(10, 102, 'Bob Smith', 'South', 'Electronics', 'Q2', 2024, 42000.00, 140, 0.05),
(11, 103, 'Carol Davis', 'East', 'Electronics', 'Q2', 2024, 55000.00, 190, 0.05),
(12, 104, 'David Wilson', 'West', 'Electronics', 'Q2', 2024, 44000.00, 150, 0.05),
(13, 101, 'Alice Johnson', 'North', 'Clothing', 'Q2', 2024, 30000.00, 220, 0.04),
(14, 102, 'Bob Smith', 'South', 'Clothing', 'Q2', 2024, 35000.00, 240, 0.04),
(15, 103, 'Carol Davis', 'East', 'Clothing', 'Q2', 2024, 28000.00, 200, 0.04),
(16, 104, 'David Wilson', 'West', 'Clothing', 'Q2', 2024, 38000.00, 270, 0.04),

-- Q3 2024
(17, 101, 'Alice Johnson', 'North', 'Electronics', 'Q3', 2024, 52000.00, 170, 0.05),
(18, 102, 'Bob Smith', 'South', 'Electronics', 'Q3', 2024, 46000.00, 150, 0.05),
(19, 103, 'Carol Davis', 'East', 'Electronics', 'Q3', 2024, 58000.00, 200, 0.05),
(20, 104, 'David Wilson', 'West', 'Electronics', 'Q3', 2024, 47000.00, 160, 0.05),
(21, 101, 'Alice Johnson', 'North', 'Clothing', 'Q3', 2024, 32000.00, 240, 0.04),
(22, 102, 'Bob Smith', 'South', 'Clothing', 'Q3', 2024, 38000.00, 260, 0.04),
(23, 103, 'Carol Davis', 'East', 'Clothing', 'Q3', 2024, 30000.00, 220, 0.04),
(24, 104, 'David Wilson', 'West', 'Clothing', 'Q3', 2024, 42000.00, 300, 0.04);

-- Insert sample employee performance data
INSERT INTO employee_performance VALUES
-- Q1 2024 Evaluations
(1, 201, 'Emma Brown', 'Engineering', 'Senior Developer', '2024-03-31', 4.2, 3, 480),
(2, 202, 'Frank Miller', 'Engineering', 'Developer', '2024-03-31', 3.8, 2, 450),
(3, 203, 'Grace Lee', 'Marketing', 'Marketing Manager', '2024-03-31', 4.5, 4, 520),
(4, 204, 'Henry Taylor', 'Sales', 'Sales Representative', '2024-03-31', 4.1, 5, 480),
(5, 205, 'Ivy Chen', 'Engineering', 'Developer', '2024-03-31', 3.9, 2, 460),
(6, 206, 'Jack Anderson', 'Marketing', 'Marketing Specialist', '2024-03-31', 4.0, 3, 500),

-- Q2 2024 Evaluations
(7, 201, 'Emma Brown', 'Engineering', 'Senior Developer', '2024-06-30', 4.4, 4, 520),
(8, 202, 'Frank Miller', 'Engineering', 'Developer', '2024-06-30', 4.0, 3, 480),
(9, 203, 'Grace Lee', 'Marketing', 'Marketing Manager', '2024-06-30', 4.6, 5, 540),
(10, 204, 'Henry Taylor', 'Sales', 'Sales Representative', '2024-06-30', 4.3, 6, 500),
(11, 205, 'Ivy Chen', 'Engineering', 'Developer', '2024-06-30', 4.1, 3, 480),
(12, 206, 'Jack Anderson', 'Marketing', 'Marketing Specialist', '2024-06-30', 4.2, 4, 520),

-- Q3 2024 Evaluations
(13, 201, 'Emma Brown', 'Engineering', 'Senior Developer', '2024-09-30', 4.5, 5, 540),
(14, 202, 'Frank Miller', 'Engineering', 'Developer', '2024-09-30', 4.2, 4, 500),
(15, 203, 'Grace Lee', 'Marketing', 'Marketing Manager', '2024-09-30', 4.7, 6, 560),
(16, 204, 'Henry Taylor', 'Sales', 'Sales Representative', '2024-09-30', 4.4, 7, 520),
(17, 205, 'Ivy Chen', 'Engineering', 'Developer', '2024-09-30', 4.3, 4, 500),
(18, 206, 'Jack Anderson', 'Marketing', 'Marketing Specialist', '2024-09-30', 4.4, 5, 540);

-- =====================================================
-- Example 1: Employee Performance Trends
-- =====================================================

-- Analyze employee performance trends over time
WITH employee_trends AS (
    SELECT 
        employee_id,
        employee_name,
        department,
        position,
        evaluation_date,
        performance_score,
        projects_completed,
        hours_worked,
        -- Previous evaluation score
        LAG(performance_score) OVER (
            PARTITION BY employee_id 
            ORDER BY evaluation_date
        ) as prev_score,
        -- Performance improvement
        ROUND(
            (performance_score - LAG(performance_score) OVER (
                PARTITION BY employee_id 
                ORDER BY evaluation_date
            )), 2
        ) as score_improvement,
        -- Department ranking
        ROW_NUMBER() OVER (
            PARTITION BY department, evaluation_date 
            ORDER BY performance_score DESC
        ) as dept_rank,
        -- Department percentile
        ROUND((PERCENT_RANK() OVER (
            PARTITION BY department, evaluation_date 
            ORDER BY performance_score
        ))::NUMERIC, 3) as dept_percentile
    FROM employee_performance
)
SELECT 
    employee_name,
    department,
    position,
    evaluation_date,
    performance_score,
    prev_score,
    score_improvement,
    dept_rank,
    dept_percentile,
    CASE 
        WHEN score_improvement > 0.3 THEN 'Significant Improvement'
        WHEN score_improvement > 0.1 THEN 'Moderate Improvement'
        WHEN score_improvement > -0.1 THEN 'Stable'
        WHEN score_improvement > -0.3 THEN 'Slight Decline'
        ELSE 'Needs Attention'
    END as trend_direction
FROM employee_trends
ORDER BY employee_id, evaluation_date;

-- =====================================================
-- Example 2: Category Performance Analysis
-- =====================================================

-- Analyze performance across product categories
WITH category_analysis AS (
    SELECT 
        product_category,
        quarter,
        year,
        SUM(sales_amount) as total_category_sales,
        AVG(sales_amount) as avg_sales_per_person,
        COUNT(DISTINCT salesperson_id) as active_salespeople,
        -- Category growth vs previous quarter
        ROUND(
            (SUM(sales_amount) - LAG(SUM(sales_amount)) OVER (
                PARTITION BY product_category 
                ORDER BY year, quarter
            )) * 100.0 / NULLIF(LAG(SUM(sales_amount)) OVER (
                PARTITION BY product_category 
                ORDER BY year, quarter
            ), 0), 2
        ) as category_growth_pct,
        -- Category ranking by total sales
        ROW_NUMBER() OVER (
            PARTITION BY quarter, year 
            ORDER BY SUM(sales_amount) DESC
        ) as category_rank,
        -- Category contribution to total
        ROUND(
            SUM(sales_amount) * 100.0 / SUM(SUM(sales_amount)) OVER (
                PARTITION BY quarter, year
            ), 2
        ) as category_contribution_pct
    FROM sales_performance
    GROUP BY product_category, quarter, year
)
SELECT 
    product_category,
    quarter,
    year,
    total_category_sales,
    avg_sales_per_person,
    active_salespeople,
    category_growth_pct,
    category_rank,
    category_contribution_pct,
    CASE 
        WHEN category_growth_pct > 15 THEN 'High Growth'
        WHEN category_growth_pct > 5 THEN 'Moderate Growth'
        WHEN category_growth_pct > -5 THEN 'Stable'
        WHEN category_growth_pct > -15 THEN 'Declining'
        ELSE 'Significant Decline'
    END as category_trend
FROM category_analysis
ORDER BY year, quarter, category_rank;

-- =====================================================
-- Example 3: Rolling Performance Metrics
-- =====================================================

-- Calculate rolling performance metrics
SELECT 
    salesperson_id,
    salesperson_name,
    region,
    product_category,
    quarter,
    year,
    sales_amount,
    -- Rolling 3-quarter average
    ROUND(
        AVG(sales_amount) OVER (
            PARTITION BY salesperson_id, product_category 
            ORDER BY year, quarter 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) as rolling_3q_avg,
    -- Rolling 3-quarter total
    ROUND(
        SUM(sales_amount) OVER (
            PARTITION BY salesperson_id, product_category 
            ORDER BY year, quarter 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) as rolling_3q_total,
    -- Performance vs rolling average
    ROUND(
        (sales_amount - AVG(sales_amount) OVER (
            PARTITION BY salesperson_id, product_category 
            ORDER BY year, quarter 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        )) * 100.0 / NULLIF(AVG(sales_amount) OVER (
            PARTITION BY salesperson_id, product_category 
            ORDER BY year, quarter 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 0), 2
    ) as vs_rolling_avg_pct
FROM sales_performance
ORDER BY salesperson_id, product_category, year, quarter;

-- Clean up
DROP TABLE IF EXISTS sales_performance CASCADE;
DROP TABLE IF EXISTS employee_performance CASCADE; 