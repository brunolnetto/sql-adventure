-- =====================================================
-- Password Generation Example
-- =====================================================

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