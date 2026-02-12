# 06 - Data Constraints

## Overview
Constraints enforce rules on data in tables to ensure data integrity and accuracy. They prevent invalid data from being entered into the database.

**Main Constraint Types:**
- `PRIMARY KEY` - Uniquely identifies each row
- `FOREIGN KEY` - Links tables and enforces referential integrity
- `UNIQUE` - Ensures all values in a column are different
- `NOT NULL` - Ensures a column cannot have NULL values
- `CHECK` - Ensures values meet a specific condition
- `DEFAULT` - Provides a default value for a column

## NOT NULL Constraint

### Creating NOT NULL Columns
```sql
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(15)  -- NULL allowed
);

-- Cannot insert NULL into NOT NULL column
INSERT INTO users (user_id, phone) VALUES (1, '555-1234');
-- Error: username and email cannot be NULL
```

### Adding/Removing NOT NULL
```sql
-- Add NOT NULL to existing column
ALTER TABLE users
ALTER COLUMN phone SET NOT NULL;

-- Remove NOT NULL
ALTER TABLE users
ALTER COLUMN phone DROP NOT NULL;
```

## UNIQUE Constraint

### Creating UNIQUE Columns
```sql
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE,
    email VARCHAR(100) UNIQUE NOT NULL,
    ssn VARCHAR(11) UNIQUE
);

-- Cannot insert duplicate values
INSERT INTO users (username, email) VALUES ('john', 'john@example.com');
INSERT INTO users (username, email) VALUES ('john', 'jane@example.com');
-- Error: username 'john' already exists

-- NULL values are allowed (multiple NULLs OK)
INSERT INTO users (username, email, ssn) VALUES ('alice', 'alice@example.com', NULL);
INSERT INTO users (username, email, ssn) VALUES ('bob', 'bob@example.com', NULL);
-- OK: Multiple NULL values allowed in UNIQUE column
```

### Named UNIQUE Constraints
```sql
-- Name the constraint
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50),
    email VARCHAR(100),
    CONSTRAINT unique_username UNIQUE (username),
    CONSTRAINT unique_email UNIQUE (email)
);

-- Composite UNIQUE (combination must be unique)
CREATE TABLE enrollments (
    student_id INTEGER,
    course_id INTEGER,
    semester VARCHAR(20),
    CONSTRAINT unique_enrollment UNIQUE (student_id, course_id, semester)
);
```

### Adding/Removing UNIQUE
```sql
-- Add UNIQUE constraint
ALTER TABLE users
ADD CONSTRAINT unique_username UNIQUE (username);

-- Drop UNIQUE constraint
ALTER TABLE users
DROP CONSTRAINT unique_username;
```

## PRIMARY KEY Constraint

### Creating PRIMARY KEY
```sql
-- Single column primary key
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50)
);

-- Alternative syntax
CREATE TABLE employees (
    employee_id INTEGER,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    PRIMARY KEY (employee_id)
);

-- Named primary key
CREATE TABLE employees (
    employee_id INTEGER,
    first_name VARCHAR(50),
    CONSTRAINT pk_employees PRIMARY KEY (employee_id)
);
```

### Composite PRIMARY KEY
```sql
-- Multiple columns form the primary key
CREATE TABLE order_items (
    order_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    PRIMARY KEY (order_id, product_id)
);

-- Each combination of order_id and product_id must be unique
```

### PRIMARY KEY Properties
- **UNIQUE**: No duplicate values
- **NOT NULL**: Cannot be NULL
- **One per table**: Only one primary key per table
- **Indexed**: Automatically creates an index

### Adding/Removing PRIMARY KEY
```sql
-- Add primary key (column must have no NULLs or duplicates)
ALTER TABLE employees
ADD PRIMARY KEY (employee_id);

-- Drop primary key
ALTER TABLE employees
DROP CONSTRAINT employees_pkey;
```

## FOREIGN KEY Constraint

### Creating FOREIGN KEY
```sql
-- Reference another table
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100)
);

CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    department_id INTEGER,
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- Named foreign key
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    department_id INTEGER,
    CONSTRAINT fk_department
        FOREIGN KEY (department_id)
        REFERENCES departments(department_id)
);
```

### Referential Actions

#### ON DELETE Actions
```sql
-- CASCADE: Delete related rows
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE CASCADE
);
-- Deleting a customer deletes all their orders

-- SET NULL: Set foreign key to NULL
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE SET NULL
);
-- Deleting a customer sets customer_id to NULL

-- SET DEFAULT: Set foreign key to default value
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER DEFAULT 1,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE SET DEFAULT
);

-- RESTRICT / NO ACTION: Prevent deletion (default)
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE RESTRICT
);
-- Cannot delete customer if they have orders
```

#### ON UPDATE Actions
```sql
-- CASCADE: Update related rows
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON UPDATE CASCADE
);
-- Updating customer_id updates all related orders

-- SET NULL, SET DEFAULT, RESTRICT also available
```

### Composite FOREIGN KEY
```sql
CREATE TABLE order_item_reviews (
    review_id SERIAL PRIMARY KEY,
    order_id INTEGER,
    product_id INTEGER,
    rating INTEGER,
    FOREIGN KEY (order_id, product_id)
        REFERENCES order_items(order_id, product_id)
);
```

### Self-Referencing FOREIGN KEY
```sql
-- Employees table with manager reference
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    manager_id INTEGER,
    FOREIGN KEY (manager_id) REFERENCES employees(employee_id)
);
```

### Adding/Removing FOREIGN KEY
```sql
-- Add foreign key
ALTER TABLE employees
ADD CONSTRAINT fk_department
FOREIGN KEY (department_id) REFERENCES departments(department_id)
ON DELETE CASCADE;

-- Drop foreign key
ALTER TABLE employees
DROP CONSTRAINT fk_department;
```

## CHECK Constraint

### Creating CHECK Constraints
```sql
-- Simple check
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    price DECIMAL(10,2) CHECK (price > 0),
    stock_quantity INTEGER CHECK (stock_quantity >= 0)
);

-- Named check constraint
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    salary DECIMAL(10,2),
    age INTEGER,
    CONSTRAINT positive_salary CHECK (salary > 0),
    CONSTRAINT valid_age CHECK (age >= 18 AND age <= 100)
);
```

### Complex CHECK Constraints
```sql
-- Multiple conditions
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    order_date DATE,
    ship_date DATE,
    status VARCHAR(20),
    CONSTRAINT valid_dates CHECK (ship_date >= order_date),
    CONSTRAINT valid_status CHECK (status IN ('pending', 'shipped', 'delivered', 'cancelled'))
);

-- Check with multiple columns
CREATE TABLE discounts (
    discount_id SERIAL PRIMARY KEY,
    discount_percent DECIMAL(5,2),
    discount_amount DECIMAL(10,2),
    CONSTRAINT check_discount CHECK (
        (discount_percent IS NOT NULL AND discount_amount IS NULL) OR
        (discount_percent IS NULL AND discount_amount IS NOT NULL)
    )
);
```

### Adding/Removing CHECK
```sql
-- Add CHECK constraint
ALTER TABLE products
ADD CONSTRAINT positive_price CHECK (price > 0);

-- Drop CHECK constraint
ALTER TABLE products
DROP CONSTRAINT positive_price;

-- PostgreSQL: Disable/Enable constraints (not supported for CHECK)
-- Must drop and recreate
```

## DEFAULT Constraint

### Creating DEFAULT Values
```sql
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending',
    is_paid BOOLEAN DEFAULT FALSE,
    quantity INTEGER DEFAULT 1
);

-- Using functions as default
CREATE TABLE logs (
    log_id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT NOW(),
    created_date DATE DEFAULT CURRENT_DATE
);
```

### Default with Expressions
```sql
-- PostgreSQL specific
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    hire_date DATE DEFAULT CURRENT_DATE,
    probation_end DATE DEFAULT CURRENT_DATE + INTERVAL '90 days'
);
```

### Adding/Removing DEFAULT
```sql
-- Add default
ALTER TABLE orders
ALTER COLUMN status SET DEFAULT 'pending';

-- Remove default
ALTER TABLE orders
ALTER COLUMN status DROP DEFAULT;

-- Change default
ALTER TABLE orders
ALTER COLUMN status SET DEFAULT 'new';
```

## Constraint Best Practices

### Naming Conventions
```sql
-- Clear naming helps with maintenance
CREATE TABLE orders (
    order_id SERIAL,
    customer_id INTEGER,
    order_date DATE,
    total DECIMAL(10,2),

    -- Primary key: pk_tablename
    CONSTRAINT pk_orders PRIMARY KEY (order_id),

    -- Foreign key: fk_tablename_referenced
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    -- Check: ck_tablename_column
    CONSTRAINT ck_orders_total CHECK (total >= 0),

    -- Unique: uq_tablename_column
    CONSTRAINT uq_orders_confirmation UNIQUE (confirmation_number)
);
```

### Constraint Validation
```sql
-- Check existing data before adding constraint
SELECT * FROM products WHERE price <= 0;

-- If data is invalid, fix it first
UPDATE products SET price = 0.01 WHERE price <= 0;

-- Then add constraint
ALTER TABLE products
ADD CONSTRAINT positive_price CHECK (price > 0);
```

### Deferred Constraints (PostgreSQL)
```sql
-- Constraint checked at transaction end, not immediately
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    manager_id INTEGER,
    CONSTRAINT fk_manager
        FOREIGN KEY (manager_id)
        REFERENCES employees(employee_id)
        DEFERRABLE INITIALLY DEFERRED
);

-- Useful for circular references or complex updates
BEGIN;
INSERT INTO employees VALUES (1, 2);  -- References employee 2 (doesn't exist yet)
INSERT INTO employees VALUES (2, 1);  -- References employee 1
COMMIT;  -- Both constraints checked here
```

## Viewing Constraints

### PostgreSQL Information Schema
```sql
-- View all constraints
SELECT
    constraint_name,
    table_name,
    constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'public';

-- View foreign keys
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu
    ON tc.constraint_name = ccu.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY';
```

## Common Patterns

### Audit Columns
```sql
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price > 0),

    -- Audit columns with defaults
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by INTEGER REFERENCES users(user_id),
    updated_by INTEGER REFERENCES users(user_id)
);
```

### Status/Enum Columns
```sql
-- Use CHECK for status validation
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    status VARCHAR(20) DEFAULT 'pending' NOT NULL
        CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

-- PostgreSQL: Use ENUM type
CREATE TYPE order_status AS ENUM ('pending', 'processing', 'shipped', 'delivered', 'cancelled');

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    status order_status DEFAULT 'pending' NOT NULL
);
```

## Practice Problems
Check the `problems` directory for hands-on constraint exercises.

## Key Takeaways
- Constraints enforce data integrity rules
- NOT NULL prevents NULL values
- UNIQUE ensures no duplicates
- PRIMARY KEY combines UNIQUE and NOT NULL
- FOREIGN KEY maintains referential integrity
- CHECK validates data against conditions
- DEFAULT provides automatic values
- Always name your constraints for easier maintenance
- Consider referential actions (CASCADE, SET NULL, etc.)
- Validate existing data before adding constraints

## Next Steps
Move on to [07-views](../07-views/README.md) to learn about creating virtual tables.
