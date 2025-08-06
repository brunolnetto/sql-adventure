-- =====================================================
-- Window Functions: Sales Ranking with ROW_NUMBER()
-- =====================================================

-- PURPOSE: Demonstrate basic ROW_NUMBER() function for sales ranking
--          and understanding unique sequential numbering
-- LEARNING OUTCOMES: Students will understand how to use ROW_NUMBER() 
--                    for ranking data and creating unique sequential numbers
-- EXPECTED RESULTS:
-- 1. Products should be ranked by sales amount (highest first)
-- 2. Each category should have its own ranking sequence
-- 3. No ties should occur (ROW_NUMBER() gives unique ranks)
-- 4. Electronics category should have 3 products ranked 1,2,3
-- 5. Clothing category should have 2 products ranked 1,2
-- 6. Overall ranking should show Laptop Pro as #1 (highest amount)
-- DIFFICULTY: 🟢 Beginner (5-10 min)
-- CONCEPTS: ROW_NUMBER(), PARTITION BY, basic ranking, unique sequential numbers

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS sales_data CASCADE;

-- Create sample sales table
CREATE TABLE sales_data (
    sale_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    sale_amount DECIMAL(10, 2),
    sale_date DATE
);

-- Insert sample data
INSERT INTO sales_data VALUES
(1, 'Laptop Pro', 'Electronics', 1200.00, '2024-01-15'),
(2, 'Wireless Mouse', 'Electronics', 45.00, '2024-01-16'),
(3, 'Office Chair', 'Furniture', 299.99, '2024-01-17'),
(4, 'Desk Lamp', 'Furniture', 89.99, '2024-01-18'),
(5, 'Gaming Keyboard', 'Electronics', 150.00, '2024-01-19');

-- =====================================================
-- Example 1: Basic ROW_NUMBER() Ranking
-- =====================================================

-- Demonstrate basic ROW_NUMBER() for overall ranking
SELECT
    product_name,
    category,
    sale_amount,
    ROW_NUMBER() OVER (ORDER BY sale_amount DESC) AS overall_rank
FROM sales_data
ORDER BY sale_amount DESC;

-- =====================================================
-- Example 2: ROW_NUMBER() with PARTITION BY
-- =====================================================

-- Demonstrate ROW_NUMBER() with partitioning by category
SELECT
    product_name,
    category,
    sale_amount,
    ROW_NUMBER()
        OVER (PARTITION BY category ORDER BY sale_amount DESC)
        AS category_rank
FROM sales_data
ORDER BY category ASC, sale_amount DESC;

-- =====================================================
-- Example 3: Multiple ROW_NUMBER() Functions
-- =====================================================

-- Show both overall and category ranking together
SELECT
    product_name,
    category,
    sale_amount,
    ROW_NUMBER() OVER (ORDER BY sale_amount DESC) AS overall_rank,
    ROW_NUMBER()
        OVER (PARTITION BY category ORDER BY sale_amount DESC)
        AS category_rank
FROM sales_data
ORDER BY sale_amount DESC;

-- Clean up
DROP TABLE IF EXISTS sales_data CASCADE;
