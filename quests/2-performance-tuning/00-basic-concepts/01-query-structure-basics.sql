-- =====================================================
-- Performance Tuning Quest: Query Structure Basics
-- =====================================================
-- 
-- PURPOSE: Demonstrate fundamental query structure optimization for beginners
-- DIFFICULTY: 🟢 Beginner (5-10 min)
-- CONCEPTS: SELECT optimization, WHERE clause efficiency, basic query structure

-- Example 1: Optimizing SELECT Statements
-- Demonstrate the importance of selecting only needed columns

-- Create sample tables
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT REFERENCES customers (customer_id),
    order_date DATE,
    total_amount DECIMAL(10, 2),
    status VARCHAR(20),
    shipping_address TEXT,
    billing_address TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO customers VALUES
(
    1,
    'John',
    'Doe',
    'john@email.com',
    '555-1234',
    '123 Main St',
    'New York',
    'NY',
    '10001',
    'USA'
),
(
    2,
    'Jane',
    'Smith',
    'jane@email.com',
    '555-5678',
    '456 Oak Ave',
    'Los Angeles',
    'CA',
    '90210',
    'USA'
),
(
    3,
    'Bob',
    'Wilson',
    'bob@email.com',
    '555-9012',
    '789 Pine St',
    'Chicago',
    'IL',
    '60601',
    'USA'
);

INSERT INTO orders VALUES
(
    1,
    1,
    '2024-01-15',
    150.00,
    'completed',
    '123 Main St',
    '123 Main St',
    'Customer requested fast shipping'
),
(
    2,
    2,
    '2024-01-20',
    75.50,
    'processing',
    '456 Oak Ave',
    '456 Oak Ave',
    'Gift order'
),
(
    3,
    1,
    '2024-01-25',
    200.00,
    'completed',
    '123 Main St',
    '123 Main St',
    'Bulk order'
);

-- POOR: Selecting all columns when only some are needed
SELECT * FROM customers
WHERE city = 'New York';

-- BETTER: Selecting only needed columns
SELECT
    customer_id,
    first_name,
    last_name,
    email,
    phone
FROM customers
WHERE city = 'New York';

-- Example 2: WHERE Clause Optimization
-- Demonstrate efficient WHERE clause ordering

-- POOR: Non-selective condition first
SELECT
    customer_id,
    first_name,
    last_name,
    email
FROM customers
WHERE
    country = 'USA'  -- Non-selective (most customers are in USA)
    AND city = 'New York';  -- More selective

-- BETTER: More selective condition first
SELECT
    customer_id,
    first_name,
    last_name,
    email
FROM customers
WHERE
    city = 'New York'  -- More selective first
    AND country = 'USA';  -- Less selective second

-- Example 3: JOIN Optimization
-- Demonstrate efficient JOIN usage

-- POOR: Using CROSS JOIN when INNER JOIN is needed
SELECT
    c.first_name,
    c.last_name,
    o.order_id,
    o.total_amount
FROM customers AS c, orders AS o
WHERE
    c.customer_id = o.customer_id
    AND o.order_date >= '2024-01-01';

-- BETTER: Using explicit INNER JOIN
SELECT
    c.first_name,
    c.last_name,
    o.order_id,
    o.total_amount
FROM customers AS c
INNER JOIN orders AS o ON c.customer_id = o.customer_id
WHERE o.order_date >= '2024-01-01';

-- Example 4: Avoiding Unnecessary Functions
-- Demonstrate avoiding functions in WHERE clauses

-- POOR: Using function in WHERE clause
SELECT
    customer_id,
    first_name,
    last_name
FROM customers
WHERE UPPER(city) = 'NEW YORK';

-- BETTER: Using direct comparison
SELECT
    customer_id,
    first_name,
    last_name
FROM customers
WHERE city = 'New York';

-- Example 5: LIMIT for Large Result Sets
-- Demonstrate using LIMIT for performance

-- POOR: No limit on potentially large result set
SELECT
    customer_id,
    first_name,
    last_name,
    email
FROM customers
ORDER BY created_at DESC;

-- BETTER: Using LIMIT for pagination
SELECT
    customer_id,
    first_name,
    last_name,
    email
FROM customers
ORDER BY created_at DESC
LIMIT 10;

-- Clean up
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
