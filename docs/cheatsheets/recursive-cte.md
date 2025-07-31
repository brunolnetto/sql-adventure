# Recursive CTE Cheatsheet 🚀

Your complete guide to mastering recursive CTEs for Data Analyst interviews and real-world applications.

## ⚠️ **When NOT to Use Recursive CTEs**

**Before diving into recursive CTEs, know when NOT to use them:**

### ❌ **Use Built-in Functions Instead:**
```sql
-- DON'T: Recursive CTE for number series
WITH RECURSIVE numbers AS (
    SELECT 1 as num
    UNION ALL
    SELECT num + 1 FROM numbers WHERE num < 10
)
SELECT num FROM numbers;

-- DO: Use generate_series()
SELECT generate_series(1, 10) as num;
```

```sql
-- DON'T: Recursive CTE for date series
WITH RECURSIVE dates AS (
    SELECT DATE '2024-01-01' as date_value
    UNION ALL
    SELECT date_value + INTERVAL '1 day' FROM dates WHERE date_value < DATE '2024-01-31'
)
SELECT date_value FROM dates;

-- DO: Use generate_series()
SELECT generate_series(DATE '2024-01-01', DATE '2024-01-31', INTERVAL '1 day')::DATE as date_value;
```

```sql
-- DON'T: Recursive CTE for running totals
WITH RECURSIVE running_total AS (
    SELECT date_id, amount, amount as running_sum
    FROM sales WHERE date_id = (SELECT MIN(date_id) FROM sales)
    UNION ALL
    SELECT s.date_id, s.amount, rt.running_sum + s.amount
    FROM sales s INNER JOIN running_total rt ON s.date_id = rt.date_id + 1
)
SELECT * FROM running_total;

-- DO: Use window functions
SELECT date_id, amount, SUM(amount) OVER (ORDER BY date_id) as running_sum
FROM sales ORDER BY date_id;
```

```sql
-- DON'T: Recursive CTE for forward fill (PostgreSQL 12+)
WITH RECURSIVE forward_fill AS (
    -- Complex recursive logic...
)
SELECT * FROM forward_fill;

-- DO: Use IGNORE NULLS window function
SELECT id, timestamp, sensor_id,
       FIRST_VALUE(temperature) IGNORE NULLS OVER (PARTITION BY sensor_id ORDER BY timestamp) as temperature
FROM time_series_data;
```

### ✅ **When Recursive CTEs ARE Appropriate:**

1. **Hierarchical Data** - Employee org charts, family trees, BOM
2. **Graph Algorithms** - Shortest path, cycle detection, reachability
3. **Mathematical Sequences** - Fibonacci, Collatz, prime generation
4. **Complex Data Transformation** - Nested JSON parsing, complex string operations
5. **Simulation & State Machines** - Multi-step processes, game states

## 📋 Quick Reference

### Basic Recursive CTE Structure
```sql
WITH RECURSIVE cte_name AS (
    -- Base case: starting point
    SELECT initial_data
    
    UNION ALL
    
    -- Recursive case: iteration logic
    SELECT next_data
    FROM cte_name
    WHERE termination_condition
)
SELECT * FROM cte_name;
```

## 🏗️ 1. Hierarchical Data Traversal

### Employee Hierarchy
```sql
WITH RECURSIVE hierarchy AS (
    SELECT id, name, manager_id, 0 as level, ARRAY[name] as path
    FROM employees WHERE manager_id IS NULL
    
    UNION ALL
    
    SELECT e.id, e.name, e.manager_id, h.level + 1, h.path || e.name
    FROM employees e
    INNER JOIN hierarchy h ON e.manager_id = h.id
)
SELECT level, name, array_to_string(path, ' → ') as hierarchy_path
FROM hierarchy ORDER BY level, name;
```

### Bill of Materials (BOM)
```sql
WITH RECURSIVE bom AS (
    SELECT component_id, quantity, 1 as level, ARRAY[component_id] as path
    FROM components WHERE parent_id IS NULL
    
    UNION ALL
    
    SELECT c.component_id, c.quantity * b.quantity, b.level + 1, b.path || c.component_id
    FROM components c
    INNER JOIN bom b ON c.parent_id = b.component_id
)
SELECT level, component_id, quantity, path
FROM bom ORDER BY level, component_id;
```

### Family Tree
```sql
WITH RECURSIVE family_tree AS (
    SELECT id, name, father_id, mother_id, 0 as generation, name as lineage
    FROM family_members WHERE father_id IS NULL AND mother_id IS NULL
    
    UNION ALL
    
    SELECT fm.id, fm.name, fm.father_id, fm.mother_id, ft.generation + 1,
           ft.lineage || ' → ' || fm.name
    FROM family_members fm
    INNER JOIN family_tree ft ON (fm.father_id = ft.id OR fm.mother_id = ft.id)
    WHERE ft.generation < 3
)
SELECT generation, name, lineage FROM family_tree ORDER BY generation, name;
```

## 🔄 2. Iteration & Loops

### Fibonacci Sequence (Legitimate Use)
```sql
WITH RECURSIVE fibonacci AS (
    SELECT 0 as n, 0 as fib_n, 1 as fib_next
    
    UNION ALL
    
    SELECT n + 1, fib_next, fib_n + fib_next
    FROM fibonacci WHERE n < 14
)
SELECT n, fib_n as fibonacci_number FROM fibonacci ORDER BY n;
```

### Collatz Sequence (Legitimate Use)
```sql
WITH RECURSIVE collatz AS (
    SELECT 27 as num, 1 as step, CAST('27' AS VARCHAR(100)) as sequence
    
    UNION ALL
    
    SELECT 
        CASE WHEN num % 2 = 0 THEN num / 2 ELSE 3 * num + 1 END,
        step + 1,
        sequence || ' → ' || CASE WHEN num % 2 = 0 THEN (num / 2)::VARCHAR ELSE (3 * num + 1)::VARCHAR END
    FROM collatz WHERE num > 1
)
SELECT step, num, sequence FROM collatz ORDER BY step;
```

## 🛤️ 3. Path Finding & Analysis

### Shortest Path
```sql
WITH RECURSIVE paths AS (
    SELECT start_node, end_node, 0 as distance, ARRAY[start_node] as path
    FROM graph WHERE start_node = target_node
    
    UNION ALL
    
    SELECT p.start_node, g.end_node, p.distance + 1, p.path || g.end_node
    FROM graph g
    INNER JOIN paths p ON g.start_node = p.end_node
    WHERE NOT (g.end_node = ANY(p.path)) AND p.distance < 5
)
SELECT * FROM paths WHERE end_node = target_end_node
ORDER BY distance LIMIT 1;
```

### Cycle Detection
```sql
WITH RECURSIVE cycle_check AS (
    SELECT node_id, ARRAY[node_id] as path, false as has_cycle
    FROM graph_nodes
    
    UNION ALL
    
    SELECT g.end_node, cc.path || g.end_node,
           g.end_node = ANY(cc.path) OR cc.has_cycle
    FROM graph_edges g
    INNER JOIN cycle_check cc ON g.start_node = cc.node_id
    WHERE NOT cc.has_cycle AND array_length(cc.path, 1) < 10
)
SELECT DISTINCT node_id, has_cycle FROM cycle_check WHERE has_cycle;
```

## 🔧 4. Data Transformation

### String Splitting (Alternative: Use built-in functions)
```sql
-- RECURSIVE CTE approach (shown for learning)
WITH RECURSIVE split_string AS (
    SELECT 1 as position, 
           split_part('apple,banana,cherry', ',', 1) as value,
           'apple,banana,cherry' as remaining
    
    UNION ALL
    
    SELECT position + 1,
           split_part(remaining, ',', 1),
           substring(remaining from position(',', remaining) + 1)
    FROM split_string
    WHERE remaining != '' AND position(',', remaining) > 0
)
SELECT position, value FROM split_string WHERE value != '';

-- SIMPLER: Use built-in functions
SELECT unnest(string_to_array('apple,banana,cherry', ',')) as value;
```

### JSON Parsing (Legitimate for complex structures)
```sql
WITH RECURSIVE json_flatten AS (
    SELECT 0 as depth, 'root' as path, json_data as value
    FROM json_table
    
    UNION ALL
    
    SELECT depth + 1,
           path || '.' || key,
           value->key
    FROM json_flatten,
         json_object_keys(value) as key
    WHERE json_typeof(value) = 'object' AND depth < 5
)
SELECT depth, path, value FROM json_flatten;
```

## 📊 5. Mathematical & Theoretical

### Prime Numbers (Sieve - Legitimate)
```sql
WITH RECURSIVE primes AS (
    SELECT 2 as num, ARRAY[2] as primes_list
    UNION ALL
    SELECT num + 1,
           CASE WHEN num % ALL(SELECT unnest(primes_list)) != 0 
                THEN primes_list || num 
                ELSE primes_list END
    FROM primes WHERE num < 20
)
SELECT unnest(primes_list) as prime_number FROM primes;
```

### Permutations (Legitimate for small sets)
```sql
WITH RECURSIVE permutations AS (
    SELECT 1 as perm_id, ARRAY['A', 'B', 'C'] as permutation
    UNION ALL SELECT 2, ARRAY['A', 'C', 'B']
    UNION ALL SELECT 3, ARRAY['B', 'A', 'C']
    UNION ALL SELECT 4, ARRAY['B', 'C', 'A']
    UNION ALL SELECT 5, ARRAY['C', 'A', 'B']
    UNION ALL SELECT 6, ARRAY['C', 'B', 'A']
)
SELECT perm_id, array_to_string(permutation, ', ') as permutation
FROM permutations ORDER BY perm_id;
```

## 🎮 6. Simulation & State Machines

### Inventory Simulation (Legitimate)
```sql
WITH RECURSIVE inventory_sim AS (
    SELECT 0 as day, 100 as stock, 0 as demand
    UNION ALL
    SELECT day + 1,
           GREATEST(0, stock - demand),
           (RANDOM() * 30 + 10)::INT as demand
    FROM inventory_sim WHERE day < 10
)
SELECT day, stock, demand,
       CASE WHEN stock < 20 THEN 'Reorder' ELSE 'OK' END as status
FROM inventory_sim;
```

## 🔧 7. Data Repair & Healing

### Sequence Gaps (Legitimate)
```sql
WITH RECURSIVE gaps AS (
    SELECT MIN(sequence_num) as start_gap,
           MIN(sequence_num) as end_gap
    FROM sequence_data
    
    UNION ALL
    
    SELECT g.end_gap + 1,
           (SELECT MIN(sequence_num) 
            FROM sequence_data 
            WHERE sequence_num > g.end_gap)
    FROM gaps g
    WHERE g.end_gap < (SELECT MAX(sequence_num) FROM sequence_data)
)
SELECT start_gap, end_gap - 1 as end_gap
FROM gaps WHERE start_gap < end_gap;
```

## 🎯 Interview Tips

### When to Use Recursive CTEs
1. **Hierarchical Data** - Trees, graphs, organizational structures
2. **Graph Algorithms** - Path finding, cycle detection, reachability
3. **Mathematical Sequences** - Where each step depends on previous steps
4. **Complex Data Transformation** - Nested structures, complex parsing
5. **Simulation** - Multi-step processes, state machines

### When NOT to Use Recursive CTEs
1. **Simple Series** - Use `generate_series()` instead
2. **Running Totals** - Use window functions instead
3. **Forward Fill** - Use `IGNORE NULLS` window functions (PostgreSQL 12+)
4. **Simple String Operations** - Use built-in string functions
5. **Basic Aggregations** - Use `GROUP BY` and window functions

### Common Patterns
1. **Base Case** - Always start with a non-recursive query
2. **Recursive Case** - Reference the CTE itself in the UNION ALL
3. **Termination** - Include a condition to stop recursion
4. **Cycle Prevention** - Use path tracking for graph traversal

### Performance Considerations
- **Limit recursion depth** - Use WHERE clauses to prevent infinite loops
- **Index optimization** - Ensure proper indexes on join columns
- **Memory usage** - Monitor for large result sets
- **Execution time** - Use EXPLAIN ANALYZE for optimization

### Common Mistakes
- ❌ Missing base case
- ❌ No termination condition
- ❌ Infinite recursion loops
- ❌ Incorrect join conditions
- ❌ Missing cycle detection
- ❌ Using recursion when simpler alternatives exist

## 📚 Additional Resources

- **Complete Examples**: [Recursive CTE Quest](../quests/recursive-cte/)
- **Learning Path**: [Structured Learning](./learning-path.md)
- **Use Cases**: [Industry Applications](./use-cases.md)
- **Documentation**: [Full Documentation](./README.md)

---

*Follow this cheatsheet to ace your SQL interviews and master recursive CTEs! 🚀* 