-- =====================================================
-- Window Functions: Basic Row Numbering
-- =====================================================

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS products CASCADE;

-- Create sample products table
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2),
    stock_quantity INT
);

-- Insert sample data
INSERT INTO products VALUES
(1, 'Laptop Pro', 'Electronics', 1299.99, 25),
(2, 'Wireless Mouse', 'Electronics', 45.00, 150),
(3, 'Office Chair', 'Furniture', 299.99, 30),
(4, 'Desk Lamp', 'Furniture', 89.99, 75),
(5, 'Gaming Keyboard', 'Electronics', 150.00, 40),
(6, 'Coffee Table', 'Furniture', 199.99, 15),
(7, 'Bluetooth Headphones', 'Electronics', 120.00, 60),
(8, 'Bookshelf', 'Furniture', 159.99, 20);

-- =====================================================
-- Example 1: Basic Row Numbering
-- =====================================================

-- Simple row numbering by price (highest to lowest)
SELECT 
    product_name,
    category,
    price,
    ROW_NUMBER() OVER (ORDER BY price DESC) as price_rank
FROM products
ORDER BY price DESC;

-- =====================================================
-- Example 2: Row Numbering by Category
-- =====================================================

-- Row numbering within each category by price
SELECT 
    product_name,
    category,
    price,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC) as category_rank
FROM products
ORDER BY category, price DESC;

-- =====================================================
-- Example 3: Multiple Rankings
-- =====================================================

-- Show both overall rank and category rank
SELECT 
    product_name,
    category,
    price,
    ROW_NUMBER() OVER (ORDER BY price DESC) as overall_rank,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC) as category_rank
FROM products
ORDER BY price DESC;

-- =====================================================
-- Example 4: Ranking by Multiple Criteria
-- =====================================================

-- Rank by price, then by stock quantity (for same prices)
SELECT 
    product_name,
    category,
    price,
    stock_quantity,
    ROW_NUMBER() OVER (ORDER BY price DESC, stock_quantity DESC) as rank
FROM products
ORDER BY price DESC, stock_quantity DESC;

-- =====================================================
-- Example 5: Top N Products by Category
-- =====================================================

-- Get top 2 products from each category
WITH ranked_products AS (
    SELECT 
        product_name,
        category,
        price,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC) as category_rank
    FROM products
)
SELECT 
    product_name,
    category,
    price,
    category_rank
FROM ranked_products
WHERE category_rank <= 2
ORDER BY category, category_rank;

-- =====================================================
-- Example 6: Ranking with Filtering
-- =====================================================

-- Rank only electronics products by price
SELECT 
    product_name,
    category,
    price,
    ROW_NUMBER() OVER (ORDER BY price DESC) as electronics_rank
FROM products
WHERE category = 'Electronics'
ORDER BY price DESC;

-- Clean up
DROP TABLE IF EXISTS products CASCADE; 