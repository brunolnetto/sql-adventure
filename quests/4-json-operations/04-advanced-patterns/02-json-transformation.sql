-- =====================================================
-- JSON Operations quest: JSON Transformation
-- =====================================================
-- 
-- PURPOSE: Demonstrate advanced JSON transformation techniques for
--          data mapping, conversion, and complex transformations
-- LEARNING OUTCOMES:
--   - Transform JSON data between different schemas and formats
--   - Implement data mapping and conversion patterns
--   - Handle complex transformation pipelines
--   - Optimize transformation performance
--   - Build flexible transformation systems
-- EXPECTED RESULTS: Transform JSON data between different formats and schemas
-- DIFFICULTY: 🔴 Advanced (15-20 min)
-- CONCEPTS: Data transformation, mapping, conversion, pipelines, optimization

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS source_data CASCADE;
DROP TABLE IF EXISTS transformation_rules CASCADE;
DROP TABLE IF EXISTS transformed_data CASCADE;

-- Create source data table
CREATE TABLE source_data (
    id INT PRIMARY KEY,
    data_type VARCHAR(50),
    source_json JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create transformation rules table
CREATE TABLE transformation_rules (
    id INT PRIMARY KEY,
    rule_name VARCHAR(100),
    source_schema JSONB,
    target_schema JSONB,
    transformation_mapping JSONB,
    is_active BOOLEAN DEFAULT true
);

-- Create transformed data table
CREATE TABLE transformed_data (
    id INT PRIMARY KEY,
    source_id INT REFERENCES source_data(id),
    rule_id INT REFERENCES transformation_rules(id),
    transformed_json JSONB,
    transformation_metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample source data
INSERT INTO source_data VALUES
(1, 'user_profile', '{
    "user_id": 12345,
    "first_name": "John",
    "last_name": "Doe",
    "email_address": "john.doe@example.com",
    "phone_number": "+1-555-123-4567",
    "date_of_birth": "1990-05-15",
    "home_address": {
        "street_number": "123",
        "street_name": "Main Street",
        "city_name": "New York",
        "state_code": "NY",
        "postal_code": "10001",
        "country_name": "United States"
    },
    "account_preferences": {
        "language_setting": "en_US",
        "timezone_setting": "America/New_York",
        "notification_settings": {
            "email_notifications": true,
            "sms_notifications": false,
            "push_notifications": true
        }
    }
}', '2024-01-15 10:00:00'),
(2, 'product_inventory', '{
    "product_code": "PROD-ABC123",
    "product_name": "Gaming Laptop",
    "product_description": "High-performance gaming laptop with RGB keyboard",
    "price_amount": 1299.99,
    "currency_code": "USD",
    "stock_quantity": 25,
    "category_id": "CAT-001",
    "category_name": "Electronics",
    "supplier_info": {
        "supplier_id": "SUPP-001",
        "supplier_name": "TechCorp Inc",
        "supplier_email": "orders@techcorp.com"
    },
    "technical_specs": {
        "processor_model": "Intel i7-12700H",
        "memory_size": "16GB",
        "storage_capacity": "512GB SSD",
        "graphics_card": "RTX 4060"
    }
}', '2024-01-15 10:01:00'),
(3, 'order_data', '{
    "order_reference": "ORD-2024-001",
    "customer_details": {
        "customer_id": 12345,
        "customer_name": "John Doe",
        "customer_email": "john.doe@example.com"
    },
    "order_items": [
        {
            "item_id": "ITEM-001",
            "item_name": "Gaming Laptop",
            "item_quantity": 1,
            "unit_price": 1299.99,
            "total_price": 1299.99
        },
        {
            "item_id": "ITEM-002",
            "item_name": "Wireless Mouse",
            "item_quantity": 2,
            "unit_price": 45.00,
            "total_price": 90.00
        }
    ],
    "order_summary": {
        "subtotal_amount": 1389.99,
        "tax_amount": 139.00,
        "shipping_amount": 15.00,
        "total_amount": 1543.99
    },
    "shipping_address": {
        "recipient_name": "John Doe",
        "street_address": "123 Main Street",
        "city": "New York",
        "state": "NY",
        "zip_code": "10001",
        "country": "USA"
    }
}', '2024-01-15 10:02:00');

-- Insert transformation rules
INSERT INTO transformation_rules VALUES
(1, 'user_profile_to_api_format', '{
    "type": "object",
    "properties": {
        "user_id": {"type": "integer"},
        "first_name": {"type": "string"},
        "last_name": {"type": "string"},
        "email_address": {"type": "string"},
        "phone_number": {"type": "string"},
        "date_of_birth": {"type": "string"},
        "home_address": {"type": "object"},
        "account_preferences": {"type": "object"}
    }
}', '{
    "type": "object",
    "properties": {
        "id": {"type": "integer"},
        "name": {"type": "string"},
        "email": {"type": "string"},
        "phone": {"type": "string"},
        "age": {"type": "integer"},
        "address": {"type": "object"},
        "preferences": {"type": "object"}
    }
}', '{
    "field_mappings": {
        "user_id": "id",
        "first_name + last_name": "name",
        "email_address": "email",
        "phone_number": "phone",
        "date_of_birth": "age_calculation",
        "home_address": "address_transformation",
        "account_preferences": "preferences_transformation"
    },
    "transformations": {
        "name": "CONCAT(first_name, '' '', last_name)",
        "age_calculation": "EXTRACT(YEAR FROM AGE(CURRENT_DATE, date_of_birth))",
        "address_transformation": {
            "street": "CONCAT(street_number, '' '', street_name)",
            "city": "city_name",
            "state": "state_code",
            "zip": "postal_code",
            "country": "country_name"
        },
        "preferences_transformation": {
            "language": "language_setting",
            "timezone": "timezone_setting",
            "notifications": "notification_settings"
        }
    }
}', true),
(2, 'product_to_catalog_format', '{
    "type": "object",
    "properties": {
        "product_code": {"type": "string"},
        "product_name": {"type": "string"},
        "product_description": {"type": "string"},
        "price_amount": {"type": "number"},
        "currency_code": {"type": "string"},
        "stock_quantity": {"type": "integer"},
        "category_id": {"type": "string"},
        "category_name": {"type": "string"},
        "supplier_info": {"type": "object"},
        "technical_specs": {"type": "object"}
    }
}', '{
    "type": "object",
    "properties": {
        "product_id": {"type": "string"},
        "name": {"type": "string"},
        "description": {"type": "string"},
        "price": {"type": "object"},
        "inventory": {"type": "object"},
        "category": {"type": "object"},
        "specifications": {"type": "object"}
    }
}', '{
    "field_mappings": {
        "product_code": "product_id",
        "product_name": "name",
        "product_description": "description",
        "price_amount + currency_code": "price_object",
        "stock_quantity": "inventory_quantity",
        "category_id + category_name": "category_object",
        "technical_specs": "specifications"
    },
    "transformations": {
        "price_object": {
            "amount": "price_amount",
            "currency": "currency_code",
            "formatted": "CONCAT(currency_code, '' '', price_amount)"
        },
        "inventory_quantity": {
            "quantity": "stock_quantity",
            "status": "CASE WHEN stock_quantity > 0 THEN ''in_stock'' ELSE ''out_of_stock'' END"
        },
        "category_object": {
            "id": "category_id",
            "name": "category_name"
        }
    }
}', true);

-- Insert transformed data
INSERT INTO transformed_data VALUES
(1, 1, 1, '{
    "id": 12345,
    "name": "John Doe",
    "email": "john.doe@example.com",
    "phone": "+1-555-123-4567",
    "age": 33,
    "address": {
        "street": "123 Main Street",
        "city": "New York",
        "state": "NY",
        "zip": "10001",
        "country": "United States"
    },
    "preferences": {
        "language": "en_US",
        "timezone": "America/New_York",
        "notifications": {
            "email_notifications": true,
            "sms_notifications": false,
            "push_notifications": true
        }
    }
}', '{
    "transformation_time": "2024-01-15T10:00:00Z",
    "rule_applied": "user_profile_to_api_format",
    "fields_transformed": 7,
    "validation_status": "success"
}', '2024-01-15 10:00:00'),
(2, 2, 2, '{
    "product_id": "PROD-ABC123",
    "name": "Gaming Laptop",
    "description": "High-performance gaming laptop with RGB keyboard",
    "price": {
        "amount": 1299.99,
        "currency": "USD",
        "formatted": "USD 1299.99"
    },
    "inventory": {
        "quantity": 25,
        "status": "in_stock"
    },
    "category": {
        "id": "CAT-001",
        "name": "Electronics"
    },
    "specifications": {
        "processor_model": "Intel i7-12700H",
        "memory_size": "16GB",
        "storage_capacity": "512GB SSD",
        "graphics_card": "RTX 4060"
    }
}', '{
    "transformation_time": "2024-01-15T10:01:00Z",
    "rule_applied": "product_to_catalog_format",
    "fields_transformed": 6,
    "validation_status": "success"
}', '2024-01-15 10:01:00');

-- Example 1: Basic Field Mapping and Transformation
-- Transform data using field mappings and basic transformations
SELECT 
    sd.id,
    sd.data_type,
    tr.rule_name,
    jsonb_build_object(
        'source_fields', jsonb_object_keys(sd.source_json),
        'target_fields', jsonb_object_keys(td.transformed_json),
        'mapping_applied', tr.transformation_mapping->'field_mappings',
        'transformation_count', (tr.transformation_mapping->'field_mappings')::jsonb
    ) as transformation_info,
    jsonb_build_object(
        'source_size', (SELECT COUNT(*) FROM jsonb_object_keys(sd.source_json)),
        'target_size', (SELECT COUNT(*) FROM jsonb_object_keys(td.transformed_json)),
        'transformation_ratio', ROUND(
            ((SELECT COUNT(*) FROM jsonb_object_keys(td.transformed_json))::DECIMAL / 
             (SELECT COUNT(*) FROM jsonb_object_keys(sd.source_json))) * 100, 2
        )
    ) as transformation_metrics
FROM source_data sd
JOIN transformed_data td ON sd.id = td.source_id
JOIN transformation_rules tr ON td.rule_id = tr.id
ORDER BY sd.created_at;

-- Example 2: Complex Data Transformation
-- Apply complex transformations with nested object restructuring
SELECT 
    sd.id,
    sd.data_type,
    CASE 
        WHEN sd.data_type = 'user_profile' THEN
            jsonb_build_object(
                'original_name', CASE
                    WHEN jsonb_typeof(sd.source_json) = 'object' THEN sd.source_json->>'first_name'
                    ELSE jsonb(sd.source_json)->>'first_name'
                END || ' ' || CASE
                    WHEN jsonb_typeof(sd.source_json) = 'object' THEN sd.source_json->>'last_name'
                    ELSE jsonb(sd.source_json)->>'last_name'
                END,
                'transformed_name', td.transformed_json->>'name',
                'age_calculation', td.transformed_json->>'age',
                'address_transformation', jsonb_build_object(
                    'original', CASE
                        WHEN jsonb_typeof(sd.source_json) = 'object' THEN sd.source_json->'home_address'
                        ELSE jsonb(sd.source_json)->'home_address'
                    END,
                    'transformed', td.transformed_json->'address'
                )
            )
        WHEN sd.data_type = 'product_inventory' THEN
            jsonb_build_object(
                'price_transformation', jsonb_build_object(
                    'original', jsonb_build_object(
                        'amount', CASE
                            WHEN jsonb_typeof(sd.source_json) = 'object' THEN sd.source_json->>'price_amount'
                            ELSE jsonb(sd.source_json)->>'price_amount'
                        END,
                        'currency', CASE
                            WHEN jsonb_typeof(sd.source_json) = 'object' THEN sd.source_json->>'currency_code'
                            ELSE jsonb(sd.source_json)->>'currency_code'
                        END
                    ),
                    'transformed', td.transformed_json->'price'
                ),
                'inventory_status', jsonb_build_object(
                    'original_quantity', CASE
                        WHEN jsonb_typeof(sd.source_json) = 'object' THEN sd.source_json->>'stock_quantity'
                        ELSE jsonb(sd.source_json)->>'stock_quantity'
                    END,
                    'transformed_status', td.transformed_json->'inventory'->>'status'
                )
            )
        ELSE jsonb_build_object('unknown_type', true)
    END as transformation_details
FROM source_data sd
JOIN transformed_data td ON sd.id = td.source_id
ORDER BY sd.created_at;

-- Example 3: Schema Validation and Transformation Pipeline
-- Validate transformations against target schemas
SELECT 
    tr.rule_name,
    tr.source_schema->>'type' as source_type,
    tr.target_schema->>'type' as target_type,
    jsonb_build_object(
        'source_properties', jsonb_object_keys(tr.source_schema->'properties'),
        'target_properties', jsonb_object_keys(tr.target_schema->'properties'),
        'mapping_coverage', ROUND(
            ((SELECT COUNT(*) FROM jsonb_object_keys(tr.transformation_mapping->'field_mappings'))::DECIMAL / 
             (SELECT COUNT(*) FROM jsonb_object_keys(tr.target_schema->'properties'))) * 100, 2
        ),
        'transformation_rules', jsonb_object_keys(tr.transformation_mapping->'transformations')
    ) as schema_analysis,
    jsonb_build_object(
        'is_active', tr.is_active,
        'has_complex_transformations', CASE 
            WHEN tr.transformation_mapping->'transformations' != '{}' THEN true
            ELSE false
        END,
        'transformation_complexity', (SELECT COUNT(*) FROM jsonb_object_keys(tr.transformation_mapping->'transformations'))
    ) as rule_metadata
FROM transformation_rules tr
ORDER BY tr.rule_name;

-- Example 4: Transformation Performance and Optimization
-- Analyze transformation performance and identify optimization opportunities
SELECT 
    'transformation_performance' as analysis_type,
    COUNT(*) as total_transformations,
    jsonb_build_object(
        'performance_metrics', jsonb_build_object(
            'avg_transformation_time', AVG(EXTRACT(EPOCH FROM (td.created_at - sd.created_at))),
            'total_fields_transformed', SUM((td.transformation_metadata->>'fields_transformed')::INT),
            'avg_fields_per_transformation', ROUND(
                AVG((td.transformation_metadata->>'fields_transformed')::INT), 2
            )
        ),
        'rule_performance', jsonb_build_object(
            'user_profile_rule', jsonb_build_object(
                'usage_count', COUNT(*) FILTER (WHERE tr.rule_name = 'user_profile_rule'),
                'avg_fields_transformed', ROUND(
                    AVG((td.transformation_metadata->>'fields_transformed')::INT) FILTER (WHERE tr.rule_name = 'user_profile_rule'), 2
                ),
                'success_rate', ROUND(
                    CASE 
                        WHEN COUNT(*) FILTER (WHERE tr.rule_name = 'user_profile_rule') > 0
                        THEN (COUNT(*) FILTER (WHERE tr.rule_name = 'user_profile_rule' AND td.transformation_metadata->>'validation_status' = 'success')::DECIMAL / 
                             COUNT(*) FILTER (WHERE tr.rule_name = 'user_profile_rule')) * 100
                        ELSE 0
                    END, 2
                )
            ),
            'product_inventory_rule', jsonb_build_object(
                'usage_count', COUNT(*) FILTER (WHERE tr.rule_name = 'product_inventory_rule'),
                'avg_fields_transformed', ROUND(
                    AVG((td.transformation_metadata->>'fields_transformed')::INT) FILTER (WHERE tr.rule_name = 'product_inventory_rule'), 2
                ),
                'success_rate', ROUND(
                    CASE 
                        WHEN COUNT(*) FILTER (WHERE tr.rule_name = 'product_inventory_rule') > 0
                        THEN (COUNT(*) FILTER (WHERE tr.rule_name = 'product_inventory_rule' AND td.transformation_metadata->>'validation_status' = 'success')::DECIMAL / 
                             COUNT(*) FILTER (WHERE tr.rule_name = 'product_inventory_rule')) * 100
                        ELSE 0
                    END, 2
                )
            )
        ),
        'optimization_opportunities', jsonb_build_object(
            'high_usage_rules', jsonb_agg(DISTINCT tr.rule_name) FILTER (
                WHERE tr.rule_name IN (
                    SELECT rule_name FROM (
                        SELECT tr_inner.rule_name, COUNT(*) as usage_count
                        FROM transformed_data td_inner
                        JOIN transformation_rules tr_inner ON td_inner.rule_id = tr_inner.id
                        GROUP BY tr_inner.rule_name
                        HAVING COUNT(*) > (SELECT AVG(rule_count) FROM (
                            SELECT COUNT(*) as rule_count 
                            FROM transformed_data 
                            GROUP BY rule_id
                        ) rule_stats)
                    ) high_usage
                )
            ),
            'complex_transformations', jsonb_agg(DISTINCT tr.rule_name) FILTER (
                WHERE (SELECT COUNT(*) FROM jsonb_object_keys(tr.transformation_mapping->'transformations')) > 3
            )
        )
    ) as performance_analysis
FROM transformed_data td
JOIN source_data sd ON td.source_id = sd.id
JOIN transformation_rules tr ON td.rule_id = tr.id
GROUP BY tr.rule_name;

-- Example 5: Data Quality and Transformation Validation
-- Validate transformation quality and data integrity
SELECT 
    sd.data_type,
    COUNT(*) as transformation_count,
    jsonb_build_object(
        'quality_metrics', jsonb_build_object(
            'successful_transformations', COUNT(*) FILTER (WHERE td.transformation_metadata->>'validation_status' = 'success'),
            'failed_transformations', COUNT(*) FILTER (WHERE td.transformation_metadata->>'validation_status' != 'success'),
            'data_completeness', ROUND(
                (COUNT(*) FILTER (WHERE td.transformed_json IS NOT NULL)::DECIMAL / COUNT(*)) * 100, 2
            )
        ),
        'transformation_quality', jsonb_build_object(
            'avg_fields_preserved', ROUND(
                AVG((td.transformation_metadata->>'fields_transformed')::INT), 2
            ),
            'schema_compliance', jsonb_build_object(
                'valid_schemas', COUNT(*) FILTER (WHERE td.transformed_json ? 'id' OR td.transformed_json ? 'product_id'),
                'missing_required_fields', COUNT(*) FILTER (WHERE NOT (td.transformed_json ? 'id' OR td.transformed_json ? 'product_id'))
            )
        ),
        'data_integrity', jsonb_build_object(
            'null_values', COUNT(*) FILTER (WHERE td.transformed_json IS NULL),
            'empty_objects', COUNT(*) FILTER (WHERE td.transformed_json = '{}'),
            'valid_structures', COUNT(*) FILTER (WHERE jsonb_typeof(td.transformed_json) = 'object')
        )
    ) as quality_analysis
FROM source_data sd
LEFT JOIN transformed_data td ON sd.id = td.source_id
GROUP BY sd.data_type
ORDER BY transformation_count DESC;

-- Clean up
DROP TABLE IF EXISTS source_data CASCADE;
DROP TABLE IF EXISTS transformation_rules CASCADE;
DROP TABLE IF EXISTS transformed_data CASCADE; 