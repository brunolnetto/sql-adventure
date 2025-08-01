-- Data Modeling Quest: Performance Denormalization
-- PURPOSE: Demonstrate strategic denormalization for read performance optimization
-- DIFFICULTY: Intermediate (15-20 min)
-- CONCEPTS: Read performance, query optimization, strategic redundancy, materialized views

-- Example 1: User Profile Denormalization
-- Demonstrate denormalizing user data for faster profile queries

-- Normalized user schema
CREATE TABLE users_normalized (
    user_id INT PRIMARY KEY,
    username VARCHAR(50) UNIQUE,
    email VARCHAR(100) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_profiles_normalized (
    profile_id INT PRIMARY KEY,
    user_id INT REFERENCES users_normalized(user_id),
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    bio TEXT,
    avatar_url VARCHAR(200),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_preferences_normalized (
    preference_id INT PRIMARY KEY,
    user_id INT REFERENCES users_normalized(user_id),
    preference_key VARCHAR(50),
    preference_value TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_stats_normalized (
    stats_id INT PRIMARY KEY,
    user_id INT REFERENCES users_normalized(user_id),
    posts_count INT DEFAULT 0,
    followers_count INT DEFAULT 0,
    following_count INT DEFAULT 0,
    last_activity TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert normalized data
INSERT INTO users_normalized VALUES
(1, 'alice_dev', 'alice@example.com', '2023-01-15 10:30:00'),
(2, 'bob_coder', 'bob@example.com', '2023-02-20 14:15:00'),
(3, 'carol_data', 'carol@example.com', '2023-03-10 09:45:00');

INSERT INTO user_profiles_normalized VALUES
(1, 1, 'Alice', 'Johnson', 'Software developer passionate about databases', 'https://avatars.com/alice.jpg', '2024-01-15 16:20:00'),
(2, 2, 'Bob', 'Smith', 'Full-stack developer and SQL enthusiast', 'https://avatars.com/bob.jpg', '2024-01-16 11:30:00'),
(3, 3, 'Carol', 'Davis', 'Data scientist and analytics expert', 'https://avatars.com/carol.jpg', '2024-01-17 13:45:00');

INSERT INTO user_preferences_normalized VALUES
(1, 1, 'theme', 'dark'),
(2, 1, 'notifications', 'email'),
(3, 1, 'language', 'en'),
(4, 2, 'theme', 'light'),
(5, 2, 'notifications', 'push'),
(6, 3, 'theme', 'dark'),
(7, 3, 'notifications', 'both');

INSERT INTO user_stats_normalized VALUES
(1, 1, 25, 150, 120, '2024-01-15 16:20:00', '2024-01-15 16:20:00'),
(2, 2, 18, 89, 95, '2024-01-16 11:30:00', '2024-01-16 11:30:00'),
(3, 3, 42, 234, 156, '2024-01-17 13:45:00', '2024-01-17 13:45:00');

-- Denormalized user profile for read performance
CREATE TABLE user_profiles_denormalized (
    user_id INT PRIMARY KEY,
    username VARCHAR(50) UNIQUE,
    email VARCHAR(100) UNIQUE,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    full_name VARCHAR(100) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
    bio TEXT,
    avatar_url VARCHAR(200),
    theme VARCHAR(20),
    notifications VARCHAR(20),
    language VARCHAR(10),
    posts_count INT DEFAULT 0,
    followers_count INT DEFAULT 0,
    following_count INT DEFAULT 0,
    last_activity TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert denormalized data
INSERT INTO user_profiles_denormalized (
    user_id, username, email, first_name, last_name, bio, avatar_url,
    theme, notifications, language, posts_count, followers_count, following_count, last_activity
) VALUES
(1, 'alice_dev', 'alice@example.com', 'Alice', 'Johnson', 
 'Software developer passionate about databases', 'https://avatars.com/alice.jpg',
 'dark', 'email', 'en', 25, 150, 120, '2024-01-15 16:20:00'),
(2, 'bob_coder', 'bob@example.com', 'Bob', 'Smith',
 'Full-stack developer and SQL enthusiast', 'https://avatars.com/bob.jpg',
 'light', 'push', 'en', 18, 89, 95, '2024-01-16 11:30:00'),
(3, 'carol_data', 'carol@example.com', 'Carol', 'Davis',
 'Data scientist and analytics expert', 'https://avatars.com/carol.jpg',
 'dark', 'both', 'en', 42, 234, 156, '2024-01-17 13:45:00');

-- Example 2: Product Catalog Denormalization
-- Demonstrate denormalizing product data for faster catalog queries

-- Normalized product schema
CREATE TABLE categories_normalized (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(100),
    parent_category_id INT REFERENCES categories_normalized(category_id),
    description TEXT
);

CREATE TABLE brands_normalized (
    brand_id INT PRIMARY KEY,
    brand_name VARCHAR(100),
    brand_description TEXT,
    logo_url VARCHAR(200)
);

CREATE TABLE products_normalized (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(200),
    category_id INT REFERENCES categories_normalized(category_id),
    brand_id INT REFERENCES brands_normalized(brand_id),
    sku VARCHAR(50) UNIQUE,
    description TEXT,
    unit_price DECIMAL(10,2),
    cost_price DECIMAL(10,2),
    weight_kg DECIMAL(5,2),
    dimensions_cm VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE product_inventory_normalized (
    inventory_id INT PRIMARY KEY,
    product_id INT REFERENCES products_normalized(product_id),
    warehouse_id INT,
    quantity_available INT DEFAULT 0,
    quantity_reserved INT DEFAULT 0,
    reorder_level INT DEFAULT 10,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert normalized data
INSERT INTO categories_normalized VALUES
(1, 'Electronics', NULL, 'Electronic devices and accessories'),
(2, 'Computers', 1, 'Desktop and laptop computers'),
(3, 'Accessories', 1, 'Computer accessories and peripherals'),
(4, 'Smartphones', 1, 'Mobile phones and accessories');

INSERT INTO brands_normalized VALUES
(1, 'TechCorp', 'Leading technology manufacturer', 'https://logos.com/techcorp.png'),
(2, 'MobilePro', 'Premium mobile device brand', 'https://logos.com/mobilepro.png'),
(3, 'AccessoryMax', 'Quality accessories provider', 'https://logos.com/accessorymax.png');

INSERT INTO products_normalized VALUES
(1, 'Laptop Pro X1', 2, 1, 'LAP-X1-001', 'High-performance laptop with latest specs', 1299.99, 800.00, 2.5, '35x25x2'),
(2, 'Wireless Mouse Elite', 3, 3, 'ACC-MSE-001', 'Ergonomic wireless mouse', 49.99, 15.00, 0.15, '12x6x3'),
(3, 'Smartphone Ultra', 4, 2, 'PHN-ULT-001', 'Latest smartphone with advanced features', 899.99, 450.00, 0.18, '15x7x0.8'),
(4, 'USB Keyboard Pro', 3, 3, 'ACC-KBD-001', 'Mechanical USB keyboard', 89.99, 30.00, 0.8, '44x15x3');

INSERT INTO product_inventory_normalized VALUES
(1, 1, 1, 25, 5, 10, '2024-01-15 10:00:00'),
(2, 2, 1, 150, 20, 50, '2024-01-15 10:00:00'),
(3, 3, 1, 45, 8, 15, '2024-01-15 10:00:00'),
(4, 4, 1, 80, 12, 25, '2024-01-15 10:00:00');

-- Denormalized product catalog for read performance
CREATE TABLE product_catalog_denormalized (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(200),
    sku VARCHAR(50) UNIQUE,
    description TEXT,
    unit_price DECIMAL(10,2),
    cost_price DECIMAL(10,2),
    profit_margin DECIMAL(10,2) GENERATED ALWAYS AS (unit_price - cost_price) STORED,
    profit_margin_percent DECIMAL(5,2) GENERATED ALWAYS AS (ROUND(((unit_price - cost_price) / unit_price) * 100, 2)) STORED,
    category_id INT,
    category_name VARCHAR(100),
    parent_category_name VARCHAR(100),
    brand_id INT,
    brand_name VARCHAR(100),
    brand_logo_url VARCHAR(200),
    weight_kg DECIMAL(5,2),
    dimensions_cm VARCHAR(50),
    quantity_available INT DEFAULT 0,
    quantity_reserved INT DEFAULT 0,
    quantity_available_for_sale INT GENERATED ALWAYS AS (quantity_available - quantity_reserved) STORED,
    reorder_level INT DEFAULT 10,
    needs_reorder BOOLEAN GENERATED ALWAYS AS (quantity_available <= reorder_level) STORED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert denormalized data
INSERT INTO product_catalog_denormalized (
    product_id, product_name, sku, description, unit_price, cost_price,
    category_id, category_name, parent_category_name, brand_id, brand_name, brand_logo_url,
    weight_kg, dimensions_cm, quantity_available, quantity_reserved, reorder_level
) VALUES
(1, 'Laptop Pro X1', 'LAP-X1-001', 'High-performance laptop with latest specs', 1299.99, 800.00,
 2, 'Computers', 'Electronics', 1, 'TechCorp', 'https://logos.com/techcorp.png',
 2.5, '35x25x2', 25, 5, 10),
(2, 'Wireless Mouse Elite', 'ACC-MSE-001', 'Ergonomic wireless mouse', 49.99, 15.00,
 3, 'Accessories', 'Electronics', 3, 'AccessoryMax', 'https://logos.com/accessorymax.png',
 0.15, '12x6x3', 150, 20, 50),
(3, 'Smartphone Ultra', 'PHN-ULT-001', 'Latest smartphone with advanced features', 899.99, 450.00,
 4, 'Smartphones', 'Electronics', 2, 'MobilePro', 'https://logos.com/mobilepro.png',
 0.18, '15x7x0.8', 45, 8, 15),
(4, 'USB Keyboard Pro', 'ACC-KBD-001', 'Mechanical USB keyboard', 89.99, 30.00,
 3, 'Accessories', 'Electronics', 3, 'AccessoryMax', 'https://logos.com/accessorymax.png',
 0.8, '44x15x3', 80, 12, 25);

-- Example 3: Performance Comparison
-- Demonstrate the performance benefits of denormalization

-- Complex query on normalized schema (multiple JOINs)
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    u.username,
    u.email,
    up.first_name,
    up.last_name,
    up.bio,
    up.avatar_url,
    upr.preference_value as theme,
    us.posts_count,
    us.followers_count,
    us.following_count,
    us.last_activity
FROM users_normalized u
JOIN user_profiles_normalized up ON u.user_id = up.user_id
LEFT JOIN user_preferences_normalized upr ON u.user_id = upr.user_id AND upr.preference_key = 'theme'
LEFT JOIN user_stats_normalized us ON u.user_id = us.user_id
WHERE u.username = 'alice_dev';

-- Simple query on denormalized schema (no JOINs)
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    username,
    email,
    first_name,
    last_name,
    full_name,
    bio,
    avatar_url,
    theme,
    posts_count,
    followers_count,
    following_count,
    last_activity
FROM user_profiles_denormalized
WHERE username = 'alice_dev';

-- Complex product query on normalized schema
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    p.product_name,
    p.sku,
    p.description,
    p.unit_price,
    c.category_name,
    pc.category_name as parent_category,
    b.brand_name,
    b.brand_logo_url,
    pi.quantity_available,
    pi.quantity_reserved,
    (pi.quantity_available - pi.quantity_reserved) as available_for_sale,
    CASE WHEN pi.quantity_available <= pi.reorder_level THEN true ELSE false END as needs_reorder
FROM products_normalized p
JOIN categories_normalized c ON p.category_id = c.category_id
LEFT JOIN categories_normalized pc ON c.parent_category_id = pc.category_id
JOIN brands_normalized b ON p.brand_id = b.brand_id
JOIN product_inventory_normalized pi ON p.product_id = pi.product_id
WHERE p.sku = 'LAP-X1-001';

-- Simple product query on denormalized schema
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    product_name,
    sku,
    description,
    unit_price,
    profit_margin,
    profit_margin_percent,
    category_name,
    parent_category_name,
    brand_name,
    brand_logo_url,
    quantity_available,
    quantity_reserved,
    quantity_available_for_sale,
    needs_reorder
FROM product_catalog_denormalized
WHERE sku = 'LAP-X1-001';

-- Example 4: Update Strategies for Denormalized Data
-- Demonstrate how to maintain consistency in denormalized data

-- Function to update user profile denormalized table
CREATE OR REPLACE FUNCTION update_user_profile_denormalized()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the denormalized table when normalized tables change
    IF TG_TABLE_NAME = 'user_profiles_normalized' THEN
        UPDATE user_profiles_denormalized SET
            first_name = NEW.first_name,
            last_name = NEW.last_name,
            bio = NEW.bio,
            avatar_url = NEW.avatar_url,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = NEW.user_id;
    ELSIF TG_TABLE_NAME = 'user_preferences_normalized' THEN
        UPDATE user_profiles_denormalized SET
            theme = CASE WHEN NEW.preference_key = 'theme' THEN NEW.preference_value ELSE theme END,
            notifications = CASE WHEN NEW.preference_key = 'notifications' THEN NEW.preference_value ELSE notifications END,
            language = CASE WHEN NEW.preference_key = 'language' THEN NEW.preference_value ELSE language END,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = NEW.user_id;
    ELSIF TG_TABLE_NAME = 'user_stats_normalized' THEN
        UPDATE user_profiles_denormalized SET
            posts_count = NEW.posts_count,
            followers_count = NEW.followers_count,
            following_count = NEW.following_count,
            last_activity = NEW.last_activity,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers to maintain denormalized data
CREATE TRIGGER trigger_update_user_profile_denormalized
    AFTER UPDATE ON user_profiles_normalized
    FOR EACH ROW EXECUTE FUNCTION update_user_profile_denormalized();

CREATE TRIGGER trigger_update_user_preferences_denormalized
    AFTER INSERT OR UPDATE ON user_preferences_normalized
    FOR EACH ROW EXECUTE FUNCTION update_user_profile_denormalized();

CREATE TRIGGER trigger_update_user_stats_denormalized
    AFTER UPDATE ON user_stats_normalized
    FOR EACH ROW EXECUTE FUNCTION update_user_profile_denormalized();

-- Test the trigger system
UPDATE user_profiles_normalized 
SET bio = 'Software developer passionate about databases and performance optimization'
WHERE user_id = 1;

-- Verify the denormalized table was updated
SELECT username, bio, updated_at 
FROM user_profiles_denormalized 
WHERE user_id = 1;

-- Clean up
DROP TABLE IF EXISTS users_normalized CASCADE;
DROP TABLE IF EXISTS user_profiles_normalized CASCADE;
DROP TABLE IF EXISTS user_preferences_normalized CASCADE;
DROP TABLE IF EXISTS user_stats_normalized CASCADE;
DROP TABLE IF EXISTS user_profiles_denormalized CASCADE;
DROP TABLE IF EXISTS categories_normalized CASCADE;
DROP TABLE IF EXISTS brands_normalized CASCADE;
DROP TABLE IF EXISTS products_normalized CASCADE;
DROP TABLE IF EXISTS product_inventory_normalized CASCADE;
DROP TABLE IF EXISTS product_catalog_denormalized CASCADE;
DROP FUNCTION IF EXISTS update_user_profile_denormalized() CASCADE; 