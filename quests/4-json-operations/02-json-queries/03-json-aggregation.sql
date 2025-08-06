-- =====================================================
-- JSON Operations: JSON Aggregation
-- =====================================================
-- 
-- PURPOSE: Demonstrate advanced JSON aggregation techniques in PostgreSQL
--          for grouping, analyzing, and summarizing JSON data
-- LEARNING OUTCOMES:
--   - Aggregate JSON data using various functions
--   - Perform grouped JSON analysis
--   - Create statistical summaries of JSON data
--   - Build complex aggregation patterns
--   - Generate comprehensive JSON reports
-- EXPECTED RESULTS: Aggregate and analyze JSON data for insights
-- DIFFICULTY: 🟡 Intermediate (10-15 min)
-- CONCEPTS: JSON aggregation, grouping, statistical analysis, complex patterns, reporting

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS sales_transactions CASCADE;
DROP TABLE IF EXISTS customer_interactions CASCADE;

-- Create sales transactions table with JSON data
CREATE TABLE sales_transactions (
    id INT PRIMARY KEY,
    transaction_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample sales transaction data
INSERT INTO sales_transactions (id, transaction_data) VALUES
(1, '{
    "transaction_id": "TXN-001",
    "customer": {
        "id": 1001,
        "name": "John Doe",
        "segment": "premium",
        "location": "New York"
    },
    "items": [
        {"product_id": "PROD-001", "name": "Laptop", "category": "Electronics", "price": 1200.00, "quantity": 1},
        {"product_id": "PROD-002", "name": "Mouse", "category": "Accessories", "price": 45.00, "quantity": 2}
    ],
    "payment": {
        "method": "credit_card",
        "amount": 1290.00,
        "currency": "USD"
    },
    "metadata": {
        "channel": "online",
        "campaign": "summer_sale",
        "discount_applied": 50.00
    }
}'),
(2, '{
    "transaction_id": "TXN-002",
    "customer": {
        "id": 1002,
        "name": "Jane Smith",
        "segment": "regular",
        "location": "Los Angeles"
    },
    "items": [
        {"product_id": "PROD-003", "name": "Headphones", "category": "Audio", "price": 299.99, "quantity": 1}
    ],
    "payment": {
        "method": "paypal",
        "amount": 299.99,
        "currency": "USD"
    },
    "metadata": {
        "channel": "mobile",
        "campaign": "new_user",
        "discount_applied": 0.00
    }
}'),
(3, '{
    "transaction_id": "TXN-003",
    "customer": {
        "id": 1003,
        "name": "Bob Johnson",
        "segment": "premium",
        "location": "Chicago"
    },
    "items": [
        {"product_id": "PROD-001", "name": "Laptop", "category": "Electronics", "price": 1200.00, "quantity": 1},
        {"product_id": "PROD-004", "name": "Keyboard", "category": "Accessories", "price": 150.00, "quantity": 1}
    ],
    "payment": {
        "method": "credit_card",
        "amount": 1350.00,
        "currency": "USD"
    },
    "metadata": {
        "channel": "online",
        "campaign": "premium_bundle",
        "discount_applied": 100.00
    }
}');

-- Create customer interactions table
CREATE TABLE customer_interactions (
    id INT PRIMARY KEY,
    customer_id INT,
    interaction_data JSONB,
    interaction_date DATE
);

-- Insert sample customer interaction data
INSERT INTO customer_interactions VALUES
(1, 1001, '{
    "interaction_type": "purchase",
    "products": ["PROD-001", "PROD-002"],
    "total_value": 1290.00,
    "satisfaction_score": 5,
    "feedback": "Great experience!"
}', '2024-01-15'),
(2, 1001, '{
    "interaction_type": "support",
    "issue": "delivery_delay",
    "resolution_time": 24,
    "satisfaction_score": 4,
    "feedback": "Issue resolved quickly"
}', '2024-01-16'),
(3, 1002, '{
    "interaction_type": "purchase",
    "products": ["PROD-003"],
    "total_value": 299.99,
    "satisfaction_score": 5,
    "feedback": "Excellent product quality"
}', '2024-01-15'),
(4, 1003, '{
    "interaction_type": "purchase",
    "products": ["PROD-001", "PROD-004"],
    "total_value": 1350.00,
    "satisfaction_score": 5,
    "feedback": "Perfect bundle deal"
}', '2024-01-17');

-- Example 1: Basic JSON Aggregation
-- Aggregate JSON data using basic functions
SELECT
    transaction_data -> 'customer' ->> 'segment' AS customer_segment,
    COUNT(*) AS transaction_count,
    SUM((transaction_data -> 'payment' ->> 'amount')::DECIMAL(10, 2))
        AS total_revenue,
    AVG((transaction_data -> 'payment' ->> 'amount')::DECIMAL(10, 2))
        AS avg_transaction_value,
    JSONB_AGG(transaction_data ->> 'transaction_id') AS transaction_ids
FROM sales_transactions
GROUP BY transaction_data -> 'customer' ->> 'segment'
ORDER BY total_revenue DESC;

-- Example 2: Complex JSON Aggregation with Nested Data
-- Aggregate complex nested JSON structures
SELECT
    transaction_data -> 'customer' ->> 'location' AS customer_location,
    transaction_data -> 'payment' ->> 'method' AS payment_method,
    COUNT(*) AS transaction_count,
    SUM((transaction_data -> 'payment' ->> 'amount')::DECIMAL(10, 2))
        AS total_revenue,
    JSONB_AGG(
        JSONB_BUILD_OBJECT(
            'transaction_id', transaction_data ->> 'transaction_id',
            'customer_name', transaction_data -> 'customer' ->> 'name',
            'amount', transaction_data -> 'payment' ->> 'amount',
            'item_count', JSONB_ARRAY_LENGTH(transaction_data -> 'items')
        )
    ) AS transaction_details
FROM sales_transactions
GROUP BY
    transaction_data -> 'customer' ->> 'location',
    transaction_data -> 'payment' ->> 'method'
ORDER BY total_revenue DESC;

-- Example 3: JSON Array Aggregation
-- Aggregate data from JSON arrays
SELECT
    transaction_data -> 'customer' ->> 'segment' AS customer_segment,
    COUNT(*) AS transaction_count,
    JSONB_AGG(DISTINCT item ->> 'category') AS unique_categories,
    JSONB_AGG(
        JSONB_BUILD_OBJECT(
            'product', item ->> 'name',
            'category', item ->> 'category',
            'price', item ->> 'price',
            'quantity', item ->> 'quantity'
        )
    ) AS all_items,
    SUM((item ->> 'price')::DECIMAL(10, 2) * (item ->> 'quantity')::INT)
        AS total_item_value
FROM sales_transactions,
    JSONB_ARRAY_ELEMENTS(transaction_data -> 'items') AS item
GROUP BY transaction_data -> 'customer' ->> 'segment'
ORDER BY total_item_value DESC;

-- Example 4: Statistical Aggregation of JSON Data
-- Perform statistical analysis on JSON data
SELECT
    transaction_data -> 'customer' ->> 'segment' AS customer_segment,
    COUNT(*) AS transaction_count,
    JSONB_BUILD_OBJECT(
        'total_revenue',
        SUM((transaction_data -> 'payment' ->> 'amount')::DECIMAL(10, 2)),
        'avg_transaction',
        AVG((transaction_data -> 'payment' ->> 'amount')::DECIMAL(10, 2)),
        'min_transaction',
        MIN((transaction_data -> 'payment' ->> 'amount')::DECIMAL(10, 2)),
        'max_transaction',
        MAX((transaction_data -> 'payment' ->> 'amount')::DECIMAL(10, 2))
    ) AS revenue_stats,
    JSONB_BUILD_OBJECT(
        'total_discount',
        SUM(
            (transaction_data -> 'metadata' ->> 'discount_applied')::DECIMAL(
                10, 2
            )
        ),
        'avg_discount',
        AVG(
            (transaction_data -> 'metadata' ->> 'discount_applied')::DECIMAL(
                10, 2
            )
        )
    ) AS discount_stats
FROM sales_transactions
GROUP BY transaction_data -> 'customer' ->> 'segment'
ORDER BY (JSONB_BUILD_OBJECT(
    'total_revenue',
    SUM((transaction_data -> 'payment' ->> 'amount')::DECIMAL(10, 2))
)) ->> 'total_revenue' DESC;

-- Example 5: Customer Behavior Aggregation
-- Aggregate customer interaction data
SELECT
    customer_id,
    COUNT(*) AS interaction_count,
    JSONB_AGG(DISTINCT interaction_data ->> 'interaction_type')
        AS interaction_types,
    JSONB_BUILD_OBJECT(
        'total_purchases',
        COUNT(*) FILTER (
            WHERE interaction_data ->> 'interaction_type' = 'purchase'
        ),
        'total_support',
        COUNT(*) FILTER (
            WHERE interaction_data ->> 'interaction_type' = 'support'
        ),
        'avg_satisfaction',
        AVG((interaction_data ->> 'satisfaction_score')::INT),
        'total_value', SUM((interaction_data ->> 'total_value')::DECIMAL(10, 2))
    ) AS interaction_summary,
    JSONB_AGG(
        JSONB_BUILD_OBJECT(
            'date', interaction_date,
            'type', interaction_data ->> 'interaction_type',
            'satisfaction', interaction_data ->> 'satisfaction_score',
            'feedback', interaction_data ->> 'feedback'
        )
    ) AS detailed_interactions
FROM customer_interactions
GROUP BY customer_id
ORDER BY (JSONB_BUILD_OBJECT(
    'total_value', SUM((interaction_data ->> 'total_value')::DECIMAL(10, 2))
)) ->> 'total_value' DESC;

-- Clean up
DROP TABLE IF EXISTS sales_transactions CASCADE;
DROP TABLE IF EXISTS customer_interactions CASCADE;
