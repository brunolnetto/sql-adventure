-- =====================================================
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
    open_price DECIMAL(8, 2),
    close_price DECIMAL(8, 2),
    high_price DECIMAL(8, 2),
    low_price DECIMAL(8, 2),
    volume INT
);

-- Create website traffic table
CREATE TABLE website_traffic (
    visit_date DATE,
    page_views INT,
    unique_visitors INT,
    bounce_rate DECIMAL(5, 2),
    avg_session_duration INT
);

-- Create temperature readings table
CREATE TABLE temperature_readings (
    reading_time TIMESTAMP,
    temperature_celsius DECIMAL(4, 2),
    humidity_percent DECIMAL(5, 2),
    pressure_hpa DECIMAL(6, 2)
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

-- =====================================================
-- Example 1: Stock Price Trend Analysis
-- =====================================================

-- Analyze stock price trends using LEAD and LAG
SELECT
    date_id,
    stock_symbol,
    close_price,
    LAG(close_price) OVER (ORDER BY date_id) AS prev_close,
    LEAD(close_price) OVER (ORDER BY date_id) AS next_close,
    LAG(close_price, 2) OVER (ORDER BY date_id) AS two_days_ago,
    LEAD(close_price, 2) OVER (ORDER BY date_id) AS two_days_ahead,
    ROUND(
        (close_price - LAG(close_price) OVER (ORDER BY date_id)) * 100.0
        / LAG(close_price) OVER (ORDER BY date_id), 2
    ) AS daily_change_percent,
    ROUND(
        (close_price - LAG(close_price, 2) OVER (ORDER BY date_id)) * 100.0
        / LAG(close_price, 2) OVER (ORDER BY date_id), 2
    ) AS two_day_change_percent,
    CASE
        WHEN close_price > LAG(close_price) OVER (ORDER BY date_id) THEN 'Up'
        WHEN close_price < LAG(close_price) OVER (ORDER BY date_id) THEN 'Down'
        ELSE 'Flat'
    END AS daily_trend,
    CASE
        WHEN
            close_price > LAG(close_price, 2) OVER (ORDER BY date_id)
            THEN 'Rising'
        WHEN
            close_price < LAG(close_price, 2) OVER (ORDER BY date_id)
            THEN 'Falling'
        ELSE 'Sideways'
    END AS two_day_trend
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
        LAG(close_price) OVER (ORDER BY date_id) AS prev_close,
        LAG(close_price, 2) OVER (ORDER BY date_id) AS two_days_ago,
        LAG(close_price, 3) OVER (ORDER BY date_id) AS three_days_ago,
        LEAD(close_price) OVER (ORDER BY date_id) AS next_close,
        LEAD(close_price, 2) OVER (ORDER BY date_id) AS two_days_ahead
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
    ROUND((close_price + prev_close + two_days_ago) / 3.0, 2) AS ma_3day,
    -- 5-day moving average
    ROUND((
        close_price + prev_close + two_days_ago + three_days_ago
        + LAG(close_price, 4) OVER (ORDER BY date_id)
    ) / 5.0, 2) AS ma_5day,
    -- Price momentum (current vs 3 days ago)
    ROUND(
        (close_price - three_days_ago) * 100.0 / three_days_ago, 2
    ) AS momentum_3day_percent,
    -- Price acceleration (change in momentum)
    ROUND(
        ((close_price - prev_close) - (prev_close - two_days_ago))
        * 100.0
        / two_days_ago,
        2
    ) AS acceleration_percent,
    -- Trend strength
    CASE
        WHEN
            close_price > prev_close AND prev_close > two_days_ago
            THEN 'Strong Up'
        WHEN
            close_price > prev_close AND prev_close <= two_days_ago
            THEN 'Weak Up'
        WHEN
            close_price < prev_close AND prev_close < two_days_ago
            THEN 'Strong Down'
        WHEN
            close_price < prev_close AND prev_close >= two_days_ago
            THEN 'Weak Down'
        ELSE 'Sideways'
    END AS trend_strength
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
    LAG(page_views) OVER (ORDER BY visit_date) AS prev_page_views,
    LEAD(page_views) OVER (ORDER BY visit_date) AS next_page_views,
    LAG(unique_visitors) OVER (ORDER BY visit_date) AS prev_visitors,
    LEAD(unique_visitors) OVER (ORDER BY visit_date) AS next_visitors,
    ROUND(
        (page_views - LAG(page_views) OVER (ORDER BY visit_date)) * 100.0
        / LAG(page_views) OVER (ORDER BY visit_date), 2
    ) AS page_views_growth_percent,
    ROUND(
        (unique_visitors - LAG(unique_visitors) OVER (ORDER BY visit_date))
        * 100.0
        / LAG(unique_visitors) OVER (ORDER BY visit_date), 2
    ) AS visitors_growth_percent,
    ROUND(
        (bounce_rate - LAG(bounce_rate) OVER (ORDER BY visit_date)), 2
    ) AS bounce_rate_change,
    ROUND(
        (
            avg_session_duration
            - LAG(avg_session_duration) OVER (ORDER BY visit_date)
        ),
        0
    ) AS session_duration_change,
    CASE
        WHEN
            page_views > LAG(page_views) OVER (ORDER BY visit_date)
            AND unique_visitors
            > LAG(unique_visitors) OVER (ORDER BY visit_date)
            THEN 'Growth'
        WHEN
            page_views < LAG(page_views) OVER (ORDER BY visit_date)
            AND unique_visitors
            < LAG(unique_visitors) OVER (ORDER BY visit_date)
            THEN 'Decline'
        ELSE 'Mixed'
    END AS traffic_trend
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
        LAG(temperature_celsius) OVER (ORDER BY reading_time) AS prev_temp,
        LEAD(temperature_celsius) OVER (ORDER BY reading_time) AS next_temp,
        LAG(temperature_celsius, 2)
            OVER (ORDER BY reading_time)
            AS two_hours_ago,
        LEAD(temperature_celsius, 2)
            OVER (ORDER BY reading_time)
            AS two_hours_ahead,
        AVG(temperature_celsius) OVER (
            ORDER BY reading_time
            ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
        ) AS moving_avg_5hour,
        STDDEV(temperature_celsius) OVER (
            ORDER BY reading_time
            ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
        ) AS moving_stddev_5hour
    FROM temperature_readings
)

SELECT
    reading_time,
    temperature_celsius,
    humidity_percent,
    pressure_hpa,
    ROUND(prev_temp, 2) AS prev_temp,
    ROUND(next_temp, 2) AS next_temp,
    ROUND(two_hours_ago, 2) AS two_hours_ago,
    ROUND(two_hours_ahead, 2) AS two_hours_ahead,
    ROUND(moving_avg_5hour, 2) AS moving_avg_5hour,
    ROUND(moving_stddev_5hour, 2) AS moving_stddev_5hour,
    ROUND(
        (temperature_celsius - moving_avg_5hour)
        / NULLIF(moving_stddev_5hour, 0),
        2
    ) AS z_score,
    ROUND(
        (temperature_celsius - prev_temp), 2
    ) AS temp_change_1h,
    ROUND(
        (temperature_celsius - two_hours_ago), 2
    ) AS temp_change_2h,
    CASE
        WHEN
            ABS(
                (temperature_celsius - moving_avg_5hour)
                / NULLIF(moving_stddev_5hour, 0)
            )
            > 2
            THEN 'Anomaly'
        WHEN
            ABS(
                (temperature_celsius - moving_avg_5hour)
                / NULLIF(moving_stddev_5hour, 0)
            )
            > 1.5
            THEN 'Unusual'
        ELSE 'Normal'
    END AS anomaly_status,
    CASE
        WHEN
            temperature_celsius > prev_temp AND prev_temp > two_hours_ago
            THEN 'Rising'
        WHEN
            temperature_celsius < prev_temp AND prev_temp < two_hours_ago
            THEN 'Falling'
        WHEN
            temperature_celsius > prev_temp AND prev_temp <= two_hours_ago
            THEN 'Turning Up'
        WHEN
            temperature_celsius < prev_temp AND prev_temp >= two_hours_ago
            THEN 'Turning Down'
        ELSE 'Stable'
    END AS temperature_trend
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
        LAG(close_price) OVER (ORDER BY date_id) AS prev_close,
        LAG(close_price, 2) OVER (ORDER BY date_id) AS two_days_ago,
        LAG(volume) OVER (ORDER BY date_id) AS prev_volume,
        LAG(volume, 2) OVER (ORDER BY date_id) AS two_days_ago_volume,
        LEAD(close_price) OVER (ORDER BY date_id) AS next_close,
        LEAD(close_price, 2) OVER (ORDER BY date_id) AS two_days_ahead,
        LEAD(volume) OVER (ORDER BY date_id) AS next_volume
    FROM stock_prices
    WHERE stock_symbol = 'AAPL'
)

SELECT
    date_id,
    close_price,
    volume,
    ROUND(prev_close, 2) AS prev_close,
    ROUND(two_days_ago, 2) AS two_days_ago,
    ROUND(next_close, 2) AS next_close,
    ROUND(two_days_ahead, 2) AS two_days_ahead,
    -- Volume trend
    CASE
        WHEN
            volume > prev_volume AND prev_volume > two_days_ago_volume
            THEN 'Increasing Volume'
        WHEN
            volume < prev_volume AND prev_volume < two_days_ago_volume
            THEN 'Decreasing Volume'
        ELSE 'Mixed Volume'
    END AS volume_trend,
    -- Price pattern
    CASE
        WHEN
            close_price > prev_close AND prev_close > two_days_ago
            THEN 'Uptrend'
        WHEN
            close_price < prev_close AND prev_close < two_days_ago
            THEN 'Downtrend'
        WHEN
            close_price > prev_close AND prev_close <= two_days_ago
            THEN 'Reversal Up'
        WHEN
            close_price < prev_close AND prev_temp >= two_days_ago
            THEN 'Reversal Down'
        ELSE 'Sideways'
    END AS price_pattern,
    -- Volume-price relationship
    CASE
        WHEN close_price > prev_close AND volume > prev_volume THEN 'Bullish'
        WHEN close_price < prev_close AND volume > prev_volume THEN 'Bearish'
        WHEN
            close_price > prev_close AND volume < prev_volume
            THEN 'Weak Bullish'
        WHEN
            close_price < prev_close AND volume < prev_volume
            THEN 'Weak Bearish'
        ELSE 'Neutral'
    END AS volume_price_signal,
    -- Predictive signal
    CASE
        WHEN
            close_price > prev_close AND volume > prev_volume * 1.2
            THEN 'Strong Buy Signal'
        WHEN
            close_price < prev_close AND volume > prev_volume * 1.2
            THEN 'Strong Sell Signal'
        WHEN
            close_price > prev_close AND volume < prev_volume * 0.8
            THEN 'Weak Buy Signal'
        WHEN
            close_price < prev_close AND volume < prev_volume * 0.8
            THEN 'Weak Sell Signal'
        ELSE 'Hold'
    END AS trading_signal
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
        EXTRACT(DOW FROM visit_date) AS day_of_week,
        LAG(page_views)
            OVER (PARTITION BY EXTRACT(DOW FROM visit_date) ORDER BY visit_date)
            AS prev_week_same_day,
        LAG(page_views, 7) OVER (ORDER BY visit_date) AS week_ago,
        AVG(page_views)
            OVER (PARTITION BY EXTRACT(DOW FROM visit_date))
            AS avg_same_day_views,
        STDDEV(page_views)
            OVER (PARTITION BY EXTRACT(DOW FROM visit_date))
            AS stddev_same_day_views
    FROM website_traffic
)

SELECT
    visit_date,
    page_views,
    unique_visitors,
    CASE day_of_week
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END AS day_name,
    ROUND(prev_week_same_day, 0) AS prev_week_same_day,
    ROUND(week_ago, 0) AS week_ago,
    ROUND(avg_same_day_views, 0) AS avg_same_day_views,
    ROUND(stddev_same_day_views, 0) AS stddev_same_day_views,
    ROUND(
        (page_views - avg_same_day_views) / NULLIF(stddev_same_day_views, 0), 2
    ) AS same_day_z_score,
    ROUND(
        (page_views - prev_week_same_day)
        * 100.0
        / NULLIF(prev_week_same_day, 0),
        2
    ) AS week_over_week_change,
    ROUND(
        (page_views - week_ago) * 100.0 / NULLIF(week_ago, 0), 2
    ) AS week_ago_change,
    CASE
        WHEN
            page_views > avg_same_day_views + stddev_same_day_views
            THEN 'Above Average'
        WHEN
            page_views < avg_same_day_views - stddev_same_day_views
            THEN 'Below Average'
        ELSE 'Average'
    END AS performance_vs_typical,
    CASE
        WHEN
            page_views > prev_week_same_day AND prev_week_same_day > week_ago
            THEN 'Improving Trend'
        WHEN
            page_views < prev_week_same_day AND prev_week_same_day < week_ago
            THEN 'Declining Trend'
        WHEN
            page_views > prev_week_same_day AND prev_week_same_day <= week_ago
            THEN 'Recovery'
        WHEN
            page_views < prev_week_same_day AND prev_week_same_day >= week_ago
            THEN 'Deterioration'
        ELSE 'Stable'
    END AS weekly_trend
FROM weekly_patterns
ORDER BY visit_date;

-- Clean up
DROP TABLE IF EXISTS stock_prices CASCADE;
DROP TABLE IF EXISTS website_traffic CASCADE;
DROP TABLE IF EXISTS temperature_readings CASCADE;
