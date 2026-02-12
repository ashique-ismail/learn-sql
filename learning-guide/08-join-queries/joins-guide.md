# 08 - Join Queries

## Overview
JOINs combine rows from two or more tables based on related columns. Understanding JOINs is crucial for working with relational databases.

**JOIN Types:**
- `INNER JOIN` - Returns matching rows from both tables
- `LEFT JOIN` (LEFT OUTER JOIN) - All rows from left table, matching from right
- `RIGHT JOIN` (RIGHT OUTER JOIN) - All rows from right table, matching from left
- `FULL JOIN` (FULL OUTER JOIN) - All rows from both tables
- `CROSS JOIN` - Cartesian product of both tables
- `SELF JOIN` - Join table to itself

## Sample Tables
```sql
-- Customers table
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100),
    city VARCHAR(50)
);

-- Orders table
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    order_date DATE,
    total_amount DECIMAL(10,2)
);
```

## INNER JOIN

### Basic INNER JOIN
```sql
-- Returns only matching rows
SELECT
    c.customer_name,
    o.order_id,
    o.order_date,
    o.total_amount
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id;

-- INNER is optional (default)
SELECT c.customer_name, o.order_id
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id;
```

### Multiple INNER JOINs
```sql
-- Join three tables
SELECT
    c.customer_name,
    o.order_id,
    p.product_name,
    oi.quantity
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id;
```

### INNER JOIN with WHERE
```sql
-- Filter results
SELECT c.customer_name, o.total_amount
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.total_amount > 1000
  AND o.order_date >= '2024-01-01';
```

## LEFT JOIN (LEFT OUTER JOIN)

### Basic LEFT JOIN
```sql
-- All customers, with orders if they exist
SELECT
    c.customer_name,
    o.order_id,
    o.total_amount
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id;

-- Customers without orders show NULL for order columns
```

### Find Records with No Match
```sql
-- Customers who have never placed an order
SELECT c.customer_name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;
```

### LEFT JOIN with Aggregation
```sql
-- Count orders per customer (including customers with 0 orders)
SELECT
    c.customer_name,
    COUNT(o.order_id) AS order_count,
    COALESCE(SUM(o.total_amount), 0) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name;
```

## RIGHT JOIN (RIGHT OUTER JOIN)

### Basic RIGHT JOIN
```sql
-- All orders, with customer info if available
SELECT
    c.customer_name,
    o.order_id,
    o.total_amount
FROM customers c
RIGHT JOIN orders o ON c.customer_id = o.customer_id;

-- Less commonly used than LEFT JOIN
-- Can be rewritten as LEFT JOIN by swapping tables
```

## FULL JOIN (FULL OUTER JOIN)

### Basic FULL JOIN
```sql
-- All customers and all orders
SELECT
    c.customer_name,
    o.order_id,
    o.total_amount
FROM customers c
FULL OUTER JOIN orders o ON c.customer_id = o.customer_id;

-- Returns:
-- - Customers with orders
-- - Customers without orders (order columns NULL)
-- - Orders without customers (customer columns NULL)
```

### Find Unmatched Records
```sql
-- Find customers without orders OR orders without customers
SELECT
    c.customer_name,
    o.order_id
FROM customers c
FULL OUTER JOIN orders o ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL OR o.order_id IS NULL;
```

## CROSS JOIN

### Basic CROSS JOIN
```sql
-- Cartesian product: every combination
SELECT
    c.customer_name,
    p.product_name
FROM customers c
CROSS JOIN products p;

-- If customers has 10 rows and products has 100 rows
-- Result has 1000 rows (10 × 100)
```

### Practical CROSS JOIN Uses
```sql
-- Generate all date-product combinations
SELECT
    d.date,
    p.product_id,
    p.product_name
FROM
    (SELECT generate_series(
        '2024-01-01'::date,
        '2024-12-31'::date,
        '1 day'::interval
    )::date AS date) d
CROSS JOIN products p;

-- Create test data combinations
SELECT
    c.color,
    s.size
FROM
    (SELECT unnest(ARRAY['Red', 'Blue', 'Green']) AS color) c
CROSS JOIN
    (SELECT unnest(ARRAY['S', 'M', 'L', 'XL']) AS size) s;
```

## SELF JOIN

### Basic SELF JOIN
```sql
-- Employees and their managers (both in same table)
SELECT
    e.first_name AS employee_name,
    m.first_name AS manager_name
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id;
```

### Comparing Rows Within Same Table
```sql
-- Find employees in same department
SELECT
    e1.first_name AS employee1,
    e2.first_name AS employee2,
    e1.department_id
FROM employees e1
JOIN employees e2
    ON e1.department_id = e2.department_id
    AND e1.employee_id < e2.employee_id;  -- Avoid duplicates

-- Find employees with similar salaries
SELECT
    e1.first_name AS employee1,
    e2.first_name AS employee2,
    e1.salary
FROM employees e1
JOIN employees e2
    ON e1.employee_id != e2.employee_id
    AND ABS(e1.salary - e2.salary) < 5000;
```

## Advanced JOIN Techniques

### Multiple Join Conditions
```sql
-- Join on multiple columns
SELECT *
FROM table1 t1
JOIN table2 t2
    ON t1.id = t2.id
    AND t1.year = t2.year
    AND t1.category = t2.category;
```

### JOIN with OR Conditions
```sql
-- Join on multiple possible matches
SELECT *
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
    OR c.email = o.customer_email;
```

### JOIN with Subqueries
```sql
-- Join with derived table
SELECT
    c.customer_name,
    summary.order_count,
    summary.total_spent
FROM customers c
JOIN (
    SELECT
        customer_id,
        COUNT(*) AS order_count,
        SUM(total_amount) AS total_spent
    FROM orders
    GROUP BY customer_id
) summary ON c.customer_id = summary.customer_id;
```

### LATERAL JOIN (PostgreSQL)
```sql
-- For each customer, get their top 3 orders
SELECT
    c.customer_name,
    recent.order_date,
    recent.total_amount
FROM customers c
LEFT JOIN LATERAL (
    SELECT order_date, total_amount
    FROM orders o
    WHERE o.customer_id = c.customer_id
    ORDER BY order_date DESC
    LIMIT 3
) recent ON true;
```

### USING Clause
```sql
-- When join columns have same name
SELECT *
FROM customers
JOIN orders USING (customer_id);

-- Equivalent to:
SELECT *
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id;

-- Multiple columns
SELECT *
FROM table1
JOIN table2 USING (column1, column2);
```

### NATURAL JOIN
```sql
-- Automatically joins on all columns with same name
SELECT *
FROM customers
NATURAL JOIN orders;

-- Not recommended: implicit behavior can cause issues
-- If tables add columns with same name, join behavior changes
```

## JOIN Performance Optimization

### Use Indexes
```sql
-- Index foreign key columns
CREATE INDEX idx_orders_customer_id ON orders(customer_id);

-- Improves JOIN performance significantly
```

### Filter Early
```sql
-- Good: filter before JOIN
SELECT c.customer_name, o.order_id
FROM customers c
JOIN (
    SELECT * FROM orders WHERE order_date >= '2024-01-01'
) o ON c.customer_id = o.customer_id;

-- Also good: filter in WHERE clause
SELECT c.customer_name, o.order_id
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_date >= '2024-01-01';
```

### Join Order Matters
```sql
-- Start with smallest table
-- Query optimizer usually handles this, but be aware
SELECT *
FROM small_table s  -- 100 rows
JOIN large_table l ON s.id = l.small_id  -- 1M rows
WHERE s.active = true;  -- Reduces to 10 rows
```

## Common JOIN Patterns

### One-to-Many Relationships
```sql
-- One customer, many orders
SELECT
    c.customer_name,
    COUNT(o.order_id) AS order_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name;
```

### Many-to-Many Relationships
```sql
-- Students and Courses (via enrollments junction table)
SELECT
    s.student_name,
    c.course_name,
    e.grade
FROM students s
JOIN enrollments e ON s.student_id = e.student_id
JOIN courses c ON e.course_id = c.course_id;
```

### Hierarchical Data
```sql
-- Organization hierarchy
WITH RECURSIVE org_chart AS (
    -- Base case: top-level managers
    SELECT employee_id, first_name, manager_id, 1 AS level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive case: employees reporting to previous level
    SELECT e.employee_id, e.first_name, e.manager_id, oc.level + 1
    FROM employees e
    JOIN org_chart oc ON e.manager_id = oc.employee_id
)
SELECT * FROM org_chart;
```

## Common Pitfalls

### Cartesian Product (Unintended)
```sql
-- WRONG: Missing JOIN condition
SELECT *
FROM customers c, orders o;
-- Returns every customer × every order

-- CORRECT: Include JOIN condition
SELECT *
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id;
```

### Ambiguous Column Names
```sql
-- WRONG: Ambiguous reference
SELECT customer_id, order_date
FROM customers
JOIN orders USING (customer_id);
-- Error: customer_id exists in both tables

-- CORRECT: Use table alias
SELECT c.customer_id, o.order_date
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id;
```

### LEFT JOIN with WHERE on Right Table
```sql
-- WRONG: Converts LEFT JOIN to INNER JOIN
SELECT c.customer_name, o.order_id
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.total_amount > 1000;  -- Excludes customers with no orders

-- CORRECT: Filter in JOIN condition
SELECT c.customer_name, o.order_id
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
    AND o.total_amount > 1000;  -- Keeps all customers
```

## Practice Problems
Check the `problems` directory for hands-on JOIN exercises.

## Key Takeaways
- INNER JOIN returns only matching rows
- LEFT JOIN returns all left table rows, matching right rows
- Use LEFT JOIN with WHERE column IS NULL to find unmatched records
- CROSS JOIN creates all combinations (use carefully)
- SELF JOIN joins table to itself
- Index foreign key columns for better performance
- Use table aliases for readability
- Be careful with WHERE clause on LEFT JOIN right table
- Understand one-to-many and many-to-many relationships

## Next Steps
Move on to [09-subqueries](../09-subqueries/README.md) to learn about nested queries.
