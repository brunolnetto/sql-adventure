# Window Functions Cheatsheet 🪟

Your complete guide to mastering advanced analytics, ranking, and time series analysis with Window Functions.

## 🎯 **Core Concepts**

### **Basic Window Function Structure**
```sql
SELECT 
    column1,
    column2,
    window_function() OVER (
        [PARTITION BY column1, column2]
        [ORDER BY column1 [ASC|DESC], column2 [ASC|DESC]]
        [ROWS|RANGE frame_specification]
    ) as result
FROM table_name;
```

### **Window Function Types**
1. **Ranking Functions** - ROW_NUMBER(), RANK(), DENSE_RANK(), NTILE()
2. **Aggregation Functions** - SUM(), AVG(), COUNT(), MIN(), MAX()
3. **Navigation Functions** - LAG(), LEAD(), FIRST_VALUE(), LAST_VALUE()
4. **Distribution Functions** - PERCENT_RANK(), CUME_DIST()

---

## 🏆 **1. Ranking Functions**

### **ROW_NUMBER() - Unique Sequential Numbers**
```sql
-- Basic row numbering
SELECT 
    product_name,
    price,
    ROW_NUMBER() OVER (ORDER BY price DESC) as price_rank
FROM products;

-- Row numbering within categories
SELECT 
    category,
    product_name,
    price,
    ROW_NUMBER() OVER (
        PARTITION BY category 
        ORDER BY price DESC
    ) as category_rank
FROM products;
```

### **RANK() - Ranking with Gaps**
```sql
-- Rank with gaps for ties
SELECT 
    student_name,
    score,
    RANK() OVER (ORDER BY score DESC) as rank_with_gaps
FROM students;

-- Rank within departments
SELECT 
    department,
    employee_name,
    salary,
    RANK() OVER (
        PARTITION BY department 
        ORDER BY salary DESC
    ) as dept_rank
FROM employees;
```

### **DENSE_RANK() - Ranking without Gaps**
```sql
-- Rank without gaps for ties
SELECT 
    student_name,
    score,
    DENSE_RANK() OVER (ORDER BY score DESC) as dense_rank
FROM students;

-- Top 3 employees per department
SELECT * FROM (
    SELECT 
        department,
        employee_name,
        salary,
        DENSE_RANK() OVER (
            PARTITION BY department 
            ORDER BY salary DESC
        ) as dept_rank
    FROM employees
) ranked
WHERE dept_rank <= 3;
```

### **NTILE() - Bucket Distribution**
```sql
-- Divide into 4 equal buckets
SELECT 
    customer_name,
    total_spent,
    NTILE(4) OVER (ORDER BY total_spent DESC) as spending_tier
FROM customers;

-- Quartile analysis
SELECT 
    product_name,
    sales_volume,
    NTILE(4) OVER (ORDER BY sales_volume) as quartile
FROM products;
```

---

## 📊 **2. Aggregation Windows**

### **Running Totals**
```sql
-- Simple running total
SELECT 
    order_date,
    daily_sales,
    SUM(daily_sales) OVER (ORDER BY order_date) as running_total
FROM daily_sales;

-- Running total by category
SELECT 
    category,
    order_date,
    daily_sales,
    SUM(daily_sales) OVER (
        PARTITION BY category 
        ORDER BY order_date
    ) as category_running_total
FROM daily_sales;
```

### **Moving Averages**
```sql
-- 3-day moving average
SELECT 
    date,
    sales,
    AVG(sales) OVER (
        ORDER BY date 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) as moving_avg_3d
FROM daily_sales;

-- 7-day moving average
SELECT 
    date,
    sales,
    AVG(sales) OVER (
        ORDER BY date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as moving_avg_7d
FROM daily_sales;
```

### **Cumulative Sums**
```sql
-- Cumulative sum by month
SELECT 
    month,
    revenue,
    SUM(revenue) OVER (ORDER BY month) as cumulative_revenue
FROM monthly_revenue;

-- Cumulative sum by region
SELECT 
    region,
    month,
    revenue,
    SUM(revenue) OVER (
        PARTITION BY region 
        ORDER BY month
    ) as region_cumulative
FROM monthly_revenue;
```

---

## 🔍 **3. Navigation Functions**

### **LAG() - Previous Row Values**
```sql
-- Compare with previous day
SELECT 
    date,
    sales,
    LAG(sales, 1) OVER (ORDER BY date) as previous_day_sales,
    sales - LAG(sales, 1) OVER (ORDER BY date) as daily_change
FROM daily_sales;

-- Compare with previous month
SELECT 
    month,
    revenue,
    LAG(revenue, 1) OVER (ORDER BY month) as previous_month,
    (revenue - LAG(revenue, 1) OVER (ORDER BY month)) / 
    LAG(revenue, 1) OVER (ORDER BY month) * 100 as growth_percent
FROM monthly_revenue;
```

### **LEAD() - Next Row Values**
```sql
-- Compare with next day
SELECT 
    date,
    sales,
    LEAD(sales, 1) OVER (ORDER BY date) as next_day_sales
FROM daily_sales;

-- Find next higher salary
SELECT 
    employee_name,
    salary,
    LEAD(salary, 1) OVER (ORDER BY salary) as next_higher_salary
FROM employees;
```

### **FIRST_VALUE() and LAST_VALUE()**
```sql
-- First value in partition
SELECT 
    department,
    employee_name,
    salary,
    FIRST_VALUE(salary) OVER (
        PARTITION BY department 
        ORDER BY salary DESC
    ) as dept_highest_salary
FROM employees;

-- Last value in partition
SELECT 
    category,
    product_name,
    price,
    LAST_VALUE(price) OVER (
        PARTITION BY category 
        ORDER BY price
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as dept_lowest_price
FROM products;
```

---

## 🎨 **4. Partitioned Analytics**

### **Category-Based Analysis**
```sql
-- Sales ranking by category
SELECT 
    category,
    product_name,
    sales,
    ROW_NUMBER() OVER (
        PARTITION BY category 
        ORDER BY sales DESC
    ) as category_rank
FROM products;

-- Average price by category
SELECT 
    category,
    product_name,
    price,
    AVG(price) OVER (PARTITION BY category) as avg_category_price,
    price - AVG(price) OVER (PARTITION BY category) as price_difference
FROM products;
```

### **Time-Based Analysis**
```sql
-- Monthly trends
SELECT 
    month,
    revenue,
    AVG(revenue) OVER (
        ORDER BY month 
        ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
    ) as centered_moving_avg
FROM monthly_revenue;

-- Year-over-year comparison
SELECT 
    month,
    revenue,
    LAG(revenue, 12) OVER (ORDER BY month) as last_year_revenue,
    (revenue - LAG(revenue, 12) OVER (ORDER BY month)) / 
    LAG(revenue, 12) OVER (ORDER BY month) * 100 as yoy_growth
FROM monthly_revenue;
```

---

## 📈 **5. Advanced Patterns**

### **Gap Analysis**
```sql
-- Find gaps in sequence
WITH numbered AS (
    SELECT 
        id,
        ROW_NUMBER() OVER (ORDER BY id) as expected_id
    FROM sequence_table
)
SELECT 
    id,
    expected_id,
    id - expected_id as gap
FROM numbered
WHERE id != expected_id;
```

### **Trend Detection**
```sql
-- Detect increasing trends
SELECT 
    date,
    value,
    CASE 
        WHEN value > LAG(value, 1) OVER (ORDER BY date) 
        AND LAG(value, 1) OVER (ORDER BY date) > LAG(value, 2) OVER (ORDER BY date)
        THEN 'Increasing Trend'
        ELSE 'No Trend'
    END as trend
FROM time_series_data;
```

### **Lead-Lag Analysis**
```sql
-- Compare current vs previous vs next
SELECT 
    date,
    sales,
    LAG(sales, 1) OVER (ORDER BY date) as previous_sales,
    sales as current_sales,
    LEAD(sales, 1) OVER (ORDER BY date) as next_sales,
    CASE 
        WHEN sales > LAG(sales, 1) OVER (ORDER BY date) 
        AND sales > LEAD(sales, 1) OVER (ORDER BY date)
        THEN 'Peak'
        WHEN sales < LAG(sales, 1) OVER (ORDER BY date) 
        AND sales < LEAD(sales, 1) OVER (ORDER BY date)
        THEN 'Valley'
        ELSE 'Normal'
    END as pattern
FROM daily_sales;
```

---

## 🎯 **6. Real-World Applications**

### **Customer RFM Analysis**
```sql
-- Recency, Frequency, Monetary analysis
WITH customer_metrics AS (
    SELECT 
        customer_id,
        MAX(order_date) as last_order_date,
        COUNT(*) as order_frequency,
        SUM(total_amount) as total_monetary
    FROM orders
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT 
        customer_id,
        NTILE(5) OVER (ORDER BY last_order_date DESC) as recency_score,
        NTILE(5) OVER (ORDER BY order_frequency) as frequency_score,
        NTILE(5) OVER (ORDER BY total_monetary) as monetary_score
    FROM customer_metrics
)
SELECT 
    customer_id,
    recency_score,
    frequency_score,
    monetary_score,
    recency_score + frequency_score + monetary_score as rfm_score
FROM rfm_scores;
```

### **Employee Performance Ranking**
```sql
-- Performance ranking with percentiles
SELECT 
    employee_name,
    department,
    performance_score,
    RANK() OVER (ORDER BY performance_score DESC) as overall_rank,
    RANK() OVER (PARTITION BY department ORDER BY performance_score DESC) as dept_rank,
    PERCENT_RANK() OVER (ORDER BY performance_score) as percentile_rank
FROM employees;
```

### **Sales Performance Analysis**
```sql
-- Sales performance by region and time
SELECT 
    region,
    month,
    sales,
    SUM(sales) OVER (PARTITION BY region ORDER BY month) as region_cumulative,
    AVG(sales) OVER (PARTITION BY region) as region_avg,
    sales - AVG(sales) OVER (PARTITION BY region) as deviation_from_avg,
    ROW_NUMBER() OVER (PARTITION BY region ORDER BY sales DESC) as region_rank
FROM regional_sales;
```

---

## 🔧 **7. Performance Optimization**

### **Indexing for Window Functions**
```sql
-- Index for efficient window function execution
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);
CREATE INDEX idx_sales_date ON daily_sales(date);
CREATE INDEX idx_employees_dept_salary ON employees(department, salary DESC);
```

### **Partitioning Strategies**
```sql
-- Partition by date for time-series analysis
CREATE TABLE sales_data (
    date DATE,
    region VARCHAR(50),
    sales DECIMAL(10,2)
) PARTITION BY RANGE (date);

-- Query with window functions on partitioned table
SELECT 
    date,
    region,
    sales,
    SUM(sales) OVER (PARTITION BY region ORDER BY date) as region_cumulative
FROM sales_data
WHERE date >= '2024-01-01';
```

---

## 🚀 **8. Best Practices**

### **Frame Specifications**
```sql
-- Unbounded preceding (all rows from start)
SUM(sales) OVER (ORDER BY date ROWS UNBOUNDED PRECEDING)

-- Bounded window (last 3 rows)
AVG(sales) OVER (ORDER BY date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)

-- Sliding window (3 rows centered)
AVG(sales) OVER (ORDER BY date ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)
```

### **Performance Tips**
```sql
-- Use appropriate frame specifications
-- Avoid unnecessary PARTITION BY clauses
-- Index columns used in ORDER BY
-- Use ROWS instead of RANGE when possible
-- Limit window size for large datasets
```

### **Common Patterns**
```sql
-- Running total
SUM(amount) OVER (ORDER BY date)

-- Moving average
AVG(amount) OVER (ORDER BY date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)

-- Rank within groups
RANK() OVER (PARTITION BY category ORDER BY sales DESC)

-- Compare with previous
LAG(amount, 1) OVER (ORDER BY date)

-- Percentile
PERCENT_RANK() OVER (ORDER BY score)
```

---

## 📊 **9. Troubleshooting**

### **Common Issues**
```sql
-- Issue: Unexpected NULL values
-- Solution: Use COALESCE or handle NULLs explicitly
SELECT 
    date,
    COALESCE(sales, 0) as sales,
    SUM(COALESCE(sales, 0)) OVER (ORDER BY date) as running_total
FROM daily_sales;

-- Issue: Performance with large datasets
-- Solution: Use appropriate indexes and limit window size
SELECT 
    date,
    sales,
    AVG(sales) OVER (
        ORDER BY date 
        ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
    ) as moving_avg_30d
FROM daily_sales;
```

---

---

## 🔬 **Advanced Patterns**

### **Complex Business Intelligence**
```sql
-- Multi-dimensional customer analysis
WITH customer_metrics AS (
    SELECT 
        customer_id,
        order_date,
        amount,
        -- Customer lifetime value
        SUM(amount) OVER (
            PARTITION BY customer_id 
            ORDER BY order_date 
            ROWS UNBOUNDED PRECEDING
        ) as cumulative_value,
        -- Order frequency
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY order_date
        ) as order_number,
        -- Days between orders
        LAG(order_date) OVER (
            PARTITION BY customer_id 
            ORDER BY order_date
        ) as previous_order_date,
        -- Average order value trend
        AVG(amount) OVER (
            PARTITION BY customer_id 
            ORDER BY order_date 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as moving_avg_order_value
    FROM orders
)
SELECT 
    customer_id,
    order_date,
    amount,
    cumulative_value,
    order_number,
    order_date - previous_order_date as days_between_orders,
    moving_avg_order_value,
    CASE 
        WHEN cumulative_value > 1000 THEN 'High Value'
        WHEN cumulative_value > 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END as customer_segment
FROM customer_metrics
WHERE order_date >= CURRENT_DATE - INTERVAL '90 days';
```

### **Time Series Analysis**
```sql
-- Advanced time series with multiple windows
SELECT 
    date,
    sales_amount,
    -- Running total
    SUM(sales_amount) OVER (
        ORDER BY date 
        ROWS UNBOUNDED PRECEDING
    ) as running_total,
    -- 7-day moving average
    AVG(sales_amount) OVER (
        ORDER BY date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as moving_avg_7d,
    -- 30-day moving average
    AVG(sales_amount) OVER (
        ORDER BY date 
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) as moving_avg_30d,
    -- Growth rate
    LAG(sales_amount) OVER (ORDER BY date) as previous_day,
    (sales_amount - LAG(sales_amount) OVER (ORDER BY date)) / 
    LAG(sales_amount) OVER (ORDER BY date) * 100 as growth_rate,
    -- Seasonal comparison
    LAG(sales_amount, 7) OVER (ORDER BY date) as week_ago,
    (sales_amount - LAG(sales_amount, 7) OVER (ORDER BY date)) / 
    LAG(sales_amount, 7) OVER (ORDER BY date) * 100 as weekly_growth
FROM daily_sales
WHERE date >= CURRENT_DATE - INTERVAL '90 days'
ORDER BY date;
```

### **Gap Analysis and Anomaly Detection**
```sql
-- Detect gaps in data and anomalies
WITH data_gaps AS (
    SELECT 
        date,
        value,
        -- Previous value
        LAG(value) OVER (ORDER BY date) as prev_value,
        -- Next value
        LEAD(value) OVER (ORDER BY date) as next_value,
        -- Days since last record
        date - LAG(date) OVER (ORDER BY date) as days_gap,
        -- Moving average for anomaly detection
        AVG(value) OVER (
            ORDER BY date 
            ROWS BETWEEN 5 PRECEDING AND 5 FOLLOWING
        ) as moving_avg,
        -- Standard deviation for anomaly detection
        STDDEV(value) OVER (
            ORDER BY date 
            ROWS BETWEEN 5 PRECEDING AND 5 FOLLOWING
        ) as moving_stddev
    FROM time_series_data
)
SELECT 
    date,
    value,
    days_gap,
    moving_avg,
    moving_stddev,
    -- Anomaly detection (values outside 2 standard deviations)
    CASE 
        WHEN ABS(value - moving_avg) > 2 * moving_stddev THEN 'Anomaly'
        ELSE 'Normal'
    END as anomaly_flag,
    -- Gap detection
    CASE 
        WHEN days_gap > 1 THEN 'Data Gap'
        ELSE 'Continuous'
    END as gap_flag
FROM data_gaps
WHERE date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY date;
```

### **Advanced Ranking and Segmentation**
```sql
-- Complex ranking with multiple criteria
SELECT 
    product_id,
    product_name,
    category,
    sales_amount,
    -- Overall ranking
    RANK() OVER (ORDER BY sales_amount DESC) as overall_rank,
    -- Category ranking
    RANK() OVER (PARTITION BY category ORDER BY sales_amount DESC) as category_rank,
    -- Percentile within category
    PERCENT_RANK() OVER (PARTITION BY category ORDER BY sales_amount) as category_percentile,
    -- Decile ranking
    NTILE(10) OVER (ORDER BY sales_amount DESC) as decile,
    -- Performance vs category average
    sales_amount - AVG(sales_amount) OVER (PARTITION BY category) as vs_category_avg,
    -- Performance vs overall average
    sales_amount - AVG(sales_amount) OVER () as vs_overall_avg,
    -- Performance segment
    CASE 
        WHEN sales_amount > AVG(sales_amount) OVER (PARTITION BY category) * 1.5 THEN 'Top Performer'
        WHEN sales_amount < AVG(sales_amount) OVER (PARTITION BY category) * 0.5 THEN 'Underperformer'
        ELSE 'Average'
    END as performance_segment
FROM products
WHERE sales_amount > 0
ORDER BY overall_rank;
```

---

*Follow this cheatsheet to master advanced analytics and ranking with Window Functions! 🪟* 