-- =====================================================
-- Spiral Matrix Generation Example
-- =====================================================

-- Generate a spiral matrix pattern recursively
WITH RECURSIVE spiral_matrix AS (
    -- Base case: start with center element
    SELECT 
        0 as x,
        0 as y,
        1 as value,
        0 as step,
        ARRAY[ARRAY[1]] as matrix,
        'right' as direction
    FROM (VALUES (1)) as t(n)
    
    UNION ALL
    
    -- Recursive case: add next element in spiral pattern
    SELECT 
        CASE 
            WHEN sm.direction = 'right' THEN sm.x + 1
            WHEN sm.direction = 'left' THEN sm.x - 1
            ELSE sm.x
        END as x,
        CASE 
            WHEN sm.direction = 'up' THEN sm.y - 1
            WHEN sm.direction = 'down' THEN sm.y + 1
            ELSE sm.y
        END as y,
        sm.value + 1 as value,
        sm.step + 1 as step,
        -- Update matrix (simplified representation)
        sm.matrix as matrix,
        CASE 
            WHEN sm.direction = 'right' AND sm.x >= sm.step THEN 'up'
            WHEN sm.direction = 'up' AND sm.y <= -sm.step THEN 'left'
            WHEN sm.direction = 'left' AND sm.x <= -sm.step THEN 'down'
            WHEN sm.direction = 'down' AND sm.y >= sm.step THEN 'right'
            ELSE sm.direction
        END as direction
    FROM spiral_matrix sm
    WHERE sm.step < 16  -- Generate 4x4 spiral (16 elements)
)
SELECT 
    step,
    x,
    y,
    value,
    direction,
    CASE 
        WHEN step <= 4 THEN 'First row'
        WHEN step <= 7 THEN 'Right column'
        WHEN step <= 10 THEN 'Bottom row'
        WHEN step <= 13 THEN 'Left column'
        ELSE 'Inner spiral'
    END as spiral_section
FROM spiral_matrix
ORDER BY step; 