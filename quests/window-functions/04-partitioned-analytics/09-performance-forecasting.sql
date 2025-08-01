-- =====================================================
-- Window Functions: Performance Forecasting & Consistency
-- =====================================================

-- PURPOSE: Demonstrate advanced window functions for performance forecasting
--          and consistency analysis using statistical measures
-- LEARNING OUTCOMES: Students will understand how to use window functions for
--                    performance forecasting, consistency analysis, and trend prediction
-- EXPECTED RESULTS:
-- 1. Performance consistency analysis across periods
-- 2. Performance forecasting using trend analysis
-- 3. Confidence level assessment for predictions
-- DIFFICULTY: 🔴 Advanced (15-30 min)
-- CONCEPTS: Performance Forecasting, Consistency Analysis, Statistical Measures,
--           rolling calculations, trend analysis

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
-- Example 1: Performance Consistency Analysis
-- =====================================================

-- Analyze performance consistency across periods
WITH consistency_analysis AS (
    SELECT 
        salesperson_id,
        salesperson_name,
        region,
        product_category,
        COUNT(*) as periods_count,
        AVG(sales_amount) as avg_performance,
        STDDEV(sales_amount) as performance_volatility,
        MIN(sales_amount) as min_performance,
        MAX(sales_amount) as max_performance,
        -- Coefficient of variation (lower = more consistent)
        CASE 
            WHEN AVG(sales_amount) > 0 THEN 
                ROUND(STDDEV(sales_amount) * 100.0 / AVG(sales_amount), 2)
            ELSE NULL
        END as cv_percent,
        -- Performance range
        MAX(sales_amount) - MIN(sales_amount) as performance_range
    FROM sales_performance
    GROUP BY salesperson_id, salesperson_name, region, product_category
)
SELECT 
    salesperson_name,
    region,
    product_category,
    periods_count,
    avg_performance,
    performance_volatility,
    min_performance,
    max_performance,
    cv_percent,
    performance_range,
    CASE 
        WHEN cv_percent < 10 THEN 'Very Consistent'
        WHEN cv_percent < 20 THEN 'Consistent'
        WHEN cv_percent < 30 THEN 'Moderately Consistent'
        WHEN cv_percent < 40 THEN 'Variable'
        ELSE 'Highly Variable'
    END as consistency_level
FROM consistency_analysis
ORDER BY cv_percent;

-- =====================================================
-- Example 2: Performance Forecasting
-- =====================================================

-- Simple performance forecasting using trend analysis
WITH performance_forecast AS (
    SELECT 
        salesperson_id,
        salesperson_name,
        region,
        product_category,
        quarter,
        year,
        sales_amount,
        -- Calculate trend using linear regression approximation
        AVG(sales_amount) OVER (
            PARTITION BY salesperson_id, product_category 
            ORDER BY year, quarter 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as trend_base,
        -- Simple forecast (trend + recent average)
        ROUND(
            AVG(sales_amount) OVER (
                PARTITION BY salesperson_id, product_category 
                ORDER BY year, quarter 
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ) * 1.05, 2
        ) as forecast_next_quarter,
        -- Confidence level based on consistency
        CASE 
            WHEN STDDEV(sales_amount) OVER (
                PARTITION BY salesperson_id, product_category 
                ORDER BY year, quarter 
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ) < 5000 THEN 'High Confidence'
            WHEN STDDEV(sales_amount) OVER (
                PARTITION BY salesperson_id, product_category 
                ORDER BY year, quarter 
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ) < 10000 THEN 'Medium Confidence'
            ELSE 'Low Confidence'
        END as forecast_confidence
    FROM sales_performance
)
SELECT 
    salesperson_name,
    region,
    product_category,
    quarter,
    year,
    sales_amount,
    trend_base,
    forecast_next_quarter,
    forecast_confidence,
    ROUND(
        (forecast_next_quarter - sales_amount) * 100.0 / NULLIF(sales_amount, 0), 2
    ) as expected_growth_pct
FROM performance_forecast
ORDER BY salesperson_id, product_category, year, quarter;

-- Clean up
DROP TABLE IF EXISTS sales_performance CASCADE; 