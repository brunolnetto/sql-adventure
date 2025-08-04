-- Data Modeling Quest: E-commerce Data Model
-- PURPOSE: Demonstrate comprehensive e-commerce data modeling
-- DIFFICULTY: 🔴 Advanced (20-25 min)
-- CONCEPTS: E-commerce modeling, inventory management, order processing, customer analytics

-- Example 1: Core E-commerce Entities
-- Demonstrate the core entities for an e-commerce system

-- Customers and Authentication
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_number VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
    is_email_verified BOOLEAN DEFAULT false,
    is_phone_verified BOOLEAN DEFAULT false,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended', 'deleted')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE customer_addresses (
    address_id INT PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    address_type VARCHAR(20) NOT NULL CHECK (address_type IN ('billing', 'shipping', 'both')),
    is_default BOOLEAN DEFAULT false,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    company VARCHAR(100),
    street_address VARCHAR(200) NOT NULL,
    street_address2 VARCHAR(200),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(50) NOT NULL DEFAULT 'USA',
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(customer_id, address_type, is_default)
);

-- Product Catalog
CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    category_code VARCHAR(20) UNIQUE NOT NULL,
    parent_category_id INT REFERENCES categories(category_id),
    description TEXT,
    image_url VARCHAR(200),
    is_active BOOLEAN DEFAULT true,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE brands (
    brand_id INT PRIMARY KEY,
    brand_name VARCHAR(100) NOT NULL,
    brand_code VARCHAR(20) UNIQUE NOT NULL,
    description TEXT,
    logo_url VARCHAR(200),
    website_url VARCHAR(200),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    product_code VARCHAR(50) UNIQUE NOT NULL,
    sku VARCHAR(50) UNIQUE NOT NULL,
    category_id INT NOT NULL REFERENCES categories(category_id),
    brand_id INT REFERENCES brands(brand_id),
    description TEXT,
    short_description VARCHAR(500),
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    compare_price DECIMAL(10,2) CHECK (compare_price >= 0),
    cost_price DECIMAL(10,2) CHECK (cost_price >= 0),
    weight_kg DECIMAL(5,2) CHECK (weight_kg >= 0),
    dimensions_cm VARCHAR(50), -- "LxWxH"
    is_active BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    is_bestseller BOOLEAN DEFAULT false,
    meta_title VARCHAR(200),
    meta_description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE product_images (
    image_id INT PRIMARY KEY,
    product_id INT NOT NULL REFERENCES products(product_id),
    image_url VARCHAR(200) NOT NULL,
    alt_text VARCHAR(200),
    is_primary BOOLEAN DEFAULT false,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE product_variants (
    variant_id INT PRIMARY KEY,
    product_id INT NOT NULL REFERENCES products(product_id),
    variant_name VARCHAR(100) NOT NULL, -- e.g., "Size: Large, Color: Red"
    sku VARCHAR(50) UNIQUE NOT NULL,
    price DECIMAL(10,2) CHECK (price >= 0),
    compare_price DECIMAL(10,2) CHECK (compare_price >= 0),
    cost_price DECIMAL(10,2) CHECK (cost_price >= 0),
    weight_kg DECIMAL(5,2) CHECK (weight_kg >= 0),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inventory Management
CREATE TABLE inventory (
    inventory_id INT PRIMARY KEY,
    product_id INT REFERENCES products(product_id),
    variant_id INT REFERENCES product_variants(variant_id),
    warehouse_id INT NOT NULL,
    quantity_available INT DEFAULT 0 CHECK (quantity_available >= 0),
    quantity_reserved INT DEFAULT 0 CHECK (quantity_reserved >= 0),
    quantity_on_order INT DEFAULT 0 CHECK (quantity_on_order >= 0),
    reorder_level INT DEFAULT 0 CHECK (reorder_level >= 0),
    reorder_quantity INT DEFAULT 0 CHECK (reorder_quantity >= 0),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(product_id, variant_id, warehouse_id)
);

-- Orders and Transactions
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    order_number VARCHAR(20) UNIQUE NOT NULL,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    billing_address_id INT NOT NULL REFERENCES customer_addresses(address_id),
    shipping_address_id INT NOT NULL REFERENCES customer_addresses(address_id),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded')),
    subtotal DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0),
    tax_amount DECIMAL(10,2) DEFAULT 0 CHECK (tax_amount >= 0),
    shipping_amount DECIMAL(10,2) DEFAULT 0 CHECK (shipping_amount >= 0),
    discount_amount DECIMAL(10,2) DEFAULT 0 CHECK (discount_amount >= 0),
    total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0),
    currency VARCHAR(3) DEFAULT 'USD',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT NOT NULL REFERENCES orders(order_id),
    product_id INT NOT NULL REFERENCES products(product_id),
    variant_id INT REFERENCES product_variants(variant_id),
    product_name VARCHAR(200) NOT NULL,
    sku VARCHAR(50) NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    total_price DECIMAL(10,2) NOT NULL CHECK (total_price >= 0),
    tax_amount DECIMAL(10,2) DEFAULT 0 CHECK (tax_amount >= 0),
    discount_amount DECIMAL(10,2) DEFAULT 0 CHECK (discount_amount >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO customers VALUES
(1, 'CUST001', 'alice@email.com', 'hashed_password_123', 'Alice', 'Johnson', '555-1234', '1990-05-15', 'female', true, true, 'active'),
(2, 'CUST002', 'bob@email.com', 'hashed_password_456', 'Bob', 'Smith', '555-5678', '1985-08-22', 'male', true, false, 'active'),
(3, 'CUST003', 'carol@email.com', 'hashed_password_789', 'Carol', 'Davis', '555-9012', '1992-03-10', 'female', false, true, 'active');

INSERT INTO customer_addresses VALUES
(1, 1, 'both', true, 'Alice', 'Johnson', NULL, '123 Main St', NULL, 'New York', 'NY', '10001', 'USA', '555-1234'),
(2, 2, 'both', true, 'Bob', 'Smith', 'Tech Corp', '456 Oak Ave', 'Suite 100', 'Los Angeles', 'CA', '90210', 'USA', '555-5678'),
(3, 3, 'both', true, 'Carol', 'Davis', NULL, '789 Pine St', NULL, 'Chicago', 'IL', '60601', 'USA', '555-9012');

INSERT INTO categories VALUES
(1, 'Electronics', 'ELEC', NULL, 'Electronic devices and accessories', '/images/electronics.jpg', true, 1),
(2, 'Computers', 'COMP', 1, 'Desktop and laptop computers', '/images/computers.jpg', true, 1),
(3, 'Accessories', 'ACC', 1, 'Computer accessories and peripherals', '/images/accessories.jpg', true, 2);

INSERT INTO brands VALUES
(1, 'TechCorp', 'TECH', 'Leading technology manufacturer', '/logos/techcorp.png', 'https://techcorp.com', true),
(2, 'AccessoryMax', 'ACC', 'Quality accessories provider', '/logos/accessorymax.png', 'https://accessorymax.com', true);

INSERT INTO products VALUES
(1, 'Laptop Pro X1', 'LAP-X1', 'LAP-X1-001', 2, 1, 'High-performance laptop with latest specs', 'Powerful laptop for professionals', 1299.99, 1499.99, 800.00, 2.5, '35x25x2', true, true, true, 'Laptop Pro X1 - High Performance', 'Professional laptop with cutting-edge technology'),
(2, 'Wireless Mouse Elite', 'WIRE-MOUSE', 'ACC-MSE-001', 3, 2, 'Ergonomic wireless mouse', 'Comfortable wireless mouse', 49.99, 59.99, 15.00, 0.15, '12x6x3', true, false, false, 'Wireless Mouse Elite', 'Ergonomic wireless mouse for comfort'),
(3, 'USB Keyboard Pro', 'USB-KBD', 'ACC-KBD-001', 3, 2, 'Mechanical USB keyboard', 'Premium mechanical keyboard', 89.99, 99.99, 30.00, 0.8, '44x15x3', true, false, false, 'USB Keyboard Pro', 'Mechanical keyboard for typing enthusiasts');

INSERT INTO product_images VALUES
(1, 1, '/products/laptop-pro-x1-1.jpg', 'Laptop Pro X1 front view', true, 1),
(2, 1, '/products/laptop-pro-x1-2.jpg', 'Laptop Pro X1 side view', false, 2),
(3, 2, '/products/wireless-mouse-1.jpg', 'Wireless Mouse Elite', true, 1),
(4, 3, '/products/usb-keyboard-1.jpg', 'USB Keyboard Pro', true, 1);

INSERT INTO product_variants VALUES
(1, 1, 'Size: 13-inch, Color: Silver', 'LAP-X1-13-SIL', 1299.99, 1499.99, 800.00, 2.3, true),
(2, 1, 'Size: 15-inch, Color: Silver', 'LAP-X1-15-SIL', 1499.99, 1699.99, 900.00, 2.7, true),
(3, 2, 'Color: Black', 'ACC-MSE-BLK', 49.99, 59.99, 15.00, 0.15, true),
(4, 2, 'Color: White', 'ACC-MSE-WHT', 49.99, 59.99, 15.00, 0.15, true);

INSERT INTO inventory VALUES
(1, 1, 1, 1, 25, 5, 10, 10, 20),
(2, 1, 2, 1, 15, 3, 8, 8, 15),
(3, 2, 3, 1, 150, 20, 50, 50, 100),
(4, 2, 4, 1, 100, 15, 30, 30, 75),
(5, 3, NULL, 1, 80, 12, 25, 25, 60);

INSERT INTO orders VALUES
(1, 'ORD-2024-001', 1, 1, 1, '2024-01-15 10:30:00', 'delivered', 1439.97, 115.20, 0.00, 0.00, 1555.17, 'USD', NULL),
(2, 'ORD-2024-002', 2, 2, 2, '2024-01-16 14:15:00', 'processing', 139.98, 11.20, 5.00, 0.00, 156.18, 'USD', NULL),
(3, 'ORD-2024-003', 3, 3, 3, '2024-01-17 09:45:00', 'confirmed', 89.99, 7.20, 0.00, 10.00, 87.19, 'USD', 'Customer requested gift wrapping');

INSERT INTO order_items VALUES
(1, 1, 1, 1, 'Laptop Pro X1', 'LAP-X1-13-SIL', 1, 1299.99, 1299.99, 103.99, 0.00),
(2, 1, 2, 3, 'Wireless Mouse Elite', 'ACC-MSE-BLK', 1, 49.99, 49.99, 4.00, 0.00),
(3, 1, 3, NULL, 'USB Keyboard Pro', 'ACC-KBD-001', 1, 89.99, 89.99, 7.20, 0.00),
(4, 2, 2, 3, 'Wireless Mouse Elite', 'ACC-MSE-BLK', 1, 49.99, 49.99, 4.00, 0.00),
(5, 2, 3, NULL, 'USB Keyboard Pro', 'ACC-KBD-001', 1, 89.99, 89.99, 7.20, 0.00),
(6, 3, 3, NULL, 'USB Keyboard Pro', 'ACC-KBD-001', 1, 89.99, 89.99, 7.20, 10.00);

-- Example 2: E-commerce Analytics Queries
-- Demonstrate comprehensive e-commerce analytics

-- Customer analytics
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer_name,
    c.email,
    COUNT(DISTINCT o.order_id) as total_orders,
    SUM(o.total_amount) as total_spent,
    ROUND(AVG(o.total_amount), 2) as avg_order_value,
    MIN(o.order_date) as first_order_date,
    MAX(o.order_date) as last_order_date,
    CASE 
        WHEN SUM(o.total_amount) >= 1000 THEN 'Premium'
        WHEN SUM(o.total_amount) >= 500 THEN 'Gold'
        WHEN SUM(o.total_amount) >= 100 THEN 'Silver'
        ELSE 'Bronze'
    END as customer_tier
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.status = 'active'
GROUP BY c.customer_id, c.first_name, c.last_name, c.email
ORDER BY total_spent DESC;

-- Product performance analysis
SELECT 
    p.product_id,
    p.product_name,
    p.sku,
    c.category_name,
    b.brand_name,
    p.price,
    p.cost_price,
    (p.price - p.cost_price) as profit_margin,
    ROUND(((p.price - p.cost_price) / p.price) * 100, 2) as profit_margin_percent,
    COUNT(oi.order_item_id) as times_ordered,
    SUM(oi.quantity) as total_quantity_sold,
    SUM(oi.total_price) as total_revenue,
    SUM(oi.total_price - (oi.quantity * p.cost_price)) as total_profit,
    CASE WHEN p.is_bestseller = true THEN 'Bestseller' ELSE 'Regular' END as product_status
FROM products p
LEFT JOIN categories c ON p.category_id = c.category_id
LEFT JOIN brands b ON p.brand_id = b.brand_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE p.is_active = true
GROUP BY p.product_id, p.product_name, p.sku, c.category_name, b.brand_name, p.price, p.cost_price, p.is_bestseller
ORDER BY total_revenue DESC;

-- Inventory analysis
SELECT 
    p.product_name,
    p.sku,
    i.warehouse_id,
    i.quantity_available,
    i.quantity_reserved,
    i.quantity_on_order,
    (i.quantity_available - i.quantity_reserved) as available_for_sale,
    i.reorder_level,
    CASE 
        WHEN i.quantity_available <= i.reorder_level THEN 'Reorder Needed'
        WHEN i.quantity_available <= i.reorder_level * 1.5 THEN 'Low Stock'
        ELSE 'In Stock'
    END as stock_status,
    CASE 
        WHEN i.quantity_available <= i.reorder_level THEN i.reorder_quantity
        ELSE 0
    END as suggested_order_quantity
FROM inventory i
JOIN products p ON i.product_id = p.product_id
WHERE p.is_active = true
ORDER BY stock_status, available_for_sale;

-- Example 3: Order Processing and Fulfillment
-- Demonstrate order processing workflows

-- Order status tracking
SELECT 
    o.order_number,
    c.first_name || ' ' || c.last_name as customer_name,
    o.order_date,
    o.status,
    o.total_amount,
    COUNT(oi.order_item_id) as item_count,
    SUM(oi.quantity) as total_quantity,
    CASE 
        WHEN o.status = 'pending' THEN 'Payment Pending'
        WHEN o.status = 'confirmed' THEN 'Payment Received'
        WHEN o.status = 'processing' THEN 'Being Prepared'
        WHEN o.status = 'shipped' THEN 'In Transit'
        WHEN o.status = 'delivered' THEN 'Delivered'
        WHEN o.status = 'cancelled' THEN 'Cancelled'
        ELSE 'Unknown'
    END as status_description
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.order_number, c.first_name, c.last_name, o.order_date, o.status, o.total_amount
ORDER BY o.order_date DESC;

-- Revenue analysis by time period
SELECT 
    DATE_TRUNC('month', o.order_date) as month,
    COUNT(DISTINCT o.order_id) as total_orders,
    COUNT(DISTINCT o.customer_id) as unique_customers,
    SUM(o.total_amount) as total_revenue,
    ROUND(AVG(o.total_amount), 2) as avg_order_value,
    SUM(o.tax_amount) as total_tax,
    SUM(o.shipping_amount) as total_shipping,
    SUM(o.discount_amount) as total_discounts,
    ROUND((SUM(o.total_amount) - LAG(SUM(o.total_amount)) OVER (ORDER BY DATE_TRUNC('month', o.order_date))) / 
          LAG(SUM(o.total_amount)) OVER (ORDER BY DATE_TRUNC('month', o.order_date)) * 100, 2) as revenue_growth_percent
FROM orders o
WHERE o.status NOT IN ('cancelled', 'refunded')
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY month;

-- Example 4: Customer Segmentation and Marketing
-- Demonstrate customer segmentation for marketing

-- Customer segmentation by purchase behavior
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name as customer_name,
        c.email,
        COUNT(DISTINCT o.order_id) as order_count,
        SUM(o.total_amount) as total_spent,
        ROUND(AVG(o.total_amount), 2) as avg_order_value,
        MIN(o.order_date) as first_order_date,
        MAX(o.order_date) as last_order_date,
        EXTRACT(DAYS FROM (CURRENT_DATE - MAX(o.order_date))) as days_since_last_order
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    WHERE c.status = 'active'
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email
)
SELECT 
    customer_id,
    customer_name,
    email,
    order_count,
    total_spent,
    avg_order_value,
    days_since_last_order,
    CASE 
        WHEN total_spent >= 1000 AND order_count >= 5 THEN 'VIP Customer'
        WHEN total_spent >= 500 AND order_count >= 3 THEN 'Loyal Customer'
        WHEN total_spent >= 100 AND order_count >= 2 THEN 'Regular Customer'
        WHEN total_spent >= 50 THEN 'Occasional Customer'
        WHEN total_spent > 0 THEN 'New Customer'
        ELSE 'Prospect'
    END as customer_segment,
    CASE 
        WHEN days_since_last_order <= 30 THEN 'Recent'
        WHEN days_since_last_order <= 90 THEN 'Active'
        WHEN days_since_last_order <= 365 THEN 'At Risk'
        ELSE 'Inactive'
    END as recency_segment
FROM customer_metrics
ORDER BY total_spent DESC;

-- Example 5: Inventory Optimization
-- Demonstrate inventory optimization strategies

-- Inventory optimization analysis
WITH inventory_analysis AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.sku,
        c.category_name,
        i.quantity_available,
        i.quantity_reserved,
        i.quantity_on_order,
        i.reorder_level,
        i.reorder_quantity,
        COALESCE(SUM(oi.quantity), 0) as total_sold_last_30_days,
        COALESCE(AVG(oi.quantity), 0) as avg_daily_sales,
        CASE 
            WHEN i.quantity_available <= i.reorder_level THEN 'Reorder'
            WHEN i.quantity_available <= i.reorder_level * 1.5 THEN 'Monitor'
            ELSE 'OK'
        END as action_needed
    FROM inventory i
    JOIN products p ON i.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.order_id
    WHERE p.is_active = true
    AND (o.order_date IS NULL OR o.order_date >= CURRENT_DATE - INTERVAL '30 days')
    GROUP BY p.product_id, p.product_name, p.sku, c.category_name, i.quantity_available, 
             i.quantity_reserved, i.quantity_on_order, i.reorder_level, i.reorder_quantity
)
SELECT 
    product_name,
    sku,
    category_name,
    quantity_available,
    quantity_reserved,
    quantity_on_order,
    reorder_level,
    total_sold_last_30_days,
    ROUND(avg_daily_sales, 2) as avg_daily_sales,
    action_needed,
    CASE 
        WHEN action_needed = 'Reorder' THEN reorder_quantity
        WHEN action_needed = 'Monitor' THEN GREATEST(0, reorder_level - quantity_available)
        ELSE 0
    END as suggested_order_quantity
FROM inventory_analysis
ORDER BY action_needed, avg_daily_sales DESC;

-- Clean up
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS product_variants CASCADE;
DROP TABLE IF EXISTS product_images CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS brands CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS customer_addresses CASCADE;
DROP TABLE IF EXISTS customers CASCADE; 