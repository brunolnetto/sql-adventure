-- =====================================================
-- Inventory Simulation Example
-- =====================================================

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS daily_demand CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;

-- Create tables
CREATE TABLE inventory (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    current_stock INT,
    reorder_point INT,
    reorder_quantity INT
);

CREATE TABLE daily_demand (
    day_number INT,
    product_id INT,
    demand_quantity INT
);

-- Insert sample data
INSERT INTO inventory VALUES
(1, 'Widget A', 100, 20, 50),
(2, 'Widget B', 75, 15, 40),
(3, 'Widget C', 200, 30, 100);

INSERT INTO daily_demand VALUES
(1, 1, 10), (1, 2, 5), (1, 3, 15),
(2, 1, 12), (2, 2, 8), (2, 3, 20),
(3, 1, 15), (3, 2, 10), (3, 3, 25),
(4, 1, 8), (4, 2, 6), (4, 3, 18),
(5, 1, 20), (5, 2, 12), (5, 3, 30);

-- Simulate inventory depletion over 5 days
WITH RECURSIVE inventory_simulation AS (
    -- Base case: day 0 (initial inventory)
    SELECT 
        0 as day_number,
        product_id,
        product_name,
        current_stock,
        reorder_point,
        reorder_quantity,
        0 as total_demand,
        0 as reorder_count
    FROM inventory
    
    UNION ALL
    
    -- Recursive case: simulate each day
    SELECT 
        is.day_number + 1,
        is.product_id,
        is.product_name,
        CASE 
            WHEN (is.current_stock - dd.demand_quantity) < is.reorder_point 
            THEN (is.current_stock - dd.demand_quantity) + is.reorder_quantity
            ELSE is.current_stock - dd.demand_quantity
        END as current_stock,
        is.reorder_point,
        is.reorder_quantity,
        is.total_demand + dd.demand_quantity,
        CASE 
            WHEN (is.current_stock - dd.demand_quantity) < is.reorder_point 
            THEN is.reorder_count + 1
            ELSE is.reorder_count
        END as reorder_count
    FROM inventory_simulation is
    INNER JOIN daily_demand dd ON is.product_id = dd.product_id AND is.day_number + 1 = dd.day_number
    WHERE is.day_number < 5
)
SELECT 
    day_number,
    product_name,
    current_stock,
    total_demand,
    reorder_count,
    CASE 
        WHEN current_stock <= reorder_point THEN 'Low Stock'
        WHEN current_stock <= reorder_point * 2 THEN 'Medium Stock'
        ELSE 'Good Stock'
    END as stock_status
FROM inventory_simulation
ORDER BY product_id, day_number;

-- Clean up
DROP TABLE IF EXISTS daily_demand CASCADE;
DROP TABLE IF EXISTS inventory CASCADE; 