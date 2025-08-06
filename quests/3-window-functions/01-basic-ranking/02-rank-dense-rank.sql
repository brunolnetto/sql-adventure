-- =====================================================
-- Window Functions: Basic RANK and DENSE_RANK
-- =====================================================

-- PURPOSE: Demonstrate RANK() and DENSE_RANK() functions for handling ties
--          and understanding the differences between ranking methods
-- LEARNING OUTCOMES: Students will understand how to use RANK() and DENSE_RANK()
--                    for ranking data with ties, and when to use each function
-- EXPECTED RESULTS:
-- 1. RANK() shows gaps in ranking when ties occur
-- 2. DENSE_RANK() shows consecutive ranking without gaps
-- 3. ROW_NUMBER() provides unique sequential numbers
-- 4. Ranking within partitions by subject
-- 5. Multiple ranking functions compared side by side
-- 6. Top N students identified using ranking functions
-- 7. Percentile ranking calculations using RANK and DENSE_RANK
-- DIFFICULTY: 🟢 Beginner (5-10 min)
-- CONCEPTS: RANK(), DENSE_RANK(), ROW_NUMBER(), PARTITION BY, ranking with ties, percentile calculations

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS student_scores CASCADE;

-- Create sample student scores table
CREATE TABLE student_scores (
    student_id INT PRIMARY KEY,
    student_name VARCHAR(100),
    subject VARCHAR(50),
    score DECIMAL(5, 2),
    exam_date DATE
);

-- Insert sample data with ties
INSERT INTO student_scores VALUES
(1, 'Alice Johnson', 'Mathematics', 95.50, '2024-01-15'),
(2, 'Bob Smith', 'Mathematics', 88.00, '2024-01-15'),
(3, 'Carol Davis', 'Mathematics', 95.50, '2024-01-15'), -- Tie with Alice
(4, 'David Wilson', 'Mathematics', 92.00, '2024-01-15'),
(5, 'Eve Brown', 'Mathematics', 88.00, '2024-01-15'),   -- Tie with Bob
(6, 'Frank Miller', 'Mathematics', 85.00, '2024-01-15'),
(7, 'Grace Lee', 'Mathematics', 90.00, '2024-01-15'),
(8, 'Henry Taylor', 'Mathematics', 88.00, '2024-01-15'); -- Tie with Bob and Eve

-- =====================================================
-- Example 1: Basic RANK vs DENSE_RANK
-- =====================================================

-- Compare RANK and DENSE_RANK for handling ties
SELECT
    student_name,
    score,
    ROW_NUMBER() OVER (ORDER BY score DESC) AS row_number,
    RANK() OVER (ORDER BY score DESC) AS rank_with_gaps,
    DENSE_RANK() OVER (ORDER BY score DESC) AS dense_rank_no_gaps
FROM student_scores
ORDER BY score DESC;

-- =====================================================
-- Example 2: RANK with PARTITION BY
-- =====================================================

-- Add more subjects to demonstrate partitioning
INSERT INTO student_scores VALUES
(9, 'Alice Johnson', 'Physics', 92.00, '2024-01-16'),
(10, 'Bob Smith', 'Physics', 89.00, '2024-01-16'),
(11, 'Carol Davis', 'Physics', 94.00, '2024-01-16'),
(12, 'David Wilson', 'Physics', 91.00, '2024-01-16'),
(13, 'Eve Brown', 'Physics', 89.00, '2024-01-16'),
(14, 'Frank Miller', 'Physics', 87.00, '2024-01-16'),
(15, 'Grace Lee', 'Physics', 93.00, '2024-01-16'),
(16, 'Henry Taylor', 'Physics', 88.00, '2024-01-16');

-- Rank students within each subject
SELECT
    student_name,
    subject,
    score,
    RANK() OVER (PARTITION BY subject ORDER BY score DESC) AS subject_rank,
    DENSE_RANK()
        OVER (PARTITION BY subject ORDER BY score DESC)
        AS subject_dense_rank
FROM student_scores
ORDER BY subject ASC, score DESC;

-- =====================================================
-- Example 3: Multiple Ranking Functions
-- =====================================================

-- Show all ranking functions together
SELECT
    student_name,
    subject,
    score,
    ROW_NUMBER() OVER (PARTITION BY subject ORDER BY score DESC) AS row_num,
    RANK() OVER (PARTITION BY subject ORDER BY score DESC) AS rank_with_gaps,
    DENSE_RANK() OVER (PARTITION BY subject ORDER BY score DESC) AS dense_rank,
    NTILE(3) OVER (PARTITION BY subject ORDER BY score DESC) AS performance_tier
FROM student_scores
ORDER BY subject ASC, score DESC;

-- Clean up
DROP TABLE IF EXISTS student_scores CASCADE;
