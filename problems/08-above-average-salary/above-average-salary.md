# Problem 8: Above Average Salary

**Difficulty:** Intermediate
**Concepts:** Subqueries, Correlated subqueries, Derived tables
**Phase:** Advanced Querying (Days 7-9)

---

## Learning Objectives

- Write subqueries in different clauses (WHERE, FROM, SELECT)
- Understand correlated vs uncorrelated subqueries
- Compare subquery approaches for the same problem
- Use derived tables for complex filtering

---

## Concept Summary

**Subquery** is a query nested inside another query. Can be used in SELECT, FROM, WHERE, or HAVING clauses.

### Syntax

```sql
-- Subquery in WHERE
SELECT columns FROM table
WHERE column IN (SELECT column FROM table2 WHERE condition);

-- Subquery in FROM (derived table)
SELECT columns FROM (
    SELECT columns FROM table WHERE condition
) AS subquery;

-- Subquery in SELECT (scalar subquery - returns single value)
SELECT
    column,
    (SELECT AGG_FUNC(col) FROM table2 WHERE condition) AS alias
FROM table;

-- Correlated subquery (references outer query)
SELECT columns FROM table1 t1
WHERE column > (
    SELECT AVG(column) FROM table2 t2
    WHERE t2.key = t1.key  -- References outer query
);
```

### Correlated vs Uncorrelated

- **Uncorrelated:** Independent, runs once
- **Correlated:** References outer query, runs for each row (slower)

---

## Problem Statement

**Task:** Find employees earning more than the average salary of their department

---

## Hint

Use a correlated subquery comparing each employee's salary to their department's average, or use a derived table with department averages.

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

### Method 1: Correlated Subquery

```sql
SELECT name, salary, department
FROM employees e1
WHERE salary > (
    SELECT AVG(salary)
    FROM employees e2
    WHERE e2.department = e1.department
);
```

### Method 2: Derived Table (JOIN)

```sql
SELECT e.name, e.salary, e.department
FROM employees e
JOIN (
    SELECT department, AVG(salary) as avg_sal
    FROM employees
    GROUP BY department
) dept_avg ON e.department = dept_avg.department
WHERE e.salary > dept_avg.avg_sal;
```

### Explanation

**Method 1 (Correlated Subquery):**
1. Outer query examines each employee
2. For each employee, inner query calculates their department's average
3. Compare employee's salary to that average
4. Keep employee if salary is higher
5. Runs subquery once per employee row (can be slower)

**Method 2 (Derived Table):**
1. Inner query first calculates average salary per department
2. Join this result to employees table
3. Filter where employee salary exceeds department average
4. Subquery runs only once (typically faster)

### Alternative Solutions

```sql
-- Method 3: Using CTE (most readable)
WITH dept_averages AS (
    SELECT department, AVG(salary) as avg_salary
    FROM employees
    GROUP BY department
)
SELECT
    e.name,
    e.salary,
    e.department,
    ROUND(d.avg_salary, 2) as dept_avg,
    ROUND(e.salary - d.avg_salary, 2) as difference
FROM employees e
JOIN dept_averages d ON e.department = d.department
WHERE e.salary > d.avg_salary
ORDER BY e.department, e.salary DESC;

-- Method 4: Window function (advanced)
SELECT name, salary, department, dept_avg
FROM (
    SELECT
        name,
        salary,
        department,
        AVG(salary) OVER (PARTITION BY department) as dept_avg
    FROM employees
) subquery
WHERE salary > dept_avg;
```

---

## Try These Variations

1. Find employees earning less than their department average
2. Find employees earning more than the company average
3. Show employees with salary difference from department average
4. Find top earner in each department
5. Find employees in departments where average > company average

### Solutions to Variations

```sql
-- 1. Below department average
SELECT name, salary, department
FROM employees e1
WHERE salary < (
    SELECT AVG(salary)
    FROM employees e2
    WHERE e2.department = e1.department
);

-- 2. Above company average
SELECT name, salary, department
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- 3. Difference from department average
SELECT
    name,
    salary,
    department,
    ROUND((
        SELECT AVG(salary)
        FROM employees e2
        WHERE e2.department = e1.department
    ), 2) as dept_avg,
    ROUND(salary - (
        SELECT AVG(salary)
        FROM employees e2
        WHERE e2.department = e1.department
    ), 2) as difference
FROM employees e1
ORDER BY department, difference DESC;

-- 4. Top earner per department (subquery method)
SELECT name, salary, department
FROM employees e1
WHERE salary = (
    SELECT MAX(salary)
    FROM employees e2
    WHERE e2.department = e1.department
);

-- 5. Employees in high-paying departments
SELECT name, salary, department
FROM employees e
WHERE department IN (
    SELECT department
    FROM employees
    GROUP BY department
    HAVING AVG(salary) > (SELECT AVG(salary) FROM employees)
);
```

---

## Sample Output

```
      name       | salary  |  department
-----------------+---------+---------------
 Alice Johnson   | 150000  | Executive
 Bob Smith       | 140000  | Executive
 Emma Davis      | 95000   | Engineering
 Frank Miller    | 88000   | Engineering
 Grace Lee       | 92000   | Engineering
 Tom Anderson    | 78000   | Sales
 Sarah Parker    | 76000   | Sales
```

---

## Common Mistakes

1. **Missing correlation:** Forgetting WHERE clause in correlated subquery
2. **Subquery returns multiple rows:** Using = instead of IN when subquery returns multiple values
3. **Performance issues:** Using correlated subquery on large tables without indexes
4. **NULL handling:** Not considering NULL values in comparisons
5. **Column ambiguity:** Not using table aliases in correlated subqueries

---

## Performance Comparison

```sql
-- SLOW: Correlated subquery (runs once per row)
SELECT name FROM employees e1
WHERE salary > (
    SELECT AVG(salary) FROM employees e2
    WHERE e2.department = e1.department
);
-- Execution: N subqueries (one per employee)

-- FASTER: Derived table (runs once)
SELECT e.name
FROM employees e
JOIN (
    SELECT department, AVG(salary) as avg_sal
    FROM employees GROUP BY department
) d ON e.department = d.department
WHERE e.salary > d.avg_sal;
-- Execution: 1 subquery + 1 join

-- FASTEST: Window function (single scan)
SELECT name FROM (
    SELECT name, salary, AVG(salary) OVER (PARTITION BY department) as avg_sal
    FROM employees
) t
WHERE salary > avg_sal;
-- Execution: 1 table scan
```

---

## Subquery Types Summary

| Type | Location | Returns | Example Use |
|------|----------|---------|-------------|
| Scalar | SELECT | Single value | `SELECT (SELECT MAX(price) FROM products)` |
| Row | WHERE | Single row | `WHERE (a,b) = (SELECT x,y FROM t LIMIT 1)` |
| Column | WHERE | Multiple values | `WHERE id IN (SELECT id FROM table)` |
| Table | FROM | Multiple rows/cols | `FROM (SELECT * FROM t WHERE x>5) AS sub` |
| Correlated | WHERE/SELECT | Varies | `WHERE x > (SELECT AVG(y) WHERE z = outer.z)` |

---

## Performance Note

- Derived tables and CTEs are usually faster than correlated subqueries
- Window functions are often the fastest for this type of problem
- Index the columns used in WHERE clauses
- Use EXPLAIN to compare performance

```sql
-- Compare execution plans
EXPLAIN ANALYZE
SELECT name FROM employees e1
WHERE salary > (SELECT AVG(salary) FROM employees e2 WHERE e2.department = e1.department);
```

---

## Related Problems

- **Previous:** [Problem 7 - Employee Manager Hierarchy](../07-employee-manager-hierarchy/)
- **Next:** [Problem 9 - Department Analysis](../09-department-analysis/)
- **Related:** Problem 9 (CTEs), Problem 10 (Window Functions)

---

## Notes

```
Your notes here:




```

---

[← Previous](../07-employee-manager-hierarchy/) | [Back to Overview](../../README.md) | [Next Problem →](../09-department-analysis/)
