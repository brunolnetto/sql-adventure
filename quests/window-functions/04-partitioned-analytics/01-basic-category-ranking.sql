-- =====================================================
-- Window Functions: Basic Category Ranking
-- =====================================================

-- PURPOSE: Demonstrate fundamental window function partitioning for 
--          category-based sales analysis and ranking
-- LEARNING OUTCOMES: Students will understand how to use PARTITION BY 
--                    for basic business analytics and ranking within groups
-- EXPECTED RESULTS: 
-- 1. Products ranked within each category by sales amount
-- 2. Category-level statistics and percentiles
-- 3. Top performers identified within each category
-- DIFFICULTY: 🟡 Intermediate (10-20 min)
-- CONCEPTS: PARTITION BY, ROW_NUMBER(), RANK(), DENSE_RANK(), 
--           PERCENT_RANK(), NTILE()

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS product_sales CASCADE;

-- Create comprehensive product sales table
CREATE TABLE product_sales (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    subcategory VARCHAR(50),
    sales_amount DECIMAL(10,2),
    units_sold INT,
    sale_date DATE,
    region VARCHAR(50)
);

-- Insert realistic sales data across multiple categories
INSERT INTO product_sales VALUES
-- Electronics Category
(1, 'Laptop Pro', 'Electronics', 'Computers', 1200.00, 15, '2024-01-15', 'North'),
(2, 'Wireless Mouse', 'Electronics', 'Accessories', 45.00, 120, '2024-01-16', 'North'),
(3, 'Gaming Keyboard', 'Electronics', 'Accessories', 150.00, 25, '2024-01-17', 'South'),
(4, '4K Monitor', 'Electronics', 'Displays', 450.00, 8, '2024-01-18', 'East'),
(5, 'Bluetooth Headphones', 'Electronics', 'Audio', 89.99, 45, '2024-01-19', 'West'),
(6, 'Tablet Air', 'Electronics', 'Mobile', 350.00, 12, '2024-01-20', 'North'),

-- Clothing Category
(7, 'Denim Jacket', 'Clothing', 'Outerwear', 85.00, 30, '2024-01-15', 'North'),
(8, 'Running Shoes', 'Clothing', 'Footwear', 120.00, 22, '2024-01-16', 'South'),
(9, 'Cotton T-Shirt', 'Clothing', 'Casual', 25.00, 150, '2024-01-17', 'East'),
(10, 'Formal Shirt', 'Clothing', 'Business', 65.00, 18, '2024-01-18', 'West'),
(11, 'Winter Coat', 'Clothing', 'Outerwear', 180.00, 12, '2024-01-19', 'North'),
(12, 'Sneakers', 'Clothing', 'Footwear', 95.00, 28, '2024-01-20', 'South'),

-- Home & Garden Category
(13, 'Garden Hose', 'Home & Garden', 'Outdoor', 35.00, 40, '2024-01-15', 'West'),
(14, 'Kitchen Blender', 'Home & Garden', 'Appliances', 75.00, 15, '2024-01-16', 'East'),
(15, 'LED Light Bulbs', 'Home & Garden', 'Lighting', 12.99, 200, '2024-01-17', 'North'),
(16, 'Coffee Maker', 'Home & Garden', 'Appliances', 120.00, 10, '2024-01-18', 'South'),
(17, 'Plant Pot Set', 'Home & Garden', 'Decor', 45.00, 25, '2024-01-19', 'West'),
(18, 'Tool Kit', 'Home & Garden', 'Tools', 85.00, 8, '2024-01-20', 'East');

-- =====================================================
-- Example 1: Basic Category Ranking
-- =====================================================

-- Rank products within each category by sales amount
SELECT 
    product_name,
    category,
    subcategory,
    sales_amount,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY sales_amount DESC) as category_rank,
    RANK() OVER (PARTITION BY category ORDER BY sales_amount DESC) as rank_with_ties,
    DENSE_RANK() OVER (PARTITION BY category ORDER BY sales_amount DESC) as dense_rank
FROM product_sales
ORDER BY category, sales_amount DESC;

-- =====================================================
-- Example 2: Category Performance Analysis
-- =====================================================

-- Analyze category performance with multiple metrics
SELECT 
    category,
    COUNT(*) as product_count,
    ROUND(AVG(sales_amount), 2) as avg_sales,
    ROUND(SUM(sales_amount), 2) as total_sales,
    ROUND(MAX(sales_amount), 2) as max_sales,
    ROUND(MIN(sales_amount), 2) as min_sales,
    ROUND(STDDEV(sales_amount), 2) as sales_stddev,
    ROUND(
        (MAX(sales_amount) - MIN(sales_amount)) * 100.0 / AVG(sales_amount), 2
    ) as sales_variation_pct
FROM product_sales
GROUP BY category
ORDER BY total_sales DESC;

-- =====================================================
-- Example 3: Top Performers by Category
-- =====================================================

-- Get top 3 products from each category
WITH ranked_products AS (
    SELECT 
        product_name,
        category,
        subcategory,
        sales_amount,
        units_sold,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY sales_amount DESC) as category_rank
    FROM product_sales
)
SELECT 
    product_name,
    category,
    subcategory,
    sales_amount,
    units_sold,
    category_rank
FROM ranked_products
WHERE category_rank <= 3
ORDER BY category, category_rank;

-- Clean up
DROP TABLE IF EXISTS product_sales CASCADE; 