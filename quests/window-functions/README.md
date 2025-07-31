# Window Functions Quest 🪟

Master the power of window functions for advanced data analytics and reporting in SQL.

## 🎯 What You'll Learn

Window functions are one of the most powerful features in SQL for data analysis. They allow you to perform calculations across a set of table rows that are somehow related to the current row, without reducing the number of rows returned.

### **Key Concepts:**
- **Ranking functions** - ROW_NUMBER(), RANK(), DENSE_RANK()
- **Aggregation windows** - Running totals, moving averages
- **Partitioned analytics** - Group-based calculations
- **Lead/Lag functions** - Time series analysis
- **Frame specifications** - Custom window boundaries

## 📊 Difficulty Level Evaluation

### **Difficulty Scale:**
- 🟢 **Beginner** - Basic window function concepts (15-30 min)
- 🟡 **Intermediate** - Complex partitioning and framing (30-60 min)
- 🔴 **Advanced** - Performance optimization and edge cases (1-2 hours)
- ⚫ **Expert** - Advanced analytics patterns (2-4 hours)

### **Complete Example Difficulty Table:**

| Category | Example | Difficulty | Description |
|----------|---------|------------|-------------|
| **Basic Ranking** | `01-row-number.sql` | 🟢 Beginner | Simple row numbering |
| | `02-rank-dense-rank.sql` | 🟢 Beginner | Ranking with ties |
| | `03-percent-rank.sql` | 🟡 Intermediate | Percentile calculations |
| **Aggregation Windows** | `01-running-totals.sql` | 🟢 Beginner | Cumulative sums |
| | `02-moving-averages.sql` | 🟡 Intermediate | Rolling averages |
| | `03-cumulative-sums.sql` | 🟡 Intermediate | Complex aggregations |
| **Partitioned Analytics** | `01-sales-by-category.sql` | 🟡 Intermediate | Category-based ranking |
| | `02-customer-segmentation.sql` | 🔴 Advanced | Customer analysis |
| | `03-performance-comparison.sql` | 🔴 Advanced | Comparative analytics |
| **Advanced Patterns** | `01-lead-lag-analysis.sql` | 🔴 Advanced | Time series analysis |
| | `02-gap-analysis.sql` | ⚫ Expert | Gap detection patterns |
| | `03-trend-detection.sql` | ⚫ Expert | Trend identification |

## 🚀 Quick Start

### **Prerequisites**
- Basic SQL knowledge (SELECT, FROM, WHERE, ORDER BY)
- Understanding of GROUP BY and aggregate functions
- PostgreSQL 12+ (for advanced features)

### **1. Start with Basic Ranking**
```sql
-- Simple row numbering
SELECT 
    product_name,
    price,
    ROW_NUMBER() OVER (ORDER BY price DESC) as rank
FROM products;
```

### **2. Explore Partitioned Analytics**
```sql
-- Ranking within categories
SELECT 
    product_name,
    category,
    price,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC) as category_rank
FROM products;
```

### **3. Master Aggregation Windows**
```sql
-- Running totals
SELECT 
    date,
    sales_amount,
    SUM(sales_amount) OVER (ORDER BY date) as running_total
FROM daily_sales;
```

## 📚 Learning Path

### **🟢 Beginner Path (Start Here)**
1. `01-row-number.sql` - Understand basic window functions
2. `01-running-totals.sql` - Learn aggregation windows
3. `02-rank-dense-rank.sql` - Handle ranking with ties
4. `01-sales-by-category.sql` - Apply partitioning

### **🟡 Intermediate Path**
1. `02-moving-averages.sql` - Complex aggregations
2. `03-percent-rank.sql` - Percentile calculations
3. `02-customer-segmentation.sql` - Business analytics
4. `03-cumulative-sums.sql` - Advanced aggregations

### **🔴 Advanced Path**
1. `03-performance-comparison.sql` - Comparative analysis
2. `01-lead-lag-analysis.sql` - Time series patterns
3. `02-gap-analysis.sql` - Gap detection
4. `03-trend-detection.sql` - Trend analysis

## 🎮 Running Examples

### **Option 1: Docker (Recommended)**
```bash
# Start the environment
docker-compose up -d

# Run all window function examples
./scripts/run-examples.sh quest window-functions

# Run specific category
./scripts/run-examples.sh quest window-functions basic-ranking
```

### **Option 2: Manual Execution**
```bash
# Connect to PostgreSQL
psql -h localhost -p 5433 -U postgres -d sql_adventure_db

# Run individual examples
\i quests/window-functions/01-basic-ranking/01-row-number.sql
```

## 🏢 Real-World Applications

### **Business Analytics**
- **Sales ranking** - Top performers by region/category
- **Customer segmentation** - RFM analysis and scoring
- **Performance tracking** - Employee/product rankings
- **Financial reporting** - Running totals and trends

### **Data Science**
- **Time series analysis** - Moving averages and trends
- **Statistical analysis** - Percentiles and distributions
- **Anomaly detection** - Outlier identification
- **Predictive modeling** - Feature engineering

### **Reporting & BI**
- **Executive dashboards** - KPI tracking and rankings
- **Operational reports** - Daily/weekly/monthly summaries
- **Comparative analysis** - Period-over-period comparisons
- **Trend analysis** - Growth and decline patterns

## 🔧 Key Window Function Concepts

### **1. OVER Clause**
```sql
-- Basic window function
SELECT 
    column1,
    column2,
    window_function() OVER (window_definition) as result
FROM table_name;
```

### **2. PARTITION BY**
```sql
-- Partition by category
SELECT 
    product_name,
    category,
    price,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC) as rank
FROM products;
```

### **3. ORDER BY**
```sql
-- Order by date for time series
SELECT 
    date,
    sales,
    SUM(sales) OVER (ORDER BY date) as running_total
FROM daily_sales;
```

### **4. Frame Specification**
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
```

## 📊 Performance Considerations

### **Optimization Tips**
- **Use appropriate indexes** on ORDER BY columns
- **Limit window size** for large datasets
- **Consider materialized views** for complex calculations
- **Monitor execution plans** for performance issues

### **Common Pitfalls**
- **Unbounded windows** can cause performance issues
- **Complex frame specifications** may be slow
- **Large partitions** can consume significant memory
- **Missing indexes** on partition/order columns

## 🎯 Advanced Patterns

### **1. Gap Analysis**
```sql
-- Find gaps in sequences
WITH gaps AS (
    SELECT 
        id,
        LAG(id) OVER (ORDER BY id) as prev_id,
        id - LAG(id) OVER (ORDER BY id) as gap_size
    FROM sequence_table
)
SELECT * FROM gaps WHERE gap_size > 1;
```

### **2. Trend Detection**
```sql
-- Detect trends using moving averages
SELECT 
    date,
    value,
    AVG(value) OVER (ORDER BY date ROWS 6 PRECEDING) as ma_7d,
    CASE 
        WHEN value > AVG(value) OVER (ORDER BY date ROWS 6 PRECEDING) 
        THEN 'Above Trend'
        ELSE 'Below Trend'
    END as trend
FROM time_series_data;
```

### **3. Percentile Analysis**
```sql
-- Calculate percentiles
SELECT 
    product_name,
    price,
    PERCENT_RANK() OVER (ORDER BY price) as price_percentile,
    NTILE(4) OVER (ORDER BY price) as price_quartile
FROM products;
```

## 🤝 Contributing

We welcome contributions to expand the Window Functions quest! Please ensure:

- **Examples are idempotent** (safe to run multiple times)
- **Include clear comments** explaining the concepts
- **Use realistic data** that demonstrates real-world scenarios
- **Follow the difficulty rating system**
- **Test thoroughly** before submitting

## 📚 Further Reading

- [PostgreSQL Window Functions Documentation](https://www.postgresql.org/docs/current/tutorial-window.html)
- [SQL Server Window Functions](https://docs.microsoft.com/en-us/sql/t-sql/queries/select-over-clause-transact-sql)
- [Oracle Window Functions](https://docs.oracle.com/en/database/oracle/oracle-database/19/sqlrf/Analytic-Functions.html)

---

*Ready to master window functions? Start with the [Basic Ranking examples](./01-basic-ranking/)! 🚀* 