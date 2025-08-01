# Window Functions Quest 🪟

Master the power of window functions for advanced data analytics and reporting in SQL.

## ✅ **COMPLETION STATUS: 100% COMPLETE** 🎉

**Total Examples: 112** | **Categories: 5** | **Files: 23**

### **📊 Progress Summary:**
- ✅ **Basic Ranking** - 2/2 files (6 examples)
- ✅ **Advanced Ranking** - 3/3 files (14 examples)
- ✅ **Aggregation Windows** - 3/3 files (20 examples)  
- ✅ **Partitioned Analytics** - 9/9 files (26 examples)
- ✅ **Advanced Patterns** - 3/3 files (22 examples)

**🎯 All examples tested and validated! Ready for learning.**

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
- 🟢 **Beginner** - Basic window function concepts (5-15 min)
- 🟡 **Intermediate** - Complex partitioning and framing (10-25 min)
- 🔴 **Advanced** - Performance optimization and edge cases (15-45 min)
- ⚫ **Expert** - Advanced analytics patterns (30-60 min)

### **📈 Difficulty Distribution by Examples:**
- 🟢 **Beginner**: 2 examples (**1.8%**) - Perfect starting point for new learners
- 🟡 **Intermediate**: 10 examples (**8.9%**) - Building complexity and real-world applications
- 🔴 **Advanced**: 8 examples (**7.1%**) - Complex patterns and performance considerations
- ⚫ **Expert**: 3 examples (**2.7%**) - Cutting-edge techniques and optimization

**💡 Learning Tip**: Start with Beginner examples and progress gradually. Each level builds upon the previous one, ensuring a solid foundation before tackling advanced concepts.

### **🎯 Difficulty Percentage Guide:**
- **10-25%**: Perfect for beginners - focus on understanding basic concepts
- **30-60%**: Ideal for intermediate learners - build confidence with real applications
- **65-85%**: Advanced learners - tackle complex patterns and optimization
- **90-100%**: Expert level - master cutting-edge techniques and performance tuning

**📚 Progression Strategy**: Aim to complete examples within 10-15% of your current comfort level for optimal learning progression.

### **Complete Example Difficulty Table:**

| Category | File | Difficulty | Description | Examples |
|----------|------|------------|-------------|----------|
| **Basic Ranking** | `01-row-number.sql` | 🟢 Beginner | Simple row numbering | 3 |
| | `02-rank-dense-rank.sql` | 🟢 Beginner | RANK and DENSE_RANK basics | 3 |
| **Advanced Ranking** | `01-ntile-analysis.sql` | 🟡 Intermediate | NTILE and advanced ranking | 4 |
| | `02-percentile-analysis.sql` | 🟡 Intermediate | PERCENT_RANK basics | 4 |
| | `03-salary-analysis.sql` | 🔴 Advanced | Complex salary analysis | 6 |
| **Aggregation Windows** | `01-running-totals.sql` | 🟢 Beginner | Cumulative sums | 10 |
| | `02-moving-averages.sql` | 🟡 Intermediate | Rolling averages | 5 |
| | `03-cumulative-sums.sql` | 🟡 Intermediate | Complex aggregations | 5 |
| **Partitioned Analytics** | `01-basic-category-ranking.sql` | 🟡 Intermediate | Category-based ranking | 3 |
| | `02-category-performance-analysis.sql` | 🟡 Intermediate | Performance metrics | 3 |
| | `03-category-comparisons.sql` | 🟡 Intermediate | Cross-category analysis | 4 |
| | `04-customer-rfm-analysis.sql` | 🔴 Advanced | RFM analysis | 3 |
| | `05-customer-segmentation.sql` | 🔴 Advanced | Customer segmentation | 3 |
| | `06-customer-retention-analysis.sql` | 🔴 Advanced | Retention analysis | 2 |
| | `07-quarterly-performance.sql` | 🔴 Advanced | Quarterly analysis | 3 |
| | `08-employee-performance-trends.sql` | 🔴 Advanced | Employee trends | 3 |
| | `09-performance-forecasting.sql` | 🔴 Advanced | Performance forecasting | 2 |
| **Advanced Patterns** | `01-lead-lag-analysis.sql` | ⚫ Expert | Time series analysis | 8 |
| | `02-gap-analysis.sql` | ⚫ Expert | Gap detection patterns | 8 |
| | `03-trend-detection.sql` | ⚫ Expert | Trend identification | 6 |

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
2. `02-rank-dense-rank.sql` - Handle ranking with ties
3. `01-running-totals.sql` - Learn aggregation windows
4. `01-basic-category-ranking.sql` - Apply partitioning

### **🟡 Intermediate Path**
1. `01-ntile-analysis.sql` - NTILE and advanced ranking
2. `02-percentile-analysis.sql` - Percentile calculations
3. `02-moving-averages.sql` - Complex aggregations
4. `02-category-performance-analysis.sql` - Performance metrics

### **🔴 Advanced Path**
1. `03-salary-analysis.sql` - Complex salary analysis
2. `04-customer-rfm-analysis.sql` - RFM analysis
3. `05-customer-segmentation.sql` - Customer segmentation
4. `07-quarterly-performance.sql` - Quarterly analysis

### **⚫ Expert Path**
1. `01-lead-lag-analysis.sql` - Time series analysis
2. `02-gap-analysis.sql` - Gap detection patterns
3. `03-trend-detection.sql` - Trend identification
4. `09-performance-forecasting.sql` - Performance forecasting

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

## 📁 File Organization

### **01-basic-ranking/**
- `01-row-number.sql` - Basic row numbering (3 examples)
- `02-rank-dense-rank.sql` - Ranking with ties (3 examples)

### **02-advanced-ranking/**
- `01-ntile-analysis.sql` - NTILE and advanced ranking (4 examples)
- `02-percentile-analysis.sql` - PERCENT_RANK basics (4 examples)
- `03-salary-analysis.sql` - Complex salary analysis (6 examples)

### **03-aggregation-windows/**
- `01-running-totals.sql` - Cumulative sums (4 examples)
- `02-moving-averages.sql` - Rolling averages (4 examples)
- `03-cumulative-sums.sql` - Complex aggregations (4 examples)

### **04-partitioned-analytics/**
- `01-basic-category-ranking.sql` - Category-based ranking (3 examples)
- `02-category-performance-analysis.sql` - Performance metrics (3 examples)
- `03-category-comparisons.sql` - Cross-category analysis (4 examples)
- `04-customer-rfm-analysis.sql` - RFM analysis (3 examples)
- `05-customer-segmentation.sql` - Customer segmentation (3 examples)
- `06-customer-retention-analysis.sql` - Retention analysis (2 examples)
- `07-quarterly-performance.sql` - Quarterly analysis (3 examples)
- `08-employee-performance-trends.sql` - Employee trends (3 examples)
- `09-performance-forecasting.sql` - Performance forecasting (2 examples)

### **05-advanced-patterns/**
- `01-lead-lag-analysis.sql` - Time series analysis (8 examples)
- `02-gap-analysis.sql` - Gap detection patterns (8 examples)
- `03-trend-detection.sql` - Trend identification (6 examples)

## 🤝 Contributing

We welcome contributions to expand the Window Functions quest! Please ensure:

- **Examples are idempotent** (safe to run multiple times)
- **Include clear comments** explaining the concepts
- **Use realistic data** that demonstrates real-world scenarios
- **Follow the difficulty rating system**
- **Test thoroughly** before submitting
- **Keep files focused** with 3-4 examples per file
- **Maintain clear learning progression** between files

## 📚 Further Reading

- [PostgreSQL Window Functions Documentation](https://www.postgresql.org/docs/current/tutorial-window.html)
- [SQL Server Window Functions](https://docs.microsoft.com/en-us/sql/t-sql/queries/select-over-clause-transact-sql)
- [Oracle Window Functions](https://docs.oracle.com/en/database/oracle/oracle-database/19/sqlrf/Analytic-Functions.html)

---

*Ready to master window functions? Start with the [Basic Ranking examples](./01-basic-ranking/)! 🚀* 