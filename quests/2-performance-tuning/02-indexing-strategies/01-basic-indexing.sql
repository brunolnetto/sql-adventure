-- =====================================================
-- Performance Tuning: Basic Indexing Strategies
-- =====================================================
-- 
-- PURPOSE: Demonstrate fundamental indexing strategies in PostgreSQL
--          for improving query performance and data access patterns
-- LEARNING OUTCOMES:
--   - Understand when and how to create indexes
--   - Choose appropriate index types for different scenarios
--   - Analyze index usage and effectiveness
--   - Optimize queries with proper indexing
--   - Monitor index performance and maintenance
-- EXPECTED RESULTS: Improve query performance through strategic indexing
-- DIFFICULTY: 🟡 Intermediate (10-15 min)
-- CONCEPTS: Index creation, index types, query optimization, performance analysis

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;

-- Create customers table
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    registration_date DATE,
    status VARCHAR(20),
    city VARCHAR(50),
    country VARCHAR(50)
);

-- Create products table
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10, 2),
    created_date DATE,
    is_active BOOLEAN DEFAULT true
);

-- Create orders table
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers (customer_id),
    product_id INT REFERENCES products (product_id),
    quantity INT,
    order_date DATE,
    total_amount DECIMAL(10, 2),
    status VARCHAR(20)
);

-- Insert sample data
INSERT INTO customers (
    first_name, last_name, email, registration_date, status, city, country
) VALUES
(
    'John',
    'Doe',
    'john.doe@email.com',
    '2023-01-15',
    'active',
    'New York',
    'USA'
),
(
    'Jane',
    'Smith',
    'jane.smith@email.com',
    '2023-02-20',
    'active',
    'Los Angeles',
    'USA'
),
(
    'Bob',
    'Johnson',
    'bob.johnson@email.com',
    '2023-03-10',
    'inactive',
    'Chicago',
    'USA'
),
(
    'Alice',
    'Brown',
    'alice.brown@email.com',
    '2023-04-05',
    'active',
    'Toronto',
    'Canada'
),
(
    'Charlie',
    'Wilson',
    'charlie.wilson@email.com',
    '2023-05-12',
    'active',
    'London',
    'UK'
);

INSERT INTO products (name, category, price, created_date, is_active) VALUES
('Laptop Pro', 'Electronics', 1200.00, '2023-01-01', true),
('Wireless Mouse', 'Electronics', 45.00, '2023-01-15', true),
('Office Chair', 'Furniture', 299.99, '2023-02-01', true),
('Desk Lamp', 'Furniture', 89.99, '2023-02-15', true),
('Gaming Keyboard', 'Electronics', 150.00, '2023-03-01', true);

INSERT INTO orders (
    customer_id, product_id, quantity, order_date, total_amount, status
) VALUES
(1, 1, 1, '2024-01-15', 1200.00, 'completed'),
(1, 2, 2, '2024-01-16', 90.00, 'completed'),
(2, 3, 1, '2024-01-17', 299.99, 'pending'),
(3, 1, 1, '2024-01-18', 1200.00, 'completed'),
(3, 4, 1, '2024-01-19', 89.99, 'completed'),
(4, 5, 1, '2024-01-20', 150.00, 'completed'),
(5, 2, 3, '2024-01-21', 135.00, 'pending');

-- Example 1: Basic Single-Column Index
-- Create index on frequently queried column
CREATE INDEX idx_customers_email ON customers (email);

-- Query that benefits from the index
SELECT
    customer_id,
    first_name,
    last_name,
    email
FROM customers
WHERE email = 'john.doe@email.com';

-- Example 2: Composite Index for Multi-Column Queries
-- Create composite index for queries with multiple WHERE conditions
CREATE INDEX idx_orders_customer_date ON orders (customer_id, order_date);

-- Query that benefits from composite index
SELECT
    o.order_id,
    o.order_date,
    o.total_amount,
    c.first_name,
    c.last_name
FROM orders AS o
INNER JOIN customers AS c ON o.customer_id = c.customer_id
WHERE o.customer_id = 1 AND o.order_date >= '2024-01-01';

-- Example 3: Partial Index for Filtered Data
-- Create index only on active products
CREATE INDEX idx_products_active ON products (product_id, name, price)
WHERE is_active = true;

-- Query that benefits from partial index
SELECT
    product_id,
    name,
    price
FROM products
WHERE is_active = true AND price > 100;

-- Example 4: Index on Expression
-- Create index on computed expression
CREATE INDEX idx_customers_name_lower ON customers (
    LOWER(first_name || ' ' || last_name)
);

-- Query that benefits from expression index
SELECT
    customer_id,
    first_name,
    last_name,
    email
FROM customers
WHERE LOWER(first_name || ' ' || last_name) = 'john doe';

-- Example 5: Unique Index for Data Integrity
-- Create unique index on combination of columns
CREATE UNIQUE INDEX idx_customers_name_city ON customers (
    first_name, last_name, city
);

-- Query to test unique constraint
SELECT
    first_name,
    last_name,
    city,
    COUNT(*)
FROM customers
GROUP BY first_name, last_name, city
HAVING COUNT(*) > 1;

-- Example 6: Index Analysis and Usage
-- Analyze index usage and effectiveness
-- Note: This query requires specific PostgreSQL configuration and may not work in all environments
-- Skipping this query to avoid compatibility issues

-- Clean up
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS products CASCADE;
