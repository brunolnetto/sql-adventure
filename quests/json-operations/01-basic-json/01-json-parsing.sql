-- =====================================================
-- JSON Operations: Basic JSON Parsing
-- =====================================================
-- 
-- PURPOSE: Demonstrate fundamental JSON parsing techniques in PostgreSQL
--          for extracting data from JSON objects, arrays, and nested structures
-- LEARNING OUTCOMES:
--   - Extract values from JSON objects using -> and ->> operators
--   - Parse nested JSON structures and arrays
--   - Handle different JSON data types (strings, numbers, booleans, nulls)
--   - Convert JSON data to PostgreSQL native types
--   - Validate JSON structure and content
-- EXPECTED RESULTS: Extract and parse JSON data from various structures
-- DIFFICULTY: 🟢 Beginner (5-10 min)
-- CONCEPTS: JSON parsing, operators, type casting, nested structures, arrays

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS user_profiles CASCADE;
DROP TABLE IF EXISTS product_catalog CASCADE;

-- Create user profiles table with JSON data
CREATE TABLE user_profiles (
    id INT PRIMARY KEY,
    profile_data JSONB
);

-- Insert sample user profile data
INSERT INTO user_profiles VALUES
(1, '{
    "name": "John Doe",
    "email": "john.doe@example.com",
    "age": 30,
    "is_active": true,
    "preferences": {
        "theme": "dark",
        "notifications": true,
        "language": "en"
    },
    "hobbies": ["reading", "hiking", "photography"]
}'),
(2, '{
    "name": "Jane Smith",
    "email": "jane.smith@example.com",
    "age": 25,
    "is_active": false,
    "preferences": {
        "theme": "light",
        "notifications": false,
        "language": "es"
    },
    "hobbies": ["cooking", "traveling"]
}');

-- Example 1: Basic JSON Value Extraction
-- Extract simple values from JSON objects using -> and ->> operators
SELECT 
    id,
    profile_data->>'name' as user_name,
    profile_data->>'email' as email,
    (profile_data->>'age')::INT as age,
    (profile_data->>'is_active')::BOOLEAN as is_active
FROM user_profiles
ORDER BY id;

-- Example 2: Nested JSON Object Extraction
-- Extract values from nested objects using chained operators
SELECT 
    id,
    profile_data->'preferences'->>'theme' as theme,
    profile_data->'preferences'->>'language' as language,
    (profile_data->'preferences'->>'notifications')::BOOLEAN as notifications_enabled
FROM user_profiles
ORDER BY id;

-- Example 3: JSON Array Handling
-- Extract and work with JSON arrays
SELECT 
    id,
    profile_data->>'name' as user_name,
    profile_data->'hobbies' as hobbies_array,
    jsonb_array_length(profile_data->'hobbies') as hobby_count,
    profile_data->'hobbies'->0 as first_hobby,
    profile_data->'hobbies'->1 as second_hobby
FROM user_profiles
ORDER BY id;

-- Example 4: JSON Type Validation and Conversion
-- Validate and convert JSON data types
SELECT 
    id,
    profile_data->>'name' as name_string,
    CASE 
        WHEN jsonb_typeof(profile_data->'age') = 'number' 
        THEN (profile_data->>'age')::INT 
        ELSE NULL 
    END as age_validated,
    CASE 
        WHEN jsonb_typeof(profile_data->'is_active') = 'boolean' 
        THEN (profile_data->>'is_active')::BOOLEAN 
        ELSE NULL 
    END as is_active_validated,
    CASE 
        WHEN jsonb_typeof(profile_data->'hobbies') = 'array' 
        THEN jsonb_array_length(profile_data->'hobbies') 
        ELSE 0 
    END as hobbies_count
FROM user_profiles
ORDER BY id;

-- Clean up
DROP TABLE IF EXISTS user_profiles CASCADE;
DROP TABLE IF EXISTS product_catalog CASCADE; 