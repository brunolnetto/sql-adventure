-- =====================================================
-- Data Modeling Quest: Basic Constraints
-- =====================================================
-- 
-- PURPOSE: Demonstrate fundamental constraint concepts for beginners
-- DIFFICULTY: 🟢 Beginner (5-10 min)
-- CONCEPTS: NOT NULL, UNIQUE, CHECK, DEFAULT constraints

-- Example 1: NOT NULL and UNIQUE Constraints
-- Demonstrate basic data integrity constraints

-- Create a table with various constraints
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    hire_date DATE NOT NULL,
    salary DECIMAL(10, 2) NOT NULL,
    department VARCHAR(50) DEFAULT 'General',
    is_active BOOLEAN DEFAULT true
);

-- Insert valid data
INSERT INTO employees VALUES
(
    1,
    'John',
    'Doe',
    'john.doe@company.com',
    '555-1234',
    '2023-01-15',
    50000.00,
    'Engineering',
    true
),
(
    2,
    'Jane',
    'Smith',
    'jane.smith@company.com',
    '555-5678',
    '2023-02-20',
    55000.00,
    'Marketing',
    true
),
(
    3,
    'Bob',
    'Wilson',
    'bob.wilson@company.com',
    '555-9012',
    '2023-03-10',
    48000.00,
    'Sales',
    false
);

-- Example 2: CHECK Constraints
-- Demonstrate data validation constraints

-- Create a table with CHECK constraints
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) CHECK (price > 0),
    category VARCHAR(50) CHECK (
        category IN ('Electronics', 'Clothing', 'Books', 'Home')
    ),
    stock_quantity INT CHECK (stock_quantity >= 0),
    rating DECIMAL(3, 2) CHECK (rating >= 0 AND rating <= 5),
    is_featured BOOLEAN DEFAULT false
);

-- Insert valid data
INSERT INTO products VALUES
(1, 'Laptop', 999.99, 'Electronics', 50, 4.5, true),
(2, 'T-Shirt', 25.00, 'Clothing', 100, 4.2, false),
(3, 'Programming Book', 45.00, 'Books', 25, 4.8, true);

-- Example 3: Complex CHECK Constraints
-- Demonstrate more advanced constraint patterns

-- Create a table with complex constraints
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    shipping_address TEXT,
    CONSTRAINT valid_order_date CHECK (order_date >= '2020-01-01'),
    CONSTRAINT valid_amount CHECK (total_amount > 0),
    CONSTRAINT valid_status CHECK (
        status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')
    ),
    CONSTRAINT valid_shipping CHECK (
        (status IN ('shipped', 'delivered') AND shipping_address IS NOT null)
        OR (status NOT IN ('shipped', 'delivered'))
    )
);

-- Insert valid data
INSERT INTO orders VALUES
(1, 1, '2024-01-15', 150.00, 'pending', null),
(2, 2, '2024-01-20', 75.50, 'shipped', '123 Main St, City, State 12345'),
(3, 3, '2024-01-25', 200.00, 'delivered', '456 Oak Ave, City, State 12345');

-- Example 5: Querying with Constraints
-- Demonstrate how constraints help maintain data quality

-- Query employees with valid data
SELECT
    employee_id,
    email,
    department,
    salary,
    first_name || ' ' || last_name AS full_name
FROM employees
WHERE is_active = true
ORDER BY salary DESC;

-- Query products with valid ratings
SELECT
    product_name,
    category,
    price,
    rating,
    CASE
        WHEN rating >= 4.5 THEN 'Excellent'
        WHEN rating >= 4.0 THEN 'Good'
        WHEN rating >= 3.0 THEN 'Average'
        ELSE 'Poor'
    END AS rating_category
FROM products
WHERE stock_quantity > 0
ORDER BY rating DESC;

-- Clean up
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
