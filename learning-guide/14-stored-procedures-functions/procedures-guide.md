# 14 - Stored Procedures and Functions

## Overview
Stored procedures and functions encapsulate business logic in the database. They improve performance, maintainability, and security by centralizing code execution.

**PostgreSQL Terminology:**
- **Functions** - Return values, can be used in SELECT statements
- **Procedures** - Don't return values (PostgreSQL 11+), used for transaction control

## Creating Functions

### Basic Function Syntax
```sql
CREATE FUNCTION function_name(parameter_list)
RETURNS return_type
LANGUAGE plpgsql
AS $$
DECLARE
    -- Variable declarations
BEGIN
    -- Function body
    RETURN value;
END;
$$;
```

### Simple Function Example
```sql
-- Function to calculate discount
CREATE FUNCTION calculate_discount(price DECIMAL, discount_percent DECIMAL)
RETURNS DECIMAL
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN price * (1 - discount_percent / 100);
END;
$$;

-- Use function
SELECT calculate_discount(100, 10);  -- Returns 90
SELECT product_name, calculate_discount(price, 15) AS discounted_price
FROM products;
```

### Function with Default Parameters
```sql
CREATE FUNCTION greet(name TEXT, greeting TEXT DEFAULT 'Hello')
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN greeting || ', ' || name || '!';
END;
$$;

-- Use with default
SELECT greet('Alice');  -- Returns: Hello, Alice!

-- Override default
SELECT greet('Bob', 'Hi');  -- Returns: Hi, Bob!
```

### Function Returning Multiple Values
```sql
-- Return composite type
CREATE TYPE employee_stats AS (
    emp_count INTEGER,
    avg_salary DECIMAL,
    total_salary DECIMAL
);

CREATE FUNCTION get_department_stats(dept_id INTEGER)
RETURNS employee_stats
LANGUAGE plpgsql
AS $$
DECLARE
    result employee_stats;
BEGIN
    SELECT COUNT(*), AVG(salary), SUM(salary)
    INTO result.emp_count, result.avg_salary, result.total_salary
    FROM employees
    WHERE department_id = dept_id;

    RETURN result;
END;
$$;

-- Use function
SELECT * FROM get_department_stats(10);
```

### Function Returning Table
```sql
-- Return set of rows
CREATE FUNCTION get_high_earners(salary_threshold DECIMAL)
RETURNS TABLE(
    employee_id INTEGER,
    full_name TEXT,
    salary DECIMAL
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT e.employee_id, e.first_name || ' ' || e.last_name, e.salary
    FROM employees e
    WHERE e.salary > salary_threshold
    ORDER BY e.salary DESC;
END;
$$;

-- Use like a table
SELECT * FROM get_high_earners(100000);
```

## Function Language Options

### SQL Functions (Simplest)
```sql
-- Pure SQL, no procedural logic
CREATE FUNCTION full_name(first_name TEXT, last_name TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT first_name || ' ' || last_name;
$$;
```

### PL/pgSQL Functions (Most Common)
```sql
-- Full procedural language
CREATE FUNCTION complex_calculation(x INTEGER)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    result INTEGER;
BEGIN
    IF x > 100 THEN
        result := x * 2;
    ELSE
        result := x + 10;
    END IF;
    RETURN result;
END;
$$;
```

## Variables and Control Structures

### Variable Declaration
```sql
CREATE FUNCTION demo_variables()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    my_int INTEGER := 10;
    my_text TEXT := 'Hello';
    my_date DATE := CURRENT_DATE;
    my_record RECORD;
BEGIN
    -- Use variables
    RETURN my_text || ' ' || my_int::TEXT;
END;
$$;
```

### IF-THEN-ELSE
```sql
CREATE FUNCTION categorize_age(age INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    IF age < 18 THEN
        RETURN 'Minor';
    ELSIF age < 65 THEN
        RETURN 'Adult';
    ELSE
        RETURN 'Senior';
    END IF;
END;
$$;
```

### CASE Statement
```sql
CREATE FUNCTION grade_score(score INTEGER)
RETURNS CHAR(1)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN CASE
        WHEN score >= 90 THEN 'A'
        WHEN score >= 80 THEN 'B'
        WHEN score >= 70 THEN 'C'
        WHEN score >= 60 THEN 'D'
        ELSE 'F'
    END;
END;
$$;
```

### LOOP Structures
```sql
-- LOOP with EXIT
CREATE FUNCTION sum_to_n(n INTEGER)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    result INTEGER := 0;
    i INTEGER := 1;
BEGIN
    LOOP
        EXIT WHEN i > n;
        result := result + i;
        i := i + 1;
    END LOOP;
    RETURN result;
END;
$$;

-- WHILE LOOP
CREATE FUNCTION sum_while(n INTEGER)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    result INTEGER := 0;
    i INTEGER := 1;
BEGIN
    WHILE i <= n LOOP
        result := result + i;
        i := i + 1;
    END LOOP;
    RETURN result;
END;
$$;

-- FOR LOOP
CREATE FUNCTION sum_for(n INTEGER)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    result INTEGER := 0;
BEGIN
    FOR i IN 1..n LOOP
        result := result + i;
    END LOOP;
    RETURN result;
END;
$$;
```

### Looping Through Query Results
```sql
CREATE FUNCTION process_employees()
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    emp RECORD;
BEGIN
    FOR emp IN SELECT * FROM employees LOOP
        -- Process each employee
        RAISE NOTICE 'Employee: % %', emp.first_name, emp.last_name;
    END LOOP;
END;
$$;
```

## Error Handling

### EXCEPTION Block
```sql
CREATE FUNCTION safe_divide(numerator DECIMAL, denominator DECIMAL)
RETURNS DECIMAL
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN numerator / denominator;
EXCEPTION
    WHEN division_by_zero THEN
        RAISE NOTICE 'Cannot divide by zero';
        RETURN NULL;
    WHEN OTHERS THEN
        RAISE NOTICE 'An error occurred: %', SQLERRM;
        RETURN NULL;
END;
$$;
```

### RAISE Statements
```sql
CREATE FUNCTION check_age(age INTEGER)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    IF age < 0 THEN
        RAISE EXCEPTION 'Age cannot be negative';
    ELSIF age < 18 THEN
        RAISE WARNING 'User is a minor';
    ELSE
        RAISE NOTICE 'Age is valid: %', age;
    END IF;
END;
$$;
```

## Stored Procedures (PostgreSQL 11+)

### Creating Procedures
```sql
-- Procedures support transaction control
CREATE PROCEDURE process_orders()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Process pending orders
    UPDATE orders SET status = 'processing'
    WHERE status = 'pending';

    -- Commit within procedure
    COMMIT;

    -- Continue with more work
    UPDATE orders SET processed_at = NOW()
    WHERE status = 'processing';
END;
$$;

-- Call procedure
CALL process_orders();
```

### Procedures with Parameters
```sql
CREATE PROCEDURE update_salary(emp_id INTEGER, new_salary DECIMAL)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE employees
    SET salary = new_salary
    WHERE employee_id = emp_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Employee % not found', emp_id;
    END IF;

    COMMIT;
END;
$$;

-- Call with parameters
CALL update_salary(123, 75000);
```

### IN, OUT, INOUT Parameters
```sql
CREATE PROCEDURE calculate_stats(
    IN dept_id INTEGER,
    OUT emp_count INTEGER,
    OUT avg_salary DECIMAL
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT COUNT(*), AVG(salary)
    INTO emp_count, avg_salary
    FROM employees
    WHERE department_id = dept_id;
END;
$$;

-- Call procedure
CALL calculate_stats(10, NULL, NULL);
```

## Triggers and Trigger Functions

### Trigger Function
```sql
-- Create trigger function
CREATE FUNCTION update_modified_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- Attach trigger to table
CREATE TRIGGER update_employee_timestamp
BEFORE UPDATE ON employees
FOR EACH ROW
EXECUTE FUNCTION update_modified_timestamp();
```

### Audit Trigger
```sql
-- Audit trigger function
CREATE FUNCTION audit_employee_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO employee_audit (operation, employee_id, new_data)
        VALUES ('INSERT', NEW.employee_id, row_to_json(NEW));
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO employee_audit (operation, employee_id, old_data, new_data)
        VALUES ('UPDATE', NEW.employee_id, row_to_json(OLD), row_to_json(NEW));
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO employee_audit (operation, employee_id, old_data)
        VALUES ('DELETE', OLD.employee_id, row_to_json(OLD));
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER employee_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON employees
FOR EACH ROW EXECUTE FUNCTION audit_employee_changes();
```

### Conditional Trigger
```sql
-- Only fire trigger for specific condition
CREATE TRIGGER high_salary_audit
AFTER UPDATE ON employees
FOR EACH ROW
WHEN (NEW.salary > 150000)
EXECUTE FUNCTION log_high_salary_change();
```

## Dynamic SQL

### EXECUTE Statement
```sql
CREATE FUNCTION dynamic_query(table_name TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    row_count INTEGER;
BEGIN
    EXECUTE 'SELECT COUNT(*) FROM ' || quote_ident(table_name)
    INTO row_count;

    RETURN row_count;
END;
$$;
```

### Parameterized Dynamic SQL
```sql
CREATE FUNCTION get_employee_by_field(field_name TEXT, field_value TEXT)
RETURNS TABLE(employee_id INTEGER, first_name TEXT, last_name TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT employee_id, first_name, last_name FROM employees WHERE ' ||
        quote_ident(field_name) || ' = $1'
    USING field_value;
END;
$$;
```

## Function Modifiers

### IMMUTABLE, STABLE, VOLATILE
```sql
-- IMMUTABLE: Same input always returns same output
CREATE FUNCTION add(a INTEGER, b INTEGER)
RETURNS INTEGER
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT a + b;
$$;

-- STABLE: Same result within single statement
CREATE FUNCTION current_user_dept()
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
    SELECT department_id FROM employees WHERE user_id = current_user_id();
$$;

-- VOLATILE: Result can change (default)
CREATE FUNCTION random_number()
RETURNS DECIMAL
LANGUAGE sql
VOLATILE
AS $$
    SELECT random();
$$;
```

### STRICT
```sql
-- Return NULL if any parameter is NULL
CREATE FUNCTION multiply(a INTEGER, b INTEGER)
RETURNS INTEGER
LANGUAGE sql
STRICT
AS $$
    SELECT a * b;
$$;
```

### SECURITY DEFINER
```sql
-- Execute with privileges of function owner
CREATE FUNCTION sensitive_operation()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Runs with owner's privileges
    DELETE FROM sensitive_table;
END;
$$;
```

## Managing Functions and Procedures

### Viewing Functions
```sql
-- List all functions
\df

-- List specific function
\df+ function_name

-- Query information schema
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public';
```

### Altering Functions
```sql
-- Rename function
ALTER FUNCTION old_name() RENAME TO new_name;

-- Change owner
ALTER FUNCTION function_name() OWNER TO new_owner;

-- Change schema
ALTER FUNCTION function_name() SET SCHEMA new_schema;
```

### Dropping Functions
```sql
-- Drop function
DROP FUNCTION function_name;

-- Drop if exists
DROP FUNCTION IF EXISTS function_name;

-- Drop with parameters specified
DROP FUNCTION calculate_discount(DECIMAL, DECIMAL);

-- Drop with CASCADE
DROP FUNCTION function_name CASCADE;
```

## Best Practices

1. **Use meaningful names**
2. **Add comments**
```sql
COMMENT ON FUNCTION calculate_discount(DECIMAL, DECIMAL)
IS 'Calculates discounted price given original price and discount percentage';
```

3. **Handle NULL values**
4. **Use appropriate volatility category**
5. **Limit dynamic SQL usage** (security risk)
6. **Keep functions focused** (single responsibility)
7. **Test thoroughly**
8. **Use exception handling**

## Practice Problems
Check the `problems` directory for hands-on function and procedure exercises.

## Key Takeaways
- Functions return values, procedures don't (PostgreSQL 11+)
- PL/pgSQL provides full procedural programming
- Use functions for calculations, procedures for operations
- Triggers automate actions on data changes
- Handle errors with EXCEPTION blocks
- Use IMMUTABLE/STABLE/VOLATILE appropriately
- Dynamic SQL requires careful security consideration
- Test and document all database code

## Next Steps
Move on to [15-performance-optimization](../15-performance-optimization/README.md) to learn about database tuning.
