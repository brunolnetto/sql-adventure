-- Data Modeling Quest: Basic Table Creation
-- PURPOSE: Demonstrate fundamental table creation concepts for beginners
-- DIFFICULTY: 🟢 Beginner (5-10 min)
-- CONCEPTS: Table creation, data types, primary keys, basic constraints

-- Example 1: Basic Table Creation
-- Demonstrate creating simple tables with different data types

-- Create a simple users table
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    date_of_birth DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create a simple products table
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) CHECK (price >= 0),
    category VARCHAR(50),
    in_stock BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO users VALUES
(1, 'john_doe', 'john@email.com', 'John', 'Doe', '1990-05-15', true, '2024-01-01 10:00:00'),
(2, 'jane_smith', 'jane@email.com', 'Jane', 'Smith', '1985-08-22', true, '2024-01-02 11:30:00'),
(3, 'bob_wilson', 'bob@email.com', 'Bob', 'Wilson', '1992-12-10', false, '2024-01-03 09:15:00');

INSERT INTO products VALUES
(1, 'Laptop', 'High-performance laptop', 999.99, 'Electronics', true, '2024-01-01 08:00:00'),
(2, 'Mouse', 'Wireless mouse', 29.99, 'Electronics', true, '2024-01-01 08:00:00'),
(3, 'Desk', 'Office desk', 199.99, 'Furniture', false, '2024-01-01 08:00:00');

-- Example 2: Querying Basic Tables
-- Demonstrate simple SELECT queries

-- Query all users
SELECT * FROM users;

-- Query active users only
SELECT user_id, username, email, first_name, last_name
FROM users
WHERE is_active = true;

-- Query products with price filtering
SELECT product_name, price, category
FROM products
WHERE price > 50 AND in_stock = true;

-- Example 3: Basic Data Types and Constraints
-- Demonstrate different data types and constraints

-- Create a table with various data types
CREATE TABLE sample_data (
    id INT PRIMARY KEY,
    text_field VARCHAR(100),
    long_text TEXT,
    number_field INT,
    decimal_field DECIMAL(10,2),
    date_field DATE,
    timestamp_field TIMESTAMP,
    boolean_field BOOLEAN,
    email_field VARCHAR(100) CHECK (email_field LIKE '%@%')
);

-- Insert sample data with different types
INSERT INTO sample_data VALUES
(1, 'Short text', 'This is a longer text field that can contain much more content', 42, 123.45, '2024-01-15', '2024-01-15 14:30:00', true, 'test@example.com'),
(2, 'Another text', 'More long text content here', 100, 999.99, '2024-01-16', '2024-01-16 09:15:00', false, 'user@domain.com');

-- Query the sample data
SELECT * FROM sample_data;

-- Clean up
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS sample_data CASCADE; 