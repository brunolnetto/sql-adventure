-- =====================================================
-- Performance Tuning: Basic Query Optimization
-- =====================================================
-- PURPOSE: Learn fundamental query optimization techniques
-- LEARNING OUTCOMES: Understand query execution order, optimize WHERE clauses, choose efficient JOINs
-- EXPECTED RESULTS: Improved query performance through optimization
-- DIFFICULTY: 🟢 Beginner (5-10 min)
-- CONCEPTS: Query structure, WHERE clause optimization, JOIN efficiency

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;

-- Create sample tables with realistic data
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    registration_date DATE,
    status VARCHAR(20) DEFAULT 'active',
    total_orders INTEGER DEFAULT 0
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2),
    stock_quantity INTEGER,
    created_date DATE
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    product_id INTEGER REFERENCES products(product_id),
    quantity INTEGER,
    order_date DATE,
    total_amount DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'pending'
);

-- Insert sample data
INSERT INTO customers (first_name, last_name, email, registration_date, total_orders) VALUES
('John', 'Doe', 'john.doe@email.com', '2023-01-15', 5),
('Jane', 'Smith', 'jane.smith@email.com', '2023-02-20', 3),
('Bob', 'Johnson', 'bob.johnson@email.com', '2023-03-10', 8),
('Alice', 'Brown', 'alice.brown@email.com', '2023-04-05', 2),
('Charlie', 'Wilson', 'charlie.wilson@email.com', '2023-05-12', 6);

INSERT INTO products (name, category, price, stock_quantity, created_date) VALUES
('Laptop Pro', 'Electronics', 1200.00, 50, '2023-01-01'),
('Wireless Mouse', 'Electronics', 45.00, 200, '2023-01-15'),
('Office Chair', 'Furniture', 299.99, 30, '2023-02-01'),
('Desk Lamp', 'Furniture', 89.99, 100, '2023-02-15'),
('Gaming Keyboard', 'Electronics', 150.00, 75, '2023-03-01');

INSERT INTO orders (customer_id, product_id, quantity, order_date, total_amount) VALUES
(1, 1, 1, '2024-01-15', 1200.00),
(1, 2, 2, '2024-01-16', 90.00),
(2, 3, 1, '2024-01-17', 299.99),
(3, 1, 1, '2024-01-18', 1200.00),
(3, 4, 1, '2024-01-19', 89.99),
(4, 5, 1, '2024-01-20', 150.00),
(5, 2, 3, '2024-01-21', 135.00);

-- Example 1: WHERE Clause Optimization
-- Demonstrate the importance of condition ordering in WHERE clauses

-- POOR: Non-selective condition first
SELECT customer_id, first_name, last_name, email
FROM customers
WHERE status = 'active'  -- Non-selective (most customers are active)
  AND registration_date >= '2023-03-01';  -- More selective

-- BETTER: More selective condition first
SELECT customer_id, first_name, last_name, email
FROM customers
WHERE registration_date >= '2023-03-01'  -- More selective first
  AND status = 'active';  -- Less selective second

-- Example 2: JOIN Type Selection
-- Compare INNER JOIN vs LEFT JOIN performance

-- INNER JOIN: More efficient when you only need matching records
SELECT c.first_name, c.last_name, o.order_id, o.total_amount
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_date >= '2024-01-15';

-- LEFT JOIN: Use only when you need all customers, even without orders
SELECT c.first_name, c.last_name, o.order_id, o.total_amount
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_date >= '2024-01-15' OR o.order_id IS NULL;

-- Example 3: Subquery vs JOIN Performance
-- Compare subquery and JOIN approaches

-- Using subquery (can be slower)
SELECT c.first_name, c.last_name,
       (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.customer_id) as order_count
FROM customers c
WHERE c.registration_date >= '2023-03-01';

-- Using JOIN (usually more efficient)
SELECT c.first_name, c.last_name, COUNT(o.order_id) as order_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.registration_date >= '2023-03-01'
GROUP BY c.customer_id, c.first_name, c.last_name;

-- Example 4: Column Selection Optimization
-- Only select columns you actually need

-- POOR: Selecting all columns
SELECT *
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN products p ON o.product_id = p.product_id
WHERE o.order_date >= '2024-01-15';

-- BETTER: Select only needed columns
SELECT c.first_name, c.last_name, p.name, o.quantity, o.total_amount
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN products p ON o.product_id = p.product_id
WHERE o.order_date >= '2024-01-15';

-- Example 5: Avoid Functions in WHERE Clauses
-- Functions in WHERE clauses can prevent index usage

-- POOR: Function in WHERE clause (prevents index usage)
SELECT customer_id, first_name, last_name
FROM customers
WHERE UPPER(email) = 'JOHN.DOE@EMAIL.COM';

-- BETTER: Direct comparison (allows index usage)
SELECT customer_id, first_name, last_name
FROM customers
WHERE email = 'john.doe@email.com';

-- Example 6: Use LIMIT for Large Result Sets
-- Limit results when you don't need all records

-- Without LIMIT (returns all matching records)
SELECT c.first_name, c.last_name, o.total_amount
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
ORDER BY o.total_amount DESC;

-- With LIMIT (returns only top 5)
SELECT c.first_name, c.last_name, o.total_amount
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
ORDER BY o.total_amount DESC
LIMIT 5;

-- Clean up
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE; 