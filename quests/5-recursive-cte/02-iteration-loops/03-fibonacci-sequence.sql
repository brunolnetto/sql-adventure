-- =====================================================
-- Recursive CTE: Fibonacci Sequence Generation
-- =====================================================
-- 
-- PURPOSE: Demonstrate recursive CTE for mathematical sequence generation
-- LEARNING OUTCOMES:
--   - Understand mathematical sequence generation using recursion
--   - Learn to maintain multiple values in recursive CTEs
--   - Master iterative mathematical calculations
-- EXPECTED RESULTS: First 15 Fibonacci numbers (0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377)
-- DIFFICULTY: 🟡 Intermediate (10-20 min)
-- CONCEPTS: Recursive CTE, Mathematical Sequences, Fibonacci Numbers, Iterative Calculation

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
    SELECT
        0 AS n,
        0 AS fib_n,
        1 AS fib_next

    UNION ALL

    -- Recursive case: calculate next Fibonacci number
    SELECT
        n + 1,
        fib_next,
        fib_n + fib_next
    FROM fibonacci
    WHERE n < 14
)

SELECT
    n,
    fib_n AS fibonacci_number
FROM fibonacci
ORDER BY n;
