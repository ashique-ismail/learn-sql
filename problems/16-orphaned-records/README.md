# Problem 16: Orphaned Records

**Difficulty:** Intermediate
**Concepts:** EXISTS, NOT EXISTS, Subqueries, LEFT JOIN with NULL, Data integrity
**Phase:** Advanced Features (Days 14-16)

---

## Learning Objectives

- Master EXISTS and NOT EXISTS operators
- Find orphaned records (missing relationships)
- Understand difference between IN and EXISTS
- Use LEFT JOIN to find unmatched rows
- Check referential integrity without foreign keys
- Optimize existence checks for performance

---

## Concept Summary

**EXISTS** checks whether a subquery returns any rows. **NOT EXISTS** checks for absence of rows. More efficient than IN for large datasets.

### Syntax

```sql
-- EXISTS: Returns TRUE if subquery has any rows
SELECT columns FROM table1
WHERE EXISTS (
    SELECT 1 FROM table2
    WHERE table2.key = table1.key
    AND condition
);

-- NOT EXISTS: Returns TRUE if subquery has no rows
SELECT columns FROM table1
WHERE NOT EXISTS (
    SELECT 1 FROM table2
    WHERE table2.key = table1.key
);

-- Alternative: LEFT JOIN with NULL check
SELECT table1.columns
FROM table1
LEFT JOIN table2 ON table1.key = table2.key
WHERE table2.key IS NULL;

-- Alternative: NOT IN (less efficient for NULLs)
SELECT columns FROM table1
WHERE column NOT IN (SELECT column FROM table2);
```

### EXISTS vs IN

| EXISTS | IN |
|--------|-----|
| Stops at first match | Evaluates all matches |
| Works with correlated subqueries | Works with independent subqueries |
| Better for large subqueries | Better for small subqueries |
| Handles NULLs better | NULL causes unexpected results |
| Returns TRUE/FALSE | Returns list to check against |

---

## Problem Statement

**Given:**
- employees(id, name, department, salary)
- project_assignments(employee_id, project_id, hours_allocated)

**Task:** Find employees who don't have any projects assigned. Show employee id and name.

---

## Hint

Use NOT EXISTS to find employees without matching rows in project_assignments, or use LEFT JOIN and check for NULL.

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

```sql
-- Method 1: Using NOT EXISTS (most efficient)
SELECT e.id, e.name
FROM employees e
WHERE NOT EXISTS (
    SELECT 1
    FROM project_assignments pa
    WHERE pa.employee_id = e.id
);

-- Method 2: Using LEFT JOIN with NULL check
SELECT e.id, e.name
FROM employees e
LEFT JOIN project_assignments pa ON e.id = pa.employee_id
WHERE pa.employee_id IS NULL;

-- Method 3: Using NOT IN (less recommended)
SELECT id, name
FROM employees
WHERE id NOT IN (
    SELECT employee_id
    FROM project_assignments
    WHERE employee_id IS NOT NULL  -- Critical for NOT IN!
);
```

### Explanation

**Method 1 (NOT EXISTS):**
1. For each employee, check if any project_assignment exists
2. `SELECT 1` is convention (column doesn't matter, only existence)
3. Correlated subquery - references outer query's `e.id`
4. Database stops searching after first match (efficient)

**Method 2 (LEFT JOIN):**
1. Join employees with project_assignments
2. Keeps all employees (LEFT JOIN)
3. Unassigned employees have NULL in pa columns
4. Filter for NULL to get orphaned records

**Method 3 (NOT IN):**
1. Get all employee_ids from project_assignments
2. Find employees whose id is not in that list
3. **Critical:** Must handle NULLs in subquery

---

## Extended Examples

```sql
-- Find products never ordered
SELECT p.product_id, p.name, p.price
FROM products p
WHERE NOT EXISTS (
    SELECT 1
    FROM order_items oi
    WHERE oi.product_id = p.product_id
);

-- Find customers with no orders in last 6 months
SELECT c.id, c.name, c.email
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.id
      AND o.order_date >= CURRENT_DATE - INTERVAL '6 months'
);

-- Find departments with no employees
SELECT d.id, d.dept_name
FROM departments d
WHERE NOT EXISTS (
    SELECT 1
    FROM employees e
    WHERE e.dept_id = d.id
);

-- Find employees assigned to ALL projects (EXISTS with NOT EXISTS)
SELECT e.name
FROM employees e
WHERE NOT EXISTS (
    SELECT 1
    FROM projects p
    WHERE NOT EXISTS (
        SELECT 1
        FROM project_assignments pa
        WHERE pa.employee_id = e.id
          AND pa.project_id = p.project_id
    )
);

-- Multiple orphan checks
SELECT
    e.id,
    e.name,
    CASE
        WHEN NOT EXISTS (SELECT 1 FROM project_assignments WHERE employee_id = e.id)
             THEN 'No Projects'
        WHEN NOT EXISTS (SELECT 1 FROM timesheet WHERE employee_id = e.id)
             THEN 'No Timesheets'
        WHEN NOT EXISTS (SELECT 1 FROM performance_reviews WHERE employee_id = e.id)
             THEN 'No Reviews'
        ELSE 'Complete'
    END as status
FROM employees e;
```

---

## Comprehensive Orphan Detection

```sql
-- Find all types of orphaned records
WITH orphaned_employees AS (
    SELECT e.id, e.name, 'No Projects' as issue
    FROM employees e
    WHERE NOT EXISTS (
        SELECT 1 FROM project_assignments pa WHERE pa.employee_id = e.id
    )
),
orphaned_projects AS (
    SELECT p.id, p.name, 'No Employees' as issue
    FROM projects p
    WHERE NOT EXISTS (
        SELECT 1 FROM project_assignments pa WHERE pa.project_id = p.id
    )
),
orphaned_orders AS (
    SELECT o.id::TEXT, 'Order ' || o.id, 'No Items' as issue
    FROM orders o
    WHERE NOT EXISTS (
        SELECT 1 FROM order_items oi WHERE oi.order_id = o.id
    )
)
SELECT * FROM orphaned_employees
UNION ALL
SELECT * FROM orphaned_projects
UNION ALL
SELECT * FROM orphaned_orders
ORDER BY issue, name;

-- Referential integrity check
SELECT
    'employees -> departments' as relationship,
    COUNT(*) as orphaned_count
FROM employees e
WHERE dept_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM departments d WHERE d.id = e.dept_id)

UNION ALL

SELECT
    'orders -> customers',
    COUNT(*)
FROM orders o
WHERE NOT EXISTS (SELECT 1 FROM customers c WHERE c.id = o.customer_id)

UNION ALL

SELECT
    'order_items -> products',
    COUNT(*)
FROM order_items oi
WHERE NOT EXISTS (SELECT 1 FROM products p WHERE p.id = oi.product_id);
```

---

## EXISTS vs IN Performance

```sql
-- EXISTS: Stops at first match (efficient)
-- Good for: Large subquery results
SELECT e.name
FROM employees e
WHERE EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.employee_id = e.id
      AND o.order_date >= '2024-01-01'
);

-- IN: Builds complete list then checks
-- Good for: Small, static lists
SELECT name
FROM employees
WHERE department IN ('Engineering', 'Sales', 'Marketing');

-- IN with subquery: Less efficient than EXISTS
SELECT name
FROM employees
WHERE id IN (
    SELECT employee_id
    FROM orders
    WHERE order_date >= '2024-01-01'
);
```

---

## Try These Variations

1. Find customers who placed orders but never left a review
2. Find books that have authors but no borrowings
3. Find projects with no hours logged in last month
4. Find employees in departments that have no manager assigned
5. Find orphaned records in both directions (employees without projects AND projects without employees)

### Solutions to Variations

```sql
-- 1. Orders without reviews
SELECT DISTINCT c.id, c.name, c.email
FROM customers c
JOIN orders o ON c.id = o.customer_id
WHERE NOT EXISTS (
    SELECT 1
    FROM reviews r
    WHERE r.customer_id = c.id
);

-- 2. Books with no borrowings
SELECT b.book_id, b.title, STRING_AGG(a.name, ', ') as authors
FROM books b
JOIN book_authors ba ON b.book_id = ba.book_id
JOIN authors a ON ba.author_id = a.author_id
WHERE NOT EXISTS (
    SELECT 1
    FROM borrowings br
    WHERE br.book_id = b.book_id
)
GROUP BY b.book_id, b.title;

-- 3. Projects with no recent hours
SELECT p.project_id, p.name, p.start_date
FROM projects p
WHERE NOT EXISTS (
    SELECT 1
    FROM timesheet t
    WHERE t.project_id = p.project_id
      AND t.work_date >= CURRENT_DATE - INTERVAL '1 month'
)
AND p.status = 'active';

-- 4. Employees in departments without manager
SELECT e.id, e.name, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.id
WHERE d.manager_id IS NULL
   OR NOT EXISTS (
       SELECT 1
       FROM employees m
       WHERE m.id = d.manager_id
   );

-- 5. Bidirectional orphan check
SELECT
    'Employees without Projects' as orphan_type,
    COUNT(*) as count
FROM employees e
WHERE NOT EXISTS (SELECT 1 FROM project_assignments pa WHERE pa.employee_id = e.id)

UNION ALL

SELECT
    'Projects without Employees',
    COUNT(*)
FROM projects p
WHERE NOT EXISTS (SELECT 1 FROM project_assignments pa WHERE pa.project_id = p.project_id);
```

---

## Sample Output

```
 id |      name
----+-----------------
  5 | John Smith
  8 | Sarah Williams
 12 | Mike Johnson
 15 | Emily Brown
(4 rows)
```

With additional context:
```
 id |      name       | department  | hire_date
----+-----------------+-------------+------------
  5 | John Smith      | Engineering | 2024-01-15
  8 | Sarah Williams  | Marketing   | 2023-11-20
 12 | Mike Johnson    | Sales       | 2024-02-01
 15 | Emily Brown     | HR          | 2023-12-10
(4 rows)
```

---

## Common Mistakes

1. **NULL handling with NOT IN:**
   ```sql
   -- WRONG: If subquery returns NULL, entire query returns no rows!
   SELECT * FROM employees
   WHERE id NOT IN (SELECT employee_id FROM project_assignments);

   -- CORRECT: Filter NULLs
   WHERE id NOT IN (SELECT employee_id FROM project_assignments WHERE employee_id IS NOT NULL);
   ```

2. **Forgetting correlation in EXISTS:**
   ```sql
   -- WRONG: Not correlated, checks if ANY assignment exists
   WHERE NOT EXISTS (SELECT 1 FROM project_assignments);

   -- CORRECT: Correlated to check for THIS employee
   WHERE NOT EXISTS (SELECT 1 FROM project_assignments WHERE employee_id = e.id);
   ```

3. **Using SELECT * in EXISTS:**
   ```sql
   -- Wasteful: Returns all columns (not needed)
   WHERE EXISTS (SELECT * FROM project_assignments WHERE employee_id = e.id);

   -- Better: Just check existence
   WHERE EXISTS (SELECT 1 FROM project_assignments WHERE employee_id = e.id);
   ```

4. **Wrong NULL check with LEFT JOIN:**
   ```sql
   -- WRONG: Checks wrong column
   LEFT JOIN project_assignments pa ON e.id = pa.employee_id
   WHERE pa.project_id IS NULL;  -- Could be NULL even with assignments!

   -- CORRECT: Check the joining column
   WHERE pa.employee_id IS NULL;
   ```

5. **Performance: NOT IN vs NOT EXISTS:**
   ```sql
   -- Slower for large datasets
   WHERE id NOT IN (SELECT employee_id FROM large_table);

   -- Faster: Stops at first match
   WHERE NOT EXISTS (SELECT 1 FROM large_table WHERE employee_id = id);
   ```

---

## NULL Behavior Examples

```sql
-- Demonstration of NULL issues with NOT IN
CREATE TEMP TABLE test_employees (id INT);
INSERT INTO test_employees VALUES (1), (2), (3);

CREATE TEMP TABLE test_assignments (employee_id INT);
INSERT INTO test_assignments VALUES (1), (NULL);

-- Returns no rows! (unexpected)
SELECT * FROM test_employees
WHERE id NOT IN (SELECT employee_id FROM test_assignments);

-- Returns 2 and 3 (expected)
SELECT * FROM test_employees
WHERE id NOT IN (SELECT employee_id FROM test_assignments WHERE employee_id IS NOT NULL);

-- Always works correctly with NOT EXISTS
SELECT * FROM test_employees e
WHERE NOT EXISTS (
    SELECT 1 FROM test_assignments a WHERE a.employee_id = e.id
);
```

---

## Performance Note

- NOT EXISTS is generally fastest for large datasets
- LEFT JOIN with NULL can be optimized well by query planner
- NOT IN is slowest and has NULL issues
- Indexes on foreign key columns dramatically improve performance
- Use EXPLAIN ANALYZE to compare approaches

```sql
-- Check query plan
EXPLAIN ANALYZE
SELECT e.id, e.name
FROM employees e
WHERE NOT EXISTS (
    SELECT 1 FROM project_assignments pa WHERE pa.employee_id = e.id
);

-- Create helpful index
CREATE INDEX idx_project_assignments_emp ON project_assignments(employee_id);
```

---

## Real-World Use Cases

1. **Data cleanup:** Find orphaned records to delete or fix
2. **Quality checks:** Validate referential integrity
3. **Customer engagement:** Identify inactive customers
4. **Inventory management:** Products never sold
5. **HR analytics:** Employees without training, reviews, or assignments
6. **E-commerce:** Abandoned carts, incomplete orders

---

## Related Problems

- **Previous:** [Problem 15 - Categorize Salaries](../15-categorize-salaries/)
- **Next:** [Problem 17 - Query Optimization](../17-query-optimization/)
- **Related:** Problem 6 (JOINs), Problem 8 (Subqueries), Problem 29 (Data Quality Audit)

---

## Notes

```
Your notes here:




```

---

[← Previous](../15-categorize-salaries/) | [Back to Overview](../../README.md) | [Next Problem →](../17-query-optimization/)
