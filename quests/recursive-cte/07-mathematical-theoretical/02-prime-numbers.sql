-- =====================================================
-- Prime Number Generation Example
-- =====================================================
-- 
-- PURPOSE: Demonstrate recursive CTE for generating prime numbers using the sieve method
-- LEARNING OUTCOMES:
--   - Understand prime number generation and primality testing algorithms
--   - Learn to use arrays and recursion for mathematical algorithms
--   - Master iterative filtering and sequence building for prime numbers
-- EXPECTED RESULTS: Generate all prime numbers up to 20
-- DIFFICULTY: 🔴 Advanced (15-30 min)
-- CONCEPTS: Prime number generation, sieve algorithms, mathematical recursion, primality testing

-- Generate prime numbers using a simpler approach
WITH RECURSIVE prime_generation AS (
    -- Base case: start with 2 (first prime)
    SELECT 
        2 as number,
        ARRAY[2] as primes_found
    FROM (VALUES (1)) as t(n)
    
    UNION ALL
    
    -- Recursive case: check next number for primality
    SELECT 
        pg.number + 1,
        CASE 
            WHEN NOT EXISTS (
                SELECT 1 FROM unnest(pg.primes_found) as prime
                WHERE prime <= SQRT(pg.number + 1) 
                AND (pg.number + 1) % prime = 0
            ) THEN pg.primes_found || (pg.number + 1)
            ELSE pg.primes_found
        END as primes_found
    FROM prime_generation pg
    WHERE pg.number < 20  -- Limit to first 20 numbers
)
SELECT 
    number,
    primes_found,
    CASE 
        WHEN number = ANY(primes_found) THEN 'Prime'
        ELSE 'Composite'
    END as number_type
FROM prime_generation
WHERE number = ANY(primes_found)  -- Only show primes
ORDER BY number; 