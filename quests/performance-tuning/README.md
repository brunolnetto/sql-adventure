# Performance Tuning Quest ⚡

Master PostgreSQL performance optimization techniques for production environments.

## 📊 Overview

- **12 Examples** across 4 categories
- **Difficulty**: Intermediate → Advanced
- **Status**: ✅ Complete
- **Time**: 10-45 min per example

## 🚀 Quick Start

```bash
# Start environment
docker-compose up -d

# Run all examples
./scripts/run-examples.sh quest performance-tuning

# Run specific category
./scripts/run-examples.sh quest performance-tuning 01-query-optimization
```

## 📚 Categories

### **01-query-optimization/** 🟡 **Intermediate**
- `01-basic-optimization.sql` - Query structure and WHERE clause optimization (3 examples)
- `02-aggregation-optimization.sql` - GROUP BY and aggregate function optimization (3 examples)
- `03-subquery-optimization.sql` - Subquery types and EXISTS vs IN (3 examples)

### **02-indexing-strategies/** 🟡 **Intermediate**
- `01-basic-indexing.sql` - B-tree indexes and index selection (6 examples)
- `02-advanced-indexing.sql` - Partial, expression, and covering indexes (6 examples)

### **03-execution-plans/** 🔴 **Advanced**
- `01-plan-analysis.sql` - EXPLAIN output interpretation (6 examples)
- `02-statistics-analysis.sql` - Table and column statistics (6 examples)
- `03-query-rewriting.sql` - Query transformation techniques (6 examples)

### **04-performance-monitoring/** 🔴 **Advanced**
- `01-slow-query-analysis.sql` - Slow query identification and profiling (6 examples)
- `02-resource-monitoring.sql` - System resources and connection monitoring (6 examples)
- `03-performance-tuning.sql` - Configuration tuning and capacity planning (6 examples)

## 🎯 Learning Path

### **🟡 Intermediate (Start Here)**
1. `01-basic-optimization.sql` - Understand query execution order
2. `02-aggregation-optimization.sql` - Optimize GROUP BY operations
3. `03-subquery-optimization.sql` - Choose between EXISTS and IN
4. `01-basic-indexing.sql` - Understand different index types

### **🔴 Advanced**
1. `02-advanced-indexing.sql` - Master specialized index patterns
2. `01-plan-analysis.sql` - Read and interpret execution plans
3. `02-statistics-analysis.sql` - Understand and manage statistics
4. `01-slow-query-analysis.sql` - Identify and analyze slow queries

### **⚫ Expert**
1. `03-query-rewriting.sql` - Transform queries for better performance
2. `02-resource-monitoring.sql` - Monitor system resources and locks
3. `03-performance-tuning.sql` - Tune configuration and workloads

## 🔧 Key Concepts

```sql
-- Query analysis
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) 
SELECT * FROM users WHERE email = 'test@example.com';

-- Index creation
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_name_email ON users(name, email);
CREATE INDEX idx_users_active ON users(id) WHERE is_active = true;

-- Statistics analysis
SELECT schemaname, tablename, attname, n_distinct, correlation 
FROM pg_stats WHERE tablename = 'users';
```

## 🛠️ Key PostgreSQL Performance Tools

### **Query Analysis**
- `EXPLAIN` - Show query execution plan
- `EXPLAIN ANALYZE` - Show plan with actual execution times
- `EXPLAIN (BUFFERS, FORMAT JSON)` - Detailed plan analysis

### **Statistics & Monitoring**
- `pg_stat_statements` - Query execution statistics
- `pg_stat_activity` - Current activity monitoring
- `pg_stat_database` - Database-level statistics

### **Index Management**
- `CREATE INDEX` - Create various index types
- `ANALYZE` - Update table statistics
- `REINDEX` - Rebuild indexes

### **Configuration**
- `shared_buffers` - Memory allocation
- `work_mem` - Sort and hash memory
- `maintenance_work_mem` - Maintenance operations

## 🏢 Real-World Applications

- **Production Environments**: Query optimization, index strategies, resource monitoring
- **Development Teams**: Code review performance analysis, best practices
- **Database Administration**: System tuning, query analysis, monitoring
- **Data Science**: Large dataset optimization, analytical query performance

## 📊 Performance Tips

- **Use appropriate indexes** on frequently queried columns
- **Monitor execution plans** for large datasets
- **Update statistics regularly** for accurate query planning
- **Consider query rewriting** for complex operations
- **Monitor system resources** and connection patterns

---

*Ready to optimize PostgreSQL performance? Start with [Query Optimization](./01-query-optimization/)! 🚀* 