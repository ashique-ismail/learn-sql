# Problem 24: Top Products Per Category

**Difficulty:** Advanced
**Concepts:** LATERAL joins, Advanced joins, Correlated subqueries, Window functions, Top-N per group
**Phase:** Advanced Topics (Days 19-20)

---

## Learning Objectives

- Master LATERAL joins in PostgreSQL
- Understand when LATERAL outperforms window functions
- Solve "top N per group" problems efficiently
- Compare different approaches for grouped queries
- Learn cross-lateral optimization techniques
- Work with complex JOIN patterns

---

## Concept Summary

**LATERAL joins** allow subqueries in the FROM clause to reference columns from preceding table references. This enables powerful per-row subquery execution, particularly useful for "top N per group" queries.

### Syntax

```sql
-- Basic LATERAL syntax
SELECT columns
FROM table1 t1
JOIN LATERAL (
    SELECT columns
    FROM table2 t2
    WHERE t2.foreign_key = t1.primary_key
    ORDER BY some_column
    LIMIT n
) subquery ON true;

-- LEFT JOIN LATERAL (includes rows with no matches)
SELECT columns
FROM table1 t1
LEFT JOIN LATERAL (
    SELECT columns
    FROM table2
    WHERE t2.key = t1.key
    LIMIT n
) subquery ON true;
```

### LATERAL vs Window Functions

| LATERAL Joins | Window Functions |
|--------------|------------------|
| True LIMIT per group | Must filter after ranking |
| Can stop early (efficient) | Processes all rows |
| More flexible filtering | Simpler for rankings |
| Better for top N | Better for all rows with rank |
| Works with LIMIT | No LIMIT in window |

### How LATERAL Works

1. For each row in the outer table
2. Execute the LATERAL subquery
3. Use outer table columns in subquery
4. Join results back to outer row
5. Process next outer row

---

## Problem Statement

**Task:** Find the top 3 most expensive products in each category. Show category, product name, and price.

**Given:**
- categories table: (id, category_name, description)
- products table: (id, name, category_id, price, stock_quantity)

**Requirements:**
1. Get top 3 products per category
2. Order by price (highest first)
3. Include category name
4. Handle categories with fewer than 3 products

---

## Hint

Use LATERAL join with LIMIT 3, or window functions with ROW_NUMBER() and WHERE rank <= 3.

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

```sql
-- Method 1: LATERAL join (most efficient for top N)
SELECT
    c.category_name,
    p.name,
    p.price
FROM categories c
JOIN LATERAL (
    SELECT name, price
    FROM products
    WHERE category_id = c.id
    ORDER BY price DESC
    LIMIT 3
) p ON true
ORDER BY c.category_name, p.price DESC;
```

### Explanation

1. `FROM categories c` - Outer table with category list
2. `JOIN LATERAL (...)` - For each category, execute subquery
3. `WHERE category_id = c.id` - References outer table (requires LATERAL)
4. `ORDER BY price DESC LIMIT 3` - Gets top 3 per category
5. `ON true` - Always join (lateral subquery already filtered)
6. More efficient than window functions because it can stop at 3 rows per category

### Alternative Solutions

```sql
-- Method 2: Window function with ROW_NUMBER
WITH ranked_products AS (
    SELECT
        c.category_name,
        p.name,
        p.price,
        ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY p.price DESC) as rank
    FROM categories c
    JOIN products p ON c.id = p.category_id
)
SELECT category_name, name, price
FROM ranked_products
WHERE rank <= 3
ORDER BY category_name, price DESC;

-- Method 3: Correlated subquery (less efficient)
SELECT
    c.category_name,
    p.name,
    p.price
FROM categories c
JOIN products p ON c.id = p.category_id
WHERE p.id IN (
    SELECT id
    FROM products p2
    WHERE p2.category_id = c.id
    ORDER BY p2.price DESC
    LIMIT 3
)
ORDER BY c.category_name, p.price DESC;

-- Method 4: DISTINCT ON with array (alternative approach)
SELECT
    c.category_name,
    (unnest(top_products)).name,
    (unnest(top_products)).price
FROM (
    SELECT
        c.id,
        c.category_name,
        ARRAY(
            SELECT ROW(p.name, p.price)::product_info
            FROM products p
            WHERE p.category_id = c.id
            ORDER BY p.price DESC
            LIMIT 3
        ) as top_products
    FROM categories c
) sub;

-- Method 5: Using LEFT JOIN LATERAL (includes categories with no products)
SELECT
    c.category_name,
    p.name,
    p.price
FROM categories c
LEFT JOIN LATERAL (
    SELECT name, price
    FROM products
    WHERE category_id = c.id
    ORDER BY price DESC
    LIMIT 3
) p ON true
ORDER BY c.category_name, p.price DESC NULLS LAST;
```

---

## Try These Variations

1. Get top 5 products by sales volume per category
2. Get cheapest and most expensive product per category
3. Get top 3 products per category with running total
4. Find categories where top product is above $1000
5. Get top 2 customers by spending per city
6. Get latest 3 orders per customer
7. Get top performing employees per department

### Solutions to Variations

```sql
-- 1. Top 5 by sales volume
SELECT
    c.category_name,
    p.name,
    sales_data.total_quantity,
    sales_data.total_revenue
FROM categories c
JOIN LATERAL (
    SELECT
        p.id,
        p.name,
        SUM(oi.quantity) as total_quantity,
        SUM(oi.quantity * oi.price) as total_revenue
    FROM products p
    JOIN order_items oi ON p.id = oi.product_id
    WHERE p.category_id = c.id
    GROUP BY p.id, p.name
    ORDER BY SUM(oi.quantity) DESC
    LIMIT 5
) sales_data ON true
ORDER BY c.category_name, sales_data.total_quantity DESC;

-- 2. Cheapest and most expensive per category
SELECT
    c.category_name,
    cheapest.name as cheapest_product,
    cheapest.price as min_price,
    expensive.name as most_expensive_product,
    expensive.price as max_price
FROM categories c
JOIN LATERAL (
    SELECT name, price
    FROM products
    WHERE category_id = c.id
    ORDER BY price ASC
    LIMIT 1
) cheapest ON true
JOIN LATERAL (
    SELECT name, price
    FROM products
    WHERE category_id = c.id
    ORDER BY price DESC
    LIMIT 1
) expensive ON true
ORDER BY c.category_name;

-- 3. Top 3 with running total
SELECT
    c.category_name,
    p.name,
    p.price,
    SUM(p.price) OVER (
        PARTITION BY c.id
        ORDER BY p.price DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as running_total
FROM categories c
JOIN LATERAL (
    SELECT name, price
    FROM products
    WHERE category_id = c.id
    ORDER BY price DESC
    LIMIT 3
) p ON true
ORDER BY c.category_name, p.price DESC;

-- 4. Categories where top product > $1000
SELECT
    c.category_name,
    top_product.name,
    top_product.price
FROM categories c
JOIN LATERAL (
    SELECT name, price
    FROM products
    WHERE category_id = c.id
    ORDER BY price DESC
    LIMIT 1
) top_product ON true
WHERE top_product.price > 1000
ORDER BY top_product.price DESC;

-- 5. Top 2 customers by spending per city
SELECT
    u.city,
    customer_data.customer_name,
    customer_data.total_spent,
    customer_data.order_count
FROM (SELECT DISTINCT city FROM users) u
JOIN LATERAL (
    SELECT
        u2.name as customer_name,
        SUM(o.amount) as total_spent,
        COUNT(o.id) as order_count
    FROM users u2
    JOIN orders o ON u2.id = o.user_id
    WHERE u2.city = u.city
      AND o.status = 'completed'
    GROUP BY u2.id, u2.name
    ORDER BY SUM(o.amount) DESC
    LIMIT 2
) customer_data ON true
ORDER BY u.city, customer_data.total_spent DESC;

-- 6. Latest 3 orders per customer
SELECT
    c.name as customer_name,
    c.email,
    recent_orders.order_date,
    recent_orders.status,
    recent_orders.amount
FROM customers c
JOIN LATERAL (
    SELECT order_date, status, amount
    FROM orders
    WHERE customer_id = c.id
    ORDER BY order_date DESC
    LIMIT 3
) recent_orders ON true
ORDER BY c.name, recent_orders.order_date DESC;

-- 7. Top performing employees per department
SELECT
    d.dept_name,
    top_emp.name as employee_name,
    top_emp.project_count,
    top_emp.total_hours
FROM departments d
JOIN LATERAL (
    SELECT
        e.name,
        COUNT(DISTINCT pa.project_id) as project_count,
        SUM(pa.hours_allocated) as total_hours
    FROM employees e
    JOIN project_assignments pa ON e.id = pa.employee_id
    WHERE e.dept_id = d.id
    GROUP BY e.id, e.name
    ORDER BY SUM(pa.hours_allocated) DESC
    LIMIT 3
) top_emp ON true
ORDER BY d.dept_name, top_emp.total_hours DESC;
```

---

## Sample Output

```
 category_name  |     name          |  price
----------------+-------------------+---------
 Electronics    | Premium Laptop    | 2499.99
 Electronics    | 4K Smart TV       | 1899.99
 Electronics    | Wireless Headset  |  349.99
 Furniture      | Leather Sofa      | 1299.00
 Furniture      | Office Desk       |  599.99
 Furniture      | Ergonomic Chair   |  449.99
 Clothing       | Designer Jacket   |  299.99
 Clothing       | Running Shoes     |  149.99
 Clothing       | Casual Shirt      |   49.99
```

---

## Performance Comparison

```sql
-- Test with EXPLAIN ANALYZE

-- Method 1: LATERAL (usually fastest for top N)
EXPLAIN ANALYZE
SELECT c.category_name, p.name, p.price
FROM categories c
JOIN LATERAL (
    SELECT name, price
    FROM products
    WHERE category_id = c.id
    ORDER BY price DESC
    LIMIT 3
) p ON true;

-- Method 2: Window function (processes all rows)
EXPLAIN ANALYZE
SELECT category_name, name, price
FROM (
    SELECT
        c.category_name,
        p.name,
        p.price,
        ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY p.price DESC) as rn
    FROM categories c
    JOIN products p ON c.id = p.category_id
) ranked
WHERE rn <= 3;

-- Method 3: Multiple passes (slowest)
EXPLAIN ANALYZE
SELECT
    c.category_name,
    p.name,
    p.price
FROM categories c
JOIN products p ON c.id = p.category_id
WHERE (
    SELECT COUNT(*)
    FROM products p2
    WHERE p2.category_id = c.id
      AND p2.price > p.price
) < 3
ORDER BY c.category_name, p.price DESC;
```

### When to Use Each Method

**Use LATERAL when:**
- Need exactly top N rows per group
- N is small (e.g., top 3, top 5)
- Want to stop early per group
- Performance is critical

**Use Window Functions when:**
- Need ranks for analysis
- Want all rows with their ranks
- Need multiple statistics per row
- More portable code (standard SQL)

**Use Correlated Subquery when:**
- Simple logic
- Small datasets
- Backward compatibility needed

---

## Common Mistakes

1. **Forgetting LATERAL keyword:**
   ```sql
   -- WRONG: Can't reference c.id without LATERAL
   FROM categories c
   JOIN (
       SELECT name FROM products WHERE category_id = c.id
   ) p ON true;

   -- CORRECT:
   FROM categories c
   JOIN LATERAL (
       SELECT name FROM products WHERE category_id = c.id
   ) p ON true;
   ```

2. **Using ON condition instead of WHERE:**
   ```sql
   -- Less efficient (filters after join)
   JOIN LATERAL (
       SELECT name FROM products LIMIT 3
   ) p ON p.category_id = c.id;

   -- Better (filters in subquery)
   JOIN LATERAL (
       SELECT name FROM products
       WHERE category_id = c.id
       LIMIT 3
   ) p ON true;
   ```

3. **Missing ORDER BY before LIMIT:**
   - LIMIT without ORDER BY gives unpredictable results
   - Always specify ORDER BY for top N

4. **Not considering NULL values:**
   - ORDER BY price DESC NULLS LAST
   - Handle NULLs explicitly

5. **Inefficient indexes:**
   ```sql
   -- Create appropriate index
   CREATE INDEX idx_products_category_price
   ON products(category_id, price DESC);
   ```

---

## Advanced LATERAL Patterns

```sql
-- Pattern 1: Multiple LATERAL joins
SELECT
    c.category_name,
    top_product.name as top_product,
    top_product.price,
    avg_price.avg_price
FROM categories c
JOIN LATERAL (
    SELECT name, price
    FROM products
    WHERE category_id = c.id
    ORDER BY price DESC
    LIMIT 1
) top_product ON true
JOIN LATERAL (
    SELECT AVG(price) as avg_price
    FROM products
    WHERE category_id = c.id
) avg_price ON true;

-- Pattern 2: LATERAL with aggregation
SELECT
    c.category_name,
    stats.product_count,
    stats.avg_price,
    stats.total_value
FROM categories c
JOIN LATERAL (
    SELECT
        COUNT(*) as product_count,
        AVG(price) as avg_price,
        SUM(price * stock_quantity) as total_value
    FROM products
    WHERE category_id = c.id
) stats ON true
WHERE stats.product_count > 0;

-- Pattern 3: Nested LATERAL
SELECT
    d.dept_name,
    emp_projects.employee_name,
    emp_projects.top_project_name,
    emp_projects.project_hours
FROM departments d
JOIN LATERAL (
    SELECT
        e.id as emp_id,
        e.name as employee_name,
        (
            SELECT JSON_BUILD_OBJECT(
                'name', p.name,
                'hours', pa.hours_allocated
            )
            FROM project_assignments pa
            JOIN projects p ON pa.project_id = p.id
            WHERE pa.employee_id = e.id
            ORDER BY pa.hours_allocated DESC
            LIMIT 1
        ) as top_project
    FROM employees e
    WHERE e.dept_id = d.id
    LIMIT 5
) emp_data ON true
JOIN LATERAL (
    SELECT
        emp_data.employee_name,
        emp_data.top_project->>'name' as top_project_name,
        (emp_data.top_project->>'hours')::INTEGER as project_hours
) emp_projects ON true;

-- Pattern 4: LATERAL with UNION
SELECT
    category_name,
    product_type,
    name,
    price
FROM categories c
JOIN LATERAL (
    SELECT 'Expensive' as product_type, name, price
    FROM products
    WHERE category_id = c.id
    ORDER BY price DESC
    LIMIT 2

    UNION ALL

    SELECT 'Cheap' as product_type, name, price
    FROM products
    WHERE category_id = c.id
    ORDER BY price ASC
    LIMIT 2
) products ON true
ORDER BY c.category_name, product_type, price DESC;
```

---

## Optimization Tips

```sql
-- 1. Create proper indexes
CREATE INDEX idx_products_category_price
ON products(category_id, price DESC);

CREATE INDEX idx_products_category_sales
ON products(category_id, sales_count DESC);

-- 2. Use covering indexes when possible
CREATE INDEX idx_products_covering
ON products(category_id, price DESC)
INCLUDE (name, stock_quantity);

-- 3. Analyze query performance
EXPLAIN (ANALYZE, BUFFERS) your_lateral_query;

-- 4. Consider materialized views for complex queries
CREATE MATERIALIZED VIEW top_products_per_category AS
SELECT
    c.category_name,
    p.name,
    p.price
FROM categories c
JOIN LATERAL (
    SELECT name, price
    FROM products
    WHERE category_id = c.id
    ORDER BY price DESC
    LIMIT 3
) p ON true;

-- Refresh as needed
REFRESH MATERIALIZED VIEW top_products_per_category;
```

---

## Real-World Use Cases

1. **E-commerce:** Top products per category, related items
2. **Social media:** Latest posts per user, top comments
3. **Analytics:** Best performing items per segment
4. **Recommendations:** Similar products, frequently bought together
5. **Reporting:** Top N performers per group
6. **Time series:** Recent readings per sensor
7. **Leaderboards:** Top players per region/game

---

## Related Problems

- **Previous:** [Problem 23 - Index Usage Analysis](../23-index-usage-analysis/)
- **Next:** [Problem 25 - Find Missing Days](../25-find-missing-days/)
- **Related:** Problem 10 (Window Functions), Problem 22 (DISTINCT ON), Problem 20 (Analytics)

---

## Notes

```
Your notes here:




```

---

[← Previous](../23-index-usage-analysis/) | [Back to Overview](../../README.md) | [Next Problem →](../25-find-missing-days/)
