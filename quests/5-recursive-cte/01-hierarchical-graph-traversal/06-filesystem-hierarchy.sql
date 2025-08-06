-- =====================================================
-- Filesystem Hierarchy Example
-- =====================================================
-- 
-- PURPOSE: Demonstrate recursive CTE for filesystem hierarchy traversal and size calculation
-- LEARNING OUTCOMES:
--   - Understand complex hierarchical data traversal
--   - Learn to calculate aggregated values in hierarchical structures
--   - Master recursive CTE with multiple aggregation patterns
-- EXPECTED RESULTS: Complete filesystem hierarchy with full paths and directory sizes
-- DIFFICULTY: 🟡 Intermediate (10-20 min)
-- CONCEPTS: Recursive CTE, Hierarchical Aggregation, Path Manipulation, Size Calculation

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS filesystem CASCADE;

-- Create table to represent filesystem structure
CREATE TABLE filesystem (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    parent_id INT,
    is_directory BOOLEAN,
    size_bytes BIGINT,
    created_date TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES filesystem (id)
);

-- Insert sample filesystem data
INSERT INTO filesystem VALUES
(1, 'root', NULL, TRUE, 0, '2024-01-01 00:00:00'),
(2, 'home', 1, TRUE, 0, '2024-01-01 00:00:00'),
(3, 'user1', 2, TRUE, 0, '2024-01-01 00:00:00'),
(4, 'Documents', 3, TRUE, 0, '2024-01-01 00:00:00'),
(5, 'Projects', 3, TRUE, 0, '2024-01-01 00:00:00'),
(6, 'Downloads', 3, TRUE, 0, '2024-01-01 00:00:00'),
(7, 'report.pdf', 4, FALSE, 1024000, '2024-01-15 10:30:00'),
(8, 'presentation.pptx', 4, FALSE, 2048000, '2024-01-16 14:20:00'),
(9, 'sql-adventure', 5, TRUE, 0, '2024-01-20 09:00:00'),
(10, 'README.md', 9, FALSE, 5120, '2024-01-20 09:00:00'),
(11, 'docker-compose.yml', 9, FALSE, 2048, '2024-01-20 09:00:00'),
(12, 'image.jpg', 6, FALSE, 512000, '2024-01-18 16:45:00'),
(13, 'music.mp3', 6, FALSE, 8192000, '2024-01-19 11:15:00'),
(14, 'src', 9, TRUE, 0, '2024-01-20 09:00:00'),
(15, 'main.py', 14, FALSE, 15360, '2024-01-20 09:00:00'),
(16, 'config.json', 14, FALSE, 1024, '2024-01-20 09:00:00');

-- Find complete filesystem hierarchy with full paths
WITH RECURSIVE filesystem_tree AS (
    -- Base case: root directory
    SELECT
        id,
        name,
        parent_id,
        is_directory,
        size_bytes,
        created_date,
        0 AS level,
        CAST(name AS VARCHAR(500)) AS full_path,
        size_bytes AS total_size
    FROM filesystem
    WHERE parent_id IS NULL

    UNION ALL

    -- Recursive case: child files and directories
    SELECT
        f.id,
        f.name,
        f.parent_id,
        f.is_directory,
        f.size_bytes,
        f.created_date,
        ft.level + 1,
        CAST(ft.full_path || '/' || f.name AS VARCHAR(500)),
        CASE
            WHEN f.is_directory THEN 0
            ELSE f.size_bytes
        END AS total_size
    FROM filesystem AS f
    INNER JOIN filesystem_tree AS ft ON f.parent_id = ft.id
)

SELECT
    level,
    name,
    full_path,
    created_date,
    CASE
        WHEN is_directory THEN 'Directory'
        ELSE 'File'
    END AS type,
    CASE
        WHEN is_directory THEN 'N/A'
        ELSE CAST (size_bytes AS VARCHAR) || ' bytes'
    END AS size
FROM filesystem_tree
ORDER BY full_path;

-- Calculate directory sizes (including subdirectories)
WITH RECURSIVE directory_sizes AS (
    -- Base case: files (leaf nodes)
    SELECT
        id,
        parent_id,
        size_bytes AS total_size,
        0 AS level
    FROM filesystem
    WHERE NOT is_directory

    UNION ALL

    -- Recursive case: aggregate sizes up the tree
    SELECT
        f.id,
        f.parent_id,
        ds.total_size + COALESCE(f.size_bytes, 0),
        ds.level + 1
    FROM filesystem AS f
    INNER JOIN directory_sizes AS ds ON f.id = ds.parent_id
    WHERE f.is_directory
),

final_sizes AS (
    -- Get the final size for each directory (highest level)
    SELECT DISTINCT
        id,
        parent_id,
        MAX(total_size) OVER (PARTITION BY id) AS total_size,
        MAX(level) OVER (PARTITION BY id) AS max_level
    FROM directory_sizes
)

SELECT
    f.name AS directory_name,
    fs.total_size AS total_size_bytes,
    ROUND(fs.total_size / 1024.0, 2) AS total_size_kb,
    ROUND(fs.total_size / 1024.0 / 1024.0, 2) AS total_size_mb
FROM final_sizes AS fs
INNER JOIN filesystem AS f ON fs.id = f.id
WHERE f.is_directory
ORDER BY fs.total_size DESC;

-- Clean up
DROP TABLE IF EXISTS filesystem CASCADE;
