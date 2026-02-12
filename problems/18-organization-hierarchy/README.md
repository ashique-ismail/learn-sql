# Problem 18: Organization Hierarchy

**Difficulty:** Advanced
**Concepts:** Recursive CTEs, Hierarchical data, Self-referencing tables, Tree traversal
**Phase:** Advanced Topics (Days 19-20)

---

## Learning Objectives

- Master recursive CTEs (Common Table Expressions)
- Query hierarchical data structures
- Traverse organizational trees
- Calculate depth and path in hierarchies
- Handle circular references safely
- Understand base case and recursive case

---

## Concept Summary

**Recursive CTEs** are queries that reference themselves, allowing traversal of hierarchical data like org charts, file systems, or category trees.

### Syntax

```sql
WITH RECURSIVE cte_name AS (
    -- Base case (anchor member): Starting point
    SELECT columns FROM table
    WHERE base_condition

    UNION ALL

    -- Recursive case (recursive member): Iterative step
    SELECT columns FROM table
    JOIN cte_name ON join_condition
    WHERE recursive_condition
)
SELECT * FROM cte_name;
```

### Key Concepts

- **Base case:** Starting rows (e.g., root nodes)
- **Recursive case:** How to find next level
- **UNION ALL:** Combines iterations (use ALL, not UNION)
- **Termination:** Recursion stops when no new rows found
- **Depth tracking:** Add level counter to track depth

---

## Problem Statement

**Given:** employees(id, name, manager_id)

**Task:** Find all employees reporting to a specific manager (manager_id = 5), both directly and indirectly. Show employee id, name, and level in the hierarchy.

---

## Hint

Start with the target manager (base case), then recursively find employees whose manager_id matches the current level.

---

## Your Solution

```sql
-- Write your recursive CTE here




```

---

## Solution

```sql
WITH RECURSIVE employee_hierarchy AS (
    -- Base case: Start with target manager
    SELECT
        id,
        name,
        manager_id,
        1 as level
    FROM employees
    WHERE id = 5  -- Target manager

    UNION ALL

    -- Recursive case: Find direct reports
    SELECT
        e.id,
        e.name,
        e.manager_id,
        eh.level + 1
    FROM employees e
    JOIN employee_hierarchy eh ON e.manager_id = eh.id
)
SELECT
    id,
    name,
    level,
    REPEAT('  ', level - 1) || name as indented_name
FROM employee_hierarchy
WHERE id != 5  -- Exclude the manager themselves
ORDER BY level, name;
```

### Explanation

1. **Base case:** Select manager with id = 5, set level = 1
2. **UNION ALL:** Combines base case with recursive results
3. **Recursive case:** Join employees to hierarchy where manager_id matches current id
4. **Level tracking:** Increment level with each recursion
5. **Termination:** Stops when no more employees have manager_id matching current level
6. **Indentation:** Visual representation of hierarchy depth

---

## Extended Examples

### Find All Ancestors (Bottom-Up)

```sql
-- Find all managers above employee with id = 42
WITH RECURSIVE manager_chain AS (
    -- Base case: Start with target employee
    SELECT
        id,
        name,
        manager_id,
        1 as level
    FROM employees
    WHERE id = 42

    UNION ALL

    -- Recursive case: Find manager
    SELECT
        e.id,
        e.name,
        e.manager_id,
        mc.level + 1
    FROM employees e
    JOIN manager_chain mc ON e.id = mc.manager_id
)
SELECT
    level,
    id,
    name
FROM manager_chain
ORDER BY level DESC;
```

### Complete Hierarchy Tree

```sql
-- Build complete org chart from CEO down
WITH RECURSIVE org_tree AS (
    -- Base case: CEO (employee with no manager)
    SELECT
        id,
        name,
        manager_id,
        name as path,
        1 as level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive case: All employees
    SELECT
        e.id,
        e.name,
        e.manager_id,
        ot.path || ' > ' || e.name as path,
        ot.level + 1
    FROM employees e
    JOIN org_tree ot ON e.manager_id = ot.id
)
SELECT
    level,
    REPEAT('  ', level - 1) || name as org_chart,
    path
FROM org_tree
ORDER BY path;
```

### Count Direct and Indirect Reports

```sql
WITH RECURSIVE employee_hierarchy AS (
    SELECT
        id,
        name,
        manager_id,
        0 as level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT
        e.id,
        e.name,
        e.manager_id,
        eh.level + 1
    FROM employees e
    JOIN employee_hierarchy eh ON e.manager_id = eh.id
)
SELECT
    m.id,
    m.name as manager_name,
    COUNT(DISTINCT CASE WHEN eh.manager_id = m.id THEN eh.id END) as direct_reports,
    COUNT(DISTINCT eh.id) - 1 as total_reports  -- Subtract self
FROM employees m
LEFT JOIN employee_hierarchy eh ON eh.manager_id = m.id
   OR EXISTS (
       SELECT 1 FROM employee_hierarchy eh2
       WHERE eh2.manager_id = m.id AND eh.id != m.id
   )
GROUP BY m.id, m.name
HAVING COUNT(DISTINCT eh.id) > 1
ORDER BY total_reports DESC;
```

### Detect Circular References

```sql
-- Safely traverse with cycle detection
WITH RECURSIVE employee_hierarchy AS (
    SELECT
        id,
        name,
        manager_id,
        ARRAY[id] as path,
        1 as level,
        false as cycle
    FROM employees
    WHERE id = 5

    UNION ALL

    SELECT
        e.id,
        e.name,
        e.manager_id,
        eh.path || e.id,
        eh.level + 1,
        e.id = ANY(eh.path)  -- Detect cycle
    FROM employees e
    JOIN employee_hierarchy eh ON e.manager_id = eh.id
    WHERE NOT eh.cycle  -- Stop if cycle detected
)
SELECT
    id,
    name,
    level,
    cycle,
    CASE WHEN cycle THEN 'CIRCULAR REFERENCE DETECTED' ELSE 'OK' END as status
FROM employee_hierarchy;
```

---

## Advanced Hierarchy Queries

### Span of Control (Direct Reports)

```sql
WITH RECURSIVE org_tree AS (
    SELECT id, name, manager_id, 1 as level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT e.id, e.name, e.manager_id, ot.level + 1
    FROM employees e
    JOIN org_tree ot ON e.manager_id = ot.id
)
SELECT
    m.id,
    m.name,
    COUNT(e.id) as direct_reports,
    STRING_AGG(e.name, ', ' ORDER BY e.name) as report_names
FROM employees m
LEFT JOIN employees e ON e.manager_id = m.id
GROUP BY m.id, m.name
HAVING COUNT(e.id) > 0
ORDER BY direct_reports DESC;
```

### Depth of Organization

```sql
WITH RECURSIVE org_depth AS (
    SELECT id, name, manager_id, 1 as level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT e.id, e.name, e.manager_id, od.level + 1
    FROM employees e
    JOIN org_depth od ON e.manager_id = od.id
)
SELECT
    MAX(level) as max_depth,
    MIN(level) as min_depth,
    ROUND(AVG(level), 2) as avg_depth
FROM org_depth;
```

### Leaves (Employees with No Reports)

```sql
WITH RECURSIVE org_tree AS (
    SELECT id, name, manager_id, 1 as level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT e.id, e.name, e.manager_id, ot.level + 1
    FROM employees e
    JOIN org_tree ot ON e.manager_id = ot.id
)
SELECT ot.id, ot.name, ot.level
FROM org_tree ot
WHERE NOT EXISTS (
    SELECT 1 FROM employees e WHERE e.manager_id = ot.id
)
ORDER BY ot.level, ot.name;
```

---

## Try These Variations

1. Find the CEO (employee with no manager)
2. Find all employees at a specific level (e.g., level 3)
3. Calculate total salary cost for each manager's entire team
4. Find employees who are 2-3 levels below a specific manager
5. Show the shortest path between two employees

### Solutions to Variations

```sql
-- 1. Find CEO
SELECT id, name
FROM employees
WHERE manager_id IS NULL;

-- 2. Employees at specific level
WITH RECURSIVE org_tree AS (
    SELECT id, name, manager_id, 1 as level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT e.id, e.name, e.manager_id, ot.level + 1
    FROM employees e
    JOIN org_tree ot ON e.manager_id = ot.id
)
SELECT id, name
FROM org_tree
WHERE level = 3
ORDER BY name;

-- 3. Total salary cost per manager
WITH RECURSIVE team_hierarchy AS (
    SELECT id, name, manager_id, salary, 1 as level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT e.id, e.name, e.manager_id, e.salary, th.level + 1
    FROM employees e
    JOIN team_hierarchy th ON e.manager_id = th.id
)
SELECT
    m.id,
    m.name as manager,
    COUNT(th.id) - 1 as team_size,
    SUM(th.salary) as total_team_cost,
    SUM(th.salary) - m.salary as subordinates_cost
FROM employees m
JOIN team_hierarchy th ON m.id = th.id OR EXISTS (
    SELECT 1 FROM team_hierarchy th2
    WHERE th2.manager_id = m.id
)
GROUP BY m.id, m.name, m.salary
HAVING COUNT(th.id) > 1
ORDER BY total_team_cost DESC;

-- 4. Employees 2-3 levels below manager
WITH RECURSIVE hierarchy AS (
    SELECT id, name, manager_id, 0 as level
    FROM employees
    WHERE id = 5

    UNION ALL

    SELECT e.id, e.name, e.manager_id, h.level + 1
    FROM employees e
    JOIN hierarchy h ON e.manager_id = h.id
    WHERE h.level < 3
)
SELECT id, name, level
FROM hierarchy
WHERE level BETWEEN 2 AND 3
ORDER BY level, name;

-- 5. Path between two employees
WITH RECURSIVE path_up AS (
    -- Trace from employee1 to root
    SELECT id, name, manager_id, ARRAY[id] as path, 0 as level
    FROM employees
    WHERE id = 10

    UNION ALL

    SELECT e.id, e.name, e.manager_id, p.path || e.id, p.level + 1
    FROM employees e
    JOIN path_up p ON e.id = p.manager_id
),
path_down AS (
    -- Trace from employee2 to root
    SELECT id, name, manager_id, ARRAY[id] as path, 0 as level
    FROM employees
    WHERE id = 25

    UNION ALL

    SELECT e.id, e.name, e.manager_id, p.path || e.id, p.level + 1
    FROM employees e
    JOIN path_down p ON e.id = p.manager_id
)
SELECT
    u.path as path_from_10,
    d.path as path_from_25,
    -- Find common ancestor
    (SELECT unnest(u.path) INTERSECT SELECT unnest(d.path) LIMIT 1) as common_ancestor
FROM path_up u, path_down d
WHERE u.level = (SELECT MAX(level) FROM path_up)
  AND d.level = (SELECT MAX(level) FROM path_down);
```

---

## Sample Output

```
 id |      name       | level |     indented_name
----+-----------------+-------+------------------------
 12 | Alice Johnson   |   2   |   Alice Johnson
 15 | Bob Smith       |   2   |   Bob Smith
 23 | Carol White     |   3   |     Carol White
 28 | David Brown     |   3   |     David Brown
 31 | Emma Davis      |   4   |       Emma Davis
(5 rows)
```

With path visualization:
```
Level 1: John Doe (CEO)
Level 2:   Alice Johnson (VP Engineering)
Level 2:   Bob Smith (VP Sales)
Level 3:     Carol White (Engineering Manager)
Level 3:     David Brown (Sales Manager)
Level 4:       Emma Davis (Senior Engineer)
```

---

## Common Mistakes

1. **Forgetting UNION ALL:** Using UNION removes duplicates (slower, wrong for recursion)
2. **No termination condition:** Causes infinite loop
3. **Wrong join condition:** Joins on wrong columns
4. **Not tracking level:** Can't determine depth
5. **Circular references:** Need cycle detection for untrusted data
6. **Including starting node:** May need to exclude with WHERE clause

---

## Performance Note

- Recursive CTEs can be slow on deep hierarchies
- Consider materialized path or nested set models for very large trees
- Index on manager_id column is critical
- Use WHERE clauses to limit recursion depth
- Test with maximum expected depth

```sql
-- Add recursion limit (PostgreSQL)
SET max_stack_depth = '7MB';

-- Limit depth explicitly
WHERE level <= 10
```

---

## Alternative Hierarchical Models

### Materialized Path

```sql
-- Store full path in column
CREATE TABLE employees_mp (
    id INTEGER PRIMARY KEY,
    name VARCHAR(200),
    path VARCHAR(500)  -- e.g., '/1/5/12/23/'
);

-- Query is simple range scan
SELECT * FROM employees_mp
WHERE path LIKE '/1/5/%';
```

### Nested Set

```sql
-- Store left and right boundaries
CREATE TABLE employees_ns (
    id INTEGER PRIMARY KEY,
    name VARCHAR(200),
    lft INTEGER,
    rgt INTEGER
);

-- All descendants
SELECT * FROM employees_ns
WHERE lft > 10 AND rgt < 20;
```

---

## Real-World Use Cases

1. **Organization charts:** Employee reporting structure
2. **Category trees:** Product categories, menu hierarchies
3. **File systems:** Folder structure
4. **Comment threads:** Nested comments
5. **Bill of materials:** Manufacturing parts hierarchy
6. **Network routing:** Finding paths in networks

---

## Related Problems

- **Previous:** [Problem 17 - Query Optimization](../17-query-optimization/)
- **Next:** [Problem 19 - Complex Join Challenge](../19-complex-join-challenge/)
- **Related:** Problem 7 (Self Join), Problem 9 (CTEs)

---

## Notes

```
Your notes here:




```

---

[← Previous](../17-query-optimization/) | [Back to Overview](../../README.md) | [Next Problem →](../19-complex-join-challenge/)
