-- =====================================================
-- Filling Gaps in Sequences Example
-- =====================================================
-- 
-- PURPOSE: Demonstrate recursive CTE for detecting and filling gaps in sequences
-- LEARNING OUTCOMES:
--   - Understand sequence gap detection in ordered data
--   - Learn to generate missing values using recursion
--   - Master data repair and self-healing patterns
-- EXPECTED RESULTS: Identify all missing sequence numbers between 1 and 15
-- DIFFICULTY: 🟡 Intermediate (10-20 min)
-- CONCEPTS: Sequence gap detection, data repair, recursive generation, missing value identification

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS sequence_data CASCADE;

-- Create table
CREATE TABLE sequence_data (
    id INT PRIMARY KEY,
    value VARCHAR(50),
    sequence_number INT
);

-- Insert sample data
INSERT INTO sequence_data VALUES
(1, 'Item A', 1),
(2, 'Item B', 3),
(3, 'Item C', 7),
(4, 'Item D', 10),
(5, 'Item E', 15);

-- Fill gaps in sequence using recursive CTE
WITH RECURSIVE sequence_gaps AS (
    -- Base case: find the range of sequence numbers
    SELECT 
        MIN(sequence_number) as min_seq,
        MAX(sequence_number) as max_seq
    FROM sequence_data
    
    UNION ALL
    
    -- Recursive case: generate missing numbers
    SELECT 
        min_seq + 1,
        max_seq
    FROM sequence_gaps
    WHERE min_seq < max_seq
),
missing_sequences AS (
    SELECT min_seq as missing_number
    FROM sequence_gaps
    WHERE min_seq NOT IN (SELECT sequence_number FROM sequence_data)
)
SELECT 
    missing_number,
    'Missing' as status,
    'Gap in sequence' as description
FROM missing_sequences
ORDER BY missing_number;

-- Clean up
DROP TABLE IF EXISTS sequence_data CASCADE; 