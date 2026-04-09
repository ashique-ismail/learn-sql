# SQL Window Functions - Complete Guide

## Table of Contents
1. [Introduction](#introduction)
2. [What are Window Functions?](#what-are-window-functions)
3. [Basic Syntax](#basic-syntax)
4. [Types of Window Functions](#types-of-window-functions)
5. [Window Frame Specifications](#window-frame-specifications)
6. [Aggregate Window Functions](#aggregate-window-functions)
7. [Ranking Window Functions](#ranking-window-functions)
8. [Value Window Functions](#value-window-functions)
9. [Offset Window Functions](#offset-window-functions)
10. [Advanced Techniques](#advanced-techniques)
11. [Performance Optimization](#performance-optimization)
12. [Common Patterns](#common-patterns)

---

## Introduction

Window functions (also called **analytic functions** or **OVER functions**) perform calculations across a set of rows that are related to the current row. Unlike aggregate functions with GROUP BY, window functions **preserve all rows** while adding calculated values.

**Key Characteristics:**
- Operate on a "window" of rows
- Don't collapse rows like GROUP BY
- Can access multiple rows at once
- Essential for advanced analytics

---

## What are Window Functions?

### The Problem They Solve

**Without Window Functions:**
```sql
-- Get total sales per region (loses detail)
SELECT region, SUM(sales) as total_sales
FROM orders
GROUP BY region;
```
**Result (3 rows):**
| region | total_sales |
|--------|-------------|
| North  | 50000       |
| South  | 45000       |
| East   | 60000       |

**With Window Functions:**
```sql
-- Get total sales per region while keeping all rows
SELECT order_id, region, sales,
       SUM(sales) OVER (PARTITION BY region) as total_sales
FROM orders;
```
**Result (keeping all original rows):**
| order_id | region | sales | total_sales |
|----------|--------|-------|-------------|
| 1        | North  | 10000 | 50000       |
| 2        | North  | 15000 | 50000       |
| 3        | North  | 25000 | 50000       |
| 4        | South  | 20000 | 45000       |
| 5        | South  | 25000 | 45000       |
| 6        | East   | 30000 | 60000       |
| 7        | East   | 30000 | 60000       |

### Window Function Conceptual Model

```
Original Table → Define Window → Calculate → Add Result Column
     ↓                ↓              ↓              ↓
  All rows      Group/Order    Function      Original + Result
```

---

## Basic Syntax

```sql
window_function([arguments]) OVER (
    [PARTITION BY partition_expression]
    [ORDER BY sort_expression [ASC|DESC]]
    [frame_specification]
)
```

### Components

1. **window_function** - The function to apply (SUM, RANK, LAG, etc.)
2. **PARTITION BY** - Divides rows into groups (like GROUP BY, but doesn't collapse)
3. **ORDER BY** - Defines order within each partition
4. **frame_specification** - Defines which rows in the partition to include

### Simplest Example

```sql
-- Add row numbers to all rows
SELECT order_id, customer_name,
       ROW_NUMBER() OVER () as row_num
FROM orders;
```

---

## Types of Window Functions

### 1. Aggregate Functions
Apply aggregate operations over windows:
- `SUM()`, `AVG()`, `COUNT()`, `MIN()`, `MAX()`
- `STRING_AGG()`, `ARRAY_AGG()` (PostgreSQL)

### 2. Ranking Functions
Assign ranks or row numbers:
- `ROW_NUMBER()` - Unique sequential number
- `RANK()` - Rank with gaps for ties
- `DENSE_RANK()` - Rank without gaps
- `NTILE(n)` - Divide into n buckets
- `PERCENT_RANK()` - Relative rank (0-1)
- `CUME_DIST()` - Cumulative distribution

### 3. Value Functions
Access values from other rows:
- `FIRST_VALUE()` - First value in window
- `LAST_VALUE()` - Last value in window
- `NTH_VALUE()` - Nth value in window

### 4. Offset Functions
Access values from relative positions:
- `LAG()` - Access previous row
- `LEAD()` - Access next row

---

## Window Frame Specifications

Frame specifications define **which rows** in the partition to include in calculations.

### Syntax

```sql
{ ROWS | RANGE | GROUPS } BETWEEN frame_start AND frame_end
```

### Frame Boundaries

| Boundary | Meaning |
|----------|---------|
| `UNBOUNDED PRECEDING` | Start of partition |
| `n PRECEDING` | N rows before current |
| `CURRENT ROW` | Current row |
| `n FOLLOWING` | N rows after current |
| `UNBOUNDED FOLLOWING` | End of partition |

### Common Frame Patterns

```sql
-- All rows from start to current (running total)
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW

-- Current row only
ROWS BETWEEN CURRENT ROW AND CURRENT ROW

-- All rows in partition
ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING

-- 3-row moving average (previous, current, next)
ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING

-- Last 7 days (requires ORDER BY date)
ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
```

### Default Frames

**With ORDER BY:**
```sql
-- Default frame
RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
```

**Without ORDER BY:**
```sql
-- Default frame (all rows in partition)
ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
```

### ROWS vs RANGE vs GROUPS

| Mode | Behavior |
|------|----------|
| `ROWS` | Physical rows (count rows) |
| `RANGE` | Logical range (based on values) |
| `GROUPS` | Peer groups (rows with same ORDER BY value) |

**Example:**
```sql
CREATE TABLE sales (
    date DATE,
    amount INT
);

INSERT INTO sales VALUES
('2024-01-01', 100),
('2024-01-01', 150),
('2024-01-02', 200),
('2024-01-03', 250);

-- ROWS: Count physical rows
SELECT date, amount,
       SUM(amount) OVER (
           ORDER BY date
           ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
       ) as sum_rows
FROM sales;
```

**Result:**
| date       | amount | sum_rows |
|------------|--------|----------|
| 2024-01-01 | 100    | 100      | ← Current only
| 2024-01-01 | 150    | 250      | ← Previous + current
| 2024-01-02 | 200    | 350      | ← Previous + current
| 2024-01-03 | 250    | 450      | ← Previous + current

```sql
-- RANGE: Include all rows with same date
SELECT date, amount,
       SUM(amount) OVER (
           ORDER BY date
           RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) as sum_range
FROM sales;
```

**Result:**
| date       | amount | sum_range |
|------------|--------|-----------|
| 2024-01-01 | 100    | 250       | ← Both rows with same date
| 2024-01-01 | 150    | 250       | ← Both rows with same date
| 2024-01-02 | 200    | 450       | ← All up to this date
| 2024-01-03 | 250    | 700       | ← All rows

---

## Aggregate Window Functions

### SUM() - Running Totals

```sql
CREATE TABLE transactions (
    id INT,
    user_id INT,
    amount DECIMAL(10,2),
    transaction_date DATE
);

-- Running total of all transactions
SELECT id, user_id, amount, transaction_date,
       SUM(amount) OVER (ORDER BY transaction_date) as running_total
FROM transactions;

-- Running total per user
SELECT id, user_id, amount, transaction_date,
       SUM(amount) OVER (
           PARTITION BY user_id
           ORDER BY transaction_date
       ) as user_running_total
FROM transactions;
```

### AVG() - Moving Averages

```sql
-- 7-day moving average
SELECT date, price,
       AVG(price) OVER (
           ORDER BY date
           ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
       ) as moving_avg_7day
FROM stock_prices;

-- Moving average per stock
SELECT date, symbol, price,
       AVG(price) OVER (
           PARTITION BY symbol
           ORDER BY date
           ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
       ) as moving_avg_30day
FROM stock_prices;
```

### COUNT() - Rolling Counts

```sql
-- Count distinct users in last 30 days
SELECT date,
       COUNT(DISTINCT user_id) OVER (
           ORDER BY date
           RANGE BETWEEN INTERVAL '30 days' PRECEDING AND CURRENT ROW
       ) as active_users_30d
FROM user_activity;
```

### MIN() / MAX() - Range Analysis

```sql
-- Compare current price to min/max in last 52 weeks
SELECT date, symbol, price,
       MIN(price) OVER (
           PARTITION BY symbol
           ORDER BY date
           ROWS BETWEEN 51 PRECEDING AND CURRENT ROW
       ) as week_52_low,
       MAX(price) OVER (
           PARTITION BY symbol
           ORDER BY date
           ROWS BETWEEN 51 PRECEDING AND CURRENT ROW
       ) as week_52_high
FROM stock_prices;
```

### Complete Example: Sales Dashboard

```sql
CREATE TABLE daily_sales (
    sale_date DATE,
    region VARCHAR(50),
    product VARCHAR(50),
    revenue DECIMAL(10,2)
);

SELECT
    sale_date,
    region,
    product,
    revenue,

    -- Running total for this product
    SUM(revenue) OVER (
        PARTITION BY product
        ORDER BY sale_date
    ) as product_running_total,

    -- 7-day moving average
    AVG(revenue) OVER (
        PARTITION BY product
        ORDER BY sale_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as moving_avg_7day,

    -- Compare to region average for this day
    AVG(revenue) OVER (
        PARTITION BY sale_date, region
    ) as region_avg_today,

    -- Total revenue across all products today
    SUM(revenue) OVER (
        PARTITION BY sale_date
    ) as total_revenue_today

FROM daily_sales
ORDER BY sale_date, product;
```

---

## Ranking Window Functions

See [rank-functions.md](rank-functions.md) for detailed coverage.

### Quick Reference

```sql
SELECT
    name,
    department,
    salary,

    -- Unique row number
    ROW_NUMBER() OVER (
        PARTITION BY department
        ORDER BY salary DESC
    ) as row_num,

    -- Rank with gaps
    RANK() OVER (
        PARTITION BY department
        ORDER BY salary DESC
    ) as rank,

    -- Rank without gaps
    DENSE_RANK() OVER (
        PARTITION BY department
        ORDER BY salary DESC
    ) as dense_rank,

    -- Quartiles (1-4)
    NTILE(4) OVER (
        ORDER BY salary DESC
    ) as quartile,

    -- Percentile (0-1)
    PERCENT_RANK() OVER (
        ORDER BY salary DESC
    ) as percentile

FROM employees;
```

---

## Value Window Functions

### FIRST_VALUE() and LAST_VALUE()

```sql
-- Compare each sale to first and last of the month
SELECT
    sale_date,
    amount,

    -- First sale of the month
    FIRST_VALUE(amount) OVER (
        PARTITION BY DATE_TRUNC('month', sale_date)
        ORDER BY sale_date
    ) as first_sale_of_month,

    -- Last sale of the month (need full frame!)
    LAST_VALUE(amount) OVER (
        PARTITION BY DATE_TRUNC('month', sale_date)
        ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as last_sale_of_month

FROM sales;
```

**Important:** `LAST_VALUE()` requires explicit frame specification to see future rows!

### NTH_VALUE()

```sql
-- Get 2nd highest salary in each department
SELECT
    name,
    department,
    salary,
    NTH_VALUE(salary, 2) OVER (
        PARTITION BY department
        ORDER BY salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as second_highest_salary
FROM employees;
```

### Example: Price Comparison

```sql
-- Compare current price to opening and closing price
SELECT
    date,
    symbol,
    price,

    FIRST_VALUE(price) OVER (
        PARTITION BY symbol, DATE_TRUNC('day', date)
        ORDER BY date
    ) as opening_price,

    LAST_VALUE(price) OVER (
        PARTITION BY symbol, DATE_TRUNC('day', date)
        ORDER BY date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as closing_price,

    price - FIRST_VALUE(price) OVER (
        PARTITION BY symbol, DATE_TRUNC('day', date)
        ORDER BY date
    ) as change_from_open

FROM stock_prices;
```

---

## Offset Window Functions

### LAG() - Access Previous Row

```sql
LAG(column, offset, default) OVER (
    [PARTITION BY partition]
    ORDER BY order_column
)
```

**Parameters:**
- `column` - Column to access
- `offset` - How many rows back (default 1)
- `default` - Value if no previous row exists (default NULL)

**Example:**
```sql
-- Compare each day's sales to previous day
SELECT
    sale_date,
    revenue,
    LAG(revenue) OVER (ORDER BY sale_date) as prev_day_revenue,
    revenue - LAG(revenue) OVER (ORDER BY sale_date) as day_over_day_change,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY sale_date)) * 100.0
        / LAG(revenue) OVER (ORDER BY sale_date),
        2
    ) as pct_change
FROM daily_sales;
```

**Result:**
| sale_date  | revenue | prev_day_revenue | day_over_day_change | pct_change |
|------------|---------|------------------|---------------------|------------|
| 2024-01-01 | 1000    | NULL             | NULL                | NULL       |
| 2024-01-02 | 1200    | 1000             | 200                 | 20.00      |
| 2024-01-03 | 1150    | 1200             | -50                 | -4.17      |

### LEAD() - Access Next Row

```sql
LEAD(column, offset, default) OVER (
    [PARTITION BY partition]
    ORDER BY order_column
)
```

**Example:**
```sql
-- Compare current quarter to next quarter (forward-looking)
SELECT
    quarter,
    revenue,
    LEAD(revenue) OVER (ORDER BY quarter) as next_quarter_revenue,
    LEAD(revenue) OVER (ORDER BY quarter) - revenue as expected_growth
FROM quarterly_results;
```

### Multiple Offsets

```sql
-- Compare to both previous and next
SELECT
    date,
    price,
    LAG(price, 1) OVER (ORDER BY date) as prev_price,
    LEAD(price, 1) OVER (ORDER BY date) as next_price,
    (price + LAG(price, 1) OVER (ORDER BY date) + LEAD(price, 1) OVER (ORDER BY date)) / 3 as three_day_avg
FROM stock_prices;
```

### With PARTITION BY

```sql
-- Compare to previous transaction per customer
SELECT
    customer_id,
    transaction_date,
    amount,
    LAG(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
    ) as prev_transaction_amount,
    transaction_date - LAG(transaction_date) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
    ) as days_since_last_transaction
FROM transactions;
```

### Example: Detecting Trends

```sql
-- Identify consecutive increases
SELECT
    date,
    price,
    LAG(price, 1) OVER (ORDER BY date) as prev_price,
    LAG(price, 2) OVER (ORDER BY date) as prev_price_2,
    CASE
        WHEN price > LAG(price, 1) OVER (ORDER BY date)
         AND LAG(price, 1) OVER (ORDER BY date) > LAG(price, 2) OVER (ORDER BY date)
        THEN 'Uptrend'
        WHEN price < LAG(price, 1) OVER (ORDER BY date)
         AND LAG(price, 1) OVER (ORDER BY date) < LAG(price, 2) OVER (ORDER BY date)
        THEN 'Downtrend'
        ELSE 'Mixed'
    END as trend
FROM stock_prices;
```

---

## Advanced Techniques

### 1. Named Windows (WINDOW Clause)

Reuse window definitions:

```sql
SELECT
    name,
    department,
    salary,
    RANK() OVER w as rank,
    DENSE_RANK() OVER w as dense_rank,
    PERCENT_RANK() OVER w as percentile
FROM employees
WINDOW w AS (PARTITION BY department ORDER BY salary DESC);
```

### 2. Nested Window Functions

```sql
-- Rank departments by average salary
SELECT DISTINCT
    department,
    AVG(salary) OVER (PARTITION BY department) as dept_avg_salary,
    RANK() OVER (
        ORDER BY AVG(salary) OVER (PARTITION BY department) DESC
    ) as dept_rank
FROM employees;
```

### 3. Conditional Aggregation

```sql
-- Running total of only high-value transactions
SELECT
    date,
    amount,
    SUM(CASE WHEN amount > 1000 THEN amount ELSE 0 END) OVER (
        ORDER BY date
    ) as running_total_high_value
FROM transactions;
```

### 4. Multiple Windows

```sql
SELECT
    date,
    product,
    revenue,

    -- Product-specific metrics
    AVG(revenue) OVER product_window as product_avg,
    RANK() OVER product_window as product_rank,

    -- Overall metrics
    AVG(revenue) OVER date_window as daily_avg,
    SUM(revenue) OVER date_window as daily_total

FROM sales
WINDOW
    product_window AS (PARTITION BY product ORDER BY date),
    date_window AS (PARTITION BY date);
```

### 5. Gap and Island Problem

Find consecutive sequences:

```sql
-- Find consecutive days of activity
WITH numbered AS (
    SELECT
        user_id,
        activity_date,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY activity_date) as rn,
        activity_date - INTERVAL ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY activity_date
        ) DAY as grp
    FROM user_activity
)
SELECT
    user_id,
    MIN(activity_date) as streak_start,
    MAX(activity_date) as streak_end,
    COUNT(*) as consecutive_days
FROM numbered
GROUP BY user_id, grp
HAVING COUNT(*) >= 7  -- Streaks of 7+ days
ORDER BY user_id, streak_start;
```

### 6. Percentile Calculations

```sql
-- Complex percentile analysis
SELECT
    name,
    salary,
    department,

    -- Percentile within department
    PERCENT_RANK() OVER (
        PARTITION BY department
        ORDER BY salary
    ) as dept_percentile,

    -- Percentile overall
    PERCENT_RANK() OVER (ORDER BY salary) as overall_percentile,

    -- Which quartile?
    NTILE(4) OVER (ORDER BY salary) as quartile,

    -- Cumulative distribution
    CUME_DIST() OVER (ORDER BY salary) as cumulative_pct

FROM employees;
```

---

## Performance Optimization

### 1. Index Strategy

```sql
-- Index on partition and order columns
CREATE INDEX idx_sales_region_date ON sales(region, sale_date);

-- Query benefits from index
SELECT
    region,
    sale_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY region
        ORDER BY sale_date
    ) as running_total
FROM sales;
```

### 2. Filter Before Windowing

```sql
-- Good: Filter first, then window
WITH recent_sales AS (
    SELECT *
    FROM sales
    WHERE sale_date >= CURRENT_DATE - INTERVAL '90 days'
)
SELECT
    sale_date,
    amount,
    AVG(amount) OVER (ORDER BY sale_date) as moving_avg
FROM recent_sales;

-- Less efficient: Window on all data, then filter
SELECT
    sale_date,
    amount,
    moving_avg
FROM (
    SELECT
        sale_date,
        amount,
        AVG(amount) OVER (ORDER BY sale_date) as moving_avg
    FROM sales
) windowed
WHERE sale_date >= CURRENT_DATE - INTERVAL '90 days';
```

### 3. Reuse Windows

```sql
-- Efficient: Define once, use many times
SELECT
    name,
    salary,
    RANK() OVER w as rank,
    DENSE_RANK() OVER w as dense_rank,
    NTILE(10) OVER w as decile
FROM employees
WINDOW w AS (ORDER BY salary DESC);

-- Inefficient: Repeat definition
SELECT
    name,
    salary,
    RANK() OVER (ORDER BY salary DESC) as rank,
    DENSE_RANK() OVER (ORDER BY salary DESC) as dense_rank,
    NTILE(10) OVER (ORDER BY salary DESC) as decile
FROM employees;
```

### 4. Avoid Unnecessary Frames

```sql
-- Good: No frame needed for RANK
SELECT
    name,
    salary,
    RANK() OVER (ORDER BY salary DESC) as rank
FROM employees;

-- Unnecessary: RANK doesn't use frames
SELECT
    name,
    salary,
    RANK() OVER (
        ORDER BY salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as rank
FROM employees;
```

### 5. Materialized Views

```sql
-- Create materialized view for expensive calculations
CREATE MATERIALIZED VIEW sales_metrics AS
SELECT
    sale_date,
    product,
    revenue,
    SUM(revenue) OVER (
        PARTITION BY product
        ORDER BY sale_date
    ) as running_total,
    AVG(revenue) OVER (
        PARTITION BY product
        ORDER BY sale_date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) as moving_avg_30day
FROM sales;

-- Query the materialized view
SELECT * FROM sales_metrics WHERE product = 'Widget';
```

---

## Common Patterns

### Pattern 1: Top N Per Group

```sql
WITH ranked AS (
    SELECT
        category,
        product_name,
        sales,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY sales DESC
        ) as rank
    FROM products
)
SELECT category, product_name, sales
FROM ranked
WHERE rank <= 5;
```

### Pattern 2: Running Total with Reset

```sql
-- Running total that resets each month
SELECT
    date,
    amount,
    SUM(amount) OVER (
        PARTITION BY DATE_TRUNC('month', date)
        ORDER BY date
    ) as monthly_running_total
FROM transactions;
```

### Pattern 3: Year-over-Year Comparison

```sql
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', sale_date) as month,
        SUM(revenue) as monthly_revenue
    FROM sales
    GROUP BY DATE_TRUNC('month', sale_date)
)
SELECT
    month,
    monthly_revenue,
    LAG(monthly_revenue, 12) OVER (ORDER BY month) as same_month_last_year,
    monthly_revenue - LAG(monthly_revenue, 12) OVER (ORDER BY month) as yoy_change,
    ROUND(
        (monthly_revenue - LAG(monthly_revenue, 12) OVER (ORDER BY month)) * 100.0
        / LAG(monthly_revenue, 12) OVER (ORDER BY month),
        2
    ) as yoy_pct_change
FROM monthly_sales;
```

### Pattern 4: Cohort Analysis

```sql
-- Customer retention by cohort
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(purchase_date) as cohort_date
    FROM purchases
    GROUP BY customer_id
),
cohort_activity AS (
    SELECT
        fp.cohort_date,
        p.customer_id,
        DATE_TRUNC('month', p.purchase_date) as activity_month,
        EXTRACT(MONTH FROM AGE(p.purchase_date, fp.cohort_date)) as months_since_first
    FROM purchases p
    JOIN first_purchase fp ON p.customer_id = fp.customer_id
)
SELECT
    cohort_date,
    months_since_first,
    COUNT(DISTINCT customer_id) as active_customers,
    COUNT(DISTINCT customer_id) * 100.0 / FIRST_VALUE(COUNT(DISTINCT customer_id)) OVER (
        PARTITION BY cohort_date
        ORDER BY months_since_first
    ) as retention_pct
FROM cohort_activity
GROUP BY cohort_date, months_since_first
ORDER BY cohort_date, months_since_first;
```

### Pattern 5: Detecting Outliers

```sql
-- Find values more than 2 standard deviations from mean
WITH stats AS (
    SELECT
        product_id,
        sale_date,
        quantity,
        AVG(quantity) OVER (PARTITION BY product_id) as avg_qty,
        STDDEV(quantity) OVER (PARTITION BY product_id) as stddev_qty
    FROM sales
)
SELECT
    product_id,
    sale_date,
    quantity,
    avg_qty,
    CASE
        WHEN ABS(quantity - avg_qty) > 2 * stddev_qty THEN 'Outlier'
        ELSE 'Normal'
    END as classification
FROM stats
WHERE ABS(quantity - avg_qty) > 2 * stddev_qty;
```

---

## Summary

### Key Concepts

1. **Window functions preserve all rows** (unlike GROUP BY)
2. **PARTITION BY** divides data into groups
3. **ORDER BY** defines order within partitions
4. **Frame specifications** control which rows to include
5. **Named windows** improve readability and performance

### Function Categories

| Category | Functions | Use Case |
|----------|-----------|----------|
| **Aggregate** | SUM, AVG, COUNT, MIN, MAX | Running totals, moving averages |
| **Ranking** | RANK, DENSE_RANK, ROW_NUMBER | Top N, rankings, de-duplication |
| **Value** | FIRST_VALUE, LAST_VALUE, NTH_VALUE | Comparisons, reference values |
| **Offset** | LAG, LEAD | Time series, change analysis |

### Best Practices

1. **Index** partition and order columns
2. **Filter early** before windowing when possible
3. **Reuse window definitions** with WINDOW clause
4. **Choose appropriate frames** for your calculations
5. **Use CTEs** to break complex queries into steps
6. **Test performance** on realistic data volumes

### Common Mistakes to Avoid

1. ❌ Forgetting frame specification for `LAST_VALUE()`
2. ❌ Using window functions in WHERE clause (use subquery/CTE)
3. ❌ Not partitioning when analyzing groups
4. ❌ Confusing ROWS vs RANGE
5. ❌ Over-using window functions when simple aggregation would work

Window functions are powerful tools for analytics, reporting, and complex data transformations. Master them to unlock advanced SQL capabilities!
