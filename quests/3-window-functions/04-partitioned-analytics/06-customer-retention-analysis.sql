-- =====================================================
-- Window Functions: Customer Advanced Analytics
-- =====================================================

-- PURPOSE: Demonstrate advanced window functions for customer retention analysis
--          and value prediction using complex behavioral patterns
-- LEARNING OUTCOMES: Students will understand how to use window functions for
--                    retention analysis, churn prediction, and value forecasting
-- EXPECTED RESULTS:
-- 1. Customer retention patterns and rates
-- 2. Customer value prediction and forecasting
-- 3. Churn risk assessment and scoring
-- DIFFICULTY: 🔴 Advanced (15-30 min)
-- CONCEPTS: Retention Analysis, Value Prediction, Churn Risk Assessment,
--           NTILE(), ROW_NUMBER(), complex window functions

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS customer_transactions CASCADE;
DROP TABLE IF EXISTS customer_profiles CASCADE;

-- Create customer transactions table
CREATE TABLE customer_transactions (
    transaction_id INT PRIMARY KEY,
    customer_id INT,
    transaction_date DATE,
    amount DECIMAL(10, 2),
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
-- Example 1: Customer Retention Analysis
-- =====================================================

-- Analyze customer retention patterns
WITH customer_retention AS (
    SELECT
        ct.customer_id,
        cp.customer_name,
        cp.registration_date,
        COUNT(DISTINCT DATE_TRUNC('month', ct.transaction_date))
            AS active_months,
        EXTRACT(MONTH FROM (CURRENT_DATE - cp.registration_date))
            AS months_since_registration,
        CASE
            WHEN
                COUNT(DISTINCT DATE_TRUNC('month', ct.transaction_date))
                >= EXTRACT(MONTH FROM (CURRENT_DATE - cp.registration_date)) * 0.8 THEN 'High Retention'
            WHEN
                COUNT(DISTINCT DATE_TRUNC('month', ct.transaction_date))
                >= EXTRACT(MONTH FROM (CURRENT_DATE - cp.registration_date)) * 0.5 THEN 'Medium Retention'
            ELSE 'Low Retention'
        END AS retention_level
    FROM customer_transactions AS ct
    INNER JOIN customer_profiles AS cp ON ct.customer_id = cp.customer_id
    GROUP BY ct.customer_id, cp.customer_name, cp.registration_date
)

SELECT
    customer_id,
    customer_name,
    registration_date,
    active_months,
    months_since_registration,
    retention_level,
    ROUND(
        (active_months * 100.0 / NULLIF(months_since_registration, 0)), 2
    ) AS retention_rate,
    ROW_NUMBER()
        OVER (
            ORDER BY
                (
                    active_months * 100.0 / NULLIF(months_since_registration, 0)
                ) DESC
        )
        AS retention_rank
FROM customer_retention
ORDER BY retention_rate DESC;

-- =====================================================
-- Example 2: Customer Value Prediction
-- =====================================================

-- Predict future customer value based on current behavior
WITH customer_predictions AS (
    SELECT
        ct.customer_id,
        cp.customer_name,
        cp.customer_tier,
        COUNT(*) AS transaction_count,
        SUM(ct.amount) AS total_spent,
        AVG(ct.amount) AS avg_transaction,
        EXTRACT(DAY FROM (CURRENT_DATE - cp.registration_date))
            AS customer_age_days,
        EXTRACT(DAY FROM (CURRENT_DATE - MAX(ct.transaction_date)))
            AS days_since_last_purchase,
        -- Predicted annual value
        ROUND(
            (
                SUM(ct.amount)
                * 365.0
                / NULLIF(
                    EXTRACT(DAY FROM (CURRENT_DATE - cp.registration_date)), 0
                )
            ),
            2
        ) AS predicted_annual_value,
        -- Churn risk (higher days since last purchase = higher risk)
        NTILE(5)
            OVER (
                ORDER BY
                    EXTRACT(DAY FROM (CURRENT_DATE - MAX(ct.transaction_date)))
            )
            AS churn_risk_score
    FROM customer_transactions AS ct
    INNER JOIN customer_profiles AS cp ON ct.customer_id = cp.customer_id
    GROUP BY
        ct.customer_id, cp.customer_name, cp.customer_tier, cp.registration_date
)

SELECT
    customer_id,
    customer_name,
    customer_tier,
    transaction_count,
    total_spent,
    avg_transaction,
    customer_age_days,
    days_since_last_purchase,
    predicted_annual_value,
    churn_risk_score,
    CASE churn_risk_score
        WHEN 1 THEN 'Very Low Risk'
        WHEN 2 THEN 'Low Risk'
        WHEN 3 THEN 'Medium Risk'
        WHEN 4 THEN 'High Risk'
        WHEN 5 THEN 'Very High Risk'
    END AS churn_risk_level,
    ROW_NUMBER() OVER (ORDER BY predicted_annual_value DESC) AS value_rank
FROM customer_predictions
ORDER BY predicted_annual_value DESC;

-- Clean up
DROP TABLE IF EXISTS customer_transactions CASCADE;
DROP TABLE IF EXISTS customer_profiles CASCADE;
