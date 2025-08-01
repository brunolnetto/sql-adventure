-- =====================================================
-- Performance Tuning: Advanced Indexing Strategies
-- =====================================================
-- 
-- PURPOSE: Demonstrate advanced indexing techniques in PostgreSQL
--          for complex queries, text search, and specialized data types
-- LEARNING OUTCOMES:
--   - Create specialized indexes for text search and full-text queries
--   - Use GIN and GiST indexes for complex data types
--   - Implement covering indexes for query optimization
--   - Handle index maintenance and optimization
--   - Analyze index performance in complex scenarios
-- EXPECTED RESULTS: Optimize complex queries with advanced indexing
-- DIFFICULTY: 🔴 Advanced (15-20 min)
-- CONCEPTS: GIN indexes, GiST indexes, covering indexes, text search, index maintenance

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS articles CASCADE;
DROP TABLE IF EXISTS products_advanced CASCADE;
DROP TABLE IF EXISTS spatial_data CASCADE;

-- Create articles table for text search
CREATE TABLE articles (
    article_id SERIAL PRIMARY KEY,
    title VARCHAR(200),
    content TEXT,
    author VARCHAR(100),
    category VARCHAR(50),
    tags TEXT[],
    published_date DATE,
    view_count INT DEFAULT 0
);

-- Create products table with JSON data
CREATE TABLE products_advanced (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    description TEXT,
    specifications JSONB,
    categories TEXT[],
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create spatial data table
CREATE TABLE spatial_data (
    location_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    location_type VARCHAR(50),
    properties JSONB
);

-- Insert sample articles data
INSERT INTO articles (title, content, author, category, tags, published_date, view_count) VALUES
('PostgreSQL Performance Optimization', 'Learn advanced techniques for optimizing PostgreSQL queries and improving database performance...', 'John Smith', 'Database', ARRAY['postgresql', 'performance', 'optimization'], '2024-01-15', 1250),
('Introduction to Database Indexing', 'Understanding the fundamentals of database indexing and how it affects query performance...', 'Jane Doe', 'Database', ARRAY['indexing', 'database', 'performance'], '2024-01-16', 890),
('Advanced SQL Techniques', 'Explore advanced SQL features including window functions, CTEs, and complex aggregations...', 'Bob Johnson', 'SQL', ARRAY['sql', 'advanced', 'window-functions'], '2024-01-17', 1560),
('Data Modeling Best Practices', 'Learn how to design efficient database schemas and relationships...', 'Alice Brown', 'Design', ARRAY['data-modeling', 'schema', 'relationships'], '2024-01-18', 720);

-- Insert sample products data
INSERT INTO products_advanced (name, description, specifications, categories, metadata) VALUES
('Gaming Laptop', 'High-performance gaming laptop with RGB keyboard', '{"cpu": "Intel i9", "ram": "32GB", "gpu": "RTX 4080", "storage": "1TB SSD"}', ARRAY['Electronics', 'Gaming', 'Laptop'], '{"brand": "GamingTech", "warranty": "2 years", "rating": 4.8}'),
('Wireless Headphones', 'Noise-cancelling wireless headphones', '{"brand": "AudioTech", "type": "Over-ear", "battery_life": "30 hours"}', ARRAY['Electronics', 'Audio', 'Wireless'], '{"brand": "AudioTech", "warranty": "1 year", "rating": 4.6}'),
('Office Chair', 'Ergonomic office chair with lumbar support', '{"material": "Mesh", "weight_capacity": "300 lbs", "adjustable": true}', ARRAY['Furniture', 'Office', 'Ergonomic'], '{"brand": "ComfortMax", "warranty": "5 years", "rating": 4.4}');

-- Insert sample spatial data
INSERT INTO spatial_data (name, latitude, longitude, location_type, properties) VALUES
('Central Park', 40.7829, -73.9654, 'Park', '{"area_acres": 843, "established": 1857, "features": ["lakes", "trails", "playgrounds"]}'),
('Times Square', 40.7580, -73.9855, 'Landmark', '{"famous_for": "New Year celebrations", "tourist_attraction": true, "neon_signs": true}'),
('Brooklyn Bridge', 40.7061, -73.9969, 'Bridge', '{"length_feet": 5989, "opened": 1883, "pedestrian_access": true}');

-- Example 1: Full-Text Search Index
-- Create GIN index for full-text search
CREATE INDEX idx_articles_content_gin ON articles USING GIN(to_tsvector('english', content));
CREATE INDEX idx_articles_title_gin ON articles USING GIN(to_tsvector('english', title));

-- Full-text search query
SELECT article_id, title, author, ts_rank(to_tsvector('english', content), query) as rank
FROM articles, to_tsquery('english', 'performance & optimization') query
WHERE to_tsvector('english', content) @@ query
ORDER BY rank DESC;

-- Example 2: Array Index for Tag Search
-- Create GIN index for array columns
CREATE INDEX idx_articles_tags_gin ON articles USING GIN(tags);

-- Array search query
SELECT article_id, title, tags
FROM articles
WHERE tags && ARRAY['postgresql', 'performance'];

-- Example 3: JSONB Index for Complex Queries
-- Create GIN index on JSONB columns
CREATE INDEX idx_products_specs_gin ON products_advanced USING GIN(specifications);
CREATE INDEX idx_products_metadata_gin ON products_advanced USING GIN(metadata);

-- JSONB search query
SELECT product_id, name, specifications->>'cpu' as cpu
FROM products_advanced
WHERE specifications @> '{"cpu": "Intel i9"}';

-- Example 4: Covering Index for Query Optimization
-- Create covering index that includes all needed columns
CREATE INDEX idx_articles_covering ON articles (category, published_date) 
INCLUDE (title, author, view_count);

-- Query that benefits from covering index
SELECT title, author, view_count
FROM articles
WHERE category = 'Database' AND published_date >= '2024-01-15';

-- Example 5: Partial Index with Complex Conditions
-- Create partial index for high-view articles
CREATE INDEX idx_articles_popular ON articles (category, published_date)
WHERE view_count > 1000;

-- Query for popular articles
SELECT title, author, view_count
FROM articles
WHERE view_count > 1000 AND category = 'Database'
ORDER BY view_count DESC;

-- Example 6: Index Maintenance and Analysis
-- Analyze index usage and performance
SELECT 
    schemaname,
    relname as tablename,
    indexrelname as indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size
FROM pg_stat_user_indexes
WHERE relname IN ('articles', 'products_advanced', 'spatial_data')
ORDER BY idx_scan DESC;

-- Show index sizes
SELECT 
    schemaname,
    relname as tablename,
    indexrelname as indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size,
    pg_size_pretty(pg_relation_size(relid)) as table_size
FROM pg_stat_user_indexes
WHERE relname IN ('articles', 'products_advanced', 'spatial_data')
ORDER BY pg_relation_size(indexrelid) DESC;

-- Clean up
DROP TABLE IF EXISTS articles CASCADE;
DROP TABLE IF EXISTS products_advanced CASCADE;
DROP TABLE IF EXISTS spatial_data CASCADE; 