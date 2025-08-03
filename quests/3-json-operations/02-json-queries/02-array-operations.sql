-- =====================================================
-- JSON Operations: Array Operations
-- =====================================================
-- 
-- PURPOSE: Demonstrate advanced array manipulation techniques in PostgreSQL
--          for filtering, transforming, and analyzing JSON arrays
-- LEARNING OUTCOMES:
--   - Filter and select array elements based on conditions
--   - Transform array data using various functions
--   - Aggregate and analyze array contents
--   - Perform complex array operations
--   - Handle nested arrays and multi-dimensional data
-- EXPECTED RESULTS: Manipulate and analyze JSON array data
-- DIFFICULTY: 🟡 Intermediate (10-15 min)
-- CONCEPTS: Array manipulation, filtering, aggregation, transformation, nested arrays

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS product_inventory CASCADE;

-- Create product inventory table with array data
CREATE TABLE product_inventory (
    id INT PRIMARY KEY,
    product_data JSONB
);

-- Insert sample product data with complex arrays
INSERT INTO product_inventory VALUES
(1, '{
    "product_id": "PROD-001",
    "name": "Gaming Laptop",
    "tags": ["gaming", "laptop", "high-performance", "rgb"],
    "specifications": {
        "processor": "Intel i9",
        "ram": "32GB",
        "storage": "1TB SSD"
    },
    "prices": [
        {"region": "US", "amount": 2499.99, "currency": "USD"},
        {"region": "EU", "amount": 2299.99, "currency": "EUR"},
        {"region": "UK", "amount": 1999.99, "currency": "GBP"}
    ],
    "reviews": [
        {"user": "gamer123", "rating": 5, "comment": "Amazing performance!"},
        {"user": "techguru", "rating": 4, "comment": "Great but expensive"},
        {"user": "student", "rating": 3, "comment": "Good for gaming, heavy for school"}
    ],
    "variants": [
        {"color": "black", "in_stock": true, "quantity": 15},
        {"color": "white", "in_stock": false, "quantity": 0},
        {"color": "red", "in_stock": true, "quantity": 8}
    ]
}'),
(2, '{
    "product_id": "PROD-002",
    "name": "Wireless Headphones",
    "tags": ["audio", "wireless", "noise-cancelling", "bluetooth"],
    "specifications": {
        "brand": "AudioTech",
        "type": "Over-ear",
        "battery_life": "30 hours"
    },
    "prices": [
        {"region": "US", "amount": 299.99, "currency": "USD"},
        {"region": "EU", "amount": 279.99, "currency": "EUR"}
    ],
    "reviews": [
        {"user": "musiclover", "rating": 5, "comment": "Perfect sound quality"},
        {"user": "traveler", "rating": 5, "comment": "Great noise cancellation"}
    ],
    "variants": [
        {"color": "black", "in_stock": true, "quantity": 25},
        {"color": "blue", "in_stock": true, "quantity": 12}
    ]
}');

-- Example 1: Array Element Filtering and Selection
-- Filter array elements based on conditions
SELECT 
    id,
    product_data->>'name' as product_name,
    product_data->'tags' as all_tags,
    (SELECT jsonb_agg(tag) 
     FROM jsonb_array_elements_text(product_data->'tags') as tag 
     WHERE tag LIKE '%gaming%' OR tag LIKE '%audio%') as filtered_tags,
    (SELECT jsonb_agg(variant) 
     FROM jsonb_array_elements(product_data->'variants') as variant 
     WHERE (variant->>'in_stock')::BOOLEAN = true) as available_variants
FROM product_inventory
ORDER BY id;

-- Example 2: Array Aggregation and Analysis
-- Analyze array contents and perform aggregations
SELECT 
    id,
    product_data->>'name' as product_name,
    jsonb_array_length(product_data->'tags') as tag_count,
    jsonb_array_length(product_data->'reviews') as review_count,
    jsonb_array_length(product_data->'variants') as variant_count,
    (SELECT AVG((review->>'rating')::INT) 
     FROM jsonb_array_elements(product_data->'reviews') as review) as avg_rating,
    (SELECT COUNT(*) 
     FROM jsonb_array_elements(product_data->'variants') as variant 
     WHERE (variant->>'in_stock')::BOOLEAN = true) as available_variants_count
FROM product_inventory
ORDER BY id;

-- Example 3: Array Transformation and Mapping
-- Transform array data using various functions
SELECT 
    id,
    product_data->>'name' as product_name,
    (SELECT jsonb_agg(
        jsonb_build_object(
            'tag', tag,
            'tag_length', LENGTH(tag),
            'is_short', CASE WHEN LENGTH(tag) <= 6 THEN true ELSE false END
        )
    ) FROM jsonb_array_elements_text(product_data->'tags') as tag) as transformed_tags,
    (SELECT jsonb_agg(
        jsonb_build_object(
            'region', price->>'region',
            'amount_formatted', '$' || (price->>'amount')::DECIMAL(10,2),
            'is_expensive', CASE WHEN (price->>'amount')::DECIMAL(10,2) > 1000 THEN true ELSE false END
        )
    ) FROM jsonb_array_elements(product_data->'prices') as price) as transformed_prices
FROM product_inventory
ORDER BY id;

-- Example 4: Complex Array Operations
-- Perform complex operations on nested arrays
SELECT 
    id,
    product_data->>'name' as product_name,
    (SELECT jsonb_agg(
        jsonb_build_object(
            'reviewer', review->>'user',
            'rating', review->>'rating',
            'comment_length', LENGTH(review->>'comment'),
            'is_positive', CASE WHEN (review->>'rating')::INT >= 4 THEN true ELSE false END
        )
    ) FROM jsonb_array_elements(product_data->'reviews') as review) as analyzed_reviews,
    (SELECT jsonb_agg(
        jsonb_build_object(
            'color', variant->>'color',
            'stock_status', CASE 
                WHEN (variant->>'in_stock')::BOOLEAN = true THEN 'Available'
                ELSE 'Out of Stock'
            END,
            'quantity_level', CASE 
                WHEN (variant->>'quantity')::INT > 20 THEN 'High'
                WHEN (variant->>'quantity')::INT > 10 THEN 'Medium'
                ELSE 'Low'
            END
        )
    ) FROM jsonb_array_elements(product_data->'variants') as variant) as analyzed_variants
FROM product_inventory
ORDER BY id;

-- Example 5: Array Filtering with Complex Conditions
-- Filter arrays based on multiple conditions
SELECT 
    id,
    product_data->>'name' as product_name,
    (SELECT jsonb_agg(review) 
     FROM jsonb_array_elements(product_data->'reviews') as review 
     WHERE (review->>'rating')::INT >= 4 
       AND LENGTH(review->>'comment') > 10) as high_quality_reviews,
    (SELECT jsonb_agg(price) 
     FROM jsonb_array_elements(product_data->'prices') as price 
     WHERE (price->>'amount')::DECIMAL(10,2) < 1000 
       AND price->>'currency' = 'USD') as affordable_us_prices,
    (SELECT jsonb_agg(variant) 
     FROM jsonb_array_elements(product_data->'variants') as variant 
     WHERE (variant->>'in_stock')::BOOLEAN = true 
       AND (variant->>'quantity')::INT > 10) as well_stocked_variants
FROM product_inventory
ORDER BY id;

-- Clean up
DROP TABLE IF EXISTS product_inventory CASCADE; 