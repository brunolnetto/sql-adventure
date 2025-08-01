-- =====================================================
-- Window Functions: Customer Behavioral Scoring
-- =====================================================

-- PURPOSE: Demonstrate advanced window functions for customer behavioral analysis
--          and scoring using multiple behavioral factors
-- LEARNING OUTCOMES: Students will understand how to use window functions for
--                    behavioral scoring, segment performance analysis, and
--                    customer cohort analysis
-- EXPECTED RESULTS:
-- 1. Behavioral scoring based on multiple factors
-- 2. Segment performance analysis and metrics
-- 3. Customer cohort analysis by registration month
-- DIFFICULTY: 🔴 Advanced (15-30 min)
-- CONCEPTS: Behavioral Scoring, Segment Analysis, Cohort Analysis,
--           NTILE(), PERCENT_RANK(), multiple window functions

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS customer_transactions CASCADE;
DROP TABLE IF EXISTS customer_profiles CASCADE;

-- Create customer transactions table
CREATE TABLE customer_transactions (
    transaction_id INT PRIMARY KEY,
    customer_id INT,
    transaction_date DATE,
    amount DECIMAL(10,2),
    product_category VARCHAR(50),
    payment_method VARCHAR(20)
);

-- Create customer profiles table
CREATE TABLE customer_profiles (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    registration_date DATE,
    customer_tier VARCHAR(20),
    region VARCHAR(50)
);

-- Insert sample customer profiles
INSERT INTO customer_profiles VALUES
(1, 'Alice Johnson', 'alice@email.com', '2020-01-15', 'Gold', 'North'),
(2, 'Bob Smith', 'bob@email.com', '2019-03-20', 'Silver', 'South'),
(3, 'Carol Davis', 'carol@email.com', '2021-07-10', 'Bronze', 'East'),
(4, 'David Wilson', 'david@email.com', '2022-02-28', 'Gold', 'West'),
(5, 'Eve Brown', 'eve@email.com', '2020-11-05', 'Silver', 'North'),
(6, 'Frank Miller', 'frank@email.com', '2023-01-10', 'Bronze', 'South'),
(7, 'Grace Lee', 'grace@email.com', '2019-09-15', 'Gold', 'East'),
(8, 'Henry Taylor', 'henry@email.com', '2021-12-01', 'Silver', 'West'),
(9, 'Ivy Chen', 'ivy@email.com', '2022-06-20', 'Bronze', 'North'),
(10, 'Jack Anderson', 'jack@email.com', '2020-08-12', 'Gold', 'South');

-- Insert sample transaction data
INSERT INTO customer_transactions VALUES
-- High-value customer (Alice - Gold)
(1, 1, '2024-01-15', 1200.00, 'Electronics', 'Credit Card'),
(2, 1, '2024-01-20', 850.00, 'Clothing', 'Credit Card'),
(3, 1, '2024-02-05', 650.00, 'Home & Garden', 'Credit Card'),
(4, 1, '2024-02-15', 950.00, 'Electronics', 'Credit Card'),

-- Frequent customer (Bob - Silver)
(5, 2, '2024-01-10', 150.00, 'Clothing', 'Debit Card'),
(6, 2, '2024-01-25', 200.00, 'Electronics', 'Debit Card'),
(7, 2, '2024-02-10', 180.00, 'Clothing', 'Debit Card'),
(8, 2, '2024-02-20', 120.00, 'Home & Garden', 'Debit Card'),
(9, 2, '2024-03-05', 160.00, 'Electronics', 'Debit Card'),
(10, 2, '2024-03-15', 140.00, 'Clothing', 'Debit Card'),

-- Recent customer (Carol - Bronze)
(11, 3, '2024-03-01', 300.00, 'Electronics', 'PayPal'),
(12, 3, '2024-03-10', 250.00, 'Clothing', 'PayPal'),
(13, 3, '2024-03-20', 400.00, 'Electronics', 'PayPal'),

-- High-value, frequent (David - Gold)
(14, 4, '2024-01-05', 800.00, 'Electronics', 'Credit Card'),
(15, 4, '2024-01-25', 1200.00, 'Electronics', 'Credit Card'),
(16, 4, '2024-02-10', 950.00, 'Clothing', 'Credit Card'),
(17, 4, '2024-02-25', 1100.00, 'Electronics', 'Credit Card'),
(18, 4, '2024-03-10', 750.00, 'Home & Garden', 'Credit Card'),

-- Moderate customer (Eve - Silver)
(19, 5, '2024-01-15', 300.00, 'Clothing', 'Debit Card'),
(20, 5, '2024-02-05', 450.00, 'Electronics', 'Debit Card'),
(21, 5, '2024-03-01', 350.00, 'Clothing', 'Debit Card'),

-- New customer (Frank - Bronze)
(22, 6, '2024-03-15', 200.00, 'Electronics', 'PayPal'),
(23, 6, '2024-03-25', 150.00, 'Clothing', 'PayPal'),

-- Loyal customer (Grace - Gold)
(24, 7, '2024-01-01', 600.00, 'Electronics', 'Credit Card'),
(25, 7, '2024-01-20', 800.00, 'Clothing', 'Credit Card'),
(26, 7, '2024-02-10', 700.00, 'Home & Garden', 'Credit Card'),
(27, 7, '2024-02-25', 900.00, 'Electronics', 'Credit Card'),
(28, 7, '2024-03-10', 650.00, 'Clothing', 'Credit Card'),

-- Regular customer (Henry - Silver)
(29, 8, '2024-01-10', 250.00, 'Clothing', 'Debit Card'),
(30, 8, '2024-02-05', 300.00, 'Electronics', 'Debit Card'),
(31, 8, '2024-03-01', 280.00, 'Clothing', 'Debit Card'),

-- Occasional customer (Ivy - Bronze)
(32, 9, '2024-02-15', 180.00, 'Clothing', 'PayPal'),
(33, 9, '2024-03-20', 220.00, 'Electronics', 'PayPal'),

-- Premium customer (Jack - Gold)
(34, 10, '2024-01-05', 1500.00, 'Electronics', 'Credit Card'),
(35, 10, '2024-01-25', 1200.00, 'Electronics', 'Credit Card'),
(36, 10, '2024-02-10', 1800.00, 'Electronics', 'Credit Card'),
(37, 10, '2024-02-25', 1100.00, 'Clothing', 'Credit Card'),
(38, 10, '2024-03-10', 1400.00, 'Electronics', 'Credit Card');

-- =====================================================
-- Example 1: Behavioral Scoring
-- =====================================================

-- Create behavioral scores based on multiple factors
WITH behavioral_metrics AS (
    SELECT 
        ct.customer_id,
        cp.customer_name,
        cp.customer_tier,
        -- Purchase behavior
        COUNT(*) as transaction_count,
        SUM(ct.amount) as total_spent,
        AVG(ct.amount) as avg_transaction,
        -- Category diversity
        COUNT(DISTINCT ct.product_category) as category_count,
        -- Payment method preference
        MODE() WITHIN GROUP (ORDER BY ct.payment_method) as preferred_payment,
        -- Recency
        EXTRACT(DAY FROM (CURRENT_DATE - MAX(ct.transaction_date))) as days_since_last_purchase
    FROM customer_transactions ct
    JOIN customer_profiles cp ON ct.customer_id = cp.customer_id
    GROUP BY ct.customer_id, cp.customer_name, cp.customer_tier
)
SELECT 
    customer_id,
    customer_name,
    customer_tier,
    transaction_count,
    total_spent,
    avg_transaction,
    category_count,
    preferred_payment,
    days_since_last_purchase,
    -- Behavioral score components
    NTILE(5) OVER (ORDER BY transaction_count) as frequency_score,
    NTILE(5) OVER (ORDER BY total_spent) as value_score,
    NTILE(5) OVER (ORDER BY category_count) as diversity_score,
    NTILE(5) OVER (ORDER BY days_since_last_purchase DESC) as recency_score,
    -- Composite behavioral score
    (NTILE(5) OVER (ORDER BY transaction_count) * 0.3 +
     NTILE(5) OVER (ORDER BY total_spent) * 0.4 +
     NTILE(5) OVER (ORDER BY category_count) * 0.2 +
     NTILE(5) OVER (ORDER BY days_since_last_purchase DESC) * 0.1) as behavioral_score
FROM behavioral_metrics
ORDER BY behavioral_score DESC;

-- =====================================================
-- Example 2: Segment Performance Analysis
-- =====================================================

-- Analyze performance by customer segments
WITH customer_segments AS (
    SELECT 
        ct.customer_id,
        cp.customer_name,
        cp.customer_tier,
        COUNT(*) as transaction_count,
        SUM(ct.amount) as total_spent,
        AVG(ct.amount) as avg_transaction,
        NTILE(5) OVER (ORDER BY EXTRACT(DAY FROM (CURRENT_DATE - MAX(ct.transaction_date))) DESC) as recency_score,
        NTILE(5) OVER (ORDER BY COUNT(*)) as frequency_score,
        NTILE(5) OVER (ORDER BY SUM(ct.amount)) as monetary_score,
        CASE 
            WHEN (NTILE(5) OVER (ORDER BY EXTRACT(DAY FROM (CURRENT_DATE - MAX(ct.transaction_date))) DESC) +
                  NTILE(5) OVER (ORDER BY COUNT(*)) +
                  NTILE(5) OVER (ORDER BY SUM(ct.amount))) >= 13 THEN 'Champions'
            WHEN (NTILE(5) OVER (ORDER BY EXTRACT(DAY FROM (CURRENT_DATE - MAX(ct.transaction_date))) DESC) +
                  NTILE(5) OVER (ORDER BY COUNT(*)) +
                  NTILE(5) OVER (ORDER BY SUM(ct.amount))) >= 11 THEN 'Loyal Customers'
            WHEN (NTILE(5) OVER (ORDER BY EXTRACT(DAY FROM (CURRENT_DATE - MAX(ct.transaction_date))) DESC) +
                  NTILE(5) OVER (ORDER BY COUNT(*)) +
                  NTILE(5) OVER (ORDER BY SUM(ct.amount))) >= 9 THEN 'At Risk'
            WHEN (NTILE(5) OVER (ORDER BY EXTRACT(DAY FROM (CURRENT_DATE - MAX(ct.transaction_date))) DESC) +
                  NTILE(5) OVER (ORDER BY COUNT(*)) +
                  NTILE(5) OVER (ORDER BY SUM(ct.amount))) >= 7 THEN 'Can\'t Lose'
            WHEN (NTILE(5) OVER (ORDER BY EXTRACT(DAY FROM (CURRENT_DATE - MAX(ct.transaction_date))) DESC) +
                  NTILE(5) OVER (ORDER BY COUNT(*)) +
                  NTILE(5) OVER (ORDER BY SUM(ct.amount))) >= 5 THEN 'About to Sleep'
            ELSE 'Lost'
        END as customer_segment
    FROM customer_transactions ct
    JOIN customer_profiles cp ON ct.customer_id = cp.customer_id
    GROUP BY ct.customer_id, cp.customer_name, cp.customer_tier
)
SELECT 
    customer_segment,
    COUNT(*) as customer_count,
    ROUND(AVG(transaction_count), 2) as avg_transactions,
    ROUND(AVG(total_spent), 2) as avg_total_spent,
    ROUND(AVG(avg_transaction), 2) as avg_transaction_value,
    ROUND(SUM(total_spent), 2) as segment_total_value,
    ROUND(
        SUM(total_spent) * 100.0 / SUM(SUM(total_spent)) OVER (), 2
    ) as segment_contribution_pct,
    ROUND(
        PERCENT_RANK() OVER (ORDER BY AVG(total_spent)) * 100, 1
    ) as segment_percentile
FROM customer_segments
GROUP BY customer_segment
ORDER BY avg_total_spent DESC;

-- =====================================================
-- Example 3: Customer Cohort Analysis
-- =====================================================

-- Analyze customer cohorts by registration month
WITH customer_cohorts AS (
    SELECT 
        ct.customer_id,
        cp.customer_name,
        cp.registration_date,
        DATE_TRUNC('month', cp.registration_date) as cohort_month,
        DATE_TRUNC('month', ct.transaction_date) as transaction_month,
        SUM(ct.amount) as monthly_spent
    FROM customer_transactions ct
    JOIN customer_profiles cp ON ct.customer_id = cp.customer_id
    GROUP BY ct.customer_id, cp.customer_name, cp.registration_date, DATE_TRUNC('month', ct.transaction_date)
)
SELECT 
    cohort_month,
    COUNT(DISTINCT customer_id) as cohort_size,
    ROUND(AVG(monthly_spent), 2) as avg_monthly_spent,
    ROUND(SUM(monthly_spent), 2) as total_cohort_value,
    ROW_NUMBER() OVER (ORDER BY SUM(monthly_spent) DESC) as cohort_rank,
    ROUND(
        PERCENT_RANK() OVER (ORDER BY SUM(monthly_spent)) * 100, 1
    ) as cohort_percentile
FROM customer_cohorts
GROUP BY cohort_month
ORDER BY cohort_month;

-- Clean up
DROP TABLE IF EXISTS customer_transactions CASCADE;
DROP TABLE IF EXISTS customer_profiles CASCADE; 