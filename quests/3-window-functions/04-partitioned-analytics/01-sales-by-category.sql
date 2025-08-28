-- =====================================================
-- Window Functions: Sales by Category Analysis
-- =====================================================

-- PURPOSE: Demonstrate window functions for category-based sales analysis and ranking
-- LEARNING OUTCOMES:
--   - Master PARTITION BY for category-based calculations
--   - Understand ranking within groups
--   - Apply multiple window functions simultaneously
-- EXPECTED RESULTS: Comprehensive sales analysis with category rankings and performance metrics
-- DIFFICULTY: 🟡 Intermediate (10-20 min)
-- CONCEPTS: PARTITION BY, ROW_NUMBER(), RANK(), DENSE_RANK(), NTILE(), category analysis

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS sales_data CASCADE;

-- Create comprehensive sales data table
CREATE TABLE sales_data (
    sale_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    subcategory VARCHAR(50),
    sale_amount DECIMAL(10, 2),
    sale_date DATE,
    region VARCHAR(50),
    salesperson VARCHAR(100)
);

-- Insert comprehensive sample data
INSERT INTO sales_data VALUES
-- Electronics Category
(
    1,
    'Laptop Pro',
    'Electronics',
    'Computers',
    1200.00,
    '2024-01-15',
    'North',
    'Alice Johnson'
),
(
    2,
    'Wireless Mouse',
    'Electronics',
    'Accessories',
    45.00,
    '2024-01-16',
    'North',
    'Bob Smith'
),
(
    3,
    'Gaming Keyboard',
    'Electronics',
    'Accessories',
    150.00,
    '2024-01-17',
    'South',
    'Carol Davis'
),
(
    4,
    '4K Monitor',
    'Electronics',
    'Displays',
    450.00,
    '2024-01-18',
    'East',
    'David Wilson'
),
(
    5,
    'Bluetooth Headphones',
    'Electronics',
    'Audio',
    89.99,
    '2024-01-19',
    'West',
    'Eve Brown'
),
(
    6,
    'Tablet Pro',
    'Electronics',
    'Mobile',
    299.99,
    '2024-01-20',
    'North',
    'Frank Miller'
),
(
    7,
    'Smart Watch',
    'Electronics',
    'Wearables',
    199.99,
    '2024-01-21',
    'South',
    'Grace Lee'
),
(
    8,
    'USB Drive',
    'Electronics',
    'Storage',
    25.00,
    '2024-01-22',
    'East',
    'Henry Taylor'
),

-- Furniture Category
(
    9,
    'Office Chair',
    'Furniture',
    'Seating',
    299.99,
    '2024-01-15',
    'North',
    'Alice Johnson'
),
(
    10,
    'Desk Lamp',
    'Furniture',
    'Lighting',
    89.99,
    '2024-01-16',
    'South',
    'Bob Smith'
),
(
    11,
    'Standing Desk',
    'Furniture',
    'Workstations',
    599.99,
    '2024-01-17',
    'East',
    'Carol Davis'
),
(
    12,
    'Bookshelf',
    'Furniture',
    'Storage',
    199.99,
    '2024-01-18',
    'West',
    'David Wilson'
),
(
    13,
    'Coffee Table',
    'Furniture',
    'Tables',
    349.99,
    '2024-01-19',
    'North',
    'Eve Brown'
),
(
    14,
    'Sofa',
    'Furniture',
    'Seating',
    899.99,
    '2024-01-20',
    'South',
    'Frank Miller'
),
(
    15,
    'Dining Table',
    'Furniture',
    'Tables',
    799.99,
    '2024-01-21',
    'East',
    'Grace Lee'
),
(
    16,
    'Bed Frame',
    'Furniture',
    'Bedroom',
    449.99,
    '2024-01-22',
    'West',
    'Henry Taylor'
),

-- Clothing Category
(
    17,
    'Business Suit',
    'Clothing',
    'Formal',
    299.99,
    '2024-01-15',
    'North',
    'Alice Johnson'
),
(
    18,
    'Casual T-Shirt',
    'Clothing',
    'Casual',
    25.00,
    '2024-01-16',
    'South',
    'Bob Smith'
),
(
    19,
    'Running Shoes',
    'Clothing',
    'Athletic',
    89.99,
    '2024-01-17',
    'East',
    'Carol Davis'
),
(
    20,
    'Winter Jacket',
    'Clothing',
    'Outerwear',
    199.99,
    '2024-01-18',
    'West',
    'David Wilson'
),
(21, 'Jeans', 'Clothing', 'Casual', 79.99, '2024-01-19', 'North', 'Eve Brown'),
(
    22,
    'Dress Shirt',
    'Clothing',
    'Formal',
    59.99,
    '2024-01-20',
    'South',
    'Frank Miller'
),
(23, 'Hoodie', 'Clothing', 'Casual', 45.00, '2024-01-21', 'East', 'Grace Lee'),
(
    24,
    'Dress',
    'Clothing',
    'Formal',
    129.99,
    '2024-01-22',
    'West',
    'Henry Taylor'
);

-- =====================================================
-- Example 1: Basic Category Ranking
-- =====================================================

-- Rank products within each category by sale amount
SELECT
    product_name,
    category,
    sale_amount,
    ROW_NUMBER()
        OVER (PARTITION BY category ORDER BY sale_amount DESC)
        AS category_rank,
    RANK()
        OVER (PARTITION BY category ORDER BY sale_amount DESC)
        AS category_rank_with_ties,
    DENSE_RANK()
        OVER (PARTITION BY category ORDER BY sale_amount DESC)
        AS category_dense_rank
FROM sales_data
ORDER BY category ASC, sale_amount DESC;

-- =====================================================
-- Example 2: Category Performance Analysis
-- =====================================================

-- Analyze category performance with multiple metrics
WITH category_summary AS (
    SELECT
        category,
        COUNT(*) AS total_sales,
        SUM(sale_amount) AS total_revenue,
        AVG(sale_amount) AS avg_sale_amount,
        MAX(sale_amount) AS max_sale_amount,
        MIN(sale_amount) AS min_sale_amount
    FROM sales_data
    GROUP BY category
)
SELECT
    category,
    total_sales,
    total_revenue,
    avg_sale_amount,
    max_sale_amount,
    min_sale_amount,
    ROUND(AVG(avg_sale_amount) OVER (ORDER BY total_revenue DESC), 2)
        AS overall_avg,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM category_summary
ORDER BY total_revenue DESC;

-- =====================================================
-- Example 3: Subcategory Analysis within Categories
-- =====================================================

-- Analyze subcategories within each category
WITH subcategory_summary AS (
    SELECT
        category,
        subcategory,
        COUNT(*) AS sales_count,
        SUM(sale_amount) AS subcategory_revenue,
        AVG(sale_amount) AS avg_sale_amount
    FROM sales_data
    GROUP BY category, subcategory
)
SELECT
    category,
    subcategory,
    sales_count,
    subcategory_revenue,
    avg_sale_amount,
    ROW_NUMBER()
        OVER (PARTITION BY category ORDER BY subcategory_revenue DESC)
        AS subcategory_rank,
    ROUND(
        subcategory_revenue
        * 100.0
        / SUM(subcategory_revenue) OVER (PARTITION BY category),
        2
    ) AS revenue_percentage
FROM subcategory_summary
ORDER BY category ASC, subcategory_revenue DESC;

-- =====================================================
-- Example 4: Regional Performance by Category
-- =====================================================

-- Compare regional performance within categories
SELECT
    category,
    region,
    COUNT(*) AS regional_sales,
    SUM(sale_amount) AS regional_revenue,
    AVG(sale_amount) AS avg_regional_sale,
    RANK()
        OVER (PARTITION BY category ORDER BY SUM(sale_amount) DESC)
        AS regional_rank,
    ROUND(
        SUM(sale_amount)
        * 100.0
        / SUM(SUM(sale_amount)) OVER (PARTITION BY category),
        2
    ) AS regional_percentage
FROM sales_data
GROUP BY category, region
ORDER BY category ASC, regional_revenue DESC;

-- =====================================================
-- Example 5: Salesperson Performance by Category
-- =====================================================

-- Analyze salesperson performance within categories
SELECT
    category,
    salesperson,
    COUNT(*) AS sales_count,
    SUM(sale_amount) AS total_sales_amount,
    AVG(sale_amount) AS avg_sale_amount,
    ROW_NUMBER()
        OVER (PARTITION BY category ORDER BY SUM(sale_amount) DESC)
        AS salesperson_rank,
    NTILE(3)
        OVER (PARTITION BY category ORDER BY SUM(sale_amount) DESC)
        AS performance_tier
FROM sales_data
GROUP BY category, salesperson
ORDER BY category ASC, total_sales_amount DESC;

-- =====================================================
-- Example 6: Price Tier Analysis
-- =====================================================

-- Create price tiers within each category
SELECT
    product_name,
    category,
    sale_amount,
    NTILE(4)
        OVER (PARTITION BY category ORDER BY sale_amount)
        AS price_quartile,
    CASE
        WHEN sale_amount >= 500 THEN 'Premium'
        WHEN sale_amount >= 200 THEN 'Mid-Range'
        WHEN sale_amount >= 50 THEN 'Budget'
        ELSE 'Economy'
    END AS price_tier,
    ROUND(
        sale_amount * 100.0 / SUM(sale_amount) OVER (PARTITION BY category), 2
    ) AS category_percentage
FROM sales_data
ORDER BY category ASC, sale_amount DESC;

-- =====================================================
-- Example 7: Category Growth Analysis
-- =====================================================

-- Analyze sales growth by category over time
WITH daily_category_sales AS (
    SELECT
        category,
        sale_date,
        SUM(sale_amount) AS daily_revenue,
        COUNT(*) AS daily_sales_count
    FROM sales_data
    GROUP BY category, sale_date
)

SELECT
    category,
    sale_date,
    daily_revenue,
    daily_sales_count,
    LAG(daily_revenue)
        OVER (PARTITION BY category ORDER BY sale_date)
        AS prev_day_revenue,
    ROUND(
        (
            daily_revenue
            - LAG(daily_revenue) OVER (PARTITION BY category ORDER BY sale_date)
        )
        * 100.0
        / LAG(daily_revenue) OVER (PARTITION BY category ORDER BY sale_date), 2
    ) AS daily_growth_percentage,
    SUM(daily_revenue)
        OVER (PARTITION BY category ORDER BY sale_date)
        AS cumulative_revenue
FROM daily_category_sales
ORDER BY category, sale_date;

-- =====================================================
-- Example 8: Category Performance Comparison
-- =====================================================

-- Compare categories against overall performance
SELECT
    category,
    COUNT(*) AS total_sales,
    SUM(sale_amount) AS total_revenue,
    AVG(sale_amount) AS avg_sale_amount,
    ROUND(AVG(sale_amount) * 100.0 / AVG(AVG(sale_amount)) OVER (), 2)
        AS avg_vs_overall_percentage,
    ROUND(SUM(sale_amount) * 100.0 / SUM(SUM(sale_amount)) OVER (), 2)
        AS revenue_share_percentage,
    RANK() OVER (ORDER BY SUM(sale_amount) DESC) AS revenue_rank,
    RANK() OVER (ORDER BY AVG(sale_amount) DESC) AS avg_sale_rank
FROM sales_data
GROUP BY category
ORDER BY total_revenue DESC;

-- Clean up
DROP TABLE IF EXISTS sales_data CASCADE;
