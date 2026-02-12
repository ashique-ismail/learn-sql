# Problem 4: Department Statistics

**Difficulty:** Beginner
**Concepts:** Aggregate functions (COUNT, AVG, SUM, MIN, MAX)
**Phase:** Intermediate Queries (Days 4-6)

---

## Learning Objectives

- Use aggregate functions to perform calculations on groups of rows
- Understand COUNT, AVG, SUM, MIN, and MAX functions
- Combine aggregate functions with GROUP BY
- Learn when to use each aggregate function

---

## Concept Summary

**Aggregate functions** perform calculations on multiple rows and return a single value.

### Syntax

```sql
COUNT(column)    -- Count non-NULL values
COUNT(*)         -- Count all rows
SUM(column)      -- Sum of values
AVG(column)      -- Average
MIN(column)      -- Minimum
MAX(column)      -- Maximum

SELECT COUNT(*), AVG(salary), MAX(salary) FROM employees;
```

### Key Points

- Aggregate functions ignore NULL values (except COUNT(*))
- Can be used with GROUP BY to calculate per group
- Without GROUP BY, aggregates operate on entire table
- Can combine multiple aggregate functions in one query

---

## Problem Statement

**Given table:** `employees(id, name, salary, department)`

**Task:** Find average salary and employee count for each department

---

## Hint

Use GROUP BY with aggregate functions to calculate statistics per department.

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

```sql
SELECT department, AVG(salary) as avg_salary, COUNT(*) as emp_count
FROM employees
GROUP BY department;
```

### Explanation

1. `SELECT department` - Include the grouping column in results
2. `AVG(salary) as avg_salary` - Calculate average salary per department
3. `COUNT(*) as emp_count` - Count employees in each department
4. `GROUP BY department` - Group rows by department before aggregating

### Alternative Solutions

```sql
-- More comprehensive statistics
SELECT
    department,
    COUNT(*) as employee_count,
    AVG(salary) as avg_salary,
    MIN(salary) as min_salary,
    MAX(salary) as max_salary,
    SUM(salary) as total_payroll
FROM employees
GROUP BY department
ORDER BY avg_salary DESC;

-- With formatted output
SELECT
    department,
    COUNT(*) as employees,
    ROUND(AVG(salary), 2) as avg_salary,
    ROUND(AVG(salary) / 12, 2) as avg_monthly_salary
FROM employees
GROUP BY department
ORDER BY department;
```

---

## Try These Variations

1. Find total payroll (sum of all salaries) by department
2. Find the highest and lowest salary in each department
3. Count employees per department, only show departments with more than 5 employees
4. Calculate average salary for the entire company (no GROUP BY)
5. Find departments with average salary above 80000

### Solutions to Variations

```sql
-- 1. Total payroll by department
SELECT department, SUM(salary) as total_payroll
FROM employees
GROUP BY department;

-- 2. Salary range per department
SELECT
    department,
    MIN(salary) as lowest_salary,
    MAX(salary) as highest_salary,
    MAX(salary) - MIN(salary) as salary_range
FROM employees
GROUP BY department;

-- 3. Departments with more than 5 employees
SELECT department, COUNT(*) as emp_count
FROM employees
GROUP BY department
HAVING COUNT(*) > 5;

-- 4. Company-wide average (no GROUP BY)
SELECT
    COUNT(*) as total_employees,
    AVG(salary) as company_avg_salary,
    SUM(salary) as total_payroll
FROM employees;

-- 5. High-paying departments
SELECT department, AVG(salary) as avg_salary
FROM employees
GROUP BY department
HAVING AVG(salary) > 80000
ORDER BY avg_salary DESC;
```

---

## Sample Output

```
   department    | avg_salary  | emp_count
-----------------+-------------+-----------
 Engineering     | 87666.67    |        12
 Executive       | 138333.33   |         3
 Sales           | 71500.00    |         8
 Marketing       | 69000.00    |         5
 Finance         | 75000.00    |         4
 Human Resources | 68500.00    |         4
 Operations      | 64000.00    |         6
```

---

## Common Mistakes

1. **Not using GROUP BY:** Mixing aggregates with non-aggregated columns without GROUP BY causes errors
2. **Counting wrong:** `COUNT(column)` excludes NULLs, use `COUNT(*)` to count all rows
3. **Filtering groups with WHERE:** Use HAVING to filter after aggregation, not WHERE
4. **Forgetting column alias:** Use `as` for readable column names
5. **Rounding issues:** Use ROUND() for decimal precision control

---

## Performance Note

- Aggregate functions can be expensive on large datasets
- Indexes on GROUP BY columns improve performance
- Consider materialized views for frequently-run aggregate queries
- COUNT(*) is typically faster than COUNT(column)

```sql
-- Create index to speed up grouping
CREATE INDEX idx_employees_department ON employees(department);
```

---

## Related Problems

- **Previous:** [Problem 3 - Top Earners](../03-top-earners/)
- **Next:** [Problem 5 - Large Departments](../05-large-departments/)
- **Related:** Problem 9 (CTEs with aggregates), Problem 20 (E-commerce Analytics)

---

## Notes

```
Your notes here:




```

---

[← Previous](../03-top-earners/) | [Back to Overview](../../README.md) | [Next Problem →](../05-large-departments/)
