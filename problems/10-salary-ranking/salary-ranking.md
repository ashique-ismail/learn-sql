# Problem 10: Salary Ranking

**Difficulty:** Intermediate
**Concepts:** Window functions, PARTITION BY, Ranking functions, Running totals
**Phase:** Advanced Querying (Days 7-9)

---

## Learning Objectives

- Master window functions for advanced analytics
- Use PARTITION BY to create groups within queries
- Apply ranking functions (ROW_NUMBER, RANK, DENSE_RANK)
- Calculate running totals and moving aggregates
- Understand when window functions outperform GROUP BY

---

## Concept Summary

**Window functions** perform calculations across rows related to the current row without collapsing results (unlike GROUP BY).

### Syntax

```sql
-- Basic syntax
function_name() OVER (
    PARTITION BY column1    -- Optional: divide into groups
    ORDER BY column2        -- Optional: order within partition
    ROWS/RANGE clause       -- Optional: define window frame
)

-- Common window functions
ROW_NUMBER()    -- Sequential number for each row
RANK()          -- Rank with gaps for ties
DENSE_RANK()    -- Rank without gaps
NTILE(n)        -- Divide rows into n buckets
LAG(col, n)     -- Access previous row value
LEAD(col, n)    -- Access next row value
FIRST_VALUE()   -- First value in window
LAST_VALUE()    -- Last value in window

-- Aggregate functions as window functions
SUM() OVER(), AVG() OVER(), COUNT() OVER(), etc.
```

### Window Functions vs GROUP BY

| Window Functions | GROUP BY |
|-----------------|----------|
| Keep all rows | Collapse to one row per group |
| Can use other columns | Limited to grouped/aggregated columns |
| More flexible | Simpler for basic aggregation |
| Can rank, lag, lead | Cannot access other rows |

---

## Problem Statement

**Task:** Rank employees by salary within each department. Show running total of salaries in each department.

---

## Hint

Use RANK() with PARTITION BY for department ranking, and SUM() OVER for running total.

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

```sql
SELECT
    name,
    department,
    salary,
    RANK() OVER (PARTITION BY department ORDER BY salary DESC) as dept_rank,
    SUM(salary) OVER (PARTITION BY department ORDER BY salary DESC) as running_total
FROM employees
ORDER BY department, dept_rank;
```

### Explanation

1. `RANK() OVER (...)` - Assigns rank within each partition
2. `PARTITION BY department` - Creates separate ranking for each department
3. `ORDER BY salary DESC` - Ranks by salary from highest to lowest
4. `SUM(salary) OVER (...)` - Calculates running total
5. The running total accumulates as we go down the ordered rows
6. All columns from employees table remain in output (no grouping collapse)

### Alternative Solutions

```sql
-- Using different ranking functions
SELECT
    name,
    department,
    salary,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) as row_num,
    RANK() OVER (PARTITION BY department ORDER BY salary DESC) as rank,
    DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) as dense_rank,
    NTILE(4) OVER (PARTITION BY department ORDER BY salary DESC) as quartile
FROM employees
ORDER BY department, salary DESC;

-- With additional analytics
SELECT
    name,
    department,
    salary,
    RANK() OVER (PARTITION BY department ORDER BY salary DESC) as dept_rank,
    SUM(salary) OVER (PARTITION BY department ORDER BY salary DESC) as running_total,
    AVG(salary) OVER (PARTITION BY department) as dept_avg,
    salary - AVG(salary) OVER (PARTITION BY department) as diff_from_avg,
    COUNT(*) OVER (PARTITION BY department) as dept_size
FROM employees
ORDER BY department, salary DESC;
```

---

## Try These Variations

1. Find top 3 earners in each department
2. Show each employee's salary with previous and next employee's salary
3. Calculate percentage of department's total salary for each employee
4. Find employees in the bottom 25% of their department
5. Show running average instead of running total

### Solutions to Variations

```sql
-- 1. Top 3 per department
SELECT name, department, salary, dept_rank
FROM (
    SELECT
        name,
        department,
        salary,
        RANK() OVER (PARTITION BY department ORDER BY salary DESC) as dept_rank
    FROM employees
) ranked
WHERE dept_rank <= 3;

-- 2. Previous and next salary
SELECT
    name,
    department,
    salary,
    LAG(salary) OVER (PARTITION BY department ORDER BY salary) as prev_salary,
    LEAD(salary) OVER (PARTITION BY department ORDER BY salary) as next_salary,
    salary - LAG(salary) OVER (PARTITION BY department ORDER BY salary) as diff_from_prev
FROM employees
ORDER BY department, salary;

-- 3. Percentage of department total
SELECT
    name,
    department,
    salary,
    SUM(salary) OVER (PARTITION BY department) as dept_total,
    ROUND(
        salary * 100.0 / SUM(salary) OVER (PARTITION BY department),
        2
    ) as pct_of_dept_total
FROM employees
ORDER BY department, salary DESC;

-- 4. Bottom 25% (quartile 4)
SELECT name, department, salary, quartile
FROM (
    SELECT
        name,
        department,
        salary,
        NTILE(4) OVER (PARTITION BY department ORDER BY salary DESC) as quartile
    FROM employees
) q
WHERE quartile = 4;

-- 5. Running average
SELECT
    name,
    department,
    salary,
    ROUND(AVG(salary) OVER (
        PARTITION BY department
        ORDER BY salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) as running_avg
FROM employees
ORDER BY department, salary DESC;
```

---

## Sample Output

```
      name       |  department  | salary  | dept_rank | running_total
-----------------+--------------+---------+-----------+---------------
 Emma Davis      | Engineering  |  95000  |     1     |      95000
 Grace Lee       | Engineering  |  92000  |     2     |     187000
 Henry Wilson    | Engineering  |  90000  |     3     |     277000
 Frank Miller    | Engineering  |  88000  |     4     |     365000
 Kate Anderson   | Engineering  |  85000  |     5     |     450000
 Alice Johnson   | Executive    | 150000  |     1     |     150000
 Bob Smith       | Executive    | 140000  |     2     |     290000
 Carol White     | Executive    | 135000  |     3     |     425000
```

---

## Common Mistakes

1. **Forgetting ORDER BY in window:** `RANK() OVER (PARTITION BY dept)` produces meaningless ranks
2. **Using PARTITION BY without OVER:** PARTITION BY only works with window functions
3. **Confusing RANK, DENSE_RANK, ROW_NUMBER:**
   - ROW_NUMBER: 1,2,3,4,5 (always unique)
   - RANK: 1,2,2,4,5 (gaps after ties)
   - DENSE_RANK: 1,2,2,3,4 (no gaps)
4. **Frame clause misunderstanding:** Default frame for running total is correct, but can be confusing
5. **Performance:** Window functions can be expensive on very large datasets

---

## Ranking Functions Comparison

```sql
SELECT
    name,
    salary,
    ROW_NUMBER() OVER (ORDER BY salary DESC) as row_num,
    RANK() OVER (ORDER BY salary DESC) as rank,
    DENSE_RANK() OVER (ORDER BY salary DESC) as dense_rank
FROM employees
ORDER BY salary DESC;
```

Example output with ties:
```
    name     | salary | row_num | rank | dense_rank
-------------+--------+---------+------+------------
 Alice       | 100000 |    1    |  1   |     1
 Bob         |  95000 |    2    |  2   |     2
 Carol       |  95000 |    3    |  2   |     2
 Dave        |  90000 |    4    |  4   |     3
```

---

## Window Frame Clauses

```sql
-- Default frame for SUM
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW

-- All rows in partition
ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING

-- Moving average (current + 2 preceding rows)
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW

-- Centered window (1 before, current, 1 after)
ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
```

Example:
```sql
SELECT
    name,
    salary,
    -- 3-row moving average
    AVG(salary) OVER (
        ORDER BY name
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) as moving_avg_3
FROM employees;
```

---

## Performance Note

- Window functions can be expensive on large datasets
- Indexes on PARTITION BY and ORDER BY columns help
- Multiple window functions with same WINDOW clause are optimized together
- Consider materialized views for frequently-run window queries

```sql
-- Reuse window definition
SELECT
    name,
    salary,
    RANK() OVER w as rank,
    SUM(salary) OVER w as running_total
FROM employees
WINDOW w AS (PARTITION BY department ORDER BY salary DESC);
```

---

## Real-World Use Cases

1. **Leaderboards:** Ranking users by score
2. **Sales analytics:** Running totals, moving averages
3. **Financial analysis:** Year-over-year comparisons with LAG
4. **Time series:** Previous/next values for trend analysis
5. **Percentile analysis:** Quartiles, deciles with NTILE

---

## Related Problems

- **Previous:** [Problem 9 - Department Analysis](../09-department-analysis/)
- **Next:** [Problem 11 - Moving Average](../11-moving-average/)
- **Related:** Problem 11 (Window Frames), Problem 22 (DISTINCT ON), Problem 26 (Statistical Functions)

---

## Notes

```
Your notes here:




```

---

[← Previous](../09-department-analysis/) | [Back to Overview](../../README.md) | [Next Problem →](../11-moving-average/)
