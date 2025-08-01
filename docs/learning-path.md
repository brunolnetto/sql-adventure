# Learning Path 📖

Structured progression from beginner to advanced SQL concepts with 179+ examples from SQL Adventure.

## 🥇 Beginner Level

### 1. Basic SQL Concepts
- **SELECT** - Retrieving data from tables
- **INSERT** - Adding new records
- **UPDATE** - Modifying existing data
- **DELETE** - Removing records
- **WHERE** - Filtering results

### 2. Joins and Relationships
- **INNER JOIN** - Matching records from both tables
- **LEFT JOIN** - All records from left table + matching right
- **RIGHT JOIN** - All records from right table + matching left
- **FULL JOIN** - All records from both tables
- **CROSS JOIN** - Cartesian product of tables

### 3. Aggregation Functions
- **GROUP BY** - Grouping results
- **HAVING** - Filtering grouped results
- **COUNT, SUM, AVG, MIN, MAX** - Statistical functions

## 🥈 Intermediate Level

### 1. Recursive CTEs (31 Examples)
**Start Here**: [Recursive CTE Cheatsheet](./cheatsheets/recursive-cte.md)

#### 🏗️ Hierarchical Data Traversal (7 examples)
- **Employee Hierarchy** - [01-employee-hierarchy.sql](../quests/recursive-cte/01-hierarchical-graph-traversal/01-employee-hierarchy.sql)
- **Bill of Materials** - [02-bill-of-materials.sql](../quests/recursive-cte/01-hierarchical-graph-traversal/02-bill-of-materials.sql)
- **Category Tree** - [03-category-tree.sql](../quests/recursive-cte/01-hierarchical-graph-traversal/03-category-tree.sql)
- **Graph Reachability** - [04-graph-reachability.sql](../quests/recursive-cte/01-hierarchical-graph-traversal/04-graph-reachability.sql)
- **Dependency Resolution** - [05-dependency-resolution.sql](../quests/recursive-cte/01-hierarchical-graph-traversal/05-dependency-resolution.sql)
- **Filesystem Hierarchy** - [06-filesystem-hierarchy.sql](../quests/recursive-cte/01-hierarchical-graph-traversal/06-filesystem-hierarchy.sql)
- **Family Tree** - [07-family-tree.sql](../quests/recursive-cte/01-hierarchical-graph-traversal/07-family-tree.sql)

#### 🔄 Iteration & Loops (7 examples)
- **Number Series** - [01-number-series.sql](../quests/recursive-cte/02-iteration-loops/01-number-series.sql)
- **Date Series** - [02-date-series.sql](../quests/recursive-cte/02-iteration-loops/02-date-series.sql)
- **Fibonacci Sequence** - [03-fibonacci-sequence.sql](../quests/recursive-cte/02-iteration-loops/03-fibonacci-sequence.sql)
- **Collatz Sequence** - [04-collatz-sequence.sql](../quests/recursive-cte/02-iteration-loops/04-collatz-sequence.sql)
- **Base Conversion** - [05-base-conversion.sql](../quests/recursive-cte/02-iteration-loops/05-base-conversion.sql)
- **Factorial Calculation** - [06-factorial-calculation.sql](../quests/recursive-cte/02-iteration-loops/06-factorial-calculation.sql)
- **Running Total** - [07-running-total.sql](../quests/recursive-cte/02-iteration-loops/07-running-total.sql)

#### 🛤️ Path Finding & Analysis (3 examples)
- **Shortest Path** - [01-shortest-path.sql](../quests/recursive-cte/03-path-finding-analysis/01-shortest-path.sql)
- **Topological Sort** - [02-topological-sort.sql](../quests/recursive-cte/03-path-finding-analysis/02-topological-sort.sql)
- **Cycle Detection** - [03-cycle-detection.sql](../quests/recursive-cte/03-path-finding-analysis/03-cycle-detection.sql)

#### 🔧 Data Transformation (3 examples)
- **String Splitting** - [01-string-splitting.sql](../quests/recursive-cte/04-data-transformation-parsing/01-string-splitting.sql)
- **Transitive Closure** - [02-transitive-closure.sql](../quests/recursive-cte/04-data-transformation-parsing/02-transitive-closure.sql)
- **JSON Parsing** - [03-json-parsing.sql](../quests/recursive-cte/04-data-transformation-parsing/03-json-parsing.sql)

#### 🎮 Simulation & State Machines (2 examples)
- **Inventory Simulation** - [01-inventory-simulation.sql](../quests/recursive-cte/05-simulation-state-machines/01-inventory-simulation.sql)
- **Game Simulation** - [02-game-simulation.sql](../quests/recursive-cte/05-simulation-state-machines/02-game-simulation.sql)

#### 🔧 Data Repair & Healing (3 examples)
- **Sequence Gaps** - [01-sequence-gaps.sql](../quests/recursive-cte/06-data-repair-healing/01-sequence-gaps.sql)
- **Forward Fill Nulls** - [02-forward-fill-nulls.sql](../quests/recursive-cte/06-data-repair-healing/02-forward-fill-nulls.sql)
- **Interval Coalescing** - [03-interval-coalescing.sql](../quests/recursive-cte/06-data-repair-healing/03-interval-coalescing.sql)

#### 📊 Mathematical & Theoretical (3 examples)
- **Fibonacci Sequence** - [01-fibonacci-sequence.sql](../quests/recursive-cte/07-mathematical-theoretical/01-fibonacci-sequence.sql)
- **Prime Numbers** - [02-prime-numbers.sql](../quests/recursive-cte/07-mathematical-theoretical/02-prime-numbers.sql)
- **Permutation Generation** - [03-permutation-generation.sql](../quests/recursive-cte/07-mathematical-theoretical/03-permutation-generation.sql)

#### 🎯 Bonus Quirky Examples (3 examples)
- **Work Streak** - [01-work-streak.sql](../quests/recursive-cte/08-bonus-quirky-examples/01-work-streak.sql)
- **Password Generator** - [02-password-generator.sql](../quests/recursive-cte/08-bonus-quirky-examples/02-password-generator.sql)
- **Spiral Matrix** - [03-spiral-matrix.sql](../quests/recursive-cte/08-bonus-quirky-examples/03-spiral-matrix.sql)

### 2. Window Functions (112 Examples)
**Advanced Analytics**: [Window Functions Quest](../quests/window-functions/)

#### 🏆 Basic Ranking (2 examples)
- **Row Number** - [01-row-number.sql](../quests/window-functions/01-basic-ranking/01-row-number.sql)
- **Rank & Dense Rank** - [02-rank-dense-rank.sql](../quests/window-functions/01-basic-ranking/02-rank-dense-rank.sql)

#### 🎯 Advanced Ranking (3 examples)
- **NTILE Analysis** - [01-ntile-analysis.sql](../quests/window-functions/02-advanced-ranking/01-ntile-analysis.sql)
- **Percentile Analysis** - [02-percentile-analysis.sql](../quests/window-functions/02-advanced-ranking/02-percentile-analysis.sql)
- **Salary Analysis** - [03-salary-analysis.sql](../quests/window-functions/02-advanced-ranking/03-salary-analysis.sql)

#### 📊 Aggregation Windows (3 examples)
- **Running Totals** - [01-running-totals.sql](../quests/window-functions/03-aggregation-windows/01-running-totals.sql)
- **Moving Averages** - [02-moving-averages.sql](../quests/window-functions/03-aggregation-windows/02-moving-averages.sql)
- **Cumulative Sums** - [03-cumulative-sums.sql](../quests/window-functions/03-aggregation-windows/03-cumulative-sums.sql)

#### 🎨 Partitioned Analytics (12 examples)
- **Sales by Category** - [01-sales-by-category.sql](../quests/window-functions/04-partitioned-analytics/01-sales-by-category.sql)
- **Customer Segmentation** - [02-customer-segmentation.sql](../quests/window-functions/04-partitioned-analytics/02-customer-segmentation.sql)
- **Performance Comparison** - [03-performance-comparison.sql](../quests/window-functions/04-partitioned-analytics/03-performance-comparison.sql)
- **Customer RFM Analysis** - [04-customer-rfm-analysis.sql](../quests/window-functions/04-partitioned-analytics/04-customer-rfm-analysis.sql)
- **Customer Retention Analysis** - [06-customer-retention-analysis.sql](../quests/window-functions/04-partitioned-analytics/06-customer-retention-analysis.sql)
- **Quarterly Performance** - [07-quarterly-performance.sql](../quests/window-functions/04-partitioned-analytics/07-quarterly-performance.sql)
- **Employee Performance Trends** - [08-employee-performance-trends.sql](../quests/window-functions/04-partitioned-analytics/08-employee-performance-trends.sql)
- **Performance Forecasting** - [09-performance-forecasting.sql](../quests/window-functions/04-partitioned-analytics/09-performance-forecasting.sql)

#### 🔬 Advanced Patterns (3 examples)
- **Lead Lag Analysis** - [01-lead-lag-analysis.sql](../quests/window-functions/05-advanced-patterns/01-lead-lag-analysis.sql)
- **Gap Analysis** - [02-gap-analysis.sql](../quests/window-functions/05-advanced-patterns/02-gap-analysis.sql)
- **Trend Detection** - [03-trend-detection.sql](../quests/window-functions/05-advanced-patterns/03-trend-detection.sql)

### 3. JSON Operations (12 Examples)
**Modern PostgreSQL**: [JSON Operations Quest](../quests/json-operations/)

#### 🎯 Basic JSON (3 examples)
- **JSON Parsing** - [01-json-parsing.sql](../quests/json-operations/01-basic-json/01-json-parsing.sql)
- **JSON Generation** - [02-json-generation.sql](../quests/json-operations/01-basic-json/02-json-generation.sql)
- **JSON Validation** - [03-json-validation.sql](../quests/json-operations/01-basic-json/03-json-validation.sql)

#### 🔍 JSON Queries (3 examples)
- **Nested Extraction** - [01-nested-extraction.sql](../quests/json-operations/02-json-queries/01-nested-extraction.sql)
- **Array Operations** - [02-array-operations.sql](../quests/json-operations/02-json-queries/02-array-operations.sql)
- **JSON Aggregation** - [03-json-aggregation.sql](../quests/json-operations/02-json-queries/03-json-aggregation.sql)

#### 🌍 Real-world Applications (3 examples)
- **API Data Processing** - [01-api-data-processing.sql](../quests/json-operations/03-real-world-applications/01-api-data-processing.sql)
- **Configuration Management** - [02-configuration-management.sql](../quests/json-operations/03-real-world-applications/02-configuration-management.sql)
- **Log Analysis** - [03-log-analysis.sql](../quests/json-operations/03-real-world-applications/03-log-analysis.sql)

#### ⚡ Advanced Patterns (3 examples)
- **Schema Validation** - [01-json-schema-validation.sql](../quests/json-operations/04-advanced-patterns/01-json-schema-validation.sql)
- **JSON Transformation** - [02-json-transformation.sql](../quests/json-operations/04-advanced-patterns/02-json-transformation.sql)
- **JSON Performance** - [03-json-performance.sql](../quests/json-operations/04-advanced-patterns/03-json-performance.sql)

### 4. Performance Tuning (12 Examples)
**Production Optimization**: [Performance Tuning Quest](../quests/performance-tuning/)

#### ⚡ Query Optimization (3 examples)
- **Basic Optimization** - [01-basic-optimization.sql](../quests/performance-tuning/01-query-optimization/01-basic-optimization.sql)
- **Aggregation Optimization** - [02-aggregation-optimization.sql](../quests/performance-tuning/01-query-optimization/02-aggregation-optimization.sql)
- **Subquery Optimization** - [03-subquery-optimization.sql](../quests/performance-tuning/01-query-optimization/03-subquery-optimization.sql)

#### 📊 Indexing Strategies (3 examples)
- **Basic Indexing** - [01-basic-indexing.sql](../quests/performance-tuning/02-indexing-strategies/01-basic-indexing.sql)
- **Advanced Indexing** - [02-advanced-indexing.sql](../quests/performance-tuning/02-indexing-strategies/02-advanced-indexing.sql)

#### 🔍 Execution Plans (3 examples)
- **Plan Analysis** - [01-plan-analysis.sql](../quests/performance-tuning/03-execution-plans/01-plan-analysis.sql)
- **Statistics Analysis** - [02-statistics-analysis.sql](../quests/performance-tuning/03-execution-plans/02-statistics-analysis.sql)

#### 📈 Performance Monitoring (3 examples)
- **Slow Query Analysis** - [01-slow-query-analysis.sql](../quests/performance-tuning/04-performance-monitoring/01-slow-query-analysis.sql)
- **Resource Monitoring** - [02-resource-monitoring.sql](../quests/performance-tuning/04-performance-monitoring/02-resource-monitoring.sql)

### 5. Data Modeling (12 Examples)
**Database Design**: [Data Modeling Quest](../quests/data-modeling/)

#### 🏗️ Normalization Patterns (3 examples)
- **Basic Normalization** - [01-basic-normalization.sql](../quests/data-modeling/01-normalization-patterns/01-basic-normalization.sql)
- **Advanced Normalization** - [02-advanced-normalization.sql](../quests/data-modeling/01-normalization-patterns/02-advanced-normalization.sql)
- **Normalization Trade-offs** - [03-normalization-trade-offs.sql](../quests/data-modeling/01-normalization-patterns/03-normalization-trade-offs.sql)

#### 📊 Denormalization Strategies (3 examples)
- **Performance Denormalization** - [01-performance-denormalization.sql](../quests/data-modeling/02-denormalization-strategies/01-performance-denormalization.sql)
- **Analytics Denormalization** - [02-analytics-denormalization.sql](../quests/data-modeling/02-denormalization-strategies/02-analytics-denormalization.sql)
- **Hybrid Approaches** - [03-hybrid-approaches.sql](../quests/data-modeling/02-denormalization-strategies/03-hybrid-approaches.sql)

#### 🔧 Schema Design Principles (3 examples)
- **Entity Relationship** - [01-entity-relationship.sql](../quests/data-modeling/03-schema-design-principles/01-entity-relationship.sql)
- **Data Integrity** - [02-data-integrity.sql](../quests/data-modeling/03-schema-design-principles/02-data-integrity.sql)
- **Schema Evolution** - [03-schema-evolution.sql](../quests/data-modeling/03-schema-design-principles/03-schema-evolution.sql)

#### 🌍 Real-world Applications (3 examples)
- **E-commerce Model** - [01-ecommerce-model.sql](../quests/data-modeling/04-real-world-applications/01-ecommerce-model.sql)
- **Healthcare Model** - [02-healthcare-model.sql](../quests/data-modeling/04-real-world-applications/02-healthcare-model.sql)
- **Financial Model** - [03-financial-model.sql](../quests/data-modeling/04-real-world-applications/03-financial-model.sql)

## 🥉 Advanced Level

### 1. Advanced Joins
- **Self-joins** - Joining table to itself
- **Cross joins** - Cartesian products
- **Lateral joins** - Correlated subqueries
- **Natural joins** - Automatic column matching

### 2. Subqueries
- **Correlated subqueries** - Dependent on outer query
- **Non-correlated subqueries** - Independent execution
- **EXISTS/NOT EXISTS** - Existence checks
- **IN/NOT IN** - Set membership

### 3. Data Transformation
- **Pivot tables** - Crosstab operations
- **Data cleaning** - Validation and repair
- **ETL workflows** - Extract, transform, load
- **Complex aggregations** - Advanced calculations

## 🚀 Getting Started

### Step 1: Environment Setup
```bash
# Clone the repository
git clone <repository-url>
cd sql-adventure

# Start the Docker environment
docker-compose up -d

# Connect to PostgreSQL
PGPASSWORD=postgres psql -h localhost -p 5433 -U postgres -d sql_adventure_db
```

### Step 2: Choose Your Path

#### **🎯 For Interviews & Quick Reference**
1. **[Recursive CTE Cheatsheet](./cheatsheets/recursive-cte.md)** - Complete reference
2. **Practice with examples** - Run any of the 179+ working examples
3. **Master patterns** - Understand base case + recursive case structure

#### **📚 For Deep Learning**
1. **Follow the progression** - Start with Recursive CTEs, then Window Functions
2. **Explore by category** - Choose your focus area
3. **Apply to your industry** - See [Use Cases](./use-cases.md) for real-world applications

### Step 3: Progress Through Quests

1. **🔄 Recursive CTE** - Start with hierarchical data and iteration
2. **🪟 Window Functions** - Master advanced analytics and ranking
3. **🎯 JSON Operations** - Learn modern PostgreSQL features
4. **⚡ Performance Tuning** - Optimize for production environments
5. **🏗️ Data Modeling** - Design efficient database schemas

## 📊 Progress Tracking

### Beginner Milestones
- [ ] Complete basic SQL concepts
- [ ] Run first recursive CTE example
- [ ] Understand base case vs recursive case
- [ ] Complete 5 simple examples

### Intermediate Milestones
- [ ] Complete all 31 recursive CTE examples
- [ ] Complete all 112 window function examples
- [ ] Complete all 12 JSON operation examples
- [ ] Complete all 12 performance tuning examples
- [ ] Complete all 12 data modeling examples

### Advanced Milestones
- [ ] Optimize query performance
- [ ] Design complex data models
- [ ] Create custom recursive patterns
- [ ] Master advanced window function patterns
- [ ] Mentor others in the community

---

*Ready to start your SQL Adventure? Begin with the [Recursive CTE Cheatsheet](./cheatsheets/recursive-cte.md)! 🚀*
