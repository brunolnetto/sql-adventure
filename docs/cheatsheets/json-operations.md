# JSON Operations Cheatsheet 🎯

Your complete guide to mastering modern PostgreSQL JSON operations for handling semi-structured data and API responses.

## 🎯 **Core Concepts**

### **JSON Data Types**
```sql
-- JSON (text-based, preserves whitespace and key order)
CREATE TABLE json_example (
    id INT PRIMARY KEY,
    data JSON
);

-- JSONB (binary format, more efficient, no whitespace/order preservation)
CREATE TABLE jsonb_example (
    id INT PRIMARY KEY,
    data JSONB
);
```

### **JSON vs JSONB**
- **JSON**: Text format, preserves formatting, slower operations
- **JSONB**: Binary format, faster operations, supports indexing, no formatting preservation

---

## 🔍 **1. JSON Parsing & Extraction**

### **Basic Extraction Operators**
```sql
-- Extract JSON object field (returns JSON)
SELECT data->'name' as name_json FROM users;

-- Extract JSON object field as text (returns TEXT)
SELECT data->>'name' as name_text FROM users;

-- Extract nested field
SELECT data->'address'->'city' as city_json FROM users;
SELECT data->'address'->>'city' as city_text FROM users;

-- Extract array element
SELECT data->'tags'->0 as first_tag FROM products;
SELECT data->'tags'->>0 as first_tag_text FROM products;
```

### **Path Extraction**
```sql
-- Extract using path notation
SELECT data#>>'{address,city}' as city FROM users;
SELECT data#>>'{tags,0}' as first_tag FROM products;

-- Extract multiple levels
SELECT 
    data->>'name' as name,
    data->'address'->>'city' as city,
    data->'address'->>'country' as country
FROM users;
```

### **Type Checking**
```sql
-- Check JSON type
SELECT 
    jsonb_typeof(data->'name') as name_type,
    jsonb_typeof(data->'age') as age_type,
    jsonb_typeof(data->'tags') as tags_type
FROM users;

-- Conditional extraction based on type
SELECT 
    CASE 
        WHEN jsonb_typeof(data->'value') = 'number' 
        THEN (data->>'value')::numeric
        ELSE NULL 
    END as numeric_value
FROM measurements;
```

---

## 🏗️ **2. JSON Generation**

### **Building JSON Objects**
```sql
-- Create JSON object from columns
SELECT 
    jsonb_build_object(
        'id', user_id,
        'name', user_name,
        'email', email,
        'active', is_active
    ) as user_json
FROM users;

-- Create JSON with computed values
SELECT 
    jsonb_build_object(
        'product_id', product_id,
        'name', product_name,
        'price', price,
        'discounted_price', price * 0.9,
        'in_stock', stock_quantity > 0
    ) as product_json
FROM products;
```

### **Building JSON Arrays**
```sql
-- Create array from column values
SELECT 
    jsonb_agg(product_name) as product_names
FROM products;

-- Create array of objects
SELECT 
    jsonb_agg(
        jsonb_build_object(
            'id', product_id,
            'name', product_name,
            'price', price
        )
    ) as products_json
FROM products;

-- Create array with conditions
SELECT 
    jsonb_agg(
        jsonb_build_object(
            'id', product_id,
            'name', product_name
        )
    ) FILTER (WHERE price < 100) as affordable_products
FROM products;
```

### **JSON Concatenation**
```sql
-- Merge JSON objects
SELECT 
    jsonb_build_object('id', user_id) || 
    jsonb_build_object('name', user_name) as user_data
FROM users;

-- Combine arrays
SELECT 
    jsonb_agg(tag) || jsonb_agg(category) as all_tags
FROM product_tags;
```

---

## ✅ **3. JSON Validation**

### **Schema Validation**
```sql
-- Check if JSON has required fields
SELECT 
    data->>'name' IS NOT NULL as has_name,
    data->>'email' IS NOT NULL as has_email,
    data->'address' IS NOT NULL as has_address
FROM users;

-- Validate JSON structure
SELECT 
    jsonb_typeof(data->'name') = 'string' as name_is_string,
    jsonb_typeof(data->'age') = 'number' as age_is_number,
    jsonb_typeof(data->'tags') = 'array' as tags_is_array
FROM users;
```

### **Data Type Validation**
```sql
-- Validate email format
SELECT 
    data->>'email' ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' as valid_email
FROM users;

-- Validate numeric range
SELECT 
    (data->>'age')::int BETWEEN 0 AND 150 as valid_age
FROM users;

-- Validate array length
SELECT 
    jsonb_array_length(data->'tags') <= 10 as valid_tag_count
FROM products;
```

---

## 🔧 **4. Array Operations**

### **Array Functions**
```sql
-- Get array length
SELECT 
    jsonb_array_length(data->'tags') as tag_count
FROM products;

-- Check if array contains value
SELECT 
    data->'tags' ? 'electronics' as has_electronics_tag
FROM products;

-- Check if array contains any value from list
SELECT 
    data->'tags' ?| ARRAY['electronics', 'computers'] as has_tech_tag
FROM products;

-- Check if array contains all values from list
SELECT 
    data->'tags' ?& ARRAY['electronics', 'wireless'] as has_all_tags
FROM products;
```

### **Array Manipulation**
```sql
-- Add element to array
SELECT 
    data || jsonb_build_object('tags', data->'tags' || '"new_tag"'::jsonb) as updated_data
FROM products;

-- Remove element from array
SELECT 
    data - 'tags' as data_without_tags
FROM products;

-- Filter array elements
SELECT 
    jsonb_path_query_array(data->'tags', '$[*] ? (@ like_regex "tech")') as tech_tags
FROM products;
```

---

## 🌍 **5. Real-World Applications**

### **API Data Processing**
```sql
-- Process API response
WITH api_data AS (
    SELECT '{
        "users": [
            {"id": 1, "name": "John", "email": "john@example.com"},
            {"id": 2, "name": "Jane", "email": "jane@example.com"}
        ],
        "total": 2,
        "page": 1
    }'::jsonb as response
)
SELECT 
    jsonb_array_elements(response->'users') as user_data,
    response->>'total' as total_users,
    response->>'page' as current_page
FROM api_data;

-- Extract user information
SELECT 
    user_data->>'id' as user_id,
    user_data->>'name' as user_name,
    user_data->>'email' as user_email
FROM api_data,
     jsonb_array_elements(response->'users') as user_data;
```

### **Configuration Management**
```sql
-- Store application configuration
CREATE TABLE app_config (
    config_key VARCHAR(100) PRIMARY KEY,
    config_value JSONB
);

INSERT INTO app_config VALUES
('database', '{"host": "localhost", "port": 5432, "ssl": true}'),
('email', '{"smtp_server": "smtp.gmail.com", "port": 587, "tls": true}'),
('features', '{"dark_mode": true, "notifications": false, "analytics": true}');

-- Query configuration
SELECT 
    config_key,
    config_value->>'host' as db_host,
    config_value->>'port' as db_port
FROM app_config 
WHERE config_key = 'database';
```

### **Log Analysis**
```sql
-- Process log entries
CREATE TABLE log_entries (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP,
    log_data JSONB
);

-- Query logs by severity
SELECT 
    timestamp,
    log_data->>'message' as message,
    log_data->>'level' as severity
FROM log_entries 
WHERE log_data->>'level' = 'ERROR';

-- Analyze log patterns
SELECT 
    log_data->>'level' as severity,
    COUNT(*) as count,
    AVG((log_data->>'response_time')::numeric) as avg_response_time
FROM log_entries 
GROUP BY log_data->>'level';
```

---

## ⚡ **6. Advanced Patterns**

### **JSON Path Queries**
```sql
-- Complex path queries
SELECT 
    jsonb_path_query(data, '$.users[*] ? (@.age > 25)') as adult_users
FROM user_data;

-- Nested object queries
SELECT 
    jsonb_path_query(data, '$.orders[*] ? (@.items[*] ? (@.category == "electronics")).id') as electronics_orders
FROM order_data;

-- Array filtering
SELECT 
    jsonb_path_query_array(data->'products', '$[*] ? (@.price < 100)') as affordable_products
FROM catalog_data;
```

### **JSON Transformation**
```sql
-- Transform JSON structure
SELECT 
    jsonb_build_object(
        'user_id', data->>'id',
        'full_name', data->>'first_name' || ' ' || data->>'last_name',
        'contact', jsonb_build_object(
            'email', data->>'email',
            'phone', data->>'phone'
        ),
        'metadata', jsonb_build_object(
            'created_at', data->>'created_at',
            'last_login', data->>'last_login'
        )
    ) as transformed_data
FROM users;

-- Flatten nested JSON
SELECT 
    jsonb_build_object(
        'id', data->>'id',
        'name', data->>'name',
        'city', data->'address'->>'city',
        'country', data->'address'->>'country',
        'street', data->'address'->>'street'
    ) as flattened_data
FROM users;
```

---

## 🔧 **7. Performance Optimization**

### **JSONB Indexing**
```sql
-- GIN index for full-text search
CREATE INDEX idx_users_data_gin ON users USING gin(data);

-- GIN index for specific keys
CREATE INDEX idx_users_name_gin ON users USING gin((data->'name'));

-- B-tree index for specific values
CREATE INDEX idx_users_email_btree ON users ((data->>'email'));

-- Partial index for specific conditions
CREATE INDEX idx_active_users ON users ((data->>'status')) 
WHERE data->>'status' = 'active';
```

### **Query Optimization**
```sql
-- Use JSONB instead of JSON for better performance
-- Index frequently queried paths
-- Use containment operators (? and ?&) for efficient searches
-- Avoid extracting large JSON objects unnecessarily

-- Efficient query example
SELECT id, data->>'name' as name
FROM users 
WHERE data->'tags' ? 'premium'
  AND (data->>'age')::int > 25;
```

---

## 🚀 **8. Best Practices**

### **Data Design**
```sql
-- Use JSONB for better performance
-- Keep JSON structure consistent
-- Validate data at application level
-- Use appropriate data types within JSON

-- Good structure example
{
    "id": 123,
    "name": "Product Name",
    "price": 99.99,
    "tags": ["electronics", "wireless"],
    "metadata": {
        "created_at": "2024-01-01T00:00:00Z",
        "updated_at": "2024-01-02T00:00:00Z"
    }
}
```

### **Query Patterns**
```sql
-- Extract specific fields when possible
SELECT data->>'name' as name FROM users;

-- Use containment for array searches
SELECT * FROM products WHERE data->'tags' ? 'electronics';

-- Validate before casting
SELECT 
    CASE 
        WHEN jsonb_typeof(data->'price') = 'number' 
        THEN (data->>'price')::numeric 
        ELSE NULL 
    END as price
FROM products;
```

### **Error Handling**
```sql
-- Safe extraction with defaults
SELECT 
    COALESCE(data->>'name', 'Unknown') as name,
    COALESCE((data->>'age')::int, 0) as age
FROM users;

-- Validate JSON structure
SELECT 
    CASE 
        WHEN data ? 'name' AND data ? 'email' 
        THEN 'valid' 
        ELSE 'invalid' 
    END as validation_status
FROM users;
```

---

## 📊 **9. Common Use Cases**

### **E-commerce Product Data**
```sql
-- Store flexible product attributes
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200),
    price DECIMAL(10,2),
    attributes JSONB
);

-- Query by attributes
SELECT name, price
FROM products 
WHERE attributes->>'brand' = 'Apple'
  AND (attributes->>'storage')::int >= 256;

-- Search in arrays
SELECT name, price
FROM products 
WHERE attributes->'colors' ? 'blue'
  AND attributes->'sizes' ? 'large';
```

### **User Preferences**
```sql
-- Store user preferences
CREATE TABLE user_preferences (
    user_id INT PRIMARY KEY,
    preferences JSONB
);

-- Query user settings
SELECT 
    user_id,
    preferences->>'theme' as theme,
    preferences->>'language' as language,
    preferences->>'notifications' as notifications_enabled
FROM user_preferences 
WHERE preferences->>'theme' = 'dark';
```

---

---

## 🔬 **Advanced Patterns**

### **Complex JSON Data Pipeline**
```sql
-- Process complex API responses with nested data
WITH api_data AS (
    SELECT 
        response_id,
        response_data,
        -- Extract user information
        response_data->>'user_id' as user_id,
        response_data->>'session_id' as session_id,
        -- Extract nested metadata
        response_data->'metadata'->>'source' as data_source,
        response_data->'metadata'->>'version' as api_version,
        -- Extract array of events
        jsonb_array_elements(response_data->'events') as event
    FROM api_responses
    WHERE response_data ? 'user_id'
),
processed_events AS (
    SELECT 
        response_id,
        user_id,
        session_id,
        data_source,
        api_version,
        -- Extract event details
        event->>'type' as event_type,
        event->>'timestamp' as event_timestamp,
        (event->>'value')::DECIMAL(10,2) as event_value,
        -- Extract nested event metadata
        event->'metadata'->>'category' as event_category,
        event->'metadata'->>'priority' as event_priority,
        -- Extract tags array
        jsonb_array_elements_text(event->'tags') as tag
    FROM api_data
)
SELECT 
    user_id,
    session_id,
    event_type,
    event_category,
    event_priority,
    tag,
    event_value,
    COUNT(*) OVER (PARTITION BY user_id, session_id) as session_event_count,
    SUM(event_value) OVER (PARTITION BY user_id, session_id) as session_total_value
FROM processed_events
WHERE event_timestamp >= CURRENT_TIMESTAMP - INTERVAL '1 hour'
ORDER BY user_id, event_timestamp;
```

### **JSON Schema Validation and Transformation**
```sql
-- Validate and transform JSON data
WITH validation_results AS (
    SELECT 
        data_id,
        json_data,
        -- Validate required fields
        CASE 
            WHEN json_data ? 'id' AND json_data ? 'name' AND json_data ? 'email' 
            THEN true ELSE false 
        END as has_required_fields,
        -- Validate data types
        CASE 
            WHEN jsonb_typeof(json_data->'id') = 'number' 
            AND jsonb_typeof(json_data->'name') = 'string'
            AND jsonb_typeof(json_data->'email') = 'string'
            THEN true ELSE false 
        END as has_correct_types,
        -- Validate email format (basic)
        CASE 
            WHEN json_data->>'email' ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
            THEN true ELSE false 
        END as has_valid_email,
        -- Extract and transform data
        (json_data->>'id')::INT as user_id,
        UPPER(json_data->>'name') as user_name,
        LOWER(json_data->>'email') as user_email,
        -- Extract optional fields with defaults
        COALESCE(json_data->>'phone', 'N/A') as phone,
        COALESCE(json_data->'preferences'->>'theme', 'default') as theme,
        -- Extract array length
        jsonb_array_length(COALESCE(json_data->'tags', '[]'::jsonb)) as tag_count
    FROM user_data
)
SELECT 
    data_id,
    user_id,
    user_name,
    user_email,
    phone,
    theme,
    tag_count,
    -- Validation status
    CASE 
        WHEN has_required_fields AND has_correct_types AND has_valid_email 
        THEN 'Valid' ELSE 'Invalid' 
    END as validation_status,
    -- Error details
    CASE 
        WHEN NOT has_required_fields THEN 'Missing required fields'
        WHEN NOT has_correct_types THEN 'Invalid data types'
        WHEN NOT has_valid_email THEN 'Invalid email format'
        ELSE 'OK'
    END as error_details
FROM validation_results
ORDER BY validation_status, data_id;
```

### **JSON Aggregation and Analytics**
```sql
-- Advanced JSON aggregation with analytics
WITH json_analytics AS (
    SELECT 
        category,
        -- Aggregate JSON objects
        jsonb_build_object(
            'total_products', COUNT(*),
            'avg_price', AVG((attributes->>'price')::DECIMAL(10,2)),
            'price_range', jsonb_build_object(
                'min', MIN((attributes->>'price')::DECIMAL(10,2)),
                'max', MAX((attributes->>'price')::DECIMAL(10,2))
            ),
            'brands', jsonb_object_agg(
                attributes->>'brand', 
                COUNT(*) FILTER (WHERE attributes->>'brand' IS NOT NULL)
            ),
            'features', jsonb_object_agg(
                feature.key, feature.value
            ) FILTER (WHERE feature.key IS NOT NULL)
        ) as category_summary,
        -- Extract and aggregate features
        jsonb_array_elements(attributes->'features') as feature
    FROM products
    WHERE attributes ? 'price'
    GROUP BY category
),
feature_analysis AS (
    SELECT 
        category,
        category_summary,
        -- Analyze feature distribution
        jsonb_object_agg(
            feature->>'name',
            jsonb_build_object(
                'count', COUNT(*),
                'percentage', ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY category), 2)
            )
        ) as feature_distribution
    FROM json_analytics
    WHERE feature ? 'name'
    GROUP BY category, category_summary
)
SELECT 
    category,
    category_summary->>'total_products' as total_products,
    category_summary->>'avg_price' as avg_price,
    category_summary->'price_range'->>'min' as min_price,
    category_summary->'price_range'->>'max' as max_price,
    category_summary->'brands' as brand_distribution,
    feature_distribution
FROM feature_analysis
ORDER BY (category_summary->>'total_products')::INT DESC;
```

### **Real-time JSON Processing**
```sql
-- Real-time JSON event processing
WITH event_stream AS (
    SELECT 
        event_id,
        event_data,
        event_timestamp,
        -- Extract event details
        event_data->>'event_type' as event_type,
        event_data->>'user_id' as user_id,
        event_data->>'session_id' as session_id,
        -- Extract metrics
        (event_data->>'duration')::INT as duration,
        (event_data->>'value')::DECIMAL(10,2) as value,
        -- Extract context
        event_data->'context'->>'page_url' as page_url,
        event_data->'context'->>'user_agent' as user_agent,
        -- Extract custom properties
        event_data->'properties' as properties
    FROM real_time_events
    WHERE event_timestamp >= CURRENT_TIMESTAMP - INTERVAL '15 minutes'
),
session_analytics AS (
    SELECT 
        user_id,
        session_id,
        event_type,
        page_url,
        duration,
        value,
        event_timestamp,
        -- Session-level metrics
        COUNT(*) OVER (PARTITION BY user_id, session_id) as session_event_count,
        SUM(duration) OVER (PARTITION BY user_id, session_id) as session_duration,
        SUM(value) OVER (PARTITION BY user_id, session_id) as session_value,
        -- Real-time trends
        AVG(value) OVER (
            ORDER BY event_timestamp 
            ROWS BETWEEN 99 PRECEDING AND CURRENT ROW
        ) as global_value_trend,
        -- User behavior patterns
        jsonb_object_agg(
            event_type, 
            COUNT(*) FILTER (WHERE event_type IS NOT NULL)
        ) OVER (PARTITION BY user_id, session_id) as event_type_distribution
    FROM event_stream
)
SELECT 
    user_id,
    session_id,
    event_type,
    page_url,
    duration,
    value,
    session_event_count,
    session_duration,
    session_value,
    global_value_trend,
    event_type_distribution,
    -- Real-time alerts
    CASE 
        WHEN session_duration > 3600 THEN 'Long Session'
        WHEN session_value > global_value_trend * 3 THEN 'High Value Session'
        WHEN session_event_count > 50 THEN 'High Activity Session'
        ELSE 'Normal Session'
    END as session_alert
FROM session_analytics
ORDER BY event_timestamp DESC;
```

---

*Follow this cheatsheet to master modern PostgreSQL JSON operations! 🎯* 