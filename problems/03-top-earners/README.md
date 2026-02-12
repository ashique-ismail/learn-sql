# Problem 3: Top Earners

**Difficulty:** Beginner
**Concepts:** ORDER BY, LIMIT, DESC/ASC
**Phase:** Foundations (Days 1-3)

---

## Learning Objectives

- Sort query results with ORDER BY
- Limit number of rows returned with LIMIT
- Understand ascending vs descending order

---

## Concept Summary

**ORDER BY** sorts results. **LIMIT** restricts the number of rows returned.

### Syntax

```sql
SELECT columns FROM table
ORDER BY column1 ASC, column2 DESC;

SELECT columns FROM table LIMIT n;
SELECT columns FROM table LIMIT n OFFSET m;  -- Skip m rows, return n rows
```

### Key Points

- `ASC` = Ascending (default, lowest to highest)
- `DESC` = Descending (highest to lowest)
- Can order by multiple columns
- `LIMIT` comes after ORDER BY
- `OFFSET` skips rows (useful for pagination)

---

## Problem Statement

**Task:** Find top 5 highest paid employees

---

## Hint

Sort by salary descending, then limit the results.

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

```sql
SELECT name, salary FROM employees
ORDER BY salary DESC
LIMIT 5;
```

### Explanation

1. `SELECT name, salary` - Get employee names and salaries
2. `ORDER BY salary DESC` - Sort by salary from highest to lowest
3. `LIMIT 5` - Return only the first 5 rows

### Alternative Solutions

```sql
-- Include department and email
SELECT name, department, salary, email
FROM employees
ORDER BY salary DESC
LIMIT 5;

-- See top 5 with their rank
SELECT name, salary,
    RANK() OVER (ORDER BY salary DESC) as rank
FROM employees
ORDER BY salary DESC
LIMIT 5;

-- Top 5 per department (advanced)
WITH ranked AS (
    SELECT name, department, salary,
        ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) as rn
    FROM employees
)
SELECT name, department, salary
FROM ranked
WHERE rn <= 5;
```

---

## Try These Variations

1. Find bottom 5 earners (lowest salaries)
2. Find employees 6-10 in salary ranking
3. Sort by department (alphabetically), then salary (descending)
4. Find top 3 employees in Engineering department
5. Find employees with 10th to 15th highest salaries

### Solutions to Variations

```sql
-- 1. Bottom 5 earners
SELECT name, salary FROM employees
ORDER BY salary ASC
LIMIT 5;

-- 2. Employees ranked 6-10
SELECT name, salary FROM employees
ORDER BY salary DESC
LIMIT 5 OFFSET 5;

-- 3. Sort by department, then salary
SELECT department, name, salary FROM employees
ORDER BY department ASC, salary DESC;

-- 4. Top 3 in Engineering
SELECT name, salary FROM employees
WHERE department = 'Engineering'
ORDER BY salary DESC
LIMIT 3;

-- 5. Ranks 10-15
SELECT name, salary FROM employees
ORDER BY salary DESC
LIMIT 6 OFFSET 9;  -- Skip 9, get 6 (positions 10-15)
```

---

## Sample Output

```
      name       |  salary
-----------------+----------
 Alice Johnson   | 150000.00
 Bob Smith       | 140000.00
 Carol White     | 135000.00
 David Brown     | 130000.00
 George Wright   |  98000.00
```

---

## Common Mistakes

1. **Forgetting DESC:** `ORDER BY salary` returns lowest first (ASC is default)
2. **LIMIT without ORDER BY:** Results are unpredictable without sorting
3. **Wrong OFFSET calculation:** OFFSET 5 skips first 5 rows (not 6)
4. **Ordering by wrong column:** Make sure to order by the column you're interested in

---

## Pagination Pattern

```sql
-- Page 1 (items 1-10)
SELECT * FROM employees ORDER BY id LIMIT 10 OFFSET 0;

-- Page 2 (items 11-20)
SELECT * FROM employees ORDER BY id LIMIT 10 OFFSET 10;

-- Page 3 (items 21-30)
SELECT * FROM employees ORDER BY id LIMIT 10 OFFSET 20;

-- Formula: OFFSET = (page_number - 1) * page_size
```

---

## Performance Note

- ORDER BY can be expensive on large tables
- Add index on ORDER BY columns for better performance
- `CREATE INDEX idx_employees_salary ON employees(salary);`
- LIMIT helps performance by stopping early

---

## Related Problems

- **Previous:** [Problem 2 - Filtering Data](../02-filtering-data/)
- **Next:** [Problem 4 - Department Statistics](../04-department-statistics/)
- **Related:** Problem 10 (Window Functions for ranking)

---

## Notes

```
Your notes here:




```

---

[← Previous](../02-filtering-data/) | [Back to Overview](../../README.md) | [Next Problem →](../04-department-statistics/)
