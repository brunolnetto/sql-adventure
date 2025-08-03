-- =====================================================
-- Window Functions: Trend Detection and Pattern Analysis
-- =====================================================

-- PURPOSE: Demonstrate advanced trend detection techniques using window functions
--          for identifying patterns, trends, and anomalies in time series data
-- LEARNING OUTCOMES: Students will understand how to use window functions for
--                    trend detection, pattern recognition, anomaly identification,
--                    and predictive analytics in time series data
-- EXPECTED RESULTS:
-- 1. Moving averages calculated for trend smoothing
-- 2. Trend direction identified (increasing, decreasing, stable)
-- 3. Anomaly detection using statistical measures
-- 4. Seasonal patterns identified in time series data
-- 5. Breakpoint detection for trend changes
-- 6. Predictive trend analysis with confidence intervals
-- DIFFICULTY: ⚫ Expert (30-45 min)
-- CONCEPTS: Moving averages, trend analysis, anomaly detection, pattern recognition, statistical measures, time series analysis, predictive analytics

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS sales_trends CASCADE;
DROP TABLE IF EXISTS stock_prices CASCADE;
DROP TABLE IF EXISTS website_metrics CASCADE;
DROP TABLE IF EXISTS temperature_data CASCADE;
DROP TABLE IF EXISTS customer_behavior CASCADE;
DROP TABLE IF EXISTS production_metrics CASCADE;

-- Create sales trends table
CREATE TABLE sales_trends (
    id INT PRIMARY KEY,
    date_id DATE,
    product_category VARCHAR(50),
    daily_sales DECIMAL(10,2),
    units_sold INT
);

-- Insert sample data with trends
INSERT INTO sales_trends VALUES
(1, '2024-01-01', 'Electronics', 12500.00, 25),
(2, '2024-01-02', 'Electronics', 13200.00, 26),
(3, '2024-01-03', 'Electronics', 14100.00, 28),
(4, '2024-01-04', 'Electronics', 13800.00, 27),
(5, '2024-01-05', 'Electronics', 15200.00, 30),
(6, '2024-01-06', 'Electronics', 14800.00, 29),
(7, '2024-01-07', 'Electronics', 16500.00, 33),
(8, '2024-01-08', 'Electronics', 17200.00, 34),
(9, '2024-01-09', 'Electronics', 16800.00, 33),
(10, '2024-01-10', 'Electronics', 18500.00, 37),
(11, '2024-01-11', 'Electronics', 19200.00, 38),
(12, '2024-01-12', 'Electronics', 18800.00, 37),
(13, '2024-01-13', 'Electronics', 20500.00, 41),
(14, '2024-01-14', 'Electronics', 21200.00, 42),
(15, '2024-01-15', 'Electronics', 20800.00, 41);

-- Example 1: Moving Average Trend Analysis
-- Calculate moving averages and identify trend direction
SELECT 
    date_id,
    daily_sales,
    units_sold,
    ROUND(AVG(daily_sales) OVER (ORDER BY date_id ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) as ma_3day,
    ROUND(AVG(daily_sales) OVER (ORDER BY date_id ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) as ma_7day,
    CASE 
        WHEN daily_sales > LAG(daily_sales) OVER (ORDER BY date_id) THEN 'Increasing'
        WHEN daily_sales < LAG(daily_sales) OVER (ORDER BY date_id) THEN 'Decreasing'
        ELSE 'Stable'
    END as day_over_day_trend,
    CASE 
        WHEN AVG(daily_sales) OVER (ORDER BY date_id ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) > 
             AVG(daily_sales) OVER (ORDER BY date_id ROWS BETWEEN 13 PRECEDING AND 7 PRECEDING) THEN 'Upward Trend'
        WHEN AVG(daily_sales) OVER (ORDER BY date_id ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) < 
             AVG(daily_sales) OVER (ORDER BY date_id ROWS BETWEEN 13 PRECEDING AND 7 PRECEDING) THEN 'Downward Trend'
        ELSE 'Sideways Trend'
    END as overall_trend
FROM sales_trends
ORDER BY date_id;

-- Create stock prices table
CREATE TABLE stock_prices (
    id INT PRIMARY KEY,
    date_id DATE,
    stock_symbol VARCHAR(10),
    close_price DECIMAL(8,2),
    volume INT
);

-- Insert sample data with price trends
INSERT INTO stock_prices VALUES
(1, '2024-01-01', 'AAPL', 150.25, 45000000),
(2, '2024-01-02', 'AAPL', 152.80, 52000000),
(3, '2024-01-03', 'AAPL', 151.90, 48000000),
(4, '2024-01-04', 'AAPL', 153.60, 51000000),
(5, '2024-01-05', 'AAPL', 156.40, 55000000),
(6, '2024-01-08', 'AAPL', 158.20, 58000000),
(7, '2024-01-09', 'AAPL', 155.80, 49000000),
(8, '2024-01-10', 'AAPL', 157.60, 53000000),
(9, '2024-01-11', 'AAPL', 159.40, 56000000),
(10, '2024-01-12', 'AAPL', 161.20, 59000000),
(11, '2024-01-15', 'AAPL', 163.00, 62000000),
(12, '2024-01-16', 'AAPL', 160.60, 54000000),
(13, '2024-01-17', 'AAPL', 162.40, 57000000),
(14, '2024-01-18', 'AAPL', 164.20, 60000000),
(15, '2024-01-19', 'AAPL', 166.00, 63000000);

-- Example 2: Anomaly Detection in Stock Prices
-- Detect price anomalies using statistical measures
WITH price_stats AS (
    SELECT 
        date_id,
        close_price,
        volume,
        AVG(close_price) OVER (ORDER BY date_id ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) as avg_price,
        STDDEV(close_price) OVER (ORDER BY date_id ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) as price_stddev,
        AVG(volume) OVER (ORDER BY date_id ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) as avg_volume,
        STDDEV(volume) OVER (ORDER BY date_id ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) as volume_stddev
    FROM stock_prices
    WHERE stock_symbol = 'AAPL'
)
SELECT 
    date_id,
    close_price,
    volume,
    ROUND(avg_price, 2) as moving_avg_price,
    ROUND(price_stddev, 2) as price_volatility,
    ROUND(avg_volume, 0) as moving_avg_volume,
    ROUND(volume_stddev, 0) as volume_volatility,
    CASE 
        WHEN ABS(close_price - avg_price) > 2 * price_stddev THEN 'Price Anomaly'
        ELSE 'Normal Price'
    END as price_anomaly_status,
    CASE 
        WHEN ABS(volume - avg_volume) > 2 * volume_stddev THEN 'Volume Anomaly'
        ELSE 'Normal Volume'
    END as volume_anomaly_status
FROM price_stats
WHERE date_id >= '2024-01-11'  -- Show recent data with enough history
ORDER BY date_id;

-- Create website metrics table
CREATE TABLE website_metrics (
    id INT PRIMARY KEY,
    date_id DATE,
    page_views INT,
    unique_visitors INT,
    bounce_rate DECIMAL(5,2),
    avg_session_duration INT
);

-- Insert sample data with seasonal patterns
INSERT INTO website_metrics VALUES
(1, '2024-01-01', 15000, 8500, 45.2, 180),
(2, '2024-01-02', 16200, 9200, 44.8, 185),
(3, '2024-01-03', 15800, 8900, 46.1, 175),
(4, '2024-01-04', 17500, 9800, 43.5, 195),
(5, '2024-01-05', 18200, 10200, 42.9, 200),
(6, '2024-01-06', 19500, 10800, 41.8, 210),
(7, '2024-01-07', 18800, 10500, 42.5, 205),
(8, '2024-01-08', 17200, 9600, 44.2, 190),
(9, '2024-01-09', 16800, 9400, 45.1, 185),
(10, '2024-01-10', 18500, 10300, 43.1, 195),
(11, '2024-01-11', 19200, 10700, 42.3, 200),
(12, '2024-01-12', 20500, 11400, 41.2, 215),
(13, '2024-01-13', 19800, 11000, 41.8, 210),
(14, '2024-01-14', 18500, 10300, 43.0, 195),
(15, '2024-01-15', 17800, 9900, 44.1, 190);

-- Example 3: Seasonal Pattern Detection
-- Identify weekly patterns in website traffic
SELECT 
    date_id,
    page_views,
    unique_visitors,
    bounce_rate,
    avg_session_duration,
    EXTRACT(DOW FROM date_id) as day_of_week,
    CASE EXTRACT(DOW FROM date_id)
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END as day_name,
    ROUND(AVG(page_views) OVER (PARTITION BY EXTRACT(DOW FROM date_id)), 0) as avg_page_views_by_day,
    ROUND(AVG(bounce_rate) OVER (PARTITION BY EXTRACT(DOW FROM date_id)), 2) as avg_bounce_rate_by_day,
    CASE 
        WHEN page_views > AVG(page_views) OVER (PARTITION BY EXTRACT(DOW FROM date_id)) * 1.1 THEN 'High Traffic Day'
        WHEN page_views < AVG(page_views) OVER (PARTITION BY EXTRACT(DOW FROM date_id)) * 0.9 THEN 'Low Traffic Day'
        ELSE 'Normal Traffic Day'
    END as traffic_pattern
FROM website_metrics
ORDER BY date_id;

-- Create temperature data table
CREATE TABLE temperature_data (
    id INT PRIMARY KEY,
    timestamp TIMESTAMP,
    temperature_celsius DECIMAL(4,2),
    humidity_percent DECIMAL(5,2)
);

-- Insert sample data with temperature trends
INSERT INTO temperature_data VALUES
(1, '2024-01-01 08:00:00', 18.5, 65.2),
(2, '2024-01-01 12:00:00', 22.3, 58.1),
(3, '2024-01-01 16:00:00', 24.8, 52.3),
(4, '2024-01-01 20:00:00', 20.1, 61.5),
(5, '2024-01-02 08:00:00', 19.2, 63.8),
(6, '2024-01-02 12:00:00', 23.1, 56.9),
(7, '2024-01-02 16:00:00', 25.5, 50.7),
(8, '2024-01-02 20:00:00', 21.3, 59.2),
(9, '2024-01-03 08:00:00', 20.8, 62.1),
(10, '2024-01-03 12:00:00', 24.2, 55.4),
(11, '2024-01-03 16:00:00', 26.1, 49.8),
(12, '2024-01-03 20:00:00', 22.5, 57.6),
(13, '2024-01-04 08:00:00', 21.5, 60.9),
(14, '2024-01-04 12:00:00', 25.3, 53.2),
(15, '2024-01-04 16:00:00', 27.2, 47.5);

-- Example 4: Breakpoint Detection
-- Identify trend changes and breakpoints
WITH temperature_trends AS (
    SELECT 
        timestamp,
        temperature_celsius,
        AVG(temperature_celsius) OVER (ORDER BY timestamp ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) as prev_avg_temp,
        AVG(temperature_celsius) OVER (ORDER BY timestamp ROWS BETWEEN 1 FOLLOWING AND 5 FOLLOWING) as next_avg_temp,
        STDDEV(temperature_celsius) OVER (ORDER BY timestamp ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) as prev_stddev,
        STDDEV(temperature_celsius) OVER (ORDER BY timestamp ROWS BETWEEN 1 FOLLOWING AND 5 FOLLOWING) as next_stddev
    FROM temperature_data
)
SELECT 
    timestamp,
    temperature_celsius,
    ROUND(prev_avg_temp, 2) as previous_avg,
    ROUND(next_avg_temp, 2) as next_avg,
    ROUND(prev_stddev, 2) as previous_volatility,
    ROUND(next_stddev, 2) as next_volatility,
    CASE 
        WHEN ABS(next_avg_temp - prev_avg_temp) > 2 * GREATEST(prev_stddev, next_stddev) THEN 'Trend Breakpoint'
        ELSE 'Normal Variation'
    END as breakpoint_status,
    CASE 
        WHEN next_avg_temp > prev_avg_temp + 1 THEN 'Trend Increasing'
        WHEN next_avg_temp < prev_avg_temp - 1 THEN 'Trend Decreasing'
        ELSE 'Trend Stable'
    END as trend_direction
FROM temperature_trends
WHERE timestamp BETWEEN '2024-01-02 08:00:00' AND '2024-01-03 20:00:00'
ORDER BY timestamp;

-- Create customer behavior table
CREATE TABLE customer_behavior (
    id INT PRIMARY KEY,
    date_id DATE,
    customer_id INT,
    purchase_amount DECIMAL(10,2),
    purchase_count INT,
    session_duration INT
);

-- Insert sample data with customer behavior patterns
INSERT INTO customer_behavior VALUES
(1, '2024-01-01', 1001, 150.00, 2, 1200),
(2, '2024-01-02', 1001, 180.00, 3, 1350),
(3, '2024-01-03', 1001, 220.00, 4, 1500),
(4, '2024-01-04', 1001, 195.00, 3, 1400),
(5, '2024-01-05', 1001, 250.00, 5, 1600),
(6, '2024-01-06', 1001, 280.00, 6, 1750),
(7, '2024-01-07', 1001, 265.00, 5, 1650),
(8, '2024-01-08', 1001, 320.00, 7, 1900),
(9, '2024-01-09', 1001, 295.00, 6, 1800),
(10, '2024-01-10', 1001, 350.00, 8, 2000),
(11, '2024-01-11', 1001, 330.00, 7, 1950),
(12, '2024-01-12', 1001, 380.00, 9, 2100),
(13, '2024-01-13', 1001, 365.00, 8, 2050),
(14, '2024-01-14', 1001, 420.00, 10, 2250),
(15, '2024-01-15', 1001, 395.00, 9, 2150);

-- Example 5: Predictive Trend Analysis
-- Analyze customer behavior trends and predict future patterns
WITH customer_trends AS (
    SELECT 
        date_id,
        customer_id,
        purchase_amount,
        purchase_count,
        session_duration,
        AVG(purchase_amount) OVER (ORDER BY date_id ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING) as avg_purchase_amount,
        AVG(purchase_count) OVER (ORDER BY date_id ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING) as avg_purchase_count,
        AVG(session_duration) OVER (ORDER BY date_id ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING) as avg_session_duration,
        STDDEV(purchase_amount) OVER (ORDER BY date_id ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING) as purchase_amount_stddev,
        STDDEV(purchase_count) OVER (ORDER BY date_id ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING) as purchase_count_stddev
    FROM customer_behavior
    WHERE customer_id = 1001
)
SELECT 
    date_id,
    purchase_amount,
    purchase_count,
    session_duration,
    ROUND(avg_purchase_amount, 2) as predicted_purchase_amount,
    ROUND(avg_purchase_count, 1) as predicted_purchase_count,
    ROUND(avg_session_duration, 0) as predicted_session_duration,
    ROUND(avg_purchase_amount + 2 * purchase_amount_stddev, 2) as upper_bound_amount,
    ROUND(avg_purchase_amount - 2 * purchase_amount_stddev, 2) as lower_bound_amount,
    CASE 
        WHEN purchase_amount > avg_purchase_amount + 2 * purchase_amount_stddev THEN 'Above Expected'
        WHEN purchase_amount < avg_purchase_amount - 2 * purchase_amount_stddev THEN 'Below Expected'
        ELSE 'Within Expected Range'
    END as performance_status
FROM customer_trends
WHERE date_id >= '2024-01-08'  -- Show recent data with enough history
ORDER BY date_id;

-- Create production metrics table
CREATE TABLE production_metrics (
    id INT PRIMARY KEY,
    date_id DATE,
    production_line VARCHAR(50),
    units_produced INT,
    defect_rate DECIMAL(5,2),
    efficiency_score DECIMAL(5,2)
);

-- Insert sample data with production trends
INSERT INTO production_metrics VALUES
(1, '2024-01-01', 'Line A', 850, 2.1, 92.5),
(2, '2024-01-02', 'Line A', 870, 2.0, 93.1),
(3, '2024-01-03', 'Line A', 890, 1.9, 93.8),
(4, '2024-01-04', 'Line A', 910, 1.8, 94.2),
(5, '2024-01-05', 'Line A', 930, 1.7, 94.8),
(6, '2024-01-06', 'Line A', 950, 1.6, 95.3),
(7, '2024-01-07', 'Line A', 970, 1.5, 95.9),
(8, '2024-01-08', 'Line A', 990, 1.4, 96.4),
(9, '2024-01-09', 'Line A', 1010, 1.3, 96.8),
(10, '2024-01-10', 'Line A', 1030, 1.2, 97.2),
(11, '2024-01-11', 'Line A', 1050, 1.1, 97.6),
(12, '2024-01-12', 'Line A', 1070, 1.0, 98.1),
(13, '2024-01-13', 'Line A', 1090, 0.9, 98.5),
(14, '2024-01-14', 'Line A', 1110, 0.8, 98.9),
(15, '2024-01-15', 'Line A', 1130, 0.7, 99.2);

-- Example 6: Comprehensive Trend Analysis
-- Combine multiple trend detection techniques
SELECT 
    date_id,
    units_produced,
    defect_rate,
    efficiency_score,
    -- Production trend
    CASE 
        WHEN units_produced > LAG(units_produced) OVER (ORDER BY date_id) THEN 'Increasing'
        WHEN units_produced < LAG(units_produced) OVER (ORDER BY date_id) THEN 'Decreasing'
        ELSE 'Stable'
    END as production_trend,
    -- Quality trend
    CASE 
        WHEN defect_rate < LAG(defect_rate) OVER (ORDER BY date_id) THEN 'Improving'
        WHEN defect_rate > LAG(defect_rate) OVER (ORDER BY date_id) THEN 'Declining'
        ELSE 'Stable'
    END as quality_trend,
    -- Efficiency trend
    CASE 
        WHEN efficiency_score > LAG(efficiency_score) OVER (ORDER BY date_id) THEN 'Improving'
        WHEN efficiency_score < LAG(efficiency_score) OVER (ORDER BY date_id) THEN 'Declining'
        ELSE 'Stable'
    END as efficiency_trend,
    -- Moving averages
    ROUND(AVG(units_produced) OVER (ORDER BY date_id ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 0) as ma_units_produced,
    ROUND(AVG(defect_rate) OVER (ORDER BY date_id ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) as ma_defect_rate,
    ROUND(AVG(efficiency_score) OVER (ORDER BY date_id ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) as ma_efficiency_score,
    -- Overall performance rating
    CASE 
        WHEN efficiency_score > 98 AND defect_rate < 1.0 THEN 'Excellent'
        WHEN efficiency_score > 95 AND defect_rate < 1.5 THEN 'Good'
        WHEN efficiency_score > 90 AND defect_rate < 2.0 THEN 'Average'
        ELSE 'Needs Improvement'
    END as performance_rating
FROM production_metrics
WHERE production_line = 'Line A'
ORDER BY date_id;

-- Clean up
DROP TABLE IF EXISTS sales_trends CASCADE;
DROP TABLE IF EXISTS stock_prices CASCADE;
DROP TABLE IF EXISTS website_metrics CASCADE;
DROP TABLE IF EXISTS temperature_data CASCADE;
DROP TABLE IF EXISTS customer_behavior CASCADE;
DROP TABLE IF EXISTS production_metrics CASCADE; 