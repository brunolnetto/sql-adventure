-- Data Modeling Quest: Hybrid Denormalization Approaches
-- PURPOSE: Demonstrate balanced approaches combining normalization and denormalization
-- DIFFICULTY: 🔴 Advanced (20-25 min)
-- CONCEPTS: Hybrid schemas, read replicas, materialized views, caching strategies

-- Example 1: Hybrid E-commerce Schema
-- Demonstrate a hybrid approach for e-commerce with normalized OLTP and denormalized analytics

-- Normalized OLTP Schema (for transactions)
CREATE TABLE customers_oltp (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    customer_email VARCHAR(100) UNIQUE,
    customer_phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE customer_addresses_oltp (
    address_id INT PRIMARY KEY,
    customer_id INT REFERENCES customers_oltp (customer_id),
    address_type VARCHAR(20), -- 'billing', 'shipping'
    street_address VARCHAR(200),
    city VARCHAR(100),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50),
    is_default BOOLEAN DEFAULT false
);

CREATE TABLE products_oltp (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(200),
    category_id INT,
    brand_id INT,
    sku VARCHAR(50) UNIQUE,
    description TEXT,
    unit_price DECIMAL(10, 2),
    cost_price DECIMAL(10, 2),
    weight_kg DECIMAL(5, 2),
    dimensions_cm VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categories_oltp (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(100),
    parent_category_id INT REFERENCES categories_oltp (category_id),
    description TEXT
);

CREATE TABLE brands_oltp (
    brand_id INT PRIMARY KEY,
    brand_name VARCHAR(100),
    brand_description TEXT
);

CREATE TABLE orders_oltp (
    order_id INT PRIMARY KEY,
    customer_id INT REFERENCES customers_oltp (customer_id),
    billing_address_id INT REFERENCES customer_addresses_oltp (address_id),
    shipping_address_id INT REFERENCES customer_addresses_oltp (address_id),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20),
    total_amount DECIMAL(10, 2),
    tax_amount DECIMAL(10, 2),
    shipping_amount DECIMAL(10, 2)
);

CREATE TABLE order_items_oltp (
    order_item_id INT PRIMARY KEY,
    order_id INT REFERENCES orders_oltp (order_id),
    product_id INT REFERENCES products_oltp (product_id),
    quantity INT,
    unit_price DECIMAL(10, 2),
    discount_amount DECIMAL(10, 2)
);

-- Insert OLTP data
INSERT INTO customers_oltp VALUES
(1, 'Alice Johnson', 'alice@email.com', '555-1234'),
(2, 'Bob Smith', 'bob@email.com', '555-5678'),
(3, 'Carol Davis', 'carol@email.com', '555-9012');

INSERT INTO customer_addresses_oltp VALUES
(1, 1, 'billing', '123 Main St', 'New York', 'NY', '10001', 'USA', true),
(2, 1, 'shipping', '456 Oak Ave', 'New York', 'NY', '10002', 'USA', false),
(3, 2, 'billing', '789 Pine St', 'Los Angeles', 'CA', '90210', 'USA', true);

INSERT INTO categories_oltp VALUES
(1, 'Electronics', null, 'Electronic devices and accessories'),
(2, 'Computers', 1, 'Desktop and laptop computers'),
(3, 'Accessories', 1, 'Computer accessories and peripherals');

INSERT INTO brands_oltp VALUES
(1, 'TechCorp', 'Leading technology manufacturer'),
(2, 'AccessoryMax', 'Quality accessories provider');

INSERT INTO products_oltp VALUES
(
    1,
    'Laptop Pro X1',
    2,
    1,
    'LAP-X1-001',
    'High-performance laptop',
    1299.99,
    800.00,
    2.5,
    '35x25x2'
),
(
    2,
    'Wireless Mouse Elite',
    3,
    2,
    'ACC-MSE-001',
    'Ergonomic wireless mouse',
    49.99,
    15.00,
    0.15,
    '12x6x3'
),
(
    3,
    'USB Keyboard Pro',
    3,
    2,
    'ACC-KBD-001',
    'Mechanical USB keyboard',
    89.99,
    30.00,
    0.8,
    '44x15x3'
);

INSERT INTO orders_oltp VALUES
(1, 1, 1, 2, '2024-01-15 10:30:00', 'completed', 1439.97, 115.20, 0.00),
(2, 2, 3, 3, '2024-01-16 14:15:00', 'processing', 139.98, 11.20, 5.00);

INSERT INTO order_items_oltp VALUES
(1, 1, 1, 1, 1299.99, 0.00),
(2, 1, 2, 1, 49.99, 0.00),
(3, 1, 3, 1, 89.99, 0.00),
(4, 2, 2, 1, 49.99, 0.00),
(5, 2, 3, 1, 89.99, 0.00);

-- Denormalized Analytics Schema (for reporting)
CREATE TABLE customer_analytics (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    customer_email VARCHAR(100),
    customer_city VARCHAR(100),
    customer_state VARCHAR(50),
    customer_country VARCHAR(50),
    total_orders INT DEFAULT 0,
    total_spent DECIMAL(12, 2) DEFAULT 0,
    avg_order_value DECIMAL(10, 2) DEFAULT 0,
    first_order_date DATE,
    last_order_date DATE,
    days_since_last_order INT,
    customer_segment VARCHAR(20),
    is_active BOOLEAN DEFAULT true,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE product_analytics (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(200),
    product_sku VARCHAR(50),
    category_name VARCHAR(100),
    parent_category_name VARCHAR(100),
    brand_name VARCHAR(100),
    unit_price DECIMAL(10, 2),
    cost_price DECIMAL(10, 2),
    profit_margin DECIMAL(10, 2),
    total_quantity_sold INT DEFAULT 0,
    total_revenue DECIMAL(12, 2) DEFAULT 0,
    total_profit DECIMAL(12, 2) DEFAULT 0,
    avg_order_quantity DECIMAL(5, 2) DEFAULT 0,
    is_bestseller BOOLEAN DEFAULT false,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sales_summary (
    summary_id BIGSERIAL PRIMARY KEY,
    summary_date DATE,
    total_orders INT DEFAULT 0,
    total_customers INT DEFAULT 0,
    total_revenue DECIMAL(12, 2) DEFAULT 0,
    total_profit DECIMAL(12, 2) DEFAULT 0,
    avg_order_value DECIMAL(10, 2) DEFAULT 0,
    profit_margin_percent DECIMAL(5, 2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Populate analytics tables
INSERT INTO customer_analytics (
    customer_id,
    customer_name,
    customer_email,
    customer_city,
    customer_state,
    customer_country,
    total_orders,
    total_spent,
    avg_order_value,
    first_order_date,
    last_order_date,
    days_since_last_order, customer_segment
) VALUES
(
    1, 'Alice Johnson', 'alice@email.com', 'New York', 'NY', 'USA',
    1, 1439.97, 1439.97, '2024-01-15', '2024-01-15', 0, 'Premium'
),
(
    2, 'Bob Smith', 'bob@email.com', 'Los Angeles', 'CA', 'USA',
    1, 139.98, 139.98, '2024-01-16', '2024-01-16', 0, 'Standard'
);

INSERT INTO product_analytics (
    product_id,
    product_name,
    product_sku,
    category_name,
    parent_category_name,
    brand_name,
    unit_price,
    cost_price,
    profit_margin,
    total_quantity_sold,
    total_revenue,
    total_profit,
    avg_order_quantity, is_bestseller
) VALUES
(
    1, 'Laptop Pro X1', 'LAP-X1-001', 'Computers', 'Electronics', 'TechCorp',
    1299.99, 800.00, 499.99, 1, 1299.99, 499.99, 1.00, true
),
(
    2,
    'Wireless Mouse Elite',
    'ACC-MSE-001',
    'Accessories',
    'Electronics',
    'AccessoryMax',
    49.99, 15.00, 34.99, 2, 99.98, 69.98, 1.00, false
),
(
    3,
    'USB Keyboard Pro',
    'ACC-KBD-001',
    'Accessories',
    'Electronics',
    'AccessoryMax',
    89.99, 30.00, 59.99, 2, 179.98, 119.98, 1.00, false
);

INSERT INTO sales_summary (
    summary_date, total_orders, total_customers, total_revenue, total_profit,
    avg_order_value, profit_margin_percent
) VALUES
('2024-01-15', 1, 1, 1439.97, 614.97, 1439.97, 42.71),
('2024-01-16', 1, 1, 139.98, 89.98, 139.98, 64.28);

-- Example 2: Materialized Views for Hybrid Approach
-- Demonstrate materialized views that bridge normalized and denormalized data

-- Materialized view for customer analytics
CREATE MATERIALIZED VIEW mv_customer_analytics AS
SELECT
    c.customer_id,
    c.customer_name,
    c.customer_email,
    ca.city,
    ca.state,
    ca.country,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(o.total_amount) AS total_spent,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value,
    MIN(DATE(o.order_date)) AS first_order_date,
    MAX(DATE(o.order_date)) AS last_order_date,
    EXTRACT(day FROM AGE(CURRENT_DATE, MAX(DATE(o.order_date))))
        AS days_since_last_order,
    CASE
        WHEN SUM(o.total_amount) >= 1000 THEN 'Premium'
        WHEN SUM(o.total_amount) >= 100 THEN 'Standard'
        ELSE 'Basic'
    END AS customer_segment,
    COALESCE(
        MAX(o.order_date) >= CURRENT_DATE - INTERVAL '90 days',
        false
    ) AS is_active
FROM customers_oltp AS c
LEFT JOIN
    customer_addresses_oltp AS ca
    ON c.customer_id = ca.customer_id AND ca.address_type = 'billing'
LEFT JOIN orders_oltp AS o ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id, c.customer_name, c.customer_email, ca.city, ca.state, ca.country;

-- Materialized view for product analytics
CREATE MATERIALIZED VIEW mv_product_analytics AS
SELECT
    p.product_id,
    p.product_name,
    p.sku,
    c.category_name,
    pc.category_name AS parent_category_name,
    b.brand_name,
    p.unit_price,
    p.cost_price,
    (p.unit_price - p.cost_price) AS profit_margin,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.quantity * oi.unit_price) AS total_revenue,
    SUM(oi.quantity * (oi.unit_price - p.cost_price)) AS total_profit,
    ROUND(AVG(oi.quantity), 2) AS avg_order_quantity,
    COALESCE(SUM(oi.quantity) >= 10, false) AS is_bestseller
FROM products_oltp AS p
LEFT JOIN categories_oltp AS c ON p.category_id = c.category_id
LEFT JOIN categories_oltp AS pc ON c.parent_category_id = pc.category_id
LEFT JOIN brands_oltp AS b ON p.brand_id = b.brand_id
LEFT JOIN order_items_oltp AS oi ON p.product_id = oi.product_id
LEFT JOIN orders_oltp AS o ON oi.order_id = o.order_id
GROUP BY
    p.product_id, p.product_name, p.sku, c.category_name, pc.category_name,
    b.brand_name, p.unit_price, p.cost_price;

-- Example 3: Hybrid Query Strategies
-- Demonstrate how to use both normalized and denormalized data effectively

-- Complex analytical query using denormalized data (fast)
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_spent), 2) AS avg_total_spent,
    ROUND(AVG(avg_order_value), 2) AS avg_order_value,
    ROUND(SUM(total_spent), 2) AS total_revenue
FROM customer_analytics
WHERE is_active = true
GROUP BY customer_segment
ORDER BY total_revenue DESC;

-- Detailed transactional query using normalized data (accurate)
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.customer_name,
    c.customer_email,
    ca.city,
    ca.state,
    o.order_id,
    o.order_date,
    o.total_amount,
    o.status,
    STRING_AGG(p.product_name, ', ' ORDER BY p.product_name) AS products_ordered
FROM customers_oltp AS c
INNER JOIN
    customer_addresses_oltp AS ca
    ON c.customer_id = ca.customer_id AND ca.address_type = 'billing'
INNER JOIN orders_oltp AS o ON c.customer_id = o.customer_id
INNER JOIN order_items_oltp AS oi ON o.order_id = oi.order_id
INNER JOIN products_oltp AS p ON oi.product_id = p.product_id
WHERE o.order_date >= '2024-01-01'
GROUP BY
    c.customer_name,
    c.customer_email,
    ca.city,
    ca.state,
    o.order_id,
    o.order_date,
    o.total_amount,
    o.status
ORDER BY o.order_date DESC;

-- Example 4: Synchronization Strategies
-- Demonstrate how to keep normalized and denormalized data in sync

-- Note: For production use, you would implement triggers and functions to
-- automatically sync data between normalized and denormalized tables.
-- Here we demonstrate manual synchronization:

-- Manual refresh of materialized views
REFRESH MATERIALIZED VIEW mv_customer_analytics;
REFRESH MATERIALIZED VIEW mv_product_analytics;

-- Example 5: Performance Comparison
-- Demonstrate the performance benefits of hybrid approach

-- Query using denormalized data (fast)
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_spent), 2) AS avg_total_spent
FROM customer_analytics
GROUP BY customer_segment;

-- Equivalent query using normalized data (slower but more flexible)
EXPLAIN (ANALYZE, BUFFERS)
WITH customer_segments AS (
    SELECT
        c.customer_id,
        c.customer_name,
        CASE
            WHEN COALESCE(SUM(o.total_amount), 0) >= 1000 THEN 'Premium'
            WHEN COALESCE(SUM(o.total_amount), 0) >= 100 THEN 'Standard'
            ELSE 'Basic'
        END AS customer_segment,
        COALESCE(SUM(o.total_amount), 0) AS total_spent
    FROM customers_oltp AS c
    LEFT JOIN orders_oltp AS o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_spent), 2) AS avg_total_spent
FROM customer_segments
GROUP BY customer_segment;

-- Test the synchronization
INSERT INTO orders_oltp (
    order_id,
    customer_id,
    billing_address_id,
    shipping_address_id,
    order_date,
    status,
    total_amount
)
VALUES (3, 3, 3, 3, '2024-01-17 12:00:00', 'completed', 299.99);

INSERT INTO order_items_oltp (
    order_item_id, order_id, product_id, quantity, unit_price, discount_amount
)
VALUES (6, 3, 1, 1, 299.99, 0.00);

-- Verify the analytics tables were updated
SELECT
    customer_id,
    customer_name,
    total_orders,
    total_spent,
    customer_segment
FROM customer_analytics
ORDER BY customer_id;

SELECT
    product_id,
    product_name,
    total_quantity_sold,
    total_revenue,
    is_bestseller
FROM product_analytics
ORDER BY product_id;

-- Clean up
DROP TABLE IF EXISTS customers_oltp CASCADE;
DROP TABLE IF EXISTS customer_addresses_oltp CASCADE;
DROP TABLE IF EXISTS products_oltp CASCADE;
DROP TABLE IF EXISTS categories_oltp CASCADE;
DROP TABLE IF EXISTS brands_oltp CASCADE;
DROP TABLE IF EXISTS orders_oltp CASCADE;
DROP TABLE IF EXISTS order_items_oltp CASCADE;
DROP TABLE IF EXISTS customer_analytics CASCADE;
DROP TABLE IF EXISTS product_analytics CASCADE;
DROP TABLE IF EXISTS sales_summary CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mv_customer_analytics CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mv_product_analytics CASCADE;
