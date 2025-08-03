-- =====================================================
-- JSON Operations: Nested Extraction
-- =====================================================
-- 
-- PURPOSE: Demonstrate advanced JSON querying techniques in PostgreSQL
--          for extracting data from deeply nested structures and complex paths
-- LEARNING OUTCOMES:
--   - Extract data from deeply nested JSON objects
--   - Use path expressions for complex queries
--   - Handle conditional nested extraction
--   - Process complex nested arrays
--   - Analyze nested structure relationships
-- EXPECTED RESULTS: Extract data from complex nested JSON structures
-- DIFFICULTY: 🟡 Intermediate (10-15 min)
-- CONCEPTS: Deep nested extraction, path expressions, complex queries, conditional logic

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS ecommerce_data CASCADE;

-- Create ecommerce data table with deeply nested JSON
CREATE TABLE ecommerce_data (
    id INT PRIMARY KEY,
    order_data JSONB
);

-- Insert sample ecommerce data with complex nested structures
INSERT INTO ecommerce_data VALUES
(1, '{
    "order_id": "ORD-001",
    "customer": {
        "id": 1001,
        "name": "John Doe",
        "contact": {
            "email": "john.doe@example.com",
            "phone": "+1-555-123-4567",
            "address": {
                "street": "123 Main St",
                "city": "New York",
                "state": "NY",
                "zip": "10001"
            }
        },
        "preferences": {
            "language": "en",
            "currency": "USD",
            "notifications": {
                "email": true,
                "sms": false,
                "push": true
            }
        }
    },
    "items": [
        {
            "product_id": "PROD-001",
            "name": "Laptop Pro",
            "category": {
                "id": "CAT-001",
                "name": "Electronics"
            },
            "pricing": {
                "base_price": 1200.00,
                "discount": {
                    "type": "percentage",
                    "value": 10
                },
                "final_price": 1080.00
            }
        }
    ],
    "shipping": {
        "method": "express",
        "address": {
            "street": "123 Main St",
            "city": "New York",
            "state": "NY"
        },
        "cost": 15.00
    }
}'),
(2, '{
    "order_id": "ORD-002",
    "customer": {
        "id": 1002,
        "name": "Jane Smith",
        "contact": {
            "email": "jane.smith@example.com",
            "phone": "+1-555-987-6543",
            "address": {
                "street": "456 Oak Ave",
                "city": "Los Angeles",
                "state": "CA",
                "zip": "90210"
            }
        },
        "preferences": {
            "language": "en",
            "currency": "USD",
            "notifications": {
                "email": true,
                "sms": true,
                "push": false
            }
        }
    },
    "items": [
        {
            "product_id": "PROD-002",
            "name": "Coffee Maker",
            "category": {
                "id": "CAT-002",
                "name": "Kitchen"
            },
            "pricing": {
                "base_price": 89.99,
                "discount": null,
                "final_price": 89.99
            }
        }
    ],
    "shipping": {
        "method": "standard",
        "address": {
            "street": "456 Oak Ave",
            "city": "Los Angeles",
            "state": "CA"
        },
        "cost": 8.00
    }
}');

-- Example 1: Deep Nested Object Extraction
-- Extract customer information from deeply nested structures
SELECT 
    id,
    order_data->>'order_id' as order_id,
    order_data->'customer'->>'name' as customer_name,
    order_data->'customer'->'contact'->>'email' as customer_email,
    order_data->'customer'->'contact'->'address'->>'city' as customer_city,
    order_data->'customer'->'preferences'->>'currency' as preferred_currency
FROM ecommerce_data
ORDER BY id;

-- Example 2: Path-based JSON Querying
-- Use path expressions to extract data at specific paths
SELECT 
    id,
    order_data->>'order_id' as order_id,
    order_data #>> '{customer,contact,phone}' as customer_phone,
    order_data #>> '{customer,contact,address,state}' as customer_state,
    order_data #>> '{shipping,method}' as shipping_method,
    order_data #>> '{shipping,address,city}' as shipping_city
FROM ecommerce_data
ORDER BY id;

-- Example 3: Conditional Nested Extraction
-- Extract data conditionally based on nested structure
SELECT 
    id,
    order_data->>'order_id' as order_id,
    order_data->'customer'->>'name' as customer_name,
    CASE 
        WHEN order_data->'customer'->'preferences'->'notifications'->>'email' = 'true' 
        THEN 'Email notifications enabled'
        ELSE 'Email notifications disabled'
    END as email_status,
    CASE 
        WHEN order_data->'customer'->'preferences'->'notifications'->>'sms' = 'true' 
        THEN 'SMS notifications enabled'
        ELSE 'SMS notifications disabled'
    END as sms_status
FROM ecommerce_data
ORDER BY id;

-- Example 4: Array Element Filtering and Extraction
-- Extract specific elements from nested arrays
SELECT 
    id,
    order_data->>'order_id' as order_id,
    jsonb_array_length(order_data->'items') as item_count,
    order_data->'items'->0->>'name' as first_item_name,
    order_data->'items'->0->'category'->>'name' as first_item_category,
    order_data->'items'->0->'pricing'->>'final_price' as first_item_price
FROM ecommerce_data
ORDER BY id;

-- Example 5: Complex Nested Structure Analysis
-- Analyze relationships within nested structures
SELECT 
    id,
    order_data->>'order_id' as order_id,
    order_data->'customer'->>'name' as customer_name,
    jsonb_array_length(order_data->'items') as total_items,
    (SELECT jsonb_agg(item->>'name') 
     FROM jsonb_array_elements(order_data->'items') as item) as all_item_names,
    (SELECT jsonb_agg((item->'pricing'->>'final_price')::DECIMAL(10,2)) 
     FROM jsonb_array_elements(order_data->'items') as item) as all_prices
FROM ecommerce_data
ORDER BY id;

-- Clean up
DROP TABLE IF EXISTS ecommerce_data CASCADE; 