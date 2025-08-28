-- =====================================================
-- Data Modeling Quest: Analytics Denormalization
-- =====================================================
-- 
-- PURPOSE: Demonstrate denormalization strategies for analytics and reporting
-- DIFFICULTY: 🔴 Advanced (20-25 min)
-- CONCEPTS: Star schema, snowflake schema, fact tables, dimension tables, data warehousing

-- Example 1: Sales Analytics Star Schema
-- Demonstrate star schema for sales analytics

-- Normalized sales schema
CREATE TABLE customers_normalized (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    customer_email VARCHAR(100),
    customer_phone VARCHAR(20),
    address_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE addresses_normalized (
    address_id INT PRIMARY KEY,
    street_address VARCHAR(200),
    city VARCHAR(100),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50)
);

CREATE TABLE products_normalized (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(200),
    category_id INT,
    brand_id INT,
    sku VARCHAR(50) UNIQUE,
    unit_price DECIMAL(10, 2),
    cost_price DECIMAL(10, 2)
);

CREATE TABLE categories_normalized (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(100),
    parent_category_id INT REFERENCES categories_normalized (category_id),
    description TEXT
);

CREATE TABLE brands_normalized (
    brand_id INT PRIMARY KEY,
    brand_name VARCHAR(100),
    brand_description TEXT
);

CREATE TABLE orders_normalized (
    order_id INT PRIMARY KEY,
    customer_id INT REFERENCES customers_normalized (customer_id),
    order_date TIMESTAMP,
    status VARCHAR(20),
    total_amount DECIMAL(10, 2)
);

CREATE TABLE order_items_normalized (
    order_item_id INT PRIMARY KEY,
    order_id INT REFERENCES orders_normalized (order_id),
    product_id INT REFERENCES products_normalized (product_id),
    quantity INT,
    unit_price DECIMAL(10, 2),
    discount_amount DECIMAL(10, 2)
);

-- Insert normalized data
INSERT INTO addresses_normalized VALUES
(1, '123 Main St', 'New York', 'NY', '10001', 'USA'),
(2, '456 Oak Ave', 'Los Angeles', 'CA', '90210', 'USA'),
(3, '789 Pine St', 'Chicago', 'IL', '60601', 'USA');

INSERT INTO customers_normalized VALUES
(1, 'Alice Johnson', 'alice@email.com', '555-1234', 1, '2023-01-15'),
(2, 'Bob Smith', 'bob@email.com', '555-5678', 2, '2023-02-20'),
(3, 'Carol Davis', 'carol@email.com', '555-9012', 3, '2023-03-10');

INSERT INTO categories_normalized VALUES
(1, 'Electronics', NULL, 'Electronic devices and accessories'),
(2, 'Computers', 1, 'Desktop and laptop computers'),
(3, 'Accessories', 1, 'Computer accessories and peripherals'),
(4, 'Smartphones', 1, 'Mobile phones and accessories');

INSERT INTO brands_normalized VALUES
(1, 'TechCorp', 'Leading technology manufacturer'),
(2, 'MobilePro', 'Premium mobile device brand'),
(3, 'AccessoryMax', 'Quality accessories provider');

INSERT INTO products_normalized VALUES
(1, 'Laptop Pro X1', 2, 1, 'LAP-X1-001', 1299.99, 800.00),
(2, 'Wireless Mouse Elite', 3, 3, 'ACC-MSE-001', 49.99, 15.00),
(3, 'Smartphone Ultra', 4, 2, 'PHN-ULT-001', 899.99, 450.00),
(4, 'USB Keyboard Pro', 3, 3, 'ACC-KBD-001', 89.99, 30.00);

INSERT INTO orders_normalized VALUES
(1, 1, '2024-01-15 10:30:00', 'completed', 1439.97),
(2, 2, '2024-01-16 14:15:00', 'completed', 139.98),
(3, 3, '2024-01-17 09:45:00', 'completed', 899.99),
(4, 1, '2024-01-18 16:20:00', 'completed', 89.99);

INSERT INTO order_items_normalized VALUES
(1, 1, 1, 1, 1299.99, 0.00),
(2, 1, 2, 1, 49.99, 0.00),
(3, 1, 4, 1, 89.99, 0.00),
(4, 2, 2, 1, 49.99, 0.00),
(5, 2, 4, 1, 89.99, 0.00),
(6, 3, 3, 1, 899.99, 0.00),
(7, 4, 4, 1, 89.99, 0.00);

-- Star Schema for Analytics
-- Dimension Tables
CREATE TABLE dim_customers (
    customer_key INT PRIMARY KEY,
    customer_id INT,
    customer_name VARCHAR(100),
    customer_email VARCHAR(100),
    customer_city VARCHAR(100),
    customer_state VARCHAR(50),
    customer_country VARCHAR(50),
    customer_segment VARCHAR(50),
    customer_lifetime_value DECIMAL(12, 2),
    is_active BOOLEAN DEFAULT TRUE,
    valid_from DATE,
    valid_to DATE,
    current_flag BOOLEAN DEFAULT TRUE
);

CREATE TABLE dim_products (
    product_key INT PRIMARY KEY,
    product_id INT,
    product_name VARCHAR(200),
    product_sku VARCHAR(50),
    category_name VARCHAR(100),
    parent_category_name VARCHAR(100),
    brand_name VARCHAR(100),
    unit_price DECIMAL(10, 2),
    cost_price DECIMAL(10, 2),
    profit_margin DECIMAL(10, 2),
    profit_margin_percent DECIMAL(5, 2),
    is_active BOOLEAN DEFAULT TRUE,
    valid_from DATE,
    valid_to DATE,
    current_flag BOOLEAN DEFAULT TRUE
);

CREATE TABLE dim_time (
    time_key INT PRIMARY KEY,
    full_date DATE,
    day_of_week VARCHAR(10),
    day_of_month INT,
    day_of_year INT,
    week_of_year INT,
    month_name VARCHAR(10),
    month_number INT,
    quarter VARCHAR(2),
    year INT,
    is_weekend BOOLEAN,
    is_holiday BOOLEAN DEFAULT FALSE
);

CREATE TABLE dim_geography (
    geography_key INT PRIMARY KEY,
    city VARCHAR(100),
    state VARCHAR(50),
    country VARCHAR(50),
    region VARCHAR(50),
    population INT,
    timezone VARCHAR(50)
);

-- Fact Table
CREATE TABLE fact_sales (
    sale_key BIGSERIAL PRIMARY KEY,
    customer_key INT REFERENCES dim_customers (customer_key),
    product_key INT REFERENCES dim_products (product_key),
    time_key INT REFERENCES dim_time (time_key),
    geography_key INT REFERENCES dim_geography (geography_key),
    order_id INT,
    quantity INT,
    unit_price DECIMAL(10, 2),
    total_amount DECIMAL(10, 2),
    discount_amount DECIMAL(10, 2),
    net_amount DECIMAL(10, 2),
    cost_amount DECIMAL(10, 2),
    profit_amount DECIMAL(10, 2),
    profit_margin_percent DECIMAL(5, 2)
);

-- Populate dimension tables
INSERT INTO dim_customers (
    customer_key, customer_id, customer_name, customer_email,
    customer_city, customer_state, customer_country, customer_segment,
    customer_lifetime_value, valid_from, valid_to, current_flag
) VALUES
(
    1,
    1,
    'Alice Johnson',
    'alice@email.com',
    'New York',
    'NY',
    'USA',
    'Premium',
    1529.96,
    '2023-01-15',
    NULL,
    TRUE
),
(
    2,
    2,
    'Bob Smith',
    'bob@email.com',
    'Los Angeles',
    'CA',
    'USA',
    'Standard',
    139.98,
    '2023-02-20',
    NULL,
    TRUE
),
(
    3,
    3,
    'Carol Davis',
    'carol@email.com',
    'Chicago',
    'IL',
    'USA',
    'Premium',
    899.99,
    '2023-03-10',
    NULL,
    TRUE
);

INSERT INTO dim_products (
    product_key,
    product_id,
    product_name,
    product_sku,
    category_name,
    parent_category_name,
    brand_name, unit_price, cost_price, profit_margin, profit_margin_percent,
    valid_from, valid_to, current_flag
) VALUES
(
    1,
    1,
    'Laptop Pro X1',
    'LAP-X1-001',
    'Computers',
    'Electronics',
    'TechCorp',
    1299.99,
    800.00,
    499.99,
    38.46,
    '2024-01-01',
    NULL,
    TRUE
),
(
    2,
    2,
    'Wireless Mouse Elite',
    'ACC-MSE-001',
    'Accessories',
    'Electronics',
    'AccessoryMax',
    49.99,
    15.00,
    34.99,
    70.00,
    '2024-01-01',
    NULL,
    TRUE
),
(
    3,
    3,
    'Smartphone Ultra',
    'PHN-ULT-001',
    'Smartphones',
    'Electronics',
    'MobilePro',
    899.99,
    450.00,
    449.99,
    50.00,
    '2024-01-01',
    NULL,
    TRUE
),
(
    4,
    4,
    'USB Keyboard Pro',
    'ACC-KBD-001',
    'Accessories',
    'Electronics',
    'AccessoryMax',
    89.99,
    30.00,
    59.99,
    66.67,
    '2024-01-01',
    NULL,
    TRUE
);

INSERT INTO dim_time (
    time_key, full_date, day_of_week, day_of_month, day_of_year, week_of_year,
    month_name, month_number, quarter, year, is_weekend
) VALUES
(20240115, '2024-01-15', 'Monday', 15, 15, 3, 'January', 1, 'Q1', 2024, FALSE),
(20240116, '2024-01-16', 'Tuesday', 16, 16, 3, 'January', 1, 'Q1', 2024, FALSE),
(
    20240117,
    '2024-01-17',
    'Wednesday',
    17,
    17,
    3,
    'January',
    1,
    'Q1',
    2024,
    FALSE
),
(
    20240118,
    '2024-01-18',
    'Thursday',
    18,
    18,
    3,
    'January',
    1,
    'Q1',
    2024,
    FALSE
);

INSERT INTO dim_geography (
    geography_key, city, state, country, region, population, timezone
) VALUES
(1, 'New York', 'NY', 'USA', 'Northeast', 8336817, 'America/New_York'),
(2, 'Los Angeles', 'CA', 'USA', 'West', 3979576, 'America/Los_Angeles'),
(3, 'Chicago', 'IL', 'USA', 'Midwest', 2693976, 'America/Chicago');

-- Populate fact table
INSERT INTO fact_sales (
    customer_key, product_key, time_key, geography_key, order_id,
    quantity, unit_price, total_amount, discount_amount, net_amount,
    cost_amount, profit_amount, profit_margin_percent
) VALUES
(
    1,
    1,
    20240115,
    1,
    1,
    1,
    1299.99,
    1299.99,
    0.00,
    1299.99,
    800.00,
    499.99,
    38.46
),
(1, 2, 20240115, 1, 1, 1, 49.99, 49.99, 0.00, 49.99, 15.00, 34.99, 70.00),
(1, 4, 20240115, 1, 1, 1, 89.99, 89.99, 0.00, 89.99, 30.00, 59.99, 66.67),
(2, 2, 20240116, 2, 2, 1, 49.99, 49.99, 0.00, 49.99, 15.00, 34.99, 70.00),
(2, 4, 20240116, 2, 2, 1, 89.99, 89.99, 0.00, 89.99, 30.00, 59.99, 66.67),
(3, 3, 20240117, 3, 3, 1, 899.99, 899.99, 0.00, 899.99, 450.00, 449.99, 50.00),
(1, 4, 20240118, 1, 4, 1, 89.99, 89.99, 0.00, 89.99, 30.00, 59.99, 66.67);

-- Example 2: Analytics Queries on Star Schema
-- Demonstrate the power of star schema for analytics

-- Sales by customer segment
SELECT
    dc.customer_segment,
    COUNT(DISTINCT fs.order_id) AS total_orders,
    SUM(fs.quantity) AS total_quantity,
    SUM(fs.net_amount) AS total_revenue,
    SUM(fs.profit_amount) AS total_profit,
    ROUND(AVG(fs.profit_margin_percent), 2) AS avg_profit_margin,
    ROUND(SUM(fs.profit_amount) / SUM(fs.net_amount) * 100, 2)
        AS overall_profit_margin
FROM fact_sales AS fs
INNER JOIN dim_customers AS dc ON fs.customer_key = dc.customer_key
GROUP BY dc.customer_segment
ORDER BY total_revenue DESC;

-- Sales by product category and time
SELECT
    dp.category_name,
    dt.month_name,
    dt.year,
    COUNT(DISTINCT fs.order_id) AS total_orders,
    SUM(fs.quantity) AS total_quantity,
    SUM(fs.net_amount) AS total_revenue,
    SUM(fs.profit_amount) AS total_profit
FROM fact_sales AS fs
INNER JOIN dim_products AS dp ON fs.product_key = dp.product_key
INNER JOIN dim_time AS dt ON fs.time_key = dt.time_key
GROUP BY dp.category_name, dt.month_name, dt.year, dt.month_number
ORDER BY dt.year ASC, dt.month_number ASC, total_revenue DESC;

-- Geographic sales analysis
SELECT
    dg.city,
    dg.state,
    dg.region,
    COUNT(DISTINCT fs.order_id) AS total_orders,
    COUNT(DISTINCT fs.customer_key) AS unique_customers,
    SUM(fs.net_amount) AS total_revenue,
    ROUND(AVG(fs.net_amount), 2) AS avg_order_value,
    SUM(fs.profit_amount) AS total_profit
FROM fact_sales AS fs
INNER JOIN dim_geography AS dg ON fs.geography_key = dg.geography_key
GROUP BY dg.city, dg.state, dg.region
ORDER BY total_revenue DESC;

-- Example 3: Snowflake Schema Extension
-- Demonstrate snowflake schema for more detailed dimensions

-- Extended product dimension (snowflake)
CREATE TABLE dim_product_categories (
    category_key INT PRIMARY KEY,
    category_name VARCHAR(100),
    parent_category_name VARCHAR(100),
    category_level INT,
    category_path VARCHAR(200)
);

CREATE TABLE dim_product_brands (
    brand_key INT PRIMARY KEY,
    brand_name VARCHAR(100),
    brand_description TEXT,
    brand_country VARCHAR(50),
    brand_website VARCHAR(200)
);

-- Extended customer dimension (snowflake)
CREATE TABLE dim_customer_segments (
    segment_key INT PRIMARY KEY,
    segment_name VARCHAR(50),
    segment_description TEXT,
    min_lifetime_value DECIMAL(12, 2),
    max_lifetime_value DECIMAL(12, 2)
);

-- Populate snowflake dimensions
INSERT INTO dim_product_categories VALUES
(1, 'Electronics', NULL, 1, 'Electronics'),
(2, 'Computers', 'Electronics', 2, 'Electronics > Computers'),
(3, 'Accessories', 'Electronics', 2, 'Electronics > Accessories'),
(4, 'Smartphones', 'Electronics', 2, 'Electronics > Smartphones');

INSERT INTO dim_product_brands VALUES
(
    1,
    'TechCorp',
    'Leading technology manufacturer',
    'USA',
    'https://techcorp.com'
),
(
    2,
    'MobilePro',
    'Premium mobile device brand',
    'South Korea',
    'https://mobilepro.com'
),
(
    3,
    'AccessoryMax',
    'Quality accessories provider',
    'China',
    'https://accessorymax.com'
);

INSERT INTO dim_customer_segments VALUES
(
    1,
    'Premium',
    'High-value customers with significant purchase history',
    1000.00,
    NULL
),
(
    2,
    'Standard',
    'Regular customers with moderate purchase history',
    100.00,
    999.99
),
(3, 'Basic', 'New or occasional customers', 0.00, 99.99);

-- Example 4: Materialized Views for Analytics
-- Demonstrate materialized views for pre-computed analytics

-- Materialized view for daily sales summary
CREATE MATERIALIZED VIEW mv_daily_sales_summary AS
SELECT
    dt.full_date,
    dt.day_of_week,
    dt.month_name,
    dt.quarter,
    dt.year,
    COUNT(DISTINCT fs.order_id) AS total_orders,
    COUNT(DISTINCT fs.customer_key) AS unique_customers,
    SUM(fs.quantity) AS total_quantity,
    SUM(fs.net_amount) AS total_revenue,
    SUM(fs.profit_amount) AS total_profit,
    ROUND(AVG(fs.net_amount), 2) AS avg_order_value,
    ROUND(SUM(fs.profit_amount) / SUM(fs.net_amount) * 100, 2)
        AS profit_margin_percent
FROM fact_sales AS fs
INNER JOIN dim_time AS dt ON fs.time_key = dt.time_key
GROUP BY dt.full_date, dt.day_of_week, dt.month_name, dt.quarter, dt.year
ORDER BY dt.full_date;

-- Materialized view for customer lifetime value
CREATE MATERIALIZED VIEW mv_customer_lifetime_value AS
SELECT
    dc.customer_key,
    dc.customer_name,
    dc.customer_segment,
    COUNT(DISTINCT fs.order_id) AS total_orders,
    SUM(fs.net_amount) AS lifetime_value,
    SUM(fs.profit_amount) AS lifetime_profit,
    ROUND(AVG(fs.net_amount), 2) AS avg_order_value,
    MIN(dt.full_date) AS first_order_date,
    MAX(dt.full_date) AS last_order_date,
    ROUND(SUM(fs.net_amount) / COUNT(DISTINCT fs.order_id), 2)
        AS customer_value_per_order
FROM fact_sales AS fs
INNER JOIN dim_customers AS dc ON fs.customer_key = dc.customer_key
INNER JOIN dim_time AS dt ON fs.time_key = dt.time_key
GROUP BY dc.customer_key, dc.customer_name, dc.customer_segment
ORDER BY lifetime_value DESC;

-- Query the materialized views
SELECT * FROM mv_daily_sales_summary
ORDER BY full_date;

SELECT * FROM mv_customer_lifetime_value LIMIT 10;

-- Example 5: Incremental Loading Strategy
-- Demonstrate how to incrementally load fact tables
-- NOTE: Function definition removed due to SQL parser limitations
-- In a real implementation, this would handle incremental loading

-- Clean up
DROP TABLE IF EXISTS customers_normalized CASCADE;
DROP TABLE IF EXISTS addresses_normalized CASCADE;
DROP TABLE IF EXISTS products_normalized CASCADE;
DROP TABLE IF EXISTS categories_normalized CASCADE;
DROP TABLE IF EXISTS brands_normalized CASCADE;
DROP TABLE IF EXISTS orders_normalized CASCADE;
DROP TABLE IF EXISTS order_items_normalized CASCADE;
DROP TABLE IF EXISTS dim_customers CASCADE;
DROP TABLE IF EXISTS dim_products CASCADE;
DROP TABLE IF EXISTS dim_time CASCADE;
DROP TABLE IF EXISTS dim_geography CASCADE;
DROP TABLE IF EXISTS fact_sales CASCADE;
DROP TABLE IF EXISTS dim_product_categories CASCADE;
DROP TABLE IF EXISTS dim_product_brands CASCADE;
DROP TABLE IF EXISTS dim_customer_segments CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mv_daily_sales_summary CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mv_customer_lifetime_value CASCADE;
DROP FUNCTION IF EXISTS LOAD_SALES_INCREMENTAL(DATE, DATE) CASCADE;
