# Problem 22: Latest Order Per Customer

**Difficulty:** Advanced
**Concepts:** DISTINCT ON, Window functions, ROW_NUMBER, Subqueries, Deduplication
**Phase:** Advanced Features (Days 14-16)

---

## Learning Objectives

- Master PostgreSQL's DISTINCT ON clause
- Understand deduplication strategies
- Compare DISTINCT ON vs window functions
- Work with ordering within groups
- Learn when each approach is most efficient
- Handle "top N per group" scenarios

---

## Concept Summary

**DISTINCT ON** is a PostgreSQL extension that returns the first row of each group based on the ORDER BY clause. It's more flexible than basic DISTINCT and often more efficient than window functions for selecting one record per group.

### Syntax

```sql
-- DISTINCT ON syntax
SELECT DISTINCT ON (column1, column2)
    columns
FROM table
ORDER BY column1, column2, ordering_column;

-- Important: ORDER BY must start with DISTINCT ON columns
-- Returns first row for each unique combination of DISTINCT ON columns
-- Based on the complete ORDER BY clause
```

### DISTINCT ON vs Window Functions

| DISTINCT ON | Window Functions |
|-------------|------------------|
| PostgreSQL specific | Standard SQL |
| Faster for "first per group" | More flexible |
| Simpler syntax | Can get multiple rows per group |
| Limited to one row per group | Can rank, number, etc. |
| Less memory usage | More functionality |

---

## Problem Statement

**Task:** Find the most recent order for each customer. Show customer name, email, order date, status, and amount.

**Given:**
- customers table: (id, name, email, registration_date)
- orders table: (id, customer_id, order_date, status, amount)

**Requirements:**
1. One order per customer (the latest)
2. Include customer details
3. Show order information
4. Order results by customer name

---

## Hint

Use DISTINCT ON with ORDER BY order_date DESC to get the latest order, or use ROW_NUMBER() window function with WHERE rn = 1.

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

```sql
-- Method 1: DISTINCT ON (PostgreSQL-specific, most efficient)
SELECT DISTINCT ON (c.id)
    c.name,
    c.email,
    o.order_date,
    o.status,
    o.amount
FROM customers c
JOIN orders o ON c.id = o.customer_id
ORDER BY c.id, o.order_date DESC;
```

### Explanation

1. `DISTINCT ON (c.id)` - Returns one row per customer
2. `ORDER BY c.id, o.order_date DESC` - First by customer (required), then by date (determines which row)
3. For each customer, gets the row with the latest order_date
4. JOIN ensures we only get customers who have orders
5. Most efficient method for this specific use case

### Alternative Solutions

```sql
-- Method 2: Window function with ROW_NUMBER
WITH ranked_orders AS (
    SELECT
        c.name,
        c.email,
        o.order_date,
        o.status,
        o.amount,
        ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY o.order_date DESC) as rn
    FROM customers c
    JOIN orders o ON c.id = o.customer_id
)
SELECT name, email, order_date, status, amount
FROM ranked_orders
WHERE rn = 1;

-- Method 3: Correlated subquery
SELECT
    c.name,
    c.email,
    o.order_date,
    o.status,
    o.amount
FROM customers c
JOIN orders o ON c.id = o.customer_id
WHERE o.order_date = (
    SELECT MAX(order_date)
    FROM orders
    WHERE customer_id = c.id
);

-- Method 4: Using LATERAL join (PostgreSQL)
SELECT
    c.name,
    c.email,
    latest.order_date,
    latest.status,
    latest.amount
FROM customers c
JOIN LATERAL (
    SELECT order_date, status, amount
    FROM orders
    WHERE customer_id = c.id
    ORDER BY order_date DESC
    LIMIT 1
) latest ON true;

-- Method 5: Include customers with no orders (LEFT JOIN + DISTINCT ON)
SELECT DISTINCT ON (c.id)
    c.name,
    c.email,
    o.order_date,
    o.status,
    o.amount
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
ORDER BY c.id, o.order_date DESC NULLS LAST;
```

---

## Try These Variations

1. Get the latest 3 orders per customer
2. Get first and last order for each customer
3. Find customers whose latest order was cancelled
4. Get latest order per customer per year
5. Show time between latest and second-latest order
6. Find customers with only one order
7. Get latest order amount vs average order amount per customer

### Solutions to Variations

```sql
-- 1. Latest 3 orders per customer
SELECT name, email, order_date, status, amount, order_rank
FROM (
    SELECT
        c.name,
        c.email,
        o.order_date,
        o.status,
        o.amount,
        ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY o.order_date DESC) as order_rank
    FROM customers c
    JOIN orders o ON c.id = o.customer_id
) ranked
WHERE order_rank <= 3
ORDER BY name, order_rank;

-- 2. First and last order for each customer
SELECT
    c.name,
    c.email,
    FIRST_VALUE(o.order_date) OVER w as first_order,
    LAST_VALUE(o.order_date) OVER w as last_order,
    FIRST_VALUE(o.amount) OVER w as first_amount,
    LAST_VALUE(o.amount) OVER w as last_amount,
    COUNT(*) OVER w as total_orders
FROM customers c
JOIN orders o ON c.id = o.customer_id
WINDOW w AS (
    PARTITION BY c.id
    ORDER BY o.order_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
)
-- Remove duplicates
WHERE o.order_date IN (
    SELECT MIN(order_date) FROM orders WHERE customer_id = c.id
    UNION
    SELECT MAX(order_date) FROM orders WHERE customer_id = c.id
);

-- Cleaner approach with DISTINCT ON twice
WITH first_orders AS (
    SELECT DISTINCT ON (c.id)
        c.id as customer_id,
        c.name,
        c.email,
        o.order_date as first_order_date,
        o.amount as first_order_amount
    FROM customers c
    JOIN orders o ON c.id = o.customer_id
    ORDER BY c.id, o.order_date ASC
),
last_orders AS (
    SELECT DISTINCT ON (c.id)
        c.id as customer_id,
        o.order_date as last_order_date,
        o.amount as last_order_amount
    FROM customers c
    JOIN orders o ON c.id = o.customer_id
    ORDER BY c.id, o.order_date DESC
)
SELECT
    f.name,
    f.email,
    f.first_order_date,
    f.first_order_amount,
    l.last_order_date,
    l.last_order_amount,
    l.last_order_date - f.first_order_date as customer_lifespan_days
FROM first_orders f
JOIN last_orders l ON f.customer_id = l.customer_id;

-- 3. Latest order was cancelled
SELECT DISTINCT ON (c.id)
    c.name,
    c.email,
    o.order_date,
    o.status,
    o.amount
FROM customers c
JOIN orders o ON c.id = o.customer_id
WHERE o.status = 'cancelled'
ORDER BY c.id, o.order_date DESC;

-- Alternative: All customers whose most recent order was cancelled
SELECT c.name, c.email, o.order_date, o.status, o.amount
FROM customers c
JOIN orders o ON c.id = o.customer_id
WHERE o.order_date = (
    SELECT MAX(order_date)
    FROM orders
    WHERE customer_id = c.id
)
AND o.status = 'cancelled';

-- 4. Latest order per customer per year
SELECT DISTINCT ON (c.id, EXTRACT(YEAR FROM o.order_date))
    c.name,
    EXTRACT(YEAR FROM o.order_date) as year,
    o.order_date,
    o.status,
    o.amount
FROM customers c
JOIN orders o ON c.id = o.customer_id
ORDER BY c.id, EXTRACT(YEAR FROM o.order_date), o.order_date DESC;

-- 5. Time between latest and second-latest order
WITH ranked_orders AS (
    SELECT
        c.id,
        c.name,
        o.order_date,
        ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY o.order_date DESC) as rn
    FROM customers c
    JOIN orders o ON c.id = o.customer_id
)
SELECT
    name,
    MAX(CASE WHEN rn = 1 THEN order_date END) as latest_order,
    MAX(CASE WHEN rn = 2 THEN order_date END) as second_latest,
    MAX(CASE WHEN rn = 1 THEN order_date END) -
    MAX(CASE WHEN rn = 2 THEN order_date END) as days_between
FROM ranked_orders
WHERE rn <= 2
GROUP BY id, name
HAVING COUNT(*) = 2  -- Only customers with at least 2 orders
ORDER BY days_between;

-- 6. Customers with only one order
SELECT
    c.name,
    c.email,
    o.order_date,
    o.amount,
    COUNT(*) OVER (PARTITION BY c.id) as order_count
FROM customers c
JOIN orders o ON c.id = o.customer_id
WHERE c.id IN (
    SELECT customer_id
    FROM orders
    GROUP BY customer_id
    HAVING COUNT(*) = 1
);

-- 7. Latest order amount vs average
WITH customer_stats AS (
    SELECT
        c.id,
        c.name,
        c.email,
        AVG(o.amount) as avg_order_amount,
        COUNT(*) as total_orders
    FROM customers c
    JOIN orders o ON c.id = o.customer_id
    GROUP BY c.id, c.name, c.email
),
latest_orders AS (
    SELECT DISTINCT ON (c.id)
        c.id,
        o.order_date,
        o.amount as latest_amount
    FROM customers c
    JOIN orders o ON c.id = o.customer_id
    ORDER BY c.id, o.order_date DESC
)
SELECT
    cs.name,
    cs.email,
    lo.order_date as latest_order_date,
    lo.latest_amount,
    ROUND(cs.avg_order_amount, 2) as avg_amount,
    cs.total_orders,
    ROUND(lo.latest_amount - cs.avg_order_amount, 2) as diff_from_avg,
    CASE
        WHEN lo.latest_amount > cs.avg_order_amount THEN 'Above Average'
        WHEN lo.latest_amount < cs.avg_order_amount THEN 'Below Average'
        ELSE 'Average'
    END as comparison
FROM customer_stats cs
JOIN latest_orders lo ON cs.id = lo.id
ORDER BY diff_from_avg DESC;
```

---

## Sample Output

```
      name       |         email          |  order_date  |   status   |  amount
-----------------+------------------------+--------------+------------+---------
 Alice Johnson   | alice@example.com      | 2024-01-15   | completed  | 1250.00
 Bob Smith       | bob@example.com        | 2024-01-20   | pending    |  800.50
 Carol White     | carol@example.com      | 2024-01-18   | completed  | 2100.75
 David Brown     | david@example.com      | 2024-01-22   | processing |  450.00
 Emma Davis      | emma@example.com       | 2024-01-19   | completed  | 1800.25
```

---

## Common Mistakes

1. **Wrong ORDER BY with DISTINCT ON:**
   ```sql
   -- WRONG: ORDER BY must start with DISTINCT ON columns
   SELECT DISTINCT ON (customer_id)
       name, order_date
   FROM orders
   ORDER BY order_date DESC;  -- ERROR!

   -- CORRECT:
   SELECT DISTINCT ON (customer_id)
       name, order_date
   FROM orders
   ORDER BY customer_id, order_date DESC;
   ```

2. **Forgetting ties with MAX:**
   - Correlated subquery with MAX can return multiple rows if there are ties
   - Use ROW_NUMBER or DISTINCT ON to guarantee one row

3. **NULLS handling:**
   ```sql
   -- Without NULLS LAST, NULL dates come first with DESC
   ORDER BY c.id, o.order_date DESC NULLS LAST;
   ```

4. **Performance with correlated subqueries:**
   - Correlated subqueries can be slow on large datasets
   - DISTINCT ON or LATERAL joins are usually faster

5. **Including customers without orders:**
   - Use LEFT JOIN with DISTINCT ON
   - Be careful with ORDER BY when NULLs are involved

6. **Using DISTINCT instead of DISTINCT ON:**
   - `DISTINCT` removes duplicate rows
   - `DISTINCT ON` selects specific rows per group

---

## Performance Comparison

```sql
-- Benchmark different approaches
EXPLAIN ANALYZE
-- Method 1: DISTINCT ON (usually fastest)
SELECT DISTINCT ON (customer_id)
    customer_id, order_date, amount
FROM orders
ORDER BY customer_id, order_date DESC;

EXPLAIN ANALYZE
-- Method 2: Window function (more flexible but slower)
SELECT customer_id, order_date, amount
FROM (
    SELECT
        customer_id,
        order_date,
        amount,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) as rn
    FROM orders
) ranked
WHERE rn = 1;

EXPLAIN ANALYZE
-- Method 3: LATERAL (good for complex filtering)
SELECT c.id, latest.order_date, latest.amount
FROM customers c
JOIN LATERAL (
    SELECT order_date, amount
    FROM orders
    WHERE customer_id = c.id
    ORDER BY order_date DESC
    LIMIT 1
) latest ON true;
```

### Performance Tips
- Index on (customer_id, order_date DESC) helps all methods
- DISTINCT ON is usually fastest for simple cases
- Window functions better when you need multiple ranks
- LATERAL joins good for complex per-group logic

```sql
-- Optimal index
CREATE INDEX idx_orders_customer_date
ON orders(customer_id, order_date DESC);
```

---

## When to Use Each Method

### Use DISTINCT ON when:
- PostgreSQL database
- Need exactly one row per group
- Simple ordering logic
- Performance is critical

### Use Window Functions when:
- Need portable SQL (works on all databases)
- Want top N per group (not just top 1)
- Need multiple ranks or statistics
- Complex analytical requirements

### Use LATERAL when:
- Complex per-group filtering
- Need to reference outer query columns
- Per-group aggregations or calculations

### Use Correlated Subquery when:
- Simple MAX/MIN selection
- Small datasets
- Readable code is priority

---

## Real-World Use Cases

1. **Customer activity:** Last login, last purchase, last interaction
2. **Inventory:** Most recent stock update per product
3. **Monitoring:** Latest status per server/service
4. **Analytics:** Most recent conversion per campaign
5. **Audit logs:** Latest change per record
6. **Time series:** Latest reading per sensor

---

## Related Problems

- **Previous:** [Problem 21 - Pattern Matching](../21-pattern-matching/)
- **Next:** [Problem 23 - Index Usage Analysis](../23-index-usage-analysis/)
- **Related:** Problem 10 (Window Functions), Problem 24 (LATERAL Joins), Problem 20 (Analytics)

---

## Notes

```
Your notes here:




```

---

[← Previous](../21-pattern-matching/) | [Back to Overview](../../README.md) | [Next Problem →](../23-index-usage-analysis/)
