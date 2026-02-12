# 04 - DML (Data Manipulation Language)

## Overview
DML (Data Manipulation Language) statements are used to manipulate data within database tables. These are the most commonly used SQL commands in day-to-day operations.

**Main DML Commands:**
- `SELECT` - Retrieve data from tables
- `INSERT` - Add new rows to tables
- `UPDATE` - Modify existing rows
- `DELETE` - Remove rows from tables

## INSERT - Adding Data

### INSERT Single Row
```sql
-- Basic syntax
INSERT INTO table_name (column1, column2, column3)
VALUES (value1, value2, value3);

-- Example
INSERT INTO employees (first_name, last_name, email, hire_date, salary)
VALUES ('John', 'Doe', 'john.doe@example.com', '2024-01-15', 75000);
```

### INSERT Without Column Names
```sql
-- Must provide values for ALL columns in order
INSERT INTO employees
VALUES (1, 'John', 'Doe', 'john.doe@example.com', '2024-01-15', 75000);
```

### INSERT Multiple Rows
```sql
INSERT INTO employees (first_name, last_name, email, hire_date, salary)
VALUES
    ('John', 'Doe', 'john.doe@example.com', '2024-01-15', 75000),
    ('Jane', 'Smith', 'jane.smith@example.com', '2024-01-16', 80000),
    ('Bob', 'Johnson', 'bob.johnson@example.com', '2024-01-17', 70000);
```

### INSERT with DEFAULT Values
```sql
-- Use DEFAULT keyword
INSERT INTO products (product_name, price, stock_quantity)
VALUES ('Laptop', 999.99, DEFAULT);  -- stock_quantity uses default value

-- Omit columns with defaults
INSERT INTO products (product_name, price)
VALUES ('Mouse', 19.99);  -- stock_quantity gets default value
```

### INSERT with RETURNING (PostgreSQL)
```sql
-- Return inserted data
INSERT INTO employees (first_name, last_name, email)
VALUES ('Alice', 'Williams', 'alice@example.com')
RETURNING employee_id, first_name, last_name;

-- Return all columns
INSERT INTO employees (first_name, last_name, email)
VALUES ('Bob', 'Brown', 'bob@example.com')
RETURNING *;

-- Return computed values
INSERT INTO orders (customer_id, total_amount)
VALUES (101, 1500.00)
RETURNING order_id, total_amount * 0.9 AS discounted_amount;
```

### INSERT from SELECT (Copy Data)
```sql
-- Insert data from another table
INSERT INTO archive_employees (employee_id, first_name, last_name)
SELECT employee_id, first_name, last_name
FROM employees
WHERE hire_date < '2010-01-01';

-- Insert with calculations
INSERT INTO employee_bonuses (employee_id, bonus_amount)
SELECT employee_id, salary * 0.1
FROM employees
WHERE performance_rating = 'Excellent';
```

### INSERT ... ON CONFLICT (Upsert - PostgreSQL)
```sql
-- Do nothing if conflict
INSERT INTO users (user_id, username, email)
VALUES (1, 'johndoe', 'john@example.com')
ON CONFLICT (user_id) DO NOTHING;

-- Update on conflict
INSERT INTO users (user_id, username, email, updated_at)
VALUES (1, 'johndoe', 'john@example.com', CURRENT_TIMESTAMP)
ON CONFLICT (user_id)
DO UPDATE SET
    username = EXCLUDED.username,
    email = EXCLUDED.email,
    updated_at = EXCLUDED.updated_at;

-- Conditional update on conflict
INSERT INTO inventory (product_id, quantity)
VALUES (101, 50)
ON CONFLICT (product_id)
DO UPDATE SET
    quantity = inventory.quantity + EXCLUDED.quantity
WHERE inventory.quantity < 100;
```

## UPDATE - Modifying Data

### UPDATE Single Column
```sql
-- Basic syntax
UPDATE table_name
SET column1 = value1
WHERE condition;

-- Example
UPDATE employees
SET salary = 80000
WHERE employee_id = 1;
```

### UPDATE Multiple Columns
```sql
UPDATE employees
SET
    salary = 85000,
    department_id = 5,
    updated_at = CURRENT_TIMESTAMP
WHERE employee_id = 1;
```

### UPDATE with Calculations
```sql
-- Increase salary by 10%
UPDATE employees
SET salary = salary * 1.10
WHERE department_id = 3;

-- Decrease price by $5
UPDATE products
SET price = price - 5
WHERE category = 'Electronics';
```

### UPDATE with Subquery
```sql
-- Update based on another table
UPDATE employees
SET department_id = (
    SELECT department_id
    FROM departments
    WHERE department_name = 'Engineering'
)
WHERE job_title = 'Software Engineer';

-- Update with aggregate
UPDATE products
SET average_rating = (
    SELECT AVG(rating)
    FROM reviews
    WHERE reviews.product_id = products.product_id
);
```

### UPDATE with JOIN (PostgreSQL)
```sql
-- Update using FROM clause
UPDATE employees e
SET salary = salary * 1.15
FROM departments d
WHERE e.department_id = d.department_id
  AND d.department_name = 'Sales';
```

### UPDATE with RETURNING
```sql
-- Return updated rows
UPDATE employees
SET salary = salary * 1.10
WHERE department_id = 5
RETURNING employee_id, first_name, salary;
```

### UPDATE All Rows (Be Careful!)
```sql
-- Updates EVERY row in the table
UPDATE products
SET is_active = TRUE;

-- Always verify with SELECT first!
SELECT * FROM products WHERE is_active = FALSE;
```

## DELETE - Removing Data

### DELETE Specific Rows
```sql
-- Basic syntax
DELETE FROM table_name
WHERE condition;

-- Example
DELETE FROM employees
WHERE employee_id = 1;
```

### DELETE with Multiple Conditions
```sql
DELETE FROM employees
WHERE department_id = 10
  AND hire_date < '2010-01-01';

DELETE FROM products
WHERE stock_quantity = 0
  OR is_discontinued = TRUE;
```

### DELETE with Subquery
```sql
-- Delete based on another table
DELETE FROM order_items
WHERE order_id IN (
    SELECT order_id
    FROM orders
    WHERE status = 'cancelled'
);

-- Delete with NOT EXISTS
DELETE FROM products p
WHERE NOT EXISTS (
    SELECT 1
    FROM order_items oi
    WHERE oi.product_id = p.product_id
);
```

### DELETE with RETURNING
```sql
-- Return deleted rows
DELETE FROM employees
WHERE department_id = 10
RETURNING employee_id, first_name, last_name;

-- Archive before deleting
WITH deleted AS (
    DELETE FROM old_records
    WHERE created_at < '2020-01-01'
    RETURNING *
)
INSERT INTO archive_records
SELECT * FROM deleted;
```

### DELETE All Rows (Be Careful!)
```sql
-- Deletes EVERY row in the table
DELETE FROM temporary_data;

-- TRUNCATE is faster for this purpose
TRUNCATE TABLE temporary_data;
```

### DELETE with JOIN (PostgreSQL)
```sql
-- Delete using USING clause
DELETE FROM employees e
USING departments d
WHERE e.department_id = d.department_id
  AND d.is_closed = TRUE;
```

## Advanced DML Patterns

### Bulk Insert Optimization
```sql
-- Use multi-row INSERT
INSERT INTO logs (user_id, action, timestamp)
VALUES
    (1, 'login', CURRENT_TIMESTAMP),
    (2, 'logout', CURRENT_TIMESTAMP),
    (3, 'purchase', CURRENT_TIMESTAMP);
-- Much faster than 3 separate INSERT statements

-- Use COPY for very large datasets (PostgreSQL CLI)
\copy users FROM '/path/to/users.csv' WITH CSV HEADER;
```

### Conditional INSERT (INSERT if not exists)
```sql
-- Using NOT EXISTS
INSERT INTO users (username, email)
SELECT 'johndoe', 'john@example.com'
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE username = 'johndoe'
);

-- Using ON CONFLICT (PostgreSQL)
INSERT INTO users (username, email)
VALUES ('johndoe', 'john@example.com')
ON CONFLICT (username) DO NOTHING;
```

### Conditional UPDATE
```sql
-- Update only if condition met
UPDATE products
SET price = price * 0.9
WHERE category = 'Electronics'
  AND stock_quantity > 10;

-- Update with CASE
UPDATE employees
SET bonus = CASE
    WHEN salary < 50000 THEN salary * 0.10
    WHEN salary < 100000 THEN salary * 0.08
    ELSE salary * 0.05
END;
```

### Swap Values
```sql
-- Swap using CASE
UPDATE employees
SET status = CASE
    WHEN status = 'active' THEN 'inactive'
    WHEN status = 'inactive' THEN 'active'
    ELSE status
END;
```

### Safe DELETE Pattern
```sql
-- 1. Always SELECT first to verify
SELECT * FROM employees
WHERE hire_date < '2010-01-01';

-- 2. Verify count
SELECT COUNT(*) FROM employees
WHERE hire_date < '2010-01-01';

-- 3. Begin transaction
BEGIN;

-- 4. Delete
DELETE FROM employees
WHERE hire_date < '2010-01-01';

-- 5. Verify result
SELECT COUNT(*) FROM employees;

-- 6. Commit or rollback
COMMIT;  -- or ROLLBACK; if something is wrong
```

### Soft Delete Pattern
```sql
-- Instead of DELETE, mark as deleted
ALTER TABLE employees
ADD COLUMN deleted_at TIMESTAMP NULL;

-- "Delete" by setting timestamp
UPDATE employees
SET deleted_at = CURRENT_TIMESTAMP
WHERE employee_id = 1;

-- Query active records only
SELECT * FROM employees
WHERE deleted_at IS NULL;

-- Create view for convenience
CREATE VIEW active_employees AS
SELECT * FROM employees
WHERE deleted_at IS NULL;
```

### Audit Trail Pattern
```sql
-- Create audit table
CREATE TABLE employee_audit (
    audit_id SERIAL PRIMARY KEY,
    employee_id INTEGER,
    operation VARCHAR(10),
    old_salary DECIMAL(10,2),
    new_salary DECIMAL(10,2),
    changed_by VARCHAR(100),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Update with audit
BEGIN;

INSERT INTO employee_audit (employee_id, operation, old_salary, new_salary)
SELECT employee_id, 'UPDATE', salary, salary * 1.10
FROM employees
WHERE employee_id = 1;

UPDATE employees
SET salary = salary * 1.10
WHERE employee_id = 1;

COMMIT;
```

## Common Pitfalls and Best Practices

### Always Use WHERE Clause
```sql
-- DANGER: Updates all rows!
UPDATE employees SET salary = 50000;

-- SAFE: Updates specific rows
UPDATE employees SET salary = 50000 WHERE employee_id = 1;
```

### Test with SELECT First
```sql
-- First: SELECT to see what will be affected
SELECT * FROM employees WHERE department_id = 10;

-- Then: UPDATE or DELETE
DELETE FROM employees WHERE department_id = 10;
```

### Use Transactions for Safety
```sql
BEGIN;

UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;

-- Verify changes
SELECT * FROM accounts WHERE account_id IN (1, 2);

-- If correct: COMMIT, if wrong: ROLLBACK
COMMIT;
```

### Avoid Cartesian Products in UPDATE/DELETE
```sql
-- WRONG: Can cause unintended updates
UPDATE employees e
SET salary = d.budget
FROM departments d;

-- CORRECT: Include JOIN condition
UPDATE employees e
SET salary = d.budget
FROM departments d
WHERE e.department_id = d.department_id;
```

### Use RETURNING for Verification
```sql
-- Know exactly what was changed
UPDATE employees
SET salary = salary * 1.10
WHERE department_id = 5
RETURNING employee_id, first_name, salary;
```

### Batch Large Operations
```sql
-- Instead of updating 1 million rows at once
UPDATE huge_table SET status = 'processed';

-- Update in batches
DO $$
BEGIN
    LOOP
        UPDATE huge_table
        SET status = 'processed'
        WHERE id IN (
            SELECT id FROM huge_table
            WHERE status != 'processed'
            LIMIT 10000
        );

        EXIT WHEN NOT FOUND;
        COMMIT;
    END LOOP;
END $$;
```

## Performance Tips

1. **Use batch inserts** instead of multiple single inserts
2. **Disable indexes temporarily** for bulk inserts
3. **Use COPY** for very large data imports
4. **Add WHERE clause** to limit UPDATE/DELETE scope
5. **Use transactions** to group related operations
6. **Index foreign key columns** used in JOINs
7. **Analyze query plans** with EXPLAIN for slow queries

## Practice Problems
Check the `problems` directory for hands-on DML exercises.

## Key Takeaways
- INSERT adds new data to tables
- UPDATE modifies existing data
- DELETE removes data from tables
- Always use WHERE clause unless you intend to affect all rows
- Test with SELECT before UPDATE/DELETE
- Use transactions for safety
- RETURNING clause shows affected rows
- Consider soft deletes for important data
- Batch large operations for better performance

## Next Steps
Move on to [05-aggregate-queries](../05-aggregate-queries/README.md) to learn about summarizing and analyzing data.
