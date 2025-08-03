-- =====================================================
-- Recursive CTE: Category Tree Navigation
-- =====================================================
-- 
-- PURPOSE: Demonstrate recursive CTE for category tree navigation and path building
-- LEARNING OUTCOMES:
--   - Understand tree structure traversal and path construction
--   - Learn to build full hierarchical paths using recursion
--   - Master simple tree navigation patterns
-- EXPECTED RESULTS: Complete category tree with full hierarchical paths
-- DIFFICULTY: 🟢 Beginner (5-10 min)
-- CONCEPTS: Recursive CTE, Tree Structures, Path Building, Hierarchical Navigation

-- PURPOSE: Demonstrate recursive CTE for navigating hierarchical category
--          structures and building complete category paths
-- LEARNING OUTCOMES: Students will understand how to use recursive CTEs for
--                    tree navigation, building hierarchical paths, and
--                    managing nested category structures
-- EXPECTED RESULTS:
-- 1. Complete category tree with hierarchical levels
-- 2. Full category paths from root to leaf categories
-- 3. Tree navigation from parent to child categories
-- 4. Hierarchical category structure analysis
-- 5. Category path building and display
-- DIFFICULTY: 🟢 Beginner (5-10 min)
-- CONCEPTS: Recursive CTE, tree navigation, hierarchical paths, category structure, parent-child relationships

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS categories CASCADE;

-- Create table
CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    name VARCHAR(100),
    parent_id INT,
    FOREIGN KEY (parent_id) REFERENCES categories(category_id)
);

-- Insert sample data
INSERT INTO categories VALUES
(1, 'Electronics', NULL),
(2, 'Computers', 1),
(3, 'Laptops', 2),
(4, 'Desktops', 2),
(5, 'Phones', 1),
(6, 'Smartphones', 5),
(7, 'Feature Phones', 5),
(8, 'Accessories', 1),
(9, 'Laptop Bags', 8),
(10, 'Phone Cases', 8);

-- Find all categories with their full path
WITH RECURSIVE category_tree AS (
    -- Base case: root categories
    SELECT 
        category_id,
        name,
        parent_id,
        0 as level,
        CAST(name AS VARCHAR(500)) as full_path
    FROM categories 
    WHERE parent_id IS NULL
    
    UNION ALL
    
    -- Recursive case: child categories
    SELECT 
        c.category_id,
        c.name,
        c.parent_id,
        ct.level + 1,
        CAST(ct.full_path || ' > ' || c.name AS VARCHAR(500))
    FROM categories c
    INNER JOIN category_tree ct ON c.parent_id = ct.category_id
)
SELECT 
    level,
    name,
    full_path
FROM category_tree
ORDER BY full_path;

-- Clean up
DROP TABLE IF EXISTS categories CASCADE; 