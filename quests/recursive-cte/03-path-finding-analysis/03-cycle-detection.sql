-- =====================================================
-- Cycle Detection Example
-- =====================================================
-- PURPOSE: Demonstrate recursive CTE for detecting cycles in directed graphs
-- LEARNING OUTCOMES: 
--   - Understand cycle detection in directed graphs
--   - Learn to track paths and detect revisits
--   - Master graph traversal with cycle prevention
-- EXPECTED RESULTS: Detect cycles in the graph (B→C→D→E→B and A→F→A)
-- DIFFICULTY: Advanced
-- CONCEPTS: Graph algorithms, cycle detection, path tracking

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

-- Insert sample data (including cycles)
INSERT INTO graph_nodes VALUES
(1, 'A'),
(2, 'B'),
(3, 'C'),
(4, 'D'),
(5, 'E'),
(6, 'F');

INSERT INTO graph_edges VALUES
(1, 2),  -- A → B
(2, 3),  -- B → C
(3, 4),  -- C → D
(4, 5),  -- D → E
(5, 2),  -- E → B (creates cycle: B → C → D → E → B)
(1, 6),  -- A → F
(6, 1);  -- F → A (creates cycle: A → F → A)

-- Detect cycles in the graph
WITH RECURSIVE cycle_detection AS (
    -- Base case: start from each node
    SELECT 
        from_node as start_node,
        from_node as current_node,
        ARRAY[from_node] as path,
        ARRAY[gn.node_name]::VARCHAR[] as path_names,
        0 as depth
    FROM graph_edges ge
    INNER JOIN graph_nodes gn ON ge.from_node = gn.node_id
    
    UNION ALL
    
    -- Recursive case: follow edges and detect cycles
    SELECT 
        cd.start_node,
        ge.to_node,
        cd.path || ge.to_node,
        cd.path_names || gn.node_name,
        cd.depth + 1
    FROM graph_edges ge
    INNER JOIN cycle_detection cd ON ge.from_node = cd.current_node
    INNER JOIN graph_nodes gn ON ge.to_node = gn.node_id
    WHERE NOT (ge.to_node = ANY(cd.path))  -- Continue if no cycle yet
    AND cd.depth < 10  -- Limit depth to prevent infinite recursion
),
cycle_found AS (
    -- Find cycles: when we reach a node that's already in the path
    SELECT DISTINCT
        start_node,
        current_node,
        path,
        path_names,
        depth,
        'Cycle detected' as cycle_type
    FROM cycle_detection cd
    WHERE EXISTS (
        SELECT 1 FROM graph_edges ge 
        WHERE ge.from_node = cd.current_node 
        AND ge.to_node = ANY(cd.path)
    )
)
SELECT 
    start_node,
    current_node,
    path_names,
    depth,
    cycle_type
FROM cycle_found
ORDER BY depth, start_node;

-- Clean up
DROP TABLE IF EXISTS graph_edges CASCADE;
DROP TABLE IF EXISTS graph_nodes CASCADE; 