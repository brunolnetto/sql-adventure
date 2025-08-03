-- =====================================================
-- Performance Tuning: Aggregation Optimization
-- =====================================================
-- PURPOSE: Learn GROUP BY optimization and aggregate function efficiency
-- LEARNING OUTCOMES: Optimize GROUP BY operations, choose efficient aggregate functions, use HAVING effectively
-- EXPECTED RESULTS: Improved aggregation query performance
-- DIFFICULTY: 🟡 Intermediate (10-15 min)
-- CONCEPTS: GROUP BY optimization, aggregate functions, HAVING clauses

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;

-- Create sample tables with realistic data
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    description TEXT
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    category_id INTEGER REFERENCES categories(category_id),
    price DECIMAL(10,2),
    cost DECIMAL(10,2),
    created_date DATE
);

CREATE TABLE sales (
    sale_id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(product_id),
    quantity INTEGER,
    sale_date DATE,
    customer_id INTEGER,
    region VARCHAR(50),
    discount_percent DECIMAL(5,2) DEFAULT 0
);

-- Insert sample data
INSERT INTO categories (name, description) VALUES
('Electronics', 'Electronic devices and accessories'),
('Furniture', 'Office and home furniture'),
('Clothing', 'Apparel and accessories'),
('Books', 'Books and publications');

INSERT INTO products (name, category_id, price, cost, created_date) VALUES
('Laptop Pro', 1, 1200.00, 800.00, '2023-01-01'),
('Wireless Mouse', 1, 45.00, 25.00, '2023-01-15'),
('Office Chair', 2, 299.99, 150.00, '2023-02-01'),
('Desk Lamp', 2, 89.99, 45.00, '2023-02-15'),
('Gaming Keyboard', 1, 150.00, 75.00, '2023-03-01'),
('T-Shirt', 3, 25.00, 10.00, '2023-03-15'),
('Programming Book', 4, 49.99, 20.00, '2023-04-01');

INSERT INTO sales (product_id, quantity, sale_date, customer_id, region, discount_percent) VALUES
(1, 2, '2024-01-15', 101, 'North', 5.0),
(2, 5, '2024-01-15', 102, 'South', 0.0),
(3, 1, '2024-01-16', 103, 'East', 10.0),
(1, 1, '2024-01-16', 104, 'West', 0.0),
(4, 3, '2024-01-17', 105, 'North', 15.0),
(5, 2, '2024-01-17', 106, 'South', 5.0),
(6, 10, '2024-01-18', 107, 'East', 0.0),
(7, 1, '2024-01-18', 108, 'West', 20.0),
(2, 3, '2024-01-19', 109, 'North', 0.0),
(3, 2, '2024-01-19', 110, 'South', 5.0);

-- Example 1: GROUP BY Column Ordering
-- Order columns from most selective to least selective

-- POOR: Less selective column first
SELECT c.name as category, p.name as product, COUNT(*) as sales_count
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY c.name, p.name;  -- Category is less selective than product

-- BETTER: More selective column first
SELECT p.name as product, c.name as category, COUNT(*) as sales_count
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY p.name, c.name;  -- Product is more selective than category

-- Example 2: Aggregate Function Selection
-- Choose the most efficient aggregate function for your needs

-- Using COUNT(*) vs COUNT(column)
SELECT p.name, 
       COUNT(*) as total_sales,           -- Counts all rows including NULLs
       COUNT(s.quantity) as quantity_sales, -- Counts only non-NULL quantities
       COUNT(DISTINCT s.customer_id) as unique_customers
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.name;

-- Using SUM vs AVG for calculations
SELECT p.name,
       SUM(s.quantity * p.price * (1 - s.discount_percent/100)) as total_revenue,
       AVG(s.quantity * p.price * (1 - s.discount_percent/100)) as avg_sale_value,
       SUM(s.quantity * p.price * (1 - s.discount_percent/100)) / COUNT(*) as calculated_avg
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.name;

-- Example 3: HAVING vs WHERE Performance
-- Use WHERE for row-level filtering, HAVING for aggregate filtering

-- POOR: Using HAVING for row-level filtering
SELECT p.name, COUNT(*) as sales_count
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.name
HAVING s.quantity > 1;  -- This won't work - s.quantity not in GROUP BY

-- BETTER: Use WHERE for row-level filtering
SELECT p.name, COUNT(*) as sales_count
FROM sales s
JOIN products p ON s.product_id = p.product_id
WHERE s.quantity > 1  -- Filter rows before aggregation
GROUP BY p.name;

-- CORRECT: Use HAVING for aggregate filtering
SELECT p.name, COUNT(*) as sales_count, SUM(s.quantity) as total_quantity
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.name
HAVING COUNT(*) > 1;  -- Filter after aggregation

-- Example 4: Window Functions vs GROUP BY
-- Choose the right approach for your use case

-- Using GROUP BY (when you need aggregated results)
SELECT p.name, 
       SUM(s.quantity * p.price) as total_revenue,
       COUNT(*) as sales_count
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.name
ORDER BY total_revenue DESC;

-- Using Window Functions (when you need both detail and aggregates)
SELECT p.name, s.quantity, s.sale_date,
       SUM(s.quantity * p.price) OVER (PARTITION BY p.name) as product_total_revenue,
       SUM(s.quantity * p.price) OVER () as overall_total_revenue
FROM sales s
JOIN products p ON s.product_id = p.product_id
ORDER BY p.name, s.sale_date;

-- Example 5: Optimizing Complex Aggregations
-- Break down complex aggregations for better performance

-- COMPLEX: Single query with multiple aggregations
SELECT c.name as category,
       COUNT(DISTINCT s.customer_id) as unique_customers,
       SUM(s.quantity * p.price * (1 - s.discount_percent/100)) as total_revenue,
       AVG(s.quantity * p.price * (1 - s.discount_percent/100)) as avg_sale_value,
       SUM(s.quantity * p.cost) as total_cost,
       SUM(s.quantity * p.price * (1 - s.discount_percent/100)) - SUM(s.quantity * p.cost) as total_profit
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY c.name;

-- OPTIMIZED: Break down into simpler aggregations
WITH sales_summary AS (
    SELECT p.category_id,
           s.customer_id,
           s.quantity * p.price * (1 - s.discount_percent/100) as sale_value,
           s.quantity * p.cost as sale_cost
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
)
SELECT c.name as category,
       COUNT(DISTINCT ss.customer_id) as unique_customers,
       SUM(ss.sale_value) as total_revenue,
       AVG(ss.sale_value) as avg_sale_value,
       SUM(ss.sale_cost) as total_cost,
       SUM(ss.sale_value) - SUM(ss.sale_cost) as total_profit
FROM sales_summary ss
JOIN categories c ON ss.category_id = c.category_id
GROUP BY c.name;

-- Example 6: Conditional Aggregations
-- Use CASE statements for conditional aggregations

-- Conditional aggregation based on region
SELECT p.name,
       SUM(CASE WHEN s.region = 'North' THEN s.quantity * p.price ELSE 0 END) as north_revenue,
       SUM(CASE WHEN s.region = 'South' THEN s.quantity * p.price ELSE 0 END) as south_revenue,
       SUM(CASE WHEN s.region = 'East' THEN s.quantity * p.price ELSE 0 END) as east_revenue,
       SUM(CASE WHEN s.region = 'West' THEN s.quantity * p.price ELSE 0 END) as west_revenue,
       SUM(s.quantity * p.price) as total_revenue
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.name;

-- Conditional aggregation based on discount
SELECT p.name,
       COUNT(*) as total_sales,
       COUNT(CASE WHEN s.discount_percent > 0 THEN 1 END) as discounted_sales,
       COUNT(CASE WHEN s.discount_percent = 0 THEN 1 END) as full_price_sales,
       AVG(CASE WHEN s.discount_percent > 0 THEN s.discount_percent END) as avg_discount
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.name;

-- Clean up
DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE; 