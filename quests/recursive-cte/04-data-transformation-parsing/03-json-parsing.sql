-- =====================================================
-- JSON-like Structure Parsing Example
-- =====================================================

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS json_data CASCADE;

-- Create table to store JSON-like structure in relational form
CREATE TABLE json_data (
    id INT PRIMARY KEY,
    parent_id INT,
    key_name VARCHAR(100),
    value_type VARCHAR(20),
    string_value VARCHAR(500),
    numeric_value DECIMAL(10,2),
    boolean_value BOOLEAN,
    FOREIGN KEY (parent_id) REFERENCES json_data(id)
);

-- Insert sample JSON-like data (representing: {"user": {"name": "John", "age": 30, "active": true, "hobbies": ["reading", "gaming"]}})
INSERT INTO json_data VALUES
(1, NULL, 'user', 'object', NULL, NULL, NULL),
(2, 1, 'name', 'string', 'John', NULL, NULL),
(3, 1, 'age', 'number', NULL, 30, NULL),
(4, 1, 'active', 'boolean', NULL, NULL, TRUE),
(5, 1, 'hobbies', 'array', NULL, NULL, NULL),
(6, 5, '0', 'string', 'reading', NULL, NULL),
(7, 5, '1', 'string', 'gaming', NULL, NULL);

-- Parse and flatten the JSON-like structure
WITH RECURSIVE json_parser AS (
    -- Base case: root objects
    SELECT 
        id,
        parent_id,
        key_name,
        value_type,
        string_value,
        numeric_value,
        boolean_value,
        0 as depth,
        CAST(key_name AS VARCHAR(500)) as path
    FROM json_data
    WHERE parent_id IS NULL
    
    UNION ALL
    
    -- Recursive case: child elements
    SELECT 
        jd.id,
        jd.parent_id,
        jd.key_name,
        jd.value_type,
        jd.string_value,
        jd.numeric_value,
        jd.boolean_value,
        jp.depth + 1,
        CAST(jp.path || '.' || jd.key_name AS VARCHAR(500))
    FROM json_data jd
    INNER JOIN json_parser jp ON jd.parent_id = jp.id
    WHERE jp.depth < 10  -- Limit depth
)
SELECT 
    depth,
    path,
    key_name,
    value_type,
    CASE 
        WHEN value_type = 'string' THEN string_value
        WHEN value_type = 'number' THEN numeric_value::VARCHAR
        WHEN value_type = 'boolean' THEN boolean_value::VARCHAR
        ELSE 'object/array'
    END as value
FROM json_parser
ORDER BY path;

-- Clean up
DROP TABLE IF EXISTS json_data CASCADE; 