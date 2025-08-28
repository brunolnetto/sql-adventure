-- =====================================================
-- Recursive CTE quest: String Splitting Example
-- =====================================================
-- 
-- PURPOSE: Demonstrate recursive CTE for parsing and splitting delimited strings
-- LEARNING OUTCOMES:
--   - Understand string parsing and tokenization techniques
--   - Learn to extract values from delimited strings using recursion
--   - Master iterative string processing and token extraction
-- EXPECTED RESULTS: Split "apple,banana,cherry,date,elderberry" into 5 individual values
-- DIFFICULTY: 🟢 Beginner (5-10 min)
-- CONCEPTS: String parsing, tokenization, iterative processing, string manipulation

-- Split a comma-separated string into individual values
WITH RECURSIVE string_split AS (
    -- Base case: find first comma or end of string
    SELECT
        'apple,banana,cherry,date,elderberry' AS input_string,
        1 AS position,
        CASE
            WHEN POSITION(',' IN 'apple,banana,cherry,date,elderberry') > 0
                THEN
                    SUBSTRING(
                        'apple,banana,cherry,date,elderberry' FROM 1 FOR POSITION(
                            ',' IN 'apple,banana,cherry,date,elderberry'
                        )
                        - 1
                    )
            ELSE 'apple,banana,cherry,date,elderberry'
        END AS extracted_value,
        CASE
            WHEN POSITION(',' IN 'apple,banana,cherry,date,elderberry') > 0
                THEN
                    SUBSTRING(
                        'apple,banana,cherry,date,elderberry' FROM POSITION(
                            ',' IN 'apple,banana,cherry,date,elderberry'
                        )
                        + 1
                    )
            ELSE ''
        END AS remaining_string

    UNION ALL

    -- Recursive case: process remaining string
    SELECT
        remaining_string,
        position + 1,
        CASE
            WHEN POSITION(',' IN remaining_string) > 0
                THEN
                    SUBSTRING(
                        remaining_string FROM 1 FOR POSITION(
                            ',' IN remaining_string
                        )
                        - 1
                    )
            ELSE remaining_string
        END,
        CASE
            WHEN POSITION(',' IN remaining_string) > 0
                THEN
                    SUBSTRING(
                        remaining_string FROM POSITION(',' IN remaining_string)
                        + 1
                    )
            ELSE ''
        END
    FROM string_split
    WHERE LENGTH(remaining_string) > 0
)

SELECT
    position,
    extracted_value,
    LENGTH(extracted_value) AS value_length
FROM string_split
WHERE LENGTH(extracted_value) > 0
ORDER BY position;
