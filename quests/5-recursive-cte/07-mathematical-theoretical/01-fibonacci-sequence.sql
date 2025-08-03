-- =====================================================
-- Fibonacci Sequence Example
-- =====================================================
-- 
-- PURPOSE: Demonstrate recursive CTE for generating the Fibonacci sequence
-- LEARNING OUTCOMES:
--   - Understand mathematical recursion in SQL for sequence generation
--   - Learn to generate sequences where each value depends on previous values
--   - Master iterative sequence generation with mathematical patterns
-- EXPECTED RESULTS: Generate the first 15 Fibonacci numbers (0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377)
-- DIFFICULTY: 🟡 Intermediate (10-20 min)
-- CONCEPTS: Mathematical recursion, sequence generation, Fibonacci numbers, iterative calculation

-- Generate first 15 Fibonacci numbers
WITH RECURSIVE fibonacci AS (
    -- Base case: first two numbers
    SELECT 0 as n, 0 as fib_n, 1 as fib_next
    
    UNION ALL
    
    -- Recursive case: calculate next Fibonacci number
    SELECT 
        n + 1,
        fib_next,
        fib_n + fib_next
    FROM fibonacci
    WHERE n < 14
)
SELECT n, fib_n as fibonacci_number
FROM fibonacci
ORDER BY n; 