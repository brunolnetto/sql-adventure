-- =====================================================
-- JSON Operations: Performance Optimization
-- =====================================================
-- 
-- PURPOSE: Demonstrate JSON performance optimization techniques for
--          improving query performance, indexing strategies, and optimization
-- LEARNING OUTCOMES:
--   - Optimize JSON query performance with proper indexing
--   - Implement efficient JSON storage and retrieval patterns
--   - Use query optimization techniques for JSON operations
--   - Monitor and analyze JSON performance metrics
--   - Apply best practices for JSON performance
-- EXPECTED RESULTS: Optimize JSON operations for better performance
-- DIFFICULTY: 🔴 Advanced (15-20 min)
-- CONCEPTS: Performance optimization, indexing, query tuning, monitoring, best practices

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS performance_test_data CASCADE;
DROP TABLE IF EXISTS json_indexes CASCADE;
DROP TABLE IF EXISTS performance_metrics CASCADE;

-- Create performance test data table
CREATE TABLE performance_test_data (
    id INT PRIMARY KEY,
    user_data JSONB,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create JSON indexes table
CREATE TABLE json_indexes (
    id INT PRIMARY KEY,
    index_name VARCHAR(100),
    index_type VARCHAR(50),
    index_definition JSONB,
    is_active BOOLEAN DEFAULT true
);

-- Create performance metrics table
CREATE TABLE performance_metrics (
    id INT PRIMARY KEY,
    query_name VARCHAR(100),
    execution_time_ms DECIMAL(10, 3),
    rows_processed INT,
    index_used VARCHAR(100),
    performance_data JSONB,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample performance test data
INSERT INTO performance_test_data VALUES
(1, '{
    "user_id": 1001,
    "name": "John Doe",
    "email": "john.doe@example.com",
    "age": 30,
    "location": "New York",
    "preferences": {
        "theme": "dark",
        "language": "en",
        "notifications": true
    },
    "activity": {
        "last_login": "2024-01-15T10:00:00Z",
        "login_count": 150,
        "favorite_categories": ["electronics", "books", "sports"]
    }
}', '{
    "data_size_bytes": 512,
    "complexity_score": 8,
    "access_pattern": "frequent"
}', '2024-01-15 10:00:00'),
(2, '{
    "user_id": 1002,
    "name": "Jane Smith",
    "email": "jane.smith@example.com",
    "age": 25,
    "location": "Los Angeles",
    "preferences": {
        "theme": "light",
        "language": "en",
        "notifications": false
    },
    "activity": {
        "last_login": "2024-01-15T09:30:00Z",
        "login_count": 75,
        "favorite_categories": ["fashion", "beauty"]
    }
}', '{
    "data_size_bytes": 456,
    "complexity_score": 6,
    "access_pattern": "moderate"
}', '2024-01-15 10:01:00'),
(3, '{
    "user_id": 1003,
    "name": "Bob Johnson",
    "email": "bob.johnson@example.com",
    "age": 35,
    "location": "Chicago",
    "preferences": {
        "theme": "auto",
        "language": "en",
        "notifications": true
    },
    "activity": {
        "last_login": "2024-01-15T08:45:00Z",
        "login_count": 200,
        "favorite_categories": ["technology", "gaming", "music"]
    }
}', '{
    "data_size_bytes": 623,
    "complexity_score": 9,
    "access_pattern": "frequent"
}', '2024-01-15 10:02:00'),
(4, '{
    "user_id": 1004,
    "name": "Alice Brown",
    "email": "alice.brown@example.com",
    "age": 28,
    "location": "Miami",
    "preferences": {
        "theme": "dark",
        "language": "es",
        "notifications": true
    },
    "activity": {
        "last_login": "2024-01-15T07:15:00Z",
        "login_count": 120,
        "favorite_categories": ["travel", "food", "photography"]
    }
}', '{
    "data_size_bytes": 589,
    "complexity_score": 7,
    "access_pattern": "moderate"
}', '2024-01-15 10:03:00'),
(5, '{
    "user_id": 1005,
    "name": "Charlie Wilson",
    "email": "charlie.wilson@example.com",
    "age": 42,
    "location": "Seattle",
    "preferences": {
        "theme": "light",
        "language": "en",
        "notifications": false
    },
    "activity": {
        "last_login": "2024-01-15T06:30:00Z",
        "login_count": 300,
        "favorite_categories": ["books", "education", "science"]
    }
}', '{
    "data_size_bytes": 678,
    "complexity_score": 10,
    "access_pattern": "frequent"
}', '2024-01-15 10:04:00');

-- Insert sample JSON indexes
INSERT INTO json_indexes VALUES
(1, 'idx_user_id', 'GIN', '{
    "index_type": "GIN",
    "indexed_path": "user_id",
    "index_definition": "CREATE INDEX idx_user_id ON performance_test_data USING GIN ((user_data->\"user_id\"))",
    "use_case": "Exact user_id lookups"
}', true),
(2, 'idx_user_email', 'GIN', '{
    "index_type": "GIN",
    "indexed_path": "email",
    "index_definition": "CREATE INDEX idx_user_email ON performance_test_data USING GIN ((user_data->\"email\"))",
    "use_case": "Email-based searches"
}', true),
(3, 'idx_user_location', 'GIN', '{
    "index_type": "GIN",
    "indexed_path": "location",
    "index_definition": "CREATE INDEX idx_user_location ON performance_test_data USING GIN ((user_data->\"location\"))",
    "use_case": "Location-based queries"
}', true),
(4, 'idx_user_preferences', 'GIN', '{
    "index_type": "GIN",
    "indexed_path": "preferences",
    "index_definition": "CREATE INDEX idx_user_preferences ON performance_test_data USING GIN (user_data)",
    "use_case": "Complex preference queries"
}', true),
(5, 'idx_activity_last_login', 'BTREE', '{
    "index_type": "BTREE",
    "indexed_path": "activity.last_login",
    "index_definition": "CREATE INDEX idx_activity_last_login ON performance_test_data USING BTREE ((user_data->\"activity\"->\"last_login\"))",
    "use_case": "Time-based range queries"
}', true);

-- Insert sample performance metrics
INSERT INTO performance_metrics VALUES
(1, 'user_id_lookup', 2.5, 1, 'idx_user_id', '{
    "query_type": "exact_match",
    "index_effectiveness": "high",
    "rows_examined": 1,
    "rows_returned": 1
}', '2024-01-15 10:00:00'),
(2, 'email_search', 3.2, 1, 'idx_user_email', '{
    "query_type": "pattern_match",
    "index_effectiveness": "high",
    "rows_examined": 1,
    "rows_returned": 1
}', '2024-01-15 10:01:00'),
(3, 'location_filter', 15.8, 2, 'idx_user_location', '{
    "query_type": "range_query",
    "index_effectiveness": "medium",
    "rows_examined": 3,
    "rows_returned": 2
}', '2024-01-15 10:02:00'),
(4, 'preference_complex_query', 45.2, 3, 'idx_user_preferences', '{
    "query_type": "complex_filter",
    "index_effectiveness": "low",
    "rows_examined": 5,
    "rows_returned": 3
}', '2024-01-15 10:03:00'),
(5, 'no_index_query', 125.6, 2, 'none', '{
    "query_type": "full_scan",
    "index_effectiveness": "none",
    "rows_examined": 5,
    "rows_returned": 2
}', '2024-01-15 10:04:00');

-- Example 1: Index Performance Analysis
-- Analyze the effectiveness of different JSON indexes
SELECT
    ji.index_name,
    ji.index_type,
    ji.index_definition ->> 'use_case' AS use_case,
    COUNT(pm.id) AS usage_count,
    AVG(pm.execution_time_ms) AS avg_execution_time,
    JSONB_BUILD_OBJECT(
        'performance_grade', CASE
            WHEN AVG(pm.execution_time_ms) < 5 THEN 'A'
            WHEN AVG(pm.execution_time_ms) < 20 THEN 'B'
            WHEN AVG(pm.execution_time_ms) < 50 THEN 'C'
            ELSE 'D'
        END,
        'index_effectiveness',
        JSONB_AGG(DISTINCT pm.performance_data ->> 'index_effectiveness'),
        'query_types', JSONB_AGG(DISTINCT pm.performance_data ->> 'query_type'),
        'avg_rows_examined',
        ROUND(AVG((pm.performance_data ->> 'rows_examined')::INT), 2),
        'avg_rows_returned',
        ROUND(AVG((pm.performance_data ->> 'rows_returned')::INT), 2)
    ) AS performance_metrics
FROM json_indexes AS ji
LEFT JOIN performance_metrics AS pm ON ji.index_name = pm.index_used
WHERE ji.is_active = true
GROUP BY ji.id, ji.index_name, ji.index_type, ji.index_definition
ORDER BY avg_execution_time;

-- Example 2: Query Performance Optimization
-- Compare query performance with and without indexes
SELECT
    pm.query_name,
    pm.index_used,
    pm.execution_time_ms,
    pm.rows_processed,
    CASE
        WHEN pm.index_used = 'none' THEN 'No Index'
        ELSE 'Indexed'
    END AS indexing_status,
    JSONB_BUILD_OBJECT(
        'performance_impact', CASE
            WHEN pm.index_used = 'none' THEN 'High Impact'
            WHEN pm.execution_time_ms < 10 THEN 'Low Impact'
            WHEN pm.execution_time_ms < 50 THEN 'Medium Impact'
            ELSE 'High Impact'
        END,
        'optimization_potential', CASE
            WHEN pm.index_used = 'none' THEN 'Add appropriate index'
            WHEN
                pm.execution_time_ms > 50
                THEN 'Optimize query or add composite index'
            ELSE 'Well optimized'
        END,
        'query_complexity', CASE
            WHEN
                pm.performance_data ->> 'query_type' = 'exact_match'
                THEN 'Simple'
            WHEN
                pm.performance_data ->> 'query_type' = 'pattern_match'
                THEN 'Medium'
            WHEN
                pm.performance_data ->> 'query_type' = 'complex_filter'
                THEN 'Complex'
            ELSE 'Unknown'
        END
    ) AS optimization_analysis
FROM performance_metrics AS pm
ORDER BY pm.execution_time_ms DESC;

-- Example 3: JSON Storage Optimization
-- Analyze JSON storage patterns and optimization opportunities
SELECT
    'storage_optimization' AS analysis_type,
    COUNT(*) AS total_records,
    JSONB_BUILD_OBJECT(
        'storage_metrics', JSONB_BUILD_OBJECT(
            'avg_data_size_bytes',
            ROUND(AVG((ptd.metadata ->> 'data_size_bytes')::INT), 2),
            'total_storage_bytes',
            SUM((ptd.metadata ->> 'data_size_bytes')::INT),
            'complexity_distribution', JSONB_BUILD_OBJECT(
                'Low',
                COUNT(*) FILTER (
                    WHERE (ptd.metadata ->> 'complexity_score')::INT <= 5
                ),
                'Medium',
                COUNT(*) FILTER (
                    WHERE (
                        ptd.metadata ->> 'complexity_score'
                    )::INT BETWEEN 6 AND 8
                ),
                'High',
                COUNT(*) FILTER (
                    WHERE (ptd.metadata ->> 'complexity_score')::INT > 8
                )
            )
        ),
        'access_pattern_analysis', JSONB_BUILD_OBJECT(
            'frequent_access',
            COUNT(*) FILTER (
                WHERE ptd.metadata ->> 'access_pattern' = 'frequent'
            ),
            'moderate_access',
            COUNT(*) FILTER (
                WHERE ptd.metadata ->> 'access_pattern' = 'moderate'
            ),
            'rare_access',
            COUNT(*) FILTER (WHERE ptd.metadata ->> 'access_pattern' = 'rare')
        ),
        'optimization_recommendations', JSONB_BUILD_OBJECT(
            'large_objects',
            JSONB_AGG(ptd.id) FILTER (
                WHERE (ptd.metadata ->> 'data_size_bytes')::INT > 600
            ),
            'high_complexity',
            JSONB_AGG(ptd.id) FILTER (
                WHERE (ptd.metadata ->> 'complexity_score')::INT > 8
            ),
            'frequent_access_large', JSONB_AGG(ptd.id) FILTER (
                WHERE ptd.metadata ->> 'access_pattern' = 'frequent'
                AND (ptd.metadata ->> 'data_size_bytes')::INT > 500
            )
        )
    ) AS storage_analysis
FROM performance_test_data AS ptd;

-- Example 4: Performance Monitoring and Alerting
-- Create performance monitoring system for JSON operations
SELECT
    'performance_monitoring' AS monitoring_type,
    COUNT(*) AS total_queries,
    JSONB_BUILD_OBJECT(
        'performance_thresholds', JSONB_BUILD_OBJECT(
            'fast_queries', COUNT(*) FILTER (WHERE execution_time_ms < 10),
            'medium_queries',
            COUNT(*) FILTER (WHERE execution_time_ms BETWEEN 10 AND 50),
            'slow_queries', COUNT(*) FILTER (WHERE execution_time_ms > 50),
            'critical_queries', COUNT(*) FILTER (WHERE execution_time_ms > 100)
        ),
        'performance_alerts', JSONB_BUILD_OBJECT(
            'slow_query_alert', COALESCE(COUNT(*) FILTER (WHERE execution_time_ms > 50) > 0, FALSE),
            'critical_query_alert', COALESCE(COUNT(*) FILTER (WHERE execution_time_ms > 100) > 0, FALSE),
            'index_missing_alert', COALESCE(COUNT(*) FILTER (WHERE index_used = 'none') > 0, FALSE)
        ),
        'performance_trends', JSONB_BUILD_OBJECT(
            'avg_execution_time', ROUND(AVG(execution_time_ms), 2),
            'max_execution_time', MAX(execution_time_ms),
            'min_execution_time', MIN(execution_time_ms),
            'execution_time_variance', ROUND(VARIANCE(execution_time_ms), 2)
        ),
        'query_distribution', JSONB_BUILD_OBJECT(
            'simple_extraction',
            COUNT(*) FILTER (WHERE query_name = 'simple_extraction'),
            'nested_extraction',
            COUNT(*) FILTER (WHERE query_name = 'nested_extraction'),
            'array_operations',
            COUNT(*) FILTER (WHERE query_name = 'array_operations'),
            'complex_aggregation',
            COUNT(*) FILTER (WHERE query_name = 'complex_aggregation')
        )
    ) AS monitoring_metrics
FROM performance_metrics;

-- Example 5: Best Practices Implementation
-- Implement and validate JSON performance best practices
SELECT
    'best_practices_validation' AS validation_type,
    JSONB_BUILD_OBJECT(
        'indexing_best_practices', JSONB_BUILD_OBJECT(
            'appropriate_indexes', COUNT(*) FILTER (WHERE index_used != 'none'),
            'missing_indexes', COUNT(*) FILTER (WHERE index_used = 'none'),
            'index_coverage', ROUND(
                (
                    COUNT(*) FILTER (WHERE index_used != 'none')::DECIMAL
                    / COUNT(*)
                )
                * 100,
                2
            )
        ),
        'query_optimization_best_practices', JSONB_BUILD_OBJECT(
            'fast_queries_percentage', ROUND(
                (
                    COUNT(*) FILTER (WHERE execution_time_ms < 10)::DECIMAL
                    / COUNT(*)
                )
                * 100,
                2
            ),
            'slow_queries_percentage', ROUND(
                (
                    COUNT(*) FILTER (WHERE execution_time_ms > 50)::DECIMAL
                    / COUNT(*)
                )
                * 100,
                2
            ),
            'efficient_queries', COUNT(*) FILTER (WHERE execution_time_ms < 20)
        ),
        'storage_best_practices', JSONB_BUILD_OBJECT(
            'avg_object_size_optimal', COALESCE(AVG((ptd.metadata ->> 'data_size_bytes')::INT) < 1000, FALSE),
            'large_objects_count',
            COUNT(*) FILTER (
                WHERE (ptd.metadata ->> 'data_size_bytes')::INT > 1000
            ),
            'complexity_distribution_healthy', COALESCE(AVG((ptd.metadata ->> 'complexity_score')::INT) < 8, FALSE)
        ),
        'recommendations', JSONB_BUILD_OBJECT(
            'add_indexes_for',
            JSONB_AGG(DISTINCT query_name) FILTER (WHERE index_used = 'none'),
            'optimize_queries',
            JSONB_AGG(DISTINCT query_name) FILTER (
                WHERE execution_time_ms > 50
            ),
            'consider_partitioning',
            JSONB_AGG(ptd.id) FILTER (
                WHERE (ptd.metadata ->> 'data_size_bytes')::INT > 1000
            )
        )
    ) AS best_practices_analysis
FROM performance_metrics
CROSS JOIN performance_test_data AS ptd;

-- Clean up
DROP TABLE IF EXISTS performance_test_data CASCADE;
DROP TABLE IF EXISTS json_indexes CASCADE;
DROP TABLE IF EXISTS performance_metrics CASCADE;
