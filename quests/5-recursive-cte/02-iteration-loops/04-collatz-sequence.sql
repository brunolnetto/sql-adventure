-- =====================================================
-- Collatz Sequence Example
-- =====================================================
-- 
-- PURPOSE: Demonstrate recursive CTE for conditional mathematical sequence generation
-- LEARNING OUTCOMES:
--   - Understand conditional logic in recursive CTEs
--   - Learn to implement mathematical algorithms with branching logic
--   - Master complex iterative calculations with termination conditions
-- EXPECTED RESULTS: Complete Collatz sequence for number 27 with step-by-step progression
-- DIFFICULTY: 🟡 Intermediate (10-20 min)
-- CONCEPTS: Recursive CTE, Conditional Logic, Mathematical Algorithms, Sequence Generation

-- Calculate Collatz sequence for number 27
WITH RECURSIVE collatz AS (
    -- Base case: start number
    SELECT 27 as num, 1 as step, CAST('27' AS VARCHAR(1000)) as sequence
    
    UNION ALL
    
    -- Recursive case: apply Collatz rules
    SELECT 
        CASE 
            WHEN num % 2 = 0 THEN num / 2  -- Even: divide by 2
            ELSE 3 * num + 1               -- Odd: multiply by 3 and add 1
        END,
        step + 1,
        CAST(sequence || ' → ' || 
             CASE 
                 WHEN num % 2 = 0 THEN (num / 2)::VARCHAR
                 ELSE (3 * num + 1)::VARCHAR
             END AS VARCHAR(1000))
    FROM collatz
    WHERE num > 1  -- Stop when we reach 1
)
SELECT 
    step,
    num,
    sequence
FROM collatz
ORDER BY step; 