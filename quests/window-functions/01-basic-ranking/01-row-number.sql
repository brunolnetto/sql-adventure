-- =====================================================
-- Window Functions: Sales Ranking with ROW_NUMBER()
-- =====================================================

-- Context: This example demonstrates how to use ROW_NUMBER() 
--          to rank sales data by amount within categories.
-- Purpose: Teach basic window function ranking concepts
-- Learning Outcome: Students will understand how to use 
--                   ROW_NUMBER() for ranking data and creating
--                   unique sequential numbers for each row

-- Expected Results:
-- 1. Products should be ranked by sales amount (highest first)
-- 2. Each category should have its own ranking sequence
-- 3. No ties should occur (ROW_NUMBER() gives unique ranks)
-- 4. Electronics category should have 3 products ranked 1,2,3
-- 5. Clothing category should have 2 products ranked 1,2
-- 6. Overall ranking should show Laptop Pro as #1 (highest amount)

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS sales_data CASCADE;

-- Create sample sales table
CREATE TABLE sales_data (
    sale_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    sale_amount DECIMAL(10,2),
    sale_date DATE
);

-- Insert sample data
INSERT INTO sales_data VALUES
(1, 'Laptop Pro', 'Electronics', 1200.00, '2024-01-15'),
(2, 'Wireless Mouse', 'Electronics', 45.00, '2024-01-16'),
(3, 'Office Chair', 'Furniture', 299.99, '2024-01-17'),
(4, 'Desk Lamp', 'Furniture', 89.99, '2024-01-18'),
(5, 'Gaming Keyboard', 'Electronics', 150.00, '2024-01-19');

-- Demonstrate window functions
SELECT 
    product_name,
    category,
    sale_amount,
    ROW_NUMBER() OVER (ORDER BY sale_amount DESC) as overall_rank,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY sale_amount DESC) as category_rank
FROM sales_data
ORDER BY sale_amount DESC;

-- Validation: Verify expected results
-- Validation 1: Check that Electronics has 3 products
SELECT 
    category,
    COUNT(*) as product_count
FROM sales_data 
WHERE category = 'Electronics'
GROUP BY category;

-- Validation 2: Check that highest sale amount is ranked 1 overall
WITH ranked_data AS (
    SELECT 
        product_name,
        sale_amount,
        ROW_NUMBER() OVER (ORDER BY sale_amount DESC) as rank
    FROM sales_data
)
SELECT 
    product_name,
    sale_amount,
    rank
FROM ranked_data
WHERE rank = 1;

-- Validation 3: Verify no duplicate ranks within categories
WITH category_ranks AS (
    SELECT 
        category,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY sale_amount DESC) as category_rank
    FROM sales_data
)
SELECT 
    category,
    COUNT(*) as total_products,
    COUNT(DISTINCT category_rank) as unique_ranks
FROM category_ranks
GROUP BY category;

-- Validation 4: Verify Electronics category ranking sequence
SELECT 
    product_name,
    sale_amount,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY sale_amount DESC) as category_rank
FROM sales_data
WHERE category = 'Electronics'
ORDER BY sale_amount DESC;

-- Validation 5: Verify overall ranking sequence
SELECT 
    product_name,
    sale_amount,
    ROW_NUMBER() OVER (ORDER BY sale_amount DESC) as overall_rank
FROM sales_data
ORDER BY sale_amount DESC;

-- Clean up
DROP TABLE IF EXISTS sales_data CASCADE; 