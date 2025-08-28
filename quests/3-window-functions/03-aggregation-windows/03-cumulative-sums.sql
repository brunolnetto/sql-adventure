-- =====================================================
-- Window Functions quest: Cumulative Sums & Complex Aggregations
-- =====================================================

-- PURPOSE: Demonstrate advanced window function aggregation for complex
--          cumulative calculations and multi-dimensional analysis
-- LEARNING OUTCOMES: Students will understand how to use multiple window functions
--                    for complex aggregations, project tracking, and financial analysis
-- EXPECTED RESULTS:
-- 1. Complex cumulative calculations with multiple dimensions
-- 2. Project progress tracking with cumulative metrics
-- 3. Customer spending pattern analysis
-- 4. Advanced financial analysis with cumulative ratios
-- 5. Multi-dimensional rolling calculations
-- DIFFICULTY: 🟡 Intermediate (10-20 min)
-- CONCEPTS: Multiple window functions, complex aggregations, project tracking, financial analysis

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS sales_transactions CASCADE;
DROP TABLE IF EXISTS project_tasks CASCADE;
DROP TABLE IF EXISTS customer_orders CASCADE;

-- =====================================================
-- Example 1: Sales Transaction Analysis
-- =====================================================

-- Create sales transactions table
CREATE TABLE sales_transactions (
    transaction_id INT PRIMARY KEY,
    date DATE,
    product_category VARCHAR(50),
    sales_amount DECIMAL(10, 2),
    customer_id INT,
    region VARCHAR(50)
);

-- Insert sample sales data
INSERT INTO sales_transactions VALUES
(1, '2024-01-01', 'Electronics', 1200.00, 101, 'North'),
(2, '2024-01-01', 'Clothing', 450.00, 102, 'South'),
(3, '2024-01-02', 'Electronics', 1800.00, 103, 'North'),
(4, '2024-01-02', 'Books', 300.00, 104, 'East'),
(5, '2024-01-03', 'Clothing', 750.00, 105, 'West'),
(6, '2024-01-03', 'Electronics', 950.00, 106, 'North'),
(7, '2024-01-04', 'Books', 250.00, 107, 'South'),
(8, '2024-01-04', 'Clothing', 600.00, 108, 'East'),
(9, '2024-01-05', 'Electronics', 2200.00, 109, 'West'),
(10, '2024-01-05', 'Books', 400.00, 110, 'North'),
(11, '2024-01-06', 'Clothing', 850.00, 111, 'South'),
(12, '2024-01-06', 'Electronics', 1600.00, 112, 'East'),
(13, '2024-01-07', 'Books', 350.00, 113, 'West'),
(14, '2024-01-07', 'Clothing', 700.00, 114, 'North'),
(15, '2024-01-08', 'Electronics', 1900.00, 115, 'South');

-- Demonstrate cumulative sums and running totals
SELECT
    date,
    product_category,
    sales_amount,
    -- Cumulative sum by date
    SUM(sales_amount) OVER (
        ORDER BY date
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_total,
    -- Cumulative sum by category
    SUM(sales_amount) OVER (
        PARTITION BY product_category
        ORDER BY date
        ROWS UNBOUNDED PRECEDING
    ) AS category_cumulative,
    -- Running total for last 3 days
    SUM(sales_amount) OVER (
        ORDER BY date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_3day_total,
    -- Percentage of total sales
    ROUND(
        sales_amount * 100.0 / SUM(sales_amount) OVER (), 2
    ) AS percent_of_total,
    -- Percentage within category
    ROUND(
        sales_amount * 100.0 / SUM(sales_amount) OVER (
            PARTITION BY product_category
        ), 2
    ) AS percent_within_category
FROM sales_transactions
ORDER BY date, product_category;

-- =====================================================
-- Example 2: Project Task Progress Tracking
-- =====================================================

-- Create project tasks table
CREATE TABLE project_tasks (
    task_id INT PRIMARY KEY,
    project_name VARCHAR(100),
    task_name VARCHAR(200),
    start_date DATE,
    end_date DATE,
    estimated_hours INT,
    actual_hours INT,
    status VARCHAR(20)
);

-- Insert sample project data
INSERT INTO project_tasks VALUES
(
    1,
    'Website Redesign',
    'Requirements Analysis',
    '2024-01-01',
    '2024-01-03',
    16,
    18,
    'Completed'
),
(
    2,
    'Website Redesign',
    'Design Mockups',
    '2024-01-04',
    '2024-01-08',
    24,
    22,
    'Completed'
),
(
    3,
    'Website Redesign',
    'Frontend Development',
    '2024-01-09',
    '2024-01-15',
    40,
    45,
    'In Progress'
),
(
    4,
    'Website Redesign',
    'Backend Development',
    '2024-01-10',
    '2024-01-16',
    32,
    30,
    'In Progress'
),
(
    5,
    'Website Redesign',
    'Testing',
    '2024-01-17',
    '2024-01-19',
    16,
    NULL,
    'Not Started'
),
(6, 'Mobile App', 'UI Design', '2024-01-01', '2024-01-05', 20, 19, 'Completed'),
(
    7,
    'Mobile App',
    'iOS Development',
    '2024-01-06',
    '2024-01-12',
    35,
    38,
    'Completed'
),
(
    8,
    'Mobile App',
    'Android Development',
    '2024-01-07',
    '2024-01-13',
    35,
    32,
    'Completed'
),
(
    9,
    'Mobile App',
    'Testing & QA',
    '2024-01-14',
    '2024-01-18',
    20,
    22,
    'In Progress'
),
(
    10,
    'Mobile App',
    'App Store Submission',
    '2024-01-19',
    '2024-01-20',
    8,
    NULL,
    'Not Started'
),
(
    11,
    'Database Migration',
    'Data Analysis',
    '2024-01-01',
    '2024-01-02',
    12,
    10,
    'Completed'
),
(
    12,
    'Database Migration',
    'Schema Design',
    '2024-01-03',
    '2024-01-05',
    16,
    14,
    'Completed'
),
(
    13,
    'Database Migration',
    'Migration Scripts',
    '2024-01-06',
    '2024-01-10',
    24,
    26,
    'Completed'
),
(
    14,
    'Database Migration',
    'Testing',
    '2024-01-11',
    '2024-01-12',
    12,
    11,
    'Completed'
),
(
    15,
    'Database Migration',
    'Go-Live',
    '2024-01-13',
    '2024-01-13',
    8,
    6,
    'Completed'
);

-- Analyze project progress with cumulative metrics
SELECT
    project_name,
    task_name,
    start_date,
    end_date,
    estimated_hours,
    actual_hours,
    status,
    -- Cumulative estimated hours by project
    SUM(estimated_hours) OVER (
        PARTITION BY project_name
        ORDER BY start_date
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_estimated,
    -- Cumulative actual hours by project
    SUM(COALESCE(actual_hours, 0)) OVER (
        PARTITION BY project_name
        ORDER BY start_date
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_actual,
    -- Project completion percentage
    ROUND(
        SUM(COALESCE(actual_hours, 0)) OVER (
            PARTITION BY project_name
            ORDER BY start_date
            ROWS UNBOUNDED PRECEDING
        ) * 100.0 / SUM(estimated_hours) OVER (
            PARTITION BY project_name
        ), 2
    ) AS project_completion_percent,
    -- Efficiency ratio (actual vs estimated)
    CASE
        WHEN estimated_hours > 0
            THEN
                ROUND(COALESCE(actual_hours, 0) * 100.0 / estimated_hours, 2)
    END AS efficiency_percent,
    -- Running average of actual hours
    AVG(COALESCE(actual_hours, 0)) OVER (
        PARTITION BY project_name
        ORDER BY start_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS running_avg_hours
FROM project_tasks
ORDER BY project_name, start_date;

-- =====================================================
-- Example 3: Customer Order Analysis
-- =====================================================

-- Create customer orders table
CREATE TABLE customer_orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    order_amount DECIMAL(10, 2),
    shipping_cost DECIMAL(8, 2),
    discount_amount DECIMAL(8, 2),
    customer_tier VARCHAR(20)
);

-- Insert sample order data
INSERT INTO customer_orders VALUES
(1, 101, '2024-01-01', 150.00, 10.00, 15.00, 'Bronze'),
(2, 102, '2024-01-01', 300.00, 0.00, 30.00, 'Silver'),
(3, 103, '2024-01-02', 500.00, 0.00, 50.00, 'Gold'),
(4, 101, '2024-01-02', 200.00, 10.00, 20.00, 'Bronze'),
(5, 104, '2024-01-03', 750.00, 0.00, 75.00, 'Gold'),
(6, 102, '2024-01-03', 250.00, 0.00, 25.00, 'Silver'),
(7, 105, '2024-01-04', 1200.00, 0.00, 120.00, 'Platinum'),
(8, 103, '2024-01-04', 400.00, 0.00, 40.00, 'Gold'),
(9, 101, '2024-01-05', 180.00, 10.00, 18.00, 'Bronze'),
(10, 106, '2024-01-05', 900.00, 0.00, 90.00, 'Gold'),
(11, 104, '2024-01-06', 600.00, 0.00, 60.00, 'Gold'),
(12, 102, '2024-01-06', 350.00, 0.00, 35.00, 'Silver'),
(13, 107, '2024-01-07', 1500.00, 0.00, 150.00, 'Platinum'),
(14, 103, '2024-01-07', 450.00, 0.00, 45.00, 'Gold'),
(15, 101, '2024-01-08', 220.00, 10.00, 22.00, 'Bronze');

-- Analyze customer spending patterns
WITH customer_spending AS (
    SELECT
        customer_id,
        order_date,
        order_amount,
        shipping_cost,
        discount_amount,
        customer_tier,
        -- Net amount (order - discount + shipping)
        order_amount - discount_amount + shipping_cost AS net_amount,
        -- Cumulative spending by customer
        SUM(order_amount) OVER (
            PARTITION BY customer_id
            ORDER BY order_date
            ROWS UNBOUNDED PRECEDING
        ) AS customer_cumulative_spending,
        -- Cumulative net amount by customer
        SUM(order_amount - discount_amount + shipping_cost) OVER (
            PARTITION BY customer_id
            ORDER BY order_date
            ROWS UNBOUNDED PRECEDING
        ) AS customer_cumulative_net,
        -- Running average order amount by customer
        AVG(order_amount) OVER (
            PARTITION BY customer_id
            ORDER BY order_date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS customer_avg_order,
        -- Days since first order
        order_date - MIN(order_date) OVER (
            PARTITION BY customer_id
        ) AS days_since_first_order
    FROM customer_orders
)
SELECT
    customer_id,
    order_date,
    order_amount,
    shipping_cost,
    discount_amount,
    customer_tier,
    net_amount,
    customer_cumulative_spending,
    customer_cumulative_net,
    customer_avg_order,
    -- Customer ranking within tier based on cumulative spending
    RANK() OVER (
        PARTITION BY customer_tier
        ORDER BY customer_cumulative_spending DESC
    ) AS tier_ranking,
    days_since_first_order
FROM customer_spending
ORDER BY customer_id, order_date;

-- =====================================================
-- Example 4: Advanced Cumulative Patterns
-- =====================================================

-- Demonstrate complex cumulative calculations
WITH sales_analysis AS (
    SELECT
        date,
        product_category,
        sales_amount,
        -- Cumulative sum with reset by category
        SUM(sales_amount) OVER (
            PARTITION BY product_category
            ORDER BY date
            ROWS UNBOUNDED PRECEDING
        ) AS category_cumulative,
        -- Running total with window
        SUM(sales_amount) OVER (
            ORDER BY date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS rolling_total,
        -- Running average with window
        AVG(sales_amount) OVER (
            ORDER BY date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS rolling_average,
        -- Running maximum
        MAX(sales_amount) OVER (
            ORDER BY date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS rolling_max,
        -- Running minimum
        MIN(sales_amount) OVER (
            ORDER BY date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS rolling_min
    FROM sales_transactions
)

SELECT
    date,
    product_category,
    sales_amount,
    category_cumulative,
    rolling_total,
    rolling_average,
    rolling_max,
    rolling_min,
    -- Volatility indicator
    rolling_max - rolling_min AS price_range,
    -- Trend indicator
    CASE
        WHEN sales_amount > rolling_average THEN 'Above Average'
        WHEN sales_amount < rolling_average THEN 'Below Average'
        ELSE 'At Average'
    END AS trend_indicator,
    -- Momentum indicator
    CASE
        WHEN
            sales_amount > LAG(sales_amount, 1) OVER (ORDER BY date)
            THEN 'Increasing'
        WHEN
            sales_amount < LAG(sales_amount, 1) OVER (ORDER BY date)
            THEN 'Decreasing'
        ELSE 'Stable'
    END AS momentum
FROM sales_analysis
ORDER BY date, product_category;

-- =====================================================
-- Example 5: Financial Analysis with Cumulative Metrics
-- =====================================================

-- Calculate financial metrics using cumulative functions
WITH sales_with_cumulative AS (
    SELECT
        date,
        product_category,
        sales_amount,
        -- Cumulative revenue
        SUM(sales_amount) OVER (
            ORDER BY date
            ROWS UNBOUNDED PRECEDING
        ) AS total_revenue,
        -- Cumulative revenue by category
        SUM(sales_amount) OVER (
            PARTITION BY product_category
            ORDER BY date
            ROWS UNBOUNDED PRECEDING
        ) AS category_revenue
    FROM sales_transactions
)
SELECT
    date,
    product_category,
    sales_amount,
    total_revenue,
    category_revenue,
    -- Revenue growth rate
    CASE
        WHEN LAG(total_revenue, 1) OVER (ORDER BY date) > 0
            THEN
                ROUND(
                    (total_revenue - LAG(total_revenue, 1) OVER (ORDER BY date)) * 100.0
                    / LAG(total_revenue, 1) OVER (ORDER BY date), 2
                )
    END AS revenue_growth_percent,
    -- Category contribution to total
    ROUND(
        category_revenue * 100.0 / total_revenue, 2
    ) AS category_contribution_percent,
    -- Running profit margin (assuming 30% margin)
    ROUND(
        SUM(sales_amount * 0.3) OVER (
            ORDER BY date
            ROWS UNBOUNDED PRECEDING
        ) * 100.0 / SUM(sales_amount) OVER (
            ORDER BY date
            ROWS UNBOUNDED PRECEDING
        ), 2
    ) AS cumulative_profit_margin
FROM sales_with_cumulative
ORDER BY date, product_category;

-- Clean up
DROP TABLE IF EXISTS sales_transactions CASCADE;
DROP TABLE IF EXISTS project_tasks CASCADE;
DROP TABLE IF EXISTS customer_orders CASCADE;
