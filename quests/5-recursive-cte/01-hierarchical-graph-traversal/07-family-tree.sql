-- =====================================================
-- Family Tree Example
-- =====================================================
-- 
-- PURPOSE: Demonstrate recursive CTE for complex family relationship analysis
-- LEARNING OUTCOMES:
--   - Understand multi-relationship hierarchical data traversal
--   - Learn to handle complex family tree structures with multiple parent types
--   - Master recursive CTE with multiple relationship paths
-- EXPECTED RESULTS: Complete family tree with generations and lineage paths
-- DIFFICULTY: 🟡 Intermediate (10-20 min)
-- CONCEPTS: Recursive CTE, Complex Hierarchies, Multiple Relationships, Lineage Analysis

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

-- Find complete family tree with generations (simplified approach)
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
        CAST(name AS VARCHAR(500)) as lineage_path
    FROM family_members 
    WHERE father_id IS NULL AND mother_id IS NULL
    
    UNION ALL
    
    -- Recursive case: children (simplified)
    SELECT 
        fm.id,
        fm.name,
        fm.birth_date,
        fm.death_date,
        fm.gender,
        fm.father_id,
        fm.mother_id,
        ft.generation + 1,
        CAST(ft.lineage_path || ' → ' || fm.name AS VARCHAR(500))
    FROM family_members fm
    INNER JOIN family_tree ft ON (fm.father_id = ft.id OR fm.mother_id = ft.id)
    WHERE ft.generation < 3  -- Limit to 3 generations for safety
),
unique_family_tree AS (
    -- Get unique entries for each person (take the shortest lineage path)
    SELECT DISTINCT ON (id)
        id,
        name,
        birth_date,
        death_date,
        gender,
        generation,
        lineage_path
    FROM family_tree
    ORDER BY id, LENGTH(lineage_path)
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
FROM unique_family_tree
ORDER BY generation, name;

-- Find all descendants of a specific person (simplified)
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
    
    -- Recursive case: find children (simplified)
    SELECT 
        fm.id,
        fm.name,
        fm.gender,
        fm.birth_date,
        d.descendant_level + 1,
        CAST(d.descendant_path || ' → ' || fm.name AS VARCHAR(500))
    FROM family_members fm
    INNER JOIN descendants d ON (fm.father_id = d.id OR fm.mother_id = d.id)
    WHERE d.descendant_level < 3  -- Limit to 3 generations for safety
)
SELECT 
    descendant_level as generation,
    name,
    gender,
    birth_date,
    descendant_path
FROM descendants
ORDER BY descendant_level, name;

-- Find common ancestors between two people (simplified)
WITH direct_ancestors AS (
    -- Get direct ancestors for both people
    SELECT 
        fm1.id as person1_id,
        fm1.name as person1_name,
        fm2.id as person2_id,
        fm2.name as person2_name,
        fm1.father_id,
        fm1.mother_id
    FROM family_members fm1
    CROSS JOIN family_members fm2
    WHERE fm1.name = 'Michael Smith' AND fm2.name = 'Amanda Wilson'
),
common_ancestors AS (
    SELECT 
        da.person1_name,
        da.person2_name,
        fm.name as common_ancestor_name,
        CASE 
            WHEN fm.id = da.father_id THEN 'Father'
            WHEN fm.id = da.mother_id THEN 'Mother'
            ELSE 'Unknown'
        END as relationship
    FROM direct_ancestors da
    INNER JOIN family_members fm ON (fm.id = da.father_id OR fm.id = da.mother_id)
    WHERE fm.id IS NOT NULL
)
SELECT 
    person1_name,
    person2_name,
    common_ancestor_name,
    relationship,
    'Direct ancestor relationship found' as note
FROM common_ancestors
ORDER BY relationship;

-- Clean up
DROP TABLE IF EXISTS family_members CASCADE; 