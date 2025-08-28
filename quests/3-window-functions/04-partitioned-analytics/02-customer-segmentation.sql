-- =====================================================
-- Window Functions: Customer Segmentation Analysis
-- =====================================================

-- PURPOSE: Demonstrate advanced customer segmentation using RFM analysis and behavioral scoring
-- LEARNING OUTCOMES:
--   - Master RFM (Recency, Frequency, Monetary) analysis
--   - Understand customer behavioral scoring
--   - Apply percentile-based segmentation
-- EXPECTED RESULTS: Complete customer segmentation with RFM scores and behavioral tiers
-- DIFFICULTY: 🔴 Advanced (15-30 min)
-- CONCEPTS: RFM Analysis, Customer Segmentation, Behavioral Scoring, Percentile Analysis

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS customer_transactions CASCADE;
DROP TABLE IF EXISTS customer_profiles CASCADE;

-- Create customer transactions table
CREATE TABLE customer_transactions (
    transaction_id INT PRIMARY KEY,
    customer_id INT,
    customer_name VARCHAR(100),
    transaction_date DATE,
    transaction_amount DECIMAL(10,2),
    product_category VARCHAR(50),
    payment_method VARCHAR(50),
    region VARCHAR(50)
);

-- Create customer profiles table
CREATE TABLE customer_profiles (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    registration_date DATE,
    customer_type VARCHAR(50),
    region VARCHAR(50),
    total_lifetime_value DECIMAL(10,2)
);

-- Insert customer profiles
INSERT INTO customer_profiles VALUES
(1, 'Alice Johnson', '2020-01-15', 'Premium', 'North', 8500.00),
(2, 'Bob Smith', '2021-03-22', 'Standard', 'South', 3200.00),
(3, 'Carol Davis', '2019-11-08', 'Premium', 'East', 12000.00),
(4, 'David Wilson', '2022-06-14', 'Standard', 'West', 1800.00),
(5, 'Eve Brown', '2020-08-30', 'Premium', 'North', 9500.00),
(6, 'Frank Miller', '2021-12-05', 'Standard', 'South', 2800.00),
(7, 'Grace Lee', '2019-05-18', 'Premium', 'East', 11000.00),
(8, 'Henry Taylor', '2022-02-28', 'Standard', 'West', 2200.00),
(9, 'Ivy Chen', '2020-10-12', 'Premium', 'North', 7800.00),
(10, 'Jack Anderson', '2021-07-25', 'Standard', 'South', 3500.00);

-- Insert comprehensive transaction data
INSERT INTO customer_transactions VALUES
-- Alice Johnson (Premium, High Value)
(1, 1, 'Alice Johnson', '2024-01-15', 450.00, 'Electronics', 'Credit Card', 'North'),
(2, 1, 'Alice Johnson', '2024-01-20', 299.99, 'Furniture', 'Credit Card', 'North'),
(3, 1, 'Alice Johnson', '2024-02-05', 150.00, 'Clothing', 'Credit Card', 'North'),
(4, 1, 'Alice Johnson', '2024-02-18', 899.99, 'Electronics', 'Credit Card', 'North'),
(5, 1, 'Alice Johnson', '2024-03-01', 199.99, 'Clothing', 'Credit Card', 'North'),

-- Bob Smith (Standard, Medium Value)
(6, 2, 'Bob Smith', '2024-01-10', 89.99, 'Electronics', 'Debit Card', 'South'),
(7, 2, 'Bob Smith', '2024-02-12', 45.00, 'Clothing', 'Debit Card', 'South'),
(8, 2, 'Bob Smith', '2024-03-15', 129.99, 'Electronics', 'Debit Card', 'South'),

-- Carol Davis (Premium, Very High Value)
(9, 3, 'Carol Davis', '2024-01-05', 1200.00, 'Electronics', 'Credit Card', 'East'),
(10, 3, 'Carol Davis', '2024-01-25', 599.99, 'Furniture', 'Credit Card', 'East'),
(11, 3, 'Carol Davis', '2024-02-10', 299.99, 'Clothing', 'Credit Card', 'East'),
(12, 3, 'Carol Davis', '2024-02-28', 899.99, 'Electronics', 'Credit Card', 'East'),
(13, 3, 'Carol Davis', '2024-03-12', 450.00, 'Furniture', 'Credit Card', 'East'),
(14, 3, 'Carol Davis', '2024-03-25', 199.99, 'Clothing', 'Credit Card', 'East'),

-- David Wilson (Standard, Low Value)
(15, 4, 'David Wilson', '2024-01-20', 25.00, 'Clothing', 'Cash', 'West'),
(16, 4, 'David Wilson', '2024-03-01', 79.99, 'Electronics', 'Debit Card', 'West'),

-- Eve Brown (Premium, High Value)
(17, 5, 'Eve Brown', '2024-01-12', 349.99, 'Furniture', 'Credit Card', 'North'),
(18, 5, 'Eve Brown', '2024-02-05', 199.99, 'Clothing', 'Credit Card', 'North'),
(19, 5, 'Eve Brown', '2024-02-20', 599.99, 'Electronics', 'Credit Card', 'North'),
(20, 5, 'Eve Brown', '2024-03-10', 299.99, 'Furniture', 'Credit Card', 'North'),

-- Frank Miller (Standard, Medium Value)
(21, 6, 'Frank Miller', '2024-01-18', 89.99, 'Electronics', 'Debit Card', 'South'),
(22, 6, 'Frank Miller', '2024-02-22', 45.00, 'Clothing', 'Debit Card', 'South'),
(23, 6, 'Frank Miller', '2024-03-18', 129.99, 'Electronics', 'Debit Card', 'South'),

-- Grace Lee (Premium, Very High Value)
(24, 7, 'Grace Lee', '2024-01-08', 899.99, 'Electronics', 'Credit Card', 'East'),
(25, 7, 'Grace Lee', '2024-01-28', 449.99, 'Furniture', 'Credit Card', 'East'),
(26, 7, 'Grace Lee', '2024-02-15', 199.99, 'Clothing', 'Credit Card', 'East'),
(27, 7, 'Grace Lee', '2024-03-05', 699.99, 'Electronics', 'Credit Card', 'East'),
(28, 7, 'Grace Lee', '2024-03-20', 349.99, 'Furniture', 'Credit Card', 'East'),

-- Henry Taylor (Standard, Low Value)
(29, 8, 'Henry Taylor', '2024-01-25', 59.99, 'Clothing', 'Cash', 'West'),
(30, 8, 'Henry Taylor', '2024-03-08', 89.99, 'Electronics', 'Debit Card', 'West'),

-- Ivy Chen (Premium, High Value)
(31, 9, 'Ivy Chen', '2024-01-15', 299.99, 'Furniture', 'Credit Card', 'North'),
(32, 9, 'Ivy Chen', '2024-02-08', 199.99, 'Clothing', 'Credit Card', 'North'),
(33, 9, 'Ivy Chen', '2024-02-25', 499.99, 'Electronics', 'Credit Card', 'North'),
(34, 9, 'Ivy Chen', '2024-03-15', 299.99, 'Furniture', 'Credit Card', 'North'),

-- Jack Anderson (Standard, Medium Value)
(35, 10, 'Jack Anderson', '2024-01-22', 129.99, 'Electronics', 'Debit Card', 'South'),
(36, 10, 'Jack Anderson', '2024-02-18', 79.99, 'Clothing', 'Debit Card', 'South'),
(37, 10, 'Jack Anderson', '2024-03-12', 199.99, 'Electronics', 'Debit Card', 'South');

-- =====================================================
-- Example 1: Basic RFM Analysis
-- =====================================================

-- Calculate RFM scores for each customer
WITH rfm_scores AS (
    SELECT
        customer_id,
        customer_name,
        -- Recency: Days since last purchase
        (CURRENT_DATE - MAX(transaction_date)) as recency_days,
        -- Frequency: Number of transactions
        COUNT(*) as frequency,
        -- Monetary: Total amount spent
        SUM(transaction_amount) as monetary,
        -- RFM Scores (1-5 scale, 5 being best)
        NTILE(5) OVER (ORDER BY (CURRENT_DATE - MAX(transaction_date)) DESC) as recency_score,
        NTILE(5) OVER (ORDER BY COUNT(*)) as frequency_score,
        NTILE(5) OVER (ORDER BY SUM(transaction_amount)) as monetary_score
    FROM customer_transactions
    GROUP BY customer_id, customer_name
)
SELECT
    customer_id,
    customer_name,
    recency_days,
    frequency,
    monetary,
    recency_score,
    frequency_score,
    monetary_score,
    (recency_score + frequency_score + monetary_score) as rfm_score,
    CASE
        WHEN (recency_score + frequency_score + monetary_score) >= 13 THEN 'Champions'
        WHEN (recency_score + frequency_score + monetary_score) >= 11 THEN 'Loyal Customers'
        WHEN (recency_score + frequency_score + monetary_score) >= 9 THEN 'At Risk'
        WHEN (recency_score + frequency_score + monetary_score) >= 7 THEN 'Can''t Lose'
        ELSE 'Lost'
    END as customer_segment
FROM rfm_scores
ORDER BY rfm_score DESC;

-- =====================================================
-- Example 2: Advanced RFM Segmentation
-- =====================================================

-- Create detailed RFM segments with percentile analysis
WITH customer_metrics AS (
    SELECT
        customer_id,
        customer_name,
        (CURRENT_DATE - MAX(transaction_date)) as recency_days,
        COUNT(*) as frequency,
        SUM(transaction_amount) as monetary,
        AVG(transaction_amount) as avg_transaction_value,
        COUNT(DISTINCT DATE_TRUNC('month', transaction_date)) as active_months
    FROM customer_transactions
    GROUP BY customer_id, customer_name
),
rfm_percentiles AS (
    SELECT
        *,
        ROUND((PERCENT_RANK() OVER (ORDER BY recency_days DESC) * 100)::numeric, 2) as recency_percentile,
        ROUND((PERCENT_RANK() OVER (ORDER BY frequency) * 100)::numeric, 2) as frequency_percentile,
        ROUND((PERCENT_RANK() OVER (ORDER BY monetary) * 100)::numeric, 2) as monetary_percentile,
        ROUND((PERCENT_RANK() OVER (ORDER BY avg_transaction_value) * 100)::numeric, 2) as avg_value_percentile
    FROM customer_metrics
)
SELECT 
    customer_id,
    customer_name,
    recency_days,
    frequency,
    monetary,
    avg_transaction_value,
    active_months,
    ROUND(recency_percentile * 100, 1) as recency_percentile,
    ROUND(frequency_percentile * 100, 1) as frequency_percentile,
    ROUND(monetary_percentile * 100, 1) as monetary_percentile,
    ROUND(avg_value_percentile * 100, 1) as avg_value_percentile,
    CASE 
        WHEN recency_percentile >= 0.8 AND frequency_percentile >= 0.8 AND monetary_percentile >= 0.8 THEN 'VIP Customers'
        WHEN recency_percentile >= 0.6 AND frequency_percentile >= 0.6 AND monetary_percentile >= 0.6 THEN 'High Value'
        WHEN recency_percentile >= 0.4 AND frequency_percentile >= 0.4 AND monetary_percentile >= 0.4 THEN 'Medium Value'
        WHEN recency_percentile >= 0.2 AND frequency_percentile >= 0.2 AND monetary_percentile >= 0.2 THEN 'Low Value'
        ELSE 'At Risk'
    END as detailed_segment
FROM rfm_percentiles
ORDER BY monetary_percentile DESC;

-- =====================================================
-- Example 3: Behavioral Scoring
-- =====================================================

-- Create behavioral scoring based on multiple factors
WITH behavioral_metrics AS (
    SELECT 
        ct.customer_id,
        ct.customer_name,
        cp.customer_type,
        cp.total_lifetime_value,
        COUNT(*) as transaction_count,
        SUM(ct.transaction_amount) as total_spent,
        AVG(ct.transaction_amount) as avg_transaction,
        COUNT(DISTINCT ct.product_category) as categories_purchased,
        COUNT(DISTINCT ct.payment_method) as payment_methods_used,
        (MAX(ct.transaction_date) - MIN(ct.transaction_date)) as customer_tenure_days,
        (CURRENT_DATE - MAX(ct.transaction_date)) as days_since_last_purchase
    FROM customer_transactions ct
    JOIN customer_profiles cp ON ct.customer_id = cp.customer_id
    GROUP BY ct.customer_id, ct.customer_name, cp.customer_type, cp.total_lifetime_value
),
behavioral_scores AS (
    SELECT 
        *,
        -- Transaction frequency score
        NTILE(5) OVER (ORDER BY transaction_count) as frequency_score,
        -- Average transaction value score
        NTILE(5) OVER (ORDER BY avg_transaction) as value_score,
        -- Category diversity score
        NTILE(5) OVER (ORDER BY categories_purchased) as diversity_score,
        -- Recency score (inverse of days since last purchase)
        NTILE(5) OVER (ORDER BY days_since_last_purchase DESC) as recency_score,
        -- Payment method score
        NTILE(5) OVER (ORDER BY payment_methods_used) as payment_score
    FROM behavioral_metrics
)
SELECT 
    customer_id,
    customer_name,
    customer_type,
    transaction_count,
    total_spent,
    avg_transaction,
    categories_purchased,
    customer_tenure_days,
    days_since_last_purchase,
    frequency_score,
    value_score,
    diversity_score,
    recency_score,
    payment_score,
    (frequency_score + value_score + diversity_score + recency_score + payment_score) as total_behavioral_score,
    NTILE(4) OVER (ORDER BY (frequency_score + value_score + diversity_score + recency_score + payment_score)) as behavioral_tier,
    CASE 
        WHEN (frequency_score + value_score + diversity_score + recency_score + payment_score) >= 20 THEN 'Elite'
        WHEN (frequency_score + value_score + diversity_score + recency_score + payment_score) >= 15 THEN 'Premium'
        WHEN (frequency_score + value_score + diversity_score + recency_score + payment_score) >= 10 THEN 'Standard'
        ELSE 'Basic'
    END as behavioral_segment
FROM behavioral_scores
ORDER BY total_behavioral_score DESC;

-- =====================================================
-- Example 4: Customer Lifetime Value Analysis
-- =====================================================

-- Analyze customer lifetime value with predictive scoring
WITH customer_lifetime_metrics AS (
    SELECT 
        ct.customer_id,
        ct.customer_name,
        cp.registration_date,
        cp.total_lifetime_value,
        COUNT(*) as total_transactions,
        SUM(ct.transaction_amount) as total_spent_current_period,
        AVG(ct.transaction_amount) as avg_transaction_value,
        COUNT(DISTINCT DATE_TRUNC('month', ct.transaction_date)) as active_months,
        (CURRENT_DATE - cp.registration_date) as customer_age_days,
        (CURRENT_DATE - MAX(ct.transaction_date)) as days_since_last_purchase
    FROM customer_transactions ct
    JOIN customer_profiles cp ON ct.customer_id = cp.customer_id
    GROUP BY ct.customer_id, ct.customer_name, cp.registration_date, cp.total_lifetime_value
),
clv_analysis AS (
    SELECT
        *,
        -- Monthly average revenue
        total_spent_current_period / NULLIF(active_months, 0) as monthly_avg_revenue,
        -- Customer retention rate (months active / total possible months)
        active_months * 100.0 / NULLIF(EXTRACT(MONTH FROM AGE(CURRENT_DATE, registration_date)), 0) as retention_rate,
        -- Predicted CLV (monthly revenue * retention rate * 12 months)
        (total_spent_current_period / NULLIF(active_months, 0)) *
        (active_months * 100.0 / NULLIF(EXTRACT(MONTH FROM AGE(CURRENT_DATE, registration_date)), 0)) * 12 / 100 as predicted_clv
    FROM customer_lifetime_metrics
)
SELECT 
    customer_id,
    customer_name,
    registration_date,
    total_lifetime_value,
    total_transactions,
    total_spent_current_period,
    avg_transaction_value,
    active_months,
    ROUND(monthly_avg_revenue, 2) as monthly_avg_revenue,
    ROUND(retention_rate, 1) as retention_rate_percent,
    ROUND(predicted_clv, 2) as predicted_clv,
    ROUND(predicted_clv * 100.0 / total_lifetime_value, 1) as clv_accuracy_percent,
    NTILE(5) OVER (ORDER BY predicted_clv) as clv_quintile,
    CASE 
        WHEN predicted_clv >= 10000 THEN 'Ultra High Value'
        WHEN predicted_clv >= 5000 THEN 'High Value'
        WHEN predicted_clv >= 2000 THEN 'Medium Value'
        WHEN predicted_clv >= 500 THEN 'Low Value'
        ELSE 'Minimal Value'
    END as clv_segment
FROM clv_analysis
ORDER BY predicted_clv DESC;

-- =====================================================
-- Example 5: Regional Customer Analysis
-- =====================================================

-- Analyze customer behavior by region
WITH regional_metrics AS (
    SELECT 
        ct.region,
        COUNT(DISTINCT ct.customer_id) as unique_customers,
        COUNT(*) as total_transactions,
        SUM(ct.transaction_amount) as total_revenue,
        AVG(ct.transaction_amount) as avg_transaction_value,
        COUNT(*) * 100.0 / COUNT(DISTINCT ct.customer_id) as transactions_per_customer,
        SUM(ct.transaction_amount) * 100.0 / COUNT(DISTINCT ct.customer_id) as revenue_per_customer
    FROM customer_transactions ct
    GROUP BY ct.region
)
SELECT 
    region,
    unique_customers,
    total_transactions,
    total_revenue,
    ROUND(avg_transaction_value, 2) as avg_transaction_value,
    ROUND(transactions_per_customer, 1) as transactions_per_customer,
    ROUND(revenue_per_customer, 2) as revenue_per_customer,
    ROUND(unique_customers * 100.0 / SUM(unique_customers) OVER (), 1) as customer_share_percent,
    ROUND(total_revenue * 100.0 / SUM(total_revenue) OVER (), 1) as revenue_share_percent,
    RANK() OVER (ORDER BY total_revenue DESC) as revenue_rank,
    RANK() OVER (ORDER BY avg_transaction_value DESC) as avg_value_rank,
    RANK() OVER (ORDER BY revenue_per_customer DESC) as customer_value_rank
FROM regional_metrics
ORDER BY total_revenue DESC;

-- =====================================================
-- Example 6: Product Category Preference Analysis
-- =====================================================

-- Analyze customer preferences by product category
WITH category_preferences AS (
    SELECT 
        ct.customer_id,
        ct.customer_name,
        ct.product_category,
        COUNT(*) as category_transactions,
        SUM(ct.transaction_amount) as category_spent,
        AVG(ct.transaction_amount) as avg_category_value,
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY ct.customer_id) as category_percentage
    FROM customer_transactions ct
    GROUP BY ct.customer_id, ct.customer_name, ct.product_category
),
category_rankings AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY category_spent DESC) as category_rank,
        RANK() OVER (PARTITION BY customer_id ORDER BY category_spent DESC) as category_rank_with_ties,
        NTILE(3) OVER (PARTITION BY customer_id ORDER BY category_spent DESC) as category_tier
    FROM category_preferences
)
SELECT 
    customer_id,
    customer_name,
    product_category,
    category_transactions,
    category_spent,
    ROUND(avg_category_value, 2) as avg_category_value,
    ROUND(category_percentage, 1) as category_percentage,
    category_rank,
    category_rank_with_ties,
    category_tier,
    CASE 
        WHEN category_rank = 1 THEN 'Primary Category'
        WHEN category_rank = 2 THEN 'Secondary Category'
        ELSE 'Tertiary Category'
    END as category_importance
FROM category_rankings
ORDER BY customer_id, category_rank;

-- Clean up
DROP TABLE IF EXISTS customer_transactions CASCADE;
DROP TABLE IF EXISTS customer_profiles CASCADE; 