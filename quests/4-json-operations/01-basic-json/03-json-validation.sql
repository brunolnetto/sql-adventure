-- =====================================================
-- JSON Operations: JSON Validation
-- =====================================================
-- 
-- PURPOSE: Demonstrate JSON validation techniques in PostgreSQL
--          for ensuring data integrity, schema compliance, and error handling
-- LEARNING OUTCOMES:
--   - Validate JSON structure and format
--   - Check data types within JSON objects
--   - Enforce required fields and constraints
--   - Handle validation errors gracefully
--   - Create custom validation rules
-- EXPECTED RESULTS: Validate JSON data integrity and structure
-- DIFFICULTY: 🟢 Beginner (5-10 min)
-- CONCEPTS: JSON validation, schema checking, data type validation, error handling

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS user_data CASCADE;
DROP TABLE IF EXISTS product_data CASCADE;

-- Create user data table with JSON validation
CREATE TABLE user_data (
    id INT PRIMARY KEY,
    user_profile JSONB,
    validation_status VARCHAR(20) DEFAULT 'pending'
);

-- Create product data table
CREATE TABLE product_data (
    id INT PRIMARY KEY,
    product_info JSONB,
    validation_errors TEXT []
);

-- Insert sample data for validation testing
INSERT INTO user_data VALUES
(1, '{
    "name": "John Doe",
    "email": "john.doe@example.com",
    "age": 30,
    "is_active": true,
    "preferences": {
        "theme": "dark",
        "notifications": true
    }
}', 'valid'),
(2, '{
    "name": "Jane Smith",
    "email": "invalid-email",
    "age": "twenty-five",
    "is_active": "yes"
}', 'invalid'),
(3, '{
    "name": "",
    "email": "alice@example.com",
    "age": -5,
    "is_active": true
}', 'invalid');

INSERT INTO product_data VALUES
(1, '{
    "name": "Laptop Pro",
    "price": 1299.99,
    "category": "Electronics",
    "in_stock": true
}', ARRAY[]::TEXT []),
(2, '{
    "name": "Invalid Product",
    "price": -100.00,
    "category": "",
    "in_stock": "maybe"
}', ARRAY['Invalid price', 'Invalid category', 'Invalid stock status']);

-- Example 1: Basic JSON Structure Validation
-- Check if JSON is valid and has required structure
SELECT
    id,
    user_profile,
    CASE
        WHEN user_profile IS NULL THEN 'NULL data'
        WHEN jsonb_typeof(user_profile) != 'object' THEN 'Not an object'
        WHEN NOT (user_profile ? 'name') THEN 'Missing name field'
        WHEN NOT (user_profile ? 'email') THEN 'Missing email field'
        WHEN NOT (user_profile ? 'age') THEN 'Missing age field'
        ELSE 'Valid structure'
    END AS structure_validation
FROM user_data
ORDER BY id;

-- Example 2: Data Type Validation
-- Validate data types within JSON fields
SELECT
    id,
    user_profile ->> 'name' AS name,
    user_profile ->> 'email' AS email,
    user_profile ->> 'age' AS age,
    user_profile ->> 'is_active' AS is_active,
    CASE
        WHEN
            jsonb_typeof(user_profile -> 'name') != 'string'
            THEN 'Name must be string'
        WHEN
            jsonb_typeof(user_profile -> 'email') != 'string'
            THEN 'Email must be string'
        WHEN
            jsonb_typeof(user_profile -> 'age') != 'number'
            THEN 'Age must be number'
        WHEN
            jsonb_typeof(user_profile -> 'is_active') != 'boolean'
            THEN 'Is_active must be boolean'
        ELSE 'Valid data types'
    END AS type_validation
FROM user_data
ORDER BY id;

-- Example 3: Email Format Validation
-- Validate email format using regex
SELECT
    id,
    user_profile ->> 'email' AS email,
    CASE
        WHEN
            user_profile ->> 'email'
            ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
            THEN 'Valid email format'
        ELSE 'Invalid email format'
    END AS email_validation
FROM user_data
WHERE user_profile ? 'email'
ORDER BY id;

-- Example 4: Required Field Validation
-- Check for required fields and their values
SELECT
    id,
    user_profile,
    CASE
        WHEN user_profile ->> 'name' IS NULL OR user_profile ->> 'name' = ''
            THEN 'Name is required and cannot be empty'
        WHEN user_profile ->> 'email' IS NULL OR user_profile ->> 'email' = ''
            THEN 'Email is required and cannot be empty'
        WHEN user_profile ->> 'age' IS NULL
            THEN 'Age is required'
        ELSE 'All required fields present'
    END AS required_field_validation
FROM user_data
ORDER BY id;

-- Example 5: Product Data Validation
-- Comprehensive validation for product information
SELECT
    id,
    product_info ->> 'name' AS product_name,
    product_info ->> 'price' AS price,
    product_info ->> 'category' AS category,
    CASE
        WHEN product_info ->> 'name' IS NULL OR product_info ->> 'name' = ''
            THEN 'Product name is required'
        WHEN (product_info ->> 'price')::DECIMAL <= 0
            THEN 'Price must be positive'
        WHEN
            product_info ->> 'category' IS NULL
            OR product_info ->> 'category' = ''
            THEN 'Category is required'
        WHEN jsonb_typeof(product_info -> 'in_stock') != 'boolean'
            THEN 'In_stock must be boolean'
        ELSE 'Valid product data'
    END AS product_validation
FROM product_data
ORDER BY id;

-- Clean up
DROP TABLE IF EXISTS user_data CASCADE;
DROP TABLE IF EXISTS product_data CASCADE;
