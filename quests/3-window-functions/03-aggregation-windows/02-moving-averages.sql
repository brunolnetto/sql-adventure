-- =====================================================
-- Window Functions quest: Moving Averages & Rolling Calculations
-- =====================================================

-- PURPOSE: Demonstrate window function aggregation for moving averages
--          and rolling calculations across different time windows
-- LEARNING OUTCOMES: Students will understand how to use AVG() OVER() 
--                    for moving averages, rolling statistics, and trend analysis
-- EXPECTED RESULTS:
-- 1. Simple moving averages with different window sizes
-- 2. Rolling statistics (mean, std dev, volatility)
-- 3. Trend analysis and momentum indicators
-- 4. Anomaly detection using rolling metrics
-- 5. Financial analysis with moving averages
-- DIFFICULTY: 🟡 Intermediate (10-20 min)
-- CONCEPTS: AVG() OVER(), ROWS BETWEEN, rolling windows, moving averages, trend analysis
DROP TABLE IF EXISTS stock_prices CASCADE;
DROP TABLE IF EXISTS website_traffic CASCADE;
DROP TABLE IF EXISTS sensor_readings CASCADE;

-- =====================================================
-- Example 1: Stock Price Moving Averages
-- =====================================================

-- Create stock prices table
CREATE TABLE stock_prices (
    date DATE PRIMARY KEY,
    symbol VARCHAR(10),
    close_price DECIMAL(10, 2),
    volume BIGINT
);

-- Insert sample stock data
INSERT INTO stock_prices VALUES
('2024-01-01', 'AAPL', 150.25, 50000000),
('2024-01-02', 'AAPL', 152.30, 52000000),
('2024-01-03', 'AAPL', 149.80, 48000000),
('2024-01-04', 'AAPL', 151.45, 51000000),
('2024-01-05', 'AAPL', 153.20, 53000000),
('2024-01-08', 'AAPL', 154.75, 54000000),
('2024-01-09', 'AAPL', 152.90, 49000000),
('2024-01-10', 'AAPL', 155.30, 55000000),
('2024-01-11', 'AAPL', 156.80, 56000000),
('2024-01-12', 'AAPL', 158.45, 58000000),
('2024-01-15', 'AAPL', 157.20, 52000000),
('2024-01-16', 'AAPL', 159.80, 59000000),
('2024-01-17', 'AAPL', 161.25, 61000000),
('2024-01-18', 'AAPL', 160.90, 57000000),
('2024-01-19', 'AAPL', 162.75, 62000000);

-- Demonstrate different moving averages
SELECT
    date,
    symbol,
    close_price,
    -- 3-day simple moving average
    AVG(close_price) OVER (
        ORDER BY date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS sma_3day,
    -- 5-day simple moving average
    AVG(close_price) OVER (
        ORDER BY date
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS sma_5day,
    -- 7-day simple moving average
    AVG(close_price) OVER (
        ORDER BY date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS sma_7day,
    -- Volume moving average
    AVG(volume) OVER (
        ORDER BY date
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS volume_ma_5day
FROM stock_prices
ORDER BY date;

-- =====================================================
-- Example 2: Website Traffic Analysis
-- =====================================================

-- Create website traffic table
CREATE TABLE website_traffic (
    date DATE,
    page_url VARCHAR(200),
    visitors INT,
    page_views INT,
    bounce_rate DECIMAL(5, 2),
    PRIMARY KEY (date, page_url)
);

-- Insert sample traffic data
INSERT INTO website_traffic VALUES
('2024-01-01', '/home', 1200, 1800, 35.5),
('2024-01-02', '/home', 1350, 2100, 32.1),
('2024-01-03', '/home', 1100, 1650, 38.2),
('2024-01-04', '/home', 1400, 2200, 30.8),
('2024-01-05', '/home', 1600, 2500, 28.5),
('2024-01-06', '/home', 1800, 2800, 26.3),
('2024-01-07', '/home', 1700, 2600, 27.8),
('2024-01-08', '/home', 1900, 3000, 25.1),
('2024-01-09', '/home', 2100, 3300, 23.5),
('2024-01-10', '/home', 2000, 3100, 24.8),
('2024-01-01', '/products', 800, 1200, 45.2),
('2024-01-02', '/products', 900, 1350, 42.8),
('2024-01-03', '/products', 750, 1100, 48.1),
('2024-01-04', '/products', 950, 1450, 41.5),
('2024-01-05', '/products', 1100, 1700, 38.9),
('2024-01-06', '/products', 1200, 1850, 36.2),
('2024-01-07', '/products', 1150, 1750, 37.8),
('2024-01-08', '/products', 1300, 2000, 34.5),
('2024-01-09', '/products', 1400, 2150, 32.1),
('2024-01-10', '/products', 1350, 2050, 33.8);

-- Analyze traffic trends with moving averages
SELECT
    date,
    page_url,
    visitors,
    page_views,
    bounce_rate,
    -- 3-day moving average for visitors
    AVG(visitors) OVER (
        PARTITION BY page_url
        ORDER BY date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS visitors_ma_3day,
    -- 5-day moving average for page views
    AVG(page_views) OVER (
        PARTITION BY page_url
        ORDER BY date
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS pageviews_ma_5day,
    -- 7-day moving average for bounce rate
    AVG(bounce_rate) OVER (
        PARTITION BY page_url
        ORDER BY date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS bounce_rate_ma_7day,
    -- Trend indicator (current vs 3-day average)
    CASE
        WHEN visitors > AVG(visitors) OVER (
            PARTITION BY page_url
            ORDER BY date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) THEN 'Increasing'
        ELSE 'Decreasing'
    END AS visitor_trend
FROM website_traffic
ORDER BY page_url, date;

-- =====================================================
-- Example 3: Sensor Data Analysis
-- =====================================================

-- Create sensor readings table
CREATE TABLE sensor_readings (
    timestamp TIMESTAMP,
    sensor_id VARCHAR(20),
    temperature DECIMAL(5, 2),
    humidity DECIMAL(5, 2),
    pressure DECIMAL(8, 2),
    PRIMARY KEY (timestamp, sensor_id)
);

-- Insert sample sensor data
INSERT INTO sensor_readings VALUES
('2024-01-01 00:00:00', 'SENSOR_001', 22.5, 45.2, 1013.25),
('2024-01-01 01:00:00', 'SENSOR_001', 22.8, 44.8, 1013.30),
('2024-01-01 02:00:00', 'SENSOR_001', 23.1, 44.5, 1013.28),
('2024-01-01 03:00:00', 'SENSOR_001', 22.9, 45.1, 1013.32),
('2024-01-01 04:00:00', 'SENSOR_001', 22.6, 45.8, 1013.29),
('2024-01-01 05:00:00', 'SENSOR_001', 22.3, 46.2, 1013.26),
('2024-01-01 06:00:00', 'SENSOR_001', 22.7, 45.9, 1013.31),
('2024-01-01 07:00:00', 'SENSOR_001', 23.2, 45.3, 1013.35),
('2024-01-01 08:00:00', 'SENSOR_001', 23.8, 44.7, 1013.40),
('2024-01-01 09:00:00', 'SENSOR_001', 24.1, 44.2, 1013.38),
('2024-01-01 10:00:00', 'SENSOR_001', 24.5, 43.8, 1013.42),
('2024-01-01 11:00:00', 'SENSOR_001', 24.8, 43.5, 1013.45),
('2024-01-01 12:00:00', 'SENSOR_001', 25.2, 43.1, 1013.48),
('2024-01-01 13:00:00', 'SENSOR_001', 25.5, 42.8, 1013.50),
('2024-01-01 14:00:00', 'SENSOR_001', 25.8, 42.5, 1013.52),
('2024-01-01 15:00:00', 'SENSOR_001', 25.6, 42.9, 1013.49),
('2024-01-01 16:00:00', 'SENSOR_001', 25.3, 43.2, 1013.46),
('2024-01-01 17:00:00', 'SENSOR_001', 25.0, 43.6, 1013.43),
('2024-01-01 18:00:00', 'SENSOR_001', 24.7, 44.0, 1013.40),
('2024-01-01 19:00:00', 'SENSOR_001', 24.4, 44.4, 1013.37),
('2024-01-01 20:00:00', 'SENSOR_001', 24.1, 44.8, 1013.34),
('2024-01-01 21:00:00', 'SENSOR_001', 23.8, 45.2, 1013.31),
('2024-01-01 22:00:00', 'SENSOR_001', 23.5, 45.6, 1013.28),
('2024-01-01 23:00:00', 'SENSOR_001', 23.2, 46.0, 1013.25);

-- Analyze sensor data with multiple moving averages
SELECT
    timestamp,
    sensor_id,
    temperature,
    humidity,
    pressure,
    -- 3-hour moving average for temperature
    AVG(temperature) OVER (
        PARTITION BY sensor_id
        ORDER BY timestamp
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS temp_ma_3hour,
    -- 6-hour moving average for humidity
    AVG(humidity) OVER (
        PARTITION BY sensor_id
        ORDER BY timestamp
        ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
    ) AS humidity_ma_6hour,
    -- 12-hour moving average for pressure
    AVG(pressure) OVER (
        PARTITION BY sensor_id
        ORDER BY timestamp
        ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
    ) AS pressure_ma_12hour,
    -- Temperature trend (current vs 3-hour average)
    temperature - AVG(temperature) OVER (
        PARTITION BY sensor_id
        ORDER BY timestamp
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS temp_deviation,
    -- Anomaly detection (temperature > 2 std dev from 6-hour average)
    CASE
        WHEN ABS(temperature - AVG(temperature) OVER (
            PARTITION BY sensor_id
            ORDER BY timestamp
            ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
        )) > 2 * STDDEV(temperature) OVER (
            PARTITION BY sensor_id
            ORDER BY timestamp
            ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
        ) THEN 'ANOMALY'
        ELSE 'NORMAL'
    END AS anomaly_flag
FROM sensor_readings
ORDER BY timestamp;

-- =====================================================
-- Example 4: Advanced Moving Average Patterns
-- =====================================================

-- Demonstrate exponential moving average simulation
-- (PostgreSQL doesn't have built-in EMA, so we simulate it)
WITH stock_data AS (
    SELECT
        date,
        close_price,
        -- Simple moving average
        AVG(close_price) OVER (
            ORDER BY date
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS sma_5day,
        -- Weighted moving average (more recent data has higher weight)
        (
            close_price * 5
            + LAG(close_price, 1) OVER (ORDER BY date) * 4
            + LAG(close_price, 2) OVER (ORDER BY date) * 3
            + LAG(close_price, 3) OVER (ORDER BY date) * 2
            + LAG(close_price, 4) OVER (ORDER BY date) * 1
        ) / 15.0 AS wma_5day
    FROM stock_prices
)

SELECT
    date,
    close_price,
    sma_5day,
    wma_5day,
    -- Compare SMA vs WMA
    CASE
        WHEN wma_5day > sma_5day THEN 'WMA > SMA (Bullish)'
        WHEN wma_5day < sma_5day THEN 'WMA < SMA (Bearish)'
        ELSE 'WMA = SMA (Neutral)'
    END AS trend_signal,
    -- Price position relative to moving averages
    CASE
        WHEN
            close_price > wma_5day AND wma_5day > sma_5day
            THEN 'Strong Bullish'
        WHEN close_price > wma_5day THEN 'Moderate Bullish'
        WHEN
            close_price < wma_5day AND wma_5day < sma_5day
            THEN 'Strong Bearish'
        WHEN close_price < wma_5day THEN 'Moderate Bearish'
        ELSE 'Neutral'
    END AS position_signal
FROM stock_data
WHERE date >= '2024-01-05'  -- Only show dates with enough history
ORDER BY date;

-- =====================================================
-- Example 5: Rolling Statistics and Volatility
-- =====================================================

-- Calculate rolling statistics for stock prices
SELECT
    date,
    close_price,
    -- 5-day moving average
    AVG(close_price) OVER (
        ORDER BY date
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS ma_5day,
    -- 5-day standard deviation (volatility)
    STDDEV(close_price) OVER (
        ORDER BY date
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS volatility_5day,
    -- 5-day coefficient of variation (volatility relative to mean)
    CASE
        WHEN
            AVG(close_price) OVER (
                ORDER BY date
                ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
            ) > 0
            THEN
                STDDEV(close_price) OVER (
                    ORDER BY date
                    ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
                ) / AVG(close_price) OVER (
                    ORDER BY date
                    ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
                ) * 100
    END AS cv_5day_percent,
    -- Price range (high-low) over 5 days
    MAX(close_price) OVER (
        ORDER BY date
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) - MIN(close_price) OVER (
        ORDER BY date
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS price_range_5day,
    -- Volatility classification
    CASE
        WHEN STDDEV(close_price) OVER (
            ORDER BY date
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) > 3.0 THEN 'High Volatility'
        WHEN STDDEV(close_price) OVER (
            ORDER BY date
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) > 1.5 THEN 'Medium Volatility'
        ELSE 'Low Volatility'
    END AS volatility_level
FROM stock_prices
WHERE date >= '2024-01-05'  -- Only show dates with enough history
ORDER BY date;

-- Clean up
DROP TABLE IF EXISTS stock_prices CASCADE;
DROP TABLE IF EXISTS website_traffic CASCADE;
DROP TABLE IF EXISTS sensor_readings CASCADE;
