# Problem 12: Salary Update

**Difficulty:** Intermediate
**Concepts:** UPDATE statement, SET clause, Conditional updates, Data manipulation
**Phase:** Data Manipulation (Days 10-11)

---

## Learning Objectives

- Master UPDATE statement syntax
- Apply conditional updates with WHERE
- Update data based on calculations
- Understand transaction safety with updates
- Learn best practices for data modification

---

## Concept Summary

**UPDATE** modifies existing rows in a table. Always use WHERE clause to avoid updating all rows.

### Syntax

```sql
-- Basic update
UPDATE table_name
SET column1 = value1, column2 = value2
WHERE condition;

-- Update with calculation
UPDATE table_name
SET column = column * 1.10
WHERE condition;

-- Update from another table (PostgreSQL)
UPDATE table1 t1
SET column = t2.value
FROM table2 t2
WHERE t1.key = t2.key;

-- Update with subquery
UPDATE table1
SET column = (SELECT value FROM table2 WHERE table2.key = table1.key)
WHERE condition;

-- Update with CASE
UPDATE table_name
SET column = CASE
    WHEN condition1 THEN value1
    WHEN condition2 THEN value2
    ELSE current_value
END
WHERE condition;
```

---

## Problem Statement

**Task:** Give a 10% salary raise to employees in the 'Engineering' department who earn less than $80,000.

**Before running UPDATE, always:**
1. Use SELECT to preview affected rows
2. Check row count
3. Consider using transactions (BEGIN/COMMIT/ROLLBACK)

---

## Hint

Use SET with multiplication for percentage increase, and combine multiple conditions in WHERE with AND.

---

## Your Solution

```sql
-- Preview the update first
SELECT * FROM employees
WHERE department = 'Engineering' AND salary < 80000;

-- Write your UPDATE statement here




```

---

## Solution

```sql
-- Step 1: Preview affected rows
SELECT id, name, department, salary, salary * 1.10 as new_salary
FROM employees
WHERE department = 'Engineering' AND salary < 80000;

-- Step 2: Perform the update
UPDATE employees
SET salary = salary * 1.10
WHERE department = 'Engineering' AND salary < 80000;

-- Step 3: Verify the update
SELECT id, name, department, salary
FROM employees
WHERE department = 'Engineering' AND salary < 88000  -- 80000 * 1.10
ORDER BY salary;
```

### Explanation

1. Always SELECT first to see what will be updated
2. `SET salary = salary * 1.10` multiplies current salary by 1.10 (10% increase)
3. `WHERE department = 'Engineering' AND salary < 80000` targets specific employees
4. After update, verify changes with another SELECT
5. Row count returned shows number of rows affected

---

## Alternative Solutions

```sql
-- Using RETURNING clause (PostgreSQL)
UPDATE employees
SET salary = salary * 1.10
WHERE department = 'Engineering' AND salary < 80000
RETURNING id, name, salary as new_salary;

-- Update with CASE for different raises
UPDATE employees
SET salary = CASE
    WHEN department = 'Engineering' AND salary < 80000 THEN salary * 1.10
    WHEN department = 'Sales' AND salary < 60000 THEN salary * 1.15
    WHEN department = 'Marketing' THEN salary * 1.05
    ELSE salary
END;

-- Safe update with transaction
BEGIN;

UPDATE employees
SET salary = salary * 1.10
WHERE department = 'Engineering' AND salary < 80000;

-- Check the results
SELECT * FROM employees WHERE department = 'Engineering';

-- If satisfied:
COMMIT;
-- If not satisfied:
-- ROLLBACK;

-- Update from subquery
UPDATE employees
SET salary = salary * 1.10
WHERE id IN (
    SELECT id
    FROM employees
    WHERE department = 'Engineering'
      AND salary < 80000
      AND hire_date < '2023-01-01'
);

-- Update with JOIN (PostgreSQL syntax)
UPDATE employees e
SET salary = e.salary * (1 + d.bonus_rate)
FROM departments d
WHERE e.dept_id = d.id
  AND d.name = 'Engineering'
  AND e.salary < 80000;
```

---

## Try These Variations

1. Give a 5% raise to all employees earning less than department average
2. Update multiple columns: salary and bonus together
3. Cap salaries at a maximum value
4. Update based on performance rating from another table
5. Bulk update with different raises per department

### Solutions to Variations

```sql
-- 1. Raise based on department average
UPDATE employees e
SET salary = salary * 1.05
WHERE salary < (
    SELECT AVG(salary)
    FROM employees e2
    WHERE e2.department = e.department
);

-- 2. Update multiple columns
UPDATE employees
SET
    salary = salary * 1.10,
    bonus = salary * 0.10,  -- 10% bonus based on OLD salary
    last_raise_date = CURRENT_DATE
WHERE department = 'Engineering' AND salary < 80000;

-- 3. Cap salaries at maximum
UPDATE employees
SET salary = CASE
    WHEN salary > 150000 THEN 150000
    ELSE salary
END;

-- Alternative with LEAST function
UPDATE employees
SET salary = LEAST(salary, 150000);

-- 4. Update based on performance rating
UPDATE employees e
SET salary = e.salary * (1 + pr.raise_percentage)
FROM performance_ratings pr
WHERE e.id = pr.employee_id
  AND pr.year = 2023
  AND pr.rating >= 4;

-- 5. Different raises per department
UPDATE employees
SET salary = salary * CASE department
    WHEN 'Engineering' THEN 1.10
    WHEN 'Sales' THEN 1.12
    WHEN 'Marketing' THEN 1.08
    WHEN 'HR' THEN 1.06
    ELSE 1.05
END
WHERE salary < 100000;
```

---

## Sample Output

```sql
-- Before UPDATE
SELECT id, name, department, salary FROM employees
WHERE department = 'Engineering' AND salary < 80000;
```

```
 id |     name      | department  | salary
----+---------------+-------------+--------
  5 | John Smith    | Engineering | 65000
  8 | Jane Doe      | Engineering | 72000
 12 | Mike Johnson  | Engineering | 78000
(3 rows)
```

```sql
-- After UPDATE
UPDATE employees SET salary = salary * 1.10
WHERE department = 'Engineering' AND salary < 80000;
-- UPDATE 3

SELECT id, name, department, salary FROM employees
WHERE department = 'Engineering' AND id IN (5, 8, 12);
```

```
 id |     name      | department  | salary
----+---------------+-------------+--------
  5 | John Smith    | Engineering | 71500
  8 | Jane Doe      | Engineering | 79200
 12 | Mike Johnson  | Engineering | 85800
(3 rows)
```

---

## Common Mistakes

1. **Forgetting WHERE clause:** Updates ALL rows - extremely dangerous!
   ```sql
   -- DANGER: Updates entire table!
   UPDATE employees SET salary = salary * 1.10;
   ```

2. **Double-updating:** Running the same UPDATE twice doubles the change
   ```sql
   -- First run: 80000 * 1.10 = 88000
   -- Second run: 88000 * 1.10 = 96800 (NOT intended!)
   ```

3. **Using wrong comparison after update:** WHERE clause uses old values
   ```sql
   -- This finds employees who HAD salary < 80000 before update
   SELECT * FROM employees WHERE salary < 80000;
   ```

4. **Order dependency with multiple updates:**
   ```sql
   -- These are different!
   UPDATE employees SET salary = 100000 WHERE id = 1;
   UPDATE employees SET bonus = salary * 0.1 WHERE id = 1;  -- bonus = 10000

   -- vs
   UPDATE employees SET salary = 100000, bonus = salary * 0.1 WHERE id = 1;  -- uses OLD salary
   ```

5. **No backup before mass updates:** Always backup or use transactions

6. **Rounding issues with decimals:** May need to ROUND() results

---

## Safety Best Practices

### Always Follow This Pattern

```sql
-- 1. Start transaction
BEGIN;

-- 2. Preview with SELECT
SELECT id, name, salary, salary * 1.10 as new_salary
FROM employees
WHERE department = 'Engineering' AND salary < 80000;

-- 3. Count affected rows
SELECT COUNT(*) FROM employees
WHERE department = 'Engineering' AND salary < 80000;

-- 4. Perform UPDATE
UPDATE employees
SET salary = salary * 1.10
WHERE department = 'Engineering' AND salary < 80000;

-- 5. Verify results
SELECT id, name, salary FROM employees
WHERE department = 'Engineering' AND salary >= 71500;  -- Check updated range

-- 6. Commit if satisfied, rollback if not
COMMIT;
-- Or: ROLLBACK;
```

### Create Audit Trail

```sql
-- Create history table
CREATE TABLE salary_history (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER,
    old_salary DECIMAL(10,2),
    new_salary DECIMAL(10,2),
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(100)
);

-- Update with audit
BEGIN;

-- Record old values
INSERT INTO salary_history (employee_id, old_salary, new_salary, changed_by)
SELECT id, salary, salary * 1.10, CURRENT_USER
FROM employees
WHERE department = 'Engineering' AND salary < 80000;

-- Perform update
UPDATE employees
SET salary = salary * 1.10
WHERE department = 'Engineering' AND salary < 80000;

COMMIT;
```

---

## Performance Note

- UPDATE locks affected rows
- Large updates can be slow and lock tables
- Consider batch updates for very large tables
- Indexes on WHERE clause columns improve performance
- UPDATE triggers fire for each affected row

```sql
-- Batch update pattern for large tables
DO $$
DECLARE
    batch_size INTEGER := 1000;
    updated INTEGER;
BEGIN
    LOOP
        UPDATE employees
        SET salary = salary * 1.10
        WHERE id IN (
            SELECT id
            FROM employees
            WHERE department = 'Engineering'
              AND salary < 80000
            LIMIT batch_size
        );
        GET DIAGNOSTICS updated = ROW_COUNT;
        EXIT WHEN updated = 0;
        COMMIT;
    END LOOP;
END $$;
```

---

## Real-World Use Cases

1. **Annual salary adjustments:** Across entire organization
2. **Cost of living increases:** Based on location or inflation
3. **Merit increases:** Based on performance ratings
4. **Data corrections:** Fix errors in imported data
5. **Status updates:** Change order status, user status
6. **Price adjustments:** Update product prices based on market conditions

---

## Related Problems

- **Previous:** [Problem 11 - Moving Average](../11-moving-average/)
- **Next:** [Problem 13 - Library Schema Design](../13-library-schema-design/)
- **Related:** Problem 27 (Multi-Table Update), Problem 29 (Data Quality Audit)

---

## Notes

```
Your notes here:




```

---

[← Previous](../11-moving-average/) | [Back to Overview](../../README.md) | [Next Problem →](../13-library-schema-design/)
