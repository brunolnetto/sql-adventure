-- =====================================================
-- Base Conversion Example (Decimal to Binary)
-- =====================================================
-- PURPOSE: Demonstrate recursive CTE for number base conversion
-- LEARNING OUTCOMES: 
--   - Understand iterative division for base conversion
--   - Learn to build strings from right to left
--   - Master recursive number manipulation
-- EXPECTED RESULTS: Convert decimal 42 to binary 101010
-- DIFFICULTY: Intermediate
-- CONCEPTS: Recursive division, string concatenation, base conversion

-- Convert decimal 42 to binary
WITH RECURSIVE binary_conversion AS (
    -- Base case: start with the number and empty result
    SELECT 42 as decimal_num, 0 as position, CAST('' AS VARCHAR(50)) as binary_result
    
    UNION ALL
    
    -- Recursive case: divide by 2 and build binary from right to left
    SELECT 
        decimal_num / 2,
        position + 1,
        CAST((decimal_num % 2)::VARCHAR || binary_result AS VARCHAR(50))
    FROM binary_conversion
    WHERE decimal_num > 0
)
SELECT 
    decimal_num as original_decimal,
    binary_result as binary_representation,
    '42 in binary is: ' || binary_result as explanation
FROM binary_conversion
WHERE decimal_num = 0; 