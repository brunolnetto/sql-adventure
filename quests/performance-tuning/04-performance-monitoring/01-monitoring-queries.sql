-- =====================================================
-- Performance Tuning: Performance Monitoring
-- =====================================================
-- 
-- PURPOSE: Demonstrate performance monitoring techniques in PostgreSQL
--          for tracking, analyzing, and optimizing database performance
-- LEARNING OUTCOMES:
--   - Monitor database performance metrics
--   - Track slow queries and bottlenecks
--   - Analyze connection and resource usage
--   - Monitor index and table statistics
--   - Create performance dashboards and alerts
-- EXPECTED RESULTS: Monitor and optimize database performance
-- DIFFICULTY: 🔴 Advanced (15-20 min)
-- CONCEPTS: Performance monitoring, slow queries, resource usage, statistics, optimization

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS performance_logs CASCADE;
DROP TABLE IF EXISTS slow_queries CASCADE;
DROP TABLE IF EXISTS connection_stats CASCADE;

-- Create performance monitoring tables
CREATE TABLE performance_logs (
    log_id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    query_text TEXT,
    execution_time_ms INT,
    rows_returned INT,
    cpu_usage DECIMAL(5,2),
    memory_usage_mb INT,
    io_operations INT
);

CREATE TABLE slow_queries (
    query_id SERIAL PRIMARY KEY,
    query_hash TEXT,
    query_text TEXT,
    avg_execution_time_ms DECIMAL(10,2),
    max_execution_time_ms INT,
    execution_count INT,
    last_executed TIMESTAMP,
    first_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE connection_stats (
    stat_id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    active_connections INT,
    idle_connections INT,
    max_connections INT,
    connection_wait_time_ms INT,
    database_name VARCHAR(100)
);

-- Insert sample performance data
INSERT INTO performance_logs (query_text, execution_time_ms, rows_returned, cpu_usage, memory_usage_mb, io_operations) VALUES
('SELECT * FROM users WHERE email = $1', 15, 1, 2.5, 45, 3),
('SELECT COUNT(*) FROM orders WHERE created_date >= $1', 2500, 1, 85.2, 120, 150),
('SELECT * FROM products ORDER BY price DESC LIMIT 100', 89, 100, 12.8, 67, 25),
('UPDATE users SET last_login = NOW() WHERE user_id = $1', 8, 1, 1.2, 23, 2),
('SELECT * FROM orders o JOIN users u ON o.user_id = u.user_id WHERE o.status = $1', 1200, 50, 45.6, 89, 45),
('SELECT AVG(price) FROM products GROUP BY category', 156, 5, 18.9, 56, 18);

INSERT INTO slow_queries (query_hash, query_text, avg_execution_time_ms, max_execution_time_ms, execution_count, last_executed) VALUES
('abc123def456', 'SELECT * FROM orders WHERE created_date >= $1', 2500.5, 5000, 25, '2024-01-15 10:30:00'),
('xyz789ghi012', 'SELECT * FROM orders o JOIN users u ON o.user_id = u.user_id WHERE o.status = $1', 1200.3, 3000, 15, '2024-01-15 10:25:00'),
('def456ghi789', 'SELECT COUNT(*) FROM large_table WHERE complex_condition = $1', 3500.8, 8000, 8, '2024-01-15 10:20:00');

INSERT INTO connection_stats (active_connections, idle_connections, max_connections, connection_wait_time_ms, database_name) VALUES
(45, 12, 100, 0, 'sql_adventure_db'),
(67, 8, 100, 150, 'sql_adventure_db'),
(23, 34, 100, 0, 'sql_adventure_db'),
(89, 5, 100, 300, 'sql_adventure_db'),
(12, 45, 100, 0, 'sql_adventure_db');

-- Example 1: Slow Query Analysis
-- Identify and analyze slow queries
SELECT 
    query_hash,
    LEFT(query_text, 100) as query_preview,
    avg_execution_time_ms,
    max_execution_time_ms,
    execution_count,
    ROUND(avg_execution_time_ms * execution_count / 1000, 2) as total_time_seconds,
    last_executed,
    CASE 
        WHEN avg_execution_time_ms > 5000 THEN 'Critical'
        WHEN avg_execution_time_ms > 1000 THEN 'High'
        WHEN avg_execution_time_ms > 500 THEN 'Medium'
        ELSE 'Low'
    END as severity
FROM slow_queries
ORDER BY avg_execution_time_ms DESC;

-- Example 2: Performance Trend Analysis
-- Analyze performance trends over time
SELECT 
    DATE(timestamp) as log_date,
    COUNT(*) as total_queries,
    AVG(execution_time_ms) as avg_execution_time,
    MAX(execution_time_ms) as max_execution_time,
    SUM(execution_time_ms) as total_execution_time,
    AVG(cpu_usage) as avg_cpu_usage,
    AVG(memory_usage_mb) as avg_memory_usage
FROM performance_logs
GROUP BY DATE(timestamp)
ORDER BY log_date DESC;

-- Example 3: Resource Usage Monitoring
-- Monitor CPU and memory usage patterns
SELECT 
    CASE 
        WHEN cpu_usage > 80 THEN 'High CPU'
        WHEN cpu_usage > 50 THEN 'Medium CPU'
        ELSE 'Low CPU'
    END as cpu_category,
    CASE 
        WHEN memory_usage_mb > 100 THEN 'High Memory'
        WHEN memory_usage_mb > 50 THEN 'Medium Memory'
        ELSE 'Low Memory'
    END as memory_category,
    COUNT(*) as query_count,
    AVG(execution_time_ms) as avg_execution_time,
    AVG(cpu_usage) as avg_cpu_usage,
    AVG(memory_usage_mb) as avg_memory_usage
FROM performance_logs
GROUP BY 
    CASE 
        WHEN cpu_usage > 80 THEN 'High CPU'
        WHEN cpu_usage > 50 THEN 'Medium CPU'
        ELSE 'Low CPU'
    END,
    CASE 
        WHEN memory_usage_mb > 100 THEN 'High Memory'
        WHEN memory_usage_mb > 50 THEN 'Medium Memory'
        ELSE 'Low Memory'
    END
ORDER BY avg_execution_time DESC;

-- Example 4: Connection Pool Analysis
-- Analyze database connection usage
SELECT 
    DATE(timestamp) as stat_date,
    HOUR(timestamp) as stat_hour,
    AVG(active_connections) as avg_active_connections,
    AVG(idle_connections) as avg_idle_connections,
    MAX(active_connections) as max_active_connections,
    AVG(connection_wait_time_ms) as avg_wait_time,
    ROUND((AVG(active_connections) / MAX(max_connections)) * 100, 2) as connection_utilization_percent
FROM connection_stats
GROUP BY DATE(timestamp), HOUR(timestamp)
ORDER BY stat_date DESC, stat_hour DESC;

-- Example 5: Query Performance Categories
-- Categorize queries by performance characteristics
SELECT 
    CASE 
        WHEN execution_time_ms < 10 THEN 'Fast (< 10ms)'
        WHEN execution_time_ms < 100 THEN 'Normal (10-100ms)'
        WHEN execution_time_ms < 1000 THEN 'Slow (100ms-1s)'
        WHEN execution_time_ms < 5000 THEN 'Very Slow (1-5s)'
        ELSE 'Critical (> 5s)'
    END as performance_category,
    COUNT(*) as query_count,
    ROUND(AVG(execution_time_ms), 2) as avg_execution_time,
    ROUND(AVG(cpu_usage), 2) as avg_cpu_usage,
    ROUND(AVG(memory_usage_mb), 2) as avg_memory_usage,
    ROUND(AVG(io_operations), 2) as avg_io_operations,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM performance_logs)), 2) as percentage_of_total
FROM performance_logs
GROUP BY 
    CASE 
        WHEN execution_time_ms < 10 THEN 'Fast (< 10ms)'
        WHEN execution_time_ms < 100 THEN 'Normal (10-100ms)'
        WHEN execution_time_ms < 1000 THEN 'Slow (100ms-1s)'
        WHEN execution_time_ms < 5000 THEN 'Very Slow (1-5s)'
        ELSE 'Critical (> 5s)'
    END
ORDER BY avg_execution_time DESC;

-- Example 6: Performance Health Dashboard
-- Create a comprehensive performance health overview
SELECT 
    'performance_health_overview' as metric_type,
    COUNT(*) as total_queries_monitored,
    ROUND(AVG(execution_time_ms), 2) as overall_avg_execution_time,
    MAX(execution_time_ms) as slowest_query_time,
    COUNT(*) FILTER (WHERE execution_time_ms > 1000) as slow_queries_count,
    ROUND((COUNT(*) FILTER (WHERE execution_time_ms > 1000) * 100.0 / COUNT(*)), 2) as slow_query_percentage,
    ROUND(AVG(cpu_usage), 2) as avg_cpu_usage,
    ROUND(AVG(memory_usage_mb), 2) as avg_memory_usage_mb,
    ROUND(AVG(io_operations), 2) as avg_io_operations,
    jsonb_build_object(
        'performance_score', CASE 
            WHEN AVG(execution_time_ms) < 100 THEN 'Excellent'
            WHEN AVG(execution_time_ms) < 500 THEN 'Good'
            WHEN AVG(execution_time_ms) < 1000 THEN 'Fair'
            ELSE 'Poor'
        END,
        'cpu_health', CASE 
            WHEN AVG(cpu_usage) < 30 THEN 'Good'
            WHEN AVG(cpu_usage) < 70 THEN 'Fair'
            ELSE 'Poor'
        END,
        'memory_health', CASE 
            WHEN AVG(memory_usage_mb) < 50 THEN 'Good'
            WHEN AVG(memory_usage_mb) < 100 THEN 'Fair'
            ELSE 'Poor'
        END,
        'recommendations', jsonb_agg(DISTINCT 
            CASE 
                WHEN execution_time_ms > 5000 THEN 'Investigate critical slow queries'
                WHEN cpu_usage > 80 THEN 'Consider query optimization or scaling'
                WHEN memory_usage_mb > 100 THEN 'Review memory-intensive queries'
                ELSE 'Performance within acceptable range'
            END
        )
    ) as health_metrics
FROM performance_logs;

-- Clean up
DROP TABLE IF EXISTS performance_logs CASCADE;
DROP TABLE IF EXISTS slow_queries CASCADE;
DROP TABLE IF EXISTS connection_stats CASCADE; 