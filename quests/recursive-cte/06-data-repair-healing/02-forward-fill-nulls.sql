-- =====================================================
-- Forward Fill Nulls Example
-- =====================================================

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS time_series_data CASCADE;

-- Create table with time series data containing nulls
CREATE TABLE time_series_data (
    id INT PRIMARY KEY,
    timestamp TIMESTAMP,
    sensor_id INT,
    temperature DECIMAL(5,2),
    humidity DECIMAL(5,2),
    pressure DECIMAL(8,2)
);

-- Insert sample data with null values
INSERT INTO time_series_data VALUES
(1, '2024-01-01 08:00:00', 1, 22.5, 45.2, 1013.25),
(2, '2024-01-01 08:15:00', 1, NULL, 46.1, 1013.30),
(3, '2024-01-01 08:30:00', 1, NULL, NULL, 1013.28),
(4, '2024-01-01 08:45:00', 1, 23.1, 47.5, NULL),
(5, '2024-01-01 09:00:00', 1, NULL, 48.2, 1013.35),
(6, '2024-01-01 09:15:00', 1, 24.0, NULL, 1013.40),
(7, '2024-01-01 09:30:00', 1, NULL, NULL, NULL),
(8, '2024-01-01 09:45:00', 1, 25.2, 50.1, 1013.45),
(9, '2024-01-01 10:00:00', 2, 26.0, 51.0, 1013.50),
(10, '2024-01-01 10:15:00', 2, NULL, 52.1, 1013.55),
(11, '2024-01-01 10:30:00', 2, 27.5, NULL, NULL),
(12, '2024-01-01 10:45:00', 2, NULL, NULL, 1013.60);

-- Forward fill nulls using recursive CTE
WITH RECURSIVE forward_fill AS (
    -- Base case: first row for each sensor
    SELECT 
        id,
        timestamp,
        sensor_id,
        temperature,
        humidity,
        pressure,
        1 as row_num
    FROM time_series_data
    WHERE id = (
        SELECT MIN(id) 
        FROM time_series_data ts2 
        WHERE ts2.sensor_id = time_series_data.sensor_id
    )
    
    UNION ALL
    
    -- Recursive case: fill nulls with previous values
    SELECT 
        tsd.id,
        tsd.timestamp,
        tsd.sensor_id,
        COALESCE(tsd.temperature, ff.temperature) as temperature,
        COALESCE(tsd.humidity, ff.humidity) as humidity,
        COALESCE(tsd.pressure, ff.pressure) as pressure,
        ff.row_num + 1
    FROM time_series_data tsd
    INNER JOIN forward_fill ff ON tsd.sensor_id = ff.sensor_id
    WHERE tsd.id > ff.id
    AND tsd.id = (
        SELECT MIN(id) 
        FROM time_series_data ts3 
        WHERE ts3.sensor_id = tsd.sensor_id 
        AND ts3.id > ff.id
    )
)
SELECT 
    id,
    timestamp,
    sensor_id,
    temperature,
    humidity,
    pressure,
    CASE 
        WHEN temperature IS NOT NULL THEN 'Original'
        ELSE 'Forward Filled'
    END as temperature_status,
    CASE 
        WHEN humidity IS NOT NULL THEN 'Original'
        ELSE 'Forward Filled'
    END as humidity_status,
    CASE 
        WHEN pressure IS NOT NULL THEN 'Original'
        ELSE 'Forward Filled'
    END as pressure_status
FROM forward_fill
ORDER BY sensor_id, timestamp;

-- Alternative approach: Forward fill with window functions for comparison
WITH filled_data AS (
    SELECT 
        id,
        timestamp,
        sensor_id,
        temperature,
        humidity,
        pressure,
        -- Forward fill using window functions
        FIRST_VALUE(temperature) IGNORE NULLS OVER (
            PARTITION BY sensor_id 
            ORDER BY timestamp 
            ROWS UNBOUNDED PRECEDING
        ) as filled_temperature,
        FIRST_VALUE(humidity) IGNORE NULLS OVER (
            PARTITION BY sensor_id 
            ORDER BY timestamp 
            ROWS UNBOUNDED PRECEDING
        ) as filled_humidity,
        FIRST_VALUE(pressure) IGNORE NULLS OVER (
            PARTITION BY sensor_id 
            ORDER BY timestamp 
            ROWS UNBOUNDED PRECEDING
        ) as filled_pressure
    FROM time_series_data
)
SELECT 
    id,
    timestamp,
    sensor_id,
    temperature as original_temperature,
    filled_temperature,
    humidity as original_humidity,
    filled_humidity,
    pressure as original_pressure,
    filled_pressure,
    CASE 
        WHEN temperature IS NULL THEN 'Filled'
        ELSE 'Original'
    END as temperature_status
FROM filled_data
ORDER BY sensor_id, timestamp;

-- Clean up
DROP TABLE IF EXISTS time_series_data CASCADE; 