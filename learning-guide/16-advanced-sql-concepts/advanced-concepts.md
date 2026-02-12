# 16 - Advanced SQL Concepts

## Overview
This section covers advanced SQL features including recursive queries, window functions, advanced joins, and modern SQL capabilities that enable sophisticated data analysis and manipulation.

## Recursive Queries (CTEs)

### Basic Recursive CTE
```sql
-- Generate sequence of numbers
WITH RECURSIVE numbers AS (
    -- Base case
    SELECT 1 AS n
    UNION ALL
    -- Recursive case
    SELECT n + 1 FROM numbers WHERE n < 10
)
SELECT * FROM numbers;
-- Returns: 1, 2, 3, ..., 10
```

### Employee Hierarchy
```sql
-- Find all employees reporting to a manager
WITH RECURSIVE employee_tree AS (
    -- Base case: start with CEO (no manager)
    SELECT employee_id, first_name, manager_id, 1 AS level, first_name AS path
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive case: find direct reports
    SELECT e.employee_id, e.first_name, e.manager_id, et.level + 1, et.path || ' -> ' || e.first_name
    FROM employees e
    JOIN employee_tree et ON e.manager_id = et.employee_id
)
SELECT * FROM employee_tree ORDER BY level, first_name;
```

### Graph Traversal
```sql
-- Find all connected nodes in a graph
WITH RECURSIVE connected_nodes AS (
    -- Start node
    SELECT node_id, 1 AS depth
    FROM graph
    WHERE node_id = 1

    UNION

    -- Find connected nodes
    SELECT g.target_node_id, cn.depth + 1
    FROM graph g
    JOIN connected_nodes cn ON g.node_id = cn.node_id
    WHERE cn.depth < 10  -- Prevent infinite recursion
)
SELECT DISTINCT node_id FROM connected_nodes;
```

### Bill of Materials (BOM)
```sql
-- Calculate total cost including sub-components
WITH RECURSIVE bom AS (
    -- Top-level product
    SELECT product_id, component_id, quantity, 1 AS level
    FROM product_components
    WHERE product_id = 100

    UNION ALL

    -- Sub-components
    SELECT bom.product_id, pc.component_id, bom.quantity * pc.quantity, bom.level + 1
    FROM product_components pc
    JOIN bom ON pc.product_id = bom.component_id
)
SELECT component_id, SUM(quantity) AS total_quantity
FROM bom
GROUP BY component_id;
```

## Advanced Window Functions

### Ranking with Gaps and Dense Ranking
```sql
SELECT
    product_name,
    price,
    ROW_NUMBER() OVER (ORDER BY price DESC) AS row_num,
    RANK() OVER (ORDER BY price DESC) AS rank,
    DENSE_RANK() OVER (ORDER BY price DESC) AS dense_rank,
    NTILE(4) OVER (ORDER BY price DESC) AS quartile
FROM products;

-- Results:
-- Product  | Price | row_num | rank | dense_rank | quartile
-- Premium  | 100   | 1       | 1    | 1          | 1
-- Deluxe   | 100   | 2       | 1    | 1          | 1
-- Standard | 90    | 3       | 3    | 2          | 2
```

### Running Totals and Moving Averages
```sql
SELECT
    order_date,
    total_amount,
    -- Running total
    SUM(total_amount) OVER (ORDER BY order_date) AS running_total,
    -- Moving average (last 7 days)
    AVG(total_amount) OVER (
        ORDER BY order_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS moving_avg_7day,
    -- Cumulative average
    AVG(total_amount) OVER (ORDER BY order_date) AS cumulative_avg
FROM orders;
```

### Lead and Lag for Comparisons
```sql
-- Compare with previous and next rows
SELECT
    order_date,
    total_amount,
    LAG(total_amount) OVER (ORDER BY order_date) AS prev_amount,
    LEAD(total_amount) OVER (ORDER BY order_date) AS next_amount,
    total_amount - LAG(total_amount) OVER (ORDER BY order_date) AS diff_from_prev,
    CASE
        WHEN total_amount > LAG(total_amount) OVER (ORDER BY order_date) THEN 'Increase'
        WHEN total_amount < LAG(total_amount) OVER (ORDER BY order_date) THEN 'Decrease'
        ELSE 'Same'
    END AS trend
FROM orders;
```

### First and Last Values
```sql
-- Compare each row with first and last in partition
SELECT
    department_id,
    employee_name,
    salary,
    FIRST_VALUE(salary) OVER (
        PARTITION BY department_id
        ORDER BY salary DESC
    ) AS highest_salary,
    LAST_VALUE(salary) OVER (
        PARTITION BY department_id
        ORDER BY salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS lowest_salary,
    salary - LAST_VALUE(salary) OVER (
        PARTITION BY department_id
        ORDER BY salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS diff_from_lowest
FROM employees;
```

## Lateral Joins

### Basic LATERAL Join
```sql
-- For each customer, get their 3 most recent orders
SELECT
    c.customer_name,
    recent_orders.order_date,
    recent_orders.total_amount
FROM customers c
CROSS JOIN LATERAL (
    SELECT order_date, total_amount
    FROM orders o
    WHERE o.customer_id = c.customer_id
    ORDER BY order_date DESC
    LIMIT 3
) recent_orders;
```

### LATERAL with Complex Calculations
```sql
-- Calculate statistics per department
SELECT
    d.department_name,
    stats.avg_salary,
    stats.max_salary,
    stats.employee_count
FROM departments d
LEFT JOIN LATERAL (
    SELECT
        AVG(salary) AS avg_salary,
        MAX(salary) AS max_salary,
        COUNT(*) AS employee_count
    FROM employees e
    WHERE e.department_id = d.department_id
) stats ON true;
```

## PIVOT and UNPIVOT (Crosstab)

### Manual PIVOT
```sql
-- Convert rows to columns
SELECT
    product_id,
    SUM(CASE WHEN EXTRACT(MONTH FROM order_date) = 1 THEN quantity ELSE 0 END) AS jan,
    SUM(CASE WHEN EXTRACT(MONTH FROM order_date) = 2 THEN quantity ELSE 0 END) AS feb,
    SUM(CASE WHEN EXTRACT(MONTH FROM order_date) = 3 THEN quantity ELSE 0 END) AS mar
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
GROUP BY product_id;
```

### Crosstab (PostgreSQL)
```sql
-- Install tablefunc extension
CREATE EXTENSION IF NOT EXISTS tablefunc;

-- Pivot with crosstab
SELECT * FROM crosstab(
    'SELECT product_id, month, sales FROM monthly_sales ORDER BY 1, 2',
    'SELECT DISTINCT month FROM monthly_sales ORDER BY 1'
) AS ct(product_id INTEGER, jan NUMERIC, feb NUMERIC, mar NUMERIC);
```

### UNPIVOT
```sql
-- Convert columns to rows
SELECT product_id, 'jan' AS month, jan AS sales FROM sales_pivot
UNION ALL
SELECT product_id, 'feb', feb FROM sales_pivot
UNION ALL
SELECT product_id, 'mar', mar FROM sales_pivot;
```

## GROUPING SETS, CUBE, ROLLUP

### GROUPING SETS
```sql
-- Multiple groupings in one query
SELECT
    department_id,
    job_title,
    COUNT(*) AS employee_count,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY GROUPING SETS (
    (department_id, job_title),  -- Group by both
    (department_id),              -- Group by department only
    (job_title),                  -- Group by job title only
    ()                            -- Grand total
);
```

### ROLLUP
```sql
-- Hierarchical subtotals
SELECT
    EXTRACT(YEAR FROM order_date) AS year,
    EXTRACT(QUARTER FROM order_date) AS quarter,
    EXTRACT(MONTH FROM order_date) AS month,
    SUM(total_amount) AS total_sales
FROM orders
GROUP BY ROLLUP (
    EXTRACT(YEAR FROM order_date),
    EXTRACT(QUARTER FROM order_date),
    EXTRACT(MONTH FROM order_date)
);
-- Generates totals at each level of hierarchy
```

### CUBE
```sql
-- All possible combinations of dimensions
SELECT
    department_id,
    job_title,
    COUNT(*) AS employee_count
FROM employees
GROUP BY CUBE (department_id, job_title);
-- Generates:
-- (dept, job), (dept, ALL), (ALL, job), (ALL, ALL)
```

### GROUPING and GROUPING_ID
```sql
SELECT
    department_id,
    job_title,
    COUNT(*) AS employee_count,
    GROUPING(department_id) AS dept_grouping,
    GROUPING(job_title) AS job_grouping
FROM employees
GROUP BY CUBE (department_id, job_title);
-- GROUPING returns 1 if column is aggregated, 0 otherwise
```

## Array Operations (PostgreSQL)

### Array Creation and Access
```sql
-- Create array
SELECT ARRAY[1, 2, 3, 4, 5] AS numbers;
SELECT ARRAY['red', 'green', 'blue'] AS colors;

-- Array from subquery
SELECT ARRAY(SELECT product_id FROM products WHERE category = 'Electronics');

-- Access elements (1-indexed)
SELECT (ARRAY[10, 20, 30])[1];  -- Returns 10

-- Array slicing
SELECT (ARRAY[1, 2, 3, 4, 5])[2:4];  -- Returns {2, 3, 4}
```

### Array Functions
```sql
-- Array operations
SELECT ARRAY[1, 2, 3] || ARRAY[4, 5];  -- Concatenate: {1,2,3,4,5}
SELECT ARRAY[1, 2, 3] || 4;            -- Append: {1,2,3,4}
SELECT ARRAY_LENGTH(ARRAY[1, 2, 3], 1);  -- Length: 3
SELECT UNNEST(ARRAY[1, 2, 3]);         -- Convert to rows

-- Array aggregation
SELECT ARRAY_AGG(product_name ORDER BY price DESC)
FROM products;

-- Check containment
SELECT ARRAY[1, 2, 3] @> ARRAY[2];     -- Contains: true
SELECT ARRAY[1, 2, 3] <@ ARRAY[1, 2, 3, 4];  -- Contained by: true
```

### Array Queries
```sql
-- Find rows with specific array element
SELECT * FROM products WHERE 'electronics' = ANY(tags);

-- Find rows where all elements match
SELECT * FROM products WHERE tags @> ARRAY['sale', 'featured'];

-- Expand array to rows
SELECT product_id, UNNEST(tags) AS tag FROM products;
```

## JSON and JSONB Operations

### JSON Querying
```sql
-- Extract JSON field
SELECT data->'name' AS name FROM users;          -- Returns JSON
SELECT data->>'name' AS name FROM users;         -- Returns text

-- Nested extraction
SELECT data->'address'->>'city' AS city FROM users;

-- Array element
SELECT data->'items'->0->>'product_id' AS first_product FROM orders;
```

### JSONB Operators
```sql
-- Contains
SELECT * FROM users WHERE data @> '{"status": "active"}';

-- Key exists
SELECT * FROM users WHERE data ? 'email';

-- Any key exists
SELECT * FROM users WHERE data ?| ARRAY['email', 'phone'];

-- All keys exist
SELECT * FROM users WHERE data ?& ARRAY['first_name', 'last_name'];
```

### JSON Functions
```sql
-- Build JSON
SELECT JSON_BUILD_OBJECT(
    'id', employee_id,
    'name', first_name || ' ' || last_name,
    'salary', salary
) FROM employees;

-- Aggregate to JSON
SELECT JSON_AGG(
    JSON_BUILD_OBJECT('name', product_name, 'price', price)
) FROM products;

-- Extract keys
SELECT JSONB_OBJECT_KEYS(data) FROM users;

-- Pretty print
SELECT JSONB_PRETTY(data) FROM users;
```

## Full-Text Search

### Create Search Vector
```sql
-- Add tsvector column
ALTER TABLE articles ADD COLUMN search_vector tsvector;

-- Update search vector
UPDATE articles
SET search_vector =
    TO_TSVECTOR('english', title || ' ' || body);

-- Create GIN index
CREATE INDEX idx_articles_search ON articles USING GIN(search_vector);
```

### Full-Text Search Queries
```sql
-- Basic search
SELECT * FROM articles
WHERE search_vector @@ TO_TSQUERY('english', 'postgresql & database');

-- Phrase search
SELECT * FROM articles
WHERE search_vector @@ PHRASETO_TSQUERY('english', 'relational database');

-- Ranking results
SELECT
    title,
    TS_RANK(search_vector, TO_TSQUERY('english', 'postgresql')) AS rank
FROM articles
WHERE search_vector @@ TO_TSQUERY('english', 'postgresql')
ORDER BY rank DESC;
```

### Search Configuration
```sql
-- Highlight matches
SELECT TS_HEADLINE(
    'english',
    body,
    TO_TSQUERY('english', 'postgresql'),
    'MaxWords=50, MinWords=20'
) FROM articles;
```

## Table Inheritance (PostgreSQL)

### Creating Inherited Tables
```sql
-- Parent table
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    salary DECIMAL(10, 2)
);

-- Child table inherits from parent
CREATE TABLE managers (
    department_id INTEGER,
    bonus DECIMAL(10, 2)
) INHERITS (employees);

-- Query parent includes child rows
SELECT * FROM employees;  -- Includes managers

-- Query only parent
SELECT * FROM ONLY employees;  -- Excludes managers
```

## Generated Columns (PostgreSQL 12+)

### Stored Generated Columns
```sql
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    price DECIMAL(10, 2),
    tax_rate DECIMAL(5, 4),
    price_with_tax DECIMAL(10, 2) GENERATED ALWAYS AS (price * (1 + tax_rate)) STORED
);

-- price_with_tax is automatically calculated
INSERT INTO products (price, tax_rate) VALUES (100, 0.08);
SELECT * FROM products;  -- price_with_tax = 108.00
```

### Virtual Columns
```sql
-- Not stored, computed on read
CREATE TABLE employees (
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    full_name VARCHAR(101) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED
);
```

## Practice Problems
Check the `problems` directory for advanced SQL exercises.

## Key Takeaways
- Recursive CTEs traverse hierarchical data
- Window functions enable complex analytics without GROUP BY
- LATERAL joins allow correlated subqueries in FROM clause
- GROUPING SETS, CUBE, ROLLUP provide flexible aggregations
- PostgreSQL arrays enable multi-valued columns
- JSONB provides flexible schema and powerful operators
- Full-text search offers sophisticated text querying
- Generated columns automate calculations
- Advanced features improve expressiveness and performance

## Congratulations!
You've completed the SQL learning guide. Continue practicing with the problems directory and apply these concepts to real-world projects.

## Further Learning
- PostgreSQL documentation: https://www.postgresql.org/docs/
- SQL standard specifications
- Database-specific extensions and features
- Query optimization techniques
- Database design patterns
- Distributed databases and scaling
