-- =====================================================
-- Prime Number Generation Example
-- =====================================================

-- Generate prime numbers using Sieve of Eratosthenes (simplified)
WITH RECURSIVE prime_generation AS (
    -- Base case: start with 2 (first prime)
    SELECT 
        2 as number,
        1 as prime_count,
        ARRAY[2] as primes_found
    FROM (VALUES (1)) as t(n)
    
    UNION ALL
    
    -- Recursive case: check next number for primality
    SELECT 
        pg.number + 1,
        CASE 
            WHEN NOT EXISTS (
                SELECT 1 FROM prime_generation pg2 
                WHERE pg2.number <= SQRT(pg.number + 1) 
                AND (pg.number + 1) % pg2.number = 0
            ) THEN pg.prime_count + 1
            ELSE pg.prime_count
        END as prime_count,
        CASE 
            WHEN NOT EXISTS (
                SELECT 1 FROM prime_generation pg2 
                WHERE pg2.number <= SQRT(pg.number + 1) 
                AND (pg.number + 1) % pg2.number = 0
            ) THEN pg.primes_found || (pg.number + 1)
            ELSE pg.primes_found
        END as primes_found
    FROM prime_generation pg
    WHERE pg.number < 50  -- Limit to first 50 numbers
)
SELECT 
    number,
    prime_count,
    primes_found,
    CASE 
        WHEN number = ANY(primes_found) THEN 'Prime'
        ELSE 'Composite'
    END as number_type
FROM prime_generation
WHERE number = ANY(primes_found)  -- Only show primes
ORDER BY number; 