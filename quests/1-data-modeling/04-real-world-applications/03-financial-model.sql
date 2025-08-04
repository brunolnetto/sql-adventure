-- Data Modeling Quest: Financial Data Model
-- PURPOSE: Demonstrate financial data modeling for banking and transaction systems
-- DIFFICULTY: 🔴 Advanced (20-25 min)
-- CONCEPTS: Financial modeling, banking systems, transaction processing, risk management

-- Example 1: Core Banking Entities
-- Demonstrate core banking data model

-- Customers and Accounts
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_number VARCHAR(20) UNIQUE NOT NULL,
    ssn_hash VARCHAR(64) UNIQUE NOT NULL, -- Hashed SSN for security
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address_line1 VARCHAR(200) NOT NULL,
    address_line2 VARCHAR(200),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(50) DEFAULT 'USA',
    employment_status VARCHAR(50),
    annual_income DECIMAL(12,2),
    credit_score INT CHECK (credit_score >= 300 AND credit_score <= 850),
    risk_level VARCHAR(20) DEFAULT 'medium' CHECK (risk_level IN ('low', 'medium', 'high')),
    kyc_status VARCHAR(20) DEFAULT 'pending' CHECK (kyc_status IN ('pending', 'verified', 'rejected')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE account_types (
    account_type_id INT PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL,
    type_code VARCHAR(10) UNIQUE NOT NULL,
    description TEXT,
    minimum_balance DECIMAL(10,2) DEFAULT 0,
    monthly_fee DECIMAL(8,2) DEFAULT 0,
    interest_rate DECIMAL(5,4) DEFAULT 0,
    overdraft_limit DECIMAL(10,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE accounts (
    account_id INT PRIMARY KEY,
    account_number VARCHAR(20) UNIQUE NOT NULL,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    account_type_id INT NOT NULL REFERENCES account_types(account_type_id),
    account_status VARCHAR(20) DEFAULT 'active' CHECK (account_status IN ('active', 'suspended', 'closed', 'frozen')),
    current_balance DECIMAL(12,2) DEFAULT 0,
    available_balance DECIMAL(12,2) DEFAULT 0,
    hold_amount DECIMAL(12,2) DEFAULT 0,
    interest_earned DECIMAL(12,2) DEFAULT 0,
    last_activity_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    opened_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Transactions and Payments
CREATE TABLE transaction_types (
    transaction_type_id INT PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL,
    type_code VARCHAR(10) UNIQUE NOT NULL,
    description TEXT,
    is_debit BOOLEAN NOT NULL, -- true for debits, false for credits
    is_fee BOOLEAN DEFAULT false,
    is_reversible BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    transaction_number VARCHAR(30) UNIQUE NOT NULL,
    account_id INT NOT NULL REFERENCES accounts(account_id),
    transaction_type_id INT NOT NULL REFERENCES transaction_types(transaction_type_id),
    amount DECIMAL(12,2) NOT NULL,
    description TEXT,
    reference_number VARCHAR(50),
    merchant_name VARCHAR(100),
    merchant_category VARCHAR(50),
    transaction_date TIMESTAMP NOT NULL,
    posted_date TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'posted', 'failed', 'reversed', 'disputed')),
    balance_after DECIMAL(12,2),
    fee_amount DECIMAL(8,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE transfers (
    transfer_id INT PRIMARY KEY,
    from_account_id INT NOT NULL REFERENCES accounts(account_id),
    to_account_id INT NOT NULL REFERENCES accounts(account_id),
    amount DECIMAL(12,2) NOT NULL,
    description TEXT,
    transfer_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
    fee_amount DECIMAL(8,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Loans and Credit
CREATE TABLE loan_types (
    loan_type_id INT PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL,
    type_code VARCHAR(10) UNIQUE NOT NULL,
    description TEXT,
    min_amount DECIMAL(12,2),
    max_amount DECIMAL(12,2),
    min_term_months INT,
    max_term_months INT,
    base_interest_rate DECIMAL(5,4),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE loans (
    loan_id INT PRIMARY KEY,
    loan_number VARCHAR(20) UNIQUE NOT NULL,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    loan_type_id INT NOT NULL REFERENCES loan_types(loan_type_id),
    principal_amount DECIMAL(12,2) NOT NULL,
    interest_rate DECIMAL(5,4) NOT NULL,
    term_months INT NOT NULL,
    monthly_payment DECIMAL(10,2) NOT NULL,
    remaining_balance DECIMAL(12,2) NOT NULL,
    next_payment_date DATE,
    loan_status VARCHAR(20) DEFAULT 'active' CHECK (loan_status IN ('active', 'paid_off', 'defaulted', 'charged_off')),
    disbursement_date DATE,
    maturity_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE loan_payments (
    payment_id INT PRIMARY KEY,
    loan_id INT NOT NULL REFERENCES loans(loan_id),
    payment_date DATE NOT NULL,
    payment_amount DECIMAL(10,2) NOT NULL,
    principal_paid DECIMAL(10,2) NOT NULL,
    interest_paid DECIMAL(10,2) NOT NULL,
    remaining_balance DECIMAL(12,2) NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'scheduled' CHECK (payment_status IN ('scheduled', 'paid', 'late', 'missed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO customers VALUES
(1, 'CUST001', 'hashed_ssn_123', 'John', 'Smith', '1980-05-15', 'john.smith@email.com', '555-1234', '123 Main St', NULL, 'New York', 'NY', '10001', 'USA', 'Employed', 75000.00, 720, 'low', 'verified', true),
(2, 'CUST002', 'hashed_ssn_456', 'Sarah', 'Johnson', '1992-08-22', 'sarah.johnson@email.com', '555-5678', '456 Oak Ave', 'Apt 2B', 'Los Angeles', 'CA', '90210', 'USA', 'Self-employed', 95000.00, 780, 'low', 'verified', true),
(3, 'CUST003', 'hashed_ssn_789', 'Michael', 'Brown', '1975-03-10', 'michael.brown@email.com', '555-9012', '789 Pine St', NULL, 'Chicago', 'IL', '60601', 'USA', 'Unemployed', 25000.00, 580, 'high', 'pending', true);

INSERT INTO account_types VALUES
(1, 'Checking Account', 'CHK', 'Basic checking account with no minimum balance', 0.00, 0.00, 0.0001, 500.00, true),
(2, 'Savings Account', 'SAV', 'Interest-bearing savings account', 100.00, 0.00, 0.0250, 0.00, true),
(3, 'Premium Checking', 'PREM', 'Premium checking with higher limits', 2500.00, 0.00, 0.0050, 1000.00, true),
(4, 'Money Market', 'MM', 'High-yield money market account', 10000.00, 0.00, 0.0350, 0.00, true);

INSERT INTO accounts VALUES
(1, 'ACC001', 1, 1, 'active', 2500.00, 2500.00, 0.00, 0.25, '2024-01-15 10:30:00', '2023-01-15', NULL),
(2, 'ACC002', 1, 2, 'active', 15000.00, 15000.00, 0.00, 375.00, '2024-01-15 10:30:00', '2023-01-15', NULL),
(3, 'ACC003', 2, 3, 'active', 5000.00, 5000.00, 0.00, 25.00, '2024-01-16 14:15:00', '2023-02-01', NULL),
(4, 'ACC004', 3, 1, 'active', 500.00, 500.00, 0.00, 0.05, '2024-01-17 09:45:00', '2023-03-01', NULL);

INSERT INTO transaction_types VALUES
(1, 'Deposit', 'DEP', 'Cash or check deposit', false, false, true),
(2, 'Withdrawal', 'WTH', 'Cash withdrawal', true, false, true),
(3, 'Purchase', 'PUR', 'Point of sale purchase', true, false, true),
(4, 'Transfer In', 'TIN', 'Incoming transfer', false, false, true),
(5, 'Transfer Out', 'TOUT', 'Outgoing transfer', true, false, true),
(6, 'Monthly Fee', 'FEE', 'Monthly account fee', true, true, false),
(7, 'Interest Credit', 'INT', 'Interest earned', false, false, false);

INSERT INTO transactions VALUES
(1, 'TXN001', 1, 1, 1000.00, 'Initial deposit', 'REF001', NULL, NULL, '2024-01-15 10:30:00', '2024-01-15 10:30:00', 'posted', 1000.00, 0.00),
(2, 'TXN002', 1, 3, 50.00, 'Grocery store purchase', 'REF002', 'Walmart', 'Groceries', '2024-01-15 14:20:00', '2024-01-15 14:20:00', 'posted', 950.00, 0.00),
(3, 'TXN003', 2, 1, 5000.00, 'Salary deposit', 'REF003', 'ABC Corp', 'Salary', '2024-01-16 09:00:00', '2024-01-16 09:00:00', 'posted', 5000.00, 0.00),
(4, 'TXN004', 3, 1, 10000.00, 'Investment transfer', 'REF004', 'Investment Co', 'Investment', '2024-01-16 14:15:00', '2024-01-16 14:15:00', 'posted', 10000.00, 0.00),
(5, 'TXN005', 4, 3, 25.00, 'Gas station purchase', 'REF005', 'Shell', 'Gas', '2024-01-17 09:45:00', '2024-01-17 09:45:00', 'posted', 475.00, 0.00);

INSERT INTO transfers VALUES
(1, 1, 2, 500.00, 'Transfer to savings', '2024-01-15 16:00:00', 'completed', 0.00),
(2, 3, 4, 1000.00, 'Transfer to checking', '2024-01-16 15:00:00', 'completed', 0.00);

INSERT INTO loan_types VALUES
(1, 'Personal Loan', 'PERS', 'Unsecured personal loan', 1000.00, 50000.00, 12, 60, 0.0850, true),
(2, 'Auto Loan', 'AUTO', 'Secured auto loan', 5000.00, 100000.00, 24, 84, 0.0650, true),
(3, 'Home Loan', 'HOME', 'Secured home loan', 50000.00, 1000000.00, 120, 360, 0.0450, true);

INSERT INTO loans VALUES
(1, 'LOAN001', 1, 1, 10000.00, 0.0850, 36, 315.00, 9500.00, '2024-02-15', 'active', '2023-11-15', '2026-11-15'),
(2, 'LOAN002', 2, 2, 25000.00, 0.0650, 60, 485.00, 24000.00, '2024-02-01', 'active', '2023-08-01', '2028-08-01');

INSERT INTO loan_payments VALUES
(1, 1, '2024-01-15', 315.00, 250.00, 65.00, 9500.00, 'paid'),
(2, 2, '2024-01-01', 485.00, 300.00, 185.00, 24000.00, 'paid');

-- Example 2: Financial Analytics and Reporting
-- Demonstrate comprehensive financial analytics

-- Customer financial health analysis
SELECT 
    c.first_name || ' ' || c.last_name as customer_name,
    c.credit_score,
    c.risk_level,
    COUNT(a.account_id) as total_accounts,
    SUM(a.current_balance) as total_balance,
    ROUND(AVG(a.current_balance), 2) as avg_account_balance,
    SUM(a.interest_earned) as total_interest_earned,
    COUNT(l.loan_id) as active_loans,
    COALESCE(SUM(l.remaining_balance), 0) as total_loan_balance,
    CASE 
        WHEN SUM(a.current_balance) > 100000 THEN 'High Net Worth'
        WHEN SUM(a.current_balance) > 50000 THEN 'Affluent'
        WHEN SUM(a.current_balance) > 10000 THEN 'Middle Class'
        ELSE 'Basic'
    END as customer_segment
FROM customers c
LEFT JOIN accounts a ON c.customer_id = a.customer_id AND a.account_status = 'active'
LEFT JOIN loans l ON c.customer_id = l.customer_id AND l.loan_status = 'active'
WHERE c.is_active = true
GROUP BY c.customer_id, c.first_name, c.last_name, c.credit_score, c.risk_level
ORDER BY total_balance DESC;

-- Transaction analysis by category
SELECT 
    merchant_category,
    COUNT(*) as transaction_count,
    SUM(amount) as total_amount,
    ROUND(AVG(amount), 2) as avg_amount,
    ROUND(SUM(amount) * 100.0 / SUM(SUM(amount)) OVER (), 2) as percentage_of_total,
    COUNT(DISTINCT account_id) as unique_accounts
FROM transactions
WHERE status = 'posted'
AND merchant_category IS NOT NULL
GROUP BY merchant_category
ORDER BY total_amount DESC;

-- Account performance analysis
SELECT 
    at.type_name,
    COUNT(a.account_id) as account_count,
    SUM(a.current_balance) as total_balance,
    ROUND(AVG(a.current_balance), 2) as avg_balance,
    ROUND(SUM(a.interest_earned), 2) as total_interest_paid,
    ROUND(AVG(at.interest_rate * 100), 2) as avg_interest_rate,
    ROUND(SUM(a.interest_earned) * 100.0 / SUM(a.current_balance), 2) as effective_interest_rate
FROM accounts a
JOIN account_types at ON a.account_type_id = at.account_type_id
WHERE a.account_status = 'active'
GROUP BY at.account_type_id, at.type_name
ORDER BY total_balance DESC;

-- Example 3: Risk Management and Compliance
-- Demonstrate risk management and compliance monitoring

-- High-risk transaction monitoring
SELECT 
    t.transaction_number,
    c.first_name || ' ' || c.last_name as customer_name,
    a.account_number,
    t.amount,
    t.merchant_name,
    t.merchant_category,
    t.transaction_date,
    c.risk_level,
    CASE 
        WHEN t.amount > 10000 THEN 'Large Transaction'
        WHEN t.amount > 5000 AND c.risk_level = 'high' THEN 'High Risk Large Transaction'
        WHEN t.merchant_category IN ('Gambling', 'Adult Entertainment') THEN 'Suspicious Category'
        ELSE 'Normal'
    END as risk_flag
FROM transactions t
JOIN accounts a ON t.account_id = a.account_id
JOIN customers c ON a.customer_id = c.customer_id
WHERE t.status = 'posted'
AND (
    t.amount > 5000 
    OR c.risk_level = 'high'
    OR t.merchant_category IN ('Gambling', 'Adult Entertainment')
)
ORDER BY t.amount DESC;

-- Loan portfolio risk analysis
SELECT 
    lt.type_name,
    COUNT(l.loan_id) as total_loans,
    SUM(l.principal_amount) as total_principal,
    SUM(l.remaining_balance) as total_outstanding,
    ROUND(AVG(l.interest_rate * 100), 2) as avg_interest_rate,
    COUNT(CASE WHEN l.loan_status = 'defaulted' THEN 1 END) as defaulted_loans,
    ROUND(COUNT(CASE WHEN l.loan_status = 'defaulted' THEN 1 END) * 100.0 / COUNT(*), 2) as default_rate,
    ROUND(SUM(CASE WHEN l.loan_status = 'defaulted' THEN l.remaining_balance ELSE 0 END), 2) as defaulted_amount
FROM loans l
JOIN loan_types lt ON l.loan_type_id = lt.loan_type_id
GROUP BY lt.loan_type_id, lt.type_name
ORDER BY default_rate DESC;

-- Customer overdraft analysis
SELECT 
    c.first_name || ' ' || c.last_name as customer_name,
    a.account_number,
    at.type_name,
    a.current_balance,
    a.available_balance,
    at.overdraft_limit,
    (a.current_balance - at.overdraft_limit) as overdraft_exposure,
    CASE 
        WHEN a.current_balance < 0 THEN 'Overdrawn'
        WHEN a.current_balance < at.overdraft_limit THEN 'Near Overdraft'
        ELSE 'Safe'
    END as overdraft_status
FROM accounts a
JOIN customers c ON a.customer_id = c.customer_id
JOIN account_types at ON a.account_type_id = at.account_type_id
WHERE a.account_status = 'active'
AND at.overdraft_limit > 0
ORDER BY overdraft_exposure;

-- Example 4: Revenue and Profitability Analysis
-- Demonstrate revenue and profitability tracking

-- Fee revenue analysis
SELECT 
    DATE_TRUNC('month', t.transaction_date) as month,
    tt.type_name,
    COUNT(*) as transaction_count,
    SUM(t.fee_amount) as total_fees,
    ROUND(AVG(t.fee_amount), 2) as avg_fee,
    ROUND(SUM(t.fee_amount) * 100.0 / SUM(SUM(t.fee_amount)) OVER (PARTITION BY DATE_TRUNC('month', t.transaction_date)), 2) as fee_percentage
FROM transactions t
JOIN transaction_types tt ON t.transaction_type_id = tt.transaction_type_id
WHERE t.fee_amount > 0
AND t.status = 'posted'
GROUP BY DATE_TRUNC('month', t.transaction_date), tt.transaction_type_id, tt.type_name
ORDER BY month DESC, total_fees DESC;

-- Interest income analysis
SELECT 
    DATE_TRUNC('month', t.transaction_date) as month,
    COUNT(*) as interest_transactions,
    SUM(t.amount) as total_interest_paid,
    ROUND(AVG(t.amount), 2) as avg_interest_payment,
    ROUND(SUM(t.amount) - LAG(SUM(t.amount)) OVER (ORDER BY DATE_TRUNC('month', t.transaction_date)), 2) as interest_growth
FROM transactions t
WHERE t.transaction_type_id = (SELECT transaction_type_id FROM transaction_types WHERE type_code = 'INT')
AND t.status = 'posted'
GROUP BY DATE_TRUNC('month', t.transaction_date)
ORDER BY month DESC;

-- Account profitability analysis
WITH account_metrics AS (
    SELECT 
        a.account_id,
        a.account_number,
        c.first_name || ' ' || c.last_name as customer_name,
        at.type_name,
        a.current_balance,
        a.interest_earned,
        COUNT(t.transaction_id) as transaction_count,
        SUM(t.fee_amount) as total_fees_paid,
        ROUND(AVG(a.current_balance * at.interest_rate), 2) as expected_interest_income,
        ROUND(SUM(t.fee_amount) - AVG(a.current_balance * at.interest_rate), 2) as net_revenue
    FROM accounts a
    JOIN customers c ON a.customer_id = c.customer_id
    JOIN account_types at ON a.account_type_id = at.account_type_id
    LEFT JOIN transactions t ON a.account_id = t.account_id AND t.status = 'posted'
    WHERE a.account_status = 'active'
    GROUP BY a.account_id, a.account_number, c.first_name, c.last_name, at.type_name, a.current_balance, a.interest_earned, at.interest_rate
)
SELECT 
    customer_name,
    account_number,
    type_name,
    current_balance,
    interest_earned,
    transaction_count,
    total_fees_paid,
    expected_interest_income,
    net_revenue,
    CASE 
        WHEN net_revenue > 100 THEN 'Highly Profitable'
        WHEN net_revenue > 0 THEN 'Profitable'
        ELSE 'Unprofitable'
    END as profitability_status
FROM account_metrics
ORDER BY net_revenue DESC;

-- Example 5: Regulatory Compliance and Reporting
-- Demonstrate regulatory compliance monitoring

-- KYC compliance status
SELECT 
    kyc_status,
    COUNT(*) as customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage,
    ROUND(AVG(credit_score), 0) as avg_credit_score,
    ROUND(AVG(annual_income), 2) as avg_annual_income
FROM customers
WHERE is_active = true
GROUP BY kyc_status
ORDER BY customer_count DESC;

-- Large transaction reporting (for regulatory compliance)
SELECT 
    t.transaction_number,
    c.first_name || ' ' || c.last_name as customer_name,
    c.ssn_hash,
    a.account_number,
    t.amount,
    t.merchant_name,
    t.transaction_date,
    CASE 
        WHEN t.amount >= 10000 THEN 'CTR Required'
        WHEN t.amount >= 3000 THEN 'Suspicious Activity'
        ELSE 'Normal'
    END as reporting_requirement
FROM transactions t
JOIN accounts a ON t.account_id = a.account_id
JOIN customers c ON a.customer_id = c.customer_id
WHERE t.status = 'posted'
AND t.amount >= 3000
ORDER BY t.amount DESC;

-- Loan compliance monitoring
SELECT 
    l.loan_number,
    c.first_name || ' ' || c.last_name as customer_name,
    lt.type_name,
    l.principal_amount,
    l.interest_rate,
    l.remaining_balance,
    l.loan_status,
    CASE 
        WHEN l.remaining_balance > l.principal_amount * 0.9 THEN 'High Risk'
        WHEN l.remaining_balance > l.principal_amount * 0.7 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END as risk_assessment,
    CASE 
        WHEN l.loan_status = 'defaulted' THEN 'Immediate Action Required'
        WHEN l.remaining_balance > l.principal_amount * 0.9 THEN 'Close Monitoring'
        ELSE 'Normal'
    END as compliance_status
FROM loans l
JOIN customers c ON l.customer_id = c.customer_id
JOIN loan_types lt ON l.loan_type_id = lt.loan_type_id
WHERE l.loan_status IN ('active', 'defaulted')
ORDER BY risk_assessment, l.remaining_balance DESC;

-- Clean up
DROP TABLE IF EXISTS loan_payments CASCADE;
DROP TABLE IF EXISTS loans CASCADE;
DROP TABLE IF EXISTS loan_types CASCADE;
DROP TABLE IF EXISTS transfers CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS transaction_types CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS account_types CASCADE;
DROP TABLE IF EXISTS customers CASCADE; 