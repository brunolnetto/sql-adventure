-- =====================================================
-- Data Modeling Quest: Simple Relationships
-- =====================================================
-- 
-- PURPOSE: Demonstrate basic relationship concepts for beginners
-- DIFFICULTY: 🟢 Beginner (5-10 min)
-- CONCEPTS: Foreign keys, one-to-many relationships, JOIN queries

-- Example 1: One-to-Many Relationship
-- Demonstrate a simple relationship between customers and orders

-- Create customers table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create orders table with foreign key to customers
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
);

-- Insert sample data
INSERT INTO customers VALUES
(1, 'Alice Johnson', 'alice@email.com', '555-1234', '2024-01-01 10:00:00'),
(2, 'Bob Smith', 'bob@email.com', '555-5678', '2024-01-02 11:30:00'),
(3, 'Carol Davis', 'carol@email.com', '555-9012', '2024-01-03 09:15:00');

INSERT INTO orders VALUES
(1, 1, '2024-01-15', 150.00, 'completed'),
(2, 1, '2024-01-20', 75.50, 'completed'),
(3, 2, '2024-01-25', 200.00, 'pending'),
(4, 3, '2024-01-30', 125.75, 'completed');

-- Example 2: Querying Related Data
-- Demonstrate JOIN queries to get related information

-- Get customer information with their orders
SELECT
    c.customer_name,
    c.email,
    o.order_id,
    o.order_date,
    o.total_amount,
    o.status
FROM customers AS c
INNER JOIN orders AS o ON c.customer_id = o.customer_id
ORDER BY c.customer_name, o.order_date;

-- Get customers with their order counts
SELECT
    c.customer_name,
    c.email,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS total_spent
FROM customers AS c
LEFT JOIN orders AS o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.email
ORDER BY total_spent DESC;

-- Example 3: Simple Many-to-Many Relationship
-- Demonstrate a simple many-to-many relationship

-- Create categories table
CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL,
    description TEXT
);

-- Create products table
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

-- Create junction table for many-to-many relationship
CREATE TABLE product_categories (
    product_id INT,
    category_id INT,
    PRIMARY KEY (product_id, category_id),
    FOREIGN KEY (product_id) REFERENCES products (product_id),
    FOREIGN KEY (category_id) REFERENCES categories (category_id)
);

-- Insert sample data
INSERT INTO categories VALUES
(1, 'Electronics', 'Electronic devices and accessories'),
(2, 'Clothing', 'Apparel and fashion items'),
(3, 'Books', 'Books and publications');

INSERT INTO products VALUES
(1, 'Laptop', 999.99),
(2, 'T-Shirt', 25.00),
(3, 'Programming Book', 45.00),
(4, 'Smartphone', 699.99);

INSERT INTO product_categories VALUES
(1, 1), -- Laptop in Electronics
(2, 2), -- T-Shirt in Clothing
(3, 3), -- Programming Book in Books
(4, 1), -- Smartphone in Electronics
(1, 3); -- Laptop also in Books (tech books)

-- Query products with their categories
SELECT
    p.product_name,
    p.price,
    STRING_AGG(c.category_name, ', ') AS categories
FROM products AS p
INNER JOIN product_categories AS pc ON p.product_id = pc.product_id
INNER JOIN categories AS c ON pc.category_id = c.category_id
GROUP BY p.product_id, p.product_name, p.price
ORDER BY p.product_name;

-- Clean up
DROP TABLE IF EXISTS product_categories CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
