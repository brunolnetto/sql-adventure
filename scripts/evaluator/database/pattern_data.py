#!/usr/bin/env python3
"""
Enhanced SQL Pattern definitions for SQL Adventure evaluator.
Unified pattern catalog with regex patterns, descriptions, and examples.
"""

SQL_PATTERNS = [
    # DDL Patterns
    {
        "name": "table_creation",
        "display_name": "Table Creation",
        "description": "Creating tables with CREATE TABLE statements including column definitions, data types, and constraints",
        "category": "DDL",
        "complexity_level": "Basic",
        "regex_pattern": r'CREATE\s+TABLE',
        "base_description": "CREATE TABLE statements with column definitions, data types, and constraints",
        "examples": ["CREATE TABLE users (id INT PRIMARY KEY, name VARCHAR(50))", "CREATE TABLE products (product_id SERIAL, price DECIMAL(10,2))"]
    },
    {
        "name": "index_creation",
        "display_name": "Index Creation",
        "description": "Creating indexes for query performance optimization using CREATE INDEX statements",
        "category": "DDL",
        "complexity_level": "Intermediate",
        "regex_pattern": r'CREATE\s+(UNIQUE\s+)?INDEX',
        "base_description": "CREATE INDEX statements for query performance optimization",
        "examples": ["CREATE INDEX idx_user_email ON users(email)", "CREATE UNIQUE INDEX idx_product_sku ON products(sku)"]
    },
    {
        "name": "constraint_definition",
        "display_name": "Constraint Definition",
        "description": "Defining table constraints including PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK, and NOT NULL",
        "category": "DDL",
        "complexity_level": "Intermediate",
        "regex_pattern": r'CONSTRAINT|PRIMARY\s+KEY|FOREIGN\s+KEY|UNIQUE|CHECK',
        "base_description": "Table constraints including PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK, NOT NULL",
        "examples": ["ALTER TABLE orders ADD CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES customers(id)", "CHECK (price > 0)"]
    },
    {
        "name": "view_creation",
        "display_name": "View Creation",
        "description": "Creating virtual tables using CREATE VIEW statements for data abstraction and simplification",
        "category": "DDL",
        "complexity_level": "Intermediate",
        "regex_pattern": r'CREATE\s+(OR\s+REPLACE\s+)?VIEW',
        "base_description": "CREATE VIEW statements for virtual tables and data abstraction",
        "examples": ["CREATE VIEW active_users AS SELECT * FROM users WHERE is_active = true", "CREATE OR REPLACE VIEW customer_summary AS SELECT customer_id, SUM(total) FROM orders GROUP BY customer_id"]
    },
    {
        "name": "schema_creation",
        "display_name": "Schema Creation",
        "description": "Creating database schemas for organizing and grouping database objects",
        "category": "DDL",
        "complexity_level": "Intermediate",
        "regex_pattern": r'CREATE\s+SCHEMA',
        "base_description": "CREATE SCHEMA statements for organizing database objects",
        "examples": ["CREATE SCHEMA sales", "CREATE SCHEMA hr AUTHORIZATION admin"]
    },

    # DML Patterns
    {
        "name": "data_insertion",
        "display_name": "Data Insertion",
        "description": "Inserting new records into tables using INSERT INTO statements",
        "category": "DML",
        "complexity_level": "Basic",
        "regex_pattern": r'INSERT\s+INTO',
        "base_description": "INSERT INTO statements for adding new records to tables",
        "examples": ["INSERT INTO users (name, email) VALUES ('John', 'john@email.com')", "INSERT INTO products SELECT * FROM temp_products"]
    },
    {
        "name": "data_update",
        "display_name": "Data Update",
        "description": "Modifying existing records using UPDATE statements with WHERE conditions",
        "category": "DML",
        "complexity_level": "Basic",
        "regex_pattern": r'UPDATE\s+',
        "base_description": "UPDATE statements for modifying existing records",
        "examples": ["UPDATE users SET email = 'new@email.com' WHERE id = 1", "UPDATE products SET price = price * 1.1 WHERE category = 'electronics'"]
    },
    {
        "name": "data_deletion",
        "display_name": "Data Deletion",
        "description": "Removing records from tables using DELETE FROM statements",
        "category": "DML",
        "complexity_level": "Basic",
        "regex_pattern": r'DELETE\s+FROM',
        "base_description": "DELETE FROM statements for removing records from tables",
        "examples": ["DELETE FROM users WHERE last_login < '2023-01-01'", "DELETE FROM orders WHERE status = 'cancelled'"]
    },
    {
        "name": "data_upsert",
        "display_name": "Data Upsert",
        "description": "Insert or update operations using INSERT with ON CONFLICT or MERGE statements",
        "category": "DML",
        "complexity_level": "Intermediate",
        "regex_pattern": r'INSERT\s+.*ON\s+CONFLICT|MERGE\s+INTO',
        "base_description": "INSERT with ON CONFLICT or MERGE statements for upsert operations",
        "examples": ["INSERT INTO users (id, name) VALUES (1, 'John') ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name", "MERGE INTO inventory USING updates ON inventory.id = updates.id WHEN MATCHED THEN UPDATE SET quantity = updates.quantity"]
    },

    # DQL Patterns
    {
        "name": "simple_select",
        "display_name": "Simple SELECT",
        "description": "Basic SELECT queries with WHERE, ORDER BY, and LIMIT clauses",
        "category": "DQL",
        "complexity_level": "Basic",
        "regex_pattern": r'SELECT\s+.*FROM',
        "base_description": "Basic SELECT statements with WHERE, ORDER BY, LIMIT clauses",
        "examples": ["SELECT name, email FROM users WHERE is_active = true", "SELECT * FROM products ORDER BY price DESC LIMIT 10"]
    },
    {
        "name": "joins",
        "display_name": "Table Joins",
        "description": "Joining multiple tables using INNER, LEFT, RIGHT, FULL OUTER, and CROSS JOIN operations",
        "category": "DQL",
        "complexity_level": "Intermediate",
        "regex_pattern": r'(INNER|LEFT|RIGHT|FULL|CROSS)\s+JOIN',
        "base_description": "INNER, LEFT, RIGHT, FULL OUTER, and CROSS JOIN operations",
        "examples": ["SELECT u.name, o.total FROM users u JOIN orders o ON u.id = o.user_id", "LEFT JOIN products p ON oi.product_id = p.id"]
    },
    {
        "name": "aggregation",
        "display_name": "Aggregation Functions",
        "description": "Using aggregate functions like COUNT, SUM, AVG, MIN, MAX with GROUP BY and HAVING",
        "category": "DQL",
        "complexity_level": "Intermediate",
        "regex_pattern": r'GROUP\s+BY|HAVING',
        "base_description": "GROUP BY, HAVING, and aggregate functions (COUNT, SUM, AVG, MAX, MIN)",
        "examples": ["SELECT category, AVG(price) FROM products GROUP BY category", "SELECT user_id, COUNT(*) FROM orders GROUP BY user_id HAVING COUNT(*) > 5"]
    },
    {
        "name": "subqueries",
        "display_name": "Subqueries",
        "description": "Nested SELECT statements within other SQL statements for complex queries",
        "category": "DQL",
        "complexity_level": "Advanced",
        "regex_pattern": r'SELECT\s+.*SELECT',
        "base_description": "Nested SELECT statements within other SQL statements",
        "examples": ["SELECT * FROM users WHERE id IN (SELECT user_id FROM orders WHERE total > 100)", "SELECT name FROM products WHERE price > (SELECT AVG(price) FROM products)"]
    },
    {
        "name": "window_functions",
        "display_name": "Window Functions",
        "description": "Using window functions with OVER clause including ROW_NUMBER, RANK, LEAD, LAG",
        "category": "DQL",
        "complexity_level": "Advanced",
        "regex_pattern": r'OVER\s*\(',
        "base_description": "OVER clause with ROW_NUMBER, RANK, LEAD, LAG, and partition operations",
        "examples": ["SELECT name, salary, ROW_NUMBER() OVER (ORDER BY salary DESC) FROM employees", "LAG(price) OVER (PARTITION BY category ORDER BY date)"]
    },
    {
        "name": "cte",
        "display_name": "Common Table Expressions",
        "description": "Using WITH clauses for temporary named result sets and query organization",
        "category": "DQL",
        "complexity_level": "Advanced",
        "regex_pattern": r'WITH\s+',
        "base_description": "WITH clauses for temporary named result sets and query organization",
        "examples": ["WITH high_value_customers AS (SELECT user_id FROM orders GROUP BY user_id HAVING SUM(total) > 1000)", "WITH RECURSIVE employee_hierarchy AS (SELECT id, name, manager_id FROM employees WHERE manager_id IS NULL UNION ALL SELECT e.id, e.name, e.manager_id FROM employees e JOIN employee_hierarchy eh ON e.manager_id = eh.id)"]
    },
    {
        "name": "recursive_cte",
        "display_name": "Recursive CTE",
        "description": "Using WITH RECURSIVE for hierarchical data traversal and graph operations",
        "category": "DQL",
        "complexity_level": "Expert",
        "regex_pattern": r'WITH\s+RECURSIVE',
        "base_description": "WITH RECURSIVE for hierarchical data traversal and graph operations",
        "examples": ["WITH RECURSIVE employee_hierarchy AS (SELECT id, name, manager_id FROM employees WHERE manager_id IS NULL UNION ALL SELECT e.id, e.name, e.manager_id FROM employees e JOIN employee_hierarchy eh ON e.manager_id = eh.id)", "WITH RECURSIVE path_finder AS (SELECT id, name, parent_id, name::text as path FROM categories WHERE parent_id IS NULL UNION ALL SELECT c.id, c.name, c.parent_id, pf.path || ' > ' || c.name FROM categories c JOIN path_finder pf ON c.parent_id = pf.id)"]
    },

    # Analytics Patterns
    {
        "name": "explain_plan",
        "display_name": "EXPLAIN Plan",
        "description": "Using EXPLAIN and EXPLAIN ANALYZE for query performance analysis and optimization",
        "category": "ANALYTICS",
        "complexity_level": "Intermediate",
        "regex_pattern": r'EXPLAIN',
        "base_description": "EXPLAIN and EXPLAIN ANALYZE for query performance analysis",
        "examples": ["EXPLAIN SELECT * FROM users WHERE email = 'test@example.com'", "EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE created_at >= '2024-01-01'"]
    },
    {
        "name": "index_usage",
        "display_name": "Index Usage",
        "description": "Query optimization techniques that effectively utilize database indexes",
        "category": "ANALYTICS",
        "complexity_level": "Intermediate",
        "regex_pattern": r'INDEX|USING\s+INDEX',
        "base_description": "Query optimization techniques using indexes effectively",
        "examples": ["SELECT * FROM products WHERE category = 'electronics' -- uses idx_products_category", "WHERE date_created >= '2024-01-01' -- uses idx_products_date"]
    },
    {
        "name": "query_optimization",
        "display_name": "Query Optimization",
        "description": "Advanced query optimization techniques including EXISTS vs IN and subquery to JOIN conversions",
        "category": "ANALYTICS",
        "complexity_level": "Advanced",
        "regex_pattern": r'OPTIMIZATION|HINT',
        "base_description": "Performance tuning through query rewriting and optimization techniques",
        "examples": ["SELECT * FROM users u WHERE EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id AND o.total > 100)", "SELECT u.name FROM users u JOIN orders o ON u.id = o.user_id WHERE o.total > 100"]
    },

    # JSON Patterns
    {
        "name": "json_parsing",
        "display_name": "JSON Parsing",
        "description": "Extracting data from JSON columns using JSON operators like ->, ->>, #>, #>>",
        "category": "JSON",
        "complexity_level": "Intermediate",
        "regex_pattern": r'->|->>|#>>|#>',
        "base_description": "JSON operators (->, ->>, #>, #>>) for extracting data from JSON columns",
        "examples": ["SELECT data->>'name' FROM users WHERE data->>'age' > '25'", "SELECT jsonb_extract_path(config, 'database', 'host') FROM settings"]
    },
    {
        "name": "json_aggregation",
        "display_name": "JSON Aggregation",
        "description": "Creating JSON objects and arrays from query results using JSON_AGG and JSON_OBJECT_AGG",
        "category": "JSON",
        "complexity_level": "Advanced",
        "regex_pattern": r'JSON_|json_',
        "base_description": "JSON_AGG, JSON_OBJECT_AGG for converting relational data to JSON format",
        "examples": ["SELECT JSON_AGG(name) FROM users", "SELECT JSON_OBJECT_AGG(id, name) FROM products"]
    },
    {
        "name": "json_construction",
        "display_name": "JSON Construction",
        "description": "Constructing JSON data using functions like TO_JSON and JSON_BUILD_OBJECT",
        "category": "JSON",
        "complexity_level": "Intermediate",
        "regex_pattern": r'TO_JSON|JSON_BUILD',
        "base_description": "JSON construction functions for creating JSON data",
        "examples": ["SELECT TO_JSON(users) FROM users", "SELECT JSON_BUILD_OBJECT('name', name, 'email', email) FROM users"]
    },

    # Advanced Patterns
    {
        "name": "full_text_search",
        "display_name": "Full Text Search",
        "description": "PostgreSQL full-text search using tsvector, tsquery, and ranking functions",
        "category": "DQL",
        "complexity_level": "Advanced",
        "regex_pattern": r'@@|to_tsvector|to_tsquery',
        "base_description": "PostgreSQL full-text search with tsvector, tsquery, and ranking",
        "examples": ["SELECT * FROM articles WHERE to_tsvector(title || ' ' || content) @@ to_tsquery('database & optimization')", "CREATE INDEX idx_articles_search ON articles USING gin(to_tsvector('english', title || ' ' || content))"]
    },
    {
        "name": "array_operations",
        "display_name": "Array Operations",
        "description": "PostgreSQL array operations including creation, indexing, searching, and aggregation",
        "category": "DQL",
        "complexity_level": "Intermediate",
        "regex_pattern": r'ARRAY|unnest|array_',
        "base_description": "PostgreSQL array data type operations: creation, indexing, searching, and aggregation",
        "examples": ["SELECT * FROM products WHERE tags @> ARRAY['electronics', 'mobile']", "SELECT UNNEST(string_to_array(categories, ',')) as category FROM products"]
    },
    {
        "name": "temporal_queries",
        "display_name": "Temporal Queries",
        "description": "Date and time operations using INTERVAL, DATE_TRUNC, and EXTRACT functions",
        "category": "DQL",
        "complexity_level": "Intermediate",
        "regex_pattern": r'INTERVAL|DATE_TRUNC|EXTRACT',
        "base_description": "Date and time operations, intervals, and temporal data analysis",
        "examples": ["SELECT * FROM orders WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'", "DATE_TRUNC('month', order_date)"]
    },
    {
        "name": "geospatial",
        "display_name": "Geospatial Queries",
        "description": "Spatial queries using PostGIS functions for geographic data analysis",
        "category": "DQL",
        "complexity_level": "Expert",
        "regex_pattern": r'ST_|geometry|geography',
        "base_description": "PostGIS spatial queries for geographic data analysis and location-based operations",
        "examples": ["SELECT * FROM stores WHERE ST_DWithin(location, ST_Point(-122.4194, 37.7749), 1000)", "SELECT ST_Area(ST_Transform(geometry, 3857)) FROM parcels"]
    }
]
