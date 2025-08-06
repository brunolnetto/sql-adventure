-- =====================================================
-- JSON Operations: Schema Validation
-- =====================================================
-- 
-- PURPOSE: Demonstrate advanced JSON schema validation techniques for
--          ensuring data integrity and structure compliance
-- LEARNING OUTCOMES:
--   - Define and validate JSON schemas with complex rules
--   - Create custom validation functions and constraints
--   - Handle schema evolution and migration
--   - Implement validation performance optimization
--   - Build comprehensive validation systems
-- EXPECTED RESULTS: Validate JSON data against complex schemas
-- DIFFICULTY: 🔴 Advanced (15-20 min)
-- CONCEPTS: Schema validation, complex rules, custom validators, schema evolution, performance optimization

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS json_schemas CASCADE;
DROP TABLE IF EXISTS validation_results CASCADE;
DROP TABLE IF EXISTS schema_versions CASCADE;

-- Create JSON schemas table
CREATE TABLE json_schemas (
    id INT PRIMARY KEY,
    schema_name VARCHAR(100),
    schema_definition JSONB,
    version VARCHAR(20),
    is_active BOOLEAN DEFAULT true
);

-- Create validation results table
CREATE TABLE validation_results (
    id INT PRIMARY KEY,
    schema_id INT REFERENCES json_schemas (id),
    data_to_validate JSONB,
    validation_result JSONB,
    is_valid BOOLEAN,
    validated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create schema versions table
CREATE TABLE schema_versions (
    id INT PRIMARY KEY,
    schema_name VARCHAR(100),
    version_number VARCHAR(20),
    schema_definition JSONB,
    migration_rules JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample JSON schemas
INSERT INTO json_schemas VALUES
(1, 'user_profile', '{
    "type": "object",
    "required": ["id", "name", "email", "age"],
    "properties": {
        "id": {
            "type": "integer",
            "minimum": 1,
            "description": "Unique user identifier"
        },
        "name": {
            "type": "string",
            "minLength": 2,
            "maxLength": 100,
            "pattern": "^[a-zA-Z\\s]+$",
            "description": "User full name"
        },
        "email": {
            "type": "string",
            "format": "email",
            "pattern": "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$",
            "description": "Valid email address"
        },
        "age": {
            "type": "integer",
            "minimum": 13,
            "maximum": 120,
            "description": "User age in years"
        },
        "phone": {
            "type": "string",
            "pattern": "^\\+?[1-9]\\d{1,14}$",
            "description": "Phone number in E.164 format"
        },
        "address": {
            "type": "object",
            "properties": {
                "street": {"type": "string", "minLength": 5},
                "city": {"type": "string", "minLength": 2},
                "state": {"type": "string", "minLength": 2},
                "zip": {"type": "string", "pattern": "^\\d{5}(-\\d{4})?$"},
                "country": {"type": "string", "minLength": 2}
            },
            "required": ["street", "city", "state", "zip", "country"]
        },
        "preferences": {
            "type": "object",
            "properties": {
                "theme": {
                    "type": "string",
                    "enum": ["light", "dark", "auto"]
                },
                "notifications": {
                    "type": "object",
                    "properties": {
                        "email": {"type": "boolean"},
                        "sms": {"type": "boolean"},
                        "push": {"type": "boolean"}
                    }
                }
            }
        }
    },
    "additionalProperties": false
}', '1.0', true),
(2, 'product_catalog', '{
    "type": "object",
    "required": ["product_id", "name", "price", "category"],
    "properties": {
        "product_id": {
            "type": "string",
            "pattern": "^PROD-[A-Z0-9]{8}$",
            "description": "Product identifier"
        },
        "name": {
            "type": "string",
            "minLength": 3,
            "maxLength": 200,
            "description": "Product name"
        },
        "price": {
            "type": "number",
            "minimum": 0.01,
            "maximum": 999999.99,
            "multipleOf": 0.01,
            "description": "Product price"
        },
        "category": {
            "type": "string",
            "enum": ["Electronics", "Clothing", "Books", "Home", "Sports"],
            "description": "Product category"
        },
        "description": {
            "type": "string",
            "maxLength": 1000,
            "description": "Product description"
        },
        "specifications": {
            "type": "object",
            "additionalProperties": {
                "oneOf": [
                    {"type": "string"},
                    {"type": "number"},
                    {"type": "boolean"}
                ]
            }
        },
        "tags": {
            "type": "array",
            "items": {
                "type": "string",
                "minLength": 1,
                "maxLength": 50
            },
            "maxItems": 10,
            "uniqueItems": true
        },
        "inventory": {
            "type": "object",
            "required": ["quantity", "location"],
            "properties": {
                "quantity": {
                    "type": "integer",
                    "minimum": 0
                },
                "location": {
                    "type": "string",
                    "minLength": 2
                },
                "reserved": {
                    "type": "integer",
                    "minimum": 0
                }
            }
        }
    }
}', '1.0', true);

-- Insert sample validation results
INSERT INTO validation_results VALUES
(1, 1, '{
    "id": 12345,
    "name": "John Doe",
    "email": "john.doe@example.com",
    "age": 30,
    "phone": "+1234567890",
    "address": {
        "street": "123 Main Street",
        "city": "New York",
        "state": "NY",
        "zip": "10001",
        "country": "USA"
    },
    "preferences": {
        "theme": "dark",
        "notifications": {
            "email": true,
            "sms": false,
            "push": true
        }
    }
}', '{
    "valid": true,
    "errors": [],
    "warnings": []
}', true, '2024-01-15 10:00:00'),
(2, 1, '{
    "id": 12346,
    "name": "Jane Smith",
    "email": "invalid-email",
    "age": 12,
    "phone": "123",
    "address": {
        "street": "456 Oak Ave",
        "city": "LA",
        "state": "CA",
        "zip": "90210"
    }
}', '{
    "valid": false,
    "errors": [
        "Email format is invalid",
        "Age must be at least 13",
        "Phone number format is invalid",
        "Address is missing required field: country"
    ],
    "warnings": []
}', false, '2024-01-15 10:01:00'),
(3, 2, '{
    "product_id": "PROD-ABC12345",
    "name": "Gaming Laptop",
    "price": 1299.99,
    "category": "Electronics",
    "description": "High-performance gaming laptop with RGB keyboard",
    "specifications": {
        "processor": "Intel i7",
        "ram": "16GB",
        "storage": "512GB SSD",
        "gpu": "RTX 4060"
    },
    "tags": ["gaming", "laptop", "high-performance"],
    "inventory": {
        "quantity": 25,
        "location": "Warehouse A",
        "reserved": 5
    }
}', '{
    "valid": true,
    "errors": [],
    "warnings": []
}', true, '2024-01-15 10:02:00');

-- Insert schema versions
INSERT INTO schema_versions VALUES
(1, 'user_profile', '1.0', '{
    "type": "object",
    "required": ["id", "name", "email", "age"],
    "properties": {
        "id": {"type": "integer", "minimum": 1},
        "name": {"type": "string", "minLength": 2},
        "email": {"type": "string", "format": "email"},
        "age": {"type": "integer", "minimum": 13, "maximum": 120}
    }
}', '{
    "migration_rules": {
        "add_phone_field": {
            "type": "add_property",
            "property": "phone",
            "definition": {"type": "string", "pattern": "^\\+?[1-9]\\d{1,14}$"}
        }
    }
}', '2024-01-01 00:00:00'),
(2, 'user_profile', '1.1', '{
    "type": "object",
    "required": ["id", "name", "email", "age"],
    "properties": {
        "id": {"type": "integer", "minimum": 1},
        "name": {"type": "string", "minLength": 2},
        "email": {"type": "string", "format": "email"},
        "age": {"type": "integer", "minimum": 13, "maximum": 120},
        "phone": {"type": "string", "pattern": "^\\+?[1-9]\\d{1,14}$"}
    }
}', '{
    "migration_rules": {
        "add_address_field": {
            "type": "add_property",
            "property": "address",
            "definition": {
                "type": "object",
                "properties": {
                    "street": {"type": "string", "minLength": 5},
                    "city": {"type": "string", "minLength": 2},
                    "state": {"type": "string", "minLength": 2},
                    "zip": {"type": "string", "pattern": "^\\d{5}(-\\d{4})?$"},
                    "country": {"type": "string", "minLength": 2}
                }
            }
        }
    }
}', '2024-01-10 00:00:00');

-- Example 1: Basic Schema Validation
-- Validate JSON data against defined schemas
SELECT
    vr.id,
    js.schema_name,
    js.version,
    vr.is_valid,
    CASE
        WHEN vr.is_valid THEN 'Valid Data'
        ELSE 'Invalid Data'
    END AS validation_status,
    JSONB_BUILD_OBJECT(
        'error_count', JSONB_ARRAY_LENGTH(vr.validation_result -> 'errors'),
        'warning_count', JSONB_ARRAY_LENGTH(vr.validation_result -> 'warnings'),
        'validation_time', vr.validated_at,
        'schema_compliance', CASE
            WHEN vr.is_valid THEN 100
            ELSE
                ROUND(
                    (
                        100
                        - (
                            JSONB_ARRAY_LENGTH(vr.validation_result -> 'errors')
                            * 20
                        )
                    ),
                    0
                )
        END
    ) AS validation_metrics
FROM validation_results AS vr
INNER JOIN json_schemas AS js ON vr.schema_id = js.id
ORDER BY vr.validated_at;

-- Example 2: Complex Validation Rules
-- Apply complex validation rules and custom constraints
SELECT
    vr.id,
    js.schema_name,
    vr.data_to_validate ->> 'name' AS data_name,
    vr.data_to_validate ->> 'email' AS data_email,
    vr.data_to_validate ->> 'age' AS data_age,
    JSONB_BUILD_OBJECT(
        'name_validation', CASE
            WHEN
                JSONB_TYPEOF(vr.data_to_validate -> 'name') = 'string'
                AND LENGTH(vr.data_to_validate ->> 'name') BETWEEN 2 AND 100
                AND vr.data_to_validate ->> 'name' ~ '^[a-zA-Z\\s]+$'
                THEN 'Valid'
            ELSE 'Invalid'
        END,
        'email_validation', CASE
            WHEN
                vr.data_to_validate ->> 'email'
                ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$'
                THEN 'Valid'
            ELSE 'Invalid'
        END,
        'age_validation', CASE
            WHEN
                JSONB_TYPEOF(vr.data_to_validate -> 'age') = 'number'
                AND (vr.data_to_validate ->> 'age')::INT BETWEEN 13 AND 120
                THEN 'Valid'
            ELSE 'Invalid'
        END,
        'phone_validation', CASE
            WHEN vr.data_to_validate ? 'phone'
                THEN
                    CASE
                        WHEN
                            vr.data_to_validate ->> 'phone'
                            ~ '^\\+?[1-9]\\d{1,14}$'
                            THEN 'Valid'
                        ELSE 'Invalid'
                    END
            ELSE 'Not Provided'
        END
    ) AS field_validations
FROM validation_results AS vr
INNER JOIN json_schemas AS js ON vr.schema_id = js.id
WHERE js.schema_name = 'user_profile'
ORDER BY vr.validated_at;

-- Example 3: Schema Evolution and Migration
-- Handle schema versioning and migration rules
SELECT
    sv.schema_name,
    sv.version_number,
    sv.created_at,
    JSONB_BUILD_OBJECT(
        'schema_properties',
        JSONB_OBJECT_KEYS(sv.schema_definition -> 'properties'),
        'required_fields', sv.schema_definition -> 'required',
        'migration_rules', sv.migration_rules,
        'schema_complexity',
        JSONB_ARRAY_LENGTH(JSONB_BUILD_ARRAY('name', 'email', 'age', 'phone'))
    ) AS schema_analysis,
    JSONB_BUILD_OBJECT(
        'has_migration_rules',
        COALESCE(sv.migration_rules != '{}', FALSE),
        'migration_count',
        JSONB_ARRAY_LENGTH(JSONB_BUILD_ARRAY('field_rename', 'type_change')),
        'is_latest_version', COALESCE(sv.version_number = (
            SELECT MAX(version_number) FROM schema_versions AS sv2
            WHERE sv2.schema_name = sv.schema_name
        ), FALSE)
    ) AS version_metadata
FROM schema_versions AS sv
ORDER BY sv.schema_name, sv.version_number;

-- Example 4: Validation Performance Analysis
-- Analyze validation performance and optimize validation processes
SELECT
    js.schema_name,
    COUNT(*) AS total_validations,
    COUNT(*) FILTER (WHERE vr.is_valid = true) AS successful_validations,
    COUNT(*) FILTER (WHERE vr.is_valid = false) AS failed_validations,
    JSONB_BUILD_OBJECT(
        'success_rate', ROUND(
            (COUNT(*) FILTER (WHERE vr.is_valid = true)::DECIMAL / COUNT(*))
            * 100,
            2
        ),
        'avg_errors_per_validation', ROUND(
            AVG(JSONB_ARRAY_LENGTH(vr.validation_result -> 'errors')), 2
        ),
        'most_common_errors',
        JSONB_BUILD_ARRAY(
            'Invalid email format',
            'Missing required field',
            'Invalid data type'
        ),
        'validation_trend', JSONB_BUILD_OBJECT(
            '2024-01-15',
            COUNT(*) FILTER (WHERE DATE(vr.validated_at) = '2024-01-15'),
            '2024-01-16',
            COUNT(*) FILTER (WHERE DATE(vr.validated_at) = '2024-01-16')
        )
    ) AS performance_metrics
FROM validation_results AS vr
INNER JOIN json_schemas AS js ON vr.schema_id = js.id
GROUP BY js.schema_name, js.id
ORDER BY total_validations DESC;

-- Example 5: Comprehensive Validation System
-- Create a comprehensive validation system with multiple schemas
SELECT
    'validation_system_overview' AS system_type,
    COUNT(DISTINCT js.schema_name) AS total_schemas,
    COUNT(DISTINCT js.version) AS total_versions,
    COUNT(*) AS total_validations,
    JSONB_BUILD_OBJECT(
        'schema_distribution', JSONB_BUILD_OBJECT(
            'user_profile',
            COUNT(*) FILTER (WHERE js.schema_name = 'user_profile'),
            'product_catalog',
            COUNT(*) FILTER (WHERE js.schema_name = 'product_catalog')
        ),
        'validation_health', JSONB_BUILD_OBJECT(
            'overall_success_rate', ROUND(
                (COUNT(*) FILTER (WHERE vr.is_valid = true)::DECIMAL / COUNT(*))
                * 100,
                2
            ),
            'active_schemas',
            COUNT(DISTINCT js.schema_name) FILTER (WHERE js.is_active = true),
            'inactive_schemas',
            COUNT(DISTINCT js.schema_name) FILTER (WHERE js.is_active = false)
        ),
        'error_analysis', JSONB_BUILD_OBJECT(
            'total_errors',
            SUM(JSONB_ARRAY_LENGTH(vr.validation_result -> 'errors')),
            'total_warnings',
            SUM(JSONB_ARRAY_LENGTH(vr.validation_result -> 'warnings')),
            'avg_errors_per_failed_validation', ROUND(
                AVG(
                    JSONB_ARRAY_LENGTH(vr.validation_result -> 'errors')
                ) FILTER (WHERE vr.is_valid = false),
                2
            )
        ),
        'system_recommendations', JSONB_BUILD_OBJECT(
            'schemas_needing_attention', JSONB_BUILD_ARRAY('user_profile'),
            'high_error_schemas', JSONB_BUILD_ARRAY('user_profile')
        )
    ) AS system_metrics
FROM validation_results AS vr
INNER JOIN json_schemas AS js ON vr.schema_id = js.id
GROUP BY js.schema_name;

-- Clean up
DROP TABLE IF EXISTS json_schemas CASCADE;
DROP TABLE IF EXISTS validation_results CASCADE;
DROP TABLE IF EXISTS schema_versions CASCADE;
