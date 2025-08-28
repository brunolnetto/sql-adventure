-- =====================================================
-- Performance Tuning Quest: Aggregation Optimization
-- =====================================================
-- 
-- PURPOSE: Demonstrate optimizing aggregation queries for better performance
-- DIFFICULTY: 🟡 Intermediate (10-15 min)
-- CONCEPTS: Aggregation optimization, GROUP BY efficiency, window functions vs aggregations

-- Example 1: Basic Aggregation Optimization
-- Demonstrate optimizing simple aggregation queries

-- Create sample tables
CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    customer_id INT,
    product_id INT,
    sale_date DATE,
    quantity INT,
    unit_price DECIMAL(10, 2),
    total_amount DECIMAL(10, 2),
    region VARCHAR(50),
    salesperson_id INT
);

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    city VARCHAR(100),
    state VARCHAR(50),
    customer_segment VARCHAR(20)
);

-- Insert sample data
INSERT INTO customers VALUES
(1, 'Alice Johnson', 'New York', 'NY', 'Premium'),
(2, 'Bob Smith', 'Los Angeles', 'CA', 'Standard'),
(3, 'Carol Davis', 'Chicago', 'IL', 'Premium'),
(4, 'David Wilson', 'Houston', 'TX', 'Standard');

INSERT INTO sales VALUES
(1, 1, 101, '2024-01-15', 2, 50.00, 100.00, 'North', 1),
(2, 1, 102, '2024-01-16', 1, 75.00, 75.00, 'North', 1),
(3, 2, 101, '2024-01-17', 3, 50.00, 150.00, 'South', 2),
(4, 3, 103, '2024-01-18', 1, 200.00, 200.00, 'East', 3),
(5, 4, 102, '2024-01-19', 2, 75.00, 150.00, 'West', 4),
(6, 1, 104, '2024-01-20', 1, 100.00, 100.00, 'North', 1);

-- Create indexes for aggregation optimization
CREATE INDEX idx_sales_customer_date ON sales (customer_id, sale_date);
CREATE INDEX idx_sales_region_date ON sales (region, sale_date);
CREATE INDEX idx_sales_amount ON sales (total_amount);

-- Example 2: GROUP BY Optimization
-- Demonstrate optimizing GROUP BY clauses

-- POOR: GROUP BY without proper indexing
SELECT
    customer_id,
    COUNT(*) AS total_sales,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_sale
FROM sales
GROUP BY customer_id;

-- BETTER: GROUP BY with indexed columns
SELECT
    s.customer_id,
    c.customer_name,
    COUNT(*) AS total_sales,
    SUM(s.total_amount) AS total_revenue,
    AVG(s.total_amount) AS avg_sale
FROM sales AS s
INNER JOIN customers AS c ON s.customer_id = c.customer_id
GROUP BY s.customer_id, c.customer_name
ORDER BY total_revenue DESC;

-- Example 3: Filtering Before Aggregation
-- Demonstrate filtering early for better performance

-- POOR: Aggregate then filter
SELECT
    customer_id,
    COUNT(*) AS total_sales,
    SUM(total_amount) AS total_revenue
FROM sales
GROUP BY customer_id
HAVING SUM(total_amount) > 200;

-- BETTER: Filter before aggregation
SELECT
    customer_id,
    COUNT(*) AS total_sales,
    SUM(total_amount) AS total_revenue
FROM sales
WHERE total_amount > 50  -- Filter early
GROUP BY customer_id
HAVING SUM(total_amount) > 200;

-- Example 4: Window Functions vs Aggregations
-- Demonstrate when to use each approach

-- Using aggregation (for summary data)
SELECT
    region,
    COUNT(*) AS total_sales,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_sale
FROM sales
GROUP BY region
ORDER BY total_revenue DESC;

-- Using window functions (for row-level data with aggregates)
SELECT
    sale_id,
    customer_id,
    total_amount,
    region,
    SUM(total_amount) OVER (PARTITION BY region) AS region_total,
    AVG(total_amount) OVER (PARTITION BY region) AS region_avg,
    ROW_NUMBER()
        OVER (PARTITION BY region ORDER BY total_amount DESC)
        AS region_rank
FROM sales
ORDER BY region ASC, total_amount DESC;

-- Example 5: Complex Aggregation Optimization
-- Demonstrate optimizing complex aggregation queries

-- POOR: Multiple subqueries
SELECT
    c.customer_name,
    c.customer_segment,
    (
        SELECT COUNT(*) FROM sales AS s
        WHERE s.customer_id = c.customer_id)
        AS total_sales,
    (
        SELECT SUM(total_amount) FROM sales AS s
        WHERE s.customer_id = c.customer_id
    ) AS total_revenue,
    (
        SELECT AVG(total_amount) FROM sales AS s
        WHERE s.customer_id = c.customer_id
    ) AS avg_sale
FROM customers AS c;

-- BETTER: Single aggregation with JOIN
WITH sales_stats AS (
    SELECT
        customer_id,
        COUNT(*) AS total_sales,
        SUM(total_amount) AS total_revenue,
        AVG(total_amount) AS avg_sale
    FROM sales
    GROUP BY customer_id
)

SELECT
    c.customer_name,
    c.customer_segment,
    COALESCE(sales_stats.total_sales, 0) AS total_sales,
    COALESCE(sales_stats.total_revenue, 0) AS total_revenue,
    COALESCE(sales_stats.avg_sale, 0) AS avg_sale
FROM customers AS c
LEFT JOIN sales_stats ON c.customer_id = sales_stats.customer_id
ORDER BY sales_stats.total_revenue DESC NULLS LAST;

-- Example 6: Time-Based Aggregation Optimization
-- Demonstrate optimizing time-based aggregations

-- Daily sales aggregation
SELECT
    sale_date,
    COUNT(*) AS daily_sales,
    SUM(total_amount) AS daily_revenue,
    AVG(total_amount) AS avg_daily_sale
FROM sales
WHERE sale_date >= '2024-01-01'
GROUP BY sale_date
ORDER BY sale_date;

-- Monthly sales aggregation with customer breakdown
SELECT
    c.customer_segment,
    DATE_TRUNC('month', sale_date) AS month,
    COUNT(*) AS monthly_sales,
    SUM(s.total_amount) AS monthly_revenue,
    AVG(s.total_amount) AS avg_monthly_sale
FROM sales AS s
INNER JOIN customers AS c ON s.customer_id = c.customer_id
WHERE sale_date >= '2024-01-01'
GROUP BY DATE_TRUNC('month', sale_date), c.customer_segment
ORDER BY month ASC, monthly_revenue DESC;

-- Example 7: Conditional Aggregation
-- Demonstrate optimizing conditional aggregations

-- Using CASE statements for conditional aggregation
SELECT
    region,
    COUNT(*) AS total_sales,
    SUM(CASE WHEN total_amount > 100 THEN total_amount ELSE 0 END)
        AS high_value_sales,
    COUNT(CASE WHEN total_amount > 100 THEN 1 END) AS high_value_count,
    AVG(CASE WHEN total_amount > 100 THEN total_amount END)
        AS avg_high_value_sale
FROM sales
GROUP BY region
ORDER BY total_sales DESC;

-- Using FILTER clause (PostgreSQL specific)
SELECT
    region,
    COUNT(*) AS total_sales,
    SUM(total_amount) FILTER (WHERE total_amount > 100) AS high_value_sales,
    COUNT(*) FILTER (WHERE total_amount > 100) AS high_value_count,
    AVG(total_amount) FILTER (WHERE total_amount > 100) AS avg_high_value_sale
FROM sales
GROUP BY region
ORDER BY total_sales DESC;

-- Clean up
DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
