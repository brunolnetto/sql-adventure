# Window Functions Quest 🪟

Master advanced analytics, ranking, and time series analysis with Window Functions.

## 📊 Overview

- **112 Examples** across 5 categories
- **Difficulty**: Beginner → Expert
- **Status**: ✅ Complete
- **Time**: 5-60 min per example

## 🚀 Quick Start

```bash
# Start environment
docker-compose up -d

# Run all examples
./scripts/run-examples.sh quest window-functions

# Run specific category
./scripts/run-examples.sh quest window-functions basic-ranking
```

## 📚 Categories

### **01-basic-ranking/** 🟢 **Beginner**
- `01-row-number.sql` - Simple row numbering (3 examples)
- `02-rank-dense-rank.sql` - RANK and DENSE_RANK basics (3 examples)

### **02-advanced-ranking/** 🟡 **Intermediate**
- `01-ntile-analysis.sql` - NTILE and advanced ranking (4 examples)
- `02-percentile-analysis.sql` - PERCENT_RANK basics (4 examples)
- `03-salary-analysis.sql` - Complex salary analysis (6 examples)

### **03-aggregation-windows/** 🟡 **Intermediate**
- `01-running-totals.sql` - Cumulative sums (10 examples)
- `02-moving-averages.sql` - Rolling averages (5 examples)
- `03-cumulative-sums.sql` - Complex aggregations (5 examples)

### **04-partitioned-analytics/** 🔴 **Advanced**
- `01-basic-category-ranking.sql` - Category-based ranking (3 examples)
- `02-category-performance-analysis.sql` - Performance metrics (3 examples)
- `03-category-comparisons.sql` - Cross-category analysis (4 examples)
- `04-customer-rfm-analysis.sql` - RFM analysis (3 examples)
- `05-customer-segmentation.sql` - Customer segmentation (3 examples)
- `06-customer-retention-analysis.sql` - Retention analysis (2 examples)
- `07-quarterly-performance.sql` - Quarterly analysis (3 examples)
- `08-employee-performance-trends.sql` - Employee trends (3 examples)
- `09-performance-forecasting.sql` - Performance forecasting (2 examples)

### **05-advanced-patterns/** ⚫ **Expert**
- `01-lead-lag-analysis.sql` - Time series analysis (8 examples)
- `02-gap-analysis.sql` - Gap detection patterns (8 examples)
- `03-trend-detection.sql` - Trend identification (6 examples)

## 🎯 Learning Path

### **🟢 Beginner (Start Here)**
1. `01-row-number.sql` - Understand basic window functions
2. `02-rank-dense-rank.sql` - Handle ranking with ties
3. `01-running-totals.sql` - Learn aggregation windows
4. `01-basic-category-ranking.sql` - Apply partitioning

### **🟡 Intermediate**
1. `01-ntile-analysis.sql` - NTILE and advanced ranking
2. `02-percentile-analysis.sql` - Percentile calculations
3. `02-moving-averages.sql` - Complex aggregations
4. `02-category-performance-analysis.sql` - Performance metrics

### **🔴 Advanced**
1. `03-salary-analysis.sql` - Complex salary analysis
2. `04-customer-rfm-analysis.sql` - RFM analysis
3. `05-customer-segmentation.sql` - Customer segmentation
4. `07-quarterly-performance.sql` - Quarterly analysis

### **⚫ Expert**
1. `01-lead-lag-analysis.sql` - Time series analysis
2. `02-gap-analysis.sql` - Gap detection patterns
3. `03-trend-detection.sql` - Trend identification
4. `09-performance-forecasting.sql` - Performance forecasting

## 🔧 Key Concepts

```sql
-- Basic window function
SELECT 
    column1,
    column2,
    window_function() OVER (window_definition) as result
FROM table_name;

-- Partition by category
SELECT 
    product_name,
    category,
    price,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC) as rank
FROM products;

-- Running total
SELECT 
    date,
    sales,
    SUM(sales) OVER (ORDER BY date) as running_total
FROM daily_sales;

-- Moving average
SELECT 
    date,
    sales,
    AVG(sales) OVER (
        ORDER BY date 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) as moving_avg_3d
FROM daily_sales;
```

## 🏢 Real-World Applications

- **Business Analytics**: Sales ranking, customer segmentation, performance tracking
- **Data Science**: Time series analysis, statistical analysis, anomaly detection
- **Reporting & BI**: Executive dashboards, operational reports, trend analysis

## 📊 Performance Tips

- **Use appropriate indexes** on ORDER BY columns
- **Limit window size** for large datasets
- **Consider materialized views** for complex calculations
- **Monitor execution plans** for performance issues

---

*Ready to master window functions? Start with [Basic Ranking](./01-basic-ranking/)! 🚀* 