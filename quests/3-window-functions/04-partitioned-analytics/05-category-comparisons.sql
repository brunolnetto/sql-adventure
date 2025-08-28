-- =====================================================
-- Window Functions quest: Category Comparisons & Advanced Analysis
-- =====================================================

-- PURPOSE: Demonstrate advanced window function partitioning for 
--          regional analysis, performance gaps, and rolling calculations
-- LEARNING OUTCOMES: Students will understand how to use window functions for
--                    regional performance analysis, statistical comparisons,
--                    and rolling calculations within categories
-- EXPECTED RESULTS: 
-- 1. Regional performance analysis within categories
-- 2. Performance gap analysis using statistical measures
-- 3. Rolling averages and cumulative calculations
-- 4. Comprehensive category performance summaries
-- DIFFICULTY: 🟡 Intermediate (10-20 min)
-- CONCEPTS: Rolling windows, statistical analysis, regional comparisons,
--           performance gaps, cumulative calculations

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS product_sales CASCADE;

-- Create comprehensive product sales table
CREATE TABLE product_sales (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    subcategory VARCHAR(50),
    sales_amount DECIMAL(10, 2),
    units_sold INT,
    sale_date DATE,
    region VARCHAR(50)
);

-- Insert realistic sales data across multiple categories
INSERT INTO product_sales VALUES
-- Electronics Category
(
    1,
    'Laptop Pro',
    'Electronics',
    'Computers',
    1200.00,
    15,
    '2024-01-15',
    'North'
),
(
    2,
    'Wireless Mouse',
    'Electronics',
    'Accessories',
    45.00,
    120,
    '2024-01-16',
    'North'
),
(
    3,
    'Gaming Keyboard',
    'Electronics',
    'Accessories',
    150.00,
    25,
    '2024-01-17',
    'South'
),
(4, '4K Monitor', 'Electronics', 'Displays', 450.00, 8, '2024-01-18', 'East'),
(
    5,
    'Bluetooth Headphones',
    'Electronics',
    'Audio',
    89.99,
    45,
    '2024-01-19',
    'West'
),
(6, 'Tablet Air', 'Electronics', 'Mobile', 350.00, 12, '2024-01-20', 'North'),

-- Clothing Category
(7, 'Denim Jacket', 'Clothing', 'Outerwear', 85.00, 30, '2024-01-15', 'North'),
(8, 'Running Shoes', 'Clothing', 'Footwear', 120.00, 22, '2024-01-16', 'South'),
(9, 'Cotton T-Shirt', 'Clothing', 'Casual', 25.00, 150, '2024-01-17', 'East'),
(10, 'Formal Shirt', 'Clothing', 'Business', 65.00, 18, '2024-01-18', 'West'),
(11, 'Winter Coat', 'Clothing', 'Outerwear', 180.00, 12, '2024-01-19', 'North'),
(12, 'Sneakers', 'Clothing', 'Footwear', 95.00, 28, '2024-01-20', 'South'),

-- Home & Garden Category
(
    13,
    'Garden Hose',
    'Home & Garden',
    'Outdoor',
    35.00,
    40,
    '2024-01-15',
    'West'
),
(
    14,
    'Kitchen Blender',
    'Home & Garden',
    'Appliances',
    75.00,
    15,
    '2024-01-16',
    'East'
),
(
    15,
    'LED Light Bulbs',
    'Home & Garden',
    'Lighting',
    12.99,
    200,
    '2024-01-17',
    'North'
),
(
    16,
    'Coffee Maker',
    'Home & Garden',
    'Appliances',
    120.00,
    10,
    '2024-01-18',
    'South'
),
(
    17,
    'Plant Pot Set',
    'Home & Garden',
    'Decor',
    45.00,
    25,
    '2024-01-19',
    'West'
),
(18, 'Tool Kit', 'Home & Garden', 'Tools', 85.00, 8, '2024-01-20', 'East');

-- =====================================================
-- Example 1: Regional Performance by Category
-- =====================================================

-- Analyze regional performance within categories
SELECT
    category,
    region,
    COUNT(*) AS product_count,
    ROUND(AVG(sales_amount), 2) AS avg_sales,
    ROUND(SUM(sales_amount), 2) AS total_sales,
    ROW_NUMBER()
        OVER (PARTITION BY category ORDER BY SUM(sales_amount) DESC)
        AS category_region_rank,
    ROUND(
        SUM(sales_amount)
        * 100.0
        / SUM(SUM(sales_amount)) OVER (PARTITION BY category),
        2
    ) AS category_contribution_pct
FROM product_sales
GROUP BY category, region
ORDER BY category ASC, total_sales DESC;

-- =====================================================
-- Example 2: Performance Gap Analysis
-- =====================================================

-- Identify performance gaps within categories
WITH category_stats AS (
    SELECT
        category,
        AVG(sales_amount) AS category_avg,
        STDDEV(sales_amount) AS category_stddev
    FROM product_sales
    GROUP BY category
)

SELECT
    ps.product_name,
    ps.category,
    ps.sales_amount,
    cs.category_avg,
    cs.category_stddev,
    ROUND(
        (ps.sales_amount - cs.category_avg) / cs.category_stddev, 2
    ) AS z_score,
    CASE
        WHEN
            ps.sales_amount > cs.category_avg + cs.category_stddev
            THEN 'High Performer'
        WHEN
            ps.sales_amount < cs.category_avg - cs.category_stddev
            THEN 'Low Performer'
        ELSE 'Average Performer'
    END AS performance_level
FROM product_sales AS ps
INNER JOIN category_stats AS cs ON ps.category = cs.category
ORDER BY ps.category ASC, ps.sales_amount DESC;

-- =====================================================
-- Example 3: Rolling Category Analysis
-- =====================================================

-- Show rolling averages within categories
SELECT
    product_name,
    category,
    sales_amount,
    ROUND(
        AVG(sales_amount) OVER (
            PARTITION BY category
            ORDER BY sales_amount
            ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
        ), 2
    ) AS rolling_avg_3,
    ROUND(
        AVG(sales_amount) OVER (
            PARTITION BY category
            ORDER BY sales_amount
            ROWS UNBOUNDED PRECEDING
        ), 2
    ) AS cumulative_avg
FROM product_sales
ORDER BY category, sales_amount;

-- =====================================================
-- Example 4: Category Performance Summary
-- =====================================================

-- Comprehensive category performance summary
WITH category_summary AS (
    SELECT
        category,
        COUNT(*) AS total_products,
        ROUND(AVG(sales_amount), 2) AS avg_sales,
        ROUND(SUM(sales_amount), 2) AS total_sales,
        ROUND(MAX(sales_amount), 2) AS max_sales,
        ROUND(MIN(sales_amount), 2) AS min_sales,
        ROUND(
            (MAX(sales_amount) - MIN(sales_amount)) * 100.0 / AVG(sales_amount), 2
        ) AS variation_pct
    FROM product_sales
    GROUP BY category
)
SELECT
    category,
    total_products,
    avg_sales,
    total_sales,
    max_sales,
    min_sales,
    variation_pct,
    ROUND(
        total_sales * 100.0 / SUM(total_sales) OVER (), 2
    ) AS market_share_pct,
    ROUND(
        (PERCENT_RANK() OVER (ORDER BY total_sales) * 100)::numeric, 1
    ) AS category_percentile
FROM category_summary
ORDER BY total_sales DESC;

-- Clean up
DROP TABLE IF EXISTS product_sales CASCADE;
