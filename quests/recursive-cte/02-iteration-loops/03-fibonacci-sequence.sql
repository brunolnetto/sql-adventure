-- =====================================================
-- Recursive CTE: Fibonacci Sequence Generation
-- =====================================================

-- PURPOSE: Demonstrate recursive CTE for generating mathematical sequences
--          specifically the Fibonacci sequence using iterative recursion
-- LEARNING OUTCOMES: Students will understand how to use recursive CTEs for
--                    mathematical sequence generation, iterative calculations,
--                    and managing state across recursive iterations
-- EXPECTED RESULTS:
-- 1. First 15 Fibonacci numbers generated (0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377)
-- 2. Sequential number generation using recursion
-- 3. Mathematical pattern implementation in SQL
-- 4. Iterative calculation with state management
-- 5. Sequence generation with termination conditions
-- DIFFICULTY: 🟡 Intermediate (10-20 min)
-- CONCEPTS: Recursive CTE, mathematical sequences, Fibonacci numbers, iterative calculations, state management

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