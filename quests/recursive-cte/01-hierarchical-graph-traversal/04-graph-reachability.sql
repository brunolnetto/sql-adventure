-- =====================================================
-- Graph Reachability Example
-- =====================================================

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS graph_edges CASCADE;

-- Create table
CREATE TABLE graph_edges (
    from_node INT,
    to_node INT,
    weight INT
);

-- Insert sample data
INSERT INTO graph_edges VALUES
(1, 2, 1),
(2, 3, 1),
(3, 4, 1),
(1, 5, 1),
(5, 6, 1),
(6, 4, 1),
(7, 8, 1);

-- Find all nodes reachable from node 1
WITH RECURSIVE reachable_nodes AS (
    -- Base case: start node
    SELECT 
        from_node as node,
        0 as distance,
        CAST(from_node AS VARCHAR(100)) as path
    FROM graph_edges 
    WHERE from_node = 1
    
    UNION ALL
    
    -- Recursive case: follow edges
    SELECT 
        ge.to_node,
        rn.distance + 1,
        CAST(rn.path || ' → ' || ge.to_node AS VARCHAR(100))
    FROM graph_edges ge
    INNER JOIN reachable_nodes rn ON ge.from_node = rn.node
)
SELECT DISTINCT
    node,
    MIN(distance) as shortest_distance,
    MIN(path) as shortest_path
FROM reachable_nodes
GROUP BY node
ORDER BY shortest_distance, node;

-- Clean up
DROP TABLE IF EXISTS graph_edges CASCADE; 