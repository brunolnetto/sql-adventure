-- =====================================================
-- Recursive CTE: Longest Work Streak Analysis
-- =====================================================

-- PURPOSE: Demonstrate recursive CTE for analyzing continuous work streaks
--          and identifying patterns in employee attendance data
-- LEARNING OUTCOMES: Students will understand how to use recursive CTEs for
--                    pattern recognition, streak analysis, and identifying
--                    continuous sequences in time series data
-- EXPECTED RESULTS:
-- 1. Longest continuous work streaks identified for each employee
-- 2. Streak start and end dates calculated
-- 3. Total hours worked during streaks
-- 4. Pattern recognition in attendance data
-- 5. Continuous sequence analysis in time series
-- DIFFICULTY: 🟡 Intermediate (10-20 min)
-- CONCEPTS: Recursive CTE, pattern recognition, streak analysis, time series, continuous sequences, attendance tracking

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS employee_attendance CASCADE;

-- Create table
CREATE TABLE employee_attendance (
    employee_id INT,
    work_date DATE,
    hours_worked DECIMAL(4,2),
    PRIMARY KEY (employee_id, work_date)
);

-- Insert sample data
INSERT INTO employee_attendance VALUES
(1, '2024-01-01', 8.0), (1, '2024-01-02', 8.0), (1, '2024-01-03', 8.0),
(1, '2024-01-04', 0.0), -- Day off
(1, '2024-01-05', 8.0), (1, '2024-01-06', 8.0), (1, '2024-01-07', 8.0),
(1, '2024-01-08', 8.0), (1, '2024-01-09', 8.0), (1, '2024-01-10', 8.0),
(2, '2024-01-01', 8.0), (2, '2024-01-02', 8.0), (2, '2024-01-03', 8.0),
(2, '2024-01-04', 8.0), (2, '2024-01-05', 8.0), (2, '2024-01-06', 8.0),
(2, '2024-01-07', 0.0), -- Day off
(2, '2024-01-08', 8.0), (2, '2024-01-09', 8.0), (2, '2024-01-10', 8.0);

-- Find longest continuous work streaks
WITH RECURSIVE work_streaks AS (
    -- Base case: start with first work day for each employee
    SELECT 
        employee_id,
        work_date,
        hours_worked,
        1 as streak_length,
        work_date as streak_start,
        work_date as streak_end
    FROM employee_attendance
    WHERE hours_worked > 0
    AND work_date = (
        SELECT MIN(work_date) 
        FROM employee_attendance ea2 
        WHERE ea2.employee_id = employee_attendance.employee_id
    )
    
    UNION ALL
    
    -- Recursive case: extend streak if consecutive work days
    SELECT 
        ea.employee_id,
        ea.work_date,
        ea.hours_worked,
        CASE 
            WHEN ea.hours_worked > 0 AND ea.work_date = ws.work_date + INTERVAL '1 day'
            THEN ws.streak_length + 1
            ELSE 1
        END as streak_length,
        CASE 
            WHEN ea.hours_worked > 0 AND ea.work_date = ws.work_date + INTERVAL '1 day'
            THEN ws.streak_start
            ELSE ea.work_date
        END as streak_start,
        ea.work_date as streak_end
    FROM employee_attendance ea
    INNER JOIN work_streaks ws ON ea.employee_id = ws.employee_id
    WHERE ea.work_date > ws.work_date
    AND ea.work_date = ws.work_date + INTERVAL '1 day'
)
SELECT 
    employee_id,
    MAX(streak_length) as longest_streak,
    streak_start,
    streak_end,
    streak_length * 8 as total_hours_in_streak
FROM work_streaks
WHERE streak_length = (
    SELECT MAX(streak_length) 
    FROM work_streaks ws2 
    WHERE ws2.employee_id = work_streaks.employee_id
)
GROUP BY employee_id, streak_start, streak_end, streak_length
ORDER BY longest_streak DESC;

-- Clean up
DROP TABLE IF EXISTS employee_attendance CASCADE; 