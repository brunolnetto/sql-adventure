-- =====================================================
-- Topological Sort Example
-- =====================================================

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

-- Perform topological sort
WITH RECURSIVE topological_sort AS (
    -- Base case: tasks with no dependencies
    SELECT 
        t.task_id,
        t.task_name,
        t.duration,
        0 as level,
        ARRAY[t.task_id] as sorted_order,
        ARRAY[t.task_name] as sorted_names
    FROM tasks t
    WHERE NOT EXISTS (
        SELECT 1 FROM task_dependencies td 
        WHERE td.dependent_task = t.task_id
    )
    
    UNION ALL
    
    -- Recursive case: add tasks whose dependencies are completed
    SELECT 
        t.task_id,
        t.task_name,
        t.duration,
        ts.level + 1,
        ts.sorted_order || t.task_id,
        ts.sorted_names || t.task_name
    FROM tasks t
    INNER JOIN task_dependencies td ON t.task_id = td.dependent_task
    INNER JOIN topological_sort ts ON td.prerequisite_task = ts.task_id
    WHERE NOT (t.task_id = ANY(ts.sorted_order))  -- Not already included
    AND NOT EXISTS (  -- All dependencies are in sorted_order
        SELECT 1 FROM task_dependencies td2
        WHERE td2.dependent_task = t.task_id
        AND NOT (td2.prerequisite_task = ANY(ts.sorted_order))
    )
)
SELECT 
    level,
    task_id,
    task_name,
    duration,
    sorted_names
FROM topological_sort
ORDER BY level, task_id;

-- Clean up
DROP TABLE IF EXISTS task_dependencies CASCADE;
DROP TABLE IF EXISTS tasks CASCADE; 