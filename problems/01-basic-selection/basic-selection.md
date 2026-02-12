# Problem 1: Basic Selection

**Difficulty:** Beginner
**Concepts:** SELECT, FROM
**Phase:** Foundations (Days 1-3)

---

## Learning Objectives

- Understand the SELECT statement
- Learn to retrieve specific columns from a table
- Practice basic query syntax

---

## Concept Summary

**SELECT** retrieves data from tables. It's the foundation of all SQL queries.

### Syntax

```sql
SELECT column1, column2 FROM table_name;
SELECT * FROM table_name;  -- All columns
```

---

## Problem Statement

**Given table:** `employees(id, name, salary, department)`

**Task:** Get all employee names and salaries

---

## Hint

Use SELECT with specific column names instead of `SELECT *`.

---

## Your Solution

Try to solve the problem before looking at the solution below!

```sql
-- Write your solution here




```

---

## Solution

```sql
SELECT name, salary FROM employees;
```

### Explanation

1. `SELECT name, salary` - Specifies which columns we want to retrieve
2. `FROM employees` - Specifies which table to query
3. This returns two columns for all rows in the employees table

---

## Try These Variations

1. Select only the name column
2. Select name, department, and salary (in that order)
3. Use `SELECT *` to see all columns
4. Select salary and name (reverse order)

---

## Sample Output

```
       name        | salary
-------------------+---------
 Alice Johnson     | 150000
 Bob Smith         | 140000
 Carol White       | 135000
 David Brown       | 130000
 Emma Davis        | 95000
 ...
```

---

## Related Problems

- **Next:** [Problem 2 - Filtering Data](../02-filtering-data/)
- **Related:** Problem 4 (Aggregate Functions)

---

## Notes

```
Your notes here:




```

---

[← Back to Overview](../../README.md) | [Next Problem →](../02-filtering-data/)
