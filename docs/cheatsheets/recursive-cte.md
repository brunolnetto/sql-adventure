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

---

## 🔬 **Advanced Patterns**

### **Complex Workflow State Machine**
```sql
-- Model complex business workflows with state transitions
WITH RECURSIVE workflow_states AS (
    -- Base case: starting states
    SELECT 
        state_id,
        state_name,
        workflow_type,
        ARRAY[state_id] as path,
        ARRAY[state_name] as path_names,
        0 as path_length,
        is_final
    FROM workflow_states 
    WHERE state_name = 'START'
    
    UNION ALL
    
    -- Recursive case: follow transitions
    SELECT 
        ws.state_id,
        ws.state_name,
        ws.workflow_type,
        wf.path || ws.state_id,
        wf.path_names || ws.state_name,
        wf.path_length + 1,
        ws.is_final
    FROM workflow_states ws
    INNER JOIN workflow_transitions wt ON ws.state_id = wt.to_state_id
    INNER JOIN workflow_states wf ON wt.from_state_id = wf.state_id
    WHERE wf.path_length < 10  -- Prevent infinite loops
      AND NOT (ws.state_id = ANY(wf.path))  -- Prevent cycles
),
workflow_analytics AS (
    SELECT 
        wi.instance_id,
        wi.workflow_type,
        wi.current_state_id,
        ws.state_name,
        wi.started_at,
        wi.updated_at,
        wi.data,
        -- Time spent in current state
        EXTRACT(EPOCH FROM (wi.updated_at - wi.started_at)) / 3600 as hours_in_state,
        -- Workflow duration
        EXTRACT(EPOCH FROM (wi.updated_at - wi.started_at)) / 3600 as total_hours,
        -- State ranking by duration
        RANK() OVER (PARTITION BY wi.workflow_type ORDER BY wi.updated_at - wi.started_at DESC) as duration_rank,
        -- Bottleneck detection
        AVG(EXTRACT(EPOCH FROM (wi.updated_at - wi.started_at))) OVER (PARTITION BY wi.current_state_id) as avg_state_duration,
        -- Workflow progress
        CASE 
            WHEN ws.is_final THEN 100
            ELSE (wp.path_length * 100.0 / MAX(wp.path_length) OVER (PARTITION BY wi.workflow_type))
        END as progress_percentage
    FROM workflow_instances wi
    INNER JOIN workflow_states ws ON wi.current_state_id = ws.state_id
    LEFT JOIN workflow_states wp ON ws.state_id = wp.state_id
    WHERE wi.updated_at >= CURRENT_DATE - INTERVAL '30 days'
)
SELECT 
    instance_id,
    workflow_type,
    state_name,
    hours_in_state,
    total_hours,
    duration_rank,
    avg_state_duration,
    progress_percentage,
    -- Performance insights
    CASE 
        WHEN hours_in_state > avg_state_duration * 2 THEN 'Bottleneck'
        WHEN progress_percentage < 25 THEN 'Stuck Early'
        WHEN progress_percentage > 75 AND NOT ws.is_final THEN 'Near Completion'
        ELSE 'Normal Progress'
    END as workflow_status,
    -- Extract key metrics from JSON data
    data->>'priority' as priority,
    data->>'assigned_to' as assigned_to,
    data->>'estimated_hours' as estimated_hours
FROM workflow_analytics wa
INNER JOIN workflow_states ws ON wa.current_state_id = ws.state_id
ORDER BY workflow_type, duration_rank;
```

### **Multi-Dimensional Business Intelligence**
```sql
-- Comprehensive business intelligence with multiple data sources
WITH RECURSIVE customer_network AS (
    -- Base case: customers with referrals
    SELECT 
        c.customer_id,
        c.name,
        c.segment,
        c.attributes->>'referred_by' as referred_by,
        0 as network_level,
        ARRAY[c.customer_id] as network_path
    FROM customers c
    WHERE c.attributes->>'referred_by' IS NULL
    
    UNION ALL
    
    -- Recursive case: referred customers
    SELECT 
        c.customer_id,
        c.name,
        c.segment,
        c.attributes->>'referred_by',
        cn.network_level + 1,
        cn.network_path || c.customer_id
    FROM customers c
    INNER JOIN customer_network cn ON c.attributes->>'referred_by' = cn.customer_id::TEXT
    WHERE cn.network_level < 3
),
sales_analytics AS (
    SELECT 
        s.sale_id,
        s.customer_id,
        s.product_id,
        s.quantity,
        s.unit_price,
        s.sale_date,
        s.region,
        s.channel,
        c.segment,
        p.category,
        cn.network_level,
        -- Revenue calculations
        s.quantity * s.unit_price as revenue,
        s.quantity * (s.unit_price - p.cost) as profit,
        -- Customer analytics
        SUM(s.quantity * s.unit_price) OVER (
            PARTITION BY s.customer_id 
            ORDER BY s.sale_date 
            ROWS UNBOUNDED PRECEDING
        ) as customer_lifetime_value,
        -- Product performance
        RANK() OVER (PARTITION BY p.category ORDER BY s.quantity * s.unit_price DESC) as category_rank,
        -- Regional trends
        AVG(s.quantity * s.unit_price) OVER (
            PARTITION BY s.region 
            ORDER BY s.sale_date 
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) as regional_30day_avg,
        -- Segment analysis
        PERCENT_RANK() OVER (PARTITION BY c.segment ORDER BY s.quantity * s.unit_price) as segment_percentile,
        -- Channel performance
        ROW_NUMBER() OVER (PARTITION BY s.channel ORDER BY s.sale_date DESC) as channel_recency_rank
    FROM sales s
    INNER JOIN customers c ON s.customer_id = c.customer_id
    INNER JOIN products p ON s.product_id = p.product_id
    LEFT JOIN customer_network cn ON s.customer_id = cn.customer_id
    WHERE s.sale_date >= CURRENT_DATE - INTERVAL '90 days'
),
enriched_analytics AS (
    SELECT 
        *,
        -- Extract customer preferences from JSON
        sa.metadata->>'payment_method' as payment_method,
        sa.metadata->>'campaign_id' as campaign_id,
        -- Extract product features
        p.attributes->>'brand' as brand,
        p.attributes->>'size' as size,
        p.attributes->>'color' as color,
        -- Extract customer attributes
        c.attributes->>'loyalty_tier' as loyalty_tier,
        c.attributes->>'preferred_category' as preferred_category
    FROM sales_analytics sa
    INNER JOIN customers c ON sa.customer_id = c.customer_id
    INNER JOIN products p ON sa.product_id = p.product_id
)
SELECT 
    customer_id,
    segment,
    region,
    category,
    channel,
    network_level,
    loyalty_tier,
    payment_method,
    -- Key metrics
    revenue,
    profit,
    customer_lifetime_value,
    category_rank,
    regional_30day_avg,
    segment_percentile,
    channel_recency_rank,
    -- Business insights
    CASE 
        WHEN customer_lifetime_value > 10000 THEN 'High Value'
        WHEN customer_lifetime_value > 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END as customer_value_tier,
    CASE 
        WHEN regional_30day_avg > revenue * 1.5 THEN 'Above Regional Average'
        WHEN regional_30day_avg < revenue * 0.5 THEN 'Below Regional Average'
        ELSE 'Regional Average'
    END as regional_performance,
    CASE 
        WHEN segment_percentile > 0.8 THEN 'Top Performer'
        WHEN segment_percentile < 0.2 THEN 'Needs Attention'
        ELSE 'Average Performer'
    END as segment_performance
FROM enriched_analytics
ORDER BY customer_lifetime_value DESC, revenue DESC;
```

### **Real-Time Data Processing Pipeline**
```sql
-- Real-time data streams with complex transformations
WITH RECURSIVE session_events AS (
    SELECT 
        user_id,
        session_id,
        event_type,
        event_timestamp,
        metrics,
        analytics,
        -- Build session sequence
        ROW_NUMBER() OVER (
            PARTITION BY user_id, session_id 
            ORDER BY event_timestamp
        ) as session_sequence,
        -- Calculate session duration
        FIRST_VALUE(event_timestamp) OVER (
            PARTITION BY user_id, session_id 
            ORDER BY event_timestamp
        ) as session_start,
        LAST_VALUE(event_timestamp) OVER (
            PARTITION BY user_id, session_id 
            ORDER BY event_timestamp
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) as session_end
    FROM transformed_data
),
real_time_analytics AS (
    SELECT 
        user_id,
        session_id,
        event_type,
        event_timestamp,
        session_sequence,
        session_start,
        session_end,
        metrics,
        analytics,
        -- Session-level analytics
        COUNT(*) OVER (PARTITION BY user_id, session_id) as session_event_count,
        SUM((metrics->>'duration')::INT) OVER (PARTITION BY user_id, session_id) as session_duration,
        SUM((metrics->>'value')::DECIMAL(10,2)) OVER (PARTITION BY user_id, session_id) as session_value,
        -- User-level analytics
        COUNT(DISTINCT session_id) OVER (
            PARTITION BY user_id 
            ORDER BY event_timestamp 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) as user_session_count,
        -- Real-time trends
        AVG((metrics->>'value')::DECIMAL(10,2)) OVER (
            ORDER BY event_timestamp 
            ROWS BETWEEN 99 PRECEDING AND CURRENT ROW
        ) as global_value_trend,
        -- Event type analysis
        RANK() OVER (PARTITION BY event_type ORDER BY event_timestamp DESC) as event_recency_rank
    FROM session_events
)
SELECT 
    user_id,
    session_id,
    event_type,
    event_timestamp,
    session_sequence,
    session_event_count,
    session_duration,
    session_value,
    user_session_count,
    global_value_trend,
    event_recency_rank,
    -- Real-time alerts
    CASE 
        WHEN session_duration > 3600 THEN 'Long Session'
        WHEN session_value > global_value_trend * 3 THEN 'High Value Session'
        WHEN user_session_count > 10 THEN 'Active User'
        ELSE 'Normal Activity'
    END as activity_alert,
    -- Extract key metrics
    metrics->>'duration' as event_duration,
    metrics->>'value' as event_value,
    analytics->>'page_url' as page_url
FROM real_time_analytics
WHERE event_timestamp >= CURRENT_TIMESTAMP - INTERVAL '15 minutes'
ORDER BY event_timestamp DESC;
```

---

*Follow this cheatsheet to ace your SQL interviews and master recursive CTEs! 🚀* 