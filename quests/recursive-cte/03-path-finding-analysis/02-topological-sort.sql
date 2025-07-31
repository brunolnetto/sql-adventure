-- =====================================================
-- Topological Sort Example
-- =====================================================
-- PURPOSE: Demonstrate recursive CTE for dependency resolution and topological sorting
-- LEARNING OUTCOMES: 
--   - Understand dependency graphs and topological ordering
--   - Learn to resolve task dependencies and prerequisites
--   - Master level-based dependency resolution
-- EXPECTED RESULTS: Sort tasks by dependency levels (0, 1, 2) for project planning
-- DIFFICULTY: ⚫ Expert (30-45 min)
-- CONCEPTS: Dependency resolution, topological sorting, project planning

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS task_dependencies CASCADE;
DROP TABLE IF EXISTS tasks CASCADE;

-- Create tables
CREATE TABLE tasks (
    task_id INT PRIMARY KEY,
    task_name VARCHAR(100),
    duration INT
);

CREATE TABLE task_dependencies (
    dependent_task INT,
    prerequisite_task INT,
    FOREIGN KEY (dependent_task) REFERENCES tasks(task_id),
    FOREIGN KEY (prerequisite_task) REFERENCES tasks(task_id)
);

-- Insert sample data
INSERT INTO tasks VALUES
(1, 'Design', 5),
(2, 'Frontend Development', 10),
(3, 'Backend Development', 15),
(4, 'Database Setup', 3),
(5, 'Testing', 7),
(6, 'Deployment', 2);

INSERT INTO task_dependencies VALUES
(2, 1),  -- Frontend depends on Design
(3, 1),  -- Backend depends on Design
(3, 4),  -- Backend depends on Database Setup
(5, 2),  -- Testing depends on Frontend
(5, 3),  -- Testing depends on Backend
(6, 5);  -- Deployment depends on Testing

-- Perform topological sort with manual level assignment
WITH task_dependency_counts AS (
    -- Count dependencies for each task
    SELECT 
        t.task_id,
        t.task_name,
        t.duration,
        COUNT(td.prerequisite_task) as dependency_count
    FROM tasks t
    LEFT JOIN task_dependencies td ON t.task_id = td.dependent_task
    GROUP BY t.task_id, t.task_name, t.duration
),
level0_tasks AS (
    -- Level 0: tasks with no dependencies
    SELECT 
        task_id,
        task_name,
        duration,
        0 as level
    FROM task_dependency_counts
    WHERE dependency_count = 0
),
level1_tasks AS (
    -- Level 1: tasks that depend only on level 0 tasks
    SELECT 
        tdc.task_id,
        tdc.task_name,
        tdc.duration,
        1 as level
    FROM task_dependency_counts tdc
    WHERE tdc.dependency_count > 0
    AND NOT EXISTS (
        SELECT 1 FROM task_dependencies td
        INNER JOIN task_dependency_counts tdc2 ON td.prerequisite_task = tdc2.task_id
        WHERE td.dependent_task = tdc.task_id
        AND tdc2.dependency_count > 0
    )
),
level2_tasks AS (
    -- Level 2: remaining tasks
    SELECT 
        tdc.task_id,
        tdc.task_name,
        tdc.duration,
        2 as level
    FROM task_dependency_counts tdc
    WHERE tdc.task_id NOT IN (
        SELECT task_id FROM level0_tasks
        UNION ALL
        SELECT task_id FROM level1_tasks
    )
)
SELECT 
    level,
    task_id,
    task_name,
    duration,
    'Level ' || level || ' - ' || task_name as level_description
FROM (
    SELECT * FROM level0_tasks
    UNION ALL
    SELECT * FROM level1_tasks
    UNION ALL
    SELECT * FROM level2_tasks
) all_levels
ORDER BY level, task_id;

-- Clean up
DROP TABLE IF EXISTS task_dependencies CASCADE;
DROP TABLE IF EXISTS tasks CASCADE; 