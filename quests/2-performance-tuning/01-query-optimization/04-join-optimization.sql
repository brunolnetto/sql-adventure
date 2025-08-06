-- Performance Tuning Quest: Join Optimization
-- PURPOSE: Demonstrate advanced join optimization techniques
-- DIFFICULTY: 🟡 Intermediate (10-15 min)
-- CONCEPTS: Join types, join order, join conditions, performance optimization

-- Example 1: Join Type Selection
-- Demonstrate choosing the right join type for performance

-- Create sample tables
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    city VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    total_amount DECIMAL(10, 2),
    status VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE order_items (
    item_id INT PRIMARY KEY,
    order_id INT,
    product_name VARCHAR(100),
    quantity INT,
    unit_price DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO customers VALUES
(1, 'Alice Johnson', 'alice@email.com', 'New York', '2023-01-01'),
(2, 'Bob Smith', 'bob@email.com', 'Los Angeles', '2023-01-02'),
(3, 'Carol Davis', 'carol@email.com', 'Chicago', '2023-01-03'),
(4, 'David Wilson', 'david@email.com', 'Houston', '2023-01-04');

INSERT INTO orders VALUES
(1, 1, '2024-01-15', 150.00, 'completed', '2024-01-15'),
(2, 2, '2024-01-20', 75.50, 'completed', '2024-01-20'),
(3, 1, '2024-01-25', 200.00, 'pending', '2024-01-25'),
(4, 3, '2024-01-30', 125.75, 'completed', '2024-01-30');

INSERT INTO order_items VALUES
(1, 1, 'Laptop', 1, 150.00, '2024-01-15'),
(2, 2, 'Mouse', 1, 75.50, '2024-01-20'),
(3, 3, 'Keyboard', 1, 200.00, '2024-01-25'),
(4, 4, 'Monitor', 1, 125.75, '2024-01-30');

-- Create indexes for join optimization
CREATE INDEX idx_orders_customer_id ON orders (customer_id);
CREATE INDEX idx_order_items_order_id ON order_items (order_id);

-- Example 2: INNER JOIN vs LEFT JOIN Performance
-- Demonstrate when to use each join type

-- INNER JOIN: Use when you only need matching records
SELECT
    c.customer_name,
    c.email,
    o.order_id,
    o.total_amount,
    o.status
FROM customers AS c
INNER JOIN orders AS o ON c.customer_id = o.customer_id
WHERE o.order_date >= '2024-01-01';

-- LEFT JOIN: Use when you need all customers, even without orders
SELECT
    c.customer_name,
    c.email,
    o.order_id,
    o.total_amount,
    o.status
FROM customers AS c
LEFT JOIN orders AS o ON c.customer_id = o.customer_id
WHERE o.order_date >= '2024-01-01' OR o.order_id IS NULL;

-- Example 3: Join Order Optimization
-- Demonstrate optimizing join order for better performance

-- POOR: Large table first in join
SELECT
    c.customer_name,
    o.order_id,
    oi.product_name,
    oi.quantity,
    oi.unit_price
FROM order_items AS oi  -- Large table first
INNER JOIN orders AS o ON oi.order_id = o.order_id
INNER JOIN customers AS c ON o.customer_id = c.customer_id
WHERE o.status = 'completed';

-- BETTER: Filter first, then join
SELECT
    c.customer_name,
    o.order_id,
    oi.product_name,
    oi.quantity,
    oi.unit_price
FROM orders AS o  -- Filter first
INNER JOIN customers AS c ON o.customer_id = c.customer_id
INNER JOIN order_items AS oi ON o.order_id = oi.order_id
WHERE o.status = 'completed';

-- Example 4: Multiple Join Optimization
-- Demonstrate optimizing complex joins

-- Complex join with multiple conditions
SELECT
    c.customer_name,
    c.city,
    o.order_id,
    o.order_date,
    o.total_amount,
    oi.product_name,
    oi.quantity
FROM customers AS c
INNER JOIN orders AS o ON c.customer_id = o.customer_id
INNER JOIN order_items AS oi ON o.order_id = oi.order_id
WHERE
    o.status = 'completed'
    AND o.order_date >= '2024-01-01'
    AND oi.quantity > 0
ORDER BY o.order_date DESC;

-- Example 5: Subquery vs JOIN Performance
-- Demonstrate when to use subqueries vs joins

-- Using JOIN (often faster for multiple rows)
SELECT
    c.customer_name,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS total_spent
FROM customers AS c
LEFT JOIN orders AS o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name;

-- Using subquery (sometimes faster for single values)
SELECT
    c.customer_name,
    (
        SELECT COUNT(*) FROM orders AS o
        WHERE o.customer_id = c.customer_id)
        AS total_orders,
    (
        SELECT SUM(total_amount) FROM orders AS o
        WHERE o.customer_id = c.customer_id
    ) AS total_spent
FROM customers AS c;

-- Example 6: Join with Aggregation Optimization
-- Demonstrate optimizing joins with aggregations

-- POOR: Join then aggregate
SELECT
    c.customer_name,
    c.city,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS total_spent
FROM customers AS c
LEFT JOIN orders AS o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.city
HAVING COUNT(o.order_id) > 0;

-- BETTER: Pre-aggregate then join
WITH order_stats AS (
    SELECT
        customer_id,
        COUNT(order_id) AS total_orders,
        SUM(total_amount) AS total_spent
    FROM orders
    GROUP BY customer_id
)

SELECT
    c.customer_name,
    c.city,
    COALESCE(order_stats.total_orders, 0) AS total_orders,
    COALESCE(order_stats.total_spent, 0) AS total_spent
FROM customers AS c
LEFT JOIN order_stats ON c.customer_id = order_stats.customer_id;

-- Clean up
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
