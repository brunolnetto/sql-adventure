-- =====================================================
-- Performance Tuning: Subquery Optimization
-- =====================================================
-- PURPOSE: Learn subquery optimization techniques and best practices
-- LEARNING OUTCOMES: Choose between EXISTS and IN, optimize correlated subqueries, use CTEs effectively
-- EXPECTED RESULTS: Improved subquery performance through optimization
-- DIFFICULTY: 🟡 Intermediate (10-15 min)
-- CONCEPTS: Subquery types, EXISTS vs IN, correlated subqueries, CTEs

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;

-- Create sample tables with realistic data
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    registration_date DATE,
    status VARCHAR(20) DEFAULT 'active',
    total_spent DECIMAL(10, 2) DEFAULT 0
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10, 2),
    stock_quantity INTEGER,
    is_active BOOLEAN DEFAULT true
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers (customer_id),
    order_date DATE,
    total_amount DECIMAL(10, 2),
    status VARCHAR(20) DEFAULT 'pending'
);

CREATE TABLE order_items (
    item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders (order_id),
    product_id INTEGER REFERENCES products (product_id),
    quantity INTEGER,
    unit_price DECIMAL(10, 2)
);

-- Insert sample data
INSERT INTO customers (
    first_name, last_name, email, registration_date, total_spent
) VALUES
('John', 'Doe', 'john.doe@email.com', '2023-01-15', 1500.00),
('Jane', 'Smith', 'jane.smith@email.com', '2023-02-20', 800.00),
('Bob', 'Johnson', 'bob.johnson@email.com', '2023-03-10', 2200.00),
('Alice', 'Brown', 'alice.brown@email.com', '2023-04-05', 450.00),
('Charlie', 'Wilson', 'charlie.wilson@email.com', '2023-05-12', 1200.00),
('Diana', 'Davis', 'diana.davis@email.com', '2023-06-01', 0.00);

INSERT INTO products (name, category, price, stock_quantity) VALUES
('Laptop Pro', 'Electronics', 1200.00, 50),
('Wireless Mouse', 'Electronics', 45.00, 200),
('Office Chair', 'Furniture', 299.99, 30),
('Desk Lamp', 'Furniture', 89.99, 100),
('Gaming Keyboard', 'Electronics', 150.00, 75),
('T-Shirt', 'Clothing', 25.00, 500);

INSERT INTO orders (customer_id, order_date, total_amount, status) VALUES
(1, '2024-01-15', 1200.00, 'completed'),
(1, '2024-01-20', 90.00, 'completed'),
(2, '2024-01-17', 299.99, 'completed'),
(3, '2024-01-18', 1200.00, 'completed'),
(3, '2024-01-25', 89.99, 'completed'),
(4, '2024-01-20', 150.00, 'completed'),
(5, '2024-01-21', 135.00, 'completed');

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 1200.00),
(2, 2, 2, 45.00),
(3, 3, 1, 299.99),
(4, 1, 1, 1200.00),
(5, 4, 1, 89.99),
(6, 5, 1, 150.00),
(7, 2, 3, 45.00);

-- Example 1: EXISTS vs IN Performance Comparison
-- EXISTS is generally more efficient than IN for large datasets

-- Using IN (can be slower for large subqueries)
SELECT
    c.first_name,
    c.last_name,
    c.email
FROM customers AS c
WHERE c.customer_id IN (
    SELECT DISTINCT o.customer_id
    FROM orders AS o
    WHERE o.total_amount > 1000
);

-- Using EXISTS (usually more efficient)
SELECT
    c.first_name,
    c.last_name,
    c.email
FROM customers AS c
WHERE EXISTS (
    SELECT 1
    FROM orders AS o
    WHERE
        o.customer_id = c.customer_id
        AND o.total_amount > 1000
);

-- Example 2: Correlated Subquery Optimization
-- Correlated subqueries can be slow - consider alternatives

-- POOR: Correlated subquery (executes for each row)
SELECT
    c.first_name,
    c.last_name,
    (
        SELECT COUNT(*) FROM orders AS o
        WHERE o.customer_id = c.customer_id)
        AS order_count,
    (
        SELECT MAX(o.total_amount) FROM orders AS o
        WHERE o.customer_id = c.customer_id
    ) AS max_order
FROM customers AS c
WHERE c.status = 'active';

-- BETTER: Using JOIN with aggregation
SELECT
    c.first_name,
    c.last_name,
    COUNT(o.order_id) AS order_count,
    MAX(o.total_amount) AS max_order
FROM customers AS c
LEFT JOIN orders AS o ON c.customer_id = o.customer_id
WHERE c.status = 'active'
GROUP BY c.customer_id, c.first_name, c.last_name;

-- Example 3: CTE vs Subquery Performance
-- CTEs can improve readability and sometimes performance

-- Using subquery (can be hard to read)
SELECT
    p.name,
    p.category,
    (
        SELECT COUNT(*) FROM order_items AS oi
        INNER JOIN orders AS o ON oi.order_id = o.order_id
        WHERE oi.product_id = p.product_id AND o.status = 'completed'
    ) AS sales_count,
    (
        SELECT SUM(oi.quantity * oi.unit_price) FROM order_items AS oi
        INNER JOIN orders AS o ON oi.order_id = o.order_id
        WHERE oi.product_id = p.product_id AND o.status = 'completed'
    ) AS total_revenue
FROM products AS p
WHERE p.is_active = true;

-- Using CTE (more readable and potentially faster)
WITH product_sales AS (
    SELECT
        oi.product_id,
        COUNT(*) AS sales_count,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM order_items AS oi
    INNER JOIN orders AS o ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY oi.product_id
)

SELECT
    p.name,
    p.category,
    COALESCE(ps.sales_count, 0) AS sales_count,
    COALESCE(ps.total_revenue, 0) AS total_revenue
FROM products AS p
LEFT JOIN product_sales AS ps ON p.product_id = ps.product_id
WHERE p.is_active = true;

-- Example 4: Lateral Joins for Complex Subqueries
-- Lateral joins can be more efficient than correlated subqueries

-- Using correlated subquery
SELECT
    c.first_name,
    c.last_name,
    (
        SELECT oi.product_id
        FROM order_items AS oi
        INNER JOIN orders AS o ON oi.order_id = o.order_id
        WHERE o.customer_id = c.customer_id
        ORDER BY oi.quantity * oi.unit_price DESC
        LIMIT 1
    ) AS top_product_id
FROM customers AS c
WHERE c.status = 'active';

-- Using lateral join (more efficient)
SELECT
    c.first_name,
    c.last_name,
    top_product.product_id
FROM customers AS c
CROSS JOIN
    LATERAL (
        SELECT oi.product_id
        FROM order_items AS oi
        INNER JOIN orders AS o ON oi.order_id = o.order_id
        WHERE o.customer_id = c.customer_id
        ORDER BY oi.quantity * oi.unit_price DESC
        LIMIT 1
    ) AS top_product
WHERE c.status = 'active';

-- Example 5: Subquery in SELECT vs JOIN
-- Choose the right approach based on your needs

-- Using subquery in SELECT (executes for each row)
SELECT
    c.first_name,
    c.last_name,
    (
        SELECT SUM(o.total_amount) FROM orders AS o
        WHERE o.customer_id = c.customer_id
    ) AS total_spent,
    (
        SELECT COUNT(*) FROM orders AS o
        WHERE o.customer_id = c.customer_id)
        AS order_count
FROM customers AS c
WHERE c.status = 'active';

-- Using JOIN with aggregation (usually more efficient)
SELECT
    c.first_name,
    c.last_name,
    COALESCE(SUM(o.total_amount), 0) AS total_spent,
    COUNT(o.order_id) AS order_count
FROM customers AS c
LEFT JOIN orders AS o ON c.customer_id = o.customer_id
WHERE c.status = 'active'
GROUP BY c.customer_id, c.first_name, c.last_name;

-- Example 6: Optimizing NOT EXISTS vs NOT IN
-- NOT EXISTS is generally safer and more efficient than NOT IN

-- Using NOT IN (can have issues with NULL values)
SELECT
    c.first_name,
    c.last_name
FROM customers AS c
WHERE c.customer_id NOT IN (
    SELECT o.customer_id
    FROM orders AS o
    WHERE o.status = 'completed'
);

-- Using NOT EXISTS (safer and more efficient)
SELECT
    c.first_name,
    c.last_name
FROM customers AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders AS o
    WHERE
        o.customer_id = c.customer_id
        AND o.status = 'completed'
);

-- Example 7: Subquery with Window Functions
-- Combine subqueries with window functions for complex analysis

-- Find customers with above-average spending
WITH customer_stats AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        SUM(o.total_amount) AS total_spent,
        AVG(SUM(o.total_amount)) OVER () AS avg_customer_spending
    FROM customers AS c
    LEFT JOIN orders AS o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
)

SELECT
    first_name,
    last_name,
    total_spent,
    avg_customer_spending
FROM customer_stats
WHERE total_spent > avg_customer_spending
ORDER BY total_spent DESC;

-- Example 8: Recursive CTE vs Subquery
-- Use recursive CTEs for hierarchical data instead of subqueries

-- Using subquery for hierarchical data (inefficient)
SELECT
    p.name,
    p.category,
    (
        SELECT COUNT(*) FROM products AS p2
        WHERE p2.category = p.category)
        AS category_count
FROM products AS p;

-- Using window function (more efficient)
SELECT
    p.name,
    p.category,
    COUNT(*) OVER (PARTITION BY p.category) AS category_count
FROM products AS p;

-- Clean up
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
