# Problem 23: Index Usage Analysis

**Difficulty:** Advanced
**Concepts:** EXPLAIN ANALYZE, Index creation, Query optimization, Performance tuning, Execution plans
**Phase:** Query Optimization (Days 17-18)

---

## Learning Objectives

- Master EXPLAIN and EXPLAIN ANALYZE
- Understand query execution plans
- Identify performance bottlenecks
- Create effective indexes
- Learn index types and when to use them
- Measure query performance improvements
- Understand cost estimation

---

## Concept Summary

**EXPLAIN** shows how PostgreSQL will execute a query. **EXPLAIN ANALYZE** actually runs the query and shows real timing data. These tools are essential for optimization.

### Syntax

```sql
-- Show execution plan (doesn't run query)
EXPLAIN SELECT columns FROM table WHERE condition;

-- Show execution plan with actual timing (runs query)
EXPLAIN ANALYZE SELECT columns FROM table WHERE condition;

-- Additional options
EXPLAIN (ANALYZE, BUFFERS, VERBOSE) SELECT ...;
EXPLAIN (FORMAT JSON) SELECT ...;
```

### Key Execution Plan Nodes

```
Seq Scan          -- Full table scan (slow for large tables)
Index Scan        -- Uses index to find specific rows (fast)
Index Only Scan   -- Gets data entirely from index (fastest)
Bitmap Index Scan -- Scans index, builds bitmap of matching rows
Bitmap Heap Scan  -- Fetches rows from heap using bitmap
Nested Loop       -- Join method: for each row in outer, scan inner
Hash Join         -- Build hash table, then probe (good for large tables)
Merge Join        -- Sort both sides, then merge
Sort              -- Explicit sort operation
```

### Understanding Cost

```
cost=0.00..123.45
     ^       ^
     |       |
  startup  total cost

rows=100        -- Estimated rows returned
width=50        -- Average row width in bytes
actual time=0.123..4.567  -- Real timing (milliseconds)
```

---

## Problem Statement

**Task:** Find all orders with products from 'Electronics' category. First write a query, then use EXPLAIN to analyze it, and suggest appropriate indexes to improve performance.

**Given:**
- orders table: (id, customer_id, order_date, status, amount)
- order_items table: (id, order_id, product_id, quantity, price)
- products table: (id, name, category, price, stock_quantity)

**Requirements:**
1. Write initial query
2. Analyze with EXPLAIN ANALYZE
3. Identify bottlenecks
4. Create indexes
5. Measure improvement

---

## Hint

Use EXPLAIN ANALYZE to see actual execution times. Look for "Seq Scan" on large tables - these often need indexes. Create covering indexes when possible.

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

### Step 1: Initial Query

```sql
-- Query without optimization
SELECT
    o.id,
    o.order_date,
    p.name as product_name,
    oi.quantity,
    oi.price
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id
WHERE p.category = 'Electronics'
  AND o.status = 'completed';
```

### Step 2: Analyze Initial Performance

```sql
EXPLAIN ANALYZE
SELECT
    o.id,
    o.order_date,
    p.name as product_name,
    oi.quantity,
    oi.price
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id
WHERE p.category = 'Electronics'
  AND o.status = 'completed';
```

**Expected Output (before optimization):**
```
Hash Join  (cost=234.56..789.12 rows=150 width=64) (actual time=12.456..45.789 rows=150 loops=1)
  Hash Cond: (oi.order_id = o.id)
  ->  Hash Join  (cost=123.45..456.78 rows=500 width=48) (actual time=5.234..23.456 rows=500 loops=1)
        Hash Cond: (oi.product_id = p.id)
        ->  Seq Scan on order_items oi  (cost=0.00..234.56 rows=10000 width=24) (actual time=0.012..8.234 rows=10000 loops=1)
        ->  Hash  (cost=100.23..100.23 rows=50 width=32) (actual time=2.345..2.345 rows=50 loops=1)
              Buckets: 1024  Batches: 1  Memory Usage: 10kB
              ->  Seq Scan on products p  (cost=0.00..100.23 rows=50 width=32) (actual time=0.023..1.234 rows=50 loops=1)
                    Filter: (category = 'Electronics'::text)
                    Rows Removed by Filter: 450
  ->  Hash  (cost=89.12..89.12 rows=1200 width=24) (actual time=3.456..3.456 rows=1200 loops=1)
        Buckets: 2048  Batches: 1  Memory Usage: 72kB
        ->  Seq Scan on orders o  (cost=0.00..89.12 rows=1200 width=24) (actual time=0.015..2.345 rows=1200 loops=1)
              Filter: (status = 'completed'::text)
              Rows Removed by Filter: 800

Planning Time: 0.456 ms
Execution Time: 46.234 ms
```

### Step 3: Identify Issues

**Problems found:**
1. Seq Scan on products table (filter on category)
2. Seq Scan on orders table (filter on status)
3. Seq Scan on order_items table (full table scan)
4. No index usage at all

### Step 4: Create Indexes

```sql
-- Index 1: Products by category (for WHERE clause)
CREATE INDEX idx_products_category ON products(category);

-- Index 2: Orders by status (for WHERE clause)
CREATE INDEX idx_orders_status ON orders(status);

-- Index 3: Order items for joins (foreign keys)
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- Index 4: Covering index for products (includes all needed columns)
CREATE INDEX idx_products_category_covering
ON products(category) INCLUDE (id, name, price);

-- Index 5: Composite index for order_items joins
CREATE INDEX idx_order_items_composite
ON order_items(product_id, order_id) INCLUDE (quantity, price);
```

### Step 5: Analyze After Optimization

```sql
EXPLAIN ANALYZE
SELECT
    o.id,
    o.order_date,
    p.name as product_name,
    oi.quantity,
    oi.price
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id
WHERE p.category = 'Electronics'
  AND o.status = 'completed';
```

**Expected Output (after optimization):**
```
Nested Loop  (cost=1.23..45.67 rows=150 width=64) (actual time=0.234..2.345 rows=150 loops=1)
  ->  Nested Loop  (cost=0.56..23.45 rows=500 width=48) (actual time=0.123..1.234 rows=500 loops=1)
        ->  Index Scan using idx_products_category on products p  (cost=0.15..12.34 rows=50 width=32) (actual time=0.045..0.234 rows=50 loops=1)
              Index Cond: (category = 'Electronics'::text)
        ->  Index Scan using idx_order_items_product_id on order_items oi  (cost=0.42..8.89 rows=10 width=24) (actual time=0.012..0.123 rows=10 loops=50)
              Index Cond: (product_id = p.id)
  ->  Index Scan using idx_orders_status on orders o  (cost=0.42..1.23 rows=1 width=24) (actual time=0.002..0.002 rows=0 loops=500)
        Index Cond: (id = oi.order_id)
        Filter: (status = 'completed'::text)

Planning Time: 0.234 ms
Execution Time: 2.567 ms
```

### Performance Improvement

```
Before: 46.234 ms
After:   2.567 ms
Speedup: ~18x faster
```

---

## Alternative Approaches

```sql
-- Approach 1: Using EXISTS (sometimes faster)
EXPLAIN ANALYZE
SELECT
    o.id,
    o.order_date,
    p.name as product_name,
    oi.quantity,
    oi.price
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id
WHERE o.status = 'completed'
  AND EXISTS (
      SELECT 1 FROM products p2
      WHERE p2.id = p.id AND p2.category = 'Electronics'
  );

-- Approach 2: Filter early with subquery
EXPLAIN ANALYZE
SELECT
    o.id,
    o.order_date,
    p.name as product_name,
    oi.quantity,
    oi.price
FROM (
    SELECT * FROM orders WHERE status = 'completed'
) o
JOIN order_items oi ON o.id = oi.order_id
JOIN (
    SELECT * FROM products WHERE category = 'Electronics'
) p ON oi.product_id = p.id;

-- Approach 3: Materialized CTE (for complex queries)
EXPLAIN ANALYZE
WITH electronics_products AS MATERIALIZED (
    SELECT id, name, price
    FROM products
    WHERE category = 'Electronics'
),
completed_orders AS MATERIALIZED (
    SELECT id, order_date
    FROM orders
    WHERE status = 'completed'
)
SELECT
    o.id,
    o.order_date,
    p.name as product_name,
    oi.quantity,
    oi.price
FROM completed_orders o
JOIN order_items oi ON o.id = oi.order_id
JOIN electronics_products p ON oi.product_id = p.id;
```

---

## Try These Variations

1. Analyze a query with ORDER BY and LIMIT
2. Compare index scan vs sequential scan on small tables
3. Test partial indexes for frequently filtered data
4. Analyze impact of multiple WHERE conditions
5. Compare different join orders
6. Test covering indexes vs regular indexes
7. Analyze query with aggregations and GROUP BY

### Solutions to Variations

```sql
-- 1. ORDER BY and LIMIT optimization
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE status = 'completed'
ORDER BY order_date DESC
LIMIT 10;

-- Index to optimize this query
CREATE INDEX idx_orders_status_date ON orders(status, order_date DESC);

-- 2. Force sequential scan to compare
SET enable_seqscan = ON;
SET enable_indexscan = OFF;
EXPLAIN ANALYZE SELECT * FROM products WHERE category = 'Electronics';

-- Reset and compare with index scan
RESET enable_seqscan;
RESET enable_indexscan;
EXPLAIN ANALYZE SELECT * FROM products WHERE category = 'Electronics';

-- 3. Partial index (only for active/completed orders)
CREATE INDEX idx_orders_active ON orders(order_date)
WHERE status IN ('pending', 'processing', 'completed');

EXPLAIN ANALYZE
SELECT * FROM orders
WHERE status = 'completed' AND order_date > '2024-01-01';

-- 4. Multiple WHERE conditions
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE status = 'completed'
  AND order_date >= '2024-01-01'
  AND amount > 1000;

-- Composite index for all conditions
CREATE INDEX idx_orders_multi
ON orders(status, order_date, amount)
WHERE status = 'completed';

-- 5. Join order comparison
EXPLAIN ANALYZE
SELECT *
FROM small_table s
JOIN large_table l ON s.id = l.small_id;

-- vs
EXPLAIN ANALYZE
SELECT *
FROM large_table l
JOIN small_table s ON s.id = l.small_id;

-- 6. Covering index example
-- Regular index
CREATE INDEX idx_emp_dept ON employees(department);

EXPLAIN ANALYZE
SELECT name, salary FROM employees WHERE department = 'Engineering';
-- Still needs heap access for name and salary

-- Covering index
CREATE INDEX idx_emp_dept_covering
ON employees(department) INCLUDE (name, salary);

EXPLAIN ANALYZE
SELECT name, salary FROM employees WHERE department = 'Engineering';
-- Index Only Scan (faster, no heap access)

-- 7. Aggregation optimization
EXPLAIN ANALYZE
SELECT
    department,
    COUNT(*) as emp_count,
    AVG(salary) as avg_salary
FROM employees
GROUP BY department;

-- Can benefit from index on GROUP BY column
CREATE INDEX idx_emp_dept_salary ON employees(department, salary);
```

---

## Sample EXPLAIN Output Analysis

```
Nested Loop  (cost=0.56..123.45 rows=100 width=64) (actual time=0.123..4.567 rows=98 loops=1)
  ^           ^startup  ^total   ^estimate         ^real timing     ^actual  ^loops
  |           |cost     |cost     |rows                             |rows
  |           |                                                      |
  Node type   Start cost to        Estimated                        Actual rows
              get first row        rows returned                    returned

Buffers: shared hit=245 read=12 dirtied=3 written=2
         ^
         |
         Cache statistics: hit=from cache, read=from disk
```

### What to Look For

**Bad signs:**
- Seq Scan on large tables
- High cost values
- Actual rows >> estimated rows (bad statistics)
- Many loops with high cost
- Sorts on large datasets
- Nested loops with large outer table

**Good signs:**
- Index Scan or Index Only Scan
- Low actual time
- Actual rows ≈ estimated rows
- Hash Join for large tables
- Bitmap scans for moderate selectivity

---

## Index Types in PostgreSQL

```sql
-- 1. B-tree (default) - Good for most cases
CREATE INDEX idx_btree ON table(column);

-- 2. Hash - Only for equality (=)
CREATE INDEX idx_hash ON table USING HASH(column);

-- 3. GiST - For geometric, full-text, etc.
CREATE INDEX idx_gist ON table USING GIST(column);

-- 4. GIN - For arrays, JSON, full-text
CREATE INDEX idx_gin ON table USING GIN(json_column);

-- 5. BRIN - For large tables with natural ordering
CREATE INDEX idx_brin ON table USING BRIN(timestamp_column);

-- 6. Partial index - Only for subset of rows
CREATE INDEX idx_partial ON orders(order_date)
WHERE status = 'completed';

-- 7. Expression index - Index on computed value
CREATE INDEX idx_expression ON users(LOWER(email));

-- 8. Multi-column index - For multiple columns
CREATE INDEX idx_multi ON orders(customer_id, order_date DESC);

-- 9. Covering index - Includes extra columns
CREATE INDEX idx_covering ON orders(status) INCLUDE (order_date, amount);

-- 10. Unique index - Enforces uniqueness
CREATE UNIQUE INDEX idx_unique ON users(email);
```

---

## Index Maintenance

```sql
-- Check index usage
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC;

-- Find unused indexes
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND indexrelname NOT LIKE 'pg_toast%';

-- Rebuild bloated index
REINDEX INDEX idx_name;
REINDEX TABLE table_name;

-- Update statistics (important for query planner)
ANALYZE table_name;
ANALYZE;  -- All tables

-- Check table bloat
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

---

## Common Mistakes

1. **Over-indexing:**
   - Too many indexes slow down INSERT/UPDATE/DELETE
   - Each index uses disk space
   - Keep only useful indexes

2. **Wrong column order in composite indexes:**
   - `(status, date)` ≠ `(date, status)`
   - Most selective column should usually be first
   - Match query WHERE clause order

3. **Not updating statistics:**
   - Query planner needs fresh statistics
   - Run ANALYZE regularly

4. **Indexing small tables:**
   - Sequential scan is faster for small tables
   - PostgreSQL may ignore your index

5. **Ignoring EXPLAIN ANALYZE results:**
   - "Estimated rows" vs "Actual rows" discrepancy
   - Indicates stale statistics

6. **Creating indexes without testing:**
   - Always verify with EXPLAIN ANALYZE
   - Measure before and after

---

## Performance Tuning Checklist

```sql
-- 1. Run EXPLAIN ANALYZE
EXPLAIN ANALYZE your_query;

-- 2. Look for bottlenecks
-- - Sequential scans on large tables?
-- - High cost operations?
-- - Incorrect row estimates?

-- 3. Create appropriate indexes
-- - Index WHERE clause columns
-- - Index JOIN columns
-- - Consider covering indexes

-- 4. Update statistics
ANALYZE your_table;

-- 5. Re-run EXPLAIN ANALYZE
EXPLAIN ANALYZE your_query;

-- 6. Compare performance
-- - Check actual time improvement
-- - Verify index is being used
-- - Test with real data volume

-- 7. Monitor index usage over time
SELECT * FROM pg_stat_user_indexes WHERE tablename = 'your_table';
```

---

## Real-World Use Cases

1. **Slow queries:** Identify and fix performance issues
2. **Production optimization:** Before deployment, verify query performance
3. **Index strategy:** Decide which indexes to create
4. **Query refactoring:** Compare different query approaches
5. **Capacity planning:** Estimate resource needs
6. **Performance regression:** Detect when queries slow down

---

## Related Problems

- **Previous:** [Problem 22 - Latest Order Per Customer](../22-latest-order-per-customer/)
- **Next:** [Problem 24 - Top Products Per Category](../24-top-products-per-category/)
- **Related:** Problem 17 (Query Optimization), Problem 20 (Complex Analytics), Problem 30 (Dashboard Queries)

---

## Notes

```
Your notes here:




```

---

[← Previous](../22-latest-order-per-customer/) | [Back to Overview](../../README.md) | [Next Problem →](../24-top-products-per-category/)
