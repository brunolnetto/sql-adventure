-- =====================================================
-- Recursive CTE: Dependency Resolution and Chain Analysis
-- =====================================================
-- 
-- PURPOSE: Demonstrate recursive CTE for dependency resolution and cycle detection
-- LEARNING OUTCOMES:
--   - Understand dependency graph traversal and resolution
--   - Learn to detect and handle circular dependencies
--   - Master complex dependency chain analysis
-- EXPECTED RESULTS: Complete dependency chain for package 1 with cycle detection
-- DIFFICULTY: 🔴 Advanced (15-30 min)
-- CONCEPTS: Recursive CTE, Dependency Resolution, Cycle Detection, Graph Analysis

-- PURPOSE: Demonstrate recursive CTE for resolving package dependencies
--          and analyzing dependency chains in software systems
-- LEARNING OUTCOMES: Students will understand how to use recursive CTEs for
--                    dependency resolution, chain analysis, and managing
--                    complex dependency relationships
-- EXPECTED RESULTS:
-- 1. Complete dependency chains resolved recursively
-- 2. Dependency levels tracked for complexity analysis
-- 3. Cycle detection in dependency chains
-- 4. Dependency path tracking and visualization
-- 5. Transitive dependency resolution
-- DIFFICULTY: 🔴 Advanced (15-30 min)
-- CONCEPTS: Recursive CTE, dependency resolution, chain analysis, cycle detection, transitive dependencies, path tracking

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS dependencies CASCADE;

-- Create table
CREATE TABLE dependencies (
    package_id INT,
    depends_on_id INT,
    version VARCHAR(20)
);

-- Insert sample data
INSERT INTO dependencies VALUES
(1, 2, '1.0.0'),  -- Package 1 depends on Package 2
(1, 3, '2.1.0'),  -- Package 1 depends on Package 3
(2, 4, '0.9.0'),  -- Package 2 depends on Package 4
(3, 4, '0.9.0'),  -- Package 3 depends on Package 4
(3, 5, '1.5.0'),  -- Package 3 depends on Package 5
(5, 6, '2.0.0');  -- Package 5 depends on Package 6

-- Find all dependencies for a specific package
WITH RECURSIVE package_deps AS (
    -- Base case: direct dependencies
    SELECT 
        package_id,
        depends_on_id,
        version,
        1 as level,
        CAST(depends_on_id AS VARCHAR(100)) as dep_chain,
        ARRAY[depends_on_id] as dep_path
    FROM dependencies 
    WHERE package_id = 1
    
    UNION ALL
    
    -- Recursive case: transitive dependencies
    SELECT 
        pd.package_id,
        d.depends_on_id,
        d.version,
        pd.level + 1,
        CAST(pd.dep_chain || ' → ' || d.depends_on_id AS VARCHAR(100)),
        pd.dep_path || d.depends_on_id
    FROM dependencies d
    INNER JOIN package_deps pd ON d.package_id = pd.depends_on_id
    WHERE pd.level < 10  -- Limit to 10 levels
    AND NOT (d.depends_on_id = ANY(pd.dep_path))  -- Prevent cycles
)
SELECT 
    level,
    depends_on_id,
    version,
    dep_chain
FROM package_deps
ORDER BY level, depends_on_id;

-- Clean up
DROP TABLE IF EXISTS dependencies CASCADE; 