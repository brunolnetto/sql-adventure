-- =====================================================
-- Base Conversion Example (Decimal to Binary)
-- =====================================================

-- Convert decimal 42 to binary
WITH RECURSIVE binary_conversion AS (
    -- Base case: start with the number and empty result
    SELECT 42 as decimal_num, 0 as position, '' as binary_result
    
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
    decimal_num,
    position,
    binary_result,
    CASE 
        WHEN decimal_num = 0 THEN binary_result
        ELSE NULL
    END as final_binary
FROM binary_conversion
WHERE decimal_num = 0 OR position = 1; 