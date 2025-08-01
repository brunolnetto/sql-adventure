-- =====================================================
-- Shortest Path Example (BFS style)
-- =====================================================
-- 
-- PURPOSE: Demonstrate recursive CTE for graph traversal and shortest path finding
-- LEARNING OUTCOMES:
--   - Understand breadth-first search (BFS) algorithm implementation
--   - Learn graph traversal with cycle detection and path tracking
--   - Master distance calculation and shortest path identification
-- EXPECTED RESULTS: Find shortest path from node A to node H in the graph
-- DIFFICULTY: 🔴 Advanced (15-30 min)
<<<<<<< HEAD
-- CONCEPTS: Graph algorithms, BFS, path finding, cycle detection
=======
-- CONCEPTS: Graph algorithms, BFS, path finding, cycle detection, distance calculation
>>>>>>> 4e036c9 (feat(quests) improve quest queries)

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS graph_edges CASCADE;
DROP TABLE IF EXISTS graph_nodes CASCADE;

-- Create tables
CREATE TABLE graph_nodes (
    node_id INT PRIMARY KEY,
    node_name VARCHAR(50)
);

CREATE TABLE graph_edges (
    from_node INT,
    to_node INT,
    FOREIGN KEY (from_node) REFERENCES graph_nodes(node_id),
    FOREIGN KEY (to_node) REFERENCES graph_nodes(node_id)
);

-- Insert sample data
INSERT INTO graph_nodes VALUES
(1, 'A'),
(2, 'B'),
(3, 'C'),
(4, 'D'),
(5, 'E'),
(6, 'F'),
(7, 'G'),
(8, 'H');

INSERT INTO graph_edges VALUES
(1, 2),  -- A → B
(1, 3),  -- A → C
(2, 4),  -- B → D
(2, 5),  -- B → E
(3, 5),  -- C → E
(3, 6),  -- C → F
(4, 7),  -- D → G
(5, 7),  -- E → G
(5, 8),  -- E → H
(6, 8);  -- F → H

-- Find shortest path from A to H using BFS
WITH RECURSIVE shortest_path AS (
    -- Base case: start node
    SELECT 
        1 as node_id,
        0 as distance,
        ARRAY[1] as path,
        ARRAY['A'] as path_names
    FROM graph_nodes
    WHERE node_id = 1
    
    UNION ALL
    
    -- Recursive case: explore neighbors
    SELECT 
        ge.to_node,
        sp.distance + 1,
        sp.path || ge.to_node,
        sp.path_names || gn.node_name
    FROM graph_edges ge
    INNER JOIN shortest_path sp ON ge.from_node = sp.node_id
    INNER JOIN graph_nodes gn ON ge.to_node = gn.node_id
    WHERE NOT (ge.to_node = ANY(sp.path))  -- Avoid cycles
    AND sp.distance < 10  -- Limit depth to prevent infinite recursion
)
SELECT 
    node_id,
    distance,
    path_names,
    path
FROM shortest_path
WHERE node_id = 8  -- Target node H
ORDER BY distance
LIMIT 1;

-- Clean up
DROP TABLE IF EXISTS graph_edges CASCADE;
DROP TABLE IF EXISTS graph_nodes CASCADE; 