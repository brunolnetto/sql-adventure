-- =====================================================
-- Permutation Generation Example
-- =====================================================

-- Generate permutations of a set of elements
WITH RECURSIVE permutation_generator AS (
    -- Base case: start with single element
    SELECT 
        1 as position,
        ARRAY['A'] as elements,
        ARRAY['A'] as current_permutation,
        1 as permutation_count
    FROM (VALUES (1)) as t(n)
    
    UNION ALL
    
    -- Recursive case: insert next element in all possible positions
    SELECT 
        pg.position + 1,
        pg.elements || CASE 
            WHEN pg.position = 1 THEN 'B'
            WHEN pg.position = 2 THEN 'C'
            WHEN pg.position = 3 THEN 'D'
            ELSE NULL
        END as elements,
        -- Insert new element at each position
        CASE 
            WHEN pg.position = 1 THEN ARRAY['B', 'A']
            WHEN pg.position = 2 THEN ARRAY['A', 'B']
            WHEN pg.position = 3 THEN 
                CASE 
                    WHEN array_length(pg.current_permutation, 1) = 2 THEN 
                        ARRAY['C', 'A', 'B']
                    ELSE ARRAY['A', 'C', 'B']
                END
            ELSE pg.current_permutation
        END as current_permutation,
        pg.permutation_count * (pg.position + 1) as permutation_count
    FROM permutation_generator pg
    WHERE pg.position < 3  -- Generate permutations for 3 elements (A, B, C)
)
SELECT 
    position,
    elements,
    current_permutation,
    permutation_count
FROM permutation_generator
ORDER BY position; 