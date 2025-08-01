# Learning Path 📖

A structured progression from beginner to advanced SQL concepts with specific examples from SQL Adventure.

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
- **Window Functions** - Advanced analytics
- **COUNT, SUM, AVG, MIN, MAX** - Statistical functions

## 🥈 Intermediate Level

### 1. Recursive CTEs (31 Examples Available!)
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

### 2. Window Functions (23 Examples Available!)
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
- **Basic Category Ranking** - [01-basic-category-ranking.sql](../quests/window-functions/04-partitioned-analytics/01-basic-category-ranking.sql)
- **Category Performance Analysis** - [02-category-performance-analysis.sql](../quests/window-functions/04-partitioned-analytics/02-category-performance-analysis.sql)
- **Category Comparisons** - [03-category-comparisons.sql](../quests/window-functions/04-partitioned-analytics/03-category-comparisons.sql)
- **Customer RFM Analysis** - [04-customer-rfm-analysis.sql](../quests/window-functions/04-partitioned-analytics/04-customer-rfm-analysis.sql)
- **Customer Segmentation** - [05-customer-segmentation.sql](../quests/window-functions/04-partitioned-analytics/05-customer-segmentation.sql)
- **Customer Retention Analysis** - [06-customer-retention-analysis.sql](../quests/window-functions/04-partitioned-analytics/06-customer-retention-analysis.sql)
- **Quarterly Performance** - [07-quarterly-performance.sql](../quests/window-functions/04-partitioned-analytics/07-quarterly-performance.sql)
- **Employee Performance Trends** - [08-employee-performance-trends.sql](../quests/window-functions/04-partitioned-analytics/08-employee-performance-trends.sql)
- **Performance Forecasting** - [09-performance-forecasting.sql](../quests/window-functions/04-partitioned-analytics/09-performance-forecasting.sql)
- **Sales by Category** - [01-sales-by-category.sql](../quests/window-functions/04-partitioned-analytics/01-sales-by-category.sql)
- **Customer Segmentation** - [02-customer-segmentation.sql](../quests/window-functions/04-partitioned-analytics/02-customer-segmentation.sql)
- **Performance Comparison** - [03-performance-comparison.sql](../quests/window-functions/04-partitioned-analytics/03-performance-comparison.sql)

#### 🔬 Advanced Patterns (3 examples)
- **Lead Lag Analysis** - [01-lead-lag-analysis.sql](../quests/window-functions/05-advanced-patterns/01-lead-lag-analysis.sql)
- **Gap Analysis** - [02-gap-analysis.sql](../quests/window-functions/05-advanced-patterns/02-gap-analysis.sql)
- **Trend Detection** - [03-trend-detection.sql](../quests/window-functions/05-advanced-patterns/03-trend-detection.sql)

### 3. Advanced Joins
- **Self-joins** - Joining table to itself
- **Cross joins** - Cartesian products
- **Lateral joins** - Correlated subqueries
- **Natural joins** - Automatic column matching

### 4. Subqueries
- **Correlated subqueries** - Dependent on outer query
- **Non-correlated subqueries** - Independent execution
- **EXISTS/NOT EXISTS** - Existence checks
- **IN/NOT IN** - Set membership

## 🥉 Advanced Level

### 1. Performance Optimization
- **Indexing strategies** - B-tree, hash, partial indexes
- **Query planning** - EXPLAIN ANALYZE
- **Optimization techniques** - Query rewriting
- **Performance monitoring** - pg_stat_statements

### 2. Advanced Patterns
- **Pivot tables** - Crosstab operations
- **Running totals** - Cumulative calculations
- **Gaps analysis** - Missing data identification
- **Time series** - Temporal data processing

### 3. Database Design
- **Normalization** - Reducing redundancy
- **Denormalization** - Performance optimization
- **Data modeling** - Entity-relationship design
- **Schema design** - Table structure optimization

## 🎯 Learning Resources

### Interactive Learning
- **SQL Adventure Quests** - Hands-on examples with Docker
- **Recursive CTE Cheatsheet** - [Quick Reference](./cheatsheets/recursive-cte.md)
- **Real-world Scenarios** - [Industry Applications](./use-cases.md)

### Practice Exercises
- **Category-specific examples** - Focused learning by topic
- **Progressive difficulty** - Building complexity step by step
- **Idempotent design** - Safe experimentation and repetition

### Advanced Topics
- **Performance tuning** - Query optimization techniques
- **Advanced analytics** - Window functions and complex aggregations
- **Data engineering** - ETL processes and data pipelines

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

### Step 2: Start with Basics
1. **Review the cheatsheet** - [Recursive CTE Cheatsheet](./cheatsheets/recursive-cte.md)
2. **Run simple examples** - Start with number series and date generation
3. **Understand patterns** - Learn the base case + recursive case structure

### Step 3: Progress Through Categories
1. **Hierarchical Data** - Employee hierarchies and family trees
2. **Iteration & Loops** - Mathematical sequences and series
3. **Path Finding** - Graph algorithms and shortest paths
4. **Data Transformation** - String parsing and JSON processing
5. **Simulations** - State machines and business logic
6. **Data Repair** - Cleaning and fixing data issues
7. **Mathematical** - Advanced algorithms and patterns
8. **Bonus Examples** - Creative and quirky applications

### Step 4: Master Window Functions
1. **Basic Ranking** - Row numbers and ranking
2. **Advanced Ranking** - NTILE and percentile analysis
3. **Aggregation Windows** - Running totals and moving averages
4. **Partitioned Analytics** - Category-based analysis
5. **Advanced Patterns** - Lead/lag and trend detection

### Step 5: Apply to Real Problems
1. **Choose your industry** - [Use Cases by Industry](./use-cases.md)
2. **Adapt examples** - Customize for your specific needs
3. **Optimize performance** - Learn advanced techniques
4. **Contribute back** - Share your knowledge with the community

## 📊 Progress Tracking

### Beginner Milestones
- [ ] Complete basic SQL concepts
- [ ] Run first recursive CTE example
- [ ] Understand base case vs recursive case
- [ ] Complete 5 simple examples

### Intermediate Milestones
- [ ] Complete all 31 recursive CTE examples
- [ ] Complete all 23 window function examples
- [ ] Understand hierarchical data patterns
- [ ] Master iteration and loop techniques
- [ ] Apply to real-world scenarios

### Advanced Milestones
- [ ] Optimize query performance
- [ ] Design complex data models
- [ ] Create custom recursive patterns
- [ ] Master advanced window function patterns
- [ ] Mentor others in the community

---

*Ready to start your SQL Adventure? Begin with the [Recursive CTE Cheatsheet](./cheatsheets/recursive-cte.md)! 🚀*
