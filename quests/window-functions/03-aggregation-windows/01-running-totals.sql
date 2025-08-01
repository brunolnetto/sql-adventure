-- =====================================================
-- Window Functions: Running Totals and Cumulative Sums
-- =====================================================

-- PURPOSE: Demonstrate basic window function aggregation for running totals
--          and cumulative calculations across time series data
-- LEARNING OUTCOMES: Students will understand how to use SUM() OVER() 
--                    for running totals, cumulative sums, and time-based aggregations
-- EXPECTED RESULTS:
-- 1. Running totals calculated across time periods
-- 2. Cumulative sums with and without partitioning
-- 3. Running averages and percentages
-- 4. Financial analysis with cumulative metrics
-- 5. Customer transaction analysis with running balances
<<<<<<< HEAD
-- DIFFICULTY: 🟡 Intermediate (10-20 min)
=======
-- DIFFICULTY: 🟢 Beginner (5-10 min)
>>>>>>> 4e036c9 (feat(quests) improve quest queries)
-- CONCEPTS: SUM() OVER(), PARTITION BY, ORDER BY, ROWS UNBOUNDED PRECEDING, cumulative calculations

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS daily_sales CASCADE;
DROP TABLE IF EXISTS monthly_revenue CASCADE;
DROP TABLE IF EXISTS customer_transactions CASCADE;

-- Create sample daily sales table
CREATE TABLE daily_sales (
    sale_date DATE PRIMARY KEY,
    sales_amount DECIMAL(10,2),
    product_category VARCHAR(50)
);

-- Insert sample data
INSERT INTO daily_sales VALUES
('2024-01-01', 1250.00, 'Electronics'),
('2024-01-02', 980.50, 'Electronics'),
('2024-01-03', 1450.75, 'Electronics'),
('2024-01-04', 1120.25, 'Electronics'),
('2024-01-05', 1680.00, 'Electronics'),
('2024-01-06', 890.00, 'Electronics'),
('2024-01-07', 1340.50, 'Electronics'),
('2024-01-08', 1560.75, 'Electronics'),
('2024-01-09', 1020.00, 'Electronics'),
('2024-01-10', 1780.25, 'Electronics');

-- =====================================================
-- Example 1: Basic Running Total
-- =====================================================

-- Calculate running total of daily sales
SELECT 
    sale_date,
    sales_amount,
    SUM(sales_amount) OVER (ORDER BY sale_date) as running_total,
    SUM(sales_amount) OVER (ORDER BY sale_date ROWS UNBOUNDED PRECEDING) as explicit_running_total
FROM daily_sales
ORDER BY sale_date;

-- =====================================================
-- Example 2: Running Total with Partition
-- =====================================================

-- Add more categories to demonstrate partitioning
INSERT INTO daily_sales VALUES
('2024-01-01', 850.00, 'Clothing'),
('2024-01-02', 920.00, 'Clothing'),
('2024-01-03', 780.50, 'Clothing'),
('2024-01-04', 1100.00, 'Clothing'),
('2024-01-05', 950.25, 'Clothing'),
('2024-01-06', 1200.00, 'Clothing'),
('2024-01-07', 890.75, 'Clothing'),
('2024-01-08', 1050.00, 'Clothing'),
('2024-01-09', 980.50, 'Clothing'),
('2024-01-10', 1150.00, 'Clothing')
ON CONFLICT (sale_date) DO UPDATE SET 
    sales_amount = EXCLUDED.sales_amount,
    product_category = EXCLUDED.product_category;

-- Calculate running totals by product category
SELECT 
    sale_date,
    product_category,
    sales_amount,
    SUM(sales_amount) OVER (
        PARTITION BY product_category 
        ORDER BY sale_date
    ) as category_running_total
FROM daily_sales
ORDER BY product_category, sale_date;

-- =====================================================
-- Example 3: Running Averages
-- =====================================================

-- Calculate running average of daily sales
SELECT 
    sale_date,
    product_category,
    sales_amount,
    ROUND(AVG(sales_amount) OVER (
        PARTITION BY product_category 
        ORDER BY sale_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) as moving_avg_3d,
    ROUND(AVG(sales_amount) OVER (
        PARTITION BY product_category 
        ORDER BY sale_date
        ROWS UNBOUNDED PRECEDING
    ), 2) as running_avg
FROM daily_sales
ORDER BY product_category, sale_date;

-- =====================================================
-- Example 4: Running Counts and Percentages
-- =====================================================

-- Calculate running counts and percentages
SELECT 
    sale_date,
    product_category,
    sales_amount,
    COUNT(*) OVER (
        PARTITION BY product_category 
        ORDER BY sale_date
    ) as days_count,
    ROUND(
        sales_amount * 100.0 / SUM(sales_amount) OVER (
            PARTITION BY product_category 
            ORDER BY sale_date
        ), 2
    ) as running_percentage
FROM daily_sales
ORDER BY product_category, sale_date;

-- =====================================================
-- Example 5: Financial Analysis with Running Totals
-- =====================================================

-- Create monthly revenue table for financial analysis
CREATE TABLE monthly_revenue (
    month_year VARCHAR(7),
    revenue DECIMAL(12,2),
    expenses DECIMAL(12,2)
);

INSERT INTO monthly_revenue VALUES
('2024-01', 45000.00, 32000.00),
('2024-02', 52000.00, 35000.00),
('2024-03', 48000.00, 33000.00),
('2024-04', 55000.00, 38000.00),
('2024-05', 61000.00, 42000.00),
('2024-06', 58000.00, 40000.00),
('2024-07', 65000.00, 45000.00),
('2024-08', 62000.00, 43000.00),
('2024-09', 68000.00, 47000.00),
('2024-10', 72000.00, 50000.00),
('2024-11', 75000.00, 52000.00),
('2024-12', 80000.00, 55000.00);

-- Calculate running financial metrics
SELECT 
    month_year,
    revenue,
    expenses,
    revenue - expenses as net_income,
    SUM(revenue) OVER (ORDER BY month_year) as cumulative_revenue,
    SUM(expenses) OVER (ORDER BY month_year) as cumulative_expenses,
    SUM(revenue - expenses) OVER (ORDER BY month_year) as cumulative_net_income,
    ROUND(
        (revenue - expenses) * 100.0 / revenue, 2
    ) as profit_margin,
    ROUND(
        SUM(revenue - expenses) OVER (ORDER BY month_year) * 100.0 / 
        SUM(revenue) OVER (ORDER BY month_year), 2
    ) as cumulative_profit_margin
FROM monthly_revenue
ORDER BY month_year;

-- =====================================================
-- Example 6: Customer Transaction Analysis
-- =====================================================

-- Create customer transactions table
CREATE TABLE customer_transactions (
    transaction_id INT PRIMARY KEY,
    customer_id INT,
    transaction_date DATE,
    amount DECIMAL(10,2),
    transaction_type VARCHAR(20)
);

INSERT INTO customer_transactions VALUES
(1, 101, '2024-01-01', 150.00, 'Purchase'),
(2, 101, '2024-01-05', 75.50, 'Purchase'),
(3, 101, '2024-01-10', 200.00, 'Purchase'),
(4, 101, '2024-01-15', -25.00, 'Refund'),
(5, 101, '2024-01-20', 120.00, 'Purchase'),
(6, 102, '2024-01-02', 300.00, 'Purchase'),
(7, 102, '2024-01-08', 180.00, 'Purchase'),
(8, 102, '2024-01-12', -50.00, 'Refund'),
(9, 102, '2024-01-18', 250.00, 'Purchase'),
(10, 102, '2024-01-25', 90.00, 'Purchase'),
(11, 103, '2024-01-03', 500.00, 'Purchase'),
(12, 103, '2024-01-09', 350.00, 'Purchase'),
(13, 103, '2024-01-14', 400.00, 'Purchase'),
(14, 103, '2024-01-21', -100.00, 'Refund'),
(15, 103, '2024-01-28', 600.00, 'Purchase');

-- Analyze customer spending patterns
SELECT 
    customer_id,
    transaction_date,
    amount,
    transaction_type,
    SUM(amount) OVER (
        PARTITION BY customer_id 
        ORDER BY transaction_date
    ) as running_balance,
    COUNT(*) OVER (
        PARTITION BY customer_id 
        ORDER BY transaction_date
    ) as transaction_count,
    ROUND(
        AVG(amount) OVER (
            PARTITION BY customer_id 
            ORDER BY transaction_date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) as moving_avg_amount
FROM customer_transactions
ORDER BY customer_id, transaction_date;

-- =====================================================
-- Example 7: Year-to-Date Analysis
-- =====================================================

-- Calculate year-to-date metrics
SELECT 
    month_year,
    revenue,
    SUM(revenue) OVER (
        ORDER BY month_year 
        ROWS UNBOUNDED PRECEDING
    ) as ytd_revenue,
    ROUND(
        revenue * 100.0 / SUM(revenue) OVER (
            ORDER BY month_year 
            ROWS UNBOUNDED PRECEDING
        ), 2
    ) as revenue_contribution_pct,
    ROUND(
        AVG(revenue) OVER (
            ORDER BY month_year 
            ROWS UNBOUNDED PRECEDING
        ), 2
    ) as ytd_avg_revenue
FROM monthly_revenue
ORDER BY month_year;

-- =====================================================
-- Example 8: Growth Rate Analysis
-- =====================================================

-- Calculate month-over-month growth rates
WITH growth_analysis AS (
    SELECT 
        month_year,
        revenue,
        LAG(revenue) OVER (ORDER BY month_year) as prev_month_revenue
    FROM monthly_revenue
)
SELECT 
    month_year,
    revenue,
    prev_month_revenue,
    ROUND(
        (revenue - prev_month_revenue) * 100.0 / prev_month_revenue, 2
    ) as mom_growth_pct,
    ROUND(
        revenue * 100.0 / FIRST_VALUE(revenue) OVER (ORDER BY month_year), 2
    ) as growth_vs_january
FROM growth_analysis
ORDER BY month_year;

-- =====================================================
-- Example 9: Rolling Windows with Different Frames
-- =====================================================

-- Demonstrate different window frame specifications
SELECT 
    sale_date,
    product_category,
    sales_amount,
    -- Current row only
    SUM(sales_amount) OVER (
        PARTITION BY product_category 
        ORDER BY sale_date
        ROWS CURRENT ROW
    ) as current_day_only,
    -- Current row and 1 preceding
    SUM(sales_amount) OVER (
        PARTITION BY product_category 
        ORDER BY sale_date
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) as current_and_prev,
    -- Current row and 1 following
    SUM(sales_amount) OVER (
        PARTITION BY product_category 
        ORDER BY sale_date
        ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING
    ) as current_and_next,
    -- 2 preceding to 1 following
    SUM(sales_amount) OVER (
        PARTITION BY product_category 
        ORDER BY sale_date
        ROWS BETWEEN 2 PRECEDING AND 1 FOLLOWING
    ) as rolling_5_day
FROM daily_sales
ORDER BY product_category, sale_date;

-- =====================================================
-- Example 10: Complex Running Calculations
-- =====================================================

-- Complex financial analysis with multiple running calculations
SELECT 
    month_year,
    revenue,
    expenses,
    revenue - expenses as net_income,
    -- Running totals
    SUM(revenue) OVER (ORDER BY month_year) as cumulative_revenue,
    SUM(expenses) OVER (ORDER BY month_year) as cumulative_expenses,
    SUM(revenue - expenses) OVER (ORDER BY month_year) as cumulative_net_income,
    -- Running averages
    ROUND(AVG(revenue) OVER (ORDER BY month_year), 2) as avg_revenue_ytd,
    ROUND(AVG(expenses) OVER (ORDER BY month_year), 2) as avg_expenses_ytd,
    -- Running ratios
    ROUND(
        SUM(revenue - expenses) OVER (ORDER BY month_year) * 100.0 / 
        SUM(revenue) OVER (ORDER BY month_year), 2
    ) as cumulative_profit_margin,
    -- Growth metrics
    ROUND(
        revenue * 100.0 / FIRST_VALUE(revenue) OVER (ORDER BY month_year), 2
    ) as revenue_growth_vs_january
FROM monthly_revenue
ORDER BY month_year;

-- Clean up
DROP TABLE IF EXISTS daily_sales CASCADE;
DROP TABLE IF EXISTS monthly_revenue CASCADE;
DROP TABLE IF EXISTS customer_transactions CASCADE; 