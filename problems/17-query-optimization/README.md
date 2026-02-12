# Problem 17: Query Optimization

**Difficulty:** Advanced
**Concepts:** EXPLAIN, EXPLAIN ANALYZE, Index strategies, Query planning, Performance tuning
**Phase:** Query Optimization (Days 17-18)

---

## Learning Objectives

- Understand query execution plans
- Use EXPLAIN and EXPLAIN ANALYZE
- Identify performance bottlenecks
- Create effective indexes
- Apply query optimization techniques
- Recognize when queries need optimization

---

## Concept Summary

**Query optimization** improves query performance through better indexes, query structure, and understanding execution plans.

### EXPLAIN Syntax

```sql
-- Show execution plan (no execution)
EXPLAIN
SELECT columns FROM table WHERE condition;

-- Show plan with actual execution statistics
EXPLAIN ANALYZE
SELECT columns FROM table WHERE condition;

-- Additional options (PostgreSQL)
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, FORMAT JSON)
SELECT columns FROM table WHERE condition;
```

### Key Execution Plan Terms

```
Seq Scan          -- Sequential scan (reads entire table)
Index Scan        -- Uses index, fetches rows
Index Only Scan   -- Uses index, no table lookup needed
Bitmap Index Scan -- Multiple indexes combined
Nested Loop       -- Join method for small tables
Hash Join         -- Join method for larger tables
Merge Join        -- Join on sorted data

Cost: X..Y        -- Estimated startup cost .. total cost
Rows              -- Estimated number of rows
Width             -- Average row size in bytes
Actual time       -- Real execution time (with ANALYZE)
```

---

## Problem Statement

**Given slow query:**

```sql
SELECT * FROM orders o
WHERE YEAR(order_date) = 2023
  AND (status = 'pending' OR status = 'processing');
```

**Task:**
1. Use EXPLAIN ANALYZE to identify performance issues
2. Optimize the query
3. Create appropriate indexes
4. Verify performance improvement

---

## Hint

Avoid functions on indexed columns in WHERE clause. Use range comparisons instead.

---

## Your Solution

```sql
-- Step 1: Analyze original query
EXPLAIN ANALYZE


-- Step 2: Write optimized query


-- Step 3: Create indexes


-- Step 4: Re-analyze optimized query


```

---

## Solution

### Step 1: Analyze Original Query

```sql
EXPLAIN ANALYZE
SELECT * FROM orders o
WHERE YEAR(order_date) = 2023
  AND (status = 'pending' OR status = 'processing');

-- Likely output:
-- Seq Scan on orders  (cost=0.00..1234.56 rows=100 width=128)
--   Filter: ((date_part('year', order_date) = 2023) AND ...)
-- Planning Time: 0.123 ms
-- Execution Time: 45.678 ms
```

**Problems identified:**
1. `SELECT *` retrieves unnecessary columns
2. `YEAR(order_date)` prevents index usage
3. `OR` conditions can be slow
4. No indexes visible in plan

### Step 2: Optimized Query

```sql
-- Optimized version
SELECT order_id, customer_id, order_date, status, amount
FROM orders
WHERE order_date >= '2023-01-01'
  AND order_date < '2024-01-01'
  AND status IN ('pending', 'processing');
```

**Improvements:**
1. Select only needed columns
2. Use range comparison instead of function
3. Use IN instead of OR
4. Index-friendly conditions

### Step 3: Create Indexes

```sql
-- Composite index (most specific first)
CREATE INDEX idx_orders_date_status ON orders(order_date, status);

-- Or separate indexes
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_status ON orders(status);

-- Covering index (includes all needed columns)
CREATE INDEX idx_orders_covering ON orders(order_date, status)
INCLUDE (order_id, customer_id, amount);
```

### Step 4: Verify Improvement

```sql
EXPLAIN ANALYZE
SELECT order_id, customer_id, order_date, status, amount
FROM orders
WHERE order_date >= '2023-01-01'
  AND order_date < '2024-01-01'
  AND status IN ('pending', 'processing');

-- Expected output:
-- Index Scan using idx_orders_date_status  (cost=0.42..123.45 rows=100 width=48)
--   Index Cond: ((order_date >= '2023-01-01') AND (order_date < '2024-01-01'))
--   Filter: (status IN ('pending', 'processing'))
-- Planning Time: 0.234 ms
-- Execution Time: 2.345 ms  (was 45.678 ms - ~95% improvement!)
```

---

## Common Query Anti-Patterns

### 1. Functions on Indexed Columns

```sql
-- BAD: Prevents index usage
WHERE YEAR(order_date) = 2023
WHERE UPPER(email) = 'TEST@EXAMPLE.COM'
WHERE DATE_TRUNC('day', created_at) = '2024-01-01'

-- GOOD: Index-friendly
WHERE order_date >= '2023-01-01' AND order_date < '2024-01-01'
WHERE email = 'test@example.com'  -- Store lowercase in DB
WHERE created_at >= '2024-01-01' AND created_at < '2024-01-02'
```

### 2. SELECT *

```sql
-- BAD: Retrieves unnecessary data
SELECT * FROM large_table WHERE id = 123;

-- GOOD: Only needed columns
SELECT id, name, status FROM large_table WHERE id = 123;
```

### 3. Correlated Subqueries

```sql
-- BAD: Executes subquery for every row
SELECT e.name,
    (SELECT AVG(salary) FROM employees e2 WHERE e2.dept_id = e.dept_id)
FROM employees e;

-- GOOD: Use JOIN or window function
SELECT e.name, AVG(e2.salary) OVER (PARTITION BY e.dept_id)
FROM employees e;
```

### 4. OR on Different Columns

```sql
-- BAD: Can't use multiple indexes efficiently
WHERE column1 = 'value1' OR column2 = 'value2'

-- GOOD: Use UNION (if selectivity is high)
SELECT * FROM table WHERE column1 = 'value1'
UNION
SELECT * FROM table WHERE column2 = 'value2';
```

### 5. NOT IN with Large Subquery

```sql
-- BAD: Slow, NULL issues
WHERE id NOT IN (SELECT user_id FROM large_table)

-- GOOD: Use NOT EXISTS
WHERE NOT EXISTS (SELECT 1 FROM large_table WHERE user_id = id)
```

---

## Index Strategy

### When to Index

```sql
-- Index columns used in:
-- 1. WHERE clauses
CREATE INDEX idx_orders_status ON orders(status);

-- 2. JOIN conditions
CREATE INDEX idx_order_items_order_id ON order_items(order_id);

-- 3. ORDER BY clauses
CREATE INDEX idx_products_price ON products(price);

-- 4. Foreign keys (always!)
CREATE INDEX idx_employees_dept_id ON employees(dept_id);
```

### Composite Index Order

```sql
-- Order matters! Most selective column first
-- Query: WHERE city = 'NYC' AND status = 'active' AND age > 25

-- GOOD: city is most selective
CREATE INDEX idx_users_city_status_age ON users(city, status, age);

-- Can use this index for:
-- WHERE city = 'NYC'
-- WHERE city = 'NYC' AND status = 'active'
-- WHERE city = 'NYC' AND status = 'active' AND age > 25

-- Cannot use efficiently for:
-- WHERE status = 'active'  -- city not specified
-- WHERE age > 25           -- city not specified
```

### When NOT to Index

```sql
-- 1. Small tables (< 1000 rows usually)
-- 2. Columns with low cardinality (few distinct values)
--    e.g., boolean, status with 2-3 values
-- 3. Tables with frequent INSERT/UPDATE/DELETE
-- 4. Columns rarely used in queries
```

---

## Optimization Examples

### Example 1: Subquery to JOIN

```sql
-- BEFORE: Slow correlated subquery
SELECT
    c.name,
    (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.id) as order_count
FROM customers c;

-- AFTER: Fast JOIN with GROUP BY
SELECT
    c.name,
    COUNT(o.id) as order_count
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
GROUP BY c.id, c.name;
```

### Example 2: Reducing Result Set Early

```sql
-- BEFORE: Filter after join (processes all data)
SELECT e.name, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.id
WHERE d.dept_name = 'Engineering';

-- AFTER: Filter before join (fewer rows to join)
SELECT e.name, d.dept_name
FROM employees e
JOIN (
    SELECT id, dept_name
    FROM departments
    WHERE dept_name = 'Engineering'
) d ON e.dept_id = d.id;
```

### Example 3: Covering Index

```sql
-- Query needs: user_id, email, created_at
SELECT user_id, email, created_at
FROM users
WHERE status = 'active'
ORDER BY created_at DESC
LIMIT 100;

-- Create covering index (no table lookup needed)
CREATE INDEX idx_users_covering ON users(status, created_at DESC)
INCLUDE (user_id, email);

-- Result: Index Only Scan (fastest)
```

### Example 4: Partial Index

```sql
-- Query only checks active users
SELECT * FROM users
WHERE status = 'active' AND city = 'New York';

-- Partial index (smaller, faster)
CREATE INDEX idx_users_active_city ON users(city)
WHERE status = 'active';
```

---

## EXPLAIN Output Deep Dive

### Reading the Plan

```sql
EXPLAIN ANALYZE
SELECT o.order_id, c.name, p.name, oi.quantity
FROM orders o
JOIN customers c ON o.customer_id = c.id
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id
WHERE o.order_date >= '2024-01-01'
  AND o.status = 'completed';
```

**Sample output:**
```
Hash Join  (cost=156.78..234.56 rows=45 width=128) (actual time=2.345..5.678 rows=42 loops=1)
  Hash Cond: (oi.product_id = p.id)
  ->  Hash Join  (cost=78.90..123.45 rows=45 width=96) (actual time=1.234..3.456 rows=42 loops=1)
        Hash Cond: (oi.order_id = o.id)
        ->  Seq Scan on order_items oi  (cost=0.00..34.56 rows=1234 width=16)
        ->  Hash  (cost=67.89..67.89 rows=45 width=88)
              ->  Hash Join  (cost=23.45..67.89 rows=45 width=88)
                    Hash Cond: (o.customer_id = c.id)
                    ->  Index Scan using idx_orders_date on orders o  (cost=0.42..43.21 rows=45 width=48)
                          Index Cond: (order_date >= '2024-01-01')
                          Filter: (status = 'completed')
                    ->  Hash  (cost=12.34..12.34 rows=789 width=48)
                          ->  Seq Scan on customers c  (cost=0.00..12.34 rows=789 width=48)
  ->  Hash  (cost=45.67..45.67 rows=2345 width=40)
        ->  Seq Scan on products p  (cost=0.00..45.67 rows=2345 width=40)
Planning Time: 0.456 ms
Execution Time: 6.123 ms
```

**Key observations:**
1. Orders table uses index (good!)
2. order_items uses Seq Scan (consider index on order_id)
3. Hash Joins used (appropriate for data size)
4. Estimated rows (45) close to actual (42) - good statistics

---

## Try These Optimizations

1. Optimize a query with multiple OR conditions
2. Convert a correlated subquery to window function
3. Add appropriate indexes and measure improvement
4. Use partial index for common filter
5. Create covering index for frequent query

### Solutions

```sql
-- 1. Multiple OR conditions
-- BEFORE
SELECT * FROM products
WHERE category = 'Electronics' OR category = 'Books' OR price > 1000;

-- AFTER
SELECT * FROM products WHERE category IN ('Electronics', 'Books')
UNION
SELECT * FROM products WHERE price > 1000;

-- 2. Correlated subquery to window function
-- BEFORE
SELECT
    employee_id,
    salary,
    (SELECT AVG(salary) FROM employees e2 WHERE e2.dept_id = e1.dept_id) as avg_dept_salary
FROM employees e1;

-- AFTER
SELECT
    employee_id,
    salary,
    AVG(salary) OVER (PARTITION BY dept_id) as avg_dept_salary
FROM employees;

-- 3. Measure improvement
-- Check before
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE status = 'pending' ORDER BY order_date DESC LIMIT 100;

-- Add index
CREATE INDEX idx_orders_status_date ON orders(status, order_date DESC);

-- Check after
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE status = 'pending' ORDER BY order_date DESC LIMIT 100;

-- 4. Partial index
-- Only index recent, active orders
CREATE INDEX idx_orders_recent ON orders(order_date)
WHERE status IN ('pending', 'processing')
  AND order_date >= CURRENT_DATE - INTERVAL '90 days';

-- 5. Covering index
-- Frequent query
SELECT product_id, name, price FROM products
WHERE category = 'Electronics' AND in_stock = true
ORDER BY price;

-- Covering index
CREATE INDEX idx_products_category_stock_price ON products(category, in_stock, price)
INCLUDE (product_id, name);
```

---

## Common Mistakes

1. **Over-indexing:** Too many indexes slow writes
2. **Wrong index order:** Least selective column first
3. **Ignoring statistics:** Run ANALYZE after bulk changes
4. **Not testing with real data:** Test with production-like volume
5. **Premature optimization:** Profile first, optimize what matters
6. **Ignoring EXPLAIN warnings:** "Rows removed by filter" indicates issues

---

## Performance Checklist

- [ ] SELECT only needed columns (not *)
- [ ] WHERE conditions are index-friendly (no functions on columns)
- [ ] Foreign keys have indexes
- [ ] JOIN columns have indexes
- [ ] Appropriate indexes exist (use EXPLAIN)
- [ ] Statistics are up-to-date (run ANALYZE)
- [ ] OR conditions converted to UNION or IN
- [ ] Correlated subqueries minimized
- [ ] Result set limited when possible (LIMIT)
- [ ] Query tested with production-like data volume

---

## Real-World Use Cases

1. **Slow reports:** Dashboards loading slowly
2. **API timeouts:** Database queries taking too long
3. **High CPU usage:** Inefficient queries consuming resources
4. **Deadlocks:** Poor index strategy causing locks
5. **Capacity planning:** Understanding query costs

---

## Related Problems

- **Previous:** [Problem 16 - Orphaned Records](../16-orphaned-records/)
- **Next:** [Problem 18 - Organization Hierarchy](../18-organization-hierarchy/)
- **Related:** Problem 23 (Index Analysis), All problems (apply optimization)

---

## Notes

```
Your notes here:




```

---

[← Previous](../16-orphaned-records/) | [Back to Overview](../../README.md) | [Next Problem →](../18-organization-hierarchy/)
