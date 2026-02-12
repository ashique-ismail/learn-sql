# 10 - Advanced SQL Functions

## Overview
Advanced SQL functions including window functions, string functions, date/time functions, and JSON operations provide powerful data manipulation capabilities.

## Window Functions

Window functions perform calculations across sets of rows related to the current row, without collapsing rows like GROUP BY.

### ROW_NUMBER()
```sql
-- Assign unique sequential number
SELECT
    employee_id,
    first_name,
    salary,
    ROW_NUMBER() OVER (ORDER BY salary DESC) AS salary_rank
FROM employees;

-- Partition by department
SELECT
    department_id,
    first_name,
    salary,
    ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS dept_rank
FROM employees;
```

### RANK() and DENSE_RANK()
```sql
-- RANK: Gaps in ranking for ties
SELECT
    first_name,
    salary,
    RANK() OVER (ORDER BY salary DESC) AS rank
FROM employees;
-- Salaries: 100k, 100k, 90k → Ranks: 1, 1, 3

-- DENSE_RANK: No gaps
SELECT
    first_name,
    salary,
    DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_rank
FROM employees;
-- Salaries: 100k, 100k, 90k → Ranks: 1, 1, 2
```

### NTILE()
```sql
-- Divide into N buckets
SELECT
    first_name,
    salary,
    NTILE(4) OVER (ORDER BY salary) AS quartile
FROM employees;
-- Divides employees into 4 equal groups based on salary
```

### LAG() and LEAD()
```sql
-- LAG: Access previous row
SELECT
    order_date,
    total_amount,
    LAG(total_amount) OVER (ORDER BY order_date) AS previous_amount,
    total_amount - LAG(total_amount) OVER (ORDER BY order_date) AS difference
FROM orders;

-- LEAD: Access next row
SELECT
    order_date,
    total_amount,
    LEAD(total_amount) OVER (ORDER BY order_date) AS next_amount
FROM orders;

-- With default value and offset
SELECT
    order_date,
    total_amount,
    LAG(total_amount, 1, 0) OVER (ORDER BY order_date) AS prev_amount
FROM orders;
```

### FIRST_VALUE() and LAST_VALUE()
```sql
-- First value in window
SELECT
    department_id,
    first_name,
    salary,
    FIRST_VALUE(salary) OVER (
        PARTITION BY department_id
        ORDER BY salary DESC
    ) AS highest_salary_in_dept
FROM employees;

-- Last value (be careful with frame clause)
SELECT
    department_id,
    first_name,
    salary,
    LAST_VALUE(salary) OVER (
        PARTITION BY department_id
        ORDER BY salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS lowest_salary_in_dept
FROM employees;
```

### Aggregate Window Functions
```sql
-- Running total
SELECT
    order_date,
    total_amount,
    SUM(total_amount) OVER (ORDER BY order_date) AS running_total
FROM orders;

-- Moving average (last 3 rows)
SELECT
    order_date,
    total_amount,
    AVG(total_amount) OVER (
        ORDER BY order_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_3
FROM orders;

-- Cumulative count
SELECT
    product_name,
    ROW_NUMBER() OVER (ORDER BY product_name) AS row_num,
    COUNT(*) OVER (ORDER BY product_name) AS cumulative_count
FROM products;
```

### Window Frame Clauses
```sql
-- ROWS: Physical offset
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW

-- RANGE: Logical offset
RANGE BETWEEN INTERVAL '7 days' PRECEDING AND CURRENT ROW

-- Common frames
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW  -- Start to current
ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING   -- Current to end
ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING  -- All rows
```

## String Functions

### Concatenation
```sql
-- CONCAT: Join strings
SELECT CONCAT(first_name, ' ', last_name) AS full_name FROM employees;

-- || operator (PostgreSQL)
SELECT first_name || ' ' || last_name AS full_name FROM employees;

-- CONCAT_WS: With separator
SELECT CONCAT_WS(', ', last_name, first_name) AS name FROM employees;
```

### Case Conversion
```sql
SELECT
    UPPER('hello') AS uppercase,     -- 'HELLO'
    LOWER('WORLD') AS lowercase,     -- 'world'
    INITCAP('hello world') AS title; -- 'Hello World'
```

### Substring and Position
```sql
-- SUBSTRING
SELECT SUBSTRING('PostgreSQL', 1, 6);  -- 'Postgr'
SELECT SUBSTRING('PostgreSQL' FROM 7); -- 'SQL'

-- LEFT and RIGHT
SELECT LEFT('PostgreSQL', 6);   -- 'Postgr'
SELECT RIGHT('PostgreSQL', 3);  -- 'SQL'

-- POSITION
SELECT POSITION('SQL' IN 'PostgreSQL');  -- 7

-- STRPOS (PostgreSQL)
SELECT STRPOS('PostgreSQL', 'SQL');  -- 7
```

### String Modification
```sql
-- TRIM
SELECT TRIM('  hello  ');        -- 'hello'
SELECT LTRIM('  hello');         -- 'hello'
SELECT RTRIM('hello  ');         -- 'hello'

-- REPLACE
SELECT REPLACE('Hello World', 'World', 'SQL');  -- 'Hello SQL'

-- REVERSE
SELECT REVERSE('Hello');  -- 'olleH'

-- REPEAT
SELECT REPEAT('Ha', 3);  -- 'HaHaHa'
```

### Pattern Matching
```sql
-- LIKE
SELECT * FROM users WHERE email LIKE '%@gmail.com';

-- ILIKE (case-insensitive, PostgreSQL)
SELECT * FROM users WHERE email ILIKE '%@GMAIL.COM';

-- Regular expressions (PostgreSQL)
SELECT * FROM users WHERE email ~ '^[A-Z]';  -- Starts with uppercase
SELECT * FROM users WHERE email ~* '^[A-Z]'; -- Case-insensitive
```

### String Splitting (PostgreSQL)
```sql
-- SPLIT_PART
SELECT SPLIT_PART('a,b,c', ',', 2);  -- 'b'

-- STRING_TO_ARRAY
SELECT STRING_TO_ARRAY('a,b,c', ',');  -- {a,b,c}

-- REGEXP_SPLIT_TO_ARRAY
SELECT REGEXP_SPLIT_TO_ARRAY('a1b2c3', '\d+');  -- {a,b,c}
```

## Date and Time Functions

### Current Date/Time
```sql
SELECT
    CURRENT_DATE,                    -- 2024-02-12
    CURRENT_TIME,                    -- 14:30:25.123456
    CURRENT_TIMESTAMP,               -- 2024-02-12 14:30:25.123456
    NOW(),                           -- Same as CURRENT_TIMESTAMP
    CURRENT_TIME AT TIME ZONE 'UTC'; -- Convert timezone
```

### Date Extraction
```sql
SELECT
    EXTRACT(YEAR FROM CURRENT_DATE) AS year,
    EXTRACT(MONTH FROM CURRENT_DATE) AS month,
    EXTRACT(DAY FROM CURRENT_DATE) AS day,
    EXTRACT(HOUR FROM CURRENT_TIMESTAMP) AS hour,
    EXTRACT(DOW FROM CURRENT_DATE) AS day_of_week,  -- 0=Sunday
    EXTRACT(DOY FROM CURRENT_DATE) AS day_of_year,
    EXTRACT(QUARTER FROM CURRENT_DATE) AS quarter;

-- DATE_PART (PostgreSQL, same as EXTRACT)
SELECT DATE_PART('year', CURRENT_DATE);
```

### Date Arithmetic
```sql
-- Add/subtract intervals
SELECT
    CURRENT_DATE + INTERVAL '1 day' AS tomorrow,
    CURRENT_DATE - INTERVAL '1 week' AS last_week,
    CURRENT_DATE + INTERVAL '3 months' AS three_months_later,
    NOW() - INTERVAL '2 hours' AS two_hours_ago;

-- Age calculation
SELECT AGE(CURRENT_DATE, '2000-01-01');  -- "24 years 1 mon 11 days"
SELECT AGE('2000-01-01');  -- Age from date to now

-- Date difference
SELECT CURRENT_DATE - '2024-01-01'::date AS days_diff;
```

### Date Truncation
```sql
-- Truncate to specific precision
SELECT
    DATE_TRUNC('year', CURRENT_TIMESTAMP) AS start_of_year,
    DATE_TRUNC('month', CURRENT_TIMESTAMP) AS start_of_month,
    DATE_TRUNC('week', CURRENT_TIMESTAMP) AS start_of_week,
    DATE_TRUNC('day', CURRENT_TIMESTAMP) AS start_of_day,
    DATE_TRUNC('hour', CURRENT_TIMESTAMP) AS start_of_hour;
```

### Date Formatting
```sql
-- TO_CHAR: Format date as string
SELECT TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD');        -- '2024-02-12'
SELECT TO_CHAR(CURRENT_DATE, 'Month DD, YYYY');    -- 'February  12, 2024'
SELECT TO_CHAR(CURRENT_DATE, 'Day');               -- 'Monday'
SELECT TO_CHAR(NOW(), 'HH24:MI:SS');               -- '14:30:25'

-- TO_DATE: Parse string to date
SELECT TO_DATE('2024-02-12', 'YYYY-MM-DD');
SELECT TO_DATE('12/02/2024', 'DD/MM/YYYY');

-- TO_TIMESTAMP
SELECT TO_TIMESTAMP('2024-02-12 14:30:00', 'YYYY-MM-DD HH24:MI:SS');
```

## JSON Functions (PostgreSQL)

### JSON Creation
```sql
-- JSON object
SELECT JSON_BUILD_OBJECT('name', 'John', 'age', 30);
-- {"name": "John", "age": 30}

-- JSON array
SELECT JSON_BUILD_ARRAY(1, 2, 3, 'four');
-- [1, 2, 3, "four"]

-- Row to JSON
SELECT ROW_TO_JSON(employees.*) FROM employees LIMIT 1;
```

### JSON Extraction
```sql
-- Extract field (returns JSON)
SELECT data->'name' FROM users;

-- Extract text value
SELECT data->>'name' FROM users;

-- Nested extraction
SELECT data->'address'->>'city' FROM users;

-- Extract from array
SELECT data->'items'->0->>'product' FROM orders;
```

### JSONB Operations
```sql
-- JSONB is binary format, supports indexing
-- Contains operator
SELECT * FROM users WHERE data @> '{"city": "New York"}';

-- Existence operator
SELECT * FROM users WHERE data ? 'email';

-- Array contains
SELECT * FROM users WHERE data->'tags' @> '["premium"]';
```

### JSON Aggregation
```sql
-- Aggregate to JSON array
SELECT JSON_AGG(first_name) FROM employees;

-- Aggregate to JSON object
SELECT JSON_OBJECT_AGG(employee_id, first_name) FROM employees;
```

## Conditional Functions

### CASE Expression
```sql
-- Simple CASE
SELECT
    first_name,
    CASE department_id
        WHEN 10 THEN 'Sales'
        WHEN 20 THEN 'Engineering'
        WHEN 30 THEN 'HR'
        ELSE 'Other'
    END AS department_name
FROM employees;

-- Searched CASE
SELECT
    first_name,
    salary,
    CASE
        WHEN salary < 50000 THEN 'Low'
        WHEN salary < 100000 THEN 'Medium'
        ELSE 'High'
    END AS salary_range
FROM employees;
```

### COALESCE
```sql
-- Return first non-NULL value
SELECT COALESCE(phone_number, email, 'No contact') AS contact
FROM customers;

-- Replace NULL with default
SELECT product_name, COALESCE(discount, 0) AS discount
FROM products;
```

### NULLIF
```sql
-- Return NULL if values are equal
SELECT NULLIF(column1, 0);  -- Prevents division by zero

-- Example: Safe division
SELECT sales / NULLIF(quantity, 0) AS price_per_unit
FROM order_items;
```

### GREATEST and LEAST
```sql
-- Maximum value
SELECT GREATEST(10, 20, 30, 5);  -- 30

-- Minimum value
SELECT LEAST(10, 20, 30, 5);  -- 5

-- With columns
SELECT
    product_name,
    GREATEST(price, cost) AS higher_value,
    LEAST(price, cost) AS lower_value
FROM products;
```

## Mathematical Functions
```sql
-- Rounding
SELECT ROUND(123.456, 2);     -- 123.46
SELECT CEIL(123.456);         -- 124
SELECT FLOOR(123.456);        -- 123
SELECT TRUNC(123.456, 1);     -- 123.4

-- Absolute value
SELECT ABS(-123);             -- 123

-- Power and square root
SELECT POWER(2, 3);           -- 8
SELECT SQRT(16);              -- 4

-- Trigonometric
SELECT SIN(0), COS(0), TAN(0);

-- Random
SELECT RANDOM();              -- 0 to 1
SELECT FLOOR(RANDOM() * 100); -- 0 to 99
```

## Conversion Functions
```sql
-- Type casting
SELECT CAST('123' AS INTEGER);
SELECT '123'::INTEGER;  -- PostgreSQL syntax

SELECT CAST(123.45 AS INTEGER);  -- 123

-- TO_NUMBER
SELECT TO_NUMBER('123.45', '999.99');
```

## Practice Problems
Check the `problems` directory for hands-on advanced function exercises.

## Key Takeaways
- Window functions enable advanced analytics without GROUP BY
- ROW_NUMBER, RANK, DENSE_RANK for ranking
- LAG/LEAD for accessing adjacent rows
- String functions for text manipulation
- Date functions for temporal operations
- JSON functions for semi-structured data
- CASE for conditional logic
- COALESCE for NULL handling
- Window frames control calculation scope

## Next Steps
Move on to [11-indexes](../11-indexes/README.md) to learn about query optimization.
