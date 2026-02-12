# 05 - Aggregate Queries

## Overview
Aggregate functions perform calculations on a set of rows and return a single value. They are essential for data analysis and reporting.

**Main Aggregate Functions:**
- `COUNT()` - Count rows
- `SUM()` - Sum values
- `AVG()` - Average values
- `MIN()` - Minimum value
- `MAX()` - Maximum value

## Basic Aggregate Functions

### COUNT - Counting Rows
```sql
-- Count all rows
SELECT COUNT(*) FROM employees;

-- Count non-NULL values in a column
SELECT COUNT(email) FROM employees;

-- Count distinct values
SELECT COUNT(DISTINCT department_id) FROM employees;

-- Count with condition
SELECT COUNT(*) FROM employees WHERE salary > 50000;
```

### SUM - Total Sum
```sql
-- Sum of all salaries
SELECT SUM(salary) FROM employees;

-- Sum with condition
SELECT SUM(salary) FROM employees WHERE department_id = 10;

-- Sum with calculation
SELECT SUM(price * quantity) AS total_revenue FROM order_items;

-- SUM returns NULL if no rows match
SELECT SUM(salary) FROM employees WHERE department_id = 999;
-- Returns: NULL
```

### AVG - Average Value
```sql
-- Average salary
SELECT AVG(salary) FROM employees;

-- Average with condition
SELECT AVG(salary) FROM employees WHERE department_id = 10;

-- Average ignores NULL values
SELECT AVG(commission) FROM employees;  -- NULLs are excluded

-- Round average to 2 decimal places
SELECT ROUND(AVG(salary), 2) FROM employees;
```

### MIN and MAX - Minimum and Maximum
```sql
-- Minimum and maximum salary
SELECT MIN(salary), MAX(salary) FROM employees;

-- Earliest and latest hire date
SELECT MIN(hire_date), MAX(hire_date) FROM employees;

-- Works with strings (alphabetical)
SELECT MIN(last_name), MAX(last_name) FROM employees;
```

### Combining Aggregate Functions
```sql
-- Multiple aggregates in one query
SELECT
    COUNT(*) AS total_employees,
    SUM(salary) AS total_payroll,
    AVG(salary) AS average_salary,
    MIN(salary) AS lowest_salary,
    MAX(salary) AS highest_salary
FROM employees;
```

## GROUP BY - Grouping Data

### Basic GROUP BY
```sql
-- Count employees per department
SELECT department_id, COUNT(*) AS employee_count
FROM employees
GROUP BY department_id;

-- Average salary per department
SELECT department_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id;
```

### GROUP BY with Multiple Columns
```sql
-- Count by department and job title
SELECT
    department_id,
    job_title,
    COUNT(*) AS employee_count
FROM employees
GROUP BY department_id, job_title;

-- Sales by year and quarter
SELECT
    EXTRACT(YEAR FROM order_date) AS year,
    EXTRACT(QUARTER FROM order_date) AS quarter,
    SUM(total_amount) AS total_sales
FROM orders
GROUP BY
    EXTRACT(YEAR FROM order_date),
    EXTRACT(QUARTER FROM order_date)
ORDER BY year, quarter;
```

### GROUP BY Rules
```sql
-- RULE: Every column in SELECT must be either:
-- 1. In GROUP BY clause, OR
-- 2. Inside an aggregate function

-- CORRECT
SELECT department_id, COUNT(*)
FROM employees
GROUP BY department_id;

-- WRONG: first_name not in GROUP BY or aggregate
SELECT department_id, first_name, COUNT(*)
FROM employees
GROUP BY department_id;

-- CORRECT: first_name in aggregate
SELECT department_id, MAX(first_name), COUNT(*)
FROM employees
GROUP BY department_id;
```

### GROUP BY with WHERE
```sql
-- WHERE filters BEFORE grouping
SELECT department_id, AVG(salary)
FROM employees
WHERE hire_date >= '2020-01-01'  -- Filter before grouping
GROUP BY department_id;

-- Order of execution:
-- 1. FROM employees
-- 2. WHERE hire_date >= '2020-01-01'
-- 3. GROUP BY department_id
-- 4. SELECT department_id, AVG(salary)
```

## HAVING - Filtering Groups

### Basic HAVING
```sql
-- HAVING filters AFTER grouping
SELECT department_id, COUNT(*) AS employee_count
FROM employees
GROUP BY department_id
HAVING COUNT(*) > 10;  -- Filter groups after aggregation
```

### WHERE vs HAVING
```sql
-- WHERE: filters individual rows BEFORE grouping
-- HAVING: filters groups AFTER grouping

-- Find departments with average salary > 60000
SELECT department_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id
HAVING AVG(salary) > 60000;

-- Combine WHERE and HAVING
SELECT department_id, AVG(salary) AS avg_salary
FROM employees
WHERE hire_date >= '2020-01-01'  -- Filter rows first
GROUP BY department_id
HAVING AVG(salary) > 60000;      -- Then filter groups
```

### Complex HAVING Conditions
```sql
-- Multiple conditions in HAVING
SELECT department_id, COUNT(*), AVG(salary)
FROM employees
GROUP BY department_id
HAVING COUNT(*) > 5 AND AVG(salary) > 50000;

-- HAVING with different aggregate than SELECT
SELECT department_id, AVG(salary)
FROM employees
GROUP BY department_id
HAVING COUNT(*) > 10;  -- Filter by count, show average

-- HAVING with subquery
SELECT department_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id
HAVING AVG(salary) > (
    SELECT AVG(salary) FROM employees
);
```

## Query Execution Order

Understanding the order helps write correct queries:

```sql
SELECT department_id, COUNT(*) AS emp_count     -- 5. Select columns
FROM employees                                  -- 1. From table
WHERE hire_date >= '2020-01-01'                -- 2. Filter rows
GROUP BY department_id                         -- 3. Group rows
HAVING COUNT(*) > 5                            -- 4. Filter groups
ORDER BY emp_count DESC                        -- 6. Sort results
LIMIT 10;                                      -- 7. Limit results
```

**Execution Order:**
1. FROM - Choose table
2. WHERE - Filter rows
3. GROUP BY - Group rows
4. HAVING - Filter groups
5. SELECT - Choose columns
6. ORDER BY - Sort results
7. LIMIT/OFFSET - Limit results

## Advanced Grouping

### GROUP BY with Expressions
```sql
-- Group by calculated values
SELECT
    CASE
        WHEN salary < 50000 THEN 'Low'
        WHEN salary < 100000 THEN 'Medium'
        ELSE 'High'
    END AS salary_range,
    COUNT(*) AS employee_count
FROM employees
GROUP BY
    CASE
        WHEN salary < 50000 THEN 'Low'
        WHEN salary < 100000 THEN 'Medium'
        ELSE 'High'
    END;

-- Group by year
SELECT
    EXTRACT(YEAR FROM hire_date) AS hire_year,
    COUNT(*) AS hires
FROM employees
GROUP BY EXTRACT(YEAR FROM hire_date)
ORDER BY hire_year;
```

### GROUP BY with JOINs
```sql
-- Count orders per customer
SELECT
    c.customer_name,
    COUNT(o.order_id) AS order_count,
    SUM(o.total_amount) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC;
```

### GROUP BY ALL (PostgreSQL 13+)
```sql
-- Automatically groups by all non-aggregated columns
SELECT department_id, job_title, COUNT(*)
FROM employees
GROUP BY ALL;

-- Equivalent to:
SELECT department_id, job_title, COUNT(*)
FROM employees
GROUP BY department_id, job_title;
```

## Statistical Aggregates (PostgreSQL)

### Statistical Functions
```sql
-- Standard deviation
SELECT STDDEV(salary) FROM employees;

-- Variance
SELECT VARIANCE(salary) FROM employees;

-- Correlation coefficient
SELECT CORR(years_experience, salary) FROM employees;

-- Median (PostgreSQL)
SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary)
FROM employees;
```

## String Aggregation

### STRING_AGG (PostgreSQL)
```sql
-- Concatenate values
SELECT
    department_id,
    STRING_AGG(first_name, ', ' ORDER BY first_name) AS employees
FROM employees
GROUP BY department_id;

-- Example result:
-- department_id | employees
-- 10           | Alice, Bob, Charlie
-- 20           | David, Emma, Frank
```

### ARRAY_AGG (PostgreSQL)
```sql
-- Collect values into an array
SELECT
    department_id,
    ARRAY_AGG(first_name ORDER BY first_name) AS employee_names
FROM employees
GROUP BY department_id;
```

## Common Patterns and Examples

### Top N per Group
```sql
-- Highest paid employee per department
SELECT DISTINCT ON (department_id)
    department_id,
    first_name,
    last_name,
    salary
FROM employees
ORDER BY department_id, salary DESC;

-- Alternative with window functions (covered in advanced topics)
WITH ranked AS (
    SELECT
        department_id,
        first_name,
        last_name,
        salary,
        ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rn
    FROM employees
)
SELECT department_id, first_name, last_name, salary
FROM ranked
WHERE rn = 1;
```

### Counting with Conditions
```sql
-- Count employees meeting different criteria
SELECT
    department_id,
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (WHERE salary > 50000) AS high_earners,
    COUNT(*) FILTER (WHERE hire_date >= '2020-01-01') AS recent_hires
FROM employees
GROUP BY department_id;

-- Alternative using CASE
SELECT
    department_id,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN salary > 50000 THEN 1 ELSE 0 END) AS high_earners,
    SUM(CASE WHEN hire_date >= '2020-01-01' THEN 1 ELSE 0 END) AS recent_hires
FROM employees
GROUP BY department_id;
```

### Percentage Calculations
```sql
-- Calculate percentage of total
SELECT
    department_id,
    COUNT(*) AS dept_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM employees
GROUP BY department_id;
```

### Running Totals by Group
```sql
-- Monthly sales with running total
SELECT
    DATE_TRUNC('month', order_date) AS month,
    SUM(total_amount) AS monthly_sales,
    SUM(SUM(total_amount)) OVER (ORDER BY DATE_TRUNC('month', order_date)) AS running_total
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;
```

### Aggregates with NULL Handling
```sql
-- COALESCE to handle NULL results
SELECT
    department_id,
    COALESCE(AVG(commission), 0) AS avg_commission,
    COALESCE(SUM(bonus), 0) AS total_bonus
FROM employees
GROUP BY department_id;

-- Count NULL vs non-NULL
SELECT
    department_id,
    COUNT(*) AS total_rows,
    COUNT(email) AS has_email,
    COUNT(*) - COUNT(email) AS no_email
FROM employees
GROUP BY department_id;
```

## Performance Optimization

### Indexed Columns for GROUP BY
```sql
-- Create index on frequently grouped columns
CREATE INDEX idx_employees_dept ON employees(department_id);

-- Query will be faster
SELECT department_id, COUNT(*)
FROM employees
GROUP BY department_id;
```

### Filtered Aggregates
```sql
-- More efficient than subqueries
SELECT
    department_id,
    AVG(salary) FILTER (WHERE job_title = 'Manager') AS avg_manager_salary,
    AVG(salary) FILTER (WHERE job_title = 'Developer') AS avg_developer_salary
FROM employees
GROUP BY department_id;
```

## Common Mistakes and Solutions

### Mistake 1: Forgetting GROUP BY
```sql
-- WRONG: Mixing aggregates with non-aggregated columns
SELECT department_id, COUNT(*)
FROM employees;

-- CORRECT: Include GROUP BY
SELECT department_id, COUNT(*)
FROM employees
GROUP BY department_id;
```

### Mistake 2: Using WHERE instead of HAVING
```sql
-- WRONG: Cannot use aggregate in WHERE
SELECT department_id, AVG(salary)
FROM employees
WHERE AVG(salary) > 50000  -- Error!
GROUP BY department_id;

-- CORRECT: Use HAVING
SELECT department_id, AVG(salary)
FROM employees
GROUP BY department_id
HAVING AVG(salary) > 50000;
```

### Mistake 3: NULL in Aggregates
```sql
-- Be aware: aggregates ignore NULL values
SELECT AVG(commission) FROM employees;
-- Only averages non-NULL commission values

-- Include NULLs as 0
SELECT AVG(COALESCE(commission, 0)) FROM employees;
```

## Practice Problems
Check the `problems` directory for hands-on aggregate query exercises.

## Key Takeaways
- Aggregate functions summarize multiple rows into single values
- GROUP BY groups rows with same values
- HAVING filters groups after aggregation
- WHERE filters rows before aggregation
- Every SELECT column must be in GROUP BY or an aggregate
- Aggregates ignore NULL values
- Use COALESCE to handle NULL in aggregates
- Understand query execution order for correct results

## Next Steps
Move on to [06-data-constraints](../06-data-constraints/README.md) to learn about enforcing data integrity.
