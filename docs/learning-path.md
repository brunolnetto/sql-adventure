# Learning Path 📖

Structured progression from Data Modeling to Recursive CTEs with 80 examples from SQL Adventure.

## 🎯 **Conceptual Learning Progression**

### **Why This Order?**
1. **Data Modeling** (Foundation) - Understand database structure and relationships
2. **Performance Tuning** (Optimization) - Learn to make queries fast
3. **Window Functions** (Analytics) - Advanced querying for business intelligence
4. **JSON Operations** (Modern Extension) - Handle semi-structured data
5. **Recursive CTE** (Complex Patterns) - Hierarchical and iterative logic

---

## 📋 **Prerequisites Guide**

Each quest builds upon previous knowledge. This guide helps you assess your readiness and identify any gaps before starting each quest.

### **🏗️ Quest 1: Data Modeling Prerequisites**

**Required Prerequisites:**
- **Basic SQL knowledge** - SELECT, INSERT, UPDATE, DELETE statements
- **Understanding of tables** - What tables are and how they store data
- **Basic data types** - VARCHAR, INT, DATE, BOOLEAN, etc.
- **Simple queries** - Basic WHERE clauses and simple JOINs

**Self-Assessment Checklist:**
- [ ] I can write basic SELECT queries with WHERE clauses
- [ ] I understand what tables, columns, and rows are
- [ ] I can perform simple INSERT, UPDATE, DELETE operations
- [ ] I understand basic data types (VARCHAR, INT, DATE)
- [ ] I can write simple JOIN queries between two tables
- [ ] I understand what primary keys and foreign keys are
- [ ] I can identify data redundancy in simple scenarios

### **⚡ Quest 2: Performance Tuning Prerequisites**

**Required Prerequisites:**
- **Data Modeling concepts** - Understanding of table design and relationships
- **SQL proficiency** - Comfort with complex queries and JOINs
- **Database operations** - Experience with real database systems
- **Basic performance awareness** - Understanding that some queries are slower than others

**Self-Assessment Checklist:**
- [ ] I can design normalized database schemas
- [ ] I understand primary keys, foreign keys, and constraints
- [ ] I can write complex queries with multiple JOINs
- [ ] I understand the difference between INNER JOIN and LEFT JOIN
- [ ] I can identify when queries might be slow
- [ ] I understand what indexes are (even if I don't know how to create them)
- [ ] I can read basic EXPLAIN output
- [ ] I have experience with real database systems (not just tutorials)

### **🪟 Quest 3: Window Functions Prerequisites**

**Required Prerequisites:**
- **Data Modeling mastery** - Solid understanding of table design
- **Performance Tuning concepts** - Understanding of query optimization
- **Advanced SQL skills** - Comfort with subqueries and complex aggregations
- **Analytical thinking** - Ability to think in terms of data analysis

**Self-Assessment Checklist:**
- [ ] I can design efficient database schemas
- [ ] I understand normalization and when to denormalize
- [ ] I can optimize queries using indexes and query structure
- [ ] I can read and interpret execution plans
- [ ] I can write complex GROUP BY queries with multiple aggregations
- [ ] I can use subqueries effectively
- [ ] I understand the difference between WHERE and HAVING
- [ ] I can think analytically about data problems

### **🎯 Quest 4: JSON Operations Prerequisites**

**Required Prerequisites:**
- **All previous quests** - Data Modeling, Performance Tuning, Window Functions
- **JSON familiarity** - Understanding of JSON data structure
- **Modern SQL concepts** - Comfort with PostgreSQL-specific features
- **API data handling** - Understanding of semi-structured data

**Self-Assessment Checklist:**
- [ ] I can design efficient database schemas
- [ ] I can optimize queries for performance
- [ ] I can use window functions for analytics
- [ ] I understand JSON data structure (objects, arrays, key-value pairs)
- [ ] I can work with API responses and semi-structured data
- [ ] I understand PostgreSQL-specific features

### **🔄 Quest 5: Recursive CTE Prerequisites**

**Required Prerequisites:**
- **All previous quests** - Complete mastery of all previous concepts
- **Advanced SQL thinking** - Ability to think recursively
- **Complex problem solving** - Comfort with hierarchical and iterative logic
- **Mathematical concepts** - Understanding of recursion and iteration

**Self-Assessment Checklist:**
- [ ] I have mastered all previous quest concepts
- [ ] I can think in terms of hierarchical relationships
- [ ] I understand recursive logic and iteration
- [ ] I can solve complex data problems
- [ ] I can work with tree structures and graphs
- [ ] I understand mathematical sequences and patterns

---

## 🏗️ **Phase 1: Data Modeling (15 Examples)**

**Prerequisites**: Basic SQL knowledge (SELECT, INSERT, UPDATE, DELETE, JOINs)

**Purpose**: Master database design principles, normalization patterns, and schema optimization.

### **🟢 Beginner (3 examples)**
- **Basic Table Creation** - [01-basic-table-creation.sql](../quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql)
- **Simple Relationships** - [02-simple-relationships.sql](../quests/1-data-modeling/00-basic-concepts/02-simple-relationships.sql)
- **Basic Constraints** - [03-basic-constraints.sql](../quests/1-data-modeling/00-basic-concepts/03-basic-constraints.sql)

### **🟡 Intermediate (6 examples)**
- **Basic Normalization** - [01-basic-normalization.sql](../quests/1-data-modeling/01-normalization-patterns/01-basic-normalization.sql)
- **Advanced Normalization** - [02-advanced-normalization.sql](../quests/1-data-modeling/01-normalization-patterns/02-advanced-normalization.sql)
- **Performance Denormalization** - [01-performance-denormalization.sql](../quests/1-data-modeling/02-denormalization-strategies/01-performance-denormalization.sql)
- **Analytics Denormalization** - [02-analytics-denormalization.sql](../quests/1-data-modeling/02-denormalization-strategies/02-analytics-denormalization.sql)
- **Entity Relationship** - [01-entity-relationship.sql](../quests/1-data-modeling/03-schema-design-principles/01-entity-relationship.sql)
- **Data Integrity** - [02-data-integrity.sql](../quests/1-data-modeling/03-schema-design-principles/02-data-integrity.sql)

### **🔴 Advanced (6 examples)**
- **Normalization Trade-offs** - [03-normalization-trade-offs.sql](../quests/1-data-modeling/01-normalization-patterns/03-normalization-trade-offs.sql)
- **Hybrid Approaches** - [03-hybrid-approaches.sql](../quests/1-data-modeling/02-denormalization-strategies/03-hybrid-approaches.sql)
- **Schema Evolution** - [03-schema-evolution.sql](../quests/1-data-modeling/03-schema-design-principles/03-schema-evolution.sql)
- **E-commerce Model** - [01-ecommerce-model.sql](../quests/1-data-modeling/04-real-world-applications/01-ecommerce-model.sql)
- **Healthcare Model** - [02-healthcare-model.sql](../quests/1-data-modeling/04-real-world-applications/02-healthcare-model.sql)
- **Financial Model** - [03-financial-model.sql](../quests/1-data-modeling/04-real-world-applications/03-financial-model.sql)

**Learning Outcomes**: Design efficient database schemas, understand normalization, implement data integrity constraints.

---

## ⚡ **Phase 2: Performance Tuning (15 Examples)**

**Prerequisites**: Data Modeling concepts, basic SQL proficiency

**Purpose**: Master PostgreSQL performance optimization techniques for production environments.

### **🟢 Beginner (3 examples)**
- **Query Structure Basics** - [01-query-structure-basics.sql](../quests/2-performance-tuning/00-basic-concepts/01-query-structure-basics.sql)
- **Basic Indexing** - [02-basic-indexing.sql](../quests/2-performance-tuning/00-basic-concepts/02-basic-indexing.sql)
- **Query Planning** - [03-query-planning.sql](../quests/2-performance-tuning/00-basic-concepts/03-query-planning.sql)

### **🟡 Intermediate (6 examples)**
- **Basic Optimization** - [01-basic-optimization.sql](../quests/2-performance-tuning/01-query-optimization/01-basic-optimization.sql)
- **Aggregation Optimization** - [02-aggregation-optimization.sql](../quests/2-performance-tuning/01-query-optimization/02-aggregation-optimization.sql)
- **Subquery Optimization** - [03-subquery-optimization.sql](../quests/2-performance-tuning/01-query-optimization/03-subquery-optimization.sql)
- **Join Optimization** - [04-join-optimization.sql](../quests/2-performance-tuning/01-query-optimization/04-join-optimization.sql)
- **Aggregation Optimization** - [05-aggregation-optimization.sql](../quests/2-performance-tuning/01-query-optimization/05-aggregation-optimization.sql)
- **Basic Indexing** - [01-basic-indexing.sql](../quests/2-performance-tuning/02-indexing-strategies/01-basic-indexing.sql)

### **🔴 Advanced (3 examples)**
- **Advanced Indexing** - [02-advanced-indexing.sql](../quests/2-performance-tuning/02-indexing-strategies/02-advanced-indexing.sql)
- **Composite Indexing** - [03-composite-indexing.sql](../quests/2-performance-tuning/02-indexing-strategies/03-composite-indexing.sql)
- **Plan Analysis** - [01-plan-analysis.sql](../quests/2-performance-tuning/03-execution-plans/01-plan-analysis.sql)

### **⚫ Expert (3 examples)**
- **Statistics Analysis** - [02-statistics-analysis.sql](../quests/2-performance-tuning/03-execution-plans/02-statistics-analysis.sql)
- **Advanced Query Optimization** - [01-advanced-query-optimization.sql](../quests/2-performance-tuning/05-expert-techniques/01-advanced-query-optimization.sql)
- **Performance Monitoring** - [02-performance-monitoring.sql](../quests/2-performance-tuning/05-expert-techniques/02-performance-monitoring.sql)

**Learning Outcomes**: Optimize query performance, design effective indexes, analyze execution plans, monitor system performance.

---

## 🪟 **Phase 3: Window Functions (18 Examples)**

**Prerequisites**: Data Modeling + Performance Tuning concepts

**Purpose**: Master advanced analytics, ranking, and time series analysis with Window Functions.

### **🟢 Beginner (3 examples)**
- **Row Number** - [01-row-number.sql](../quests/3-window-functions/01-basic-ranking/01-row-number.sql)
- **Rank & Dense Rank** - [02-rank-dense-rank.sql](../quests/3-window-functions/01-basic-ranking/02-rank-dense-rank.sql)
- **Running Totals** - [01-running-totals.sql](../quests/3-window-functions/03-aggregation-windows/01-running-totals.sql)

### **🟡 Intermediate (7 examples)**
- **NTILE Analysis** - [01-ntile-analysis.sql](../quests/3-window-functions/02-advanced-ranking/01-ntile-analysis.sql)
- **Percentile Analysis** - [02-percentile-analysis.sql](../quests/3-window-functions/02-advanced-ranking/02-percentile-analysis.sql)
- **Moving Averages** - [02-moving-averages.sql](../quests/3-window-functions/03-aggregation-windows/02-moving-averages.sql)
- **Cumulative Sums** - [03-cumulative-sums.sql](../quests/3-window-functions/03-aggregation-windows/03-cumulative-sums.sql)
- **Basic Category Ranking** - [01-basic-category-ranking.sql](../quests/3-window-functions/04-partitioned-analytics/01-basic-category-ranking.sql)
- **Category Performance Analysis** - [02-category-performance-analysis.sql](../quests/3-window-functions/04-partitioned-analytics/02-category-performance-analysis.sql)
- **Category Comparisons** - [03-category-comparisons.sql](../quests/3-window-functions/04-partitioned-analytics/03-category-comparisons.sql)

### **🔴 Advanced (5 examples)**
- **Salary Analysis** - [03-salary-analysis.sql](../quests/3-window-functions/02-advanced-ranking/03-salary-analysis.sql)
- **Customer RFM Analysis** - [04-customer-rfm-analysis.sql](../quests/3-window-functions/04-partitioned-analytics/04-customer-rfm-analysis.sql)
- **Customer Retention Analysis** - [06-customer-retention-analysis.sql](../quests/3-window-functions/04-partitioned-analytics/06-customer-retention-analysis.sql)
- **Quarterly Performance** - [07-quarterly-performance.sql](../quests/3-window-functions/04-partitioned-analytics/07-quarterly-performance.sql)
- **Employee Performance Trends** - [08-employee-performance-trends.sql](../quests/3-window-functions/04-partitioned-analytics/08-employee-performance-trends.sql)

### **⚫ Expert (3 examples)**
- **Lead Lag Analysis** - [01-lead-lag-analysis.sql](../quests/3-window-functions/05-advanced-patterns/01-lead-lag-analysis.sql)
- **Gap Analysis** - [02-gap-analysis.sql](../quests/3-window-functions/05-advanced-patterns/02-gap-analysis.sql)
- **Trend Detection** - [03-trend-detection.sql](../quests/3-window-functions/05-advanced-patterns/03-trend-detection.sql)

**Learning Outcomes**: Perform advanced analytics, create ranking systems, analyze time series data, build business intelligence reports.

---

## 🎯 **Phase 4: JSON Operations (12 Examples)**

**Prerequisites**: Core SQL skills from previous quests

**Purpose**: Master modern PostgreSQL JSON operations for handling semi-structured data and API responses.

### **🟢 Beginner (3 examples)**
- **JSON Parsing** - [01-json-parsing.sql](../quests/4-json-operations/01-basic-json/01-json-parsing.sql)
- **JSON Generation** - [02-json-generation.sql](../quests/4-json-operations/01-basic-json/02-json-generation.sql)
- **JSON Validation** - [03-json-validation.sql](../quests/4-json-operations/01-basic-json/03-json-validation.sql)

### **🟡 Intermediate (5 examples)**
- **Nested Extraction** - [01-nested-extraction.sql](../quests/4-json-operations/02-json-queries/01-nested-extraction.sql)
- **Array Operations** - [02-array-operations.sql](../quests/4-json-operations/02-json-queries/02-array-operations.sql)
- **JSON Aggregation** - [03-json-aggregation.sql](../quests/4-json-operations/02-json-queries/03-json-aggregation.sql)
- **API Data Processing** - [01-api-data-processing.sql](../quests/4-json-operations/03-real-world-applications/01-api-data-processing.sql)
- **Configuration Management** - [02-configuration-management.sql](../quests/4-json-operations/03-real-world-applications/02-configuration-management.sql)

### **🔴 Advanced (4 examples)**
- **Log Analysis** - [03-log-analysis.sql](../quests/4-json-operations/03-real-world-applications/03-log-analysis.sql)
- **Schema Validation** - [01-json-schema-validation.sql](../quests/4-json-operations/04-advanced-patterns/01-json-schema-validation.sql)
- **JSON Transformation** - [02-json-transformation.sql](../quests/4-json-operations/04-advanced-patterns/02-json-transformation.sql)
- **JSON Performance** - [03-json-performance.sql](../quests/4-json-operations/04-advanced-patterns/03-json-performance.sql)

**Learning Outcomes**: Handle semi-structured data, process API responses, validate JSON schemas, optimize JSON operations.

---

## 🔄 **Phase 5: Recursive CTE (20 Examples)**

**Prerequisites**: All previous quests (Data Modeling + Performance Tuning + Window Functions + JSON Operations)

**Purpose**: Master hierarchical data, graph algorithms, and iterative operations with Recursive Common Table Expressions.

### **🟢 Beginner (5 examples)**
- **Number Series** - [01-number-series.sql](../quests/5-recursive-cte/02-iteration-loops/01-number-series.sql)
- **Employee Hierarchy** - [01-employee-hierarchy.sql](../quests/5-recursive-cte/01-hierarchical-graph-traversal/01-employee-hierarchy.sql)
- **String Splitting** - [01-string-splitting.sql](../quests/5-recursive-cte/04-data-transformation-parsing/01-string-splitting.sql)
- **Category Tree** - [03-category-tree.sql](../quests/5-recursive-cte/01-hierarchical-graph-traversal/03-category-tree.sql)
- **Fibonacci Sequence** - [03-fibonacci-sequence.sql](../quests/5-recursive-cte/02-iteration-loops/03-fibonacci-sequence.sql)

### **🟡 Intermediate (7 examples)**
- **Bill of Materials** - [02-bill-of-materials.sql](../quests/5-recursive-cte/01-hierarchical-graph-traversal/02-bill-of-materials.sql)
- **Date Series** - [02-date-series.sql](../quests/5-recursive-cte/02-iteration-loops/02-date-series.sql)
- **Collatz Sequence** - [04-collatz-sequence.sql](../quests/5-recursive-cte/02-iteration-loops/04-collatz-sequence.sql)
- **Factorial Calculation** - [06-factorial-calculation.sql](../quests/5-recursive-cte/02-iteration-loops/06-factorial-calculation.sql)
- **Running Total** - [07-running-total.sql](../quests/5-recursive-cte/02-iteration-loops/07-running-total.sql)
- **Sequence Gaps** - [01-sequence-gaps.sql](../quests/5-recursive-cte/06-data-repair-healing/01-sequence-gaps.sql)
- **Forward Fill Nulls** - [02-forward-fill-nulls.sql](../quests/5-recursive-cte/06-data-repair-healing/02-forward-fill-nulls.sql)

### **🔴 Advanced (5 examples)**
- **Graph Reachability** - [04-graph-reachability.sql](../quests/5-recursive-cte/01-hierarchical-graph-traversal/04-graph-reachability.sql)
- **Dependency Resolution** - [05-dependency-resolution.sql](../quests/5-recursive-cte/01-hierarchical-graph-traversal/05-dependency-resolution.sql)
- **Filesystem Hierarchy** - [06-filesystem-hierarchy.sql](../quests/5-recursive-cte/01-hierarchical-graph-traversal/06-filesystem-hierarchy.sql)
- **Family Tree** - [07-family-tree.sql](../quests/5-recursive-cte/01-hierarchical-graph-traversal/07-family-tree.sql)
- **Transitive Closure** - [02-transitive-closure.sql](../quests/5-recursive-cte/04-data-transformation-parsing/02-transitive-closure.sql)

### **⚫ Expert (3 examples)**
- **Shortest Path** - [01-shortest-path.sql](../quests/5-recursive-cte/03-path-finding-analysis/01-shortest-path.sql)
- **Cycle Detection** - [03-cycle-detection.sql](../quests/5-recursive-cte/03-path-finding-analysis/03-cycle-detection.sql)
- **Inventory Simulation** - [01-inventory-simulation.sql](../quests/5-recursive-cte/05-simulation-state-machines/01-inventory-simulation.sql)

**Learning Outcomes**: Process hierarchical data, implement graph algorithms, create iterative solutions, build complex data transformations.

---

## 🚀 **Getting Started**

### **Step 1: Environment Setup**
```bash
# Clone the repository
git clone <repository-url>
cd sql-adventure

# Start the Docker environment
docker-compose up -d

# Connect to PostgreSQL
PGPASSWORD=postgres psql -h localhost -p 5433 -U postgres -d sql_adventure_db
```

### **Step 2: Choose Your Path**

#### **🏗️ For Complete Learning (Recommended)**
1. **Start with Data Modeling** - Build strong foundations
2. **Learn Performance Tuning** - Optimize your queries
3. **Master Window Functions** - Advanced analytics
4. **Explore JSON Operations** - Modern data handling
5. **Tackle Recursive CTEs** - Complex patterns

#### **🎯 For Quick Reference**
1. **[Data Modeling Cheatsheet](./cheatsheets/data-modeling.md)** - Database design patterns
2. **[Performance Tuning Cheatsheet](./cheatsheets/performance-tuning.md)** - Query optimization
3. **[Recursive CTE Cheatsheet](./cheatsheets/recursive-cte.md)** - Hierarchical data processing

### **Step 3: Progress Through Quests**

1. **🏗️ Data Modeling** - Start with database foundations
2. **⚡ Performance Tuning** - Learn to optimize queries
3. **🪟 Window Functions** - Master advanced analytics
4. **🎯 JSON Operations** - Handle modern data formats
5. **🔄 Recursive CTE** - Complex hierarchical patterns

## 📊 **Progress Tracking**

### **Beginner Milestones**
- [ ] Complete Data Modeling beginner examples
- [ ] Understand basic table creation and relationships
- [ ] Learn basic performance concepts
- [ ] Complete 5 simple examples across quests

### **Intermediate Milestones**
- [ ] Complete all Data Modeling examples
- [ ] Complete all Performance Tuning examples
- [ ] Complete all Window Functions examples
- [ ] Complete all JSON Operations examples
- [ ] Complete all Recursive CTE examples

### **Advanced Milestones**
- [ ] Design complex database schemas
- [ ] Optimize query performance
- [ ] Create advanced analytics reports
- [ ] Handle complex JSON data structures
- [ ] Implement hierarchical data solutions
- [ ] Mentor others in the community

## 🎯 **Learning Outcomes by Phase**

### **Phase 1: Data Modeling**
- Design efficient database schemas
- Apply normalization principles
- Implement data integrity constraints
- Create real-world data models

### **Phase 2: Performance Tuning**
- Optimize query performance
- Design effective indexes
- Analyze execution plans
- Monitor system performance

### **Phase 3: Window Functions**
- Perform advanced analytics
- Create ranking systems
- Analyze time series data
- Build business intelligence reports

### **Phase 4: JSON Operations**
- Handle semi-structured data
- Process API responses
- Validate JSON schemas
- Optimize JSON operations

### **Phase 5: Recursive CTE**
- Process hierarchical data
- Implement graph algorithms
- Create iterative solutions
- Build complex data transformations

---

---

## 🎯 **Industry Use Cases**

### **💼 Business & Finance**
- **Organization Management**: Employee hierarchies, cost rollup calculations, performance metrics
- **Financial Analysis**: Multi-level reporting, budget planning, profitability analysis
- **Workflow Automation**: Approval processes, task dependencies, compliance tracking

### **🏥 Healthcare**
- **Patient Management**: Family tree analysis, medical history tracking, treatment pathways
- **Clinical Operations**: Medical hierarchy management, resource allocation, quality metrics
- **Research & Analytics**: Clinical trials, outcome tracking, population health analysis

### **🛒 E-commerce**
- **Product Management**: Category navigation, product recommendations, inventory forecasting
- **Customer Analytics**: Purchase patterns, loyalty programs, customer segmentation
- **Operations**: Supply chain optimization, order processing, performance metrics

### **🏭 Manufacturing**
- **Production Planning**: Bill of Materials (BOM), supply chain optimization, production scheduling
- **Resource Management**: Equipment hierarchy, maintenance scheduling, capacity planning
- **Quality Assurance**: Defect tracking, compliance monitoring, process improvement

### **💻 Technology**
- **Software Development**: Dependency resolution, build systems, version control
- **System Administration**: Configuration management, performance monitoring, security analysis

---

*Ready to start your SQL Adventure? Begin with [Data Modeling](../quests/1-data-modeling/) and build your way to mastering complex patterns! 🚀*
