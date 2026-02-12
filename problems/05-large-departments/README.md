# Problem 5: Large Departments

**Difficulty:** Beginner
**Concepts:** GROUP BY, HAVING, Filtering aggregated data
**Phase:** Intermediate Queries (Days 4-6)

---

## Learning Objectives

- Understand the difference between WHERE and HAVING
- Filter groups after aggregation using HAVING
- Combine multiple conditions in HAVING clause
- Master the order of query execution

---

## Concept Summary

**GROUP BY** groups rows with same values. **HAVING** filters groups after aggregation (WHERE filters rows before grouping).

### Syntax

```sql
SELECT column, AGG_FUNC(column2)
FROM table
WHERE condition           -- Filter rows before grouping
GROUP BY column
HAVING AGG_FUNC(column2)  -- Filter groups after aggregation
ORDER BY column;
```

### Key Differences: WHERE vs HAVING

| WHERE | HAVING |
|-------|--------|
| Filters rows before grouping | Filters groups after aggregation |
| Cannot use aggregate functions | Can use aggregate functions |
| Executes first | Executes after GROUP BY |
| Example: `WHERE salary > 50000` | Example: `HAVING AVG(salary) > 50000` |

---

## Problem Statement

**Task:** Find departments with more than 10 employees and average salary > 60000

---

## Hint

Use HAVING clause for conditions on aggregated data (COUNT and AVG).

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

```sql
SELECT department, COUNT(*) as emp_count, AVG(salary) as avg_salary
FROM employees
GROUP BY department
HAVING COUNT(*) > 10 AND AVG(salary) > 60000;
```

### Explanation

1. `GROUP BY department` - Group employees by department
2. `COUNT(*) as emp_count` - Count employees in each group
3. `AVG(salary) as avg_salary` - Calculate average salary per group
4. `HAVING COUNT(*) > 10` - Keep only groups with more than 10 employees
5. `AND AVG(salary) > 60000` - Also require average salary above 60000

### Alternative Solutions

```sql
-- With better formatting and ordering
SELECT
    department,
    COUNT(*) as employee_count,
    ROUND(AVG(salary), 2) as average_salary,
    MIN(salary) as min_salary,
    MAX(salary) as max_salary
FROM employees
GROUP BY department
HAVING COUNT(*) > 10 AND AVG(salary) > 60000
ORDER BY average_salary DESC;

-- Using WHERE to pre-filter, then HAVING
SELECT
    department,
    COUNT(*) as emp_count,
    AVG(salary) as avg_salary
FROM employees
WHERE salary IS NOT NULL  -- Pre-filter before grouping
GROUP BY department
HAVING COUNT(*) > 10 AND AVG(salary) > 60000
ORDER BY emp_count DESC;
```

---

## Try These Variations

1. Find departments with at least 5 employees
2. Find departments where total payroll exceeds 500000
3. Find departments with average salary between 70000 and 90000
4. Find departments with more than 8 employees OR average salary > 80000
5. Find departments with max salary > 150000 and min salary < 50000

### Solutions to Variations

```sql
-- 1. At least 5 employees
SELECT department, COUNT(*) as emp_count
FROM employees
GROUP BY department
HAVING COUNT(*) >= 5;

-- 2. Total payroll > 500000
SELECT
    department,
    COUNT(*) as employees,
    SUM(salary) as total_payroll
FROM employees
GROUP BY department
HAVING SUM(salary) > 500000
ORDER BY total_payroll DESC;

-- 3. Average salary in range
SELECT
    department,
    ROUND(AVG(salary), 2) as avg_salary
FROM employees
GROUP BY department
HAVING AVG(salary) BETWEEN 70000 AND 90000;

-- 4. Using OR in HAVING
SELECT
    department,
    COUNT(*) as emp_count,
    ROUND(AVG(salary), 2) as avg_salary
FROM employees
GROUP BY department
HAVING COUNT(*) > 8 OR AVG(salary) > 80000;

-- 5. Salary range criteria
SELECT
    department,
    COUNT(*) as emp_count,
    MIN(salary) as min_salary,
    MAX(salary) as max_salary
FROM employees
GROUP BY department
HAVING MAX(salary) > 150000 AND MIN(salary) < 50000;
```

---

## Sample Output

```
  department   | emp_count | avg_salary
---------------+-----------+-------------
 Engineering   |        12 |  87666.67
 Sales         |        11 |  71500.00
```

---

## Common Mistakes

1. **Using WHERE for aggregates:** `WHERE COUNT(*) > 10` is invalid - use HAVING
2. **Using HAVING without GROUP BY:** HAVING requires GROUP BY (except for aggregate on entire table)
3. **Forgetting aggregate in HAVING:** If filtering on a column, it must be aggregated or in GROUP BY
4. **Wrong execution order assumption:** WHERE runs before GROUP BY, HAVING runs after
5. **Column aliases in HAVING:** Some databases don't allow `HAVING avg_salary > 60000`, must use `HAVING AVG(salary) > 60000`

---

## Query Execution Order

Understanding the order helps avoid common mistakes:

```sql
1. FROM        -- Get the data
2. WHERE       -- Filter rows
3. GROUP BY    -- Group rows
4. HAVING      -- Filter groups
5. SELECT      -- Choose columns
6. ORDER BY    -- Sort results
7. LIMIT       -- Limit output
```

Example:
```sql
SELECT department, AVG(salary) as avg_sal
FROM employees
WHERE salary > 40000          -- 1. Filter individuals first
GROUP BY department           -- 2. Then group
HAVING AVG(salary) > 70000   -- 3. Then filter groups
ORDER BY avg_sal DESC         -- 4. Finally sort
LIMIT 5;                      -- 5. And limit
```

---

## Performance Note

- Use WHERE to filter as much data as possible before grouping
- Indexes on GROUP BY columns improve performance
- HAVING is applied after aggregation, so it doesn't reduce aggregation work
- Pre-filter with WHERE when possible to reduce rows being grouped

```sql
-- Less efficient (filters after grouping all rows)
SELECT department, AVG(salary)
FROM employees
GROUP BY department
HAVING AVG(salary) > 60000;

-- More efficient (filters before grouping)
SELECT department, AVG(salary)
FROM employees
WHERE department IN ('Engineering', 'Sales', 'Finance')
GROUP BY department
HAVING AVG(salary) > 60000;
```

---

## Related Problems

- **Previous:** [Problem 4 - Department Statistics](../04-department-statistics/)
- **Next:** [Problem 6 - Employee Department Details](../06-employee-department-details/)
- **Related:** Problem 9 (CTEs), Problem 20 (E-commerce Analytics)

---

## Notes

```
Your notes here:




```

---

[← Previous](../04-department-statistics/) | [Back to Overview](../../README.md) | [Next Problem →](../06-employee-department-details/)
