# 11 - Indexes

## Overview
Indexes are database objects that improve query performance by allowing faster data retrieval. They work like a book's index, helping the database find data without scanning entire tables.

**Benefits:**
- Dramatically faster queries
- Efficient sorting
- Unique constraint enforcement

**Costs:**
- Storage overhead
- Slower INSERT/UPDATE/DELETE
- Maintenance overhead

## Index Types

### B-Tree Index (Default)
```sql
-- Standard index for most queries
CREATE INDEX idx_employees_last_name ON employees(last_name);

-- Best for:
-- - Equality comparisons (=)
-- - Range queries (<, >, BETWEEN)
-- - LIKE 'prefix%'
-- - ORDER BY
```

### Hash Index
```sql
-- Only for equality comparisons
CREATE INDEX idx_users_email_hash ON users USING HASH (email);

-- Use when:
-- - Only = comparisons
-- - Never need range queries
-- - PostgreSQL: rarely needed, B-tree is usually better
```

### GiST and GIN Indexes (PostgreSQL)
```sql
-- GIN: Good for array, JSONB, full-text search
CREATE INDEX idx_tags_gin ON articles USING GIN (tags);
CREATE INDEX idx_data_gin ON users USING GIN (data);

-- GiST: Good for geometric data, full-text
CREATE INDEX idx_location_gist ON places USING GIST (location);
```

### Partial Index
```sql
-- Index only subset of rows
CREATE INDEX idx_active_users ON users(email)
WHERE status = 'active';

-- Benefits:
-- - Smaller index
-- - Faster queries matching condition
-- - Less maintenance
```

### Unique Index
```sql
-- Enforce uniqueness
CREATE UNIQUE INDEX idx_users_email_unique ON users(email);

-- Also created automatically by UNIQUE constraint
ALTER TABLE users ADD CONSTRAINT unique_email UNIQUE (email);
-- Creates unique index implicitly
```

### Composite Index (Multi-Column)
```sql
-- Index on multiple columns
CREATE INDEX idx_employees_dept_salary
ON employees(department_id, salary);

-- Column order matters!
-- This index helps queries:
-- - WHERE department_id = X
-- - WHERE department_id = X AND salary > Y
-- - ORDER BY department_id, salary

-- But NOT:
-- - WHERE salary > Y (salary not first column)
```

### Expression Index
```sql
-- Index on computed values
CREATE INDEX idx_lower_email ON users(LOWER(email));

-- Now this query uses the index:
SELECT * FROM users WHERE LOWER(email) = 'john@example.com';

-- Date truncation index
CREATE INDEX idx_order_date_month
ON orders(DATE_TRUNC('month', order_date));
```

## Creating Indexes

### Basic CREATE INDEX
```sql
-- Single column
CREATE INDEX idx_employees_last_name ON employees(last_name);

-- Multi-column
CREATE INDEX idx_employees_dept_salary
ON employees(department_id, salary);

-- With UNIQUE
CREATE UNIQUE INDEX idx_users_username ON users(username);
```

### CREATE INDEX Options
```sql
-- IF NOT EXISTS (PostgreSQL 9.5+)
CREATE INDEX IF NOT EXISTS idx_employees_email ON employees(email);

-- Specify method
CREATE INDEX idx_tags USING GIN ON articles(tags);

-- Concurrent creation (no table lock)
CREATE INDEX CONCURRENTLY idx_employees_hire_date
ON employees(hire_date);

-- Partial index
CREATE INDEX idx_recent_orders
ON orders(order_date)
WHERE order_date >= CURRENT_DATE - INTERVAL '90 days';
```

## When to Create Indexes

### CREATE Indexes For:
```sql
-- 1. Primary keys (automatic)
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY  -- Index created automatically
);

-- 2. Foreign keys
CREATE INDEX idx_orders_customer_id ON orders(customer_id);

-- 3. Columns in WHERE clauses
SELECT * FROM employees WHERE last_name = 'Smith';
-- Add index: CREATE INDEX idx_last_name ON employees(last_name);

-- 4. Columns in JOIN conditions
SELECT * FROM orders o JOIN customers c ON o.customer_id = c.customer_id;
-- Add index on orders.customer_id

-- 5. Columns in ORDER BY
SELECT * FROM products ORDER BY price DESC;
-- Add index: CREATE INDEX idx_products_price ON products(price);

-- 6. Frequently searched columns
CREATE INDEX idx_products_sku ON products(sku);
```

### DON'T Create Indexes For:
- Small tables (few rows)
- Columns with high update frequency and rare queries
- Columns with few distinct values (low cardinality)
- Tables with frequent INSERT/UPDATE/DELETE

## Dropping Indexes

```sql
-- Drop index
DROP INDEX idx_employees_last_name;

-- Drop if exists
DROP INDEX IF EXISTS idx_employees_last_name;

-- Concurrent drop (no table lock, PostgreSQL)
DROP INDEX CONCURRENTLY idx_employees_last_name;
```

## Analyzing Index Usage

### EXPLAIN - View Query Plan
```sql
-- See if index is used
EXPLAIN SELECT * FROM employees WHERE last_name = 'Smith';

-- Detailed analysis
EXPLAIN ANALYZE
SELECT * FROM employees WHERE last_name = 'Smith';

-- Look for:
-- - "Index Scan" (good, index used)
-- - "Seq Scan" (bad, full table scan)
```

### PostgreSQL Statistics
```sql
-- View index usage
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,  -- Number of index scans
    idx_tup_read,  -- Tuples read
    idx_tup_fetch  -- Tuples fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan;

-- Find unused indexes
SELECT
    schemaname,
    tablename,
    indexname
FROM pg_stat_user_indexes
WHERE idx_scan = 0
AND indexname NOT LIKE 'pg_toast%';
```

### Index Size
```sql
-- Size of indexes
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
ORDER BY pg_relation_size(indexrelid) DESC;
```

## Index Best Practices

### 1. Index Selectivity
```sql
-- High selectivity (good for index)
-- Email: each value unique
CREATE INDEX idx_users_email ON users(email);

-- Low selectivity (poor for index)
-- Gender: only 2-3 distinct values
-- Usually not worth indexing
```

### 2. Composite Index Column Order
```sql
-- Put most selective column first
-- If querying: WHERE country = 'USA' AND city = 'New York'
-- And country has fewer distinct values than city:
CREATE INDEX idx_location ON addresses(city, country);

-- Follow query patterns
-- Queries: WHERE dept = X AND salary > Y
CREATE INDEX idx_dept_salary ON employees(department_id, salary);
```

### 3. Covering Index
```sql
-- Include frequently selected columns
CREATE INDEX idx_orders_customer_date_amount
ON orders(customer_id, order_date, total_amount);

-- Query can use index-only scan (faster)
SELECT order_date, total_amount
FROM orders
WHERE customer_id = 123;
```

### 4. Partial Index for Common Queries
```sql
-- If 90% of queries filter by status = 'active'
CREATE INDEX idx_active_users
ON users(email)
WHERE status = 'active';

-- Much smaller than full index
```

### 5. Avoid Over-Indexing
```sql
-- BAD: Too many indexes
CREATE INDEX idx1 ON employees(last_name);
CREATE INDEX idx2 ON employees(first_name);
CREATE INDEX idx3 ON employees(last_name, first_name);
CREATE INDEX idx4 ON employees(first_name, last_name);

-- GOOD: Choose based on query patterns
CREATE INDEX idx_name ON employees(last_name, first_name);
```

## Index Maintenance

### Reindex
```sql
-- Rebuild index (removes bloat)
REINDEX INDEX idx_employees_last_name;

-- Reindex table (all indexes)
REINDEX TABLE employees;

-- Reindex concurrently (PostgreSQL 12+)
REINDEX INDEX CONCURRENTLY idx_employees_last_name;
```

### Analyze Statistics
```sql
-- Update statistics for query planner
ANALYZE employees;

-- Analyze specific table
ANALYZE employees;

-- Auto-vacuum handles this automatically in PostgreSQL
```

## Common Index Patterns

### Dates and Ranges
```sql
-- For date range queries
CREATE INDEX idx_orders_date ON orders(order_date);

-- Partial for recent data
CREATE INDEX idx_recent_orders
ON orders(order_date)
WHERE order_date >= CURRENT_DATE - INTERVAL '1 year';
```

### Case-Insensitive Search
```sql
-- Index lowercase for case-insensitive
CREATE INDEX idx_email_lower ON users(LOWER(email));

-- Query must match
SELECT * FROM users WHERE LOWER(email) = LOWER('John@Example.com');
```

### JSON Data
```sql
-- GIN index for JSONB
CREATE INDEX idx_user_data ON users USING GIN (data);

-- Specific JSON path
CREATE INDEX idx_user_city ON users((data->>'city'));
```

### Full-Text Search
```sql
-- Create tsvector column
ALTER TABLE articles ADD COLUMN search_vector tsvector;

-- Update with searchable text
UPDATE articles
SET search_vector =
    to_tsvector('english', title || ' ' || body);

-- Create GIN index
CREATE INDEX idx_articles_search ON articles USING GIN (search_vector);

-- Search query
SELECT * FROM articles
WHERE search_vector @@ to_tsquery('english', 'postgresql & index');
```

## Monitoring Performance

### Slow Queries
```sql
-- Enable slow query log (PostgreSQL config)
-- log_min_duration_statement = 1000  # Log queries taking > 1 second

-- Find missing indexes (queries not using indexes)
EXPLAIN ANALYZE <your_query>;
```

### Index Bloat
```sql
-- Find bloated indexes (need reindex)
-- Use pg_stat_user_indexes to check index efficiency
```

## Practice Problems
Check the `problems` directory for hands-on indexing exercises.

## Key Takeaways
- Indexes speed up SELECT but slow down INSERT/UPDATE/DELETE
- B-tree is the default and most common index type
- Index foreign keys for better JOIN performance
- Composite index column order matters
- Use EXPLAIN to verify index usage
- Partial indexes for common filtered queries
- Expression indexes for computed columns
- Monitor and remove unused indexes
- REINDEX to remove bloat
- Balance number of indexes vs maintenance cost

## Next Steps
Move on to [12-transactions-acid](../12-transactions-acid/README.md) to learn about data consistency and transactions.
