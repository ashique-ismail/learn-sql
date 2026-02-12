# Problem 2: Filtering Data

**Difficulty:** Beginner
**Concepts:** WHERE clause, Comparison operators, Logical operators
**Phase:** Foundations (Days 1-3)

---

## Learning Objectives

- Use WHERE clause to filter rows
- Apply comparison operators (=, !=, <, >, <=, >=)
- Combine conditions with AND/OR

---

## Concept Summary

**WHERE** filters rows based on conditions. Only rows matching the condition are returned.

### Syntax

```sql
SELECT columns FROM table WHERE condition;

-- Operators: =, !=, <, >, <=, >=, BETWEEN, IN, LIKE, IS NULL
```

### Examples

```sql
-- Single condition
WHERE salary > 50000

-- Multiple conditions (AND)
WHERE salary > 50000 AND department = 'Engineering'

-- Multiple conditions (OR)
WHERE department = 'Sales' OR department = 'Marketing'

-- Range
WHERE salary BETWEEN 50000 AND 100000

-- List
WHERE department IN ('Sales', 'Marketing', 'Engineering')

-- Pattern matching
WHERE name LIKE 'A%'  -- Starts with A

-- NULL check
WHERE manager_id IS NULL
```

---

## Problem Statement

**Given table:** `employees(id, name, salary, department)`

**Task:** Find employees with salary > 50000 in 'Engineering' department

---

## Hint

Combine multiple conditions with AND operator.

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

```sql
SELECT * FROM employees
WHERE salary > 50000 AND department = 'Engineering';
```

### Explanation

1. `WHERE salary > 50000` - First condition filters employees earning more than 50000
2. `AND department = 'Engineering'` - Second condition filters for Engineering department
3. Both conditions must be true for a row to be included

### Alternative Solutions

```sql
-- Select specific columns instead of *
SELECT name, salary, department
FROM employees
WHERE salary > 50000 AND department = 'Engineering';

-- Using comparison and equality
SELECT id, name, email, salary
FROM employees
WHERE department = 'Engineering'
  AND salary > 50000
ORDER BY salary DESC;
```

---

## Try These Variations

1. Find employees in Sales OR Marketing
2. Find employees with salary BETWEEN 60000 AND 90000
3. Find employees in Engineering with salary >= 80000
4. Find employees NOT in Engineering department
5. Find employees with names starting with 'A'

### Solutions to Variations

```sql
-- 1. Sales OR Marketing
SELECT name, department FROM employees
WHERE department IN ('Sales', 'Marketing');

-- 2. Salary range
SELECT name, salary FROM employees
WHERE salary BETWEEN 60000 AND 90000;

-- 3. Engineering with high salary
SELECT name, salary FROM employees
WHERE department = 'Engineering' AND salary >= 80000;

-- 4. Not in Engineering
SELECT name, department FROM employees
WHERE department != 'Engineering';
-- OR
WHERE department <> 'Engineering';
-- OR
WHERE NOT (department = 'Engineering');

-- 5. Names starting with 'A'
SELECT name FROM employees
WHERE name LIKE 'A%';
```

---

## Sample Output

```
 id |    name     |         email          | salary  | department
----+-------------+------------------------+---------+-------------
  5 | Emma Davis  | emma.d@company.com     | 95000   | Engineering
  6 | Frank Miller| frank.m@company.com    | 88000   | Engineering
  7 | Grace Lee   | grace.l@company.com    | 92000   | Engineering
  8 | Henry Wilson| henry.w@company.com    | 85000   | Engineering
  9 | Ivy Chen    | ivy.c@company.com      | 90000   | Engineering
 11 | Kate Anderson| kate.a@company.com    | 82000   | Engineering
 12 | Liam Martinez| liam.m@company.com    | 75000   | Engineering
```

---

## Common Mistakes

1. **Using single = instead of comparing:** `WHERE salary = 50000` (this checks equality, not greater than)
2. **Forgetting quotes around strings:** `WHERE department = Engineering` (should be `'Engineering'`)
3. **Using OR when AND is needed:** Multiple conditions usually need AND
4. **Case sensitivity:** Depends on database (PostgreSQL is case-sensitive for strings)

---

## Related Problems

- **Previous:** [Problem 1 - Basic Selection](../01-basic-selection/)
- **Next:** [Problem 3 - Top Earners](../03-top-earners/)
- **Related:** Problem 16 (Complex filtering with EXISTS)

---

## Performance Note

When filtering large tables:
- Indexes on WHERE clause columns improve performance
- Filter as early as possible in the query
- More selective conditions (filtering more rows) should come first

---

## Notes

```
Your notes here:




```

---

[← Previous](../01-basic-selection/) | [Back to Overview](../../README.md) | [Next Problem →](../03-top-earners/)
