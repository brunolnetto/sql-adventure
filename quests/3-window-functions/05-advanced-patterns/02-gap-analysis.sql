-- =====================================================
-- Window Functions quest: Gap Analysis and Sequence Detection
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
        LAG(sequence_number) OVER (ORDER BY sequence_number) AS prev_sequence,
        sequence_number
        - LAG(sequence_number) OVER (ORDER BY sequence_number) AS gap_size
    FROM sequence_data
)

SELECT
    prev_sequence,
    sequence_number,
    gap_size,
    CASE
        WHEN gap_size > 1 THEN 'Gap detected'
        ELSE 'No gap'
    END AS gap_status
FROM sequence_gaps
WHERE gap_size > 1 OR gap_size IS NULL
ORDER BY sequence_number;

-- Create time series data table
CREATE TABLE time_series_data (
    id INT PRIMARY KEY,
    timestamp TIMESTAMP,
    value DECIMAL(10, 2),
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
        LAG(timestamp) OVER (ORDER BY timestamp) AS prev_timestamp,
        EXTRACT(
            EPOCH FROM (timestamp - LAG(timestamp) OVER (ORDER BY timestamp))
        )
        / 60 AS minutes_diff
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
    END AS gap_type,
    ROUND(minutes_diff / 15, 1) AS expected_intervals_missing
FROM time_gaps
WHERE minutes_diff > 15
ORDER BY timestamp;

-- Create sensor readings table
CREATE TABLE sensor_readings (
    id INT PRIMARY KEY,
    sensor_id INT,
    reading_time TIMESTAMP,
    temperature DECIMAL(5, 2),
    humidity DECIMAL(5, 2),
    pressure DECIMAL(8, 2)
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
        WHEN
            temperature IS NULL AND humidity IS NULL AND pressure IS NULL
            THEN 'Complete data loss'
        WHEN
            temperature IS NULL OR humidity IS NULL OR pressure IS NULL
            THEN 'Partial data loss'
        ELSE 'Data complete'
    END AS data_quality_status,
    CASE
        WHEN temperature IS NULL THEN 'Temperature missing'
        WHEN humidity IS NULL THEN 'Humidity missing'
        WHEN pressure IS NULL THEN 'Pressure missing'
        ELSE 'All values present'
    END AS missing_values
FROM sensor_readings
WHERE temperature IS NULL OR humidity IS NULL OR pressure IS NULL
ORDER BY reading_time;

-- Create financial transactions table
CREATE TABLE financial_transactions (
    id INT PRIMARY KEY,
    transaction_date DATE,
    account_id INT,
    amount DECIMAL(10, 2),
    transaction_type VARCHAR(20)
);

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
        LAG(transaction_date) OVER (ORDER BY transaction_date) AS prev_date,
        transaction_date
        - LAG(transaction_date) OVER (ORDER BY transaction_date) AS days_diff
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
    END AS gap_status,
    days_diff - 1 AS missing_days_count
FROM date_sequence
WHERE days_diff > 1
ORDER BY transaction_date;

-- Create employee attendance table
CREATE TABLE employee_attendance (
    id INT PRIMARY KEY,
    employee_id INT,
    work_date DATE,
    hours_worked DECIMAL(4, 2)
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
        LAG(work_date) OVER (ORDER BY work_date) AS prev_work_date,
        work_date - LAG(work_date) OVER (ORDER BY work_date) AS days_diff
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
    END AS gap_type,
    CASE
        WHEN days_diff > 1 THEN 'Gap detected'
        ELSE 'No gap'
    END AS gap_status
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
        LAG(log_date) OVER (ORDER BY log_date) AS prev_log_date,
        LAG(current_stock) OVER (ORDER BY log_date) AS prev_stock,
        log_date - LAG(log_date) OVER (ORDER BY log_date) AS days_diff
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
    END AS logging_status,
    days_diff - 1 AS missing_days
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
        LAG(check_time) OVER (ORDER BY check_time) AS prev_check,
        LAG(status) OVER (ORDER BY check_time) AS prev_status,
        EXTRACT(
            EPOCH FROM (check_time - LAG(check_time) OVER (ORDER BY check_time))
        )
        / 60 AS minutes_diff
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
        WHEN
            prev_status = 'Online' AND status = 'Offline'
            THEN 'Connection lost'
        WHEN
            prev_status = 'Offline' AND status = 'Online'
            THEN 'Connection restored'
        ELSE 'Status unchanged'
    END AS connectivity_event,
    CASE
        WHEN status = 'Offline' THEN 'Downtime period'
        ELSE 'Uptime period'
    END AS period_type
FROM connectivity_gaps
WHERE (prev_status != status) OR status = 'Offline'
ORDER BY check_time;

-- Example 8: Comprehensive Gap Analysis
-- Combine multiple gap detection techniques
WITH comprehensive_gaps AS (
    SELECT
        'sequence' AS data_type,
        sequence_number AS identifier,
        sequence_number
        - LAG(sequence_number) OVER (ORDER BY sequence_number) AS gap_size,
        'Sequence gap' AS gap_description
    FROM sequence_data

    UNION ALL

    SELECT * FROM (
        SELECT
            'time_series' AS data_type,
            EXTRACT(EPOCH FROM timestamp)::INT AS identifier,
            EXTRACT(
                EPOCH FROM (timestamp - LAG(timestamp) OVER (ORDER BY timestamp))
            ) AS gap_size,
            'Time series gap' AS gap_description
        FROM time_series_data
    ) ts
    WHERE ts.gap_size > 15 * 60  -- 15 minutes in seconds

    UNION ALL

    SELECT * FROM (
        SELECT
            'financial' AS data_type,
            EXTRACT(EPOCH FROM transaction_date)::INT AS identifier,
            (
                transaction_date
                - LAG(transaction_date) OVER (ORDER BY transaction_date)
            )::INT AS gap_size,
            'Financial data gap' AS gap_description
        FROM financial_transactions
    ) ft
    WHERE ft.gap_size > 1
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
    END AS gap_severity
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
