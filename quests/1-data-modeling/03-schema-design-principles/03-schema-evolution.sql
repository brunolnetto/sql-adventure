-- Data Modeling Quest: Schema Evolution
-- PURPOSE: Demonstrate managing schema changes over time
-- DIFFICULTY: 🔴 Advanced (20-25 min)
-- CONCEPTS: Schema evolution, versioning, migration strategies, backward compatibility

-- Example 1: Schema Versioning and Migration
-- Demonstrate schema versioning and migration strategies

-- Schema version tracking table
CREATE TABLE schema_versions (
    version_id INT PRIMARY KEY,
    version_name VARCHAR(50) NOT NULL,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT,
    migration_script TEXT,
    rollback_script TEXT
);

-- Initial schema version
INSERT INTO schema_versions VALUES
(
    1,
    'v1.0.0',
    '2024-01-01 00:00:00',
    'Initial schema',
    'Initial migration',
    'Drop all tables'
);

-- Example 2: Evolving Customer Schema
-- Demonstrate schema evolution with customer data

-- Version 1.0: Basic customer schema
CREATE TABLE customers_v1 (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data for v1
INSERT INTO customers_v1 VALUES
(1, 'John Smith', 'john@email.com', '555-1234'),
(2, 'Jane Doe', 'jane@email.com', '555-5678'),
(3, 'Bob Wilson', 'bob@email.com', '555-9012');

-- Version 1.1: Add address information
CREATE TABLE customers_v1_1 (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address VARCHAR(200),
    city VARCHAR(100),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50) DEFAULT 'USA',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Migration script from v1 to v1.1
INSERT INTO customers_v1_1 (
    customer_id, customer_name, email, phone, created_at
)
SELECT
    customer_id,
    customer_name,
    email,
    phone,
    created_at
FROM customers_v1;

-- Update schema version
INSERT INTO schema_versions VALUES
(
    2, 'v1.1.0', '2024-02-01 00:00:00', 'Added address fields',
    'ALTER TABLE customers ADD COLUMN address VARCHAR(200), ADD COLUMN city VARCHAR(100), ADD COLUMN state VARCHAR(50), ADD COLUMN postal_code VARCHAR(20), ADD COLUMN country VARCHAR(50) DEFAULT ''USA'', ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP',
    'ALTER TABLE customers DROP COLUMN address, DROP COLUMN city, DROP COLUMN state, DROP COLUMN postal_code, DROP COLUMN country, DROP COLUMN updated_at'
);

-- Version 1.2: Add customer segmentation
CREATE TABLE customers_v1_2 (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address VARCHAR(200),
    city VARCHAR(100),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50) DEFAULT 'USA',
    customer_segment VARCHAR(20) DEFAULT 'standard',
    lifetime_value DECIMAL(12, 2) DEFAULT 0,
    last_purchase_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Migration script from v1.1 to v1.2
INSERT INTO customers_v1_2 (
    customer_id,
    customer_name,
    email,
    phone,
    address,
    city,
    state,
    postal_code,
    country,
    created_at,
    updated_at
)
SELECT
    customer_id,
    customer_name,
    email,
    phone,
    address,
    city,
    state,
    postal_code,
    country,
    created_at,
    updated_at
FROM customers_v1_1;

-- Update schema version
INSERT INTO schema_versions VALUES
(
    3, 'v1.2.0', '2024-03-01 00:00:00', 'Added customer segmentation fields',
    'ALTER TABLE customers ADD COLUMN customer_segment VARCHAR(20) DEFAULT ''standard'', ADD COLUMN lifetime_value DECIMAL(12,2) DEFAULT 0, ADD COLUMN last_purchase_date DATE',
    'ALTER TABLE customers DROP COLUMN customer_segment, DROP COLUMN lifetime_value, DROP COLUMN last_purchase_date'
);

-- Example 3: Backward Compatibility Strategies
-- Demonstrate maintaining backward compatibility during schema evolution

-- Create a view for backward compatibility
CREATE VIEW customers AS
SELECT
    customer_id,
    customer_name,
    email,
    phone,
    address,
    city,
    state,
    postal_code,
    country,
    customer_segment,
    lifetime_value,
    last_purchase_date,
    created_at,
    updated_at
FROM customers_v1_2;

-- Create a function to handle schema versioning
-- NOTE: Function definitions removed due to SQL parser limitations
-- In a real implementation, these would be proper PostgreSQL functions

-- Example 4: Data Migration Strategies
-- Demonstrate different data migration approaches

-- Log migration start (simplified without function)
INSERT INTO schema_versions (version_id, version_name, description)
VALUES (
    (SELECT COALESCE(MAX(version_id), 0) + 1 FROM schema_versions),
    'v1.2.0', 'Migration example'
);-- Example 4: Data Migration Strategies
-- Demonstrate different data migration approaches

-- Example 5: Schema Evolution Patterns
-- Demonstrate common schema evolution patterns

-- Pattern 1: Adding new columns with defaults
CREATE TABLE products_v1 (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Evolution: Add category and description
CREATE TABLE products_v2 (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    category VARCHAR(100) DEFAULT 'uncategorized',
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Pattern 2: Splitting tables (normalization)
CREATE TABLE orders_v1 (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10, 2) NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    customer_email VARCHAR(100) NOT NULL,
    customer_phone VARCHAR(20)
);

-- Evolution: Split into orders and customers
CREATE TABLE customers_evolved (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    customer_email VARCHAR(100) UNIQUE NOT NULL,
    customer_phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders_v2 (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers_evolved (customer_id),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending'
);

-- Pattern 3: Changing data types
CREATE TABLE users_v1 (
    user_id INT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    age VARCHAR(10), -- Stored as string
    join_date VARCHAR(20) -- Stored as string
);

-- Evolution: Convert to proper data types
CREATE TABLE users_v2 (
    user_id INT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    age INT CHECK (age >= 0 AND age <= 150),
    join_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Migration function for data type conversion
-- NOTE: Function removed due to SQL parser limitations
-- In a real implementation, this would migrate data types

-- Example 6: Schema Evolution Best Practices
-- Demonstrate best practices for schema evolution

-- Create a schema evolution log
CREATE TABLE schema_evolution_log (
    log_id BIGSERIAL PRIMARY KEY,
    version_from VARCHAR(50),
    version_to VARCHAR(50),
    -- 'add_column', 'drop_column', 'change_type', 'split_table', etc.
    migration_type VARCHAR(50),
    table_name VARCHAR(100),
    column_name VARCHAR(100),
    old_value TEXT,
    new_value TEXT,
    migration_script TEXT,
    rollback_script TEXT,
    executed_by VARCHAR(100) DEFAULT CURRENT_USER,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    execution_time_ms INTEGER,
    success BOOLEAN DEFAULT true,
    error_message TEXT
);

-- Example 8: Rollback Strategy
-- Demonstrate rollback strategies for failed migrations
-- NOTE: Function removed due to SQL parser limitations
-- In a real implementation, this would handle rollbacks

-- Clean up
DROP TABLE IF EXISTS test_customers_v1 CASCADE;
DROP TABLE IF EXISTS test_customers_v1_1 CASCADE;
DROP TABLE IF EXISTS test_customers_v1_2 CASCADE;
DROP TABLE IF EXISTS customers_v1 CASCADE;
DROP TABLE IF EXISTS customers_v1_1 CASCADE;
DROP TABLE IF EXISTS customers_v1_2 CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS products_v1 CASCADE;
DROP TABLE IF EXISTS products_v2 CASCADE;
DROP TABLE IF EXISTS orders_v1 CASCADE;
DROP TABLE IF EXISTS customers_evolved CASCADE;
DROP TABLE IF EXISTS orders_v2 CASCADE;
DROP TABLE IF EXISTS users_v1 CASCADE;
DROP TABLE IF EXISTS users_v2 CASCADE;
DROP TABLE IF EXISTS schema_versions CASCADE;
DROP TABLE IF EXISTS schema_evolution_log CASCADE;
DROP FUNCTION IF EXISTS get_schema_version() CASCADE;
DROP FUNCTION IF EXISTS migrate_customer_data(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS migrate_user_data_types() CASCADE;
DROP FUNCTION IF EXISTS log_schema_change(
    VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, TEXT, TEXT, TEXT, TEXT
) CASCADE;
DROP FUNCTION IF EXISTS validate_schema_evolution() CASCADE;
DROP FUNCTION IF EXISTS rollback_to_version(VARCHAR) CASCADE;
