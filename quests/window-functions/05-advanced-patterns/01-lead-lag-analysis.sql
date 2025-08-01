-- =====================================================
<<<<<<< HEAD
-- Window Functions: Lead-Lag Analysis
-- =====================================================

-- PURPOSE: Demonstrate advanced time series analysis using LEAD and LAG functions
-- LEARNING OUTCOMES:
--   - Master LEAD and LAG functions for time series analysis
--   - Understand trend detection and pattern recognition
--   - Apply window functions for predictive analytics
-- EXPECTED RESULTS: Comprehensive time series analysis with trend detection and forecasting
-- DIFFICULTY: ⚫ Expert (30-45 min)
-- CONCEPTS: LEAD/LAG, Time Series Analysis, Trend Detection, Pattern Recognition, Forecasting

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS stock_prices CASCADE;
DROP TABLE IF EXISTS website_traffic CASCADE;
DROP TABLE IF EXISTS temperature_readings CASCADE;

-- Create stock prices table
CREATE TABLE stock_prices (
    date_id DATE PRIMARY KEY,
    stock_symbol VARCHAR(10),
    open_price DECIMAL(8,2),
    close_price DECIMAL(8,2),
    high_price DECIMAL(8,2),
    low_price DECIMAL(8,2),
    volume INT
);

-- Create website traffic table
CREATE TABLE website_traffic (
    visit_date DATE,
    page_views INT,
    unique_visitors INT,
=======
-- Window Functions: Lead/Lag Analysis for Time Series
-- =====================================================

-- PURPOSE: Demonstrate advanced LAG and LEAD functions for time series analysis,
--          trend detection, and sequential data processing
-- LEARNING OUTCOMES: Students will understand how to use LAG/LEAD for
--                    time series analysis, trend identification, and data comparison
-- EXPECTED RESULTS:
-- 1. Time series trend analysis with lag/lead comparisons
-- 2. Sequential data processing and pattern detection
-- 3. Growth rate calculations and momentum indicators
-- 4. Anomaly detection using historical comparisons
-- DIFFICULTY: ⚫ Expert (30-45 min)
-- CONCEPTS: LAG/LEAD functions, Time Series Analysis, Trend Detection,
--           Sequential Processing, Anomaly Detection, Momentum Indicators

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS stock_prices CASCADE;
DROP TABLE IF EXISTS website_metrics CASCADE;
DROP TABLE IF EXISTS sensor_data CASCADE;

-- Create stock prices table for time series analysis
CREATE TABLE stock_prices (
    record_id INT PRIMARY KEY,
    symbol VARCHAR(10),
    date DATE,
    open_price DECIMAL(10,2),
    close_price DECIMAL(10,2),
    high_price DECIMAL(10,2),
    low_price DECIMAL(10,2),
    volume BIGINT
);

-- Create website metrics table
CREATE TABLE website_metrics (
    record_id INT PRIMARY KEY,
    page_url VARCHAR(200),
    date DATE,
    visitors INT,
    page_views INT,
>>>>>>> 4e036c9 (feat(quests) improve quest queries)
    bounce_rate DECIMAL(5,2),
    avg_session_duration INT
);

<<<<<<< HEAD
-- Create temperature readings table
CREATE TABLE temperature_readings (
    reading_time TIMESTAMP,
    temperature_celsius DECIMAL(4,2),
    humidity_percent DECIMAL(5,2),
    pressure_hpa DECIMAL(6,2)
);

-- Insert stock price data
INSERT INTO stock_prices VALUES
('2024-01-01', 'AAPL', 150.25, 152.80, 153.50, 149.80, 45000000),
('2024-01-02', 'AAPL', 152.80, 154.20, 155.10, 152.30, 52000000),
('2024-01-03', 'AAPL', 154.20, 151.90, 154.80, 151.20, 48000000),
('2024-01-04', 'AAPL', 151.90, 153.60, 154.20, 151.50, 51000000),
('2024-01-05', 'AAPL', 153.60, 156.40, 156.80, 153.20, 55000000),
('2024-01-08', 'AAPL', 156.40, 158.20, 158.90, 156.10, 58000000),
('2024-01-09', 'AAPL', 158.20, 155.80, 158.50, 155.40, 49000000),
('2024-01-10', 'AAPL', 155.80, 157.60, 158.20, 155.60, 53000000),
('2024-01-11', 'AAPL', 157.60, 159.40, 159.80, 157.20, 56000000),
('2024-01-12', 'AAPL', 159.40, 161.20, 161.60, 159.10, 59000000),
('2024-01-15', 'AAPL', 161.20, 163.00, 163.40, 160.90, 62000000),
('2024-01-16', 'AAPL', 163.00, 160.60, 163.30, 160.20, 54000000),
('2024-01-17', 'AAPL', 160.60, 162.40, 162.80, 160.40, 57000000),
('2024-01-18', 'AAPL', 162.40, 164.20, 164.60, 162.10, 60000000),
('2024-01-19', 'AAPL', 164.20, 166.00, 166.40, 163.90, 63000000);

-- Insert website traffic data
INSERT INTO website_traffic VALUES
('2024-01-01', 12500, 8500, 35.2, 180),
('2024-01-02', 13200, 8900, 34.8, 185),
('2024-01-03', 11800, 8200, 36.1, 175),
('2024-01-04', 14100, 9500, 33.9, 190),
('2024-01-05', 15600, 10200, 32.5, 195),
('2024-01-06', 16800, 10800, 31.8, 200),
('2024-01-07', 17200, 11000, 31.2, 205),
('2024-01-08', 14500, 9800, 34.1, 188),
('2024-01-09', 13800, 9200, 35.0, 182),
('2024-01-10', 15200, 10100, 33.2, 192),
('2024-01-11', 16500, 10700, 32.1, 198),
('2024-01-12', 17800, 11300, 31.5, 203),
('2024-01-13', 18200, 11500, 31.0, 208),
('2024-01-14', 18500, 11700, 30.8, 210),
('2024-01-15', 15800, 10400, 33.5, 195);

-- Insert temperature readings data
INSERT INTO temperature_readings VALUES
('2024-01-01 00:00:00', 22.5, 65.2, 1013.2),
('2024-01-01 01:00:00', 21.8, 67.1, 1012.8),
('2024-01-01 02:00:00', 20.9, 69.5, 1012.4),
('2024-01-01 03:00:00', 19.7, 72.3, 1012.0),
('2024-01-01 04:00:00', 18.4, 75.8, 1011.6),
('2024-01-01 05:00:00', 17.2, 78.9, 1011.2),
('2024-01-01 06:00:00', 16.8, 80.1, 1010.8),
('2024-01-01 07:00:00', 17.5, 77.6, 1010.4),
('2024-01-01 08:00:00', 19.2, 73.4, 1010.0),
('2024-01-01 09:00:00', 21.8, 68.7, 1009.6),
('2024-01-01 10:00:00', 24.3, 63.2, 1009.2),
('2024-01-01 11:00:00', 26.7, 58.9, 1008.8),
('2024-01-01 12:00:00', 28.1, 55.4, 1008.4),
('2024-01-01 13:00:00', 29.2, 52.1, 1008.0),
('2024-01-01 14:00:00', 28.8, 54.3, 1007.6);
=======
-- Create sensor data table
CREATE TABLE sensor_data (
    record_id INT PRIMARY KEY,
    sensor_id VARCHAR(20),
    timestamp TIMESTAMP,
    temperature DECIMAL(5,2),
    humidity DECIMAL(5,2),
    pressure DECIMAL(8,2)
);

-- Insert sample stock price data
INSERT INTO stock_prices VALUES
-- AAPL stock data (5 days)
(1, 'AAPL', '2024-01-01', 150.25, 152.30, 153.50, 149.80, 50000000),
(2, 'AAPL', '2024-01-02', 152.30, 149.80, 152.80, 148.90, 48000000),
(3, 'AAPL', '2024-01-03', 149.80, 151.45, 152.20, 149.20, 51000000),
(4, 'AAPL', '2024-01-04', 151.45, 153.20, 154.10, 151.00, 53000000),
(5, 'AAPL', '2024-01-05', 153.20, 154.75, 155.50, 152.80, 54000000),
(6, 'AAPL', '2024-01-08', 154.75, 152.90, 155.20, 152.30, 49000000),
(7, 'AAPL', '2024-01-09', 152.90, 155.30, 156.00, 152.50, 55000000),
(8, 'AAPL', '2024-01-10', 155.30, 156.80, 157.20, 154.80, 56000000),
(9, 'AAPL', '2024-01-11', 156.80, 158.45, 159.00, 156.20, 58000000),
(10, 'AAPL', '2024-01-12', 158.45, 157.20, 159.50, 156.80, 52000000),

-- GOOGL stock data (5 days)
(11, 'GOOGL', '2024-01-01', 2800.00, 2820.50, 2830.00, 2795.00, 2000000),
(12, 'GOOGL', '2024-01-02', 2820.50, 2780.25, 2825.00, 2775.00, 1800000),
(13, 'GOOGL', '2024-01-03', 2780.25, 2810.75, 2820.00, 2778.00, 2100000),
(14, 'GOOGL', '2024-01-04', 2810.75, 2845.00, 2850.00, 2805.00, 2200000),
(15, 'GOOGL', '2024-01-05', 2845.00, 2870.25, 2880.00, 2840.00, 2400000);

-- Insert sample website metrics data
INSERT INTO website_metrics VALUES
-- Homepage metrics (10 days)
(1, '/home', '2024-01-01', 1200, 1800, 35.5, 180),
(2, '/home', '2024-01-02', 1350, 2100, 32.1, 195),
(3, '/home', '2024-01-03', 1100, 1650, 38.2, 165),
(4, '/home', '2024-01-04', 1400, 2200, 30.8, 210),
(5, '/home', '2024-01-05', 1600, 2500, 28.5, 225),
(6, '/home', '2024-01-06', 1800, 2800, 26.3, 240),
(7, '/home', '2024-01-07', 1700, 2600, 27.8, 230),
(8, '/home', '2024-01-08', 1900, 3000, 25.1, 250),
(9, '/home', '2024-01-09', 2100, 3300, 23.5, 270),
(10, '/home', '2024-01-10', 2000, 3100, 24.8, 260),

-- Products page metrics (10 days)
(11, '/products', '2024-01-01', 800, 1200, 45.2, 120),
(12, '/products', '2024-01-02', 900, 1350, 42.8, 135),
(13, '/products', '2024-01-03', 750, 1100, 48.1, 110),
(14, '/products', '2024-01-04', 950, 1450, 41.5, 145),
(15, '/products', '2024-01-05', 1100, 1700, 38.9, 170),
(16, '/products', '2024-01-06', 1200, 1850, 36.2, 185),
(17, '/products', '2024-01-07', 1150, 1750, 37.8, 175),
(18, '/products', '2024-01-08', 1300, 2000, 34.5, 200),
(19, '/products', '2024-01-09', 1400, 2150, 32.1, 215),
(20, '/products', '2024-01-10', 1350, 2050, 33.8, 205);

-- Insert sample sensor data
INSERT INTO sensor_data VALUES
-- Temperature sensor readings (24 hours)
(1, 'TEMP_001', '2024-01-01 00:00:00', 22.5, 45.2, 1013.25),
(2, 'TEMP_001', '2024-01-01 01:00:00', 22.8, 44.8, 1013.30),
(3, 'TEMP_001', '2024-01-01 02:00:00', 23.1, 44.5, 1013.28),
(4, 'TEMP_001', '2024-01-01 03:00:00', 22.9, 45.1, 1013.32),
(5, 'TEMP_001', '2024-01-01 04:00:00', 22.6, 45.8, 1013.29),
(6, 'TEMP_001', '2024-01-01 05:00:00', 22.3, 46.2, 1013.26),
(7, 'TEMP_001', '2024-01-01 06:00:00', 22.7, 45.9, 1013.31),
(8, 'TEMP_001', '2024-01-01 07:00:00', 23.2, 45.3, 1013.35),
(9, 'TEMP_001', '2024-01-01 08:00:00', 23.8, 44.7, 1013.40),
(10, 'TEMP_001', '2024-01-01 09:00:00', 24.1, 44.2, 1013.38),
(11, 'TEMP_001', '2024-01-01 10:00:00', 24.5, 43.8, 1013.42),
(12, 'TEMP_001', '2024-01-01 11:00:00', 24.8, 43.5, 1013.45),
(13, 'TEMP_001', '2024-01-01 12:00:00', 25.2, 43.1, 1013.48),
(14, 'TEMP_001', '2024-01-01 13:00:00', 25.5, 42.8, 1013.50),
(15, 'TEMP_001', '2024-01-01 14:00:00', 25.8, 42.5, 1013.52),
(16, 'TEMP_001', '2024-01-01 15:00:00', 25.6, 42.9, 1013.49),
(17, 'TEMP_001', '2024-01-01 16:00:00', 25.3, 43.2, 1013.46),
(18, 'TEMP_001', '2024-01-01 17:00:00', 25.0, 43.6, 1013.43),
(19, 'TEMP_001', '2024-01-01 18:00:00', 24.7, 44.0, 1013.40),
(20, 'TEMP_001', '2024-01-01 19:00:00', 24.4, 44.4, 1013.37),
(21, 'TEMP_001', '2024-01-01 20:00:00', 24.1, 44.8, 1013.34),
(22, 'TEMP_001', '2024-01-01 21:00:00', 23.8, 45.2, 1013.31),
(23, 'TEMP_001', '2024-01-01 22:00:00', 23.5, 45.6, 1013.28),
(24, 'TEMP_001', '2024-01-01 23:00:00', 23.2, 46.0, 1013.25);
>>>>>>> 4e036c9 (feat(quests) improve quest queries)

-- =====================================================
-- Example 1: Stock Price Trend Analysis
-- =====================================================

<<<<<<< HEAD
-- Analyze stock price trends using LEAD and LAG
SELECT 
    date_id,
    stock_symbol,
    close_price,
    LAG(close_price) OVER (ORDER BY date_id) as prev_close,
    LEAD(close_price) OVER (ORDER BY date_id) as next_close,
    LAG(close_price, 2) OVER (ORDER BY date_id) as two_days_ago,
    LEAD(close_price, 2) OVER (ORDER BY date_id) as two_days_ahead,
    ROUND(
        (close_price - LAG(close_price) OVER (ORDER BY date_id)) * 100.0 / 
        LAG(close_price) OVER (ORDER BY date_id), 2
    ) as daily_change_percent,
    ROUND(
        (close_price - LAG(close_price, 2) OVER (ORDER BY date_id)) * 100.0 / 
        LAG(close_price, 2) OVER (ORDER BY date_id), 2
    ) as two_day_change_percent,
    CASE 
        WHEN close_price > LAG(close_price) OVER (ORDER BY date_id) THEN 'Up'
        WHEN close_price < LAG(close_price) OVER (ORDER BY date_id) THEN 'Down'
        ELSE 'Flat'
    END as daily_trend,
    CASE 
        WHEN close_price > LAG(close_price, 2) OVER (ORDER BY date_id) THEN 'Rising'
        WHEN close_price < LAG(close_price, 2) OVER (ORDER BY date_id) THEN 'Falling'
        ELSE 'Sideways'
    END as two_day_trend
FROM stock_prices
WHERE stock_symbol = 'AAPL'
ORDER BY date_id;

-- =====================================================
-- Example 2: Moving Average and Price Momentum
-- =====================================================

-- Calculate moving averages and momentum indicators
WITH price_analysis AS (
    SELECT 
        date_id,
        close_price,
        LAG(close_price) OVER (ORDER BY date_id) as prev_close,
        LAG(close_price, 2) OVER (ORDER BY date_id) as two_days_ago,
        LAG(close_price, 3) OVER (ORDER BY date_id) as three_days_ago,
        LEAD(close_price) OVER (ORDER BY date_id) as next_close,
        LEAD(close_price, 2) OVER (ORDER BY date_id) as two_days_ahead
    FROM stock_prices
    WHERE stock_symbol = 'AAPL'
)
SELECT 
    date_id,
    close_price,
    prev_close,
    two_days_ago,
    three_days_ago,
    next_close,
    two_days_ahead,
    -- 3-day moving average
    ROUND((close_price + prev_close + two_days_ago) / 3.0, 2) as ma_3day,
    -- 5-day moving average
    ROUND((close_price + prev_close + two_days_ago + three_days_ago + 
           LAG(close_price, 4) OVER (ORDER BY date_id)) / 5.0, 2) as ma_5day,
    -- Price momentum (current vs 3 days ago)
    ROUND(
        (close_price - three_days_ago) * 100.0 / three_days_ago, 2
    ) as momentum_3day_percent,
    -- Price acceleration (change in momentum)
    ROUND(
        ((close_price - prev_close) - (prev_close - two_days_ago)) * 100.0 / two_days_ago, 2
    ) as acceleration_percent,
    -- Trend strength
    CASE 
        WHEN close_price > prev_close AND prev_close > two_days_ago THEN 'Strong Up'
        WHEN close_price > prev_close AND prev_close <= two_days_ago THEN 'Weak Up'
        WHEN close_price < prev_close AND prev_close < two_days_ago THEN 'Strong Down'
        WHEN close_price < prev_close AND prev_close >= two_days_ago THEN 'Weak Down'
        ELSE 'Sideways'
    END as trend_strength
FROM price_analysis
ORDER BY date_id;

-- =====================================================
-- Example 3: Website Traffic Pattern Analysis
-- =====================================================

-- Analyze website traffic patterns and trends
SELECT 
    visit_date,
    page_views,
    unique_visitors,
    bounce_rate,
    avg_session_duration,
    LAG(page_views) OVER (ORDER BY visit_date) as prev_page_views,
    LEAD(page_views) OVER (ORDER BY visit_date) as next_page_views,
    LAG(unique_visitors) OVER (ORDER BY visit_date) as prev_visitors,
    LEAD(unique_visitors) OVER (ORDER BY visit_date) as next_visitors,
    ROUND(
        (page_views - LAG(page_views) OVER (ORDER BY visit_date)) * 100.0 / 
        LAG(page_views) OVER (ORDER BY visit_date), 2
    ) as page_views_growth_percent,
    ROUND(
        (unique_visitors - LAG(unique_visitors) OVER (ORDER BY visit_date)) * 100.0 / 
        LAG(unique_visitors) OVER (ORDER BY visit_date), 2
    ) as visitors_growth_percent,
    ROUND(
        (bounce_rate - LAG(bounce_rate) OVER (ORDER BY visit_date)), 2
    ) as bounce_rate_change,
    ROUND(
        (avg_session_duration - LAG(avg_session_duration) OVER (ORDER BY visit_date)), 0
    ) as session_duration_change,
    CASE 
        WHEN page_views > LAG(page_views) OVER (ORDER BY visit_date) 
             AND unique_visitors > LAG(unique_visitors) OVER (ORDER BY visit_date) THEN 'Growth'
        WHEN page_views < LAG(page_views) OVER (ORDER BY visit_date) 
             AND unique_visitors < LAG(unique_visitors) OVER (ORDER BY visit_date) THEN 'Decline'
        ELSE 'Mixed'
    END as traffic_trend
FROM website_traffic
ORDER BY visit_date;

-- =====================================================
-- Example 4: Temperature Anomaly Detection
-- =====================================================

-- Detect temperature anomalies using statistical analysis
WITH temp_analysis AS (
    SELECT 
        reading_time,
        temperature_celsius,
        humidity_percent,
        pressure_hpa,
        LAG(temperature_celsius) OVER (ORDER BY reading_time) as prev_temp,
        LEAD(temperature_celsius) OVER (ORDER BY reading_time) as next_temp,
        LAG(temperature_celsius, 2) OVER (ORDER BY reading_time) as two_hours_ago,
        LEAD(temperature_celsius, 2) OVER (ORDER BY reading_time) as two_hours_ahead,
        AVG(temperature_celsius) OVER (
            ORDER BY reading_time 
            ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
        ) as moving_avg_5hour,
        STDDEV(temperature_celsius) OVER (
            ORDER BY reading_time 
            ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
        ) as moving_stddev_5hour
    FROM temperature_readings
)
SELECT 
    reading_time,
    temperature_celsius,
    humidity_percent,
    pressure_hpa,
    ROUND(prev_temp, 2) as prev_temp,
    ROUND(next_temp, 2) as next_temp,
    ROUND(two_hours_ago, 2) as two_hours_ago,
    ROUND(two_hours_ahead, 2) as two_hours_ahead,
    ROUND(moving_avg_5hour, 2) as moving_avg_5hour,
    ROUND(moving_stddev_5hour, 2) as moving_stddev_5hour,
    ROUND(
        (temperature_celsius - moving_avg_5hour) / NULLIF(moving_stddev_5hour, 0), 2
    ) as z_score,
    ROUND(
        (temperature_celsius - prev_temp), 2
    ) as temp_change_1h,
    ROUND(
        (temperature_celsius - two_hours_ago), 2
    ) as temp_change_2h,
    CASE 
        WHEN ABS((temperature_celsius - moving_avg_5hour) / NULLIF(moving_stddev_5hour, 0)) > 2 THEN 'Anomaly'
        WHEN ABS((temperature_celsius - moving_avg_5hour) / NULLIF(moving_stddev_5hour, 0)) > 1.5 THEN 'Unusual'
        ELSE 'Normal'
    END as anomaly_status,
    CASE 
        WHEN temperature_celsius > prev_temp AND prev_temp > two_hours_ago THEN 'Rising'
        WHEN temperature_celsius < prev_temp AND prev_temp < two_hours_ago THEN 'Falling'
        WHEN temperature_celsius > prev_temp AND prev_temp <= two_hours_ago THEN 'Turning Up'
        WHEN temperature_celsius < prev_temp AND prev_temp >= two_hours_ago THEN 'Turning Down'
        ELSE 'Stable'
    END as temperature_trend
FROM temp_analysis
ORDER BY reading_time;

-- =====================================================
-- Example 5: Predictive Pattern Recognition
-- =====================================================

-- Identify patterns that might predict future movements
WITH pattern_analysis AS (
    SELECT 
        date_id,
        close_price,
        volume,
        LAG(close_price) OVER (ORDER BY date_id) as prev_close,
        LAG(close_price, 2) OVER (ORDER BY date_id) as two_days_ago,
        LAG(volume) OVER (ORDER BY date_id) as prev_volume,
        LAG(volume, 2) OVER (ORDER BY date_id) as two_days_ago_volume,
        LEAD(close_price) OVER (ORDER BY date_id) as next_close,
        LEAD(close_price, 2) OVER (ORDER BY date_id) as two_days_ahead,
        LEAD(volume) OVER (ORDER BY date_id) as next_volume
    FROM stock_prices
    WHERE stock_symbol = 'AAPL'
)
SELECT 
    date_id,
    close_price,
    volume,
    ROUND(prev_close, 2) as prev_close,
    ROUND(two_days_ago, 2) as two_days_ago,
    ROUND(next_close, 2) as next_close,
    ROUND(two_days_ahead, 2) as two_days_ahead,
    -- Volume trend
    CASE 
        WHEN volume > prev_volume AND prev_volume > two_days_ago_volume THEN 'Increasing Volume'
        WHEN volume < prev_volume AND prev_volume < two_days_ago_volume THEN 'Decreasing Volume'
        ELSE 'Mixed Volume'
    END as volume_trend,
    -- Price pattern
    CASE 
        WHEN close_price > prev_close AND prev_close > two_days_ago THEN 'Uptrend'
        WHEN close_price < prev_close AND prev_close < two_days_ago THEN 'Downtrend'
        WHEN close_price > prev_close AND prev_close <= two_days_ago THEN 'Reversal Up'
        WHEN close_price < prev_close AND prev_temp >= two_days_ago THEN 'Reversal Down'
        ELSE 'Sideways'
    END as price_pattern,
    -- Volume-price relationship
    CASE 
        WHEN close_price > prev_close AND volume > prev_volume THEN 'Bullish'
        WHEN close_price < prev_close AND volume > prev_volume THEN 'Bearish'
        WHEN close_price > prev_close AND volume < prev_volume THEN 'Weak Bullish'
        WHEN close_price < prev_close AND volume < prev_volume THEN 'Weak Bearish'
        ELSE 'Neutral'
    END as volume_price_signal,
    -- Predictive signal
    CASE 
        WHEN close_price > prev_close AND volume > prev_volume * 1.2 THEN 'Strong Buy Signal'
        WHEN close_price < prev_close AND volume > prev_volume * 1.2 THEN 'Strong Sell Signal'
        WHEN close_price > prev_close AND volume < prev_volume * 0.8 THEN 'Weak Buy Signal'
        WHEN close_price < prev_close AND volume < prev_volume * 0.8 THEN 'Weak Sell Signal'
        ELSE 'Hold'
    END as trading_signal
FROM pattern_analysis
ORDER BY date_id;

-- =====================================================
-- Example 6: Seasonal Pattern Detection
-- =====================================================

-- Detect weekly patterns in website traffic
WITH weekly_patterns AS (
    SELECT 
        visit_date,
        page_views,
        unique_visitors,
        EXTRACT(DOW FROM visit_date) as day_of_week,
        LAG(page_views) OVER (PARTITION BY EXTRACT(DOW FROM visit_date) ORDER BY visit_date) as prev_week_same_day,
        LAG(page_views, 7) OVER (ORDER BY visit_date) as week_ago,
        AVG(page_views) OVER (PARTITION BY EXTRACT(DOW FROM visit_date)) as avg_same_day_views,
        STDDEV(page_views) OVER (PARTITION BY EXTRACT(DOW FROM visit_date)) as stddev_same_day_views
    FROM website_traffic
)
SELECT 
    visit_date,
    page_views,
    unique_visitors,
=======
-- Analyze stock price trends using LAG and LEAD
WITH stock_trends AS (
    SELECT 
        symbol,
        date,
        close_price,
        -- Previous day's close
        LAG(close_price) OVER (PARTITION BY symbol ORDER BY date) as prev_close,
        -- Next day's close
        LEAD(close_price) OVER (PARTITION BY symbol ORDER BY date) as next_close,
        -- 3-day moving average
        AVG(close_price) OVER (
            PARTITION BY symbol 
            ORDER BY date 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as ma_3day,
        -- Price change from previous day
        ROUND(
            (close_price - LAG(close_price) OVER (PARTITION BY symbol ORDER BY date)) * 100.0 / 
            NULLIF(LAG(close_price) OVER (PARTITION BY symbol ORDER BY date), 0), 2
        ) as daily_change_pct,
        -- Volume change from previous day
        ROUND(
            (volume - LAG(volume) OVER (PARTITION BY symbol ORDER BY date)) * 100.0 / 
            NULLIF(LAG(volume) OVER (PARTITION BY symbol ORDER BY date), 0), 2
        ) as volume_change_pct
    FROM stock_prices
)
SELECT 
    symbol,
    date,
    close_price,
    prev_close,
    next_close,
    ROUND(ma_3day, 2) as ma_3day,
    daily_change_pct,
    volume_change_pct,
    -- Trend direction
    CASE 
        WHEN daily_change_pct > 2 THEN 'Strong Up'
        WHEN daily_change_pct > 0 THEN 'Up'
        WHEN daily_change_pct > -2 THEN 'Down'
        ELSE 'Strong Down'
    END as price_trend,
    -- Volume trend
    CASE 
        WHEN volume_change_pct > 20 THEN 'High Volume'
        WHEN volume_change_pct > 0 THEN 'Above Average'
        WHEN volume_change_pct > -20 THEN 'Below Average'
        ELSE 'Low Volume'
    END as volume_trend
FROM stock_trends
ORDER BY symbol, date;

-- =====================================================
-- Example 2: Website Traffic Momentum Analysis
-- =====================================================

-- Analyze website traffic momentum and trends
WITH traffic_momentum AS (
    SELECT 
        page_url,
        date,
        visitors,
        page_views,
        bounce_rate,
        avg_session_duration,
        -- Previous day's metrics
        LAG(visitors) OVER (PARTITION BY page_url ORDER BY date) as prev_visitors,
        LAG(page_views) OVER (PARTITION BY page_url ORDER BY date) as prev_page_views,
        LAG(bounce_rate) OVER (PARTITION BY page_url ORDER BY date) as prev_bounce_rate,
        -- Next day's metrics
        LEAD(visitors) OVER (PARTITION BY page_url ORDER BY date) as next_visitors,
        LEAD(page_views) OVER (PARTITION BY page_url ORDER BY date) as next_page_views,
        -- 3-day moving averages
        AVG(visitors) OVER (
            PARTITION BY page_url 
            ORDER BY date 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as visitors_ma_3day,
        AVG(page_views) OVER (
            PARTITION BY page_url 
            ORDER BY date 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as pageviews_ma_3day,
        -- Growth rates
        ROUND(
            (visitors - LAG(visitors) OVER (PARTITION BY page_url ORDER BY date)) * 100.0 / 
            NULLIF(LAG(visitors) OVER (PARTITION BY page_url ORDER BY date), 0), 2
        ) as visitor_growth_pct,
        ROUND(
            (page_views - LAG(page_views) OVER (PARTITION BY page_url ORDER BY date)) * 100.0 / 
            NULLIF(LAG(page_views) OVER (PARTITION BY page_url ORDER BY date), 0), 2
        ) as pageview_growth_pct
    FROM website_metrics
)
SELECT 
    page_url,
    date,
    visitors,
    page_views,
    bounce_rate,
    avg_session_duration,
    prev_visitors,
    prev_page_views,
    ROUND(visitors_ma_3day, 0) as visitors_ma_3day,
    ROUND(pageviews_ma_3day, 0) as pageviews_ma_3day,
    visitor_growth_pct,
    pageview_growth_pct,
    -- Momentum indicators
    CASE 
        WHEN visitor_growth_pct > 10 AND pageview_growth_pct > 10 THEN 'Strong Momentum'
        WHEN visitor_growth_pct > 5 AND pageview_growth_pct > 5 THEN 'Positive Momentum'
        WHEN visitor_growth_pct > -5 AND pageview_growth_pct > -5 THEN 'Stable'
        WHEN visitor_growth_pct > -10 AND pageview_growth_pct > -10 THEN 'Declining'
        ELSE 'Significant Decline'
    END as momentum_indicator,
    -- Performance vs moving average
    CASE 
        WHEN visitors > visitors_ma_3day * 1.1 THEN 'Above Trend'
        WHEN visitors < visitors_ma_3day * 0.9 THEN 'Below Trend'
        ELSE 'On Trend'
    END as trend_position
FROM traffic_momentum
ORDER BY page_url, date;

-- =====================================================
-- Example 3: Sensor Data Anomaly Detection
-- =====================================================

-- Detect anomalies in sensor data using LAG/LEAD
WITH sensor_analysis AS (
    SELECT 
        sensor_id,
        timestamp,
        temperature,
        humidity,
        pressure,
        -- Previous readings
        LAG(temperature) OVER (PARTITION BY sensor_id ORDER BY timestamp) as prev_temp,
        LAG(humidity) OVER (PARTITION BY sensor_id ORDER BY timestamp) as prev_humidity,
        LAG(pressure) OVER (PARTITION BY sensor_id ORDER BY timestamp) as prev_pressure,
        -- Next readings
        LEAD(temperature) OVER (PARTITION BY sensor_id ORDER BY timestamp) as next_temp,
        LEAD(humidity) OVER (PARTITION BY sensor_id ORDER BY timestamp) as next_humidity,
        LEAD(pressure) OVER (PARTITION BY sensor_id ORDER BY timestamp) as next_pressure,
        -- 3-hour moving averages
        AVG(temperature) OVER (
            PARTITION BY sensor_id 
            ORDER BY timestamp 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as temp_ma_3hour,
        AVG(humidity) OVER (
            PARTITION BY sensor_id 
            ORDER BY timestamp 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as humidity_ma_3hour,
        AVG(pressure) OVER (
            PARTITION BY sensor_id 
            ORDER BY timestamp 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as pressure_ma_3hour,
        -- Rate of change
        ROUND(
            (temperature - LAG(temperature) OVER (PARTITION BY sensor_id ORDER BY timestamp)), 2
        ) as temp_change_rate,
        ROUND(
            (humidity - LAG(humidity) OVER (PARTITION BY sensor_id ORDER BY timestamp)), 2
        ) as humidity_change_rate,
        ROUND(
            (pressure - LAG(pressure) OVER (PARTITION BY sensor_id ORDER BY timestamp)), 2
        ) as pressure_change_rate
    FROM sensor_data
)
SELECT 
    sensor_id,
    timestamp,
    temperature,
    humidity,
    pressure,
    prev_temp,
    prev_humidity,
    prev_pressure,
    ROUND(temp_ma_3hour, 2) as temp_ma_3hour,
    ROUND(humidity_ma_3hour, 2) as humidity_ma_3hour,
    ROUND(pressure_ma_3hour, 2) as pressure_ma_3hour,
    temp_change_rate,
    humidity_change_rate,
    pressure_change_rate,
    -- Anomaly detection
    CASE 
        WHEN ABS(temperature - temp_ma_3hour) > 2 THEN 'Temperature Anomaly'
        WHEN ABS(humidity - humidity_ma_3hour) > 5 THEN 'Humidity Anomaly'
        WHEN ABS(pressure - pressure_ma_3hour) > 0.1 THEN 'Pressure Anomaly'
        ELSE 'Normal'
    END as anomaly_flag,
    -- Trend analysis
    CASE 
        WHEN temp_change_rate > 0.5 THEN 'Rapid Warming'
        WHEN temp_change_rate < -0.5 THEN 'Rapid Cooling'
        WHEN temp_change_rate > 0.1 THEN 'Gradual Warming'
        WHEN temp_change_rate < -0.1 THEN 'Gradual Cooling'
        ELSE 'Stable'
    END as temperature_trend
FROM sensor_analysis
ORDER BY sensor_id, timestamp;

-- =====================================================
-- Example 4: Sequential Pattern Detection
-- =====================================================

-- Detect sequential patterns in stock prices
WITH pattern_analysis AS (
    SELECT 
        symbol,
        date,
        close_price,
        -- Multiple lag periods
        LAG(close_price, 1) OVER (PARTITION BY symbol ORDER BY date) as lag_1,
        LAG(close_price, 2) OVER (PARTITION BY symbol ORDER BY date) as lag_2,
        LAG(close_price, 3) OVER (PARTITION BY symbol ORDER BY date) as lag_3,
        -- Multiple lead periods
        LEAD(close_price, 1) OVER (PARTITION BY symbol ORDER BY date) as lead_1,
        LEAD(close_price, 2) OVER (PARTITION BY symbol ORDER BY date) as lead_2,
        LEAD(close_price, 3) OVER (PARTITION BY symbol ORDER BY date) as lead_3,
        -- Price momentum (3-day)
        ROUND(
            (close_price - LAG(close_price, 3) OVER (PARTITION BY symbol ORDER BY date)) * 100.0 / 
            NULLIF(LAG(close_price, 3) OVER (PARTITION BY symbol ORDER BY date), 0), 2
        ) as momentum_3day,
        -- Volatility (standard deviation of last 3 days)
        STDDEV(close_price) OVER (
            PARTITION BY symbol 
            ORDER BY date 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as volatility_3day
    FROM stock_prices
)
SELECT 
    symbol,
    date,
    close_price,
    lag_1,
    lag_2,
    lag_3,
    lead_1,
    lead_2,
    lead_3,
    momentum_3day,
    ROUND(volatility_3day, 2) as volatility_3day,
    -- Pattern identification
    CASE 
        WHEN close_price > lag_1 AND lag_1 > lag_2 AND lag_2 > lag_3 THEN 'Uptrend'
        WHEN close_price < lag_1 AND lag_1 < lag_2 AND lag_2 < lag_3 THEN 'Downtrend'
        WHEN close_price > lag_1 AND lag_1 < lag_2 THEN 'Reversal Up'
        WHEN close_price < lag_1 AND lag_1 > lag_2 THEN 'Reversal Down'
        ELSE 'Sideways'
    END as price_pattern,
    -- Momentum classification
    CASE 
        WHEN momentum_3day > 5 THEN 'Strong Bullish'
        WHEN momentum_3day > 2 THEN 'Bullish'
        WHEN momentum_3day > -2 THEN 'Neutral'
        WHEN momentum_3day > -5 THEN 'Bearish'
        ELSE 'Strong Bearish'
    END as momentum_class
FROM pattern_analysis
ORDER BY symbol, date;

-- =====================================================
-- Example 5: Cross-Series Comparison
-- =====================================================

-- Compare multiple time series using LAG/LEAD
WITH cross_series AS (
    SELECT 
        'AAPL' as symbol,
        date,
        close_price as aapl_price,
        LAG(close_price) OVER (ORDER BY date) as aapl_prev,
        LEAD(close_price) OVER (ORDER BY date) as aapl_next
    FROM stock_prices 
    WHERE symbol = 'AAPL'
),
googl_series AS (
    SELECT 
        'GOOGL' as symbol,
        date,
        close_price as googl_price,
        LAG(close_price) OVER (ORDER BY date) as googl_prev,
        LEAD(close_price) OVER (ORDER BY date) as googl_next
    FROM stock_prices 
    WHERE symbol = 'GOOGL'
)
SELECT 
    a.date,
    a.aapl_price,
    g.googl_price,
    -- Price ratios
    ROUND(a.aapl_price / g.googl_price, 4) as price_ratio,
    -- Growth comparison
    ROUND(
        (a.aapl_price - a.aapl_prev) * 100.0 / NULLIF(a.aapl_prev, 0), 2
    ) as aapl_growth,
    ROUND(
        (g.googl_price - g.googl_prev) * 100.0 / NULLIF(g.googl_prev, 0), 2
    ) as googl_growth,
    -- Relative performance
    ROUND(
        ((a.aapl_price - a.aapl_prev) * 100.0 / NULLIF(a.aapl_prev, 0)) - 
        ((g.googl_price - g.googl_prev) * 100.0 / NULLIF(g.googl_prev, 0)), 2
    ) as relative_performance,
    -- Correlation indicator
    CASE 
        WHEN (a.aapl_price - a.aapl_prev) * (g.googl_price - g.googl_prev) > 0 THEN 'Positive Correlation'
        WHEN (a.aapl_price - a.aapl_prev) * (g.googl_price - g.googl_prev) < 0 THEN 'Negative Correlation'
        ELSE 'No Correlation'
    END as correlation_direction
FROM cross_series a
JOIN googl_series g ON a.date = g.date
ORDER BY a.date;

-- =====================================================
-- Example 6: Advanced Trend Detection
-- =====================================================

-- Advanced trend detection using multiple timeframes
WITH advanced_trends AS (
    SELECT 
        symbol,
        date,
        close_price,
        -- Multiple timeframe moving averages
        AVG(close_price) OVER (
            PARTITION BY symbol 
            ORDER BY date 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as ma_3day,
        AVG(close_price) OVER (
            PARTITION BY symbol 
            ORDER BY date 
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) as ma_5day,
        AVG(close_price) OVER (
            PARTITION BY symbol 
            ORDER BY date 
            ROWS BETWEEN 9 PRECEDING AND CURRENT ROW
        ) as ma_10day,
        -- Price momentum indicators
        ROUND(
            (close_price - LAG(close_price, 1) OVER (PARTITION BY symbol ORDER BY date)) * 100.0 / 
            NULLIF(LAG(close_price, 1) OVER (PARTITION BY symbol ORDER BY date), 0), 2
        ) as momentum_1day,
        ROUND(
            (close_price - LAG(close_price, 3) OVER (PARTITION BY symbol ORDER BY date)) * 100.0 / 
            NULLIF(LAG(close_price, 3) OVER (PARTITION BY symbol ORDER BY date), 0), 2
        ) as momentum_3day,
        ROUND(
            (close_price - LAG(close_price, 5) OVER (PARTITION BY symbol ORDER BY date)) * 100.0 / 
            NULLIF(LAG(close_price, 5) OVER (PARTITION BY symbol ORDER BY date), 0), 2
        ) as momentum_5day,
        -- Trend strength indicators
        ROUND(
            (AVG(close_price) OVER (
                PARTITION BY symbol 
                ORDER BY date 
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ) - AVG(close_price) OVER (
                PARTITION BY symbol 
                ORDER BY date 
                ROWS BETWEEN 9 PRECEDING AND CURRENT ROW
            )) * 100.0 / NULLIF(AVG(close_price) OVER (
                PARTITION BY symbol 
                ORDER BY date 
                ROWS BETWEEN 9 PRECEDING AND CURRENT ROW
            ), 0), 2
        ) as trend_strength
    FROM stock_prices
)
SELECT 
    symbol,
    date,
    close_price,
    ROUND(ma_3day, 2) as ma_3day,
    ROUND(ma_5day, 2) as ma_5day,
    ROUND(ma_10day, 2) as ma_10day,
    momentum_1day,
    momentum_3day,
    momentum_5day,
    trend_strength,
    -- Multi-timeframe trend analysis
    CASE 
        WHEN ma_3day > ma_5day AND ma_5day > ma_10day AND trend_strength > 2 THEN 'Strong Uptrend'
        WHEN ma_3day > ma_5day AND ma_5day > ma_10day THEN 'Uptrend'
        WHEN ma_3day < ma_5day AND ma_5day < ma_10day AND trend_strength < -2 THEN 'Strong Downtrend'
        WHEN ma_3day < ma_5day AND ma_5day < ma_10day THEN 'Downtrend'
        WHEN ABS(trend_strength) < 1 THEN 'Sideways'
        ELSE 'Mixed Signals'
    END as trend_analysis,
    -- Momentum classification
    CASE 
        WHEN momentum_1day > 0 AND momentum_3day > 0 AND momentum_5day > 0 THEN 'All Timeframes Bullish'
        WHEN momentum_1day < 0 AND momentum_3day < 0 AND momentum_5day < 0 THEN 'All Timeframes Bearish'
        WHEN momentum_1day > 0 AND momentum_3day > 0 THEN 'Short-term Bullish'
        WHEN momentum_1day < 0 AND momentum_3day < 0 THEN 'Short-term Bearish'
        ELSE 'Conflicting Signals'
    END as momentum_analysis
FROM advanced_trends
ORDER BY symbol, date;

-- =====================================================
-- Example 7: Seasonal Pattern Detection
-- =====================================================

-- Detect seasonal patterns in website traffic
WITH seasonal_analysis AS (
    SELECT 
        page_url,
        date,
        visitors,
        page_views,
        -- Day of week patterns
        EXTRACT(DOW FROM date) as day_of_week,
        -- Previous week same day
        LAG(visitors, 7) OVER (PARTITION BY page_url ORDER BY date) as prev_week_same_day,
        -- Next week same day
        LEAD(visitors, 7) OVER (PARTITION BY page_url ORDER BY date) as next_week_same_day,
        -- Weekly average
        AVG(visitors) OVER (
            PARTITION BY page_url 
            ORDER BY date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) as weekly_avg,
        -- Weekly growth
        ROUND(
            (visitors - LAG(visitors, 7) OVER (PARTITION BY page_url ORDER BY date)) * 100.0 / 
            NULLIF(LAG(visitors, 7) OVER (PARTITION BY page_url ORDER BY date), 0), 2
        ) as weekly_growth_pct
    FROM website_metrics
)
SELECT 
    page_url,
    date,
    visitors,
    page_views,
>>>>>>> 4e036c9 (feat(quests) improve quest queries)
    CASE day_of_week
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END as day_name,
<<<<<<< HEAD
    ROUND(prev_week_same_day, 0) as prev_week_same_day,
    ROUND(week_ago, 0) as week_ago,
    ROUND(avg_same_day_views, 0) as avg_same_day_views,
    ROUND(stddev_same_day_views, 0) as stddev_same_day_views,
    ROUND(
        (page_views - avg_same_day_views) / NULLIF(stddev_same_day_views, 0), 2
    ) as same_day_z_score,
    ROUND(
        (page_views - prev_week_same_day) * 100.0 / NULLIF(prev_week_same_day, 0), 2
    ) as week_over_week_change,
    ROUND(
        (page_views - week_ago) * 100.0 / NULLIF(week_ago, 0), 2
    ) as week_ago_change,
    CASE 
        WHEN page_views > avg_same_day_views + stddev_same_day_views THEN 'Above Average'
        WHEN page_views < avg_same_day_views - stddev_same_day_views THEN 'Below Average'
        ELSE 'Average'
    END as performance_vs_typical,
    CASE 
        WHEN page_views > prev_week_same_day AND prev_week_same_day > week_ago THEN 'Improving Trend'
        WHEN page_views < prev_week_same_day AND prev_week_same_day < week_ago THEN 'Declining Trend'
        WHEN page_views > prev_week_same_day AND prev_week_same_day <= week_ago THEN 'Recovery'
        WHEN page_views < prev_week_same_day AND prev_week_same_day >= week_ago THEN 'Deterioration'
        ELSE 'Stable'
    END as weekly_trend
FROM weekly_patterns
ORDER BY visit_date;

-- Clean up
DROP TABLE IF EXISTS stock_prices CASCADE;
DROP TABLE IF EXISTS website_traffic CASCADE;
DROP TABLE IF EXISTS temperature_readings CASCADE; 
=======
    prev_week_same_day,
    next_week_same_day,
    ROUND(weekly_avg, 0) as weekly_avg,
    weekly_growth_pct,
    -- Seasonal pattern detection
    CASE 
        WHEN visitors > weekly_avg * 1.2 THEN 'Above Weekly Average'
        WHEN visitors < weekly_avg * 0.8 THEN 'Below Weekly Average'
        ELSE 'At Weekly Average'
    END as weekly_performance,
    -- Day-of-week trend
    CASE 
        WHEN day_of_week IN (5, 6) AND visitors > weekly_avg THEN 'Weekend Surge'
        WHEN day_of_week IN (1, 2, 3, 4) AND visitors > weekly_avg THEN 'Weekday Peak'
        WHEN day_of_week IN (0) AND visitors < weekly_avg THEN 'Sunday Dip'
        ELSE 'Normal Pattern'
    END as day_pattern
FROM seasonal_analysis
ORDER BY page_url, date;

-- =====================================================
-- Example 8: Predictive Indicators
-- =====================================================

-- Create predictive indicators using LAG/LEAD patterns
WITH predictive_indicators AS (
    SELECT 
        symbol,
        date,
        close_price,
        -- Price acceleration (rate of change of rate of change)
        ROUND(
            ((close_price - LAG(close_price, 1) OVER (PARTITION BY symbol ORDER BY date)) -
             (LAG(close_price, 1) OVER (PARTITION BY symbol ORDER BY date) - 
              LAG(close_price, 2) OVER (PARTITION BY symbol ORDER BY date))), 2
        ) as price_acceleration,
        -- Volume-price divergence
        CASE 
            WHEN (close_price > LAG(close_price, 1) OVER (PARTITION BY symbol ORDER BY date)) AND
                 (volume < LAG(volume, 1) OVER (PARTITION BY symbol ORDER BY date)) THEN 'Price Up, Volume Down'
            WHEN (close_price < LAG(close_price, 1) OVER (PARTITION BY symbol ORDER BY date)) AND
                 (volume > LAG(volume, 1) OVER (PARTITION BY symbol ORDER BY date)) THEN 'Price Down, Volume Up'
            WHEN (close_price > LAG(close_price, 1) OVER (PARTITION BY symbol ORDER BY date)) AND
                 (volume > LAG(volume, 1) OVER (PARTITION BY symbol ORDER BY date)) THEN 'Price Up, Volume Up'
            WHEN (close_price < LAG(close_price, 1) OVER (PARTITION BY symbol ORDER BY date)) AND
                 (volume < LAG(volume, 1) OVER (PARTITION BY symbol ORDER BY date)) THEN 'Price Down, Volume Down'
            ELSE 'No Change'
        END as volume_price_divergence,
        -- Support and resistance levels
        LAG(close_price, 1) OVER (PARTITION BY symbol ORDER BY date) as support_level,
        LEAD(close_price, 1) OVER (PARTITION BY symbol ORDER BY date) as resistance_level,
        -- Breakout detection
        CASE 
            WHEN close_price > LAG(close_price, 1) OVER (PARTITION BY symbol ORDER BY date) * 1.02 THEN 'Breakout Up'
            WHEN close_price < LAG(close_price, 1) OVER (PARTITION BY symbol ORDER BY date) * 0.98 THEN 'Breakout Down'
            ELSE 'No Breakout'
        END as breakout_signal
    FROM stock_prices
)
SELECT 
    symbol,
    date,
    close_price,
    price_acceleration,
    volume_price_divergence,
    support_level,
    resistance_level,
    breakout_signal,
    -- Predictive signals
    CASE 
        WHEN price_acceleration > 0 AND volume_price_divergence = 'Price Up, Volume Up' THEN 'Strong Buy Signal'
        WHEN price_acceleration > 0 AND volume_price_divergence = 'Price Up, Volume Down' THEN 'Weak Buy Signal'
        WHEN price_acceleration < 0 AND volume_price_divergence = 'Price Down, Volume Up' THEN 'Strong Sell Signal'
        WHEN price_acceleration < 0 AND volume_price_divergence = 'Price Down, Volume Down' THEN 'Weak Sell Signal'
        ELSE 'Hold'
    END as trading_signal,
    -- Risk assessment
    CASE 
        WHEN breakout_signal != 'No Breakout' AND ABS(price_acceleration) > 1 THEN 'High Risk'
        WHEN breakout_signal != 'No Breakout' THEN 'Medium Risk'
        ELSE 'Low Risk'
    END as risk_level
FROM predictive_indicators
ORDER BY symbol, date;

-- Clean up
DROP TABLE IF EXISTS stock_prices CASCADE;
DROP TABLE IF EXISTS website_metrics CASCADE;
DROP TABLE IF EXISTS sensor_data CASCADE; 
>>>>>>> 4e036c9 (feat(quests) improve quest queries)
