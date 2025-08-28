-- =====================================================
-- Performance Tuning Quest: Performance Monitoring
-- =====================================================
-- 
-- PURPOSE: Demonstrate expert-level performance monitoring techniques
-- DIFFICULTY: ⚫ Expert (30-45 min)
-- CONCEPTS: Performance monitoring, query analysis, system statistics, optimization

-- Example 1: Comprehensive Performance Monitoring
-- Demonstrate monitoring database performance at multiple levels

-- Create monitoring tables
CREATE TABLE performance_logs (
    log_id BIGSERIAL PRIMARY KEY,
    query_text TEXT,
    execution_time_ms DECIMAL(10, 2),
    rows_returned INT,
    rows_scanned INT,
    cpu_time_ms DECIMAL(10, 2),
    io_time_ms DECIMAL(10, 2),
    memory_usage_mb DECIMAL(10, 2),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_id VARCHAR(50),
    user_name VARCHAR(50)
);

CREATE TABLE slow_queries (
    query_id BIGSERIAL PRIMARY KEY,
    query_hash VARCHAR(64),
    query_text TEXT,
    avg_execution_time_ms DECIMAL(10, 2),
    max_execution_time_ms DECIMAL(10, 2),
    execution_count INT,
    total_rows_returned BIGINT,
    first_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Example 2: Query Performance Analysis
-- Demonstrate analyzing query performance in detail

-- Insert sample performance data for demonstration
INSERT INTO performance_logs (query_text, execution_time_ms, rows_returned, rows_scanned, cpu_time_ms, io_time_ms, memory_usage_mb, session_id, user_name) VALUES
('SELECT * FROM users WHERE status = ?', 125.50, 1000, 50000, 80.25, 35.75, 256.5, 'sess_001', 'user1'),
('SELECT COUNT(*) FROM orders GROUP BY customer_id', 89.25, 500, 25000, 45.10, 22.15, 128.0, 'sess_002', 'user2'),
('INSERT INTO products (name, price) VALUES (?, ?)', 15.75, 1, 5, 8.50, 2.25, 64.0, 'sess_001', 'user1'),
('SELECT * FROM products WHERE price > ? ORDER BY price DESC', 234.80, 250, 100000, 156.40, 78.40, 512.0, 'sess_003', 'user3'),
('UPDATE inventory SET quantity = quantity - ? WHERE product_id = ?', 67.90, 1, 100, 34.25, 15.65, 96.0, 'sess_002', 'user2');

-- Analyze query performance patterns
SELECT
    CASE
        WHEN execution_time_ms < 10 THEN 'Very Fast (< 10ms)'
        WHEN execution_time_ms < 50 THEN 'Fast (10-50ms)'
        WHEN execution_time_ms < 200 THEN 'Moderate (50-200ms)'
        WHEN execution_time_ms < 1000 THEN 'Slow (200ms-1s)'
        ELSE 'Very Slow (> 1s)'
    END AS performance_category,
    COUNT(*) AS query_count,
    ROUND(AVG(execution_time_ms), 2) AS avg_execution_time,
    ROUND(AVG(rows_returned * 1.0 / NULLIF(rows_scanned, 0)) * 100, 2) AS avg_selectivity_percent,
    ROUND(AVG(memory_usage_mb), 2) AS avg_memory_mb
FROM performance_logs
GROUP BY
    CASE
        WHEN execution_time_ms < 10 THEN 'Very Fast (< 10ms)'
        WHEN execution_time_ms < 50 THEN 'Fast (10-50ms)'
        WHEN execution_time_ms < 200 THEN 'Moderate (50-200ms)'
        WHEN execution_time_ms < 1000 THEN 'Slow (200ms-1s)'
        ELSE 'Very Slow (> 1s)'
    END
ORDER BY avg_execution_time DESC;

-- Identify most expensive queries by resource usage
SELECT
    LEFT(query_text, 50) || '...' AS query_preview,
    execution_time_ms,
    memory_usage_mb,
    cpu_time_ms,
    io_time_ms,
    rows_scanned,
    user_name,
    timestamp
FROM performance_logs
ORDER BY execution_time_ms DESC
LIMIT 5;

-- Example 3: System Performance Monitoring
-- Demonstrate monitoring system-level performance

-- Create system performance view
CREATE VIEW v_system_performance AS
SELECT
    'Database Size' AS metric,
    PG_SIZE_PRETTY(PG_DATABASE_SIZE(CURRENT_DATABASE())) AS value
UNION ALL
SELECT
    'Active Connections',
    COUNT(*)::TEXT
FROM pg_stat_activity
WHERE state = 'active'
UNION ALL
SELECT
    'Idle Connections',
    COUNT(*)::TEXT
FROM pg_stat_activity
WHERE state = 'idle'
UNION ALL
SELECT
    'Cache Hit Ratio',
    ROUND(
        (
            SUM(heap_blks_hit)
            * 100.0
            / (SUM(heap_blks_hit) + SUM(heap_blks_read))
        ),
        2
    )::TEXT || '%'
FROM pg_statio_user_tables
UNION ALL
SELECT
    'Index Cache Hit Ratio',
    ROUND(
        (SUM(idx_blks_hit) * 100.0 / (SUM(idx_blks_hit) + SUM(idx_blks_read))),
        2
    )::TEXT || '%'
FROM pg_statio_user_indexes;

-- Example 4: Table and Index Performance Analysis
-- Demonstrate analyzing table and index performance

-- Analyze performance logs to identify table access patterns
SELECT
    CASE
        WHEN query_text ILIKE '%users%' THEN 'users'
        WHEN query_text ILIKE '%orders%' THEN 'orders'
        WHEN query_text ILIKE '%products%' THEN 'products'
        WHEN query_text ILIKE '%inventory%' THEN 'inventory'
        ELSE 'other'
    END AS table_name,
    COUNT(*) AS query_count,
    ROUND(AVG(execution_time_ms), 2) AS avg_execution_time,
    ROUND(AVG(rows_returned), 2) AS avg_rows_returned,
    ROUND(AVG(rows_scanned), 2) AS avg_rows_scanned,
    ROUND(AVG(rows_scanned * 1.0 / NULLIF(rows_returned, 0)), 2) AS avg_scan_efficiency
FROM performance_logs
GROUP BY
    CASE
        WHEN query_text ILIKE '%users%' THEN 'users'
        WHEN query_text ILIKE '%orders%' THEN 'orders'
        WHEN query_text ILIKE '%products%' THEN 'products'
        WHEN query_text ILIKE '%inventory%' THEN 'inventory'
        ELSE 'other'
    END
HAVING COUNT(*) > 0
ORDER BY query_count DESC;

-- Analyze user behavior patterns
SELECT
    user_name,
    COUNT(*) AS total_queries,
    COUNT(DISTINCT session_id) AS sessions_used,
    ROUND(AVG(execution_time_ms), 2) AS avg_query_time,
    ROUND(SUM(execution_time_ms), 2) AS total_time_spent,
    MAX(timestamp) AS last_activity,
    MIN(timestamp) AS first_activity
FROM performance_logs
GROUP BY user_name
ORDER BY total_queries DESC;

-- Example 5: Performance Reporting
-- Demonstrate generating performance reports

-- Generate comprehensive performance summary report
WITH performance_summary AS (
    SELECT
        COUNT(*) AS total_queries,
        ROUND(AVG(execution_time_ms), 2) AS avg_execution_time,
        MIN(execution_time_ms) AS min_execution_time,
        MAX(execution_time_ms) AS max_execution_time,
        ROUND(AVG(rows_returned), 2) AS avg_rows_returned,
        ROUND(AVG(memory_usage_mb), 2) AS avg_memory_usage,
        COUNT(DISTINCT user_name) AS unique_users,
        COUNT(DISTINCT session_id) AS unique_sessions
    FROM performance_logs
),
performance_trends AS (
    SELECT
        DATE_TRUNC('hour', timestamp) AS hour,
        COUNT(*) AS queries_per_hour,
        ROUND(AVG(execution_time_ms), 2) AS avg_time_per_hour
    FROM performance_logs
    GROUP BY DATE_TRUNC('hour', timestamp)
    ORDER BY hour DESC
    LIMIT 5
)
SELECT
    '=== PERFORMANCE SUMMARY REPORT ===' AS report_section,
    CURRENT_TIMESTAMP AS report_generated_at,
    ps.total_queries,
    ps.avg_execution_time,
    ps.min_execution_time,
    ps.max_execution_time,
    ps.avg_rows_returned,
    ps.avg_memory_usage,
    ps.unique_users,
    ps.unique_sessions
FROM performance_summary ps

UNION ALL

SELECT
    '=== RECENT PERFORMANCE TRENDS ===' AS report_section,
    pt.hour AS report_generated_at,
    pt.queries_per_hour AS total_queries,
    pt.avg_time_per_hour AS avg_execution_time,
    NULL AS min_execution_time,
    NULL AS max_execution_time,
    NULL AS avg_rows_returned,
    NULL AS avg_memory_usage,
    NULL AS unique_users,
    NULL AS unique_sessions
FROM performance_trends pt;

-- Clean up
DROP VIEW IF EXISTS v_system_performance CASCADE;
DROP TABLE IF EXISTS performance_logs CASCADE;
DROP TABLE IF EXISTS slow_queries CASCADE;
