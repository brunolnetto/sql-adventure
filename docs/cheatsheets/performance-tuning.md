# Performance Tuning Cheatsheet ⚡

Your complete guide to PostgreSQL query optimization, indexing strategies, and performance monitoring for production environments.

## 🎯 **Core Optimization Principles**

### **1. Query Structure Optimization**

#### **SELECT Optimization**
```sql
-- ❌ BEFORE: Selecting all columns
SELECT * FROM customers WHERE city = 'New York';

-- ✅ AFTER: Select only needed columns
SELECT customer_id, first_name, last_name, email 
FROM customers 
WHERE city = 'New York';

-- ❌ BEFORE: Using functions in WHERE clause
SELECT * FROM products 
WHERE LOWER(product_name) = 'laptop';

-- ✅ AFTER: Use indexed columns in WHERE
SELECT * FROM products 
WHERE product_name ILIKE 'laptop%';
```

#### **WHERE Clause Optimization**
```sql
-- ❌ BEFORE: Non-sargable conditions
SELECT * FROM orders 
WHERE YEAR(order_date) = 2024;

-- ✅ AFTER: Sargable conditions
SELECT * FROM orders 
WHERE order_date >= '2024-01-01' 
  AND order_date < '2025-01-01';

-- ❌ BEFORE: OR conditions
SELECT * FROM products 
WHERE category = 'electronics' OR category = 'computers';

-- ✅ AFTER: IN clause (better for indexes)
SELECT * FROM products 
WHERE category IN ('electronics', 'computers');
```

#### **JOIN Optimization**
```sql
-- ❌ BEFORE: Implicit joins
SELECT c.customer_name, o.order_id 
FROM customers c, orders o 
WHERE c.customer_id = o.customer_id;

-- ✅ AFTER: Explicit INNER JOIN
SELECT c.customer_name, o.order_id 
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id;

-- ❌ BEFORE: Cross join
SELECT * FROM products CROSS JOIN categories;

-- ✅ AFTER: Proper join condition
SELECT p.product_name, c.category_name 
FROM products p
INNER JOIN categories c ON p.category_id = c.category_id;
```

### **2. Indexing Strategies**

#### **Basic Indexing**
```sql
-- Single column index
CREATE INDEX idx_customers_email ON customers(email);

-- Composite index (most selective first)
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);

-- Partial index (for active records only)
CREATE INDEX idx_active_products ON products(product_name) 
WHERE is_active = true;

-- Expression index
CREATE INDEX idx_products_name_lower ON products(LOWER(product_name));

-- Unique index
CREATE UNIQUE INDEX idx_customers_email_unique ON customers(email);
```

#### **Advanced Indexing**
```sql
-- Covering index (includes all needed columns)
CREATE INDEX idx_orders_covering ON orders(customer_id, order_date) 
INCLUDE (total_amount, status);

-- Partial index with complex condition
CREATE INDEX idx_recent_orders ON orders(order_date) 
WHERE order_date >= CURRENT_DATE - INTERVAL '90 days';

-- Multi-column index for range queries
CREATE INDEX idx_products_category_price ON products(category_id, price);

-- Index for text search
CREATE INDEX idx_products_name_gin ON products USING gin(to_tsvector('english', product_name));
```

### **3. Execution Plan Analysis**

#### **EXPLAIN Basics**
```sql
-- Basic execution plan
EXPLAIN SELECT * FROM customers WHERE city = 'New York';

-- Detailed execution plan with timing
EXPLAIN (ANALYZE, BUFFERS) 
SELECT c.customer_name, COUNT(o.order_id) as order_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.city = 'New York'
GROUP BY c.customer_id, c.customer_name;
```

#### **Plan Analysis**
```sql
-- Check if query uses indexes
EXPLAIN SELECT * FROM products WHERE category_id = 1;

-- Analyze join performance
EXPLAIN (ANALYZE, BUFFERS) 
SELECT p.product_name, c.category_name
FROM products p
INNER JOIN categories c ON p.category_id = c.category_id
WHERE p.price > 100;

-- Check aggregation performance
EXPLAIN (ANALYZE, BUFFERS) 
SELECT category_id, AVG(price) as avg_price
FROM products 
GROUP BY category_id;
```

### **4. Aggregation Optimization**

#### **GROUP BY Optimization**
```sql
-- ❌ BEFORE: Grouping by non-indexed columns
SELECT category, COUNT(*) 
FROM products 
GROUP BY category;

-- ✅ AFTER: Use indexed columns
SELECT category_id, COUNT(*) 
FROM products 
GROUP BY category_id;

-- ❌ BEFORE: Complex aggregation without index
SELECT customer_id, SUM(total_amount) 
FROM orders 
GROUP BY customer_id;

-- ✅ AFTER: Indexed aggregation
CREATE INDEX idx_orders_customer_amount ON orders(customer_id, total_amount);
SELECT customer_id, SUM(total_amount) 
FROM orders 
GROUP BY customer_id;
```

#### **Window Functions vs Aggregations**
```sql
-- ❌ BEFORE: Subquery for running total
SELECT order_id, total_amount,
       (SELECT SUM(total_amount) 
        FROM orders o2 
        WHERE o2.order_id <= o1.order_id) as running_total
FROM orders o1;

-- ✅ AFTER: Window function (much faster)
SELECT order_id, total_amount,
       SUM(total_amount) OVER (ORDER BY order_id) as running_total
FROM orders;
```

## 📊 **Performance Monitoring**

### **System Statistics**
```sql
-- Database size
SELECT pg_size_pretty(pg_database_size(current_database())) as db_size;

-- Table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Index usage statistics
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes 
ORDER BY idx_scan DESC;
```

### **Query Performance Analysis**
```sql
-- Slow queries
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    rows
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;

-- Table access patterns
SELECT 
    schemaname,
    tablename,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch
FROM pg_stat_user_tables 
ORDER BY seq_scan DESC;
```

### **Index Analysis**
```sql
-- Unused indexes
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan
FROM pg_stat_user_indexes 
WHERE idx_scan = 0 
ORDER BY pg_relation_size(indexrelid) DESC;

-- Index sizes
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size
FROM pg_stat_user_indexes 
ORDER BY pg_relation_size(indexrelid) DESC;
```

## 🔧 **Advanced Optimization Techniques**

### **Query Rewriting**
```sql
-- ❌ BEFORE: Correlated subquery
SELECT customer_id, customer_name,
       (SELECT COUNT(*) FROM orders WHERE customer_id = c.customer_id) as order_count
FROM customers c;

-- ✅ AFTER: JOIN with aggregation
SELECT c.customer_id, c.customer_name, COUNT(o.order_id) as order_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name;

-- ❌ BEFORE: Multiple subqueries
SELECT product_id, product_name,
       (SELECT AVG(price) FROM products WHERE category_id = p.category_id) as avg_category_price,
       (SELECT COUNT(*) FROM order_items WHERE product_id = p.product_id) as order_count
FROM products p;

-- ✅ AFTER: Window functions and JOINs
SELECT p.product_id, p.product_name,
       AVG(p.price) OVER (PARTITION BY p.category_id) as avg_category_price,
       COALESCE(oi.order_count, 0) as order_count
FROM products p
LEFT JOIN (
    SELECT product_id, COUNT(*) as order_count
    FROM order_items
    GROUP BY product_id
) oi ON p.product_id = oi.product_id;
```

### **Materialized Views**
```sql
-- Create materialized view for complex aggregations
CREATE MATERIALIZED VIEW mv_customer_analytics AS
SELECT 
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) as total_orders,
    SUM(o.total_amount) as total_spent,
    AVG(o.total_amount) as avg_order_value,
    MAX(o.order_date) as last_order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name;

-- Refresh materialized view
REFRESH MATERIALIZED VIEW mv_customer_analytics;

-- Query the materialized view
SELECT * FROM mv_customer_analytics 
WHERE total_spent > 1000 
ORDER BY total_spent DESC;
```

### **Partitioning**
```sql
-- Range partitioning by date
CREATE TABLE orders (
    order_id INT,
    customer_id INT,
    order_date DATE,
    total_amount DECIMAL(10,2)
) PARTITION BY RANGE (order_date);

-- Create partitions
CREATE TABLE orders_2024_01 PARTITION OF orders
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE orders_2024_02 PARTITION OF orders
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- Query specific partition
SELECT * FROM orders_2024_01 WHERE customer_id = 123;
```

## 🚀 **Performance Best Practices**

### **Query Design**
```sql
-- Use LIMIT for large result sets
SELECT * FROM products ORDER BY created_date DESC LIMIT 100;

-- Use EXISTS instead of IN for large subqueries
SELECT customer_id, customer_name
FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o 
    WHERE o.customer_id = c.customer_id 
    AND o.total_amount > 1000
);

-- Use UNION ALL instead of UNION when duplicates don't matter
SELECT product_id, product_name FROM active_products
UNION ALL
SELECT product_id, product_name FROM featured_products;
```

### **Index Maintenance**
```sql
-- Rebuild indexes periodically
REINDEX INDEX CONCURRENTLY idx_customers_email;

-- Update table statistics
ANALYZE customers;

-- Vacuum tables to reclaim space
VACUUM ANALYZE orders;
```

### **Configuration Optimization**
```sql
-- Check current settings
SHOW shared_buffers;
SHOW effective_cache_size;
SHOW work_mem;
SHOW maintenance_work_mem;

-- Recommended settings for performance
-- shared_buffers = 25% of RAM
-- effective_cache_size = 75% of RAM
-- work_mem = 4MB (adjust based on concurrent connections)
-- maintenance_work_mem = 256MB
```

## 📈 **Performance Monitoring Dashboard**

### **System Health Check**
```sql
-- Active connections
SELECT count(*) as active_connections 
FROM pg_stat_activity 
WHERE state = 'active';

-- Database locks
SELECT 
    l.pid,
    l.mode,
    l.granted,
    a.query
FROM pg_locks l
JOIN pg_stat_activity a ON l.pid = a.pid
WHERE NOT l.granted;

-- Cache hit ratio
SELECT 
    sum(heap_blks_read) as heap_read,
    sum(heap_blks_hit) as heap_hit,
    sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as ratio
FROM pg_statio_user_tables;
```

### **Query Performance Tracking**
```sql
-- Create performance log table
CREATE TABLE query_performance_log (
    log_id SERIAL PRIMARY KEY,
    query_hash TEXT,
    query_text TEXT,
    execution_time_ms NUMERIC,
    rows_returned INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Function to log slow queries
CREATE OR REPLACE FUNCTION log_slow_query()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.mean_time > 1000 THEN -- Log queries slower than 1 second
        INSERT INTO query_performance_log (query_hash, query_text, execution_time_ms, rows_returned)
        VALUES (NEW.query, NEW.query, NEW.mean_time, NEW.rows);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

## 🔍 **Troubleshooting Common Issues**

### **Slow Queries**
```sql
-- Find slow queries
SELECT query, mean_time, calls, rows
FROM pg_stat_statements 
WHERE mean_time > 1000
ORDER BY mean_time DESC;

-- Check for table scans
SELECT schemaname, tablename, seq_scan, seq_tup_read
FROM pg_stat_user_tables 
WHERE seq_scan > 1000
ORDER BY seq_scan DESC;
```

### **Index Issues**
```sql
-- Find missing indexes
SELECT 
    schemaname,
    tablename,
    attname,
    n_distinct,
    correlation
FROM pg_stats 
WHERE schemaname = 'public' 
AND n_distinct > 100
AND correlation < 0.1;

-- Check index fragmentation
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size
FROM pg_stat_user_indexes 
ORDER BY pg_relation_size(indexrelid) DESC;
```

---

---

## 🔬 **Advanced Patterns**

### **Query Rewriting with CTEs**
```sql
-- Complex query optimization using CTEs
WITH user_stats AS (
    SELECT 
        user_id,
        COUNT(*) as order_count,
        SUM(amount) as total_spent,
        AVG(amount) as avg_order_value
    FROM orders 
    WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY user_id
),
user_segments AS (
    SELECT 
        user_id,
        order_count,
        total_spent,
        avg_order_value,
        CASE 
            WHEN total_spent > 1000 THEN 'High Value'
            WHEN total_spent > 500 THEN 'Medium Value'
            ELSE 'Low Value'
        END as segment
    FROM user_stats
)
SELECT 
    segment,
    COUNT(*) as user_count,
    AVG(order_count) as avg_orders,
    AVG(total_spent) as avg_spent
FROM user_segments
GROUP BY segment
ORDER BY avg_spent DESC;
```

### **Materialized Views for Complex Analytics**
```sql
-- Create materialized view for expensive analytics
CREATE MATERIALIZED VIEW daily_sales_summary AS
SELECT 
    DATE(created_at) as sale_date,
    product_category,
    COUNT(*) as orders,
    SUM(quantity) as total_quantity,
    SUM(quantity * unit_price) as total_revenue,
    AVG(unit_price) as avg_price
FROM orders o
JOIN products p ON o.product_id = p.product_id
WHERE created_at >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY DATE(created_at), product_category;

-- Refresh materialized view
REFRESH MATERIALIZED VIEW daily_sales_summary;

-- Query the materialized view
SELECT * FROM daily_sales_summary 
WHERE sale_date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY total_revenue DESC;
```

### **Advanced Indexing Strategies**
```sql
-- Partial indexes for filtered queries
CREATE INDEX idx_active_users_email ON users(email) 
WHERE is_active = true;

-- Expression indexes for computed columns
CREATE INDEX idx_users_lower_email ON users(LOWER(email));

-- Covering indexes for common queries
CREATE INDEX idx_orders_covering ON orders(user_id, created_at) 
INCLUDE (amount, status);

-- Multi-column indexes for complex filters
CREATE INDEX idx_products_category_price ON products(category, price DESC, name);
```

### **Performance Monitoring Dashboard**
```sql
-- Create performance monitoring views
CREATE VIEW slow_queries AS
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    rows
FROM pg_stat_statements 
WHERE mean_time > 100  -- Queries taking more than 100ms
ORDER BY mean_time DESC;

-- Table size monitoring
CREATE VIEW table_sizes AS
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
    pg_total_relation_size(schemaname||'.'||tablename) as size_bytes
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY size_bytes DESC;

-- Index usage statistics
CREATE VIEW index_usage AS
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes 
ORDER BY idx_scan DESC;
```

---

*Follow this cheatsheet to optimize your PostgreSQL queries and achieve maximum performance! ⚡* 