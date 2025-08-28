-- =====================================================
-- Recursive CTE quest: Transitive Closure Example
-- =====================================================
-- 
-- PURPOSE: Demonstrate recursive CTE for computing transitive closure of relationships
-- LEARNING OUTCOMES:
--   - Understand transitive closure concept (if A→B and B→C, then A→C)
--   - Learn to compute indirect relationships through direct ones
--   - Master relationship path analysis and hop counting
-- EXPECTED RESULTS: Find all indirect relationships and shortest path lengths
-- DIFFICULTY: 🔴 Advanced (15-30 min)
-- CONCEPTS: Transitive closure, relationship graphs, path analysis, hop counting

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS knows_relationship CASCADE;

-- Create table
CREATE TABLE knows_relationship (
    person_id INT,
    knows_person_id INT,
    relationship_type VARCHAR(20)
);

-- Insert sample data
INSERT INTO knows_relationship VALUES
(1, 2, 'friend'),
(2, 3, 'friend'),
(3, 4, 'friend'),
(1, 5, 'colleague'),
(5, 6, 'friend'),
(6, 7, 'family'),
(7, 8, 'friend'),
(2, 9, 'colleague'),
(9, 10, 'friend');

-- Find transitive closure: if A knows B and B knows C, then A knows C
WITH RECURSIVE transitive_knows AS (
    -- Base case: direct relationships
    SELECT
        person_id,
        knows_person_id,
        relationship_type,
        1 AS hop_count,
        ARRAY[person_id, knows_person_id] AS path
    FROM knows_relationship

    UNION ALL

    -- Recursive case: transitive relationships
    SELECT
        tk.person_id,
        kr.knows_person_id,
        kr.relationship_type,
        tk.hop_count + 1,
        tk.path || kr.knows_person_id
    FROM knows_relationship AS kr
    INNER JOIN transitive_knows AS tk ON kr.person_id = tk.knows_person_id
    WHERE
        NOT (kr.knows_person_id = ANY(tk.path))  -- Avoid cycles
        AND tk.hop_count < 5  -- Limit hops
)

SELECT DISTINCT
    person_id,
    knows_person_id,
    MIN(hop_count) AS shortest_path_length,
    COUNT(*) AS total_paths
FROM transitive_knows
GROUP BY person_id, knows_person_id
ORDER BY person_id, knows_person_id;

-- Clean up
DROP TABLE IF EXISTS knows_relationship CASCADE;
