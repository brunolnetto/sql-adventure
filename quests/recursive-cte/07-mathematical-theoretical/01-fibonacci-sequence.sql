-- =====================================================
-- Fibonacci Sequence Example
-- =====================================================

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