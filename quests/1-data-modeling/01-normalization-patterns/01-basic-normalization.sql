-- Data Modeling Quest: Basic Normalization
-- PURPOSE: Demonstrate 1NF, 2NF, and 3NF with simple examples
-- DIFFICULTY: 🟡 Intermediate (10-15 min)
-- CONCEPTS: 1NF, 2NF, 3NF, atomic values, functional dependencies

-- Example 1: First Normal Form (1NF) - Atomic Values
-- Break down non-atomic values into atomic components

-- Unnormalized table (violates 1NF)
CREATE TABLE unnormalized_orders (
    order_id INT PRIMARY KEY,
    customer_info TEXT, -- "John Doe, john@email.com, 555-1234"
    order_items TEXT,   -- "Laptop, Mouse, Keyboard"
    order_date DATE
);

-- Insert sample data
INSERT INTO unnormalized_orders VALUES
(1, 'John Doe, john@email.com, 555-1234', 'Laptop, Mouse', '2024-01-15'),
(2, 'Jane Smith, jane@email.com, 555-5678', 'Keyboard, Monitor', '2024-01-16');

-- Normalized tables (1NF)
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT REFERENCES customers (customer_id),
    order_date DATE
);

CREATE TABLE order_items (
    item_id INT PRIMARY KEY,
    order_id INT REFERENCES orders (order_id),
    product_name VARCHAR(100),
    quantity INT
);

-- Insert normalized data
INSERT INTO customers VALUES
(1, 'John Doe', 'john@email.com', '555-1234'),
(2, 'Jane Smith', 'jane@email.com', '555-5678');

INSERT INTO orders VALUES
(1, 1, '2024-01-15'),
(2, 2, '2024-01-16');

INSERT INTO order_items VALUES
(1, 1, 'Laptop', 1),
(2, 1, 'Mouse', 1),
(3, 2, 'Keyboard', 1),
(4, 2, 'Monitor', 1);

-- Example 2: Second Normal Form (2NF) - Remove Partial Dependencies
-- Demonstrate removing partial dependencies from composite keys

-- Table violating 2NF
CREATE TABLE order_details_violation (
    order_id INT,
    product_id INT,
    product_name VARCHAR(100), -- Depends only on product_id, not the full key
    customer_id INT,
    customer_name VARCHAR(100), -- Depends only on customer_id, not the full key
    quantity INT,
    unit_price DECIMAL(10, 2),
    PRIMARY KEY (order_id, product_id)
);

-- Normalized tables (2NF)
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    unit_price DECIMAL(10, 2)
);

CREATE TABLE order_details (
    order_id INT,
    product_id INT REFERENCES products (product_id),
    quantity INT,
    PRIMARY KEY (order_id, product_id)
);

-- Example 3: Third Normal Form (3NF) - Remove Transitive Dependencies
-- Demonstrate removing transitive dependencies

-- Table violating 3NF
CREATE TABLE employees_violation (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100),
    department_id INT,
    department_name VARCHAR(100), -- Depends on department_id, not employee_id
    -- Depends on department_id, not employee_id
    department_location VARCHAR(100)
);

-- Normalized tables (3NF)
CREATE TABLE departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(100),
    department_location VARCHAR(100)
);

CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100),
    department_id INT REFERENCES departments (department_id)
);

-- Insert sample data
INSERT INTO departments VALUES
(1, 'Engineering', 'Building A'),
(2, 'Marketing', 'Building B');

INSERT INTO employees VALUES
(1, 'Alice Johnson', 1),
(2, 'Bob Smith', 1),
(3, 'Carol Davis', 2);

-- Query to demonstrate normalization benefits
SELECT
    e.employee_name,
    d.department_name,
    d.department_location
FROM employees AS e
INNER JOIN departments AS d ON e.department_id = d.department_id;

-- Clean up
DROP TABLE IF EXISTS unnormalized_orders CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS order_details_violation CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS order_details CASCADE;
DROP TABLE IF EXISTS employees_violation CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
