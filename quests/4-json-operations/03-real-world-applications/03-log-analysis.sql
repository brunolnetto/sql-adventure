-- =====================================================
-- JSON Operations: Log Analysis
-- =====================================================
-- 
-- PURPOSE: Demonstrate JSON log parsing and analysis techniques for
--          extracting insights from structured log data
-- LEARNING OUTCOMES:
--   - Parse and analyze JSON log entries
--   - Extract patterns and trends from log data
--   - Identify error patterns and performance issues
--   - Create log aggregation and reporting systems
--   - Monitor application health through log analysis
-- EXPECTED RESULTS: Analyze log data to extract meaningful insights
-- DIFFICULTY: 🔴 Advanced (15-20 min)
-- CONCEPTS: Log parsing, pattern recognition, error analysis, performance monitoring, aggregation

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS application_logs CASCADE;
DROP TABLE IF EXISTS error_logs CASCADE;
DROP TABLE IF EXISTS performance_logs CASCADE;

-- Create application logs table
CREATE TABLE application_logs (
    id INT PRIMARY KEY,
    timestamp TIMESTAMP,
    level VARCHAR(20),
    service VARCHAR(100),
    log_data JSONB,
    user_id INT
);

-- Create error logs table
CREATE TABLE error_logs (
    id INT PRIMARY KEY,
    timestamp TIMESTAMP,
    error_type VARCHAR(100),
    error_data JSONB,
    severity VARCHAR(20),
    resolved BOOLEAN DEFAULT false
);

-- Create performance logs table
CREATE TABLE performance_logs (
    id INT PRIMARY KEY,
    timestamp TIMESTAMP,
    endpoint VARCHAR(200),
    response_time_ms INT,
    status_code INT,
    performance_data JSONB
);

-- Insert sample application log data
INSERT INTO application_logs VALUES
(1, '2024-01-15 10:00:00', 'INFO', 'user-service', '{
    "action": "user_login",
    "user_id": 12345,
    "ip_address": "192.168.1.100",
    "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    "session_id": "sess_abc123",
    "metadata": {
        "login_method": "password",
        "two_factor": false,
        "location": "New York"
    }
}', 12345),
(2, '2024-01-15 10:01:00', 'WARN', 'payment-service', '{
    "action": "payment_processing",
    "transaction_id": "txn_789",
    "amount": 99.99,
    "currency": "USD",
    "payment_method": "credit_card",
    "status": "pending",
    "metadata": {
        "retry_count": 1,
        "gateway": "stripe",
        "risk_score": 0.3
    }
}', 12345),
(3, '2024-01-15 10:02:00', 'ERROR', 'database-service', '{
    "action": "database_query",
    "query_type": "SELECT",
    "table": "users",
    "duration_ms": 2500,
    "error": {
        "code": "TIMEOUT",
        "message": "Query execution timeout",
        "details": "Query took longer than 2000ms"
    },
    "metadata": {
        "connection_pool": "main",
        "query_hash": "abc123def456"
    }
}', null),
(4, '2024-01-15 10:03:00', 'INFO', 'notification-service', '{
    "action": "email_sent",
    "recipient": "user@example.com",
    "template": "welcome_email",
    "status": "delivered",
    "metadata": {
        "provider": "sendgrid",
        "delivery_time_ms": 150,
        "bounce_rate": 0.01
    }
}', 12345),
(5, '2024-01-15 10:04:00', 'DEBUG', 'cache-service', '{
    "action": "cache_hit",
    "key": "user_profile_12345",
    "cache_type": "redis",
    "ttl_seconds": 3600,
    "metadata": {
        "cache_size_bytes": 2048,
        "hit_rate": 0.85
    }
}', 12345);

-- Insert sample error log data
INSERT INTO error_logs VALUES
(1, '2024-01-15 10:02:00', 'DatabaseTimeout', '{
    "service": "database-service",
    "query": "SELECT * FROM users WHERE email = $1",
    "parameters": ["user@example.com"],
    "timeout_ms": 2000,
    "actual_duration_ms": 2500,
    "stack_trace": "DatabaseConnection.execute() at line 45",
    "context": {
        "user_id": 12345,
        "session_id": "sess_abc123",
        "request_id": "req_xyz789"
    }
}', 'HIGH', false),
(2, '2024-01-15 10:05:00', 'ValidationError', '{
    "service": "user-service",
    "field": "email",
    "value": "invalid-email",
    "rule": "email_format",
    "message": "Invalid email format",
    "context": {
        "action": "user_registration",
        "ip_address": "192.168.1.101"
    }
}', 'MEDIUM', true),
(3, '2024-01-15 10:06:00', 'AuthenticationError', '{
    "service": "auth-service",
    "user_id": 12346,
    "attempt_count": 3,
    "ip_address": "192.168.1.102",
    "reason": "Invalid credentials",
    "context": {
        "login_method": "password",
        "user_agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0)"
    }
}', 'MEDIUM', false);

-- Insert sample performance log data
INSERT INTO performance_logs VALUES
(1, '2024-01-15 10:00:00', '/api/users/profile', 150, 200, '{
    "method": "GET",
    "user_id": 12345,
    "cache_hit": true,
    "database_queries": 1,
    "external_calls": 0,
    "memory_usage_mb": 45.2
}'),
(2, '2024-01-15 10:01:00', '/api/payments/process', 2500, 500, '{
    "method": "POST",
    "user_id": 12345,
    "cache_hit": false,
    "database_queries": 3,
    "external_calls": 2,
    "memory_usage_mb": 67.8,
    "error": "Database timeout"
}'),
(3, '2024-01-15 10:02:00', '/api/products/search', 89, 200, '{
    "method": "GET",
    "user_id": 12347,
    "cache_hit": true,
    "database_queries": 0,
    "external_calls": 0,
    "memory_usage_mb": 32.1
}'),
(4, '2024-01-15 10:03:00', '/api/orders/create', 1200, 201, '{
    "method": "POST",
    "user_id": 12348,
    "cache_hit": false,
    "database_queries": 5,
    "external_calls": 1,
    "memory_usage_mb": 78.9
}');

-- Example 1: Log Entry Parsing and Analysis
-- Parse and analyze different types of log entries
SELECT
    id,
    timestamp,
    level,
    service,
    log_data ->> 'action' AS action,
    log_data ->> 'user_id' AS user_id,
    CASE
        WHEN level = 'ERROR' THEN 'Critical'
        WHEN level = 'WARN' THEN 'Warning'
        WHEN level = 'INFO' THEN 'Information'
        WHEN level = 'DEBUG' THEN 'Debug'
        ELSE 'Unknown'
    END AS severity_category,
    jsonb_build_object(
        'has_metadata',
        coalesce(log_data ? 'metadata', false),
        'metadata_keys', CASE
            WHEN log_data ? 'metadata'
                THEN jsonb_build_array('login_method', 'two_factor', 'location')
            ELSE '[]'::JSONB
        END,
        'error_info', CASE
            WHEN log_data ? 'error'
                THEN jsonb_build_object(
                    'error_code', log_data -> 'error' ->> 'code',
                    'error_message', log_data -> 'error' ->> 'message'
                )
        END
    ) AS log_analysis
FROM application_logs
ORDER BY timestamp;

-- Example 2: Error Pattern Recognition
-- Identify patterns in error logs and categorize them
SELECT
    error_type,
    severity,
    count(*) AS error_count,
    count(*) FILTER (WHERE resolved = true) AS resolved_count,
    count(*) FILTER (WHERE resolved = false) AS unresolved_count,
    jsonb_build_object(
        'avg_occurrence_per_hour', round(count(*)::DECIMAL / 24, 2),
        'resolution_rate', round(
            (count(*) FILTER (WHERE resolved = true)::DECIMAL / count(*)) * 100,
            2
        ),
        'common_contexts', jsonb_agg(DISTINCT error_data ->> 'service'),
        'time_distribution', jsonb_build_object(
            'hour_10',
            count(*) FILTER (WHERE extract(HOUR FROM timestamp) = 10),
            'hour_11',
            count(*) FILTER (WHERE extract(HOUR FROM timestamp) = 11),
            'hour_12', count(*) FILTER (WHERE extract(HOUR FROM timestamp) = 12)
        )
    ) AS error_patterns,
    jsonb_build_object(
        'most_common_service', (
            SELECT error_data ->> 'service'
            FROM error_logs AS el2
            WHERE el2.error_type = error_logs.error_type
            GROUP BY error_data ->> 'service'
            ORDER BY count(*) DESC
            LIMIT 1
        ),
        'avg_resolution_time', avg(extract(EPOCH FROM (
            SELECT max(timestamp) FROM error_logs AS el3
            WHERE el3.error_type = error_logs.error_type AND el3.resolved = true
        ) - timestamp))
    ) AS error_metrics
FROM error_logs
GROUP BY error_type, severity
ORDER BY error_count DESC;

-- Example 3: Performance Analysis and Monitoring
-- Analyze performance metrics from log data
SELECT
    endpoint,
    count(*) AS request_count,
    avg(response_time_ms) AS avg_response_time,
    max(response_time_ms) AS max_response_time,
    min(response_time_ms) AS min_response_time,
    count(*) FILTER (WHERE status_code >= 400) AS error_count,
    jsonb_build_object(
        'performance_grade', CASE
            WHEN avg(response_time_ms) < 100 THEN 'A'
            WHEN avg(response_time_ms) < 500 THEN 'B'
            WHEN avg(response_time_ms) < 1000 THEN 'C'
            ELSE 'D'
        END,
        'cache_efficiency', round(
            (
                count(*) FILTER (
                    WHERE performance_data ->> 'cache_hit' = 'true'
                )::DECIMAL
                / count(*)
            )
            * 100,
            2
        ),
        'avg_database_queries',
        avg((performance_data ->> 'database_queries')::INT),
        'avg_external_calls', avg((performance_data ->> 'external_calls')::INT),
        'memory_usage_stats', jsonb_build_object(
            'avg_memory_mb',
            round(avg((performance_data ->> 'memory_usage_mb')::DECIMAL), 2),
            'max_memory_mb',
            max((performance_data ->> 'memory_usage_mb')::DECIMAL)
        )
    ) AS performance_metrics
FROM performance_logs
GROUP BY endpoint
ORDER BY avg_response_time DESC;

-- Example 4: User Activity Analysis
-- Analyze user behavior patterns from log data
SELECT
    user_id,
    count(*) AS activity_count,
    count(DISTINCT date(timestamp)) AS active_days,
    jsonb_agg(DISTINCT log_data ->> 'action') AS actions_performed,
    jsonb_build_object(
        'first_activity', min(timestamp),
        'last_activity', max(timestamp),
        'activity_frequency', round(
            count(*)::DECIMAL
            / greatest(
                extract(EPOCH FROM (max(timestamp) - min(timestamp))) / 3600, 1
            ),
            2
        ),
        'service_usage', jsonb_build_object(
            'user_service', count(*) FILTER (WHERE service = 'user-service'),
            'payment_service',
            count(*) FILTER (WHERE service = 'payment-service'),
            'database_service',
            count(*) FILTER (WHERE service = 'database-service'),
            'notification_service',
            count(*) FILTER (WHERE service = 'notification-service'),
            'cache_service', count(*) FILTER (WHERE service = 'cache-service')
        ),
        'error_experience', jsonb_build_object(
            'total_errors', count(*) FILTER (WHERE level = 'ERROR'),
            'error_rate', round(
                (count(*) FILTER (WHERE level = 'ERROR')::DECIMAL / count(*))
                * 100,
                2
            )
        )
    ) AS user_behavior
FROM application_logs
WHERE user_id IS NOT null
GROUP BY user_id
ORDER BY activity_count DESC;

-- Example 5: System Health Monitoring
-- Create comprehensive system health monitoring from logs
SELECT
    'system_health' AS monitoring_type,
    count(*) AS total_log_entries,
    jsonb_build_object(
        'log_distribution', jsonb_build_object(
            'INFO', count(*) FILTER (WHERE level = 'INFO'),
            'WARN', count(*) FILTER (WHERE level = 'WARN'),
            'ERROR', count(*) FILTER (WHERE level = 'ERROR'),
            'DEBUG', count(*) FILTER (WHERE level = 'DEBUG')
        ),
        'service_health', jsonb_build_object(
            'user_service', jsonb_build_object(
                'total_logs', count(*) FILTER (WHERE service = 'user-service'),
                'error_count',
                count(*) FILTER (
                    WHERE service = 'user-service' AND level = 'ERROR'
                ),
                'warning_count',
                count(*) FILTER (
                    WHERE service = 'user-service' AND level = 'WARN'
                ),
                'health_score', round(
                    (
                        count(*) FILTER (
                            WHERE service = 'user-service'
                            AND level IN ('INFO', 'DEBUG')
                        )::DECIMAL
                        / count(*) FILTER (WHERE service = 'user-service')
                    ) * 100, 2
                )
            ),
            'payment_service', jsonb_build_object(
                'total_logs',
                count(*) FILTER (WHERE service = 'payment-service'),
                'error_count',
                count(*) FILTER (
                    WHERE service = 'payment-service' AND level = 'ERROR'
                ),
                'warning_count',
                count(*) FILTER (
                    WHERE service = 'payment-service' AND level = 'WARN'
                ),
                'health_score', round(
                    (
                        count(*) FILTER (
                            WHERE service = 'payment-service'
                            AND level IN ('INFO', 'DEBUG')
                        )::DECIMAL
                        / count(*) FILTER (WHERE service = 'payment-service')
                    ) * 100, 2
                )
            )
        ),
        'performance_health', jsonb_build_object(
            'avg_response_time',
            (SELECT avg(response_time_ms) FROM performance_logs),
            'error_rate', round(
                (
                    (
                        SELECT count(*) FROM performance_logs
                        WHERE status_code >= 400
                    )::DECIMAL
                    / (SELECT count(*) FROM performance_logs)
                ) * 100, 2
            ),
            'slow_endpoints',
            jsonb_build_array('/api/payments/process', '/api/orders/create')
        ),
        'error_health', jsonb_build_object(
            'total_errors', (SELECT count(*) FROM error_logs),
            'unresolved_errors',
            (
                SELECT count(*) FROM error_logs
                WHERE resolved = false
            ),
            'critical_errors',
            (
                SELECT count(*) FROM error_logs
                WHERE severity = 'HIGH'
            ),
            'error_trend', jsonb_build_object(
                'DatabaseTimeout', count(*) FILTER (WHERE EXISTS (
                    SELECT 1
                    FROM error_logs AS el
                    WHERE el.error_type = 'DatabaseTimeout'
                )),
                'ValidationError', count(*) FILTER (WHERE EXISTS (
                    SELECT 1
                    FROM error_logs AS el
                    WHERE el.error_type = 'ValidationError'
                )),
                'AuthenticationError', count(*) FILTER (WHERE EXISTS (
                    SELECT 1
                    FROM error_logs AS el
                    WHERE el.error_type = 'AuthenticationError'
                ))
            )
        )
    ) AS health_metrics
FROM application_logs;

-- Clean up
DROP TABLE IF EXISTS application_logs CASCADE;
DROP TABLE IF EXISTS error_logs CASCADE;
DROP TABLE IF EXISTS performance_logs CASCADE;
