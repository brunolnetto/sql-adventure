-- =====================================================
-- Window Functions: Category Performance Analysis
-- =====================================================

-- PURPOSE: Demonstrate advanced window function partitioning for 
--          detailed category performance analysis and percentile calculations
-- LEARNING OUTCOMES: Students will understand how to use window functions for
--                    percentile analysis, cross-category comparisons, and
--                    performance tier classification
-- EXPECTED RESULTS: 
-- 1. Percentile ranks within categories and overall
-- 2. Cross-category performance comparisons
-- 3. Performance tier classification using NTILE
-- 4. Contribution percentages to category and total sales
-- DIFFICULTY: 🟡 Intermediate (10-20 min)
-- CONCEPTS: PERCENT_RANK(), NTILE(), multiple window functions,
--           cross-category analysis, performance tiers

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
-- Example 1: Category Percentile Analysis
-- =====================================================

-- Show percentile ranks within categories
SELECT 
    product_name,
    category,
    sales_amount,
    ROUND((PERCENT_RANK() OVER (PARTITION BY category ORDER BY sales_amount))::NUMERIC, 3) as category_percentile,
    ROUND((PERCENT_RANK() OVER (ORDER BY sales_amount))::NUMERIC, 3) as overall_percentile,
    NTILE(4) OVER (PARTITION BY category ORDER BY sales_amount DESC) as category_quartile,
    CASE NTILE(4) OVER (PARTITION BY category ORDER BY sales_amount DESC)
        WHEN 1 THEN 'Top 25%'
        WHEN 2 THEN '25-50%'
        WHEN 3 THEN '50-75%'
        WHEN 4 THEN 'Bottom 25%'
    END as performance_tier
FROM product_sales
ORDER BY category, sales_amount DESC;

-- =====================================================
-- Example 2: Cross-Category Comparison
-- =====================================================

-- Compare products across categories using overall ranking
SELECT 
    product_name,
    category,
    sales_amount,
    ROW_NUMBER() OVER (ORDER BY sales_amount DESC) as overall_rank,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY sales_amount DESC) as category_rank,
    ROUND(
        (sales_amount * 100.0 / SUM(sales_amount) OVER (PARTITION BY category)), 2
    ) as category_contribution_pct,
    ROUND(
        (sales_amount * 100.0 / SUM(sales_amount) OVER ()), 2
    ) as total_contribution_pct
FROM product_sales
ORDER BY sales_amount DESC;

-- =====================================================
-- Example 3: Subcategory Analysis
-- =====================================================

-- Analyze performance within subcategories
SELECT 
    category,
    subcategory,
    COUNT(*) as product_count,
    ROUND(AVG(sales_amount), 2) as avg_sales,
    ROUND(SUM(sales_amount), 2) as total_sales,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY SUM(sales_amount) DESC) as category_subcategory_rank,
    ROUND(
        SUM(sales_amount) * 100.0 / SUM(SUM(sales_amount)) OVER (PARTITION BY category), 2
    ) as category_contribution_pct
FROM product_sales
GROUP BY category, subcategory
ORDER BY category, total_sales DESC;

-- Clean up
DROP TABLE IF EXISTS product_sales CASCADE; 