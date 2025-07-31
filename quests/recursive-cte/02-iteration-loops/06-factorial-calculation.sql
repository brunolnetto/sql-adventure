-- =====================================================
-- Factorial Calculation Example
-- =====================================================
-- PURPOSE: Demonstrate recursive CTE for mathematical factorial calculation
-- LEARNING OUTCOMES: 
--   - Understand factorial mathematical concept (n! = n * (n-1)!)
--   - Learn recursive multiplication patterns
--   - Master iterative mathematical calculations
-- EXPECTED RESULTS: Calculate factorials from 0! to 10! (1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880, 3628800)
-- DIFFICULTY: Intermediate
-- CONCEPTS: Mathematical recursion, factorial calculation, iterative multiplication

-- Calculate factorials from 0 to 10
WITH RECURSIVE factorial AS (
    -- Base case: 0! = 1
    SELECT 0 as n, 1 as factorial_value
    
    UNION ALL
    
    -- Recursive case: n! = n * (n-1)!
    SELECT 
        n + 1,
        (n + 1) * factorial_value
    FROM factorial
    WHERE n < 10
)
SELECT 
    n,
    factorial_value,
    CASE 
        WHEN n <= 10 THEN factorial_value::VARCHAR
        ELSE 'Too large to display'
    END as display_value
FROM factorial
ORDER BY n; 