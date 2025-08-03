-- =====================================================
-- Forward Fill Nulls Example
-- =====================================================
-- 
-- PURPOSE: Demonstrate recursive CTE for forward-filling missing values in time series data
-- LEARNING OUTCOMES:
--   - Understand data imputation and forward fill techniques
--   - Learn to propagate last known value for NULLs using recursion
--   - Master recursive data repair for time series data
-- EXPECTED RESULTS: Fill all NULLs in temperature, humidity, and pressure columns using previous values
-- DIFFICULTY: 🟢 Beginner (5-10 min)
-- CONCEPTS: Data imputation, forward fill, time series repair, NULL handling

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
(2, '2024-01-01 08:15:00', 1, NULL, 46.1, 1013.30),  -- NULL temperature
(3, '2024-01-01 08:30:00', 1, NULL, NULL, 1013.28),   -- NULL temperature and humidity
(4, '2024-01-01 08:45:00', 1, 23.1, 47.5, NULL),      -- NULL pressure
(5, '2024-01-01 09:00:00', 1, NULL, 48.2, 1013.35),   -- NULL temperature
(6, '2024-01-01 09:15:00', 1, 24.0, NULL, 1013.40),   -- NULL humidity
(7, '2024-01-01 09:30:00', 1, NULL, NULL, NULL),       -- All NULLs
(8, '2024-01-01 09:45:00', 1, 25.2, 50.1, 1013.45),
(9, '2024-01-01 10:00:00', 2, 26.0, 51.0, 1013.50),
(10, '2024-01-01 10:15:00', 2, NULL, 52.1, 1013.55),  -- NULL temperature
(11, '2024-01-01 10:30:00', 2, 27.5, NULL, NULL),      -- NULL humidity and pressure
(12, '2024-01-01 10:45:00', 2, NULL, NULL, 1013.60);  -- NULL temperature and humidity

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
    ff.id,
    ff.timestamp,
    ff.sensor_id,
    ff.temperature,
    ff.humidity,
    ff.pressure,
    CASE 
        WHEN tsd.temperature IS NULL THEN 'Forward Filled'
        ELSE 'Original'
    END as temperature_status,
    CASE 
        WHEN tsd.humidity IS NULL THEN 'Forward Filled'
        ELSE 'Original'
    END as humidity_status,
    CASE 
        WHEN tsd.pressure IS NULL THEN 'Forward Filled'
        ELSE 'Original'
    END as pressure_status
FROM forward_fill ff
INNER JOIN time_series_data tsd ON ff.id = tsd.id
ORDER BY ff.sensor_id, ff.timestamp;

-- Alternative approach: Forward fill with window functions for comparison
-- Note: This demonstrates the recursive CTE approach vs window functions
-- The recursive CTE approach above is more flexible and works in all PostgreSQL versions
SELECT 
    'Recursive CTE approach shown above' as approach,
    'Window functions with IGNORE NULLS not supported in PostgreSQL' as note;

-- Clean up
DROP TABLE IF EXISTS time_series_data CASCADE; 