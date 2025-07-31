-- =====================================================
-- Running Total Example
-- =====================================================
-- PURPOSE: Demonstrate recursive CTE for cumulative calculations
-- LEARNING OUTCOMES: 
--   - Understand cumulative sum calculations
--   - Learn to maintain running totals across rows
--   - Master sequential data processing patterns
-- EXPECTED RESULTS: Calculate running totals and averages for sales data
-- DIFFICULTY: Intermediate
-- CONCEPTS: Cumulative calculations, running totals, sequential processing

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS sales CASCADE;

-- Create sample sales data
CREATE TABLE sales (
    date_id INT,
    amount DECIMAL(10,2)
);

-- Insert sample data
INSERT INTO sales VALUES
(1, 100.00),
(2, 150.00),
(3, 75.00),
(4, 200.00),
(5, 125.00),
(6, 300.00);

-- Calculate running total using recursive CTE
WITH RECURSIVE running_total AS (
    -- Base case: first row
    SELECT 
        date_id,
        amount,
        CAST(amount AS DECIMAL(10,2)) as running_sum,
        1 as row_num
    FROM sales
    WHERE date_id = (SELECT MIN(date_id) FROM sales)
    
    UNION ALL
    
    -- Recursive case: add current amount to previous running sum
    SELECT 
        s.date_id,
        s.amount,
        CAST(rt.running_sum + s.amount AS DECIMAL(10,2)),
        rt.row_num + 1
    FROM sales s
    INNER JOIN running_total rt ON s.date_id = rt.date_id + 1
)
SELECT 
    date_id,
    amount,
    running_sum,
    ROUND(running_sum / row_num, 2) as average_so_far
FROM running_total
ORDER BY date_id;

-- Clean up
DROP TABLE IF EXISTS sales CASCADE; 