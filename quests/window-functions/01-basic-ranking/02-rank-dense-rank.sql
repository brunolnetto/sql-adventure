-- =====================================================
-- Window Functions: RANK and DENSE_RANK
-- =====================================================

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS student_scores CASCADE;

-- Create sample student scores table
CREATE TABLE student_scores (
    student_id INT PRIMARY KEY,
    student_name VARCHAR(100),
    subject VARCHAR(50),
    score DECIMAL(5,2),
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
    ROW_NUMBER() OVER (ORDER BY score DESC) as row_number,
    RANK() OVER (ORDER BY score DESC) as rank_with_gaps,
    DENSE_RANK() OVER (ORDER BY score DESC) as dense_rank_no_gaps
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
    RANK() OVER (PARTITION BY subject ORDER BY score DESC) as subject_rank,
    DENSE_RANK() OVER (PARTITION BY subject ORDER BY score DESC) as subject_dense_rank
FROM student_scores
ORDER BY subject, score DESC;

-- =====================================================
-- Example 3: Multiple Ranking Functions
-- =====================================================

-- Show all ranking functions together
SELECT 
    student_name,
    subject,
    score,
    ROW_NUMBER() OVER (PARTITION BY subject ORDER BY score DESC) as row_num,
    RANK() OVER (PARTITION BY subject ORDER BY score DESC) as rank_with_gaps,
    DENSE_RANK() OVER (PARTITION BY subject ORDER BY score DESC) as dense_rank,
    NTILE(3) OVER (PARTITION BY subject ORDER BY score DESC) as performance_tier
FROM student_scores
ORDER BY subject, score DESC;

-- =====================================================
-- Example 4: Ranking with Multiple Criteria
-- =====================================================

-- Rank by score, then by exam date (for same scores)
SELECT 
    student_name,
    subject,
    score,
    exam_date,
    RANK() OVER (ORDER BY score DESC, exam_date ASC) as overall_rank,
    DENSE_RANK() OVER (ORDER BY score DESC, exam_date ASC) as overall_dense_rank
FROM student_scores
ORDER BY score DESC, exam_date ASC;

-- =====================================================
-- Example 5: Top N Students by Subject
-- =====================================================

-- Get top 3 students from each subject
WITH ranked_students AS (
    SELECT 
        student_name,
        subject,
        score,
        DENSE_RANK() OVER (PARTITION BY subject ORDER BY score DESC) as subject_rank
    FROM student_scores
)
SELECT 
    student_name,
    subject,
    score,
    subject_rank
FROM ranked_students
WHERE subject_rank <= 3
ORDER BY subject, subject_rank;

-- =====================================================
-- Example 6: Ranking with Filtering
-- =====================================================

-- Rank only Mathematics students
SELECT 
    student_name,
    score,
    RANK() OVER (ORDER BY score DESC) as math_rank,
    DENSE_RANK() OVER (ORDER BY score DESC) as math_dense_rank
FROM student_scores
WHERE subject = 'Mathematics'
ORDER BY score DESC;

-- =====================================================
-- Example 7: Percentile Ranking
-- =====================================================

-- Show percentile ranks
SELECT 
    student_name,
    subject,
    score,
    ROUND(
        (RANK() OVER (PARTITION BY subject ORDER BY score DESC) - 1) * 100.0 / 
        (COUNT(*) OVER (PARTITION BY subject) - 1), 2
    ) as percentile_rank,
    ROUND(
        (DENSE_RANK() OVER (PARTITION BY subject ORDER BY score DESC) - 1) * 100.0 / 
        (COUNT(DISTINCT score) OVER (PARTITION BY subject) - 1), 2
    ) as dense_percentile_rank
FROM student_scores
ORDER BY subject, score DESC;

-- Clean up
DROP TABLE IF EXISTS student_scores CASCADE; 