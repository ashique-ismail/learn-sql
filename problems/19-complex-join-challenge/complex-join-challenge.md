# Problem 19: Complex Join Challenge

**Difficulty:** Advanced
**Concepts:** Multiple JOINs, Complex filtering, CTEs, Data integration from multiple tables
**Phase:** Advanced Topics (Days 19-20)

---

## Learning Objectives

- Master complex multi-table joins
- Combine data from 4+ tables
- Apply filters at different join stages
- Use CTEs to organize complex queries
- Handle NULL values in joins
- Aggregate across multiple tables

---

## Concept Summary

**Complex joins** combine data from multiple tables with various conditions, requiring careful planning of join order, types, and filtering.

### Key Principles

```sql
-- 1. Join order matters for performance
-- 2. Filter early to reduce intermediate result sets
-- 3. Use appropriate join types (INNER, LEFT, etc.)
-- 4. Consider NULL handling
-- 5. Use CTEs for readability and maintenance
```

---

## Problem Statement

**Given tables:**
- customers(id, name, registration_date)
- orders(id, customer_id, order_date, amount)
- products(id, name, category)
- order_items(order_id, product_id, quantity, price)

**Task:** Find customers who:
1. Registered in 2023
2. Placed at least 3 orders
3. Ordered products from at least 2 different categories
4. Total spending > $1000

**Show:** customer name, order count, unique category count, total spending

---

## Hint

Use CTEs to break down the problem. Join all tables, then aggregate with GROUP BY and filter with HAVING.

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

### Method 1: Using CTEs for Clarity

```sql
WITH customer_stats AS (
    SELECT
        c.id,
        c.name,
        c.registration_date,
        COUNT(DISTINCT o.id) as order_count,
        COUNT(DISTINCT p.category) as category_count,
        SUM(oi.quantity * oi.price) as total_spending
    FROM customers c
    JOIN orders o ON c.id = o.customer_id
    JOIN order_items oi ON o.id = oi.order_id
    JOIN products p ON oi.product_id = p.id
    WHERE EXTRACT(YEAR FROM c.registration_date) = 2023
    GROUP BY c.id, c.name, c.registration_date
)
SELECT
    name,
    order_count,
    category_count,
    ROUND(total_spending, 2) as total_spending
FROM customer_stats
WHERE order_count >= 3
  AND category_count >= 2
  AND total_spending > 1000
ORDER BY total_spending DESC;
```

### Method 2: Single Query with Subquery

```sql
SELECT
    c.name,
    COUNT(DISTINCT o.id) as order_count,
    COUNT(DISTINCT p.category) as category_count,
    ROUND(SUM(oi.quantity * oi.price), 2) as total_spending
FROM customers c
JOIN orders o ON c.id = o.customer_id
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id
WHERE EXTRACT(YEAR FROM c.registration_date) = 2023
GROUP BY c.id, c.name
HAVING COUNT(DISTINCT o.id) >= 3
   AND COUNT(DISTINCT p.category) >= 2
   AND SUM(oi.quantity * oi.price) > 1000
ORDER BY total_spending DESC;
```

### Method 3: Multiple CTEs for Better Performance

```sql
-- Filter customers first
WITH customers_2023 AS (
    SELECT id, name
    FROM customers
    WHERE EXTRACT(YEAR FROM registration_date) = 2023
),
-- Get order details for these customers
customer_orders AS (
    SELECT
        c.id as customer_id,
        c.name,
        o.id as order_id
    FROM customers_2023 c
    JOIN orders o ON c.id = o.customer_id
),
-- Get order items with product info
order_details AS (
    SELECT
        co.customer_id,
        co.name,
        co.order_id,
        p.category,
        oi.quantity * oi.price as item_total
    FROM customer_orders co
    JOIN order_items oi ON co.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.id
),
-- Aggregate per customer
customer_aggregates AS (
    SELECT
        customer_id,
        name,
        COUNT(DISTINCT order_id) as order_count,
        COUNT(DISTINCT category) as category_count,
        SUM(item_total) as total_spending
    FROM order_details
    GROUP BY customer_id, name
)
SELECT
    name,
    order_count,
    category_count,
    ROUND(total_spending, 2) as total_spending
FROM customer_aggregates
WHERE order_count >= 3
  AND category_count >= 2
  AND total_spending > 1000
ORDER BY total_spending DESC;
```

### Explanation

1. **JOIN sequence:** customers → orders → order_items → products
2. **WHERE clause:** Filters customers registered in 2023 before aggregation
3. **GROUP BY:** Groups by customer (all columns from customers table)
4. **COUNT(DISTINCT):** Counts unique orders and categories
5. **SUM():** Calculates total spending from quantity * price
6. **HAVING clause:** Filters aggregated results
7. **ORDER BY:** Sorts by spending descending

---

## Extended Examples

### Example 1: Add More Metrics

```sql
WITH customer_analysis AS (
    SELECT
        c.id,
        c.name,
        c.email,
        c.registration_date,
        COUNT(DISTINCT o.id) as order_count,
        COUNT(DISTINCT p.category) as category_count,
        COUNT(DISTINCT p.id) as unique_products,
        SUM(oi.quantity * oi.price) as total_spending,
        AVG(oi.quantity * oi.price) as avg_item_value,
        MIN(o.order_date) as first_order_date,
        MAX(o.order_date) as last_order_date,
        STRING_AGG(DISTINCT p.category, ', ' ORDER BY p.category) as categories_ordered
    FROM customers c
    JOIN orders o ON c.id = o.customer_id
    JOIN order_items oi ON o.id = oi.order_id
    JOIN products p ON oi.product_id = p.id
    WHERE EXTRACT(YEAR FROM c.registration_date) = 2023
    GROUP BY c.id, c.name, c.email, c.registration_date
)
SELECT
    name,
    email,
    order_count,
    category_count,
    unique_products,
    ROUND(total_spending, 2) as total_spending,
    ROUND(avg_item_value, 2) as avg_item_value,
    first_order_date,
    last_order_date,
    last_order_date - first_order_date as customer_lifespan_days,
    categories_ordered,
    CASE
        WHEN total_spending > 5000 THEN 'VIP'
        WHEN total_spending > 2000 THEN 'Premium'
        ELSE 'Regular'
    END as customer_tier
FROM customer_analysis
WHERE order_count >= 3
  AND category_count >= 2
  AND total_spending > 1000
ORDER BY total_spending DESC;
```

### Example 2: Include Customers with No Orders (LEFT JOIN)

```sql
SELECT
    c.name,
    c.registration_date,
    COALESCE(COUNT(DISTINCT o.id), 0) as order_count,
    COALESCE(COUNT(DISTINCT p.category), 0) as category_count,
    COALESCE(ROUND(SUM(oi.quantity * oi.price), 2), 0) as total_spending,
    CASE
        WHEN COUNT(DISTINCT o.id) = 0 THEN 'No Orders'
        WHEN COUNT(DISTINCT o.id) < 3 THEN 'Occasional'
        ELSE 'Frequent'
    END as customer_type
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
LEFT JOIN order_items oi ON o.id = oi.order_id
LEFT JOIN products p ON oi.product_id = p.id
WHERE EXTRACT(YEAR FROM c.registration_date) = 2023
GROUP BY c.id, c.name, c.registration_date
ORDER BY order_count DESC, total_spending DESC;
```

### Example 3: Cross-Category Analysis

```sql
-- Find customers who ordered from BOTH Electronics AND Books
WITH customer_categories AS (
    SELECT
        c.id,
        c.name,
        p.category
    FROM customers c
    JOIN orders o ON c.id = o.customer_id
    JOIN order_items oi ON o.id = oi.order_id
    JOIN products p ON oi.product_id = p.id
    WHERE EXTRACT(YEAR FROM c.registration_date) = 2023
    GROUP BY c.id, c.name, p.category
)
SELECT
    cc1.name,
    COUNT(DISTINCT cc1.category) as total_categories
FROM customer_categories cc1
WHERE EXISTS (
    SELECT 1 FROM customer_categories cc2
    WHERE cc2.id = cc1.id AND cc2.category = 'Electronics'
)
AND EXISTS (
    SELECT 1 FROM customer_categories cc3
    WHERE cc3.id = cc1.id AND cc3.category = 'Books'
)
GROUP BY cc1.id, cc1.name
HAVING COUNT(DISTINCT cc1.category) >= 2;
```

---

## Try These Variations

1. Find customers who never ordered from 'Electronics' category
2. Find customers whose average order value is above $200
3. Find top 5 products by revenue from 2023 customers
4. Find customers who ordered same product multiple times
5. Compare spending between customer registration quarters

### Solutions to Variations

```sql
-- 1. Customers who never ordered Electronics
SELECT c.id, c.name
FROM customers c
WHERE EXTRACT(YEAR FROM c.registration_date) = 2023
  AND NOT EXISTS (
      SELECT 1
      FROM orders o
      JOIN order_items oi ON o.id = oi.order_id
      JOIN products p ON oi.product_id = p.id
      WHERE o.customer_id = c.id
        AND p.category = 'Electronics'
  );

-- 2. Average order value > $200
WITH order_totals AS (
    SELECT
        c.id,
        c.name,
        o.id as order_id,
        SUM(oi.quantity * oi.price) as order_total
    FROM customers c
    JOIN orders o ON c.id = o.customer_id
    JOIN order_items oi ON o.id = oi.order_id
    WHERE EXTRACT(YEAR FROM c.registration_date) = 2023
    GROUP BY c.id, c.name, o.id
)
SELECT
    id,
    name,
    COUNT(order_id) as order_count,
    ROUND(AVG(order_total), 2) as avg_order_value,
    ROUND(SUM(order_total), 2) as total_spending
FROM order_totals
GROUP BY id, name
HAVING AVG(order_total) > 200
ORDER BY avg_order_value DESC;

-- 3. Top 5 products by revenue from 2023 customers
SELECT
    p.id,
    p.name,
    p.category,
    SUM(oi.quantity) as units_sold,
    ROUND(SUM(oi.quantity * oi.price), 2) as total_revenue
FROM customers c
JOIN orders o ON c.id = o.customer_id
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id
WHERE EXTRACT(YEAR FROM c.registration_date) = 2023
GROUP BY p.id, p.name, p.category
ORDER BY total_revenue DESC
LIMIT 5;

-- 4. Customers who ordered same product multiple times
WITH product_orders AS (
    SELECT
        c.id,
        c.name,
        p.id as product_id,
        p.name as product_name,
        COUNT(DISTINCT o.id) as times_ordered,
        SUM(oi.quantity) as total_quantity
    FROM customers c
    JOIN orders o ON c.id = o.customer_id
    JOIN order_items oi ON o.id = oi.order_id
    JOIN products p ON oi.product_id = p.id
    WHERE EXTRACT(YEAR FROM c.registration_date) = 2023
    GROUP BY c.id, c.name, p.id, p.name
)
SELECT
    name,
    product_name,
    times_ordered,
    total_quantity
FROM product_orders
WHERE times_ordered > 1
ORDER BY times_ordered DESC, total_quantity DESC;

-- 5. Spending by registration quarter
SELECT
    EXTRACT(QUARTER FROM c.registration_date) as registration_quarter,
    COUNT(DISTINCT c.id) as customer_count,
    COUNT(DISTINCT o.id) as total_orders,
    ROUND(AVG(order_total.total), 2) as avg_order_value,
    ROUND(SUM(order_total.total), 2) as total_revenue
FROM customers c
JOIN orders o ON c.id = o.customer_id
JOIN (
    SELECT
        order_id,
        SUM(quantity * price) as total
    FROM order_items
    GROUP BY order_id
) order_total ON o.id = order_total.order_id
WHERE EXTRACT(YEAR FROM c.registration_date) = 2023
GROUP BY EXTRACT(QUARTER FROM c.registration_date)
ORDER BY registration_quarter;
```

---

## Sample Output

```
      name       | order_count | category_count | total_spending
-----------------+-------------+----------------+----------------
 Sarah Johnson   |      12     |       5        |    5234.50
 Mike Thompson   |       8     |       4        |    3876.25
 Emily Rodriguez |       6     |       3        |    2145.80
 David Chen      |       5     |       3        |    1842.00
 Lisa Martinez   |       4     |       2        |    1456.75
(5 rows)
```

---

## Common Mistakes

1. **Wrong join types:** Using INNER when LEFT needed (or vice versa)
2. **Cartesian products:** Forgetting join conditions
3. **Ambiguous columns:** Not specifying table aliases
4. **Incorrect aggregation:** Counting wrong things (COUNT(*) vs COUNT(DISTINCT))
5. **Filter placement:** Using HAVING instead of WHERE (or vice versa)
6. **NULL handling:** Not using COALESCE for LEFT JOINs
7. **Join order:** Inefficient join sequences

---

## Join Order Optimization

```sql
-- Less efficient: Large intermediate result
SELECT ...
FROM orders o                    -- 1,000,000 rows
JOIN order_items oi ON ...       -- 5,000,000 rows
JOIN customers c ON ...          -- 100,000 rows
WHERE c.registration_date >= '2023-01-01';  -- Filters to 10,000

-- More efficient: Filter early
WITH recent_customers AS (
    SELECT id, name
    FROM customers
    WHERE registration_date >= '2023-01-01'  -- 10,000 rows
)
SELECT ...
FROM recent_customers c
JOIN orders o ON ...
JOIN order_items oi ON ...;
```

---

## Performance Tips

1. **Filter early:** Apply WHERE before joins when possible
2. **Use CTEs:** Break complex queries into manageable steps
3. **Index foreign keys:** Critical for join performance
4. **DISTINCT carefully:** COUNT(DISTINCT) can be expensive
5. **Aggregate before join:** Reduce rows before joining large tables
6. **Use EXPLAIN:** Understand query execution plan

---

## Real-World Use Cases

1. **Customer segmentation:** Identify high-value customers
2. **Product analysis:** Cross-category purchasing patterns
3. **Sales reports:** Multi-dimensional revenue analysis
4. **Fraud detection:** Unusual purchase patterns
5. **Marketing campaigns:** Target specific customer segments
6. **Inventory planning:** Product demand across customer types

---

## Related Problems

- **Previous:** [Problem 18 - Organization Hierarchy](../18-organization-hierarchy/)
- **Next:** [Problem 20 - E-commerce Analytics](../20-ecommerce-analytics/)
- **Related:** Problem 6 (Basic JOINs), Problem 9 (CTEs), Problem 20 (Complex Analytics)

---

## Notes

```
Your notes here:




```

---

[← Previous](../18-organization-hierarchy/) | [Back to Overview](../../README.md) | [Next Problem →](../20-ecommerce-analytics/)
