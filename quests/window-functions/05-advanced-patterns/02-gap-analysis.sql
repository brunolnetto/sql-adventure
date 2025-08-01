-- =====================================================
<<<<<<< HEAD
-- Window Functions: Gap Analysis and Sequence Detection
-- =====================================================

-- PURPOSE: Demonstrate advanced gap analysis techniques using window functions
--          for detecting missing data, sequence gaps, and data quality issues
-- LEARNING OUTCOMES: Students will understand how to use window functions for
--                    gap detection, sequence analysis, data quality assessment,
--                    and identifying missing or inconsistent data patterns
-- EXPECTED RESULTS:
-- 1. Missing sequence numbers identified in ordered data
-- 2. Data gaps detected in time series with irregular intervals
-- 3. Quality issues identified in sensor readings
-- 4. Missing transactions detected in financial data
-- 5. Attendance gaps identified in employee records
-- 6. Inventory gaps detected in product sequences
-- 7. Network connectivity gaps identified
-- 8. Comprehensive gap analysis with gap size classification
-- DIFFICULTY: ⚫ Expert (30-45 min)
-- CONCEPTS: LAG(), LEAD(), gap detection, sequence analysis, data quality, missing data identification, time series gaps

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS sequence_data CASCADE;
DROP TABLE IF EXISTS time_series_data CASCADE;
DROP TABLE IF EXISTS sensor_readings CASCADE;
DROP TABLE IF EXISTS financial_transactions CASCADE;
DROP TABLE IF EXISTS employee_attendance CASCADE;
DROP TABLE IF EXISTS inventory_log CASCADE;
DROP TABLE IF EXISTS network_connectivity CASCADE;

-- Create sequence data table
CREATE TABLE sequence_data (
    id INT PRIMARY KEY,
    value VARCHAR(50),
    sequence_number INT,
    created_date TIMESTAMP
);

-- Insert sample data with gaps
INSERT INTO sequence_data VALUES
(1, 'Item A', 1, '2024-01-01 10:00:00'),
(2, 'Item B', 3, '2024-01-01 10:05:00'),  -- Gap: missing 2
(3, 'Item C', 7, '2024-01-01 10:10:00'),  -- Gap: missing 4, 5, 6
(4, 'Item D', 10, '2024-01-01 10:15:00'), -- Gap: missing 8, 9
(5, 'Item E', 15, '2024-01-01 10:20:00'); -- Gap: missing 11, 12, 13, 14

-- Example 1: Basic Gap Detection in Sequences
-- Find gaps in sequence numbers
WITH sequence_gaps AS (
    SELECT 
        sequence_number,
        LAG(sequence_number) OVER (ORDER BY sequence_number) as prev_sequence,
        sequence_number - LAG(sequence_number) OVER (ORDER BY sequence_number) as gap_size
    FROM sequence_data
)
SELECT 
    prev_sequence,
    sequence_number,
    gap_size,
    CASE 
        WHEN gap_size > 1 THEN 'Gap detected'
        ELSE 'No gap'
    END as gap_status
FROM sequence_gaps
WHERE gap_size > 1 OR gap_size IS NULL
ORDER BY sequence_number;

-- Create time series data table
CREATE TABLE time_series_data (
    id INT PRIMARY KEY,
    timestamp TIMESTAMP,
    value DECIMAL(10,2),
    expected_interval_minutes INT
);

-- Insert sample data with irregular intervals
INSERT INTO time_series_data VALUES
(1, '2024-01-01 09:00:00', 100.50, 15),
(2, '2024-01-01 09:15:00', 102.30, 15),
(3, '2024-01-01 09:45:00', 98.70, 15),   -- Gap: missing 09:30:00
(4, '2024-01-01 10:00:00', 105.20, 15),
(5, '2024-01-01 10:30:00', 103.80, 15),  -- Gap: missing 10:15:00
(6, '2024-01-01 11:00:00', 107.40, 15),
(7, '2024-01-01 11:45:00', 104.90, 15);  -- Gap: missing 11:15:00, 11:30:00

-- Example 2: Time Series Gap Detection
-- Find missing time intervals in time series data
WITH time_gaps AS (
    SELECT 
        timestamp,
        value,
        LAG(timestamp) OVER (ORDER BY timestamp) as prev_timestamp,
        EXTRACT(EPOCH FROM (timestamp - LAG(timestamp) OVER (ORDER BY timestamp)))/60 as minutes_diff
    FROM time_series_data
)
SELECT 
    prev_timestamp,
    timestamp,
    minutes_diff,
    CASE 
        WHEN minutes_diff > 15 THEN 'Large gap detected'
        WHEN minutes_diff > 15 THEN 'Small gap detected'
        ELSE 'Normal interval'
    END as gap_type,
    ROUND(minutes_diff / 15, 1) as expected_intervals_missing
FROM time_gaps
WHERE minutes_diff > 15
ORDER BY timestamp;

-- Create sensor readings table
CREATE TABLE sensor_readings (
    id INT PRIMARY KEY,
    sensor_id INT,
    reading_time TIMESTAMP,
    temperature DECIMAL(5,2),
    humidity DECIMAL(5,2),
    pressure DECIMAL(8,2)
);

-- Insert sample data with quality issues
INSERT INTO sensor_readings VALUES
(1, 1, '2024-01-01 08:00:00', 22.5, 45.2, 1013.25),
(2, 1, '2024-01-01 08:15:00', NULL, 46.1, 1013.30),  -- Missing temperature
(3, 1, '2024-01-01 08:30:00', 23.1, NULL, 1013.28),   -- Missing humidity
(4, 1, '2024-01-01 08:45:00', 23.8, 47.5, NULL),      -- Missing pressure
(5, 1, '2024-01-01 09:00:00', 24.2, 48.2, 1013.35),
(6, 1, '2024-01-01 09:15:00', NULL, NULL, NULL),      -- All values missing
(7, 1, '2024-01-01 09:30:00', 25.1, 49.8, 1013.40);

-- Example 3: Data Quality Gap Analysis
-- Detect missing values and data quality issues
SELECT 
    id,
    sensor_id,
    reading_time,
    temperature,
    humidity,
    pressure,
    CASE 
        WHEN temperature IS NULL AND humidity IS NULL AND pressure IS NULL THEN 'Complete data loss'
        WHEN temperature IS NULL OR humidity IS NULL OR pressure IS NULL THEN 'Partial data loss'
        ELSE 'Data complete'
    END as data_quality_status,
    CASE 
        WHEN temperature IS NULL THEN 'Temperature missing'
        WHEN humidity IS NULL THEN 'Humidity missing'
        WHEN pressure IS NULL THEN 'Pressure missing'
        ELSE 'All values present'
    END as missing_values
FROM sensor_readings
WHERE temperature IS NULL OR humidity IS NULL OR pressure IS NULL
ORDER BY reading_time;

-- Create financial transactions table
CREATE TABLE financial_transactions (
    id INT PRIMARY KEY,
    transaction_date DATE,
    account_id INT,
=======
-- Window Functions: Gap Analysis and Data Quality
-- =====================================================

-- PURPOSE: Demonstrate advanced window functions for gap analysis,
--          sequence detection, and data quality assessment
-- LEARNING OUTCOMES: Students will understand how to use window functions for
--                    detecting gaps, missing data, and data quality issues
-- EXPECTED RESULTS:
-- 1. Identification of gaps in sequential data
-- 2. Detection of missing records and data quality issues
-- 3. Analysis of data continuity and completeness
-- 4. Gap filling and data repair strategies
-- DIFFICULTY: ⚫ Expert (30-45 min)
-- CONCEPTS: Gap Detection, Data Quality, Sequence Analysis,
--           Missing Data, Data Repair, Continuity Analysis

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS sensor_readings CASCADE;
DROP TABLE IF EXISTS transaction_log CASCADE;
DROP TABLE IF EXISTS user_sessions CASCADE;
DROP TABLE IF EXISTS inventory_movements CASCADE;

-- Create sensor readings table with intentional gaps
CREATE TABLE sensor_readings (
    reading_id INT PRIMARY KEY,
    sensor_id VARCHAR(20),
    timestamp TIMESTAMP,
    temperature DECIMAL(5,2),
    humidity DECIMAL(5,2)
);

-- Create transaction log table
CREATE TABLE transaction_log (
    transaction_id INT PRIMARY KEY,
    user_id INT,
    transaction_date TIMESTAMP,
>>>>>>> 4e036c9 (feat(quests) improve quest queries)
    amount DECIMAL(10,2),
    transaction_type VARCHAR(20)
);

<<<<<<< HEAD
-- Insert sample data with missing transactions
INSERT INTO financial_transactions VALUES
(1, '2024-01-01', 1001, 1500.00, 'Deposit'),
(2, '2024-01-02', 1001, -500.00, 'Withdrawal'),
(3, '2024-01-04', 1001, 2000.00, 'Deposit'),  -- Gap: missing 2024-01-03
(4, '2024-01-05', 1001, -300.00, 'Withdrawal'),
(5, '2024-01-07', 1001, 1200.00, 'Deposit'),  -- Gap: missing 2024-01-06
(6, '2024-01-08', 1001, -800.00, 'Withdrawal'),
(7, '2024-01-10', 1001, 3000.00, 'Deposit');  -- Gap: missing 2024-01-09

-- Example 4: Financial Data Gap Detection
-- Find missing transaction dates
WITH date_sequence AS (
    SELECT 
        transaction_date,
        LAG(transaction_date) OVER (ORDER BY transaction_date) as prev_date,
        transaction_date - LAG(transaction_date) OVER (ORDER BY transaction_date) as days_diff
    FROM financial_transactions
    WHERE account_id = 1001
)
SELECT 
    prev_date,
    transaction_date,
    days_diff,
    CASE 
        WHEN days_diff > 1 THEN 'Missing days detected'
        ELSE 'Consecutive days'
    END as gap_status,
    days_diff - 1 as missing_days_count
FROM date_sequence
WHERE days_diff > 1
ORDER BY transaction_date;

-- Create employee attendance table
CREATE TABLE employee_attendance (
    id INT PRIMARY KEY,
    employee_id INT,
    work_date DATE,
    hours_worked DECIMAL(4,2)
);

-- Insert sample data with attendance gaps
INSERT INTO employee_attendance VALUES
(1, 1001, '2024-01-01', 8.0),
(2, 1001, '2024-01-02', 8.0),
(3, 1001, '2024-01-03', 0.0),  -- Day off
(4, 1001, '2024-01-04', 8.0),
(5, 1001, '2024-01-05', 8.0),
(6, 1001, '2024-01-08', 8.0),  -- Gap: missing weekend
(7, 1001, '2024-01-09', 8.0),
(8, 1001, '2024-01-10', 0.0),  -- Day off
(9, 1001, '2024-01-11', 8.0),
(10, 1001, '2024-01-12', 8.0),
(11, 1001, '2024-01-15', 8.0); -- Gap: missing weekend

-- Example 5: Attendance Gap Analysis
-- Detect attendance patterns and gaps
WITH attendance_gaps AS (
    SELECT 
        work_date,
        hours_worked,
        LAG(work_date) OVER (ORDER BY work_date) as prev_work_date,
        work_date - LAG(work_date) OVER (ORDER BY work_date) as days_diff
    FROM employee_attendance
    WHERE employee_id = 1001
)
SELECT 
    prev_work_date,
    work_date,
    days_diff,
    CASE 
        WHEN days_diff = 1 THEN 'Consecutive days'
        WHEN days_diff = 2 THEN 'Weekend gap'
        WHEN days_diff = 3 THEN 'Extended gap'
        ELSE 'Large gap'
    END as gap_type,
    CASE 
        WHEN days_diff > 1 THEN 'Gap detected'
        ELSE 'No gap'
    END as gap_status
FROM attendance_gaps
WHERE days_diff > 1
ORDER BY work_date;

-- Create inventory log table
CREATE TABLE inventory_log (
    id INT PRIMARY KEY,
    product_id INT,
    log_date DATE,
    quantity_change INT,
    current_stock INT
);

-- Insert sample data with inventory gaps
INSERT INTO inventory_log VALUES
(1, 2001, '2024-01-01', 100, 100),
(2, 2001, '2024-01-02', -20, 80),
(3, 2001, '2024-01-03', -15, 65),
(4, 2001, '2024-01-05', 50, 115),   -- Gap: missing 2024-01-04
(5, 2001, '2024-01-06', -30, 85),
(6, 2001, '2024-01-08', 75, 160),   -- Gap: missing 2024-01-07
(7, 2001, '2024-01-09', -25, 135),
(8, 2001, '2024-01-10', -40, 95),
(9, 2001, '2024-01-12', 60, 155);   -- Gap: missing 2024-01-11

-- Example 6: Inventory Gap Detection
-- Find missing inventory log entries
WITH inventory_gaps AS (
    SELECT 
        log_date,
        current_stock,
        LAG(log_date) OVER (ORDER BY log_date) as prev_log_date,
        LAG(current_stock) OVER (ORDER BY log_date) as prev_stock,
        log_date - LAG(log_date) OVER (ORDER BY log_date) as days_diff
    FROM inventory_log
    WHERE product_id = 2001
)
SELECT 
    prev_log_date,
    log_date,
    days_diff,
    prev_stock,
    current_stock,
    CASE 
        WHEN days_diff > 1 THEN 'Missing log entries'
        ELSE 'Consecutive logging'
    END as logging_status,
    days_diff - 1 as missing_days
FROM inventory_gaps
WHERE days_diff > 1
ORDER BY log_date;

-- Create network connectivity table
CREATE TABLE network_connectivity (
    id INT PRIMARY KEY,
    check_time TIMESTAMP,
    server_id INT,
    response_time_ms INT,
    status VARCHAR(20)
);

-- Insert sample data with connectivity gaps
INSERT INTO network_connectivity VALUES
(1, '2024-01-01 08:00:00', 3001, 45, 'Online'),
(2, '2024-01-01 08:05:00', 3001, 52, 'Online'),
(3, '2024-01-01 08:10:00', 3001, NULL, 'Offline'),  -- Connectivity issue
(4, '2024-01-01 08:15:00', 3001, NULL, 'Offline'),  -- Still offline
(5, '2024-01-01 08:20:00', 3001, 48, 'Online'),     -- Back online
(6, '2024-01-01 08:25:00', 3001, 51, 'Online'),
(7, '2024-01-01 08:30:00', 3001, NULL, 'Offline'),  -- Another issue
(8, '2024-01-01 08:35:00', 3001, 49, 'Online');     -- Back online

-- Example 7: Network Connectivity Gap Analysis
-- Detect connectivity issues and downtime periods
WITH connectivity_gaps AS (
    SELECT 
        check_time,
        status,
        response_time_ms,
        LAG(check_time) OVER (ORDER BY check_time) as prev_check,
        LAG(status) OVER (ORDER BY check_time) as prev_status,
        EXTRACT(EPOCH FROM (check_time - LAG(check_time) OVER (ORDER BY check_time)))/60 as minutes_diff
    FROM network_connectivity
    WHERE server_id = 3001
)
SELECT 
    prev_check,
    check_time,
    minutes_diff,
    prev_status,
    status,
    CASE 
        WHEN prev_status = 'Online' AND status = 'Offline' THEN 'Connection lost'
        WHEN prev_status = 'Offline' AND status = 'Online' THEN 'Connection restored'
        ELSE 'Status unchanged'
    END as connectivity_event,
    CASE 
        WHEN status = 'Offline' THEN 'Downtime period'
        ELSE 'Uptime period'
    END as period_type
FROM connectivity_gaps
WHERE (prev_status != status) OR status = 'Offline'
ORDER BY check_time;

-- Example 8: Comprehensive Gap Analysis
-- Combine multiple gap detection techniques
WITH comprehensive_gaps AS (
    SELECT 
        'sequence' as data_type,
        sequence_number as identifier,
        sequence_number - LAG(sequence_number) OVER (ORDER BY sequence_number) as gap_size,
        'Sequence gap' as gap_description
    FROM sequence_data
=======
-- Create user sessions table
CREATE TABLE user_sessions (
    session_id INT PRIMARY KEY,
    user_id INT,
    session_start TIMESTAMP,
    session_end TIMESTAMP,
    page_views INT
);

-- Create inventory movements table
CREATE TABLE inventory_movements (
    movement_id INT PRIMARY KEY,
    product_id INT,
    movement_date DATE,
    quantity_change INT,
    movement_type VARCHAR(20)
);

-- Insert sample sensor data with gaps
INSERT INTO sensor_readings VALUES
-- Continuous readings for sensor 1
(1, 'SENSOR_001', '2024-01-01 00:00:00', 22.5, 45.2),
(2, 'SENSOR_001', '2024-01-01 00:15:00', 22.8, 44.8),
(3, 'SENSOR_001', '2024-01-01 00:30:00', 23.1, 44.5),
(4, 'SENSOR_001', '2024-01-01 00:45:00', 22.9, 45.1),
(5, 'SENSOR_001', '2024-01-01 01:00:00', 22.6, 45.8),
-- Gap: missing 01:15 and 01:30 readings
(6, 'SENSOR_001', '2024-01-01 01:45:00', 22.3, 46.2),
(7, 'SENSOR_001', '2024-01-01 02:00:00', 22.7, 45.9),
(8, 'SENSOR_001', '2024-01-01 02:15:00', 23.2, 45.3),
(9, 'SENSOR_001', '2024-01-01 02:30:00', 23.8, 44.7),
(10, 'SENSOR_001', '2024-01-01 02:45:00', 24.1, 44.2),
-- Gap: missing 03:00 reading
(11, 'SENSOR_001', '2024-01-01 03:15:00', 24.5, 43.8),
(12, 'SENSOR_001', '2024-01-01 03:30:00', 24.8, 43.5),
(13, 'SENSOR_001', '2024-01-01 03:45:00', 25.2, 43.1),
(14, 'SENSOR_001', '2024-01-01 04:00:00', 25.5, 42.8),
(15, 'SENSOR_001', '2024-01-01 04:15:00', 25.8, 42.5),

-- Sensor 2 with different gaps
(16, 'SENSOR_002', '2024-01-01 00:00:00', 21.5, 50.2),
(17, 'SENSOR_002', '2024-01-01 00:15:00', 21.8, 49.8),
-- Gap: missing 00:30 reading
(18, 'SENSOR_002', '2024-01-01 00:45:00', 22.1, 49.5),
(19, 'SENSOR_002', '2024-01-01 01:00:00', 21.9, 50.1),
(20, 'SENSOR_002', '2024-01-01 01:15:00', 21.6, 50.8),
(21, 'SENSOR_002', '2024-01-01 01:30:00', 21.3, 51.2),
(22, 'SENSOR_002', '2024-01-01 01:45:00', 21.7, 50.9),
(23, 'SENSOR_002', '2024-01-01 02:00:00', 22.2, 50.3),
(24, 'SENSOR_002', '2024-01-01 02:15:00', 22.8, 49.7),
(25, 'SENSOR_002', '2024-01-01 02:30:00', 23.1, 49.2);

-- Insert sample transaction log with gaps
INSERT INTO transaction_log VALUES
-- User 101 transactions
(1, 101, '2024-01-01 09:00:00', 150.00, 'Purchase'),
(2, 101, '2024-01-01 10:15:00', 75.50, 'Purchase'),
(3, 101, '2024-01-01 11:30:00', 200.00, 'Purchase'),
-- Gap: no transactions for 2 hours
(4, 101, '2024-01-01 14:45:00', 120.00, 'Purchase'),
(5, 101, '2024-01-01 16:00:00', 85.25, 'Purchase'),
(6, 101, '2024-01-01 17:30:00', 300.00, 'Purchase'),

-- User 102 transactions
(7, 102, '2024-01-01 08:30:00', 250.00, 'Purchase'),
(8, 102, '2024-01-01 09:45:00', 180.00, 'Purchase'),
(9, 102, '2024-01-01 11:00:00', 95.75, 'Purchase'),
(10, 102, '2024-01-01 12:15:00', 320.00, 'Purchase'),
-- Gap: no transactions for 3 hours
(11, 102, '2024-01-01 16:30:00', 150.00, 'Purchase'),
(12, 102, '2024-01-01 18:00:00', 275.50, 'Purchase');

-- Insert sample user sessions with gaps
INSERT INTO user_sessions VALUES
-- User 201 sessions
(1, 201, '2024-01-01 08:00:00', '2024-01-01 08:45:00', 5),
(2, 201, '2024-01-01 09:30:00', '2024-01-01 10:15:00', 8),
-- Gap: no session for 1 hour
(3, 201, '2024-01-01 11:30:00', '2024-01-01 12:00:00', 3),
(4, 201, '2024-01-01 13:00:00', '2024-01-01 13:45:00', 6),
(5, 201, '2024-01-01 14:30:00', '2024-01-01 15:15:00', 10),

-- User 202 sessions
(6, 202, '2024-01-01 07:30:00', '2024-01-01 08:15:00', 4),
(7, 202, '2024-01-01 09:00:00', '2024-01-01 09:30:00', 2),
(8, 202, '2024-01-01 10:15:00', '2024-01-01 11:00:00', 7),
-- Gap: no session for 2 hours
(9, 202, '2024-01-01 13:30:00', '2024-01-01 14:15:00', 5),
(10, 202, '2024-01-01 15:00:00', '2024-01-01 15:45:00', 9);

-- Insert sample inventory movements with gaps
INSERT INTO inventory_movements VALUES
-- Product 301 movements
(1, 301, '2024-01-01', 100, 'Stock In'),
(2, 301, '2024-01-02', -25, 'Sale'),
(3, 301, '2024-01-03', -30, 'Sale'),
(4, 301, '2024-01-04', -20, 'Sale'),
-- Gap: no movement for 2 days
(5, 301, '2024-01-07', 50, 'Stock In'),
(6, 301, '2024-01-08', -15, 'Sale'),
(7, 301, '2024-01-09', -10, 'Sale'),

-- Product 302 movements
(8, 302, '2024-01-01', 200, 'Stock In'),
(9, 302, '2024-01-02', -50, 'Sale'),
(10, 302, '2024-01-03', -40, 'Sale'),
-- Gap: no movement for 3 days
(11, 302, '2024-01-07', 75, 'Stock In'),
(12, 302, '2024-01-08', -25, 'Sale'),
(13, 302, '2024-01-09', -30, 'Sale'),
(14, 302, '2024-01-10', -20, 'Sale');

-- =====================================================
-- Example 1: Time Series Gap Detection
-- =====================================================

-- Detect gaps in sensor readings
WITH sensor_gaps AS (
    SELECT 
        sensor_id,
        timestamp,
        temperature,
        humidity,
        -- Previous timestamp
        LAG(timestamp) OVER (PARTITION BY sensor_id ORDER BY timestamp) as prev_timestamp,
        -- Expected next timestamp (15 minutes later)
        timestamp + INTERVAL '15 minutes' as expected_next,
        -- Next actual timestamp
        LEAD(timestamp) OVER (PARTITION BY sensor_id ORDER BY timestamp) as next_timestamp,
        -- Gap size in minutes
        EXTRACT(EPOCH FROM (
            LEAD(timestamp) OVER (PARTITION BY sensor_id ORDER BY timestamp) - timestamp
        )) / 60 as gap_minutes
    FROM sensor_readings
)
SELECT 
    sensor_id,
    timestamp,
    temperature,
    humidity,
    prev_timestamp,
    expected_next,
    next_timestamp,
    gap_minutes,
    -- Gap classification
    CASE 
        WHEN gap_minutes > 30 THEN 'Large Gap'
        WHEN gap_minutes > 15 THEN 'Medium Gap'
        WHEN gap_minutes > 0 THEN 'Small Gap'
        ELSE 'No Gap'
    END as gap_type,
    -- Missing readings count
    CASE 
        WHEN gap_minutes > 0 THEN FLOOR(gap_minutes / 15) - 1
        ELSE 0
    END as missing_readings
FROM sensor_gaps
WHERE gap_minutes > 15  -- Only show actual gaps
ORDER BY sensor_id, timestamp;

-- =====================================================
-- Example 2: Transaction Pattern Gap Analysis
-- =====================================================

-- Analyze gaps in user transaction patterns
WITH transaction_gaps AS (
    SELECT 
        user_id,
        transaction_date,
        amount,
        transaction_type,
        -- Previous transaction time
        LAG(transaction_date) OVER (PARTITION BY user_id ORDER BY transaction_date) as prev_transaction,
        -- Next transaction time
        LEAD(transaction_date) OVER (PARTITION BY user_id ORDER BY transaction_date) as next_transaction,
        -- Time gap in hours
        EXTRACT(EPOCH FROM (
            transaction_date - LAG(transaction_date) OVER (PARTITION BY user_id ORDER BY transaction_date)
        )) / 3600 as hours_since_prev,
        -- Time gap to next transaction
        EXTRACT(EPOCH FROM (
            LEAD(transaction_date) OVER (PARTITION BY user_id ORDER BY transaction_date) - transaction_date
        )) / 3600 as hours_to_next
    FROM transaction_log
)
SELECT 
    user_id,
    transaction_date,
    amount,
    transaction_type,
    prev_transaction,
    next_transaction,
    ROUND(hours_since_prev, 2) as hours_since_prev,
    ROUND(hours_to_next, 2) as hours_to_next,
    -- Gap analysis
    CASE 
        WHEN hours_since_prev > 4 THEN 'Long Gap Before'
        WHEN hours_since_prev > 2 THEN 'Medium Gap Before'
        WHEN hours_since_prev > 1 THEN 'Short Gap Before'
        ELSE 'Normal Interval'
    END as gap_before,
    CASE 
        WHEN hours_to_next > 4 THEN 'Long Gap After'
        WHEN hours_to_next > 2 THEN 'Medium Gap After'
        WHEN hours_to_next > 1 THEN 'Short Gap After'
        ELSE 'Normal Interval'
    END as gap_after,
    -- Activity pattern
    CASE 
        WHEN hours_since_prev > 3 AND hours_to_next > 3 THEN 'Isolated Transaction'
        WHEN hours_since_prev > 2 OR hours_to_next > 2 THEN 'Sparse Activity'
        ELSE 'Regular Activity'
    END as activity_pattern
FROM transaction_gaps
ORDER BY user_id, transaction_date;

-- =====================================================
-- Example 3: Session Continuity Analysis
-- =====================================================

-- Analyze gaps in user session patterns
WITH session_gaps AS (
    SELECT 
        user_id,
        session_start,
        session_end,
        page_views,
        -- Previous session end
        LAG(session_end) OVER (PARTITION BY user_id ORDER BY session_start) as prev_session_end,
        -- Next session start
        LEAD(session_start) OVER (PARTITION BY user_id ORDER BY session_start) as next_session_start,
        -- Gap before session
        EXTRACT(EPOCH FROM (
            session_start - LAG(session_end) OVER (PARTITION BY user_id ORDER BY session_start)
        )) / 60 as gap_before_minutes,
        -- Gap after session
        EXTRACT(EPOCH FROM (
            LEAD(session_start) OVER (PARTITION BY user_id ORDER BY session_start) - session_end
        )) / 60 as gap_after_minutes,
        -- Session duration
        EXTRACT(EPOCH FROM (session_end - session_start)) / 60 as session_duration_minutes
    FROM user_sessions
)
SELECT 
    user_id,
    session_start,
    session_end,
    page_views,
    prev_session_end,
    next_session_start,
    ROUND(gap_before_minutes, 2) as gap_before_minutes,
    ROUND(gap_after_minutes, 2) as gap_after_minutes,
    ROUND(session_duration_minutes, 2) as session_duration_minutes,
    -- Gap analysis
    CASE 
        WHEN gap_before_minutes > 120 THEN 'Long Break Before'
        WHEN gap_before_minutes > 60 THEN 'Medium Break Before'
        WHEN gap_before_minutes > 30 THEN 'Short Break Before'
        ELSE 'Continuous Activity'
    END as break_before,
    CASE 
        WHEN gap_after_minutes > 120 THEN 'Long Break After'
        WHEN gap_after_minutes > 60 THEN 'Medium Break After'
        WHEN gap_after_minutes > 30 THEN 'Short Break After'
        ELSE 'Continuous Activity'
    END as break_after,
    -- User engagement pattern
    CASE 
        WHEN gap_before_minutes < 30 AND gap_after_minutes < 30 THEN 'Highly Engaged'
        WHEN gap_before_minutes < 60 AND gap_after_minutes < 60 THEN 'Moderately Engaged'
        WHEN gap_before_minutes > 120 OR gap_after_minutes > 120 THEN 'Occasional User'
        ELSE 'Regular User'
    END as engagement_level
FROM session_gaps
ORDER BY user_id, session_start;

-- =====================================================
-- Example 4: Inventory Movement Gap Detection
-- =====================================================

-- Detect gaps in inventory movement patterns
WITH inventory_gaps AS (
    SELECT 
        product_id,
        movement_date,
        quantity_change,
        movement_type,
        -- Previous movement date
        LAG(movement_date) OVER (PARTITION BY product_id ORDER BY movement_date) as prev_movement_date,
        -- Next movement date
        LEAD(movement_date) OVER (PARTITION BY product_id ORDER BY movement_date) as next_movement_date,
        -- Days since last movement
        movement_date - LAG(movement_date) OVER (PARTITION BY product_id ORDER BY movement_date) as days_since_prev,
        -- Days until next movement
        LEAD(movement_date) OVER (PARTITION BY product_id ORDER BY movement_date) - movement_date as days_until_next,
        -- Running inventory level
        SUM(quantity_change) OVER (
            PARTITION BY product_id 
            ORDER BY movement_date 
            ROWS UNBOUNDED PRECEDING
        ) as running_inventory
    FROM inventory_movements
)
SELECT 
    product_id,
    movement_date,
    quantity_change,
    movement_type,
    prev_movement_date,
    next_movement_date,
    days_since_prev,
    days_until_next,
    running_inventory,
    -- Gap analysis
    CASE 
        WHEN days_since_prev > 5 THEN 'Long Gap Before'
        WHEN days_since_prev > 3 THEN 'Medium Gap Before'
        WHEN days_since_prev > 1 THEN 'Short Gap Before'
        ELSE 'Daily Activity'
    END as gap_before,
    CASE 
        WHEN days_until_next > 5 THEN 'Long Gap After'
        WHEN days_until_next > 3 THEN 'Medium Gap After'
        WHEN days_until_next > 1 THEN 'Short Gap After'
        ELSE 'Daily Activity'
    END as gap_after,
    -- Inventory activity pattern
    CASE 
        WHEN days_since_prev > 3 AND days_until_next > 3 THEN 'Low Activity Product'
        WHEN days_since_prev <= 1 AND days_until_next <= 1 THEN 'High Activity Product'
        WHEN days_since_prev <= 2 AND days_until_next <= 2 THEN 'Regular Activity Product'
        ELSE 'Moderate Activity Product'
    END as activity_pattern
FROM inventory_gaps
ORDER BY product_id, movement_date;

-- =====================================================
-- Example 5: Data Quality Assessment
-- =====================================================

-- Assess data quality using gap analysis
WITH data_quality AS (
    SELECT 
        'sensor_readings' as table_name,
        sensor_id as entity_id,
        COUNT(*) as total_records,
        COUNT(DISTINCT DATE_TRUNC('hour', timestamp)) as active_hours,
        -- Expected records (assuming 15-minute intervals)
        COUNT(DISTINCT DATE_TRUNC('hour', timestamp)) * 4 as expected_records,
        -- Missing records
        (COUNT(DISTINCT DATE_TRUNC('hour', timestamp)) * 4) - COUNT(*) as missing_records,
        -- Data completeness percentage
        ROUND(
            COUNT(*) * 100.0 / NULLIF(COUNT(DISTINCT DATE_TRUNC('hour', timestamp)) * 4, 0), 2
        ) as completeness_pct
    FROM sensor_readings
    GROUP BY sensor_id
>>>>>>> 4e036c9 (feat(quests) improve quest queries)
    
    UNION ALL
    
    SELECT 
<<<<<<< HEAD
        'time_series' as data_type,
        EXTRACT(EPOCH FROM timestamp)::INT as identifier,
        EXTRACT(EPOCH FROM (timestamp - LAG(timestamp) OVER (ORDER BY timestamp))) as gap_size,
        'Time series gap' as gap_description
    FROM time_series_data
    WHERE timestamp - LAG(timestamp) OVER (ORDER BY timestamp) > INTERVAL '15 minutes'
    
    UNION ALL
    
    SELECT 
        'financial' as data_type,
        EXTRACT(EPOCH FROM transaction_date)::INT as identifier,
        (transaction_date - LAG(transaction_date) OVER (ORDER BY transaction_date))::INT as gap_size,
        'Financial data gap' as gap_description
    FROM financial_transactions
    WHERE transaction_date - LAG(transaction_date) OVER (ORDER BY transaction_date) > 1
)
SELECT 
    data_type,
    identifier,
    gap_size,
    gap_description,
    CASE 
        WHEN gap_size <= 1 THEN 'Minor gap'
        WHEN gap_size <= 3 THEN 'Moderate gap'
        WHEN gap_size <= 7 THEN 'Significant gap'
        ELSE 'Critical gap'
    END as gap_severity
FROM comprehensive_gaps
ORDER BY data_type, identifier;

-- Clean up
DROP TABLE IF EXISTS sequence_data CASCADE;
DROP TABLE IF EXISTS time_series_data CASCADE;
DROP TABLE IF EXISTS sensor_readings CASCADE;
DROP TABLE IF EXISTS financial_transactions CASCADE;
DROP TABLE IF EXISTS employee_attendance CASCADE;
DROP TABLE IF EXISTS inventory_log CASCADE;
DROP TABLE IF EXISTS network_connectivity CASCADE; 
=======
        'transaction_log' as table_name,
        user_id::VARCHAR as entity_id,
        COUNT(*) as total_records,
        COUNT(DISTINCT DATE_TRUNC('hour', transaction_date)) as active_hours,
        -- Expected records (assuming hourly activity)
        COUNT(DISTINCT DATE_TRUNC('hour', transaction_date)) as expected_records,
        -- Missing records (simplified expectation)
        0 as missing_records,
        -- Data completeness percentage
        100.0 as completeness_pct
    FROM transaction_log
    GROUP BY user_id
)
SELECT 
    table_name,
    entity_id,
    total_records,
    active_hours,
    expected_records,
    missing_records,
    completeness_pct,
    -- Data quality classification
    CASE 
        WHEN completeness_pct >= 95 THEN 'Excellent'
        WHEN completeness_pct >= 90 THEN 'Good'
        WHEN completeness_pct >= 80 THEN 'Fair'
        WHEN completeness_pct >= 70 THEN 'Poor'
        ELSE 'Very Poor'
    END as data_quality,
    -- Action required
    CASE 
        WHEN completeness_pct < 80 THEN 'Data Repair Required'
        WHEN completeness_pct < 90 THEN 'Monitor Closely'
        WHEN completeness_pct < 95 THEN 'Minor Issues'
        ELSE 'No Action Required'
    END as action_required
FROM data_quality
ORDER BY table_name, entity_id;

-- =====================================================
-- Example 6: Gap Filling Strategies
-- =====================================================

-- Demonstrate gap filling using window functions
WITH sensor_gaps_filled AS (
    SELECT 
        sensor_id,
        timestamp,
        temperature,
        humidity,
        -- Forward fill (use previous value)
        FIRST_VALUE(temperature) OVER (
            PARTITION BY sensor_id 
            ORDER BY timestamp 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) as temperature_forward_fill,
        FIRST_VALUE(humidity) OVER (
            PARTITION BY sensor_id 
            ORDER BY timestamp 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) as humidity_forward_fill,
        -- Backward fill (use next value)
        LAST_VALUE(temperature) OVER (
            PARTITION BY sensor_id 
            ORDER BY timestamp 
            ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
        ) as temperature_backward_fill,
        LAST_VALUE(humidity) OVER (
            PARTITION BY sensor_id 
            ORDER BY timestamp 
            ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
        ) as humidity_backward_fill,
        -- Linear interpolation (average of surrounding values)
        AVG(temperature) OVER (
            PARTITION BY sensor_id 
            ORDER BY timestamp 
            ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
        ) as temperature_interpolated,
        AVG(humidity) OVER (
            PARTITION BY sensor_id 
            ORDER BY timestamp 
            ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
        ) as humidity_interpolated
    FROM sensor_readings
)
SELECT 
    sensor_id,
    timestamp,
    temperature,
    humidity,
    ROUND(temperature_forward_fill, 2) as temp_forward_fill,
    ROUND(humidity_forward_fill, 2) as humidity_forward_fill,
    ROUND(temperature_backward_fill, 2) as temp_backward_fill,
    ROUND(humidity_backward_fill, 2) as humidity_backward_fill,
    ROUND(temperature_interpolated, 2) as temp_interpolated,
    ROUND(humidity_interpolated, 2) as humidity_interpolated,
    -- Gap filling recommendation
    CASE 
        WHEN temperature IS NOT NULL THEN 'Original Data'
        WHEN temperature_forward_fill IS NOT NULL AND temperature_backward_fill IS NOT NULL THEN 'Use Interpolation'
        WHEN temperature_forward_fill IS NOT NULL THEN 'Use Forward Fill'
        WHEN temperature_backward_fill IS NOT NULL THEN 'Use Backward Fill'
        ELSE 'No Fill Available'
    END as fill_strategy
FROM sensor_gaps_filled
ORDER BY sensor_id, timestamp;

-- =====================================================
-- Example 7: Sequence Continuity Analysis
-- =====================================================

-- Analyze sequence continuity and identify breaks
WITH sequence_analysis AS (
    SELECT 
        sensor_id,
        timestamp,
        temperature,
        humidity,
        -- Row number for sequence analysis
        ROW_NUMBER() OVER (PARTITION BY sensor_id ORDER BY timestamp) as row_seq,
        -- Expected timestamp based on sequence
        MIN(timestamp) OVER (PARTITION BY sensor_id) + 
        (ROW_NUMBER() OVER (PARTITION BY sensor_id ORDER BY timestamp) - 1) * INTERVAL '15 minutes' as expected_timestamp,
        -- Sequence gap
        EXTRACT(EPOCH FROM (
            timestamp - (MIN(timestamp) OVER (PARTITION BY sensor_id) + 
            (ROW_NUMBER() OVER (PARTITION BY sensor_id ORDER BY timestamp) - 1) * INTERVAL '15 minutes')
        )) / 60 as sequence_gap_minutes
    FROM sensor_readings
)
SELECT 
    sensor_id,
    timestamp,
    temperature,
    humidity,
    row_seq,
    expected_timestamp,
    ROUND(sequence_gap_minutes, 2) as sequence_gap_minutes,
    -- Sequence continuity
    CASE 
        WHEN sequence_gap_minutes = 0 THEN 'Perfect Sequence'
        WHEN ABS(sequence_gap_minutes) <= 1 THEN 'Minor Deviation'
        WHEN ABS(sequence_gap_minutes) <= 5 THEN 'Moderate Deviation'
        WHEN ABS(sequence_gap_minutes) <= 15 THEN 'Major Deviation'
        ELSE 'Sequence Break'
    END as sequence_status,
    -- Data integrity assessment
    CASE 
        WHEN sequence_gap_minutes > 15 THEN 'Data Integrity Issue'
        WHEN sequence_gap_minutes > 5 THEN 'Potential Issue'
        WHEN sequence_gap_minutes > 1 THEN 'Minor Issue'
        ELSE 'No Issues'
    END as integrity_assessment
FROM sequence_analysis
ORDER BY sensor_id, timestamp;

-- =====================================================
-- Example 8: Comprehensive Gap Report
-- =====================================================

-- Generate comprehensive gap analysis report
WITH gap_summary AS (
    SELECT 
        'sensor_readings' as data_source,
        sensor_id as entity,
        COUNT(*) as total_records,
        COUNT(DISTINCT DATE_TRUNC('hour', timestamp)) as active_hours,
        MIN(timestamp) as first_record,
        MAX(timestamp) as last_record,
        -- Gap statistics
        COUNT(CASE 
            WHEN EXTRACT(EPOCH FROM (
                LEAD(timestamp) OVER (PARTITION BY sensor_id ORDER BY timestamp) - timestamp
            )) / 60 > 15 THEN 1 
        END) as gap_count,
        AVG(CASE 
            WHEN EXTRACT(EPOCH FROM (
                LEAD(timestamp) OVER (PARTITION BY sensor_id ORDER BY timestamp) - timestamp
            )) / 60 > 15 THEN 
                EXTRACT(EPOCH FROM (
                    LEAD(timestamp) OVER (PARTITION BY sensor_id ORDER BY timestamp) - timestamp
                )) / 60 
        END) as avg_gap_minutes,
        MAX(CASE 
            WHEN EXTRACT(EPOCH FROM (
                LEAD(timestamp) OVER (PARTITION BY sensor_id ORDER BY timestamp) - timestamp
            )) / 60 > 15 THEN 
                EXTRACT(EPOCH FROM (
                    LEAD(timestamp) OVER (PARTITION BY sensor_id ORDER BY timestamp) - timestamp
                )) / 60 
        END) as max_gap_minutes
    FROM sensor_readings
    GROUP BY sensor_id
)
SELECT 
    data_source,
    entity,
    total_records,
    active_hours,
    first_record,
    last_record,
    gap_count,
    ROUND(avg_gap_minutes, 2) as avg_gap_minutes,
    ROUND(max_gap_minutes, 2) as max_gap_minutes,
    -- Data quality score
    CASE 
        WHEN gap_count = 0 THEN 100
        WHEN gap_count <= 2 THEN 90
        WHEN gap_count <= 5 THEN 80
        WHEN gap_count <= 10 THEN 70
        ELSE 60
    END as quality_score,
    -- Recommendations
    CASE 
        WHEN gap_count = 0 THEN 'Excellent - No gaps detected'
        WHEN gap_count <= 2 THEN 'Good - Minor gaps, monitor'
        WHEN gap_count <= 5 THEN 'Fair - Some gaps, consider repair'
        WHEN gap_count <= 10 THEN 'Poor - Multiple gaps, repair needed'
        ELSE 'Very Poor - Extensive gaps, immediate attention required'
    END as recommendation
FROM gap_summary
ORDER BY quality_score DESC, entity;

-- Clean up
DROP TABLE IF EXISTS sensor_readings CASCADE;
DROP TABLE IF EXISTS transaction_log CASCADE;
DROP TABLE IF EXISTS user_sessions CASCADE;
DROP TABLE IF EXISTS inventory_movements CASCADE; 
>>>>>>> 4e036c9 (feat(quests) improve quest queries)
