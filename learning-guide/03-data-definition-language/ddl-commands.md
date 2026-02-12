# 03 - DDL (Data Definition Language)

## Overview
DDL (Data Definition Language) statements are used to define and manage database structures. These commands create, modify, and delete database objects like tables, schemas, and indexes.

**Main DDL Commands:**
- `CREATE` - Create new database objects
- `ALTER` - Modify existing database objects
- `DROP` - Delete database objects
- `TRUNCATE` - Remove all data from a table
- `RENAME` - Rename database objects

## CREATE - Creating Database Objects

### CREATE DATABASE
```sql
-- Create a new database
CREATE DATABASE company;

-- With specific encoding
CREATE DATABASE company
    ENCODING 'UTF8'
    LC_COLLATE 'en_US.UTF-8'
    LC_CTYPE 'en_US.UTF-8';

-- Check if exists (PostgreSQL 9.1+)
CREATE DATABASE IF NOT EXISTS company;
```

### CREATE SCHEMA
```sql
-- Create a schema (namespace for tables)
CREATE SCHEMA sales;

-- Create schema with authorization
CREATE SCHEMA sales AUTHORIZATION admin_user;

-- Create table in specific schema
CREATE TABLE sales.orders (
    order_id SERIAL PRIMARY KEY
);
```

### CREATE TABLE - Basic Syntax
```sql
CREATE TABLE table_name (
    column1 datatype constraints,
    column2 datatype constraints,
    ...
    table_constraints
);
```

### CREATE TABLE - Examples

#### Simple Table
```sql
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    hire_date DATE,
    salary DECIMAL(10, 2)
);
```

#### Table with Multiple Constraints
```sql
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    price DECIMAL(10, 2) NOT NULL CHECK (price > 0),
    stock_quantity INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Table with Foreign Keys
```sql
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(12, 2),
    status VARCHAR(20) DEFAULT 'pending',
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
```

#### Composite Primary Key
```sql
CREATE TABLE order_items (
    order_id INTEGER,
    product_id INTEGER,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
```

### CREATE TABLE - Special Options

#### CREATE TABLE IF NOT EXISTS
```sql
CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL
);
```

#### CREATE TABLE AS (CTAS)
```sql
-- Create table from query result
CREATE TABLE high_earners AS
SELECT employee_id, first_name, last_name, salary
FROM employees
WHERE salary > 100000;

-- With specific column names
CREATE TABLE employee_summary (emp_id, full_name, annual_salary) AS
SELECT employee_id, first_name || ' ' || last_name, salary * 12
FROM employees;
```

#### CREATE TEMPORARY TABLE
```sql
-- Table exists only for the session
CREATE TEMPORARY TABLE temp_results (
    id SERIAL PRIMARY KEY,
    result_value TEXT
);

-- Or use TEMP
CREATE TEMP TABLE session_data (
    session_id VARCHAR(100),
    data JSONB
);
```

## ALTER - Modifying Database Objects

### ALTER TABLE - Add Column
```sql
-- Add single column
ALTER TABLE employees
ADD COLUMN phone_number VARCHAR(15);

-- Add column with constraints
ALTER TABLE employees
ADD COLUMN department_id INTEGER NOT NULL DEFAULT 1;

-- Add multiple columns
ALTER TABLE employees
ADD COLUMN middle_name VARCHAR(50),
ADD COLUMN birth_date DATE;
```

### ALTER TABLE - Drop Column
```sql
-- Drop single column
ALTER TABLE employees
DROP COLUMN middle_name;

-- Drop if exists
ALTER TABLE employees
DROP COLUMN IF EXISTS middle_name;

-- Drop multiple columns
ALTER TABLE employees
DROP COLUMN phone_number,
DROP COLUMN birth_date;

-- Drop with cascade (removes dependent objects)
ALTER TABLE employees
DROP COLUMN department_id CASCADE;
```

### ALTER TABLE - Modify Column

#### Change Data Type
```sql
-- Change column type
ALTER TABLE employees
ALTER COLUMN salary TYPE NUMERIC(12, 2);

-- With USING clause for conversion
ALTER TABLE employees
ALTER COLUMN hire_date TYPE TIMESTAMP
USING hire_date::TIMESTAMP;

-- Change to larger VARCHAR
ALTER TABLE employees
ALTER COLUMN email TYPE VARCHAR(150);
```

#### Set/Drop Default Value
```sql
-- Set default value
ALTER TABLE employees
ALTER COLUMN status SET DEFAULT 'active';

-- Drop default value
ALTER TABLE employees
ALTER COLUMN status DROP DEFAULT;
```

#### Set/Drop NOT NULL
```sql
-- Add NOT NULL constraint
ALTER TABLE employees
ALTER COLUMN email SET NOT NULL;

-- Remove NOT NULL constraint
ALTER TABLE employees
ALTER COLUMN email DROP NOT NULL;
```

### ALTER TABLE - Rename
```sql
-- Rename column
ALTER TABLE employees
RENAME COLUMN phone_number TO contact_number;

-- Rename table
ALTER TABLE employees
RENAME TO staff;
```

### ALTER TABLE - Constraints

#### Add Constraints
```sql
-- Add primary key
ALTER TABLE employees
ADD PRIMARY KEY (employee_id);

-- Add foreign key
ALTER TABLE orders
ADD FOREIGN KEY (customer_id) REFERENCES customers(customer_id);

-- Add foreign key with name
ALTER TABLE orders
ADD CONSTRAINT fk_customer
FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
ON DELETE CASCADE;

-- Add unique constraint
ALTER TABLE employees
ADD CONSTRAINT unique_email UNIQUE (email);

-- Add check constraint
ALTER TABLE products
ADD CONSTRAINT positive_price CHECK (price > 0);

-- Add unique constraint on multiple columns
ALTER TABLE users
ADD CONSTRAINT unique_username_email UNIQUE (username, email);
```

#### Drop Constraints
```sql
-- Drop constraint by name
ALTER TABLE employees
DROP CONSTRAINT unique_email;

-- Drop primary key
ALTER TABLE employees
DROP CONSTRAINT employees_pkey;

-- Drop foreign key
ALTER TABLE orders
DROP CONSTRAINT fk_customer;
```

## DROP - Deleting Database Objects

### DROP DATABASE
```sql
-- Drop database
DROP DATABASE company;

-- Drop if exists
DROP DATABASE IF EXISTS company;
```

### DROP TABLE
```sql
-- Drop single table
DROP TABLE employees;

-- Drop if exists
DROP TABLE IF EXISTS employees;

-- Drop multiple tables
DROP TABLE employees, departments, locations;

-- Drop with CASCADE (removes dependent objects)
DROP TABLE employees CASCADE;

-- Drop with RESTRICT (fails if dependencies exist)
DROP TABLE employees RESTRICT;
```

### DROP SCHEMA
```sql
-- Drop empty schema
DROP SCHEMA sales;

-- Drop schema and all objects
DROP SCHEMA sales CASCADE;
```

## TRUNCATE - Remove All Data

```sql
-- Remove all rows (faster than DELETE)
TRUNCATE TABLE employees;

-- Truncate multiple tables
TRUNCATE TABLE employees, departments;

-- Reset identity columns
TRUNCATE TABLE employees RESTART IDENTITY;

-- With CASCADE (truncate referencing tables)
TRUNCATE TABLE customers CASCADE;
```

**TRUNCATE vs DELETE:**
- `TRUNCATE` is faster (doesn't scan rows)
- `TRUNCATE` cannot have WHERE clause
- `TRUNCATE` cannot be rolled back in some databases
- `TRUNCATE` resets auto-increment counters
- `DELETE` logs each row deletion

## Data Types Reference

### Numeric Types
```sql
-- Integers
SMALLINT        -- 2 bytes (-32768 to 32767)
INTEGER / INT   -- 4 bytes (-2147483648 to 2147483647)
BIGINT          -- 8 bytes (very large range)
SERIAL          -- Auto-incrementing INTEGER
BIGSERIAL       -- Auto-incrementing BIGINT

-- Decimal
DECIMAL(p, s)   -- Exact decimal, p=precision, s=scale
NUMERIC(p, s)   -- Same as DECIMAL
MONEY           -- Currency amount

-- Floating-point
REAL            -- 4 bytes, 6 decimal digits precision
DOUBLE PRECISION -- 8 bytes, 15 decimal digits precision
```

### Character Types
```sql
CHAR(n)         -- Fixed-length, padded
VARCHAR(n)      -- Variable-length, max n
TEXT            -- Unlimited length
```

### Date/Time Types
```sql
DATE            -- Date only (year, month, day)
TIME            -- Time only (hour, minute, second)
TIMESTAMP       -- Date and time
TIMESTAMPTZ     -- Timestamp with timezone
INTERVAL        -- Time span
```

### Boolean
```sql
BOOLEAN         -- TRUE, FALSE, NULL
```

### Binary Data
```sql
BYTEA           -- Binary data
```

### JSON Types (PostgreSQL)
```sql
JSON            -- Text JSON, exact storage
JSONB           -- Binary JSON, processed (recommended)
```

### Arrays (PostgreSQL)
```sql
INTEGER[]       -- Array of integers
TEXT[]          -- Array of text
```

### UUID
```sql
UUID            -- Universally unique identifier
```

## Common Patterns and Best Practices

### Standard Table Template
```sql
CREATE TABLE table_name (
    id SERIAL PRIMARY KEY,
    -- Business columns
    name VARCHAR(100) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'active',
    -- Audit columns
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER REFERENCES users(user_id),
    updated_by INTEGER REFERENCES users(user_id)
);
```

### Naming Conventions
```sql
-- Tables: plural nouns, lowercase with underscores
CREATE TABLE customer_orders (
    -- Columns: lowercase with underscores
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER,
    -- Booleans: is_, has_, can_
    is_paid BOOLEAN DEFAULT FALSE,
    has_shipped BOOLEAN DEFAULT FALSE,
    -- Dates: _at suffix
    created_at TIMESTAMP,
    shipped_at TIMESTAMP,
    -- Foreign keys: referenced_table_id
    product_id INTEGER REFERENCES products(product_id)
);
```

### Safe Schema Changes
```sql
-- 1. Add column as nullable first
ALTER TABLE employees ADD COLUMN department_id INTEGER;

-- 2. Populate the column
UPDATE employees SET department_id = 1 WHERE department_id IS NULL;

-- 3. Make it NOT NULL
ALTER TABLE employees ALTER COLUMN department_id SET NOT NULL;

-- 4. Add foreign key
ALTER TABLE employees
ADD CONSTRAINT fk_department
FOREIGN KEY (department_id) REFERENCES departments(department_id);
```

## Practice Problems
Check the `problems` directory for hands-on DDL exercises.

## Key Takeaways
- DDL defines database structure (CREATE, ALTER, DROP)
- Use appropriate data types for efficiency and accuracy
- Constraints enforce data integrity
- Always use IF EXISTS/IF NOT EXISTS for safe operations
- TRUNCATE is faster than DELETE for removing all rows
- Follow naming conventions for maintainability
- Use CASCADE carefully - it can delete related data

## Next Steps
Move on to [04-data-manipulation-language](../04-data-manipulation-language/README.md) to learn about manipulating data within tables.
