# 01 - Learn the Basics

## Introduction to Databases and SQL

### What is a Database?
A database is an organized collection of structured data stored electronically. It allows for efficient storage, retrieval, and management of information.

**Key Concepts:**
- **Data**: Raw facts and figures (e.g., names, numbers, dates)
- **Information**: Processed data that has meaning
- **Database Management System (DBMS)**: Software that manages databases (e.g., PostgreSQL, MySQL, Oracle)

### What is SQL?
SQL (Structured Query Language) is the standard language for managing and manipulating relational databases.

**SQL Categories:**
1. **DDL (Data Definition Language)**: CREATE, ALTER, DROP
2. **DML (Data Manipulation Language)**: SELECT, INSERT, UPDATE, DELETE
3. **DCL (Data Control Language)**: GRANT, REVOKE
4. **TCL (Transaction Control Language)**: COMMIT, ROLLBACK, SAVEPOINT

### Relational Database Concepts

#### Tables
Tables are the fundamental structure in relational databases, consisting of rows and columns.

```sql
-- Example: A simple users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50),
    email VARCHAR(100),
    created_at TIMESTAMP
);
```

#### Rows and Columns
- **Rows (Records/Tuples)**: Individual entries in a table
- **Columns (Fields/Attributes)**: Properties of the data

#### Primary Keys
A unique identifier for each row in a table.

```sql
-- Primary key examples
id SERIAL PRIMARY KEY
user_id INTEGER PRIMARY KEY
email VARCHAR(100) PRIMARY KEY
```

#### Foreign Keys
A field that links to the primary key of another table, establishing relationships.

```sql
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    order_date DATE
);
```

### Database Relationships

#### One-to-One (1:1)
One record in Table A relates to exactly one record in Table B.

```sql
-- User and Profile (one user has one profile)
CREATE TABLE profiles (
    profile_id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE REFERENCES users(id),
    bio TEXT
);
```

#### One-to-Many (1:N)
One record in Table A relates to multiple records in Table B.

```sql
-- User and Orders (one user can have many orders)
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id)
);
```

#### Many-to-Many (M:N)
Multiple records in Table A relate to multiple records in Table B (requires a junction table).

```sql
-- Students and Courses (many students take many courses)
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    course_name VARCHAR(100)
);

CREATE TABLE enrollments (
    student_id INTEGER REFERENCES students(student_id),
    course_id INTEGER REFERENCES courses(course_id),
    PRIMARY KEY (student_id, course_id)
);
```

### Data Types

#### Numeric Types
- `INTEGER` / `INT`: Whole numbers
- `BIGINT`: Large integers
- `DECIMAL(p,s)` / `NUMERIC(p,s)`: Fixed-point numbers
- `REAL` / `FLOAT`: Floating-point numbers

#### Character Types
- `CHAR(n)`: Fixed-length string
- `VARCHAR(n)`: Variable-length string
- `TEXT`: Unlimited length string

#### Date/Time Types
- `DATE`: Calendar date (year, month, day)
- `TIME`: Time of day
- `TIMESTAMP`: Date and time
- `INTERVAL`: Time span

#### Boolean Type
- `BOOLEAN`: TRUE, FALSE, or NULL

#### Other Common Types
- `JSON` / `JSONB`: JSON data
- `UUID`: Universally unique identifier
- `ARRAY`: Array of values

### Basic SQL Commands

#### SELECT - Retrieve Data
```sql
-- Select all columns
SELECT * FROM users;

-- Select specific columns
SELECT username, email FROM users;

-- Select with alias
SELECT username AS user_name FROM users;
```

#### WHERE - Filter Data
```sql
-- Basic filtering
SELECT * FROM users WHERE id = 1;

-- Multiple conditions
SELECT * FROM users WHERE age > 18 AND country = 'USA';
```

#### ORDER BY - Sort Results
```sql
-- Ascending order (default)
SELECT * FROM users ORDER BY username;

-- Descending order
SELECT * FROM users ORDER BY created_at DESC;

-- Multiple columns
SELECT * FROM users ORDER BY country, username;
```

#### LIMIT - Restrict Results
```sql
-- Get first 10 rows
SELECT * FROM users LIMIT 10;

-- Skip first 5, get next 10
SELECT * FROM users OFFSET 5 LIMIT 10;
```

### Practice Problems
Check the `problems` directory for hands-on exercises to reinforce these concepts.

### Key Takeaways
- Databases organize data into tables with rows and columns
- SQL is the language for interacting with relational databases
- Primary keys uniquely identify records
- Foreign keys establish relationships between tables
- Understanding data types is crucial for proper database design
- Basic SELECT queries form the foundation of data retrieval

### Next Steps
Move on to [02-basic-sql-syntax](../02-basic-sql-syntax/README.md) to dive deeper into SQL query syntax.
