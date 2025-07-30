-- =====================================================
-- Number Series Generation Example
-- =====================================================

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