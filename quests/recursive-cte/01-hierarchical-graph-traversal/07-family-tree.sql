-- =====================================================
-- Family Tree Example
-- =====================================================

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS family_members CASCADE;

-- Create table to represent family relationships
CREATE TABLE family_members (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    birth_date DATE,
    death_date DATE,
    gender CHAR(1), -- 'M' for Male, 'F' for Female
    father_id INT,
    mother_id INT,
    FOREIGN KEY (father_id) REFERENCES family_members(id),
    FOREIGN KEY (mother_id) REFERENCES family_members(id)
);

-- Insert sample family data
INSERT INTO family_members VALUES
(1, 'John Smith', '1940-05-15', NULL, 'M', NULL, NULL),
(2, 'Mary Johnson', '1942-08-22', NULL, 'F', NULL, NULL),
(3, 'Robert Smith', '1965-03-10', NULL, 'M', 1, 2),
(4, 'Sarah Wilson', '1967-11-05', NULL, 'F', NULL, NULL),
(5, 'Michael Smith', '1990-07-18', NULL, 'M', 3, 4),
(6, 'Emily Smith', '1992-12-03', NULL, 'F', 3, 4),
(7, 'David Brown', '1988-04-25', NULL, 'M', NULL, NULL),
(8, 'Lisa Smith', '1995-09-14', NULL, 'F', 3, 4),
(9, 'James Wilson', '1945-01-30', '2020-06-15', 'M', NULL, NULL),
(10, 'Patricia Wilson', '1948-12-08', NULL, 'F', NULL, NULL),
(11, 'Jennifer Wilson', '1970-06-20', NULL, 'F', 9, 10),
(12, 'Christopher Wilson', '1972-03-12', NULL, 'M', 9, 10),
(13, 'Amanda Wilson', '1998-02-28', NULL, 'F', 12, NULL);

-- Find complete family tree with generations
WITH RECURSIVE family_tree AS (
    -- Base case: root ancestors (no parents)
    SELECT 
        id,
        name,
        birth_date,
        death_date,
        gender,
        father_id,
        mother_id,
        0 as generation,
        CAST(name AS VARCHAR(500)) as lineage_path,
        ARRAY[id] as ancestor_path
    FROM family_members 
    WHERE father_id IS NULL AND mother_id IS NULL
    
    UNION ALL
    
    -- Recursive case: children
    SELECT 
        fm.id,
        fm.name,
        fm.birth_date,
        fm.death_date,
        fm.gender,
        fm.father_id,
        fm.mother_id,
        ft.generation + 1,
        CAST(ft.lineage_path || ' → ' || fm.name AS VARCHAR(500)),
        ft.ancestor_path || fm.id
    FROM family_members fm
    INNER JOIN family_tree ft ON (fm.father_id = ft.id OR fm.mother_id = ft.id)
)
SELECT 
    generation,
    name,
    gender,
    birth_date,
    death_date,
    CASE 
        WHEN death_date IS NULL THEN 
            EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date))::VARCHAR || ' years'
        ELSE 
            EXTRACT(YEAR FROM AGE(death_date, birth_date))::VARCHAR || ' years (deceased)'
    END as age,
    lineage_path
FROM family_tree
ORDER BY generation, name;

-- Find all descendants of a specific person
WITH RECURSIVE descendants AS (
    -- Base case: start person
    SELECT 
        id,
        name,
        gender,
        birth_date,
        0 as descendant_level,
        CAST(name AS VARCHAR(500)) as descendant_path
    FROM family_members 
    WHERE name = 'John Smith'  -- Start with John Smith
    
    UNION ALL
    
    -- Recursive case: find children
    SELECT 
        fm.id,
        fm.name,
        fm.gender,
        fm.birth_date,
        d.descendant_level + 1,
        CAST(d.descendant_path || ' → ' || fm.name AS VARCHAR(500))
    FROM family_members fm
    INNER JOIN descendants d ON (fm.father_id = d.id OR fm.mother_id = d.id)
)
SELECT 
    descendant_level as generation,
    name,
    gender,
    birth_date,
    descendant_path
FROM descendants
ORDER BY descendant_level, name;

-- Find common ancestors between two people
WITH RECURSIVE ancestors AS (
    -- Base case: direct parents
    SELECT 
        id,
        name,
        father_id,
        mother_id,
        1 as ancestor_level,
        ARRAY[id] as ancestor_path
    FROM family_members
    
    UNION ALL
    
    -- Recursive case: find parents of parents
    SELECT 
        fm.id,
        fm.name,
        fm.father_id,
        fm.mother_id,
        a.ancestor_level + 1,
        a.ancestor_path || fm.id
    FROM family_members fm
    INNER JOIN ancestors a ON (fm.id = a.father_id OR fm.id = a.mother_id)
    WHERE a.ancestor_level < 5  -- Limit to 5 generations
),
person1_ancestors AS (
    SELECT DISTINCT id, name, ancestor_level
    FROM ancestors
    WHERE id IN (SELECT id FROM family_members WHERE name = 'Michael Smith')
),
person2_ancestors AS (
    SELECT DISTINCT id, name, ancestor_level
    FROM ancestors
    WHERE id IN (SELECT id FROM family_members WHERE name = 'Amanda Wilson')
)
SELECT 
    pa1.name as common_ancestor,
    pa1.ancestor_level as generation_from_person1,
    pa2.ancestor_level as generation_from_person2,
    (pa1.ancestor_level + pa2.ancestor_level) as total_generations
FROM person1_ancestors pa1
INNER JOIN person2_ancestors pa2 ON pa1.id = pa2.id
ORDER BY total_generations;

-- Clean up
DROP TABLE IF EXISTS family_members CASCADE; 