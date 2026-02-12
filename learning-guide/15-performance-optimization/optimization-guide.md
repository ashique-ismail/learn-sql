# 15 - Performance Optimization

## Overview
Database performance optimization involves improving query speed, reducing resource usage, and scaling for growth. This section covers practical techniques to make your database faster.

## Query Optimization

### Use EXPLAIN
```sql
-- Show query execution plan
EXPLAIN SELECT * FROM employees WHERE last_name = 'Smith';

-- Show actual execution with timing
EXPLAIN ANALYZE
SELECT * FROM employees WHERE last_name = 'Smith';

-- Look for:
-- - Seq Scan (slow, reads entire table)
-- - Index Scan (fast, uses index)
-- - Cost estimates
-- - Actual time
```

### Reading EXPLAIN Output
```sql
EXPLAIN ANALYZE
SELECT e.first_name, d.department_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id
WHERE e.salary > 50000;

-- Output shows:
-- -> Hash Join (cost=X..Y rows=Z)
--    -> Seq Scan on employees (cost=X..Y rows=Z)
--          Filter: (salary > 50000)
--    -> Hash (cost=X..Y rows=Z)
--          -> Seq Scan on departments

-- High costs or Seq Scans indicate potential issues
```

## Index Optimization

### When to Add Indexes
```sql
-- 1. Columns in WHERE clauses
CREATE INDEX idx_salary ON employees(salary);

-- 2. Columns in JOIN conditions
CREATE INDEX idx_dept_id ON employees(department_id);

-- 3. Columns in ORDER BY
CREATE INDEX idx_hire_date ON employees(hire_date);

-- 4. Columns used in GROUP BY
CREATE INDEX idx_category ON products(category_id);
```

### Composite Indexes
```sql
-- Order matters! Most selective column first
CREATE INDEX idx_dept_salary ON employees(department_id, salary);

-- This index helps:
SELECT * FROM employees WHERE department_id = 10;
SELECT * FROM employees WHERE department_id = 10 AND salary > 50000;

-- But NOT:
SELECT * FROM employees WHERE salary > 50000;  -- salary not first column
```

### Covering Indexes
```sql
-- Include all columns needed by query
CREATE INDEX idx_employee_info
ON employees(department_id, last_name, first_name, salary);

-- Query uses index-only scan (fastest)
SELECT last_name, first_name, salary
FROM employees
WHERE department_id = 10;
```

### Partial Indexes
```sql
-- Index only active records
CREATE INDEX idx_active_employees
ON employees(hire_date)
WHERE status = 'active';

-- Smaller, faster, less maintenance
```

## Query Rewriting

### Use EXISTS Instead of IN (for subqueries)
```sql
-- Slower
SELECT * FROM customers
WHERE customer_id IN (
    SELECT customer_id FROM orders WHERE total > 1000
);

-- Faster
SELECT * FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.customer_id AND o.total > 1000
);
```

### Use JOINs Instead of Subqueries
```sql
-- Slower (correlated subquery)
SELECT
    e.first_name,
    (SELECT d.department_name FROM departments d WHERE d.department_id = e.department_id) AS dept
FROM employees e;

-- Faster (JOIN)
SELECT e.first_name, d.department_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id;
```

### Avoid SELECT *
```sql
-- Bad: Retrieves all columns
SELECT * FROM employees WHERE department_id = 10;

-- Good: Retrieve only needed columns
SELECT employee_id, first_name, last_name
FROM employees
WHERE department_id = 10;
```

### Avoid Functions on Indexed Columns
```sql
-- Bad: Index not used
SELECT * FROM employees WHERE YEAR(hire_date) = 2024;

-- Good: Index used
SELECT * FROM employees
WHERE hire_date >= '2024-01-01' AND hire_date < '2025-01-01';
```

### Use LIMIT for Large Results
```sql
-- Without LIMIT: Returns all rows
SELECT * FROM orders ORDER BY order_date DESC;

-- With LIMIT: Returns only what's needed
SELECT * FROM orders ORDER BY order_date DESC LIMIT 100;
```

## JOIN Optimization

### Proper JOIN Order
```sql
-- Start with smallest table (query optimizer usually handles this)
-- Filter early to reduce join size

-- Good: Filter before join
SELECT c.customer_name, o.order_id
FROM (
    SELECT * FROM customers WHERE country = 'USA'
) c
JOIN orders o ON c.customer_id = o.customer_id;

-- Also good: WHERE clause
SELECT c.customer_name, o.order_id
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE c.country = 'USA';
```

### Index Foreign Keys
```sql
-- Always index foreign key columns
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
```

## Aggregation Optimization

### Use Appropriate GROUP BY
```sql
-- Include necessary columns only
SELECT department_id, COUNT(*), AVG(salary)
FROM employees
GROUP BY department_id;

-- If you need employee_id in result, it must be in GROUP BY
SELECT department_id, employee_id, COUNT(*)
FROM employees
GROUP BY department_id, employee_id;
```

### Use Window Functions Instead of Self-Joins
```sql
-- Slow: Self-join
SELECT e1.*, e2.avg_salary
FROM employees e1
JOIN (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
) e2 ON e1.department_id = e2.department_id;

-- Fast: Window function
SELECT
    *,
    AVG(salary) OVER (PARTITION BY department_id) AS avg_salary
FROM employees;
```

### Materialize Complex Aggregations
```sql
-- Create materialized view for expensive aggregations
CREATE MATERIALIZED VIEW monthly_sales_summary AS
SELECT
    DATE_TRUNC('month', order_date) AS month,
    SUM(total_amount) AS total_sales,
    COUNT(*) AS order_count
FROM orders
GROUP BY DATE_TRUNC('month', order_date);

-- Refresh periodically (once per day)
REFRESH MATERIALIZED VIEW monthly_sales_summary;

-- Query is now instant
SELECT * FROM monthly_sales_summary WHERE month = '2024-01-01';
```

## Table Design Optimization

### Normalization vs Denormalization
```sql
-- Normalized: Less redundancy, more joins
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id)
);

-- Denormalized: Faster queries, more storage
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER,
    customer_name VARCHAR(100),  -- Denormalized
    customer_email VARCHAR(100)  -- Denormalized
);

-- Use denormalization for:
-- - Frequently joined data
-- - Read-heavy workloads
-- - When data rarely changes
```

### Partitioning Large Tables
```sql
-- Range partitioning by date (PostgreSQL 10+)
CREATE TABLE orders (
    order_id SERIAL,
    order_date DATE NOT NULL,
    customer_id INTEGER,
    total_amount DECIMAL
) PARTITION BY RANGE (order_date);

-- Create partitions
CREATE TABLE orders_2024_q1 PARTITION OF orders
FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');

CREATE TABLE orders_2024_q2 PARTITION OF orders
FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

-- Queries automatically use appropriate partition
SELECT * FROM orders WHERE order_date = '2024-02-15';
-- Only scans orders_2024_q1
```

### Use Appropriate Data Types
```sql
-- Bad: Wastes space
CREATE TABLE products (
    product_id BIGINT,  -- SERIAL would be enough
    price DOUBLE PRECISION,  -- DECIMAL better for money
    is_active VARCHAR(10)  -- BOOLEAN better
);

-- Good: Efficient types
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    price DECIMAL(10,2),
    is_active BOOLEAN
);
```

## Connection Pooling

```python
# Python example with psycopg2 connection pool
from psycopg2 import pool

# Create connection pool
connection_pool = pool.SimpleConnectionPool(
    minconn=1,
    maxconn=20,
    host='localhost',
    database='mydb',
    user='user',
    password='pass'
)

# Get connection from pool
conn = connection_pool.getconn()

# Use connection
cursor = conn.cursor()
cursor.execute("SELECT * FROM products")

# Return connection to pool
connection_pool.putconn(conn)
```

## Vacuum and Analyze

### VACUUM
```sql
-- Remove dead tuples (from UPDATE/DELETE)
VACUUM employees;

-- Full vacuum (locks table, reclaims space)
VACUUM FULL employees;

-- Vacuum all tables
VACUUM;
```

### ANALYZE
```sql
-- Update statistics for query planner
ANALYZE employees;

-- Analyze all tables
ANALYZE;

-- Analyze specific columns
ANALYZE employees(last_name, salary);
```

### Auto-Vacuum
```sql
-- PostgreSQL runs auto-vacuum automatically
-- Configure in postgresql.conf:
-- autovacuum = on
-- autovacuum_vacuum_scale_factor = 0.2
-- autovacuum_analyze_scale_factor = 0.1
```

## Caching Strategies

### Database-Level Caching
```sql
-- PostgreSQL shared_buffers (in postgresql.conf)
-- shared_buffers = 25% of RAM (for dedicated server)

-- Effective cache size
-- effective_cache_size = 50-75% of RAM
```

### Application-Level Caching
```python
# Redis cache example
import redis
cache = redis.Redis()

def get_product(product_id):
    # Check cache first
    cached = cache.get(f"product:{product_id}")
    if cached:
        return json.loads(cached)

    # Cache miss: query database
    product = db.query("SELECT * FROM products WHERE product_id = %s", product_id)

    # Store in cache (expire in 1 hour)
    cache.setex(f"product:{product_id}", 3600, json.dumps(product))

    return product
```

### Query Result Caching
```sql
-- Use materialized views
CREATE MATERIALIZED VIEW expensive_report AS
SELECT /* complex query */;

-- Refresh when needed
REFRESH MATERIALIZED VIEW expensive_report;
```

## Monitoring Performance

### Slow Query Log
```sql
-- PostgreSQL config
-- log_min_duration_statement = 1000  # Log queries > 1 second

-- Find slow queries
SELECT
    query,
    calls,
    total_time,
    mean_time,
    max_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
```

### Table Statistics
```sql
-- Table sizes
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Table bloat
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public';
```

### Index Usage Statistics
```sql
-- Find unused indexes
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;
```

## Configuration Tuning (PostgreSQL)

### Memory Settings
```sql
-- postgresql.conf

-- Shared buffers (25% of RAM for dedicated server)
shared_buffers = 4GB

-- Work memory (per operation)
work_mem = 50MB

-- Maintenance work memory (for VACUUM, CREATE INDEX)
maintenance_work_mem = 1GB

-- Effective cache size (hint to planner)
effective_cache_size = 12GB
```

### Connection Settings
```sql
-- Max connections
max_connections = 100

-- Use connection pooling (pgBouncer) for high connection counts
```

### Checkpoint Settings
```sql
-- Checkpoint frequency
checkpoint_timeout = 15min
checkpoint_completion_target = 0.9
```

## Common Performance Anti-Patterns

### 1. N+1 Query Problem
```python
# Bad: N+1 queries
for user in users:
    # Separate query for each user
    orders = db.query("SELECT * FROM orders WHERE user_id = ?", user.id)

# Good: Single query with JOIN
results = db.query("""
    SELECT users.*, orders.*
    FROM users
    LEFT JOIN orders ON users.id = orders.user_id
""")
```

### 2. Large OFFSET
```sql
-- Slow for large offsets
SELECT * FROM products ORDER BY product_id LIMIT 10 OFFSET 1000000;

-- Better: Keyset pagination
SELECT * FROM products
WHERE product_id > 1000000
ORDER BY product_id
LIMIT 10;
```

### 3. Implicit Type Conversion
```sql
-- Bad: Implicit conversion prevents index use
SELECT * FROM employees WHERE employee_id = '123';  -- employee_id is INTEGER

-- Good: Explicit type
SELECT * FROM employees WHERE employee_id = 123;
```

## Practice Problems
Check the `problems` directory for hands-on performance optimization exercises.

## Key Takeaways
- Use EXPLAIN ANALYZE to understand query performance
- Index foreign keys and frequently queried columns
- Avoid SELECT *, retrieve only needed columns
- Use EXISTS instead of IN for subqueries
- Rewrite correlated subqueries as JOINs or window functions
- Materialize expensive aggregations
- Monitor slow queries and unused indexes
- Run VACUUM and ANALYZE regularly
- Use connection pooling for high concurrency
- Cache frequently accessed data
- Partition large tables by date or range
- Tune PostgreSQL configuration for your workload

## Next Steps
Move on to [16-advanced-sql-concepts](../16-advanced-sql-concepts/README.md) to learn about cutting-edge SQL features.
