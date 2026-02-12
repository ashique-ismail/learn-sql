# Problem 27: Multi-Table Update

**Difficulty:** Advanced
**Concepts:** Complex UPDATE with joins, Subqueries in UPDATE, FROM clause, CASE in UPDATE, Data modification
**Phase:** Data Manipulation (Days 10-11) + Advanced

---

## Learning Objectives

- Master UPDATE statements with JOIN syntax
- Use subqueries in UPDATE operations
- Update based on aggregated data
- Handle conditional updates with CASE
- Work with UPDATE...FROM pattern (PostgreSQL)
- Understand transaction safety
- Verify updates before committing

---

## Concept Summary

**Complex UPDATE statements** allow you to modify data based on values from other tables or aggregated calculations. This is essential for maintaining data consistency and implementing business logic.

### Syntax

```sql
-- PostgreSQL UPDATE...FROM syntax
UPDATE table1
SET column = new_value
FROM table2
WHERE table1.key = table2.key;

-- UPDATE with subquery
UPDATE table1
SET column = (
    SELECT value
    FROM table2
    WHERE table2.key = table1.key
)
WHERE condition;

-- UPDATE with CASE
UPDATE table
SET column = CASE
    WHEN condition1 THEN value1
    WHEN condition2 THEN value2
    ELSE default_value
END
WHERE condition;

-- UPDATE with aggregation
UPDATE table1 t1
SET column = subquery.agg_value
FROM (
    SELECT key, AGG_FUNC(value) as agg_value
    FROM table2
    GROUP BY key
) subquery
WHERE t1.key = subquery.key;
```

### Database-Specific Syntax

```sql
-- PostgreSQL
UPDATE products p
SET price = new_prices.price
FROM new_prices
WHERE p.id = new_prices.product_id;

-- MySQL
UPDATE products p
JOIN new_prices np ON p.id = np.product_id
SET p.price = np.price;

-- Standard SQL (works everywhere but less efficient)
UPDATE products
SET price = (
    SELECT price
    FROM new_prices
    WHERE new_prices.product_id = products.id
)
WHERE EXISTS (
    SELECT 1
    FROM new_prices
    WHERE new_prices.product_id = products.id
);
```

---

## Problem Statement

**Task:** Update product prices based on sales performance:
- Increase by 10% if product sold > 50 units total
- Decrease by 5% if product sold < 10 units total
- Keep same if between 10-50 units
- Also track the last price update date

**Given:**
- products table: (id, name, category, price, stock_quantity, last_price_update)
- orders table: (id, customer_id, order_date, status)
- order_items table: (id, order_id, product_id, quantity, price)

**Requirements:**
1. Calculate total sales per product
2. Update prices based on sales volume
3. Round prices to 2 decimal places
4. Update last_price_update timestamp
5. Only consider completed orders

---

## Hint

Use UPDATE with a FROM clause containing aggregated sales data. Use CASE to determine price adjustments. Verify with SELECT before updating.

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

### Step 1: Preview the Changes

```sql
-- ALWAYS preview before updating
WITH product_sales AS (
    SELECT
        p.id,
        p.name,
        p.price as current_price,
        COALESCE(SUM(oi.quantity), 0) as total_sold
    FROM products p
    LEFT JOIN order_items oi ON p.id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.id
    WHERE o.status = 'completed' OR o.status IS NULL
    GROUP BY p.id, p.name, p.price
)
SELECT
    name,
    current_price,
    total_sold,
    CASE
        WHEN total_sold > 50 THEN ROUND(current_price * 1.10, 2)
        WHEN total_sold < 10 THEN ROUND(current_price * 0.95, 2)
        ELSE current_price
    END as new_price,
    CASE
        WHEN total_sold > 50 THEN '+10%'
        WHEN total_sold < 10 THEN '-5%'
        ELSE 'No change'
    END as adjustment
FROM product_sales
ORDER BY total_sold DESC;
```

### Step 2: Perform the Update

```sql
-- Method 1: PostgreSQL UPDATE...FROM
UPDATE products p
SET
    price = ROUND(p.price * CASE
        WHEN COALESCE(sales.total_sold, 0) > 50 THEN 1.10
        WHEN COALESCE(sales.total_sold, 0) < 10 THEN 0.95
        ELSE 1.0
    END, 2),
    last_price_update = CURRENT_TIMESTAMP
FROM (
    SELECT
        p2.id,
        COALESCE(SUM(oi.quantity), 0) as total_sold
    FROM products p2
    LEFT JOIN order_items oi ON p2.id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.id AND o.status = 'completed'
    GROUP BY p2.id
) AS sales
WHERE p.id = sales.id;
```

### Step 3: Verify the Update

```sql
-- Check the results
SELECT
    p.id,
    p.name,
    p.price,
    p.last_price_update,
    COALESCE(SUM(oi.quantity), 0) as total_sold
FROM products p
LEFT JOIN order_items oi ON p.id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.id AND o.status = 'completed'
GROUP BY p.id, p.name, p.price, p.last_price_update
ORDER BY total_sold DESC;
```

### Complete Transaction-Safe Solution

```sql
-- Begin transaction for safety
BEGIN;

-- Create a backup or audit trail
CREATE TEMP TABLE price_changes_audit AS
SELECT
    p.id,
    p.name,
    p.price as old_price,
    COALESCE(SUM(oi.quantity), 0) as units_sold,
    CURRENT_TIMESTAMP as change_date
FROM products p
LEFT JOIN order_items oi ON p.id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.id AND o.status = 'completed'
GROUP BY p.id, p.name, p.price;

-- Perform the update
UPDATE products p
SET
    price = ROUND(p.price * CASE
        WHEN COALESCE(sales.total_sold, 0) > 50 THEN 1.10
        WHEN COALESCE(sales.total_sold, 0) < 10 THEN 0.95
        ELSE 1.0
    END, 2),
    last_price_update = CURRENT_TIMESTAMP
FROM (
    SELECT
        product_id,
        SUM(oi.quantity) as total_sold
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.id
    WHERE o.status = 'completed'
    GROUP BY product_id
) AS sales
WHERE p.id = sales.product_id;

-- Add new prices to audit table
UPDATE price_changes_audit pca
SET new_price = p.price
FROM products p
WHERE pca.id = p.id;

-- Review changes
SELECT
    name,
    old_price,
    new_price,
    new_price - old_price as price_change,
    ROUND((new_price - old_price) * 100.0 / old_price, 2) as pct_change,
    units_sold
FROM price_changes_audit
WHERE old_price != new_price
ORDER BY ABS(new_price - old_price) DESC;

-- If satisfied, commit; otherwise rollback
COMMIT;
-- ROLLBACK;
```

---

## Alternative Approaches

```sql
-- Method 1: Using CTE for clarity
WITH sales_stats AS (
    SELECT
        product_id,
        SUM(quantity) as total_quantity
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.id
    WHERE o.status = 'completed'
    GROUP BY product_id
)
UPDATE products p
SET
    price = ROUND(price * CASE
        WHEN COALESCE(ss.total_quantity, 0) > 50 THEN 1.10
        WHEN COALESCE(ss.total_quantity, 0) < 10 THEN 0.95
        ELSE 1.0
    END, 2),
    last_price_update = CURRENT_TIMESTAMP
FROM sales_stats ss
WHERE p.id = ss.product_id
   OR (p.id NOT IN (SELECT product_id FROM sales_stats));

-- Method 2: Separate updates for each condition (clearer logic)
-- Increase for high sellers
UPDATE products p
SET
    price = ROUND(price * 1.10, 2),
    last_price_update = CURRENT_TIMESTAMP
WHERE id IN (
    SELECT product_id
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.id
    WHERE o.status = 'completed'
    GROUP BY product_id
    HAVING SUM(quantity) > 50
);

-- Decrease for low sellers
UPDATE products p
SET
    price = ROUND(price * 0.95, 2),
    last_price_update = CURRENT_TIMESTAMP
WHERE id IN (
    SELECT product_id
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.id
    WHERE o.status = 'completed'
    GROUP BY product_id
    HAVING SUM(quantity) < 10
)
OR id NOT IN (
    SELECT DISTINCT product_id
    FROM order_items
);

-- Method 3: Update with percentage calculation stored
UPDATE products p
SET
    price = ROUND(p.price * (1 + adjustments.pct_change / 100.0), 2),
    last_price_update = CURRENT_TIMESTAMP
FROM (
    SELECT
        product_id,
        CASE
            WHEN SUM(quantity) > 50 THEN 10.0
            WHEN SUM(quantity) < 10 THEN -5.0
            ELSE 0.0
        END as pct_change
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.id
    WHERE o.status = 'completed'
    GROUP BY product_id
) adjustments
WHERE p.id = adjustments.product_id
  AND adjustments.pct_change != 0;
```

---

## Try These Variations

1. Update inventory based on pending orders
2. Set product status to 'out of stock' for zero inventory
3. Update customer tier based on total spending
4. Adjust employee salaries based on performance ratings
5. Update order totals from order items
6. Mark old orders as archived
7. Update running totals or cumulative fields

### Solutions to Variations

```sql
-- 1. Update inventory (reserve stock for pending orders)
UPDATE products p
SET
    stock_quantity = p.stock_quantity - COALESCE(pending.reserved_quantity, 0),
    last_updated = CURRENT_TIMESTAMP
FROM (
    SELECT
        oi.product_id,
        SUM(oi.quantity) as reserved_quantity
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.id
    WHERE o.status IN ('pending', 'processing')
    GROUP BY oi.product_id
) pending
WHERE p.id = pending.product_id
  AND p.stock_quantity >= pending.reserved_quantity;

-- 2. Set out of stock status
UPDATE products
SET
    status = 'out_of_stock',
    last_updated = CURRENT_TIMESTAMP
WHERE stock_quantity <= 0
  AND status != 'out_of_stock';

-- Also set back in stock when inventory added
UPDATE products
SET
    status = 'in_stock',
    last_updated = CURRENT_TIMESTAMP
WHERE stock_quantity > 0
  AND status = 'out_of_stock';

-- 3. Update customer tier
UPDATE customers c
SET
    tier = CASE
        WHEN spending.total >= 10000 THEN 'Platinum'
        WHEN spending.total >= 5000 THEN 'Gold'
        WHEN spending.total >= 1000 THEN 'Silver'
        ELSE 'Bronze'
    END,
    total_lifetime_value = spending.total,
    last_updated = CURRENT_TIMESTAMP
FROM (
    SELECT
        customer_id,
        SUM(amount) as total,
        COUNT(*) as order_count
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
) spending
WHERE c.id = spending.customer_id;

-- 4. Salary adjustment based on performance
UPDATE employees e
SET
    salary = ROUND(e.salary * (1 + adjustment.pct / 100.0), 2),
    last_review_date = CURRENT_DATE
FROM (
    SELECT
        employee_id,
        CASE
            WHEN AVG(rating) >= 4.5 THEN 10.0  -- 10% raise
            WHEN AVG(rating) >= 4.0 THEN 5.0   -- 5% raise
            WHEN AVG(rating) >= 3.0 THEN 2.0   -- 2% raise
            ELSE 0.0
        END as pct
    FROM performance_reviews
    WHERE review_date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY employee_id
) adjustment
WHERE e.id = adjustment.employee_id
  AND adjustment.pct > 0;

-- 5. Update order totals (recalculate from items)
UPDATE orders o
SET
    amount = item_totals.total,
    item_count = item_totals.count,
    last_updated = CURRENT_TIMESTAMP
FROM (
    SELECT
        order_id,
        SUM(quantity * price) as total,
        SUM(quantity) as count
    FROM order_items
    GROUP BY order_id
) item_totals
WHERE o.id = item_totals.order_id;

-- 6. Archive old orders
UPDATE orders
SET
    status = 'archived',
    archived_date = CURRENT_TIMESTAMP
WHERE status = 'completed'
  AND order_date < CURRENT_DATE - INTERVAL '2 years'
  AND status != 'archived';

-- 7. Update running totals (customer spending)
WITH customer_spending AS (
    SELECT
        customer_id,
        order_date,
        amount,
        SUM(amount) OVER (
            PARTITION BY customer_id
            ORDER BY order_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) as running_total
    FROM orders
    WHERE status = 'completed'
)
UPDATE orders o
SET cumulative_spending = cs.running_total
FROM customer_spending cs
WHERE o.customer_id = cs.customer_id
  AND o.order_date = cs.order_date
  AND o.amount = cs.amount;
```

---

## Sample Output

### Before Update
```
    name         | current_price | total_sold
-----------------+---------------+------------
 Premium Laptop  |      2499.99  |    120
 Office Desk     |       599.99  |     45
 USB Cable       |         9.99  |      3
 Monitor Stand   |        49.99  |     15
```

### After Update
```
    name         | old_price | new_price | price_change | pct_change | units_sold
-----------------+-----------+-----------+--------------+------------+------------
 Premium Laptop  |  2499.99  |  2749.99  |    +250.00   |   +10.00   |    120
 Office Desk     |   599.99  |   599.99  |      0.00    |     0.00   |     45
 USB Cable       |     9.99  |     9.49  |     -0.50    |    -5.00   |      3
 Monitor Stand   |    49.99  |    49.99  |      0.00    |     0.00   |     15
```

---

## Common Mistakes

1. **Forgetting WHERE clause (updates all rows!):**
   ```sql
   -- DANGEROUS! Updates all products
   UPDATE products
   SET price = price * 1.10;

   -- Better: Add WHERE condition
   UPDATE products
   SET price = price * 1.10
   WHERE id IN (SELECT ...);
   ```

2. **Not using transactions:**
   ```sql
   -- Always wrap in transaction
   BEGIN;
   UPDATE ...;
   -- Check results
   ROLLBACK; -- or COMMIT;
   ```

3. **Circular dependencies:**
   ```sql
   -- WRONG: Can't use same table in FROM and UPDATE target
   UPDATE products
   SET price = price * 1.10
   FROM products p2
   WHERE products.category = p2.category;
   ```

4. **Not handling NULLs:**
   ```sql
   -- WRONG: NULL propagates
   UPDATE products
   SET price = price * adjustment.factor;
   -- NULL * anything = NULL

   -- CORRECT: Use COALESCE
   SET price = price * COALESCE(adjustment.factor, 1.0);
   ```

5. **Joining without proper conditions:**
   ```sql
   -- WRONG: Cartesian product
   UPDATE products p
   SET price = sales.avg_price
   FROM sales;  -- No WHERE condition!

   -- CORRECT: Join condition
   UPDATE products p
   SET price = sales.avg_price
   FROM sales
   WHERE p.id = sales.product_id;
   ```

6. **Not verifying before committing:**
   - Always SELECT first
   - Check affected row count
   - Use transactions

---

## Safety Checklist

```sql
-- 1. Start transaction
BEGIN;

-- 2. Create backup or log
CREATE TEMP TABLE update_backup AS
SELECT * FROM target_table WHERE <conditions>;

-- 3. Preview changes with SELECT
SELECT ... -- Same logic as UPDATE

-- 4. Perform UPDATE
UPDATE target_table SET ...;

-- 5. Check affected rows
-- PostgreSQL returns: UPDATE N (where N is row count)

-- 6. Verify results
SELECT * FROM target_table WHERE ...;

-- 7. Compare before/after
SELECT
    b.id,
    b.old_value,
    t.new_value,
    t.new_value - b.old_value as diff
FROM update_backup b
JOIN target_table t ON b.id = t.id;

-- 8. If satisfied, COMMIT; otherwise ROLLBACK
COMMIT;
-- ROLLBACK;
```

---

## Performance Tips

```sql
-- 1. Create appropriate indexes
CREATE INDEX idx_order_items_product ON order_items(product_id);
CREATE INDEX idx_orders_status ON orders(status);

-- 2. Use EXPLAIN ANALYZE
EXPLAIN ANALYZE
UPDATE products p
SET price = ...
FROM (subquery) s
WHERE p.id = s.id;

-- 3. Break into smaller batches for large updates
UPDATE products
SET price = price * 1.10
WHERE id IN (
    SELECT id FROM products
    WHERE category = 'Electronics'
    LIMIT 1000
);

-- 4. Disable triggers temporarily if safe
ALTER TABLE products DISABLE TRIGGER ALL;
UPDATE products ...;
ALTER TABLE products ENABLE TRIGGER ALL;

-- 5. Use RETURNING clause to verify
UPDATE products
SET price = price * 1.10
WHERE category = 'Electronics'
RETURNING id, name, price;
```

---

## Advanced Patterns

```sql
-- Pattern 1: UPDATE with RETURNING (PostgreSQL)
WITH updated AS (
    UPDATE products
    SET price = price * 1.10
    WHERE category = 'Electronics'
    RETURNING id, name, price as new_price
)
INSERT INTO price_history (product_id, product_name, price, change_date)
SELECT id, name, new_price, CURRENT_TIMESTAMP
FROM updated;

-- Pattern 2: Conditional UPDATE (only if value changed)
UPDATE products p
SET
    price = new_prices.price,
    last_updated = CURRENT_TIMESTAMP
FROM new_prices
WHERE p.id = new_prices.product_id
  AND p.price IS DISTINCT FROM new_prices.price;

-- Pattern 3: UPDATE with rank/window functions
WITH ranked_products AS (
    SELECT
        id,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC) as price_rank
    FROM products
)
UPDATE products p
SET is_premium = (rp.price_rank <= 3)
FROM ranked_products rp
WHERE p.id = rp.id;

-- Pattern 4: Bulk UPDATE with temp table
CREATE TEMP TABLE price_updates (
    product_id INTEGER,
    new_price DECIMAL(10,2)
);

-- Load data (from file, API, etc.)
COPY price_updates FROM '/path/to/file.csv' CSV;

-- Apply updates
UPDATE products p
SET
    price = pu.new_price,
    last_updated = CURRENT_TIMESTAMP
FROM price_updates pu
WHERE p.id = pu.product_id;
```

---

## Real-World Use Cases

1. **Dynamic pricing:** Adjust prices based on demand/supply
2. **Inventory management:** Update stock levels from transactions
3. **Customer segmentation:** Update tiers based on behavior
4. **Data migration:** Transform data during system upgrades
5. **Performance management:** Apply salary adjustments
6. **Status updates:** Mark records based on time or conditions
7. **Data corrections:** Fix bulk data quality issues

---

## Related Problems

- **Previous:** [Problem 26 - Salary Quartiles](../26-salary-quartiles/)
- **Next:** [Problem 28 - Customer Retention Analysis](../28-customer-retention-analysis/)
- **Related:** Problem 12 (Simple UPDATE), Problem 4 (Aggregations), Problem 29 (Data Quality)

---

## Notes

```
Your notes here:




```

---

[← Previous](../26-salary-quartiles/) | [Back to Overview](../../README.md) | [Next Problem →](../28-customer-retention-analysis/)
