-- =====================================================
-- Recursive CTE quest: Number Series Generation Example
-- =====================================================
-- 
-- PURPOSE: Demonstrate basic recursive CTE for generating number series
-- LEARNING OUTCOMES:
--   - Understand base case and recursive case in CTEs
--   - Learn to generate sequential data using recursion
--   - Practice controlling recursion with WHERE conditions
-- EXPECTED RESULTS:
--   - First query: Numbers 1 through 10
--   - Second query: Even numbers 2, 4, 6, ..., 20
-- DIFFICULTY: 🟢 Beginner (5-10 min)
-- CONCEPTS: Recursive CTE, Base Case, Recursive Case, Termination Condition

-- Generate numbers from 1 to 10
WITH RECURSIVE number_series AS (
    -- Base case: start with 1
    SELECT 1 AS num

    UNION ALL

    -- Recursive case: increment by 1 until we reach 10
    SELECT num + 1
    FROM number_series
    WHERE num < 10
)

SELECT num FROM number_series;

-- Generate even numbers from 2 to 20
WITH RECURSIVE even_numbers AS (
    -- Base case: start with 2
    SELECT 2 AS num

    UNION ALL

    -- Recursive case: add 2 each time
    SELECT num + 2
    FROM even_numbers
    WHERE num < 20
)

SELECT num FROM even_numbers;
