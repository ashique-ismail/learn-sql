# 02 - Basic SQL Syntax

## SELECT Statement Deep Dive

### Basic SELECT Syntax
```sql
SELECT column1, column2, ...
FROM table_name;
```

### SELECT All Columns
```sql
-- Select everything
SELECT * FROM employees;

-- Better practice: specify columns
SELECT employee_id, first_name, last_name, salary
FROM employees;
```

### Column Aliases
```sql
-- Using AS keyword
SELECT first_name AS fname, last_name AS lname
FROM employees;

-- Without AS (also valid)
SELECT first_name fname, last_name lname
FROM employees;

-- With spaces (use quotes)
SELECT salary AS "Annual Salary"
FROM employees;
```

### DISTINCT - Remove Duplicates
```sql
-- Get unique values
SELECT DISTINCT department_id
FROM employees;

-- Distinct combination of columns
SELECT DISTINCT department_id, job_title
FROM employees;
```

## WHERE Clause - Filtering Data

### Comparison Operators
```sql
-- Equal to
SELECT * FROM employees WHERE department_id = 10;

-- Not equal to
SELECT * FROM employees WHERE department_id != 10;
SELECT * FROM employees WHERE department_id <> 10;

-- Greater than, Less than
SELECT * FROM employees WHERE salary > 50000;
SELECT * FROM employees WHERE hire_date < '2020-01-01';

-- Greater/Less than or equal
SELECT * FROM employees WHERE salary >= 50000;
SELECT * FROM employees WHERE age <= 30;
```

### Logical Operators

#### AND - All conditions must be true
```sql
SELECT * FROM employees
WHERE department_id = 10 AND salary > 50000;

-- Multiple AND conditions
SELECT * FROM employees
WHERE age > 25 AND age < 40 AND department_id = 5;
```

#### OR - At least one condition must be true
```sql
SELECT * FROM employees
WHERE department_id = 10 OR department_id = 20;

SELECT * FROM employees
WHERE salary > 100000 OR job_title = 'Manager';
```

#### NOT - Negates a condition
```sql
SELECT * FROM employees
WHERE NOT department_id = 10;

SELECT * FROM employees
WHERE NOT (salary > 50000 AND age < 30);
```

#### Combining Operators (use parentheses for clarity)
```sql
SELECT * FROM employees
WHERE (department_id = 10 OR department_id = 20)
  AND salary > 50000;
```

### IN Operator - Match Multiple Values
```sql
-- Instead of multiple OR conditions
SELECT * FROM employees
WHERE department_id IN (10, 20, 30);

-- Equivalent to:
-- WHERE department_id = 10 OR department_id = 20 OR department_id = 30

-- With strings
SELECT * FROM employees
WHERE job_title IN ('Manager', 'Developer', 'Analyst');

-- NOT IN
SELECT * FROM employees
WHERE department_id NOT IN (10, 20, 30);
```

### BETWEEN Operator - Range Values
```sql
-- Inclusive range
SELECT * FROM employees
WHERE salary BETWEEN 50000 AND 100000;

-- Equivalent to:
-- WHERE salary >= 50000 AND salary <= 100000

-- Date ranges
SELECT * FROM employees
WHERE hire_date BETWEEN '2020-01-01' AND '2020-12-31';

-- NOT BETWEEN
SELECT * FROM employees
WHERE salary NOT BETWEEN 50000 AND 100000;
```

### LIKE Operator - Pattern Matching

#### Wildcards
- `%` - Represents zero or more characters
- `_` - Represents exactly one character

```sql
-- Starts with 'A'
SELECT * FROM employees
WHERE first_name LIKE 'A%';

-- Ends with 'son'
SELECT * FROM employees
WHERE last_name LIKE '%son';

-- Contains 'art'
SELECT * FROM employees
WHERE first_name LIKE '%art%';

-- Second character is 'a'
SELECT * FROM employees
WHERE first_name LIKE '_a%';

-- Exactly 5 characters
SELECT * FROM employees
WHERE first_name LIKE '_____';

-- NOT LIKE
SELECT * FROM employees
WHERE email NOT LIKE '%@gmail.com';
```

#### ILIKE - Case-Insensitive LIKE (PostgreSQL)
```sql
-- Case insensitive matching
SELECT * FROM employees
WHERE first_name ILIKE 'john%';
-- Matches: John, JOHN, john, JoHn
```

### IS NULL / IS NOT NULL - Check for NULL Values
```sql
-- Find NULL values
SELECT * FROM employees
WHERE middle_name IS NULL;

-- Find non-NULL values
SELECT * FROM employees
WHERE phone_number IS NOT NULL;

-- Important: Cannot use = or != with NULL
-- WRONG: WHERE middle_name = NULL
-- CORRECT: WHERE middle_name IS NULL
```

## ORDER BY - Sorting Results

### Basic Sorting
```sql
-- Ascending (default)
SELECT * FROM employees
ORDER BY last_name;

SELECT * FROM employees
ORDER BY last_name ASC;

-- Descending
SELECT * FROM employees
ORDER BY salary DESC;
```

### Multiple Column Sorting
```sql
-- Sort by department, then by salary within each department
SELECT * FROM employees
ORDER BY department_id ASC, salary DESC;

-- First name ascending, hire date descending
SELECT * FROM employees
ORDER BY first_name, hire_date DESC;
```

### Sorting with Column Aliases
```sql
SELECT first_name, salary * 12 AS annual_salary
FROM employees
ORDER BY annual_salary DESC;
```

### Sorting by Column Position (not recommended)
```sql
-- Order by the first column in SELECT
SELECT first_name, last_name, salary
FROM employees
ORDER BY 3 DESC;  -- Orders by salary (3rd column)
```

### NULL Values in Sorting
```sql
-- NULLs last (PostgreSQL)
SELECT * FROM employees
ORDER BY bonus NULLS LAST;

-- NULLs first
SELECT * FROM employees
ORDER BY bonus DESC NULLS FIRST;
```

## LIMIT and OFFSET - Result Set Control

### LIMIT - Restrict Number of Rows
```sql
-- Get first 10 rows
SELECT * FROM employees
LIMIT 10;

-- Top 5 highest paid employees
SELECT * FROM employees
ORDER BY salary DESC
LIMIT 5;
```

### OFFSET - Skip Rows
```sql
-- Skip first 10 rows
SELECT * FROM employees
OFFSET 10;

-- Get rows 11-20
SELECT * FROM employees
OFFSET 10 LIMIT 10;
```

### Pagination Pattern
```sql
-- Page 1 (rows 1-10)
SELECT * FROM employees
ORDER BY employee_id
LIMIT 10 OFFSET 0;

-- Page 2 (rows 11-20)
SELECT * FROM employees
ORDER BY employee_id
LIMIT 10 OFFSET 10;

-- Page 3 (rows 21-30)
SELECT * FROM employees
ORDER BY employee_id
LIMIT 10 OFFSET 20;

-- Formula: OFFSET = (page_number - 1) * page_size
```

### FETCH (SQL Standard Alternative to LIMIT)
```sql
-- Fetch first 10 rows
SELECT * FROM employees
FETCH FIRST 10 ROWS ONLY;

-- With OFFSET
SELECT * FROM employees
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;
```

## Basic Arithmetic Operations

### Arithmetic Operators
```sql
-- Addition
SELECT salary + 5000 AS new_salary FROM employees;

-- Subtraction
SELECT salary - tax AS net_salary FROM employees;

-- Multiplication
SELECT salary * 12 AS annual_salary FROM employees;

-- Division
SELECT salary / 12 AS monthly_salary FROM employees;

-- Modulo (remainder)
SELECT employee_id % 2 AS is_odd FROM employees;
```

### Order of Operations
```sql
-- Use parentheses for clarity
SELECT salary * 12 + bonus AS total_compensation
FROM employees;

SELECT (salary + bonus) * 12 AS total_compensation
FROM employees;
```

## String Operations

### Concatenation
```sql
-- PostgreSQL: Using ||
SELECT first_name || ' ' || last_name AS full_name
FROM employees;

-- Using CONCAT function
SELECT CONCAT(first_name, ' ', last_name) AS full_name
FROM employees;

-- CONCAT_WS (with separator)
SELECT CONCAT_WS(' ', first_name, middle_name, last_name) AS full_name
FROM employees;
```

### String Functions
```sql
-- Uppercase
SELECT UPPER(first_name) FROM employees;

-- Lowercase
SELECT LOWER(email) FROM employees;

-- Length
SELECT LENGTH(last_name) FROM employees;

-- Substring
SELECT SUBSTRING(phone_number, 1, 3) AS area_code
FROM employees;

-- Trim whitespace
SELECT TRIM(first_name) FROM employees;
```

## Comments in SQL

```sql
-- Single line comment
SELECT * FROM employees;  -- Another comment

/*
  Multi-line comment
  Can span multiple lines
*/
SELECT * FROM employees;

/* Inline comment */ SELECT * FROM employees;
```

## Best Practices

1. **Use explicit column names** instead of `SELECT *`
2. **Use meaningful aliases** for clarity
3. **Always specify ORDER BY** when order matters
4. **Use parentheses** to make complex conditions clear
5. **Format queries** for readability (indentation, line breaks)
6. **Be consistent** with naming conventions
7. **Comment complex queries** to explain logic

## Practice Problems
Check the `problems` directory for hands-on exercises to practice these SQL syntax concepts.

## Key Takeaways
- SELECT retrieves data from tables
- WHERE filters rows based on conditions
- ORDER BY sorts results
- LIMIT restricts the number of rows returned
- Operators like IN, BETWEEN, and LIKE make filtering flexible
- NULL requires special handling with IS NULL/IS NOT NULL
- Combine conditions with AND, OR, and NOT

## Next Steps
Move on to [03-data-definition-language](../03-data-definition-language/README.md) to learn about creating and modifying database structures.
