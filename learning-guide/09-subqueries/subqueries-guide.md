# 09 - Subqueries

## Overview
A subquery is a query nested inside another query. Subqueries can appear in SELECT, FROM, WHERE, and HAVING clauses, providing powerful ways to filter and transform data.

**Subquery Types:**
- Scalar subqueries (return single value)
- Row subqueries (return single row)
- Table subqueries (return multiple rows/columns)
- Correlated subqueries (reference outer query)

## Subqueries in WHERE Clause

### Scalar Subquery
```sql
-- Find employees earning more than average
SELECT first_name, last_name, salary
FROM employees
WHERE salary > (
    SELECT AVG(salary) FROM employees
);

-- Single value comparison
SELECT product_name, price
FROM products
WHERE price = (
    SELECT MAX(price) FROM products
);
```

### IN Subquery
```sql
-- Find customers who have placed orders
SELECT customer_name
FROM customers
WHERE customer_id IN (
    SELECT DISTINCT customer_id FROM orders
);

-- Find products in specific categories
SELECT product_name
FROM products
WHERE category_id IN (
    SELECT category_id
    FROM categories
    WHERE category_name IN ('Electronics', 'Books')
);
```

### NOT IN Subquery
```sql
-- Find customers who have never ordered
SELECT customer_name
FROM customers
WHERE customer_id NOT IN (
    SELECT customer_id FROM orders WHERE customer_id IS NOT NULL
);

-- Important: Handle NULLs carefully with NOT IN
-- If subquery returns NULL, NOT IN returns no rows
```

### ANY / SOME Subquery
```sql
-- Salary greater than ANY salary in department 10
SELECT first_name, salary
FROM employees
WHERE salary > ANY (
    SELECT salary FROM employees WHERE department_id = 10
);
-- Same as: salary > MIN(salary from dept 10)

-- Using SOME (identical to ANY)
WHERE salary > SOME (SELECT salary FROM employees WHERE department_id = 10);
```

### ALL Subquery
```sql
-- Salary greater than ALL salaries in department 10
SELECT first_name, salary
FROM employees
WHERE salary > ALL (
    SELECT salary FROM employees WHERE department_id = 10
);
-- Same as: salary > MAX(salary from dept 10)

-- Find most expensive product in each category
SELECT product_name, price
FROM products p1
WHERE price >= ALL (
    SELECT price
    FROM products p2
    WHERE p2.category_id = p1.category_id
);
```

### EXISTS Subquery
```sql
-- Check if subquery returns any rows
SELECT customer_name
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
);
-- Returns customers who have at least one order

-- Typically faster than IN for large datasets
```

### NOT EXISTS Subquery
```sql
-- Find customers with no orders
SELECT customer_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
);

-- More reliable than NOT IN when NULLs are present
```

## Subqueries in SELECT Clause

### Scalar Subquery in SELECT
```sql
-- Add calculated column from subquery
SELECT
    product_name,
    price,
    (SELECT AVG(price) FROM products) AS avg_price,
    price - (SELECT AVG(price) FROM products) AS difference_from_avg
FROM products;

-- Count related records
SELECT
    d.department_name,
    (SELECT COUNT(*)
     FROM employees e
     WHERE e.department_id = d.department_id) AS employee_count
FROM departments d;
```

## Subqueries in FROM Clause (Derived Tables)

### Basic Derived Table
```sql
-- Subquery acts as a temporary table
SELECT customer_id, order_count
FROM (
    SELECT customer_id, COUNT(*) AS order_count
    FROM orders
    GROUP BY customer_id
) AS customer_orders
WHERE order_count > 5;
```

### Complex Derived Tables
```sql
-- Multi-level aggregation
SELECT
    order_month,
    AVG(monthly_sales) AS avg_monthly_sales
FROM (
    SELECT
        DATE_TRUNC('month', order_date) AS order_month,
        SUM(total_amount) AS monthly_sales
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date)
) AS monthly_summary
GROUP BY order_month;
```

### JOIN with Derived Table
```sql
-- Join with subquery results
SELECT
    c.customer_name,
    summary.total_spent,
    summary.order_count
FROM customers c
JOIN (
    SELECT
        customer_id,
        SUM(total_amount) AS total_spent,
        COUNT(*) AS order_count
    FROM orders
    GROUP BY customer_id
) summary ON c.customer_id = summary.customer_id
WHERE summary.total_spent > 1000;
```

## Correlated Subqueries

### What is a Correlated Subquery?
A correlated subquery references columns from the outer query. It's executed once for each row in the outer query.

### Basic Correlated Subquery
```sql
-- Find employees earning more than their department average
SELECT
    e1.first_name,
    e1.last_name,
    e1.salary,
    e1.department_id
FROM employees e1
WHERE salary > (
    SELECT AVG(e2.salary)
    FROM employees e2
    WHERE e2.department_id = e1.department_id  -- Correlation
);
```

### Correlated EXISTS
```sql
-- Customers with orders this year
SELECT c.customer_name
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
      AND EXTRACT(YEAR FROM o.order_date) = EXTRACT(YEAR FROM CURRENT_DATE)
);
```

### Correlated in SELECT
```sql
-- Show each employee with their department's average salary
SELECT
    first_name,
    salary,
    (SELECT AVG(salary)
     FROM employees e2
     WHERE e2.department_id = e1.department_id) AS dept_avg_salary
FROM employees e1;
```

## Subqueries vs JOINs

### When to Use Subqueries
```sql
-- Check existence (EXISTS often faster than JOIN)
SELECT c.customer_name
FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
);

-- Scalar values
SELECT product_name, price
FROM products
WHERE price > (SELECT AVG(price) FROM products);
```

### When to Use JOINs
```sql
-- Need columns from multiple tables
SELECT c.customer_name, o.order_date, o.total_amount
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id;
-- Subquery cannot easily return multiple columns from orders
```

### Converting Subquery to JOIN
```sql
-- Subquery version
SELECT customer_name
FROM customers
WHERE customer_id IN (
    SELECT customer_id FROM orders
);

-- JOIN version (typically faster)
SELECT DISTINCT c.customer_name
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id;
```

## Common Table Expressions (CTEs)

### WITH Clause (Better than Subqueries)
```sql
-- Define named subquery
WITH high_value_customers AS (
    SELECT
        customer_id,
        SUM(total_amount) AS total_spent
    FROM orders
    GROUP BY customer_id
    HAVING SUM(total_amount) > 10000
)
SELECT
    c.customer_name,
    hvc.total_spent
FROM customers c
JOIN high_value_customers hvc ON c.customer_id = hvc.customer_id;
```

### Multiple CTEs
```sql
-- Define multiple named subqueries
WITH
order_summary AS (
    SELECT customer_id, COUNT(*) AS order_count, SUM(total_amount) AS total_spent
    FROM orders
    GROUP BY customer_id
),
customer_categories AS (
    SELECT
        customer_id,
        CASE
            WHEN total_spent > 10000 THEN 'VIP'
            WHEN total_spent > 5000 THEN 'Premium'
            ELSE 'Standard'
        END AS category
    FROM order_summary
)
SELECT
    c.customer_name,
    os.order_count,
    os.total_spent,
    cc.category
FROM customers c
JOIN order_summary os ON c.customer_id = os.customer_id
JOIN customer_categories cc ON c.customer_id = cc.customer_id;
```

### Recursive CTEs
```sql
-- Build hierarchical data
WITH RECURSIVE employee_hierarchy AS (
    -- Base case: top-level employees
    SELECT employee_id, first_name, manager_id, 1 AS level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive case
    SELECT e.employee_id, e.first_name, e.manager_id, eh.level + 1
    FROM employees e
    JOIN employee_hierarchy eh ON e.manager_id = eh.employee_id
)
SELECT * FROM employee_hierarchy ORDER BY level, first_name;
```

## Advanced Subquery Patterns

### Lateral Subqueries (PostgreSQL)
```sql
-- Subquery can reference outer query
SELECT
    c.customer_name,
    recent.order_date,
    recent.total_amount
FROM customers c
CROSS JOIN LATERAL (
    SELECT order_date, total_amount
    FROM orders o
    WHERE o.customer_id = c.customer_id
    ORDER BY order_date DESC
    LIMIT 3
) recent;
```

### Subquery in UPDATE
```sql
-- Update based on subquery
UPDATE products
SET price = price * 1.1
WHERE product_id IN (
    SELECT product_id
    FROM order_items
    GROUP BY product_id
    HAVING SUM(quantity) > 100
);

-- Update with correlated subquery
UPDATE employees e1
SET salary = salary * 1.1
WHERE salary < (
    SELECT AVG(salary)
    FROM employees e2
    WHERE e2.department_id = e1.department_id
);
```

### Subquery in DELETE
```sql
-- Delete based on subquery
DELETE FROM customers
WHERE customer_id NOT IN (
    SELECT DISTINCT customer_id
    FROM orders
    WHERE customer_id IS NOT NULL
);

-- Delete with correlated subquery
DELETE FROM products p1
WHERE price < (
    SELECT AVG(price)
    FROM products p2
    WHERE p2.category_id = p1.category_id
) * 0.5;  -- Half the average price
```

## Performance Considerations

### Subquery Performance
```sql
-- Slow: Subquery runs for each outer row
SELECT e1.first_name
FROM employees e1
WHERE salary > (
    SELECT AVG(salary)
    FROM employees e2
    WHERE e2.department_id = e1.department_id
);

-- Faster: Use JOIN with pre-aggregated data
SELECT e.first_name
FROM employees e
JOIN (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
) dept_avg ON e.department_id = dept_avg.department_id
WHERE e.salary > dept_avg.avg_salary;
```

### EXISTS vs IN
```sql
-- EXISTS: Stops at first match (faster)
SELECT c.customer_name
FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
);

-- IN: Builds full list (slower for large datasets)
SELECT c.customer_name
FROM customers c
WHERE c.customer_id IN (
    SELECT customer_id FROM orders
);
```

### NOT EXISTS vs NOT IN
```sql
-- NOT EXISTS: Handles NULLs correctly, often faster
SELECT c.customer_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
);

-- NOT IN: Fails with NULLs, be careful
SELECT c.customer_name
FROM customers c
WHERE c.customer_id NOT IN (
    SELECT customer_id FROM orders WHERE customer_id IS NOT NULL
);
```

## Common Pitfalls

### NULL in NOT IN
```sql
-- DANGER: Returns no rows if subquery has NULL
SELECT * FROM customers
WHERE customer_id NOT IN (SELECT manager_id FROM employees);
-- If any manager_id is NULL, returns empty result

-- FIX: Filter NULLs or use NOT EXISTS
WHERE customer_id NOT IN (SELECT manager_id FROM employees WHERE manager_id IS NOT NULL);
```

### Correlated Subquery Performance
```sql
-- Slow: Runs subquery for each row
SELECT *
FROM employees e1
WHERE salary > (SELECT AVG(salary) FROM employees e2 WHERE e2.department_id = e1.department_id);

-- Faster: Use window functions (covered in advanced topics)
SELECT *
FROM (
    SELECT *, AVG(salary) OVER (PARTITION BY department_id) AS dept_avg
    FROM employees
) sub
WHERE salary > dept_avg;
```

## Practice Problems
Check the `problems` directory for hands-on subquery exercises.

## Key Takeaways
- Subqueries can appear in SELECT, FROM, WHERE, HAVING clauses
- Scalar subqueries return single value
- IN/NOT IN checks if value exists in list
- EXISTS/NOT EXISTS checks if subquery returns rows
- Correlated subqueries reference outer query
- CTEs (WITH clause) improve readability over nested subqueries
- EXISTS typically faster than IN
- NOT EXISTS safer than NOT IN (handles NULLs)
- Consider JOINs or window functions for performance

## Next Steps
Move on to [10-advanced-functions](../10-advanced-functions/README.md) to learn about window functions and advanced SQL features.
