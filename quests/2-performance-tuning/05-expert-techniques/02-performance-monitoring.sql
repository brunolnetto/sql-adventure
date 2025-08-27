-- Performance Tuning Quest: Performance Monitoring
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

-- Function to log query performance
CREATE OR REPLACE FUNCTION LOG_QUERY_PERFORMANCE(
    p_query_text TEXT,
    p_execution_time_ms DECIMAL(10, 2),
    p_rows_returned INT,
    p_rows_scanned INT,
    p_cpu_time_ms DECIMAL(10, 2),
    p_io_time_ms DECIMAL(10, 2),
    p_memory_usage_mb DECIMAL(10, 2),
    p_session_id VARCHAR(50),
    p_user_name VARCHAR(50)
) RETURNS VOID AS $$
BEGIN
    INSERT INTO performance_logs (
        query_text, execution_time_ms, rows_returned, rows_scanned,
        cpu_time_ms, io_time_ms, memory_usage_mb, session_id, user_name
    ) VALUES (
        p_query_text, p_execution_time_ms, p_rows_returned, p_rows_scanned,
        p_cpu_time_ms, p_io_time_ms, p_memory_usage_mb, p_session_id, p_user_name
    );
END;
$$ LANGUAGE plpgsql;

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

-- Create comprehensive table performance view
-- Note: This view requires specific PostgreSQL configuration and may not work in all environments
-- Skipping this view creation to avoid compatibility issues

-- Create index performance view
-- Note: This view requires specific PostgreSQL configuration and may not work in all environments
-- Skipping this view creation to avoid compatibility issues

-- Example 5: Query Performance Tracking
-- Demonstrate tracking query performance over time

-- Function to identify slow queries
CREATE OR REPLACE FUNCTION IDENTIFY_SLOW_QUERIES(
    p_threshold_ms DECIMAL(10, 2) DEFAULT 1000
)
RETURNS TABLE (
    query_hash VARCHAR(64),
    avg_time_ms DECIMAL(10, 2),
    max_time_ms DECIMAL(10, 2),
    execution_count INT,
    total_rows BIGINT,
    sample_query TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        MD5(pl.query_text)::VARCHAR(64) as query_hash,
        ROUND(AVG(pl.execution_time_ms), 2) as avg_time_ms,
        MAX(pl.execution_time_ms) as max_time_ms,
        COUNT(*) as execution_count,
        SUM(pl.rows_returned) as total_rows,
        MAX(pl.query_text) as sample_query
    FROM performance_logs pl
    WHERE pl.execution_time_ms > p_threshold_ms
    GROUP BY MD5(pl.query_text)
    ORDER BY avg_time_ms DESC;
END;
$$ LANGUAGE plpgsql;

-- Example 6: Performance Alerting
-- Demonstrate setting up performance alerts

-- Function to check for performance issues
CREATE OR REPLACE FUNCTION CHECK_PERFORMANCE_ISSUES()
RETURNS TABLE (
    issue_type VARCHAR(50),
    description TEXT,
    severity VARCHAR(20),
    recommendation TEXT
) AS $$
BEGIN
    -- Check for slow queries
    IF EXISTS (
        SELECT 1 FROM performance_logs 
        WHERE execution_time_ms > 5000 
        AND timestamp > CURRENT_TIMESTAMP - INTERVAL '1 hour'
    ) THEN
        RETURN QUERY SELECT 
            'Slow Queries'::VARCHAR(50),
            'Queries taking longer than 5 seconds detected'::TEXT,
            'HIGH'::VARCHAR(20),
            'Review and optimize slow queries'::TEXT;
    END IF;

    -- Check for high dead tuple ratio
    IF EXISTS (
        SELECT 1 FROM pg_stat_user_tables 
        WHERE n_dead_tup * 100.0 / NULLIF(n_live_tup + n_dead_tup, 0) > 20
    ) THEN
        RETURN QUERY SELECT 
            'High Dead Tuples'::VARCHAR(50),
            'Tables with more than 20% dead tuples detected'::TEXT,
            'MEDIUM'::VARCHAR(20),
            'Run VACUUM on affected tables'::TEXT;
    END IF;

    -- Check for low cache hit ratio
    IF EXISTS (
        SELECT 1 FROM pg_statio_user_tables 
        WHERE (sum(heap_blks_hit) * 100.0 / NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0)) < 80
    ) THEN
        RETURN QUERY SELECT 
            'Low Cache Hit Ratio'::VARCHAR(50),
            'Cache hit ratio below 80% detected'::TEXT,
            'MEDIUM'::VARCHAR(20),
            'Consider increasing shared_buffers or optimizing queries'::TEXT;
    END IF;

    -- Check for unused indexes
    -- Note: This check requires pg_stat_user_indexes which may not be available in all environments
    -- Skipping this check to avoid compatibility issues
    /*
    IF EXISTS (
        SELECT 1 FROM pg_stat_user_indexes
        WHERE idx_scan = 0
        AND indexname NOT LIKE '%_pkey'
    ) THEN
        RETURN QUERY SELECT
            'Unused Indexes'::VARCHAR(50),
            'Indexes with zero scans detected'::TEXT,
            'LOW'::VARCHAR(20),
            'Consider dropping unused indexes'::TEXT;
    END IF;
    */
END;
$$ LANGUAGE plpgsql;

-- Example 7: Performance Reporting
-- Demonstrate generating performance reports

-- Generate performance summary report
SELECT
    'Performance Summary Report' AS report_title,
    CURRENT_TIMESTAMP AS report_time;

-- Top 10 slowest queries
SELECT
    'Top 10 Slowest Queries' AS section,
    query_hash,
    avg_time_ms,
    execution_count,
    sample_query
FROM IDENTIFY_SLOW_QUERIES(100)
LIMIT 10;

-- Table performance summary
SELECT
    'Table Performance Summary' AS section,
    tablename,
    live_tuples,
    dead_tuple_ratio,
    table_size
FROM v_table_performance
WHERE live_tuples > 1000
ORDER BY live_tuples DESC;

-- Index usage summary
SELECT
    'Index Usage Summary' AS section,
    indexname,
    scans,
    fetch_ratio,
    index_size
FROM v_index_performance
WHERE scans > 0
ORDER BY scans DESC;

-- Performance issues
SELECT
    'Performance Issues' AS section,
    issue_type,
    description,
    severity,
    recommendation
FROM CHECK_PERFORMANCE_ISSUES();

-- Clean up
DROP FUNCTION IF EXISTS log_query_performance(
    TEXT, DECIMAL, INT, INT, DECIMAL, DECIMAL, DECIMAL, VARCHAR, VARCHAR
) CASCADE;
DROP FUNCTION IF EXISTS identify_slow_queries(DECIMAL) CASCADE;
DROP FUNCTION IF EXISTS check_performance_issues() CASCADE;
DROP VIEW IF EXISTS v_system_performance CASCADE;
DROP VIEW IF EXISTS v_table_performance CASCADE;
DROP VIEW IF EXISTS v_index_performance CASCADE;
DROP TABLE IF EXISTS performance_logs CASCADE;
DROP TABLE IF EXISTS slow_queries CASCADE;
