-- Performance Tuning Quest: Composite Indexing
-- PURPOSE: Demonstrate advanced composite indexing strategies
-- DIFFICULTY: 🟡 Intermediate (10-15 min)
-- CONCEPTS: Composite indexes, index column order, covering indexes, index selectivity

-- Example 1: Basic Composite Indexes
-- Demonstrate creating and using composite indexes

-- Create sample tables
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    status VARCHAR(20),
    total_amount DECIMAL(10,2),
    region VARCHAR(50),
    salesperson_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    city VARCHAR(100),
    state VARCHAR(50),
    customer_segment VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO customers VALUES
(1, 'Alice Johnson', 'alice@email.com', 'New York', 'NY', 'Premium'),
(2, 'Bob Smith', 'bob@email.com', 'Los Angeles', 'CA', 'Standard'),
(3, 'Carol Davis', 'carol@email.com', 'Chicago', 'IL', 'Premium'),
(4, 'David Wilson', 'david@email.com', 'Houston', 'TX', 'Standard');

INSERT INTO orders VALUES
(1, 1, '2024-01-15', 'completed', 150.00, 'North', 1, '2024-01-15 10:00:00'),
(2, 2, '2024-01-16', 'processing', 75.50, 'South', 2, '2024-01-16 11:30:00'),
(3, 1, '2024-01-17', 'completed', 200.00, 'North', 1, '2024-01-17 09:15:00'),
(4, 3, '2024-01-18', 'shipped', 125.75, 'East', 3, '2024-01-18 14:20:00'),
(5, 4, '2024-01-19', 'completed', 300.00, 'West', 4, '2024-01-19 16:45:00'),
(6, 1, '2024-01-20', 'processing', 89.99, 'North', 1, '2024-01-20 12:00:00');

-- Example 2: Index Column Order Importance
-- Demonstrate the importance of column order in composite indexes

-- Create composite index with customer_id first (high selectivity)
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);

-- Create composite index with order_date first (lower selectivity)
CREATE INDEX idx_orders_date_customer ON orders(order_date, customer_id);

-- Query that benefits from customer_id first
EXPLAIN SELECT * FROM orders 
WHERE customer_id = 1 AND order_date >= '2024-01-15';

-- Query that benefits from order_date first
EXPLAIN SELECT * FROM orders 
WHERE order_date >= '2024-01-15' AND customer_id = 1;

-- Example 3: Covering Indexes
-- Demonstrate creating indexes that cover all needed columns

-- Create covering index for common query
CREATE INDEX idx_orders_covering ON orders(customer_id, order_date, status, total_amount);

-- Query that uses covering index (no table lookup needed)
EXPLAIN SELECT customer_id, order_date, status, total_amount 
FROM orders 
WHERE customer_id = 1 AND order_date >= '2024-01-15';

-- Example 4: Multi-Column Indexes for Complex Queries
-- Demonstrate indexes for complex WHERE clauses

-- Create index for complex filtering
CREATE INDEX idx_orders_complex ON orders(status, region, order_date);

-- Query with multiple conditions
EXPLAIN SELECT * FROM orders 
WHERE status = 'completed' 
  AND region = 'North' 
  AND order_date >= '2024-01-01';

-- Example 5: Indexes for ORDER BY and GROUP BY
-- Demonstrate indexes that support sorting and grouping

-- Create index that supports ORDER BY
CREATE INDEX idx_orders_sort ON orders(customer_id, order_date DESC, total_amount DESC);

-- Query with ORDER BY that uses index
EXPLAIN SELECT * FROM orders 
WHERE customer_id = 1 
ORDER BY order_date DESC, total_amount DESC;

-- Create index that supports GROUP BY
CREATE INDEX idx_orders_group ON orders(status, region, order_date);

-- Query with GROUP BY that uses index
EXPLAIN SELECT status, region, COUNT(*) as order_count
FROM orders 
WHERE order_date >= '2024-01-01'
GROUP BY status, region
ORDER BY status, region;

-- Example 6: Partial Indexes
-- Demonstrate creating indexes for specific conditions

-- Create partial index for completed orders only
CREATE INDEX idx_orders_completed ON orders(customer_id, order_date)
WHERE status = 'completed';

-- Query that uses partial index
EXPLAIN SELECT * FROM orders 
WHERE status = 'completed' 
  AND customer_id = 1 
  AND order_date >= '2024-01-15';

-- Create partial index for high-value orders
CREATE INDEX idx_orders_high_value ON orders(customer_id, order_date)
WHERE total_amount > 100;

-- Query that uses high-value partial index
EXPLAIN SELECT * FROM orders 
WHERE total_amount > 100 
  AND customer_id = 1 
  AND order_date >= '2024-01-15';

-- Example 7: Index Selectivity Analysis
-- Demonstrate analyzing index effectiveness

-- Check index usage statistics
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE tablename = 'orders'
ORDER BY idx_scan DESC;

-- Analyze index selectivity
SELECT 
    customer_id,
    COUNT(*) as order_count,
    COUNT(DISTINCT order_date) as unique_dates
FROM orders
GROUP BY customer_id
ORDER BY order_count DESC;

-- Example 8: Index Maintenance
-- Demonstrate maintaining composite indexes

-- Check index sizes
SELECT 
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) as index_size
FROM pg_indexes
WHERE tablename = 'orders'
ORDER BY pg_relation_size(indexname::regclass) DESC;

-- Check for unused indexes
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan
FROM pg_stat_user_indexes
WHERE tablename = 'orders' AND idx_scan = 0;

-- Example 9: Index Optimization Strategies
-- Demonstrate optimizing index usage

-- Query that tests different index strategies
EXPLAIN (ANALYZE, BUFFERS) 
SELECT 
    o.customer_id,
    c.customer_name,
    COUNT(*) as total_orders,
    SUM(o.total_amount) as total_spent,
    AVG(o.total_amount) as avg_order
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.status = 'completed'
  AND o.order_date >= '2024-01-01'
  AND o.total_amount > 50
GROUP BY o.customer_id, c.customer_name
ORDER BY total_spent DESC;

-- Example 10: Index Design Best Practices
-- Demonstrate best practices for composite indexes

-- Good: Index on most selective columns first
CREATE INDEX idx_orders_best_practice ON orders(customer_id, status, order_date);

-- Query that demonstrates best practice
EXPLAIN SELECT * FROM orders 
WHERE customer_id = 1 
  AND status = 'completed' 
  AND order_date >= '2024-01-15';

-- Clean up
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS customers CASCADE; 