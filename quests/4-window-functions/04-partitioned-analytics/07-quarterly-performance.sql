-- =====================================================
-- Window Functions: Quarterly Performance Analysis
-- =====================================================

-- PURPOSE: Demonstrate advanced window functions for quarterly performance analysis
--          including quarter-over-quarter comparisons and regional benchmarking
-- LEARNING OUTCOMES: Students will understand how to use window functions for
--                    time-based comparisons, regional analysis, and peer benchmarking
-- EXPECTED RESULTS:
-- 1. Quarter-over-quarter performance comparisons
-- 2. Regional performance benchmarking
-- 3. Individual performance vs peer analysis
-- DIFFICULTY: 🔴 Advanced (15-30 min)
-- CONCEPTS: LAG/LEAD functions, PARTITION BY, PERCENT_RANK(), 
--           peer comparison, regional benchmarking

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS sales_performance CASCADE;

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

-- =====================================================
-- Example 1: Quarter-over-Quarter Performance Comparison
-- =====================================================

-- Compare sales performance across quarters
WITH quarterly_performance AS (
    SELECT 
        salesperson_id,
        salesperson_name,
        region,
        product_category,
        quarter,
        year,
        sales_amount,
        -- Previous quarter sales
        LAG(sales_amount) OVER (
            PARTITION BY salesperson_id, product_category 
            ORDER BY year, quarter
        ) as prev_quarter_sales,
        -- Next quarter sales
        LEAD(sales_amount) OVER (
            PARTITION BY salesperson_id, product_category 
            ORDER BY year, quarter
        ) as next_quarter_sales,
        -- Quarter-over-quarter growth
        ROUND(
            (sales_amount - LAG(sales_amount) OVER (
                PARTITION BY salesperson_id, product_category 
                ORDER BY year, quarter
            )) * 100.0 / NULLIF(LAG(sales_amount) OVER (
                PARTITION BY salesperson_id, product_category 
                ORDER BY year, quarter
            ), 0), 2
        ) as qoq_growth_pct
    FROM sales_performance
)
SELECT 
    salesperson_name,
    region,
    product_category,
    quarter,
    year,
    sales_amount,
    prev_quarter_sales,
    next_quarter_sales,
    qoq_growth_pct,
    CASE 
        WHEN qoq_growth_pct > 10 THEN 'Strong Growth'
        WHEN qoq_growth_pct > 0 THEN 'Moderate Growth'
        WHEN qoq_growth_pct > -10 THEN 'Slight Decline'
        ELSE 'Significant Decline'
    END as performance_trend
FROM quarterly_performance
ORDER BY salesperson_id, product_category, year, quarter;

-- =====================================================
-- Example 2: Regional Performance Benchmarking
-- =====================================================

-- Compare regional performance with benchmarks
WITH regional_benchmarks AS (
    SELECT 
        region,
        product_category,
        quarter,
        year,
        SUM(sales_amount) as total_sales,
        AVG(sales_amount) as avg_sales_per_person,
        COUNT(DISTINCT salesperson_id) as salesperson_count,
        -- Regional ranking
        ROW_NUMBER() OVER (
            PARTITION BY product_category, quarter, year 
            ORDER BY SUM(sales_amount) DESC
        ) as regional_rank,
        -- Regional percentile
        ROUND((PERCENT_RANK() OVER (
            PARTITION BY product_category, quarter, year 
            ORDER BY SUM(sales_amount)
        ))::NUMERIC, 3) as regional_percentile
    FROM sales_performance
    GROUP BY region, product_category, quarter, year
)
SELECT 
    region,
    product_category,
    quarter,
    year,
    total_sales,
    avg_sales_per_person,
    salesperson_count,
    regional_rank,
    regional_percentile,
    CASE 
        WHEN regional_percentile >= 0.8 THEN 'Top Performer'
        WHEN regional_percentile >= 0.6 THEN 'Above Average'
        WHEN regional_percentile >= 0.4 THEN 'Average'
        WHEN regional_percentile >= 0.2 THEN 'Below Average'
        ELSE 'Needs Improvement'
    END as performance_level
FROM regional_benchmarks
ORDER BY product_category, quarter, year, regional_rank;

-- =====================================================
-- Example 3: Individual Performance vs Peers
-- =====================================================

-- Compare individual performance against peers in same region/category
WITH peer_comparison AS (
    SELECT 
        salesperson_id,
        salesperson_name,
        region,
        product_category,
        quarter,
        year,
        sales_amount,
        -- Peer average in same region and category
        AVG(sales_amount) OVER (
            PARTITION BY region, product_category, quarter, year
        ) as peer_avg_sales,
        -- Peer median in same region and category
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sales_amount) OVER (
            PARTITION BY region, product_category, quarter, year
        ) as peer_median_sales,
        -- Performance vs peer average
        ROUND(
            (sales_amount - AVG(sales_amount) OVER (
                PARTITION BY region, product_category, quarter, year
            )) * 100.0 / NULLIF(AVG(sales_amount) OVER (
                PARTITION BY region, product_category, quarter, year
            ), 0), 2
        ) as vs_peer_avg_pct,
        -- Ranking within peer group
        ROW_NUMBER() OVER (
            PARTITION BY region, product_category, quarter, year 
            ORDER BY sales_amount DESC
        ) as peer_rank,
        -- Percentile within peer group
        ROUND((PERCENT_RANK() OVER (
            PARTITION BY region, product_category, quarter, year 
            ORDER BY sales_amount
        ))::NUMERIC, 3) as peer_percentile
    FROM sales_performance
)
SELECT 
    salesperson_name,
    region,
    product_category,
    quarter,
    year,
    sales_amount,
    peer_avg_sales,
    peer_median_sales,
    vs_peer_avg_pct,
    peer_rank,
    peer_percentile,
    CASE 
        WHEN vs_peer_avg_pct > 20 THEN 'Outstanding'
        WHEN vs_peer_avg_pct > 10 THEN 'Above Average'
        WHEN vs_peer_avg_pct > -10 THEN 'Average'
        WHEN vs_peer_avg_pct > -20 THEN 'Below Average'
        ELSE 'Needs Support'
    END as peer_performance
FROM peer_comparison
ORDER BY region, product_category, quarter, year, peer_rank;

-- Clean up
DROP TABLE IF EXISTS sales_performance CASCADE; 