# Problem 6: Employee Department Details

**Difficulty:** Beginner
**Concepts:** JOINs (INNER, LEFT, RIGHT, FULL OUTER), Combining tables
**Phase:** Intermediate Queries (Days 4-6)

---

## Learning Objectives

- Understand different types of JOINs
- Combine data from multiple tables
- Choose the appropriate JOIN type for the task
- Use table aliases for cleaner queries

---

## Concept Summary

**JOINs** combine rows from two or more tables based on related columns.

### Syntax

```sql
-- INNER JOIN: Returns matching rows from both tables
SELECT columns FROM table1
INNER JOIN table2 ON table1.key = table2.key;

-- LEFT JOIN: All from left table + matching from right
SELECT columns FROM table1
LEFT JOIN table2 ON table1.key = table2.key;

-- RIGHT JOIN: All from right table + matching from left
SELECT columns FROM table1
RIGHT JOIN table2 ON table1.key = table2.key;

-- FULL OUTER JOIN: All rows from both tables
SELECT columns FROM table1
FULL OUTER JOIN table2 ON table1.key = table2.key;

-- CROSS JOIN: Cartesian product (all combinations)
SELECT columns FROM table1 CROSS JOIN table2;
```

### JOIN Types Visual Guide

```
Table A          Table B
-------          -------
  1                1
  2                3
  3                5

INNER JOIN: 1, 3 (matching only)
LEFT JOIN:  1, 2, 3 (all from A)
RIGHT JOIN: 1, 3, 5 (all from B)
FULL OUTER: 1, 2, 3, 5 (all from both)
```

---

## Problem Statement

**Given tables:**
- `employees(id, name, dept_id, salary)`
- `departments(id, dept_name, location)`

**Task:** List all employees with their department name and location. Include employees without departments.

---

## Hint

Use LEFT JOIN to include all employees, even those without a department assigned.

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

```sql
SELECT e.name, d.dept_name, d.location
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.id;
```

### Explanation

1. `FROM employees e` - Start with employees table (use alias 'e')
2. `LEFT JOIN departments d` - Join departments table (alias 'd')
3. `ON e.dept_id = d.id` - Match on foreign key relationship
4. LEFT JOIN ensures all employees are included, even if dept_id is NULL
5. `e.name, d.dept_name, d.location` - Select columns with table aliases

### Alternative Solutions

```sql
-- Show more details including salary
SELECT
    e.id,
    e.name,
    e.salary,
    d.dept_name,
    d.location
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.id
ORDER BY d.dept_name, e.name;

-- Highlight employees without departments
SELECT
    e.name,
    COALESCE(d.dept_name, 'No Department') as department,
    COALESCE(d.location, 'N/A') as location
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.id;

-- INNER JOIN version (only employees WITH departments)
SELECT e.name, d.dept_name, d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.id;
```

---

## Try These Variations

1. Show only employees who DO have a department (INNER JOIN)
2. Show only employees who DON'T have a department
3. Count employees per department (including departments with 0 employees)
4. Show department with total salary per department
5. Find departments with no employees assigned

### Solutions to Variations

```sql
-- 1. Only employees with departments
SELECT e.name, d.dept_name, d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.id;

-- 2. Only employees without departments
SELECT e.name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.id
WHERE d.id IS NULL;

-- 3. Employees per department (including empty departments)
SELECT
    d.dept_name,
    COUNT(e.id) as employee_count
FROM departments d
LEFT JOIN employees e ON d.id = e.dept_id
GROUP BY d.dept_name
ORDER BY employee_count DESC;

-- 4. Total salary per department
SELECT
    d.dept_name,
    COUNT(e.id) as employees,
    COALESCE(SUM(e.salary), 0) as total_payroll,
    COALESCE(ROUND(AVG(e.salary), 2), 0) as avg_salary
FROM departments d
LEFT JOIN employees e ON d.id = e.dept_id
GROUP BY d.dept_name;

-- 5. Departments with no employees
SELECT d.dept_name, d.location
FROM departments d
LEFT JOIN employees e ON d.id = e.dept_id
WHERE e.id IS NULL;
```

---

## Sample Output

```
      name       |   dept_name   |    location
-----------------+---------------+----------------
 Alice Johnson   | Executive     | New York
 Bob Smith       | Executive     | New York
 Carol White     | Executive     | New York
 David Brown     | Finance       | Chicago
 Emma Davis      | Engineering   | San Francisco
 Frank Miller    | Engineering   | San Francisco
 Grace Lee       | Engineering   | San Francisco
 John Newcomer   | NULL          | NULL
(Shows all employees, even those without departments)
```

---

## Common Mistakes

1. **Wrong JOIN type:** Using INNER JOIN when LEFT JOIN is needed (loses unmatched rows)
2. **Forgetting table aliases:** Can cause ambiguous column errors
3. **Wrong JOIN condition:** Joining on wrong columns produces incorrect results
4. **Column ambiguity:** Not specifying table alias when column exists in both tables
5. **NULL handling:** Forgetting that outer joins can produce NULL values

---

## JOIN Type Decision Tree

```
Do you want all rows from the left table?
├─ YES: Use LEFT JOIN
│   └─ Do you also want unmatched rows from right table?
│       ├─ YES: Use FULL OUTER JOIN
│       └─ NO: Use LEFT JOIN
└─ NO: Do you want only matching rows?
    ├─ YES: Use INNER JOIN
    └─ NO: Do you want all rows from right table?
        └─ YES: Use RIGHT JOIN
```

---

## Performance Note

- JOINs can be expensive on large tables
- Always index foreign key columns
- INNER JOIN is typically fastest (fewer rows)
- LEFT JOIN is slower than INNER JOIN
- Consider query order - put smaller table first when possible

```sql
-- Create indexes for better JOIN performance
CREATE INDEX idx_employees_dept_id ON employees(dept_id);
CREATE INDEX idx_departments_id ON departments(id);
```

---

## Multiple JOINs Example

```sql
-- Joining three tables
SELECT
    e.name as employee,
    d.dept_name as department,
    p.project_name as project
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.id
LEFT JOIN projects p ON e.id = p.employee_id
ORDER BY e.name;
```

---

## Related Problems

- **Previous:** [Problem 5 - Large Departments](../05-large-departments/)
- **Next:** [Problem 7 - Employee Manager Hierarchy](../07-employee-manager-hierarchy/)
- **Related:** Problem 19 (Complex Join Challenge), Problem 20 (E-commerce Analytics)

---

## Notes

```
Your notes here:




```

---

[← Previous](../05-large-departments/) | [Back to Overview](../../README.md) | [Next Problem →](../07-employee-manager-hierarchy/)
