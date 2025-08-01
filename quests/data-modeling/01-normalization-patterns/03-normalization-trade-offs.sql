-- Data Modeling Quest: Normalization Trade-offs
-- PURPOSE: Demonstrate when to normalize vs. denormalize based on use cases
-- DIFFICULTY: Advanced (15-20 min)
-- CONCEPTS: Normalization trade-offs, performance vs. flexibility, OLTP vs. OLAP

-- Example 1: OLTP vs. OLAP Considerations
-- Show different normalization levels for different use cases

-- Highly normalized schema for OLTP (Online Transaction Processing)
CREATE TABLE customers_oltp (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    customer_email VARCHAR(100) UNIQUE,
    customer_phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE addresses_oltp (
    address_id INT PRIMARY KEY,
    customer_id INT REFERENCES customers_oltp(customer_id),
    address_type VARCHAR(20),
    street_address VARCHAR(200),
    city VARCHAR(100),
    state VARCHAR(50),
    postal_code VARCHAR(20)
);

CREATE TABLE orders_oltp (
    order_id INT PRIMARY KEY,
    customer_id INT REFERENCES customers_oltp(customer_id),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2)
);

-- Denormalized schema for OLAP (Online Analytical Processing)
CREATE TABLE customer_orders_olap (
    customer_id INT,
    customer_name VARCHAR(100),
    customer_email VARCHAR(100),
    customer_city VARCHAR(100),
    customer_state VARCHAR(50),
    order_id INT,
    order_date DATE,
    total_amount DECIMAL(10,2),
    customer_total_orders INT,
    customer_total_spent DECIMAL(12,2)
);

-- Insert sample data
INSERT INTO customers_oltp VALUES
(1, 'John Smith', 'john@email.com', '555-1234'),
(2, 'Jane Doe', 'jane@email.com', '555-5678');

INSERT INTO addresses_oltp VALUES
(1, 1, 'billing', '123 Main St', 'New York', 'NY', '10001'),
(2, 1, 'shipping', '456 Oak Ave', 'New York', 'NY', '10002');

INSERT INTO orders_oltp VALUES
(1, 1, '2024-01-15', 150.00),
(2, 1, '2024-01-20', 75.50),
(3, 2, '2024-01-25', 200.00);

INSERT INTO customer_orders_olap VALUES
(1, 'John Smith', 'john@email.com', 'New York', 'NY', 1, '2024-01-15', 150.00, 2, 225.50),
(1, 'John Smith', 'john@email.com', 'New York', 'NY', 2, '2024-01-20', 75.50, 2, 225.50),
(2, 'Jane Doe', 'jane@email.com', 'Los Angeles', 'CA', 3, '2024-01-25', 200.00, 1, 200.00);

-- Example 2: Read vs. Write Performance Trade-offs
-- Demonstrate performance differences between normalized and denormalized

-- Normalized approach (good for writes, slower for reads)
CREATE TABLE products_normalized (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category_id INT,
    supplier_id INT
);

CREATE TABLE categories_normalized (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(100)
);

CREATE TABLE suppliers_normalized (
    supplier_id INT PRIMARY KEY,
    supplier_name VARCHAR(100)
);

-- Denormalized approach (good for reads, slower for writes)
CREATE TABLE products_denormalized (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category_name VARCHAR(100),
    supplier_name VARCHAR(100)
);

-- Insert sample data
INSERT INTO categories_normalized VALUES
(1, 'Electronics'),
(2, 'Clothing');

INSERT INTO suppliers_normalized VALUES
(1, 'TechCorp'),
(2, 'FashionCo');

INSERT INTO products_normalized VALUES
(1, 'Laptop', 1, 1),
(2, 'T-Shirt', 2, 2);

INSERT INTO products_denormalized VALUES
(1, 'Laptop', 'Electronics', 'TechCorp'),
(2, 'T-Shirt', 'Clothing', 'FashionCo');

-- Example 3: Data Consistency vs. Performance
-- Show the trade-off between data consistency and query performance

-- Normalized approach (consistent data, multiple joins)
SELECT 
    p.product_name,
    c.category_name,
    s.supplier_name
FROM products_normalized p
JOIN categories_normalized c ON p.category_id = c.category_id
JOIN suppliers_normalized s ON p.supplier_id = s.supplier_id;

-- Denormalized approach (faster query, potential inconsistency)
SELECT 
    product_name,
    category_name,
    supplier_name
FROM products_denormalized;

-- Clean up
DROP TABLE IF EXISTS customers_oltp CASCADE;
DROP TABLE IF EXISTS addresses_oltp CASCADE;
DROP TABLE IF EXISTS orders_oltp CASCADE;
DROP TABLE IF EXISTS customer_orders_olap CASCADE;
DROP TABLE IF EXISTS products_normalized CASCADE;
DROP TABLE IF EXISTS categories_normalized CASCADE;
DROP TABLE IF EXISTS suppliers_normalized CASCADE;
DROP TABLE IF EXISTS products_denormalized CASCADE; 