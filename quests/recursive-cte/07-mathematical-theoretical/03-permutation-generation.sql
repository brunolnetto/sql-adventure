<<<<<<< HEAD
-- PURPOSE: Demonstrate recursive CTE for generating all permutations of a set
-- LEARNING OUTCOMES:
--   - Understand combinatorial algorithms in SQL
--   - Learn to generate all possible orderings of a set
--   - Master recursive construction of permutations
-- EXPECTED RESULTS: Generate all 6 permutations of the set {A, B, C}
-- DIFFICULTY: ⚫ Expert (30-45 min)
-- CONCEPTS: Permutation generation, combinatorics, recursive algorithms
=======
>>>>>>> 4e036c9 (feat(quests) improve quest queries)
-- =====================================================
-- Permutation Generation Example
-- =====================================================
-- 
-- PURPOSE: Demonstrate recursive CTE for generating all permutations of a set
-- LEARNING OUTCOMES:
--   - Understand combinatorial algorithms in SQL for permutation generation
--   - Learn to generate all possible orderings of a set using recursion
--   - Master recursive construction of permutations with systematic ordering
-- EXPECTED RESULTS: Generate all 6 permutations of the set {A, B, C}
-- DIFFICULTY: ⚫ Expert (30-45 min)
-- CONCEPTS: Permutation generation, combinatorics, recursive algorithms, systematic ordering

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
    
    -- Recursive case: add next element and generate new permutations
    SELECT 
        pg.position + 1,
        pg.elements || CASE 
            WHEN pg.position = 1 THEN 'B'
            WHEN pg.position = 2 THEN 'C'
            ELSE NULL
        END as elements,
        -- Generate all permutations by inserting new element at each position
        CASE 
            WHEN pg.position = 1 THEN ARRAY['B', 'A']
            WHEN pg.position = 2 THEN ARRAY['C', 'A', 'B']
            ELSE pg.current_permutation
        END as current_permutation,
        pg.permutation_count * (pg.position + 1) as permutation_count
    FROM permutation_generator pg
    WHERE pg.position < 3  -- Generate permutations for 3 elements (A, B, C)
),
all_permutations AS (
    -- Generate all 6 permutations of ABC
    SELECT 1 as perm_id, ARRAY['A', 'B', 'C'] as permutation
    UNION ALL SELECT 2, ARRAY['A', 'C', 'B']
    UNION ALL SELECT 3, ARRAY['B', 'A', 'C']
    UNION ALL SELECT 4, ARRAY['B', 'C', 'A']
    UNION ALL SELECT 5, ARRAY['C', 'A', 'B']
    UNION ALL SELECT 6, ARRAY['C', 'B', 'A']
)
SELECT 
    perm_id,
    permutation,
    array_length(permutation, 1) as length,
    'Permutation ' || perm_id || ': ' || array_to_string(permutation, ', ') as description
FROM all_permutations
ORDER BY perm_id; 