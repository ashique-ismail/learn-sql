# Problem 9: Department Analysis

**Difficulty:** Intermediate
**Concepts:** Common Table Expressions (CTEs), WITH clause, Multiple CTEs
**Phase:** Advanced Querying (Days 7-9)

---

## Learning Objectives

- Create and use Common Table Expressions (CTEs)
- Chain multiple CTEs together
- Improve query readability with named subqueries
- Understand when to use CTEs vs subqueries

---

## Concept Summary

**CTE (Common Table Expression)** creates temporary named result sets using the WITH clause. More readable than nested subqueries.

### Syntax

```sql
-- Single CTE
WITH cte_name AS (
    SELECT columns FROM table WHERE condition
)
SELECT columns FROM cte_name;

-- Multiple CTEs
WITH cte1 AS (
    SELECT columns FROM table1
),
cte2 AS (
    SELECT columns FROM table2
),
cte3 AS (
    SELECT columns FROM cte1 JOIN cte2
)
SELECT columns FROM cte3;
```

### Benefits of CTEs

1. **Readability:** Named subqueries are easier to understand
2. **Reusability:** Reference the same CTE multiple times
3. **Maintainability:** Changes in one place affect all references
4. **Debugging:** Can test each CTE independently

---

## Problem Statement

**Task:** Find departments where average salary is higher than company average. Show department name, average salary, and difference from company average.

---

## Hint

Use one CTE for company average, another for department averages, then join and filter them.

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

```sql
WITH company_avg AS (
    SELECT AVG(salary) as avg_salary FROM employees
),
dept_avg AS (
    SELECT department, AVG(salary) as dept_avg_salary
    FROM employees
    GROUP BY department
)
SELECT
    d.department,
    d.dept_avg_salary,
    c.avg_salary as company_avg,
    d.dept_avg_salary - c.avg_salary as difference
FROM dept_avg d
CROSS JOIN company_avg c
WHERE d.dept_avg_salary > c.avg_salary;
```

### Explanation

1. **First CTE (company_avg):** Calculate overall company average salary
2. **Second CTE (dept_avg):** Calculate average salary per department
3. **Main query:** Join the two CTEs using CROSS JOIN (since company_avg has only one row)
4. **Filter:** Keep only departments where average exceeds company average
5. **Calculate:** Show the difference between department and company average

### Alternative Solutions

```sql
-- With additional statistics
WITH company_stats AS (
    SELECT
        AVG(salary) as avg_salary,
        STDDEV(salary) as std_dev,
        COUNT(*) as total_employees
    FROM employees
),
dept_stats AS (
    SELECT
        department,
        COUNT(*) as emp_count,
        AVG(salary) as avg_salary,
        MIN(salary) as min_salary,
        MAX(salary) as max_salary
    FROM employees
    GROUP BY department
)
SELECT
    d.department,
    d.emp_count as employees,
    ROUND(d.avg_salary, 2) as dept_avg,
    ROUND(c.avg_salary, 2) as company_avg,
    ROUND(d.avg_salary - c.avg_salary, 2) as difference,
    ROUND(((d.avg_salary - c.avg_salary) / c.avg_salary * 100), 2) as percent_diff
FROM dept_stats d
CROSS JOIN company_stats c
WHERE d.avg_salary > c.avg_salary
ORDER BY difference DESC;

-- Using window function (alternative approach)
SELECT DISTINCT
    department,
    ROUND(dept_avg, 2) as dept_average,
    ROUND(company_avg, 2) as company_average,
    ROUND(dept_avg - company_avg, 2) as difference
FROM (
    SELECT
        department,
        AVG(salary) OVER (PARTITION BY department) as dept_avg,
        AVG(salary) OVER () as company_avg
    FROM employees
) subquery
WHERE dept_avg > company_avg;
```

---

## Try These Variations

1. Find departments with average salary below company average
2. Rank departments by how much they exceed/fall below company average
3. Find departments in top 25% of average salaries
4. Show each employee with their department avg and company avg
5. Find departments where max salary exceeds company average salary

### Solutions to Variations

```sql
-- 1. Below company average
WITH company_avg AS (
    SELECT AVG(salary) as avg_salary FROM employees
),
dept_avg AS (
    SELECT department, AVG(salary) as dept_avg_salary
    FROM employees GROUP BY department
)
SELECT
    d.department,
    ROUND(d.dept_avg_salary, 2) as dept_avg,
    ROUND(c.avg_salary, 2) as company_avg,
    ROUND(c.avg_salary - d.dept_avg_salary, 2) as below_by
FROM dept_avg d
CROSS JOIN company_avg c
WHERE d.dept_avg_salary < c.avg_salary
ORDER BY below_by DESC;

-- 2. Rank all departments
WITH company_avg AS (
    SELECT AVG(salary) as avg_salary FROM employees
),
dept_avg AS (
    SELECT department, AVG(salary) as dept_avg_salary
    FROM employees GROUP BY department
)
SELECT
    d.department,
    ROUND(d.dept_avg_salary, 2) as dept_avg,
    ROUND(d.dept_avg_salary - c.avg_salary, 2) as difference,
    RANK() OVER (ORDER BY d.dept_avg_salary DESC) as rank
FROM dept_avg d
CROSS JOIN company_avg c
ORDER BY rank;

-- 3. Top 25% departments (top quartile)
WITH dept_avg AS (
    SELECT department, AVG(salary) as avg_salary
    FROM employees GROUP BY department
),
quartiles AS (
    SELECT
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY avg_salary) as q3
    FROM dept_avg
)
SELECT d.department, ROUND(d.avg_salary, 2) as avg_salary
FROM dept_avg d
CROSS JOIN quartiles q
WHERE d.avg_salary >= q.q3
ORDER BY d.avg_salary DESC;

-- 4. Each employee with context
WITH dept_avg AS (
    SELECT department, AVG(salary) as dept_avg_salary
    FROM employees GROUP BY department
),
company_avg AS (
    SELECT AVG(salary) as company_avg_salary FROM employees
)
SELECT
    e.name,
    e.salary,
    e.department,
    ROUND(d.dept_avg_salary, 2) as dept_avg,
    ROUND(c.company_avg_salary, 2) as company_avg
FROM employees e
JOIN dept_avg d ON e.department = d.department
CROSS JOIN company_avg c
ORDER BY e.department, e.salary DESC;

-- 5. Departments where max > company avg
WITH company_avg AS (
    SELECT AVG(salary) as avg_salary FROM employees
),
dept_max AS (
    SELECT department, MAX(salary) as max_salary
    FROM employees GROUP BY department
)
SELECT
    d.department,
    d.max_salary,
    ROUND(c.avg_salary, 2) as company_avg,
    d.max_salary - c.avg_salary as difference
FROM dept_max d
CROSS JOIN company_avg c
WHERE d.max_salary > c.avg_salary
ORDER BY difference DESC;
```

---

## Sample Output

```
   department   | dept_avg_salary | company_avg | difference
----------------+-----------------+-------------+------------
 Executive      |      138333.33  |    77555.56 |  60777.77
 Engineering    |       87666.67  |    77555.56 |  10111.11
 Finance        |       82000.00  |    77555.56 |   4444.44
```

---

## Common Mistakes

1. **Missing comma between CTEs:** Each CTE (except last) needs comma
2. **Not using CTE:** Defining a CTE but querying original table instead
3. **Recursive CTEs without RECURSIVE:** Need `WITH RECURSIVE` for recursive queries
4. **Duplicate CTE names:** Each CTE must have unique name
5. **Referencing later CTEs:** Can only reference CTEs defined earlier

---

## CTE vs Subquery vs Temp Table

| Feature | CTE | Subquery | Temp Table |
|---------|-----|----------|------------|
| Syntax | WITH name AS (...) | (...) in query | CREATE TEMP TABLE |
| Reusable | In same query | No | Across queries |
| Readability | High | Low (nested) | High |
| Performance | Same as subquery | Varies | Can be faster with indexes |
| Scope | Single query | Single use | Session/transaction |

---

## When to Use CTEs

Use CTEs when:
- Query has multiple subqueries that could benefit from names
- Same subquery is used multiple times
- Query readability is important
- Building complex queries step by step
- Working with recursive data (requires WITH RECURSIVE)

Don't use CTEs when:
- Simple query with single subquery
- Need to materialize results (use temp table)
- Performance-critical and subquery is more efficient

---

## Advanced: Recursive CTE Example

```sql
-- Find all levels of management hierarchy
WITH RECURSIVE emp_hierarchy AS (
    -- Base case: Top-level manager
    SELECT id, name, manager_id, 1 as level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive case: Direct reports
    SELECT e.id, e.name, e.manager_id, h.level + 1
    FROM employees e
    JOIN emp_hierarchy h ON e.manager_id = h.id
)
SELECT * FROM emp_hierarchy ORDER BY level, name;
```

---

## Performance Note

- CTEs are evaluated once and results are stored temporarily
- In some databases, CTEs are materialized (PostgreSQL 12+: optimization fence)
- Can add `MATERIALIZED` hint in PostgreSQL: `WITH cte AS MATERIALIZED (...)`
- For very large datasets, consider temporary tables with indexes
- Use EXPLAIN to check if CTE is being optimized properly

---

## Related Problems

- **Previous:** [Problem 8 - Above Average Salary](../08-above-average-salary/)
- **Next:** [Problem 10 - Salary Ranking](../10-salary-ranking/)
- **Related:** Problem 18 (Recursive CTEs), Problem 20 (E-commerce Analytics)

---

## Notes

```
Your notes here:




```

---

[← Previous](../08-above-average-salary/) | [Back to Overview](../../README.md) | [Next Problem →](../10-salary-ranking/)
