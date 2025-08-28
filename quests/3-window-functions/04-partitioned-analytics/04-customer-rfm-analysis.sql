-- =====================================================
-- Window Functions: Customer Segmentation Analysis
-- =====================================================

-- PURPOSE: Demonstrate advanced window functions for customer segmentation
--          using RFM (Recency, Frequency, Monetary) analysis
-- LEARNING OUTCOMES: Students will understand how to use window functions for
--                    customer analytics, segmentation, and RFM scoring
-- EXPECTED RESULTS:
-- 1. Customer segments based on RFM analysis
-- 2. RFM scoring and ranking
-- 3. Customer lifetime value calculations
-- DIFFICULTY: 🔴 Advanced (15-30 min)
-- CONCEPTS: RFM Analysis, Customer Segmentation, NTILE(), 
--           PARTITION BY, multiple window functions

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
-- Example 1: Basic RFM Analysis
-- =====================================================

-- Calculate RFM metrics for each customer
WITH rfm_metrics AS (
    SELECT
        ct.customer_id,
        cp.customer_name,
        cp.customer_tier,
        -- Recency: Days since last purchase
        (CURRENT_DATE - MAX(ct.transaction_date)) as recency_days,
        -- Frequency: Number of transactions
        COUNT(*) as frequency,
        -- Monetary: Total amount spent
        SUM(ct.amount) as monetary_value
    FROM customer_transactions ct
    JOIN customer_profiles cp ON ct.customer_id = cp.customer_id
    GROUP BY ct.customer_id, cp.customer_name, cp.customer_tier
)
SELECT 
    customer_id,
    customer_name,
    customer_tier,
    recency_days,
    frequency,
    monetary_value,
    -- RFM Scores (1-5, where 5 is best)
    NTILE(5) OVER (ORDER BY recency_days DESC) as recency_score,
    NTILE(5) OVER (ORDER BY frequency) as frequency_score,
    NTILE(5) OVER (ORDER BY monetary_value) as monetary_score
FROM rfm_metrics
ORDER BY monetary_value DESC;

-- =====================================================
-- Example 2: Customer Segmentation
-- =====================================================

-- Create customer segments based on RFM scores
WITH rfm_scores AS (
    SELECT
        ct.customer_id,
        cp.customer_name,
        cp.customer_tier,
        (CURRENT_DATE - MAX(ct.transaction_date)) as recency_days,
        COUNT(*) as frequency,
        SUM(ct.amount) as monetary_value,
        NTILE(5) OVER (ORDER BY (CURRENT_DATE - MAX(ct.transaction_date)) DESC) as recency_score,
        NTILE(5) OVER (ORDER BY COUNT(*)) as frequency_score,
        NTILE(5) OVER (ORDER BY SUM(ct.amount)) as monetary_score
    FROM customer_transactions ct
    JOIN customer_profiles cp ON ct.customer_id = cp.customer_id
    GROUP BY ct.customer_id, cp.customer_name, cp.customer_tier
)
SELECT 
    customer_id,
    customer_name,
    customer_tier,
    recency_score,
    frequency_score,
    monetary_score,
    (recency_score + frequency_score + monetary_score) as rfm_score,
    CASE 
        WHEN (recency_score + frequency_score + monetary_score) >= 13 THEN 'Champions'
        WHEN (recency_score + frequency_score + monetary_score) >= 11 THEN 'Loyal Customers'
        WHEN (recency_score + frequency_score + monetary_score) >= 9 THEN 'At Risk'
        WHEN (recency_score + frequency_score + monetary_score) >= 7 THEN 'Can''t Lose'
        WHEN (recency_score + frequency_score + monetary_score) >= 5 THEN 'About to Sleep'
        ELSE 'Lost'
    END as customer_segment
FROM rfm_scores
ORDER BY rfm_score DESC;

-- =====================================================
-- Example 3: Customer Lifetime Value (CLV)
-- =====================================================

-- Calculate customer lifetime value with window functions
WITH customer_metrics AS (
    SELECT 
        ct.customer_id,
        cp.customer_name,
        cp.customer_tier,
        cp.registration_date,
        COUNT(*) as total_transactions,
        SUM(ct.amount) as total_spent,
        AVG(ct.amount) as avg_order_value,
        MAX(ct.transaction_date) as last_purchase_date,
        MIN(ct.transaction_date) as first_purchase_date,
        (MAX(ct.transaction_date) - MIN(ct.transaction_date)) as customer_lifetime_days
    FROM customer_transactions ct
    JOIN customer_profiles cp ON ct.customer_id = cp.customer_id
    GROUP BY ct.customer_id, cp.customer_name, cp.customer_tier, cp.registration_date
)
SELECT 
    customer_id,
    customer_name,
    customer_tier,
    total_transactions,
    total_spent,
    avg_order_value,
    customer_lifetime_days,
    -- CLV calculation: (avg_order_value * purchase_frequency * customer_lifetime)
    ROUND(
        avg_order_value * (total_transactions * 365.0 / NULLIF(customer_lifetime_days, 0)), 2
    ) as estimated_clv,
    -- Customer ranking within tier
    ROW_NUMBER() OVER (PARTITION BY customer_tier ORDER BY total_spent DESC) as tier_rank,
    -- Percentile within tier
    ROUND((PERCENT_RANK() OVER (PARTITION BY customer_tier ORDER BY total_spent))::NUMERIC, 3) as tier_percentile
FROM customer_metrics
ORDER BY total_spent DESC;

-- Clean up
DROP TABLE IF EXISTS customer_transactions CASCADE;
DROP TABLE IF EXISTS customer_profiles CASCADE; 