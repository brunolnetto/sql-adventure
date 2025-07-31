-- =====================================================
-- Number Series Generation Example
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
-- DIFFICULTY: Beginner
-- CONCEPTS: Recursive CTE, Base Case, Recursive Case, Termination Condition

-- Generate numbers from 1 to 10
WITH RECURSIVE number_series AS (
    -- Base case: start with 1
    SELECT 1 as num
    
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
    SELECT 2 as num
    
    UNION ALL
    
    -- Recursive case: add 2 each time
    SELECT num + 2
    FROM even_numbers
    WHERE num < 20
)
SELECT num FROM even_numbers;

-- =====================================================
-- VALIDATION QUERIES
-- =====================================================

-- Validation 1: Verify first series has exactly 10 numbers
WITH RECURSIVE number_series AS (
    SELECT 1 as num
    UNION ALL
    SELECT num + 1
    FROM number_series
    WHERE num < 10
)
SELECT 
    COUNT(*) as total_numbers,
    MIN(num) as min_number,
    MAX(num) as max_number,
    CASE 
        WHEN COUNT(*) = 10 AND MIN(num) = 1 AND MAX(num) = 10 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END as validation_result
FROM number_series;

-- Validation 2: Verify even numbers series has correct values
WITH RECURSIVE even_numbers AS (
    SELECT 2 as num
    UNION ALL
    SELECT num + 2
    FROM even_numbers
    WHERE num < 20
)
SELECT 
    COUNT(*) as total_even_numbers,
    MIN(num) as min_even,
    MAX(num) as max_even,
    CASE 
        WHEN COUNT(*) = 10 AND MIN(num) = 2 AND MAX(num) = 20 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END as validation_result
FROM even_numbers; 