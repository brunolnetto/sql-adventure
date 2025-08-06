-- =====================================================
-- Running Total Example
-- =====================================================
-- 
-- PURPOSE: Demonstrate recursive CTE for cumulative calculations and running totals
-- LEARNING OUTCOMES:
--   - Understand cumulative sum calculations using recursion
--   - Learn to maintain running totals across rows in SQL
--   - Master sequential data processing patterns with recursive CTEs
-- EXPECTED RESULTS: Calculate running totals and averages for sales data over time
-- DIFFICULTY: 🟢 Beginner (5-10 min)
-- CONCEPTS: Cumulative calculations, running totals, sequential processing, data aggregation

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS sales CASCADE;

-- Create sample sales data
CREATE TABLE sales (
    date_id INT,
    amount DECIMAL(10, 2)
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
        CAST(amount AS DECIMAL(10, 2)) AS running_sum,
        1 AS row_num
    FROM sales
    WHERE date_id = (SELECT MIN(date_id) FROM sales)

    UNION ALL

    -- Recursive case: add current amount to previous running sum
    SELECT
        s.date_id,
        s.amount,
        CAST(rt.running_sum + s.amount AS DECIMAL(10, 2)),
        rt.row_num + 1
    FROM sales AS s
    INNER JOIN running_total AS rt ON s.date_id = rt.date_id + 1
)

SELECT
    date_id,
    amount,
    running_sum,
    ROUND(running_sum / row_num, 2) AS average_so_far
FROM running_total
ORDER BY date_id;

-- Clean up
DROP TABLE IF EXISTS sales CASCADE;
