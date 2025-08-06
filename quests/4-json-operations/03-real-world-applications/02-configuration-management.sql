-- =====================================================
-- JSON Operations: Configuration Management
-- =====================================================
-- 
-- PURPOSE: Demonstrate JSON-based configuration management techniques for
--          storing, validating, and managing application settings
-- LEARNING OUTCOMES:
--   - Store and manage application configurations in JSON format
--   - Validate configuration schemas and data types
--   - Handle environment-specific configuration settings
--   - Implement configuration versioning and updates
--   - Create dynamic configuration management systems
-- EXPECTED RESULTS: Manage application configurations with JSON validation
-- DIFFICULTY: 🟡 Intermediate (10-15 min)
-- CONCEPTS: Configuration storage, validation, environment management, versioning, dynamic settings

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS app_configurations CASCADE;
DROP TABLE IF EXISTS environment_configs CASCADE;
DROP TABLE IF EXISTS config_versions CASCADE;

-- Create application configurations table
CREATE TABLE app_configurations (
    id INT PRIMARY KEY,
    app_name VARCHAR(100),
    config_data JSONB,
    environment VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create environment-specific configurations table
CREATE TABLE environment_configs (
    id INT PRIMARY KEY,
    environment VARCHAR(50),
    config_schema JSONB,
    default_values JSONB,
    validation_rules JSONB
);

-- Create configuration versions table
CREATE TABLE config_versions (
    id INT PRIMARY KEY,
    app_name VARCHAR(100),
    version_number VARCHAR(20),
    config_data JSONB,
    change_log JSONB,
    deployed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample configuration data
INSERT INTO app_configurations VALUES
(1, 'webapp', '{
    "database": {
        "host": "localhost",
        "port": 5432,
        "name": "myapp_prod",
        "ssl": true,
        "connection_pool": {
            "min_connections": 5,
            "max_connections": 20,
            "timeout": 30
        }
    },
    "api": {
        "timeout": 30,
        "retries": 3,
        "rate_limit": 1000,
        "endpoints": {
            "users": "/api/v1/users",
            "products": "/api/v1/products",
            "orders": "/api/v1/orders"
        }
    },
    "logging": {
        "level": "info",
        "format": "json",
        "output": "file",
        "file_path": "/var/log/app.log"
    },
    "features": {
        "cache_enabled": true,
        "analytics_enabled": true,
        "debug_mode": false
    }
}', 'production', true, '2024-01-15 10:00:00'),
(2, 'webapp', '{
    "database": {
        "host": "localhost",
        "port": 5432,
        "name": "myapp_dev",
        "ssl": false,
        "connection_pool": {
            "min_connections": 2,
            "max_connections": 10,
            "timeout": 15
        }
    },
    "api": {
        "timeout": 60,
        "retries": 5,
        "rate_limit": 100,
        "endpoints": {
            "users": "/api/v1/users",
            "products": "/api/v1/products",
            "orders": "/api/v1/orders"
        }
    },
    "logging": {
        "level": "debug",
        "format": "text",
        "output": "console",
        "file_path": null
    },
    "features": {
        "cache_enabled": false,
        "analytics_enabled": false,
        "debug_mode": true
    }
}', 'development', true, '2024-01-15 10:00:00'),
(3, 'mobile_app', '{
    "api": {
        "base_url": "https://api.example.com",
        "timeout": 15,
        "retries": 2,
        "endpoints": {
            "auth": "/auth",
            "user_profile": "/user/profile",
            "notifications": "/notifications"
        }
    },
    "ui": {
        "theme": "dark",
        "language": "en",
        "notifications": {
            "push_enabled": true,
            "email_enabled": false,
            "sms_enabled": false
        }
    },
    "security": {
        "encryption_enabled": true,
        "biometric_auth": true,
        "session_timeout": 3600
    }
}', 'production', true, '2024-01-15 10:00:00');

-- Insert environment configuration schemas
INSERT INTO environment_configs VALUES
(1, 'production', '{
    "required_fields": ["database", "api", "logging"],
    "database_schema": {
        "host": {"type": "string", "required": true},
        "port": {"type": "integer", "min": 1, "max": 65535},
        "name": {"type": "string", "required": true},
        "ssl": {"type": "boolean", "default": true}
    },
    "api_schema": {
        "timeout": {"type": "integer", "min": 1, "max": 300},
        "retries": {"type": "integer", "min": 0, "max": 10},
        "rate_limit": {"type": "integer", "min": 1}
    }
}', '{
    "database": {
        "port": 5432,
        "ssl": true
    },
    "api": {
        "timeout": 30,
        "retries": 3
    },
    "logging": {
        "level": "info",
        "format": "json"
    }
}', '{
    "database.host": "Must be a valid hostname or IP address",
    "database.port": "Must be between 1 and 65535",
    "api.timeout": "Must be between 1 and 300 seconds",
    "api.retries": "Must be between 0 and 10"
}'),
(2, 'development', '{
    "required_fields": ["database", "api"],
    "database_schema": {
        "host": {"type": "string", "required": true},
        "port": {"type": "integer", "min": 1, "max": 65535},
        "name": {"type": "string", "required": true},
        "ssl": {"type": "boolean", "default": false}
    },
    "api_schema": {
        "timeout": {"type": "integer", "min": 1, "max": 300},
        "retries": {"type": "integer", "min": 0, "max": 10}
    }
}', '{
    "database": {
        "host": "localhost",
        "port": 5432,
        "ssl": false
    },
    "api": {
        "timeout": 60,
        "retries": 5
    },
    "logging": {
        "level": "debug",
        "format": "text"
    }
}', '{
    "database.host": "Must be a valid hostname or IP address",
    "api.timeout": "Must be between 1 and 300 seconds"
}');

-- Insert configuration versions
INSERT INTO config_versions VALUES
(1, 'webapp', '1.0.0', '{
    "database": {"host": "localhost", "port": 5432, "name": "myapp_v1"},
    "api": {"timeout": 30, "retries": 3}
}', '{
    "changes": ["Initial configuration", "Database connection settings", "API timeout configuration"],
    "author": "admin",
    "approved_by": "tech_lead"
}', '2024-01-01 00:00:00'),
(2, 'webapp', '1.1.0', '{
    "database": {"host": "localhost", "port": 5432, "name": "myapp_v1", "ssl": true},
    "api": {"timeout": 30, "retries": 3, "rate_limit": 1000}
}', '{
    "changes": ["Added SSL support", "Implemented rate limiting"],
    "author": "dev_team",
    "approved_by": "tech_lead"
}', '2024-01-10 00:00:00');

-- Example 1: Configuration Validation and Schema Checking
-- Validate configuration data against defined schemas
SELECT
    ac.id,
    ac.app_name,
    ac.environment,
    CASE
        WHEN
            ac.config_data ? 'database' AND ac.config_data ? 'api'
            THEN 'Valid Structure'
        ELSE 'Missing Required Sections'
    END AS structure_validation,
    CASE
        WHEN
            JSONB_TYPEOF(ac.config_data -> 'database' -> 'port') = 'number'
            AND (
                ac.config_data -> 'database' ->> 'port'
            )::INT BETWEEN 1 AND 65535
            THEN 'Valid Port'
        ELSE 'Invalid Port'
    END AS port_validation,
    CASE
        WHEN
            JSONB_TYPEOF(ac.config_data -> 'api' -> 'timeout') = 'number'
            AND (ac.config_data -> 'api' ->> 'timeout')::INT BETWEEN 1 AND 300
            THEN 'Valid Timeout'
        ELSE 'Invalid Timeout'
    END AS timeout_validation,
    JSONB_BUILD_OBJECT(
        'has_ssl',
        COALESCE(ac.config_data -> 'database' ->> 'ssl' = 'true', FALSE),
        'has_rate_limit',
        COALESCE(ac.config_data -> 'api' ? 'rate_limit', FALSE),
        'debug_enabled',
        COALESCE(ac.config_data -> 'features' ->> 'debug_mode' = 'true', FALSE)
    ) AS feature_flags
FROM app_configurations AS ac
ORDER BY ac.app_name, ac.environment;

-- Example 2: Environment-Specific Configuration Management
-- Compare and manage configurations across different environments
SELECT
    app_name,
    JSONB_BUILD_OBJECT(
        'production', JSONB_BUILD_OBJECT(
            'database_ssl',
            COUNT(*) FILTER (
                WHERE environment = 'production'
                AND config_data -> 'database' ->> 'ssl' = 'true'
            )
            > 0,
            'api_timeout',
            MAX(
                CASE
                    WHEN
                        environment = 'production'
                        THEN (config_data -> 'api' ->> 'timeout')::INT
                END
            ),
            'logging_level',
            MAX(
                CASE
                    WHEN
                        environment = 'production'
                        THEN config_data -> 'logging' ->> 'level'
                END
            )
        ),
        'development', JSONB_BUILD_OBJECT(
            'database_ssl',
            COUNT(*) FILTER (
                WHERE environment = 'development'
                AND config_data -> 'database' ->> 'ssl' = 'true'
            )
            > 0,
            'api_timeout',
            MAX(
                CASE
                    WHEN
                        environment = 'development'
                        THEN (config_data -> 'api' ->> 'timeout')::INT
                END
            ),
            'logging_level',
            MAX(
                CASE
                    WHEN
                        environment = 'development'
                        THEN config_data -> 'logging' ->> 'level'
                END
            )
        )
    ) AS environment_comparison,
    JSONB_BUILD_OBJECT(
        'ssl_difference', CASE
            WHEN
                COUNT(*) FILTER (
                    WHERE environment = 'production'
                    AND (config_data -> 'database' ->> 'ssl')::BOOLEAN = true
                )
                > 0
                AND COUNT(*) FILTER (
                    WHERE environment = 'development'
                    AND (config_data -> 'database' ->> 'ssl')::BOOLEAN = false
                )
                > 0
                THEN 'Different SSL settings'
            ELSE 'Same SSL settings'
        END,
        'timeout_difference', CASE
            WHEN
                COUNT(*) FILTER (
                    WHERE environment = 'production'
                    AND (config_data -> 'api' ->> 'timeout')::INT = 30
                )
                > 0
                AND COUNT(*) FILTER (
                    WHERE environment = 'development'
                    AND (config_data -> 'api' ->> 'timeout')::INT = 60
                )
                > 0
                THEN 'Different timeout settings'
            ELSE 'Same timeout settings'
        END
    ) AS configuration_differences
FROM app_configurations
WHERE app_name = 'webapp'
GROUP BY app_name;

-- Example 3: Configuration Versioning and Change Tracking
-- Track configuration changes and version history
SELECT
    cv.app_name,
    cv.version_number,
    cv.deployed_at,
    cv.change_log ->> 'changes' AS changes,
    cv.change_log ->> 'author' AS author,
    cv.change_log ->> 'approved_by' AS approved_by,
    JSONB_BUILD_OBJECT(
        'database_config', CASE
            WHEN cv.config_data ? 'database'
                THEN JSONB_BUILD_OBJECT(
                    'host', cv.config_data -> 'database' ->> 'host',
                    'port', cv.config_data -> 'database' ->> 'port',
                    'ssl_enabled',
                    COALESCE(cv.config_data -> 'database' ->> 'ssl' = 'true',
                    FALSE)
                )
        END,
        'api_config', CASE
            WHEN cv.config_data ? 'api'
                THEN JSONB_BUILD_OBJECT(
                    'timeout', cv.config_data -> 'api' ->> 'timeout',
                    'retries', cv.config_data -> 'api' ->> 'retries',
                    'has_rate_limit',
                    COALESCE(cv.config_data -> 'api' ? 'rate_limit', FALSE)
                )
        END
    ) AS configuration_summary
FROM config_versions AS cv
ORDER BY cv.app_name, cv.deployed_at;

-- Example 4: Dynamic Configuration Updates
-- Create dynamic configuration management with validation
SELECT
    ac.app_name,
    ac.environment,
    ac.config_data -> 'database' ->> 'host' AS db_host,
    ac.config_data -> 'database' ->> 'name' AS db_name,
    ac.config_data -> 'api' ->> 'timeout' AS api_timeout,
    JSONB_BUILD_OBJECT(
        'current_config', ac.config_data,
        'validation_status', CASE
            WHEN
                ac.config_data ? 'database' AND ac.config_data ? 'api'
                THEN 'valid'
            ELSE 'invalid'
        END,
        'environment_specific', CASE
            WHEN ac.environment = 'production'
                THEN JSONB_BUILD_OBJECT(
                    'ssl_required', true,
                    'min_timeout', 30,
                    'logging_level', 'info'
                )
            WHEN ac.environment = 'development'
                THEN JSONB_BUILD_OBJECT(
                    'ssl_required', false,
                    'min_timeout', 60,
                    'logging_level', 'debug'
                )
            ELSE JSONB_BUILD_OBJECT('unknown_environment', true)
        END
    ) AS dynamic_config
FROM app_configurations AS ac
WHERE ac.is_active = true
ORDER BY ac.app_name, ac.environment;

-- Example 5: Configuration Health Monitoring
-- Monitor configuration health and compliance
SELECT
    'configuration_health' AS check_type,
    COUNT(*) AS total_configs,
    COUNT(*) FILTER (WHERE config_data ? 'database' AND config_data ? 'api')
        AS valid_configs,
    COUNT(*) FILTER (
        WHERE NOT (config_data ? 'database' AND config_data ? 'api')
    ) AS invalid_configs,
    JSONB_BUILD_OBJECT(
        'health_score', ROUND(
            (
                COUNT(*) FILTER (
                    WHERE config_data ? 'database' AND config_data ? 'api'
                )::DECIMAL
                / COUNT(*)
            )
            * 100,
            2
        ),
        'environment_distribution', JSONB_BUILD_OBJECT(
            'production', COUNT(*) FILTER (WHERE environment = 'production'),
            'development', COUNT(*) FILTER (WHERE environment = 'development')
        ),
        'ssl_compliance', JSONB_BUILD_OBJECT(
            'ssl_enabled_count',
            COUNT(*) FILTER (
                WHERE config_data -> 'database' ->> 'ssl' = 'true'
            ),
            'ssl_disabled_count',
            COUNT(*) FILTER (
                WHERE config_data -> 'database' ->> 'ssl' = 'false'
            ),
            'ssl_missing_count',
            COUNT(*) FILTER (WHERE NOT (config_data -> 'database' ? 'ssl'))
        ),
        'timeout_compliance', JSONB_BUILD_OBJECT(
            'valid_timeouts',
            COUNT(*) FILTER (
                WHERE (
                    config_data -> 'api' ->> 'timeout'
                )::INT BETWEEN 1 AND 300
            ),
            'invalid_timeouts',
            COUNT(*) FILTER (
                WHERE NOT (
                    (config_data -> 'api' ->> 'timeout')::INT BETWEEN 1 AND 300
                )
            )
        )
    ) AS health_metrics
FROM app_configurations
WHERE is_active = true;

-- Clean up
DROP TABLE IF EXISTS app_configurations CASCADE;
DROP TABLE IF EXISTS environment_configs CASCADE;
DROP TABLE IF EXISTS config_versions CASCADE;
