-- =====================================================
-- Recursive CTE: Password Generation with Pattern Rules
-- =====================================================
-- 
-- PURPOSE: Demonstrate recursive CTE for generating password patterns with character set rules
-- LEARNING OUTCOMES:
--   - Understand pattern-based string generation using recursion
--   - Learn to apply rules for character selection and pattern building
--   - Master recursive string building with conditional logic and character sets
-- EXPECTED RESULTS: Generate 12-character passwords following alternating character set rules
-- DIFFICULTY: 🟡 Intermediate (10-20 min)
-- CONCEPTS: Pattern generation, string building, conditional recursion, character sets

-- PURPOSE: Demonstrate recursive CTE for generating password patterns
--          with specific character set rules and complexity requirements
-- LEARNING OUTCOMES: Students will understand how to use recursive CTEs for
--                    pattern generation, string building, and implementing
--                    complex generation rules with character set tracking
-- EXPECTED RESULTS:
-- 1. 12-character passwords generated with pattern rules
-- 2. Character set diversity tracking (uppercase, lowercase, numbers, special)
-- 3. Password strength assessment based on character variety
-- 4. Pattern-based character placement (every 2nd, 3rd, 4th position)
-- 5. Complex generation rules implementation
-- DIFFICULTY: 🟡 Intermediate (10-20 min)
-- CONCEPTS: Recursive CTE, pattern generation, string building, character sets, password complexity, generation rules

-- Generate password patterns recursively
WITH RECURSIVE password_generator AS (
    -- Base case: start with empty password
    SELECT 
        '' as password,
        0 as length,
        ARRAY[]::TEXT[] as character_sets
    FROM (VALUES (1)) as t(n)
    
    UNION ALL
    
    -- Recursive case: add characters based on rules
    SELECT 
        pg.password || 
        CASE 
            WHEN pg.length % 4 = 0 THEN 'A'  -- Uppercase every 4th position
            WHEN pg.length % 3 = 0 THEN 'a'  -- Lowercase every 3rd position
            WHEN pg.length % 2 = 0 THEN '1'  -- Number every 2nd position
            ELSE '!'  -- Special character otherwise
        END as password,
        pg.length + 1,
        pg.character_sets || 
        CASE 
            WHEN pg.length % 4 = 0 THEN ARRAY['uppercase']
            WHEN pg.length % 3 = 0 THEN ARRAY['lowercase']
            WHEN pg.length % 2 = 0 THEN ARRAY['number']
            ELSE ARRAY['special']
        END
    FROM password_generator pg
    WHERE pg.length < 12  -- Generate 12-character passwords
)
SELECT 
    length,
    password,
    character_sets,
    CASE 
        WHEN array_length(character_sets, 1) >= 4 THEN 'Strong'
        WHEN array_length(character_sets, 1) >= 3 THEN 'Medium'
        ELSE 'Weak'
    END as password_strength
FROM password_generator
WHERE length > 0
ORDER BY length; 