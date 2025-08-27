-- Performance Tuning Quest: Advanced Query Optimization
-- PURPOSE: Demonstrate expert-level query optimization techniques
-- DIFFICULTY: ⚫ Expert (30-45 min)
-- CONCEPTS: Query rewriting, advanced indexing, materialized views, query hints

-- Example 1: Query Rewriting for Performance
-- Demonstrate rewriting queries for better performance

-- Create sample tables with large datasets
CREATE TABLE sales_transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    customer_id INT,
    product_id INT,
    sale_date DATE,
    quantity INT,
    unit_price DECIMAL(10, 2),
    total_amount DECIMAL(10, 2),
    region VARCHAR(50),
    salesperson_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    city VARCHAR(100),
    state VARCHAR(50),
    country VARCHAR(50),
    customer_segment VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(200),
    category VARCHAR(100),
    brand VARCHAR(100),
    unit_cost DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert large sample dataset
INSERT INTO customers (
    customer_id, customer_name, email, city, state, country, customer_segment
)
SELECT
    GENERATE_SERIES(1, 10000) AS customer_id,
    'Customer ' || GENERATE_SERIES(1, 10000) AS customer_name,
    'customer' || GENERATE_SERIES(1, 10000) || '@email.com' AS email,
    CASE (RANDOM() * 4)::INT
        WHEN 0 THEN 'New York'
        WHEN 1 THEN 'Los Angeles'
        WHEN 2 THEN 'Chicago'
        WHEN 3 THEN 'Houston'
    END AS city,
    CASE (RANDOM() * 4)::INT
        WHEN 0 THEN 'NY'
        WHEN 1 THEN 'CA'
        WHEN 2 THEN 'IL'
        WHEN 3 THEN 'TX'
    END AS state,
    'USA' AS country,
    CASE (RANDOM() * 2)::INT
        WHEN 0 THEN 'Premium'
        WHEN 1 THEN 'Standard'
    END AS customer_segment;

INSERT INTO products (product_id, product_name, category, brand, unit_cost)
SELECT
    GENERATE_SERIES(1, 1000) AS product_id,
    'Product ' || GENERATE_SERIES(1, 1000) AS product_name,
    CASE (RANDOM() * 4)::INT
        WHEN 0 THEN 'Electronics'
        WHEN 1 THEN 'Clothing'
        WHEN 2 THEN 'Books'
        WHEN 3 THEN 'Home'
    END AS category,
    'Brand ' || (RANDOM() * 10)::INT AS brand,
    (RANDOM() * 1000 + 10)::DECIMAL(10, 2) AS unit_cost;

INSERT INTO sales_transactions (
    customer_id,
    product_id,
    sale_date,
    quantity,
    unit_price,
    total_amount,
    region,
    salesperson_id
)
SELECT
    (RANDOM() * 10000 + 1)::INT AS customer_id,
    (RANDOM() * 1000 + 1)::INT AS product_id,
    '2024-01-01'::DATE + (RANDOM() * 365)::INT AS sale_date,
    (RANDOM() * 10 + 1)::INT AS quantity,
    (RANDOM() * 500 + 10)::DECIMAL(10, 2) AS unit_price,
    (RANDOM() * 5000 + 10)::DECIMAL(10, 2) AS total_amount,
    CASE (RANDOM() * 4)::INT
        WHEN 0 THEN 'North'
        WHEN 1 THEN 'South'
        WHEN 2 THEN 'East'
        WHEN 3 THEN 'West'
    END AS region,
    (RANDOM() * 100 + 1)::INT AS salesperson_id
FROM GENERATE_SERIES(1, 100000);

-- Create comprehensive indexes
CREATE INDEX idx_sales_customer_date ON sales_transactions (
    customer_id, sale_date
);
CREATE INDEX idx_sales_product_date ON sales_transactions (
    product_id, sale_date
);
CREATE INDEX idx_sales_region_date ON sales_transactions (region, sale_date);
CREATE INDEX idx_sales_amount ON sales_transactions (total_amount);
CREATE INDEX idx_customers_segment ON customers (customer_segment);
CREATE INDEX idx_products_category ON products (category);

-- Example 2: Complex Query Optimization
-- Demonstrate optimizing complex analytical queries

-- POOR: Complex query with multiple subqueries
SELECT
    c.customer_name,
    c.customer_segment,
    COUNT(s.transaction_id) AS total_transactions,
    SUM(s.total_amount) AS total_spent,
    AVG(s.total_amount) AS avg_transaction,
    (
        SELECT COUNT(*) FROM sales_transactions AS s2
        WHERE
            s2.customer_id = c.customer_id
            AND s2.sale_date >= '2024-06-01'
    ) AS recent_transactions
FROM customers AS c
LEFT JOIN sales_transactions AS s ON c.customer_id = s.customer_id
WHERE c.customer_segment = 'Premium'
GROUP BY c.customer_id, c.customer_name, c.customer_segment
HAVING COUNT(s.transaction_id) > 5;

-- BETTER: Optimized query with CTEs and pre-aggregation
WITH customer_stats AS (
    SELECT
        customer_id,
        COUNT(transaction_id) AS total_transactions,
        SUM(total_amount) AS total_spent,
        AVG(total_amount) AS avg_transaction
    FROM sales_transactions
    GROUP BY customer_id
),

recent_transactions AS (
    SELECT
        customer_id,
        COUNT(*) AS recent_count
    FROM sales_transactions
    WHERE sale_date >= '2024-06-01'
    GROUP BY customer_id
)

SELECT
    c.customer_name,
    c.customer_segment,
    COALESCE(cs.total_transactions, 0) AS total_transactions,
    COALESCE(cs.total_spent, 0) AS total_spent,
    COALESCE(cs.avg_transaction, 0) AS avg_transaction,
    COALESCE(rt.recent_count, 0) AS recent_transactions
FROM customers AS c
LEFT JOIN customer_stats AS cs ON c.customer_id = cs.customer_id
LEFT JOIN recent_transactions AS rt ON c.customer_id = rt.customer_id
WHERE
    c.customer_segment = 'Premium'
    AND COALESCE(cs.total_transactions, 0) > 5
ORDER BY cs.total_spent DESC;

-- Example 3: Materialized Views for Performance
-- Demonstrate using materialized views for complex aggregations

-- Create materialized view for customer analytics
CREATE MATERIALIZED VIEW mv_customer_analytics AS
SELECT
    c.customer_id,
    c.customer_name,
    c.customer_segment,
    c.city,
    c.state,
    COUNT(s.transaction_id) AS total_transactions,
    SUM(s.total_amount) AS total_spent,
    AVG(s.total_amount) AS avg_transaction,
    MIN(s.sale_date) AS first_purchase,
    MAX(s.sale_date) AS last_purchase,
    COUNT(DISTINCT s.product_id) AS unique_products,
    COUNT(DISTINCT DATE_TRUNC('month', s.sale_date)) AS active_months
FROM customers AS c
LEFT JOIN sales_transactions AS s ON c.customer_id = s.customer_id
GROUP BY c.customer_id, c.customer_name, c.customer_segment, c.city, c.state;

-- Create index on materialized view
CREATE INDEX idx_mv_customer_segment ON mv_customer_analytics (
    customer_segment
);
CREATE INDEX idx_mv_total_spent ON mv_customer_analytics (total_spent);

-- Query using materialized view (much faster)
SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    AVG(total_spent) AS avg_total_spent,
    SUM(total_spent) AS segment_total
FROM mv_customer_analytics
WHERE total_transactions > 5
GROUP BY customer_segment
ORDER BY segment_total DESC;

-- Example 4: Advanced Indexing Strategies
-- Demonstrate advanced indexing techniques

-- Partial indexes for specific conditions
CREATE INDEX idx_sales_premium_customers ON sales_transactions (
    customer_id, sale_date
)
WHERE total_amount > 1000;

CREATE INDEX idx_sales_recent ON sales_transactions (sale_date, customer_id)
WHERE sale_date >= '2024-01-01';

-- Expression indexes
CREATE INDEX idx_customers_email_domain ON customers (
    SUBSTRING(email FROM '@(.*)$')
);

-- Query using partial index
SELECT
    c.customer_name,
    COUNT(s.transaction_id) AS high_value_transactions,
    SUM(s.total_amount) AS high_value_total
FROM customers AS c
INNER JOIN sales_transactions AS s ON c.customer_id = s.customer_id
WHERE
    s.total_amount > 1000
    AND s.sale_date >= '2024-01-01'
GROUP BY c.customer_id, c.customer_name
ORDER BY high_value_total DESC;

-- Example 5: Query Hints and Optimization
-- Demonstrate using query hints for optimization

-- Force index usage
SELECT /*+ INDEX(sales_transactions idx_sales_customer_date) */
    c.customer_name,
    COUNT(s.transaction_id) AS transaction_count
FROM customers AS c
INNER JOIN sales_transactions AS s ON c.customer_id = s.customer_id
WHERE s.sale_date >= '2024-06-01'
GROUP BY c.customer_id, c.customer_name
ORDER BY transaction_count DESC;

-- Example 6: Performance Monitoring
-- Demonstrate monitoring query performance

-- Check index usage
-- Note: These queries require specific PostgreSQL configuration and may not work in all environments
-- Skipping these queries to avoid compatibility issues

-- Clean up
DROP MATERIALIZED VIEW IF EXISTS mv_customer_analytics CASCADE;
DROP TABLE IF EXISTS sales_transactions CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS products CASCADE;
