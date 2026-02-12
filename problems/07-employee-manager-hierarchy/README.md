# Problem 7: Employee Manager Hierarchy

**Difficulty:** Intermediate
**Concepts:** Self JOIN, Table aliases, Organizational hierarchies
**Phase:** Intermediate Queries (Days 4-6)

---

## Learning Objectives

- Understand self joins (joining a table to itself)
- Model hierarchical relationships in SQL
- Use multiple aliases for the same table
- Handle NULL values in hierarchical data

---

## Concept Summary

**Self JOIN** joins a table with itself. Useful for hierarchical data where rows reference other rows in the same table.

### Syntax

```sql
-- Self join pattern
SELECT a.column, b.column
FROM table a
JOIN table b ON a.key = b.key;

-- Example: Employee-Manager relationship
SELECT e.name as employee, m.name as manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id;
```

### Key Points

- Use different aliases for each reference to the same table
- LEFT JOIN includes employees without managers (e.g., CEO)
- manager_id is a foreign key referencing the same table's id
- Think of it as two separate copies of the table

---

## Problem Statement

**Given table:** `employees(id, name, manager_id)`

**Task:** List each employee with their manager's name

---

## Hint

Self join the employees table on manager_id. Use LEFT JOIN to include employees without managers.

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

```sql
SELECT e.name as employee, m.name as manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id;
```

### Explanation

1. `FROM employees e` - First reference to employees (the employees themselves)
2. `LEFT JOIN employees m` - Second reference to same table (the managers)
3. `ON e.manager_id = m.id` - Match employee's manager_id to manager's id
4. `e.name as employee` - Employee name from first reference
5. `m.name as manager` - Manager name from second reference
6. LEFT JOIN ensures top-level employees (NULL manager_id) are included

### Alternative Solutions

```sql
-- Include more details
SELECT
    e.id as emp_id,
    e.name as employee,
    e.salary as emp_salary,
    m.name as manager,
    m.salary as manager_salary
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id
ORDER BY m.name, e.name;

-- Show reporting structure with department
SELECT
    e.name as employee,
    e.department,
    COALESCE(m.name, 'No Manager') as manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id
ORDER BY e.department, m.name;

-- Find salary comparison with manager
SELECT
    e.name as employee,
    e.salary,
    m.name as manager,
    m.salary as manager_salary,
    m.salary - e.salary as salary_difference
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id
WHERE m.id IS NOT NULL;
```

---

## Try These Variations

1. Find employees who earn more than their manager
2. Find employees without a manager (top-level)
3. Show manager with count of direct reports
4. Find the manager of the manager (2 levels up)
5. Show employees with their manager and manager's manager

### Solutions to Variations

```sql
-- 1. Employees earning more than their manager
SELECT
    e.name as employee,
    e.salary as emp_salary,
    m.name as manager,
    m.salary as manager_salary
FROM employees e
INNER JOIN employees m ON e.manager_id = m.id
WHERE e.salary > m.salary;

-- 2. Employees without manager
SELECT name, salary, department
FROM employees
WHERE manager_id IS NULL;

-- 3. Manager with direct report count
SELECT
    m.name as manager,
    m.department,
    COUNT(e.id) as direct_reports
FROM employees m
LEFT JOIN employees e ON m.id = e.manager_id
GROUP BY m.id, m.name, m.department
HAVING COUNT(e.id) > 0
ORDER BY direct_reports DESC;

-- 4. Manager's manager (2 levels)
SELECT
    e.name as employee,
    m1.name as manager,
    m2.name as managers_manager
FROM employees e
LEFT JOIN employees m1 ON e.manager_id = m1.id
LEFT JOIN employees m2 ON m1.manager_id = m2.id;

-- 5. Three-level hierarchy
SELECT
    e.name as employee,
    e.salary,
    COALESCE(m1.name, 'None') as direct_manager,
    COALESCE(m2.name, 'None') as senior_manager,
    COALESCE(m3.name, 'None') as executive
FROM employees e
LEFT JOIN employees m1 ON e.manager_id = m1.id
LEFT JOIN employees m2 ON m1.manager_id = m2.id
LEFT JOIN employees m3 ON m2.manager_id = m3.id
ORDER BY e.name;
```

---

## Sample Output

```
    employee     |    manager
-----------------+----------------
 Alice Johnson   | NULL
 Bob Smith       | Alice Johnson
 Carol White     | Alice Johnson
 David Brown     | Carol White
 Emma Davis      | Bob Smith
 Frank Miller    | Bob Smith
 Grace Lee       | Bob Smith
 Henry Wilson    | Frank Miller
```

---

## Common Mistakes

1. **Not using aliases:** Trying to join employees to employees without aliases causes errors
2. **Using INNER JOIN:** Excludes top-level employees (those with NULL manager_id)
3. **Wrong join condition:** Joining on wrong columns produces incorrect results
4. **Circular references:** Data quality issue - employee can't be their own manager
5. **Ambiguous columns:** Must prefix columns with alias (e.g., `e.name`, not just `name`)

---

## Advanced: Finding Full Hierarchy Path

For deeper hierarchies, use recursive CTEs (PostgreSQL):

```sql
WITH RECURSIVE emp_hierarchy AS (
    -- Base case: Top-level employees
    SELECT
        id,
        name,
        manager_id,
        name as hierarchy_path,
        0 as level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive case: Add direct reports
    SELECT
        e.id,
        e.name,
        e.manager_id,
        h.hierarchy_path || ' > ' || e.name,
        h.level + 1
    FROM employees e
    INNER JOIN emp_hierarchy h ON e.manager_id = h.id
)
SELECT
    name,
    level,
    hierarchy_path
FROM emp_hierarchy
ORDER BY hierarchy_path;
```

---

## Performance Note

- Self joins can be expensive on large tables
- Index the foreign key column (manager_id)
- Consider recursive CTEs for deep hierarchies
- Materialized views can help for frequently-queried hierarchies

```sql
-- Critical index for self joins
CREATE INDEX idx_employees_manager_id ON employees(manager_id);
```

---

## Real-World Use Cases

1. **Organizational charts:** Employee-Manager relationships
2. **Product categories:** Category-Subcategory hierarchies
3. **File systems:** Folder-Subfolder structures
4. **Social networks:** Friend-of-friend relationships
5. **Bill of materials:** Part-Subpart assemblies

---

## Related Problems

- **Previous:** [Problem 6 - Employee Department Details](../06-employee-department-details/)
- **Next:** [Problem 8 - Above Average Salary](../08-above-average-salary/)
- **Related:** Problem 18 (Recursive CTEs for Organization Hierarchy)

---

## Notes

```
Your notes here:




```

---

[← Previous](../06-employee-department-details/) | [Back to Overview](../../README.md) | [Next Problem →](../08-above-average-salary/)
