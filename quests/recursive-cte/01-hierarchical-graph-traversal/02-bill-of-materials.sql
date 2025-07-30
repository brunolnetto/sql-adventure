-- =====================================================
-- Bill of Materials (BOM) Example
-- =====================================================

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS bom CASCADE;
DROP TABLE IF EXISTS products CASCADE;

-- Create tables
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    cost DECIMAL(10,2)
);

CREATE TABLE bom (
    parent_id INT,
    child_id INT,
    quantity INT,
    FOREIGN KEY (parent_id) REFERENCES products(product_id),
    FOREIGN KEY (child_id) REFERENCES products(product_id)
);

-- Insert sample data
INSERT INTO products VALUES
(1, 'Laptop', 0),
(2, 'Screen', 100),
(3, 'Keyboard', 50),
(4, 'Motherboard', 200),
(5, 'CPU', 300),
(6, 'RAM', 80),
(7, 'Battery', 60);

INSERT INTO bom VALUES
(1, 2, 1),   -- Laptop contains 1 Screen
(1, 3, 1),   -- Laptop contains 1 Keyboard
(1, 4, 1),   -- Laptop contains 1 Motherboard
(1, 7, 1),   -- Laptop contains 1 Battery
(4, 5, 1),   -- Motherboard contains 1 CPU
(4, 6, 2);   -- Motherboard contains 2 RAM modules

-- Calculate total cost of each product including subcomponents
WITH RECURSIVE product_cost AS (
    -- Base case: products with no subcomponents
    SELECT 
        p.product_id,
        p.product_name,
        p.cost as direct_cost,
        CAST(p.cost AS DECIMAL(10,2)) as total_cost,
        0 as level
    FROM products p
    WHERE NOT EXISTS (SELECT 1 FROM bom WHERE parent_id = p.product_id)
    
    UNION ALL
    
    -- Recursive case: products with subcomponents
    SELECT 
        p.product_id,
        p.product_name,
        p.cost as direct_cost,
        CAST(p.cost + (b.quantity * pc.total_cost) AS DECIMAL(10,2)) as total_cost,
        pc.level + 1
    FROM products p
    INNER JOIN bom b ON p.product_id = b.parent_id
    INNER JOIN product_cost pc ON b.child_id = pc.product_id
),
final_costs AS (
    -- Get the final cost for each product (highest level)
    SELECT DISTINCT
        product_id,
        product_name,
        direct_cost,
        MAX(total_cost) OVER (PARTITION BY product_id) as total_cost,
        MAX(level) OVER (PARTITION BY product_id) as max_level
    FROM product_cost
)
SELECT 
    product_name,
    direct_cost,
    total_cost,
    max_level as level,
    (total_cost - direct_cost) as component_cost
FROM final_costs
ORDER BY max_level DESC, product_name;

-- Clean up
DROP TABLE IF EXISTS bom CASCADE;
DROP TABLE IF EXISTS products CASCADE; 