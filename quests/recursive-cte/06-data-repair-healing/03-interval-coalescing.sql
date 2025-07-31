-- PURPOSE: Demonstrate recursive CTE for merging overlapping or adjacent intervals
-- LEARNING OUTCOMES:
--   - Understand interval coalescing and data consolidation
--   - Learn to detect and merge overlapping or adjacent time intervals
--   - Master recursive aggregation for time-based data
-- EXPECTED RESULTS: Coalesce overlapping meetings into single intervals with combined categories
-- DIFFICULTY: Advanced
-- CONCEPTS: Interval coalescing, data consolidation, recursive aggregation
-- =====================================================
-- Interval Coalescing Example
-- =====================================================

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS time_intervals CASCADE;

-- Create table
CREATE TABLE time_intervals (
    interval_id INT PRIMARY KEY,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    category VARCHAR(50)
);

-- Insert sample data with overlapping intervals
INSERT INTO time_intervals VALUES
(1, '2024-01-01 09:00:00', '2024-01-01 11:00:00', 'Meeting A'),
(2, '2024-01-01 10:30:00', '2024-01-01 12:30:00', 'Meeting B'),
(3, '2024-01-01 14:00:00', '2024-01-01 16:00:00', 'Meeting C'),
(4, '2024-01-01 15:30:00', '2024-01-01 17:30:00', 'Meeting D'),
(5, '2024-01-01 18:00:00', '2024-01-01 20:00:00', 'Meeting E'),
(6, '2024-01-02 09:00:00', '2024-01-02 10:00:00', 'Meeting F'),
(7, '2024-01-02 09:30:00', '2024-01-02 11:30:00', 'Meeting G');

-- Coalesce overlapping intervals recursively
WITH RECURSIVE interval_coalescing AS (
    -- Base case: start with the earliest interval
    SELECT 
        interval_id,
        start_time,
        end_time,
        CAST(category AS VARCHAR(200)) as category,
        0 as coalesce_step,
        ARRAY[interval_id] as coalesced_intervals
    FROM time_intervals
    WHERE start_time = (SELECT MIN(start_time) FROM time_intervals)
    
    UNION ALL
    
    -- Recursive case: merge overlapping intervals
    SELECT 
        ic.interval_id,
        LEAST(ic.start_time, ti.start_time) as start_time,
        GREATEST(ic.end_time, ti.end_time) as end_time,
        CAST(ic.category || ' + ' || ti.category AS VARCHAR(200)) as category,
        ic.coalesce_step + 1,
        ic.coalesced_intervals || ti.interval_id
    FROM time_intervals ti
    INNER JOIN interval_coalescing ic ON (
        -- Check for overlap: current interval overlaps with coalesced interval
        (ti.start_time <= ic.end_time AND ti.end_time >= ic.start_time)
        OR
        -- Check for adjacency: current interval starts right after coalesced interval
        (ti.start_time = ic.end_time)
    )
    WHERE NOT (ti.interval_id = ANY(ic.coalesced_intervals))  -- Not already included
    AND ic.coalesce_step < 10  -- Limit coalescing steps
)
SELECT 
    coalesce_step,
    start_time,
    end_time,
    category,
    EXTRACT(EPOCH FROM (end_time - start_time))/3600 as duration_hours,
    coalesced_intervals
FROM interval_coalescing
ORDER BY start_time, coalesce_step;

-- Clean up
DROP TABLE IF EXISTS time_intervals CASCADE; 