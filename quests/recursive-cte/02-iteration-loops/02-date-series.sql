-- =====================================================
-- Date Series Generation Example
-- =====================================================

-- Generate all dates between 2024-01-01 and 2024-01-31
WITH RECURSIVE date_series AS (
    -- Base case: start date
    SELECT DATE '2024-01-01' as date_value
    
    UNION ALL
    
    -- Recursive case: add one day
    SELECT CAST(date_value + INTERVAL '1 day' AS DATE)
    FROM date_series
    WHERE date_value < DATE '2024-01-31'
)
SELECT 
    date_value,
    EXTRACT(DOW FROM date_value) as day_of_week,
    EXTRACT(DAY FROM date_value) as day_of_month
FROM date_series
ORDER BY date_value;

-- Generate business days only (Monday to Friday)
WITH RECURSIVE business_days AS (
    -- Base case: start with first business day
    SELECT DATE '2024-01-01' as date_value
    
    UNION ALL
    
    -- Recursive case: add one day
    SELECT CAST(date_value + INTERVAL '1 day' AS DATE)
    FROM business_days
    WHERE date_value < DATE '2024-01-31'
)
SELECT 
    date_value,
    CASE EXTRACT(DOW FROM date_value)
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
    END as day_name
FROM business_days
WHERE EXTRACT(DOW FROM date_value) BETWEEN 1 AND 5
ORDER BY date_value; 