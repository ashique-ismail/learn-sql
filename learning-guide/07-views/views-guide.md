# 07 - Views

## Overview
A view is a virtual table based on a SQL query. Views don't store data themselves but provide a way to simplify complex queries, enhance security, and present data in different formats.

**Benefits of Views:**
- Simplify complex queries
- Enhance security by restricting data access
- Provide data abstraction
- Maintain backward compatibility
- Create logical data models

## Creating Views

### Basic CREATE VIEW
```sql
-- Simple view
CREATE VIEW active_employees AS
SELECT employee_id, first_name, last_name, email
FROM employees
WHERE status = 'active';

-- Query the view like a table
SELECT * FROM active_employees;
```

### CREATE OR REPLACE VIEW
```sql
-- Replace view if it exists
CREATE OR REPLACE VIEW active_employees AS
SELECT employee_id, first_name, last_name, email, department_id
FROM employees
WHERE status = 'active';
```

### Views with JOINs
```sql
-- View combining multiple tables
CREATE VIEW employee_details AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    d.department_name,
    e.salary,
    e.hire_date
FROM employees e
JOIN departments d ON e.department_id = d.department_id;

-- Use the view
SELECT * FROM employee_details WHERE department_name = 'Sales';
```

### Views with Aggregations
```sql
-- Summary view
CREATE VIEW department_stats AS
SELECT
    d.department_name,
    COUNT(e.employee_id) AS employee_count,
    AVG(e.salary) AS avg_salary,
    MAX(e.salary) AS max_salary,
    MIN(e.salary) AS min_salary
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name;

-- Query aggregated data
SELECT * FROM department_stats WHERE employee_count > 10;
```

### Views with Calculations
```sql
-- View with computed columns
CREATE VIEW employee_compensation AS
SELECT
    employee_id,
    first_name,
    last_name,
    salary,
    salary * 12 AS annual_salary,
    salary * 0.15 AS annual_bonus,
    salary * 12 + salary * 0.15 AS total_compensation
FROM employees;
```

## Using Views

### Querying Views
```sql
-- Views can be queried like tables
SELECT * FROM active_employees;

-- With WHERE clause
SELECT * FROM employee_details
WHERE salary > 50000;

-- With ORDER BY
SELECT * FROM department_stats
ORDER BY employee_count DESC;

-- With JOIN
SELECT
    ed.first_name,
    ed.last_name,
    o.order_date,
    o.total_amount
FROM employee_details ed
JOIN orders o ON ed.employee_id = o.salesperson_id;
```

### Views in Subqueries
```sql
-- Use view in subquery
SELECT *
FROM employees
WHERE salary > (
    SELECT AVG(avg_salary)
    FROM department_stats
);
```

## Modifying Views

### ALTER VIEW
```sql
-- PostgreSQL: Rename view
ALTER VIEW active_employees RENAME TO current_employees;

-- Change view owner
ALTER VIEW current_employees OWNER TO new_owner;
```

### Updating Data Through Views
```sql
-- Simple views (single table, no aggregation) can be updatable
CREATE VIEW sales_employees AS
SELECT employee_id, first_name, last_name, salary
FROM employees
WHERE department_id = (SELECT department_id FROM departments WHERE department_name = 'Sales');

-- INSERT through view
INSERT INTO sales_employees (first_name, last_name, salary)
VALUES ('John', 'Doe', 60000);

-- UPDATE through view
UPDATE sales_employees
SET salary = 65000
WHERE employee_id = 1;

-- DELETE through view
DELETE FROM sales_employees
WHERE employee_id = 1;
```

### WITH CHECK OPTION
```sql
-- Ensure data modified through view meets view condition
CREATE VIEW high_earners AS
SELECT employee_id, first_name, last_name, salary
FROM employees
WHERE salary > 100000
WITH CHECK OPTION;

-- This will fail: salary doesn't meet view condition
UPDATE high_earners
SET salary = 50000
WHERE employee_id = 1;
-- Error: violates check option

-- This works: salary still meets condition
UPDATE high_earners
SET salary = 120000
WHERE employee_id = 1;
```

### LOCAL vs CASCADED CHECK OPTION
```sql
-- CASCADED (default): checks all underlying views
CREATE VIEW v1 AS
SELECT * FROM employees WHERE salary > 50000
WITH CASCADED CHECK OPTION;

-- LOCAL: only checks current view
CREATE VIEW v2 AS
SELECT * FROM employees WHERE salary > 50000
WITH LOCAL CHECK OPTION;
```

## Materialized Views (PostgreSQL)

### What are Materialized Views?
Materialized views store query results physically, unlike regular views which execute the query each time.

### Creating Materialized Views
```sql
-- Create materialized view
CREATE MATERIALIZED VIEW sales_summary AS
SELECT
    DATE_TRUNC('month', order_date) AS month,
    SUM(total_amount) AS total_sales,
    COUNT(*) AS order_count,
    AVG(total_amount) AS avg_order_value
FROM orders
GROUP BY DATE_TRUNC('month', order_date);

-- Query like a regular table (fast, uses stored data)
SELECT * FROM sales_summary;
```

### Refreshing Materialized Views
```sql
-- Refresh data (locks the view)
REFRESH MATERIALIZED VIEW sales_summary;

-- Concurrent refresh (doesn't lock, requires unique index)
CREATE UNIQUE INDEX ON sales_summary (month);
REFRESH MATERIALIZED VIEW CONCURRENTLY sales_summary;
```

### When to Use Materialized Views
- Complex queries that are slow to execute
- Data that doesn't change frequently
- Reporting and analytics
- Dashboard summaries
- Pre-computed aggregations

## Dropping Views

### DROP VIEW
```sql
-- Drop single view
DROP VIEW active_employees;

-- Drop if exists
DROP VIEW IF EXISTS active_employees;

-- Drop multiple views
DROP VIEW active_employees, employee_details;

-- Drop with CASCADE (drops dependent views)
DROP VIEW employee_details CASCADE;

-- Drop with RESTRICT (fails if dependencies exist)
DROP VIEW employee_details RESTRICT;
```

### DROP MATERIALIZED VIEW
```sql
-- Drop materialized view
DROP MATERIALIZED VIEW sales_summary;

-- Drop if exists
DROP MATERIALIZED VIEW IF EXISTS sales_summary;
```

## View Security and Permissions

### Restricting Column Access
```sql
-- Create view without sensitive columns
CREATE VIEW employee_public AS
SELECT employee_id, first_name, last_name, department_id
FROM employees;
-- Excludes salary, ssn, etc.

-- Grant access to view only
GRANT SELECT ON employee_public TO public_users;
-- Users can't access underlying employees table
```

### Row-Level Security with Views
```sql
-- Managers can only see their department
CREATE VIEW manager_employees AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.department_id
FROM employees e
WHERE e.department_id = (
    SELECT department_id
    FROM employees
    WHERE employee_id = current_user_id()  -- hypothetical function
    AND is_manager = TRUE
);
```

## View Best Practices

### Naming Conventions
```sql
-- Prefix with 'v_' or 'vw_'
CREATE VIEW v_active_employees AS ...;
CREATE VIEW vw_sales_summary AS ...;

-- Or use descriptive names
CREATE VIEW employee_sales_history AS ...;
CREATE VIEW monthly_revenue_report AS ...;
```

### Documentation
```sql
-- Comment views for clarity
COMMENT ON VIEW employee_details IS
'Combines employee and department data for reporting. Updated real-time from base tables.';

-- PostgreSQL: View comments
SELECT
    schemaname,
    viewname,
    definition
FROM pg_views
WHERE schemaname = 'public';
```

### Performance Considerations
```sql
-- Bad: View with view with view (nested)
CREATE VIEW v1 AS SELECT * FROM large_table WHERE condition1;
CREATE VIEW v2 AS SELECT * FROM v1 WHERE condition2;
CREATE VIEW v3 AS SELECT * FROM v2 WHERE condition3;
-- Each query must resolve all views

-- Better: Single view with all conditions
CREATE VIEW v_optimized AS
SELECT * FROM large_table
WHERE condition1 AND condition2 AND condition3;
```

## Common View Patterns

### Active Records Pattern
```sql
-- View for active/non-deleted records
CREATE VIEW active_products AS
SELECT *
FROM products
WHERE deleted_at IS NULL;
```

### Simplified Complex JOINs
```sql
-- Simplify complex query for users
CREATE VIEW order_details AS
SELECT
    o.order_id,
    c.customer_name,
    c.email,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    oi.quantity * oi.unit_price AS line_total,
    o.order_date
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id;
```

### Calculated Fields
```sql
-- Pre-calculate complex formulas
CREATE VIEW product_margins AS
SELECT
    product_id,
    product_name,
    cost,
    price,
    price - cost AS profit,
    ROUND(((price - cost) / NULLIF(price, 0)) * 100, 2) AS margin_percent
FROM products;
```

### Union Views
```sql
-- Combine data from multiple sources
CREATE VIEW all_transactions AS
SELECT
    'sale' AS transaction_type,
    sale_id AS transaction_id,
    sale_date AS transaction_date,
    amount
FROM sales
UNION ALL
SELECT
    'refund' AS transaction_type,
    refund_id AS transaction_id,
    refund_date AS transaction_date,
    -amount
FROM refunds;
```

### Time-Based Views
```sql
-- Current month data
CREATE VIEW current_month_orders AS
SELECT *
FROM orders
WHERE order_date >= DATE_TRUNC('month', CURRENT_DATE)
  AND order_date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month';

-- Last 30 days
CREATE VIEW recent_orders AS
SELECT *
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '30 days';
```

## Viewing View Definitions

### PostgreSQL
```sql
-- View definition
\d+ view_name

-- Or query system catalog
SELECT definition
FROM pg_views
WHERE viewname = 'active_employees';

-- List all views
SELECT schemaname, viewname
FROM pg_views
WHERE schemaname = 'public';
```

### Information Schema
```sql
-- View all views
SELECT table_name, view_definition
FROM information_schema.views
WHERE table_schema = 'public';
```

## Limitations of Views

1. **Performance**: Complex views can be slow (consider materialized views)
2. **Update Limitations**: Not all views are updatable
3. **No Indexes**: Regular views can't have indexes (materialized views can)
4. **Dependencies**: Changing base tables can break views
5. **Nested Complexity**: Multiple nested views can be hard to maintain

## Practice Problems
Check the `problems` directory for hands-on view exercises.

## Key Takeaways
- Views are virtual tables based on queries
- Views simplify complex queries and enhance security
- Regular views execute the query each time
- Materialized views store results physically
- Simple views can be updatable
- Use WITH CHECK OPTION to enforce view conditions
- Views don't store data (except materialized views)
- Consider performance implications with complex views
- Use views to restrict data access

## Next Steps
Move on to [08-join-queries](../08-join-queries/README.md) to master combining data from multiple tables.
