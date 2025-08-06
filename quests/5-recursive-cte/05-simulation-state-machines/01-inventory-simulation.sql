-- =====================================================
-- Inventory Simulation Example
-- =====================================================
-- 
-- PURPOSE: Demonstrate recursive CTE for business process simulation and state management
-- LEARNING OUTCOMES:
--   - Understand business process simulation and state tracking
--   - Learn to model inventory depletion and reorder logic
--   - Master multi-step business rule implementation with recursion
-- EXPECTED RESULTS: Simulate 5 days of inventory management with reorder triggers
-- DIFFICULTY: 🔴 Advanced (15-30 min)
-- CONCEPTS: Business simulation, state machines, inventory management, business logic

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
(1, 1, 25), (1, 2, 20), (1, 3, 30),  -- Higher demand to trigger reorders
(2, 1, 30), (2, 2, 25), (2, 3, 35),  -- Even higher demand
(3, 1, 35), (3, 2, 30), (3, 3, 40),  -- Very high demand
(4, 1, 20), (4, 2, 15), (4, 3, 25),  -- Moderate demand
(5, 1, 40), (5, 2, 35), (5, 3, 45);  -- High demand again

-- Simulate inventory depletion over 5 days
WITH RECURSIVE inventory_simulation AS (
    -- Base case: day 0 (initial inventory)
    SELECT
        0 AS day_number,
        product_id,
        product_name,
        current_stock,
        reorder_point,
        reorder_quantity,
        0 AS total_demand,
        0 AS reorder_count
    FROM inventory

    UNION ALL

    -- Recursive case: simulate each day
    SELECT
        inv_sim.day_number + 1,
        inv_sim.product_id,
        inv_sim.product_name,
        CASE
            WHEN
                (inv_sim.current_stock - dd.demand_quantity)
                < inv_sim.reorder_point
                THEN
                    (inv_sim.current_stock - dd.demand_quantity)
                    + inv_sim.reorder_quantity
            ELSE inv_sim.current_stock - dd.demand_quantity
        END AS current_stock,
        inv_sim.reorder_point,
        inv_sim.reorder_quantity,
        inv_sim.total_demand + dd.demand_quantity,
        CASE
            WHEN
                (inv_sim.current_stock - dd.demand_quantity)
                < inv_sim.reorder_point
                THEN inv_sim.reorder_count + 1
            ELSE inv_sim.reorder_count
        END AS reorder_count
    FROM inventory_simulation AS inv_sim
    INNER JOIN
        daily_demand AS dd
        ON
            inv_sim.product_id = dd.product_id
            AND inv_sim.day_number + 1 = dd.day_number
    WHERE inv_sim.day_number < 5
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
    END AS stock_status
FROM inventory_simulation
ORDER BY product_id, day_number;

-- Clean up
DROP TABLE IF EXISTS daily_demand CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
