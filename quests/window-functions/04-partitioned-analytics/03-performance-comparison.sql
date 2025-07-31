-- =====================================================
-- Window Functions: Performance Comparison Analysis
-- =====================================================

-- PURPOSE: Demonstrate advanced performance comparison using window functions for business analytics
-- LEARNING OUTCOMES:
--   - Master quarter-over-quarter and year-over-year comparisons
--   - Understand performance benchmarking and ranking
--   - Apply LAG/LEAD functions for time series analysis
-- EXPECTED RESULTS: Comprehensive performance analysis with growth metrics and benchmarking
-- DIFFICULTY: 🔴 Advanced (15-30 min)
-- CONCEPTS: LAG/LEAD, Quarter-over-Quarter, Year-over-Year, Performance Benchmarking, Growth Analysis

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS quarterly_sales CASCADE;
DROP TABLE IF EXISTS employee_performance CASCADE;
DROP TABLE IF EXISTS regional_performance CASCADE;

-- Create quarterly sales table
CREATE TABLE quarterly_sales (
    quarter_id INT PRIMARY KEY,
    quarter_name VARCHAR(10),
    year INT,
    region VARCHAR(50),
    product_category VARCHAR(50),
    sales_amount DECIMAL(12,2),
    units_sold INT,
    profit_margin DECIMAL(5,2)
);

-- Create employee performance table
CREATE TABLE employee_performance (
    employee_id INT,
    employee_name VARCHAR(100),
    department VARCHAR(50),
    quarter VARCHAR(10),
    year INT,
    sales_amount DECIMAL(10,2),
    deals_closed INT,
    customer_satisfaction DECIMAL(3,2)
);

-- Create regional performance table
CREATE TABLE regional_performance (
    region_id INT,
    region_name VARCHAR(50),
    month_year VARCHAR(10),
    revenue DECIMAL(12,2),
    expenses DECIMAL(12,2),
    profit DECIMAL(12,2),
    customer_count INT
);

-- Insert quarterly sales data
INSERT INTO quarterly_sales VALUES
-- 2023 Q1
(1, 'Q1', 2023, 'North', 'Electronics', 1250000.00, 2500, 15.5),
(2, 'Q1', 2023, 'South', 'Electronics', 980000.00, 1950, 14.8),
(3, 'Q1', 2023, 'East', 'Electronics', 1100000.00, 2200, 16.2),
(4, 'Q1', 2023, 'West', 'Electronics', 890000.00, 1780, 13.9),
(5, 'Q1', 2023, 'North', 'Furniture', 850000.00, 850, 22.1),
(6, 'Q1', 2023, 'South', 'Furniture', 720000.00, 720, 21.5),
(7, 'Q1', 2023, 'East', 'Furniture', 950000.00, 950, 23.2),
(8, 'Q1', 2023, 'West', 'Furniture', 680000.00, 680, 20.8),

-- 2023 Q2
(9, 'Q2', 2023, 'North', 'Electronics', 1350000.00, 2700, 16.1),
(10, 'Q2', 2023, 'South', 'Electronics', 1020000.00, 2040, 15.2),
(11, 'Q2', 2023, 'East', 'Electronics', 1200000.00, 2400, 16.8),
(12, 'Q2', 2023, 'West', 'Electronics', 920000.00, 1840, 14.5),
(13, 'Q2', 2023, 'North', 'Furniture', 920000.00, 920, 22.8),
(14, 'Q2', 2023, 'South', 'Furniture', 780000.00, 780, 21.9),
(15, 'Q2', 2023, 'East', 'Furniture', 1050000.00, 1050, 23.5),
(16, 'Q2', 2023, 'West', 'Furniture', 720000.00, 720, 21.2),

-- 2023 Q3
(17, 'Q3', 2023, 'North', 'Electronics', 1450000.00, 2900, 16.5),
(18, 'Q3', 2023, 'South', 'Electronics', 1080000.00, 2160, 15.6),
(19, 'Q3', 2023, 'East', 'Electronics', 1300000.00, 2600, 17.1),
(20, 'Q3', 2023, 'West', 'Electronics', 980000.00, 1960, 14.9),
(21, 'Q3', 2023, 'North', 'Furniture', 980000.00, 980, 23.2),
(22, 'Q3', 2023, 'South', 'Furniture', 820000.00, 820, 22.1),
(23, 'Q3', 2023, 'East', 'Furniture', 1150000.00, 1150, 23.8),
(24, 'Q3', 2023, 'West', 'Furniture', 760000.00, 760, 21.5),

-- 2023 Q4
(25, 'Q4', 2023, 'North', 'Electronics', 1550000.00, 3100, 16.8),
(26, 'Q4', 2023, 'South', 'Electronics', 1150000.00, 2300, 15.9),
(27, 'Q4', 2023, 'East', 'Electronics', 1400000.00, 2800, 17.3),
(28, 'Q4', 2023, 'West', 'Electronics', 1050000.00, 2100, 15.2),
(29, 'Q4', 2023, 'North', 'Furniture', 1050000.00, 1050, 23.5),
(30, 'Q4', 2023, 'South', 'Furniture', 880000.00, 880, 22.4),
(31, 'Q4', 2023, 'East', 'Furniture', 1250000.00, 1250, 24.1),
(32, 'Q4', 2023, 'West', 'Furniture', 820000.00, 820, 21.8),

-- 2024 Q1
(33, 'Q1', 2024, 'North', 'Electronics', 1650000.00, 3300, 17.1),
(34, 'Q1', 2024, 'South', 'Electronics', 1220000.00, 2440, 16.2),
(35, 'Q1', 2024, 'East', 'Electronics', 1500000.00, 3000, 17.6),
(36, 'Q1', 2024, 'West', 'Electronics', 1120000.00, 2240, 15.5),
(37, 'Q1', 2024, 'North', 'Furniture', 1120000.00, 1120, 23.8),
(38, 'Q1', 2024, 'South', 'Furniture', 940000.00, 940, 22.7),
(39, 'Q1', 2024, 'East', 'Furniture', 1350000.00, 1350, 24.4),
(40, 'Q1', 2024, 'West', 'Furniture', 880000.00, 880, 22.1);

-- Insert employee performance data
INSERT INTO employee_performance VALUES
-- Sales Team
(1, 'Alice Johnson', 'Sales', 'Q1', 2023, 125000.00, 15, 4.2),
(1, 'Alice Johnson', 'Sales', 'Q2', 2023, 135000.00, 18, 4.3),
(1, 'Alice Johnson', 'Sales', 'Q3', 2023, 145000.00, 20, 4.4),
(1, 'Alice Johnson', 'Sales', 'Q4', 2023, 155000.00, 22, 4.5),
(1, 'Alice Johnson', 'Sales', 'Q1', 2024, 165000.00, 25, 4.6),

(2, 'Bob Smith', 'Sales', 'Q1', 2023, 98000.00, 12, 4.1),
(2, 'Bob Smith', 'Sales', 'Q2', 2023, 102000.00, 14, 4.2),
(2, 'Bob Smith', 'Sales', 'Q3', 2023, 108000.00, 16, 4.3),
(2, 'Bob Smith', 'Sales', 'Q4', 2023, 115000.00, 18, 4.4),
(2, 'Bob Smith', 'Sales', 'Q1', 2024, 122000.00, 20, 4.5),

(3, 'Carol Davis', 'Sales', 'Q1', 2023, 110000.00, 14, 4.3),
(3, 'Carol Davis', 'Sales', 'Q2', 2023, 120000.00, 17, 4.4),
(3, 'Carol Davis', 'Sales', 'Q3', 2023, 130000.00, 19, 4.5),
(3, 'Carol Davis', 'Sales', 'Q4', 2023, 140000.00, 21, 4.6),
(3, 'Carol Davis', 'Sales', 'Q1', 2024, 150000.00, 24, 4.7),

-- Marketing Team
(4, 'David Wilson', 'Marketing', 'Q1', 2023, 85000.00, 8, 4.0),
(4, 'David Wilson', 'Marketing', 'Q2', 2023, 92000.00, 10, 4.1),
(4, 'David Wilson', 'Marketing', 'Q3', 2023, 98000.00, 12, 4.2),
(4, 'David Wilson', 'Marketing', 'Q4', 2023, 105000.00, 14, 4.3),
(4, 'David Wilson', 'Marketing', 'Q1', 2024, 112000.00, 16, 4.4);

-- Insert regional performance data
INSERT INTO regional_performance VALUES
-- North Region
(1, 'North', '2023-01', 450000.00, 320000.00, 130000.00, 1250),
(2, 'North', '2023-02', 480000.00, 340000.00, 140000.00, 1320),
(3, 'North', '2023-03', 520000.00, 360000.00, 160000.00, 1400),
(4, 'North', '2023-04', 550000.00, 380000.00, 170000.00, 1480),
(5, 'North', '2023-05', 580000.00, 400000.00, 180000.00, 1550),
(6, 'North', '2023-06', 620000.00, 420000.00, 200000.00, 1620),
(7, 'North', '2023-07', 650000.00, 440000.00, 210000.00, 1680),
(8, 'North', '2023-08', 680000.00, 460000.00, 220000.00, 1750),
(9, 'North', '2023-09', 720000.00, 480000.00, 240000.00, 1820),
(10, 'North', '2023-10', 750000.00, 500000.00, 250000.00, 1880),
(11, 'North', '2023-11', 780000.00, 520000.00, 260000.00, 1950),
(12, 'North', '2023-12', 820000.00, 540000.00, 280000.00, 2020),

-- South Region
(13, 'South', '2023-01', 380000.00, 280000.00, 100000.00, 1100),
(14, 'South', '2023-02', 400000.00, 290000.00, 110000.00, 1150),
(15, 'South', '2023-03', 420000.00, 300000.00, 120000.00, 1200),
(16, 'South', '2023-04', 440000.00, 310000.00, 130000.00, 1250),
(17, 'South', '2023-05', 460000.00, 320000.00, 140000.00, 1300),
(18, 'South', '2023-06', 480000.00, 330000.00, 150000.00, 1350),
(19, 'South', '2023-07', 500000.00, 340000.00, 160000.00, 1400),
(20, 'South', '2023-08', 520000.00, 350000.00, 170000.00, 1450),
(21, 'South', '2023-09', 540000.00, 360000.00, 180000.00, 1500),
(22, 'South', '2023-10', 560000.00, 370000.00, 190000.00, 1550),
(23, 'South', '2023-11', 580000.00, 380000.00, 200000.00, 1600),
(24, 'South', '2023-12', 600000.00, 390000.00, 210000.00, 1650);

-- =====================================================
-- Example 1: Quarter-over-Quarter Growth Analysis
-- =====================================================

-- Analyze quarter-over-quarter growth for each region and category
WITH qoq_growth AS (
    SELECT 
        region,
        product_category,
        year,
        quarter_name,
        sales_amount,
        LAG(sales_amount) OVER (PARTITION BY region, product_category ORDER BY year, quarter_name) as prev_quarter_sales,
        LAG(sales_amount, 4) OVER (PARTITION BY region, product_category ORDER BY year, quarter_name) as prev_year_quarter_sales
    FROM quarterly_sales
)
SELECT 
    region,
    product_category,
    year,
    quarter_name,
    sales_amount,
    prev_quarter_sales,
    prev_year_quarter_sales,
    ROUND(
        (sales_amount - prev_quarter_sales) * 100.0 / NULLIF(prev_quarter_sales, 0), 2
    ) as qoq_growth_percent,
    ROUND(
        (sales_amount - prev_year_quarter_sales) * 100.0 / NULLIF(prev_year_quarter_sales, 0), 2
    ) as yoy_growth_percent,
    CASE 
        WHEN (sales_amount - prev_quarter_sales) > 0 THEN 'Growth'
        WHEN (sales_amount - prev_quarter_sales) < 0 THEN 'Decline'
        ELSE 'No Change'
    END as qoq_trend
FROM qoq_growth
WHERE prev_quarter_sales IS NOT NULL
ORDER BY region, product_category, year, quarter_name;

-- =====================================================
-- Example 2: Regional Performance Benchmarking
-- =====================================================

-- Compare regional performance against overall average
WITH regional_benchmarks AS (
    SELECT 
        region,
        product_category,
        year,
        quarter_name,
        sales_amount,
        AVG(sales_amount) OVER (PARTITION BY year, quarter_name, product_category) as avg_sales_by_quarter,
        AVG(sales_amount) OVER (PARTITION BY region, product_category) as avg_sales_by_region,
        AVG(sales_amount) OVER () as overall_avg_sales,
        RANK() OVER (PARTITION BY year, quarter_name, product_category ORDER BY sales_amount DESC) as regional_rank,
        NTILE(4) OVER (PARTITION BY year, quarter_name, product_category ORDER BY sales_amount) as performance_quartile
    FROM quarterly_sales
)
SELECT 
    region,
    product_category,
    year,
    quarter_name,
    sales_amount,
    ROUND(avg_sales_by_quarter, 2) as avg_sales_by_quarter,
    ROUND(avg_sales_by_region, 2) as avg_sales_by_region,
    ROUND(overall_avg_sales, 2) as overall_avg_sales,
    ROUND(sales_amount * 100.0 / avg_sales_by_quarter, 1) as vs_quarter_avg_percent,
    ROUND(sales_amount * 100.0 / avg_sales_by_region, 1) as vs_region_avg_percent,
    regional_rank,
    performance_quartile,
    CASE 
        WHEN sales_amount > avg_sales_by_quarter THEN 'Above Average'
        WHEN sales_amount < avg_sales_by_quarter THEN 'Below Average'
        ELSE 'Average'
    END as performance_status
FROM regional_benchmarks
ORDER BY year, quarter_name, product_category, regional_rank;

-- =====================================================
-- Example 3: Employee Performance Trends
-- =====================================================

-- Analyze employee performance trends over time
WITH employee_trends AS (
    SELECT 
        employee_id,
        employee_name,
        department,
        quarter,
        year,
        sales_amount,
        deals_closed,
        customer_satisfaction,
        LAG(sales_amount) OVER (PARTITION BY employee_id ORDER BY year, quarter) as prev_quarter_sales,
        LAG(sales_amount, 4) OVER (PARTITION BY employee_id ORDER BY year, quarter) as prev_year_sales,
        AVG(sales_amount) OVER (PARTITION BY employee_id) as avg_sales,
        RANK() OVER (PARTITION BY year, quarter ORDER BY sales_amount DESC) as sales_rank,
        NTILE(5) OVER (PARTITION BY year, quarter ORDER BY sales_amount) as performance_quintile
    FROM employee_performance
)
SELECT 
    employee_name,
    department,
    quarter,
    year,
    sales_amount,
    deals_closed,
    customer_satisfaction,
    prev_quarter_sales,
    prev_year_sales,
    ROUND(avg_sales, 2) as avg_sales,
    ROUND(
        (sales_amount - prev_quarter_sales) * 100.0 / NULLIF(prev_quarter_sales, 0), 2
    ) as qoq_growth_percent,
    ROUND(
        (sales_amount - prev_year_sales) * 100.0 / NULLIF(prev_year_sales, 0), 2
    ) as yoy_growth_percent,
    sales_rank,
    performance_quintile,
    CASE 
        WHEN sales_amount > avg_sales THEN 'Above Average'
        WHEN sales_amount < avg_sales THEN 'Below Average'
        ELSE 'Average'
    END as performance_vs_avg
FROM employee_trends
ORDER BY employee_id, year, quarter;

-- =====================================================
-- Example 4: Profit Margin Analysis
-- =====================================================

-- Analyze profit margin trends and comparisons
WITH margin_analysis AS (
    SELECT 
        region,
        product_category,
        year,
        quarter_name,
        sales_amount,
        profit_margin,
        LAG(profit_margin) OVER (PARTITION BY region, product_category ORDER BY year, quarter_name) as prev_margin,
        AVG(profit_margin) OVER (PARTITION BY region, product_category) as avg_margin_by_region,
        AVG(profit_margin) OVER (PARTITION BY product_category) as avg_margin_by_category,
        AVG(profit_margin) OVER () as overall_avg_margin,
        RANK() OVER (PARTITION BY year, quarter_name, product_category ORDER BY profit_margin DESC) as margin_rank
    FROM quarterly_sales
)
SELECT 
    region,
    product_category,
    year,
    quarter_name,
    sales_amount,
    profit_margin,
    prev_margin,
    ROUND(avg_margin_by_region, 2) as avg_margin_by_region,
    ROUND(avg_margin_by_category, 2) as avg_margin_by_category,
    ROUND(overall_avg_margin, 2) as overall_avg_margin,
    ROUND(profit_margin - prev_margin, 2) as margin_change,
    ROUND(
        (profit_margin - prev_margin) * 100.0 / NULLIF(prev_margin, 0), 2
    ) as margin_change_percent,
    margin_rank,
    CASE 
        WHEN profit_margin > avg_margin_by_region THEN 'Above Regional Avg'
        WHEN profit_margin < avg_margin_by_region THEN 'Below Regional Avg'
        ELSE 'At Regional Avg'
    END as regional_margin_status
FROM margin_analysis
WHERE prev_margin IS NOT NULL
ORDER BY region, product_category, year, quarter_name;

-- =====================================================
-- Example 5: Rolling Performance Metrics
-- =====================================================

-- Calculate rolling performance metrics for regional data
WITH rolling_metrics AS (
    SELECT 
        region_name,
        month_year,
        revenue,
        expenses,
        profit,
        customer_count,
        -- 3-month rolling averages
        AVG(revenue) OVER (
            PARTITION BY region_name 
            ORDER BY month_year 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as rolling_avg_revenue_3m,
        AVG(profit) OVER (
            PARTITION BY region_name 
            ORDER BY month_year 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as rolling_avg_profit_3m,
        -- 6-month rolling averages
        AVG(revenue) OVER (
            PARTITION BY region_name 
            ORDER BY month_year 
            ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
        ) as rolling_avg_revenue_6m,
        AVG(profit) OVER (
            PARTITION BY region_name 
            ORDER BY month_year 
            ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
        ) as rolling_avg_profit_6m,
        -- Rolling totals
        SUM(revenue) OVER (
            PARTITION BY region_name 
            ORDER BY month_year 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as rolling_total_revenue_3m,
        SUM(profit) OVER (
            PARTITION BY region_name 
            ORDER BY month_year 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as rolling_total_profit_3m
    FROM regional_performance
)
SELECT 
    region_name,
    month_year,
    revenue,
    expenses,
    profit,
    customer_count,
    ROUND(rolling_avg_revenue_3m, 2) as rolling_avg_revenue_3m,
    ROUND(rolling_avg_profit_3m, 2) as rolling_avg_profit_3m,
    ROUND(rolling_avg_revenue_6m, 2) as rolling_avg_revenue_6m,
    ROUND(rolling_avg_profit_6m, 2) as rolling_avg_profit_6m,
    ROUND(rolling_total_revenue_3m, 2) as rolling_total_revenue_3m,
    ROUND(rolling_total_profit_3m, 2) as rolling_total_profit_3m,
    ROUND(profit * 100.0 / revenue, 2) as profit_margin_percent,
    ROUND(rolling_avg_profit_3m * 100.0 / rolling_avg_revenue_3m, 2) as rolling_profit_margin_3m
FROM rolling_metrics
ORDER BY region_name, month_year;

-- =====================================================
-- Example 6: Performance Consistency Analysis
-- =====================================================

-- Analyze performance consistency across regions and categories
WITH consistency_metrics AS (
    SELECT 
        region,
        product_category,
        COUNT(*) as quarters_count,
        AVG(sales_amount) as avg_sales,
        STDDEV(sales_amount) as sales_stddev,
        MIN(sales_amount) as min_sales,
        MAX(sales_amount) as max_sales,
        AVG(profit_margin) as avg_margin,
        STDDEV(profit_margin) as margin_stddev
    FROM quarterly_sales
    GROUP BY region, product_category
)
SELECT 
    region,
    product_category,
    quarters_count,
    ROUND(avg_sales, 2) as avg_sales,
    ROUND(sales_stddev, 2) as sales_stddev,
    ROUND(min_sales, 2) as min_sales,
    ROUND(max_sales, 2) as max_sales,
    ROUND(avg_margin, 2) as avg_margin,
    ROUND(margin_stddev, 2) as margin_stddev,
    ROUND(sales_stddev * 100.0 / avg_sales, 2) as sales_coefficient_variation,
    ROUND(margin_stddev * 100.0 / avg_margin, 2) as margin_coefficient_variation,
    CASE 
        WHEN sales_stddev * 100.0 / avg_sales < 10 THEN 'Very Consistent'
        WHEN sales_stddev * 100.0 / avg_sales < 20 THEN 'Consistent'
        WHEN sales_stddev * 100.0 / avg_sales < 30 THEN 'Moderate'
        ELSE 'Volatile'
    END as sales_consistency,
    CASE 
        WHEN margin_stddev * 100.0 / avg_margin < 5 THEN 'Very Stable'
        WHEN margin_stddev * 100.0 / avg_margin < 10 THEN 'Stable'
        WHEN margin_stddev * 100.0 / avg_margin < 15 THEN 'Moderate'
        ELSE 'Unstable'
    END as margin_stability
FROM consistency_metrics
ORDER BY region, product_category;

-- Clean up
DROP TABLE IF EXISTS quarterly_sales CASCADE;
DROP TABLE IF EXISTS employee_performance CASCADE;
DROP TABLE IF EXISTS regional_performance CASCADE; 