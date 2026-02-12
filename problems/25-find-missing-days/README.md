# Problem 25: Find Missing Days

**Difficulty:** Advanced
**Concepts:** Generate series, Gaps analysis, Date sequences, LEFT JOIN, Anti-join patterns
**Phase:** Advanced Topics (Days 19-20)

---

## Learning Objectives

- Master generate_series() for creating date ranges
- Identify gaps in sequential data
- Use anti-join patterns (LEFT JOIN with NULL check)
- Work with date/time functions
- Analyze continuous vs discontinuous data
- Detect missing values in sequences

---

## Concept Summary

**Generate series** creates sequences of values (numbers, dates, timestamps). Combined with anti-joins, it's powerful for finding missing data, gaps in sequences, or ensuring continuous ranges.

### Syntax

```sql
-- Generate number series
SELECT generate_series(start, end, step) as num;
SELECT generate_series(1, 10) as num;           -- 1,2,3...10
SELECT generate_series(0, 100, 10) as num;      -- 0,10,20...100

-- Generate date series
SELECT generate_series(
    start_date,
    end_date,
    interval
)::date as date;

-- Examples
SELECT generate_series(
    '2024-01-01'::date,
    '2024-01-31'::date,
    '1 day'::interval
)::date as date;

-- Generate timestamp series
SELECT generate_series(
    '2024-01-01 00:00:00'::timestamp,
    '2024-01-01 23:00:00'::timestamp,
    '1 hour'::interval
) as hour;
```

### Gaps and Islands

**Gaps:** Missing values in a sequence
**Islands:** Continuous ranges of values

Common patterns:
1. Find missing dates
2. Find consecutive ranges
3. Identify breaks in continuity

---

## Problem Statement

**Task:** Find all dates in August 2023 where no sales were recorded. Show the date and identify consecutive gaps (how many days in a row had no sales).

**Given:**
- orders table: (id, customer_id, order_date, status, amount)

**Requirements:**
1. Generate all dates in August 2023
2. Identify dates with no orders
3. Group consecutive missing dates together
4. Show gap start, gap end, and duration

---

## Hint

Generate a series of all dates, LEFT JOIN with actual sales dates, and WHERE the join is NULL. Use window functions with gap detection to find consecutive ranges.

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

### Part 1: Find Missing Dates

```sql
-- Simple version: List all missing dates
WITH date_series AS (
    SELECT generate_series(
        '2023-08-01'::date,
        '2023-08-31'::date,
        '1 day'::interval
    )::date as sale_date
),
actual_sales AS (
    SELECT DISTINCT order_date as sale_date
    FROM orders
    WHERE order_date BETWEEN '2023-08-01' AND '2023-08-31'
)
SELECT
    ds.sale_date as missing_date
FROM date_series ds
LEFT JOIN actual_sales as ON ds.sale_date = as.sale_date
WHERE as.sale_date IS NULL
ORDER BY ds.sale_date;
```

### Part 2: Find Gaps with Duration

```sql
-- Complete solution with gap grouping
WITH date_series AS (
    SELECT generate_series(
        '2023-08-01'::date,
        '2023-08-31'::date,
        '1 day'::interval
    )::date as sale_date
),
actual_sales AS (
    SELECT DISTINCT order_date as sale_date
    FROM orders
    WHERE order_date BETWEEN '2023-08-01' AND '2023-08-31'
),
gaps AS (
    SELECT
        ds.sale_date,
        CASE WHEN as.sale_date IS NULL THEN 1 ELSE 0 END as is_gap
    FROM date_series ds
    LEFT JOIN actual_sales as ON ds.sale_date = as.sale_date
),
gap_groups AS (
    SELECT
        sale_date,
        is_gap,
        -- Create group ID by counting transitions
        SUM(CASE WHEN is_gap = 0 THEN 1 ELSE 0 END)
            OVER (ORDER BY sale_date) as group_id
    FROM gaps
)
SELECT
    MIN(sale_date) as gap_start,
    MAX(sale_date) as gap_end,
    COUNT(*) as days_without_sales
FROM gap_groups
WHERE is_gap = 1
GROUP BY group_id
ORDER BY gap_start;
```

### Explanation

1. **date_series CTE:** Generates all dates in August 2023
2. **actual_sales CTE:** Gets distinct order dates from orders table
3. **LEFT JOIN:** Matches generated dates with actual sales
4. **WHERE ... IS NULL:** Identifies dates with no sales (the gap)
5. **gap_groups:** Uses window function to group consecutive missing dates
6. **Final SELECT:** Aggregates consecutive gaps

### Alternative Solutions

```sql
-- Method 2: Using NOT EXISTS (more efficient for large datasets)
WITH date_series AS (
    SELECT generate_series(
        '2023-08-01'::date,
        '2023-08-31'::date,
        '1 day'::interval
    )::date as sale_date
)
SELECT sale_date as missing_date
FROM date_series ds
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.order_date = ds.sale_date
)
ORDER BY sale_date;

-- Method 3: Using EXCEPT (PostgreSQL)
WITH date_series AS (
    SELECT generate_series(
        '2023-08-01'::date,
        '2023-08-31'::date,
        '1 day'::interval
    )::date as sale_date
)
SELECT sale_date as missing_date
FROM date_series

EXCEPT

SELECT DISTINCT order_date
FROM orders
WHERE order_date BETWEEN '2023-08-01' AND '2023-08-31'

ORDER BY missing_date;

-- Method 4: Gap detection with LAG
WITH date_series AS (
    SELECT generate_series(
        '2023-08-01'::date,
        '2023-08-31'::date,
        '1 day'::interval
    )::date as sale_date
),
sales_with_gaps AS (
    SELECT
        ds.sale_date,
        as.sale_date IS NOT NULL as has_sale
    FROM date_series ds
    LEFT JOIN (
        SELECT DISTINCT order_date as sale_date FROM orders
    ) as ON ds.sale_date = as.sale_date
),
gap_detection AS (
    SELECT
        sale_date,
        has_sale,
        LAG(has_sale) OVER (ORDER BY sale_date) as prev_has_sale,
        -- Start of new gap
        CASE
            WHEN has_sale = false AND
                 (LAG(has_sale) OVER (ORDER BY sale_date) = true
                  OR LAG(has_sale) OVER (ORDER BY sale_date) IS NULL)
            THEN 1
            ELSE 0
        END as gap_start
    FROM sales_with_gaps
)
SELECT
    sale_date as missing_date,
    SUM(gap_start) OVER (ORDER BY sale_date) as gap_number
FROM gap_detection
WHERE has_sale = false
ORDER BY sale_date;
```

---

## Try These Variations

1. Find missing hours in a day (hourly sales data)
2. Find products never ordered
3. Find employees with no project assignments
4. Generate a calendar with weekday names
5. Find gaps in sequential IDs
6. Find overlapping date ranges
7. Create a monthly sales summary filling in zero for missing months

### Solutions to Variations

```sql
-- 1. Missing hours (24-hour period)
WITH hour_series AS (
    SELECT generate_series(
        '2024-01-15 00:00:00'::timestamp,
        '2024-01-15 23:00:00'::timestamp,
        '1 hour'::interval
    ) as hour
),
actual_sales AS (
    SELECT DISTINCT DATE_TRUNC('hour', order_date) as hour
    FROM orders
    WHERE order_date >= '2024-01-15 00:00:00'
      AND order_date < '2024-01-16 00:00:00'
)
SELECT
    TO_CHAR(hs.hour, 'YYYY-MM-DD HH24:00') as missing_hour
FROM hour_series hs
LEFT JOIN actual_sales as ON hs.hour = as.hour
WHERE as.hour IS NULL
ORDER BY hs.hour;

-- 2. Products never ordered
SELECT
    p.id,
    p.name,
    p.category,
    p.price
FROM products p
WHERE NOT EXISTS (
    SELECT 1
    FROM order_items oi
    WHERE oi.product_id = p.id
)
ORDER BY p.category, p.name;

-- Alternative with LEFT JOIN
SELECT
    p.id,
    p.name,
    p.category,
    p.price
FROM products p
LEFT JOIN order_items oi ON p.id = oi.product_id
WHERE oi.id IS NULL
ORDER BY p.category, p.name;

-- 3. Employees with no projects
SELECT
    e.id,
    e.name,
    e.department,
    e.hire_date
FROM employees e
WHERE NOT EXISTS (
    SELECT 1
    FROM project_assignments pa
    WHERE pa.employee_id = e.id
)
ORDER BY e.department, e.name;

-- 4. Calendar with weekday names
WITH date_series AS (
    SELECT generate_series(
        '2024-01-01'::date,
        '2024-01-31'::date,
        '1 day'::interval
    )::date as date
)
SELECT
    date,
    TO_CHAR(date, 'Day') as weekday,
    TO_CHAR(date, 'Dy') as weekday_short,
    EXTRACT(DOW FROM date) as day_of_week_number,
    CASE
        WHEN EXTRACT(DOW FROM date) IN (0, 6) THEN 'Weekend'
        ELSE 'Weekday'
    END as day_type,
    COALESCE(daily_sales.order_count, 0) as orders,
    COALESCE(daily_sales.total_amount, 0) as revenue
FROM date_series ds
LEFT JOIN (
    SELECT
        order_date,
        COUNT(*) as order_count,
        SUM(amount) as total_amount
    FROM orders
    WHERE order_date BETWEEN '2024-01-01' AND '2024-01-31'
    GROUP BY order_date
) daily_sales ON ds.date = daily_sales.order_date
ORDER BY date;

-- 5. Missing IDs in sequence
WITH id_series AS (
    SELECT generate_series(
        (SELECT MIN(id) FROM orders),
        (SELECT MAX(id) FROM orders)
    ) as id
)
SELECT id as missing_id
FROM id_series
WHERE id NOT IN (SELECT id FROM orders)
ORDER BY id;

-- Or for specific range
WITH id_series AS (
    SELECT generate_series(1, 10000) as id
)
SELECT id as missing_id
FROM id_series
WHERE NOT EXISTS (
    SELECT 1 FROM orders WHERE orders.id = id_series.id
)
ORDER BY id
LIMIT 100;  -- Show first 100 missing IDs

-- 6. Overlapping date ranges
WITH booking_overlaps AS (
    SELECT
        b1.id as booking1_id,
        b1.start_date as start1,
        b1.end_date as end1,
        b2.id as booking2_id,
        b2.start_date as start2,
        b2.end_date as end2
    FROM bookings b1
    JOIN bookings b2 ON b1.room_id = b2.room_id
        AND b1.id < b2.id  -- Avoid duplicates
        AND b1.start_date <= b2.end_date
        AND b1.end_date >= b2.start_date
)
SELECT * FROM booking_overlaps
ORDER BY start1;

-- 7. Monthly summary with missing months filled
WITH month_series AS (
    SELECT generate_series(
        '2023-01-01'::date,
        '2023-12-01'::date,
        '1 month'::interval
    )::date as month
)
SELECT
    TO_CHAR(ms.month, 'YYYY-MM') as month,
    TO_CHAR(ms.month, 'Month') as month_name,
    COALESCE(monthly_sales.order_count, 0) as orders,
    COALESCE(monthly_sales.total_revenue, 0) as revenue,
    COALESCE(monthly_sales.unique_customers, 0) as customers
FROM month_series ms
LEFT JOIN (
    SELECT
        DATE_TRUNC('month', order_date) as month,
        COUNT(*) as order_count,
        SUM(amount) as total_revenue,
        COUNT(DISTINCT customer_id) as unique_customers
    FROM orders
    WHERE EXTRACT(YEAR FROM order_date) = 2023
    GROUP BY DATE_TRUNC('month', order_date)
) monthly_sales ON ms.month = monthly_sales.month
ORDER BY ms.month;
```

---

## Sample Output

### Part 1: Missing Dates
```
 missing_date
--------------
 2023-08-03
 2023-08-04
 2023-08-05
 2023-08-15
 2023-08-16
 2023-08-27
```

### Part 2: Gaps with Duration
```
 gap_start  |  gap_end   | days_without_sales
------------+------------+-------------------
 2023-08-03 | 2023-08-05 |         3
 2023-08-15 | 2023-08-16 |         2
 2023-08-27 | 2023-08-27 |         1
```

---

## Common Mistakes

1. **Forgetting to cast to date:**
   ```sql
   -- WRONG: Returns timestamp
   SELECT generate_series('2023-01-01', '2023-01-31', '1 day');

   -- CORRECT: Cast to date
   SELECT generate_series(
       '2023-01-01'::date,
       '2023-01-31'::date,
       '1 day'::interval
   )::date;
   ```

2. **Boundary issues:**
   - BETWEEN is inclusive on both ends
   - Be careful with timestamp precision
   ```sql
   -- Correct for full day inclusion
   WHERE order_date >= '2023-08-01'
     AND order_date < '2023-09-01'
   ```

3. **Not handling time zones:**
   ```sql
   -- Be explicit about time zones
   SELECT generate_series(
       '2023-01-01 00:00:00'::timestamp AT TIME ZONE 'UTC',
       '2023-01-31 23:59:59'::timestamp AT TIME ZONE 'UTC',
       '1 hour'::interval
   );
   ```

4. **Performance on large ranges:**
   - generate_series can create millions of rows
   - Use appropriate date ranges
   - Consider indexing

5. **Incorrect gap grouping:**
   - Need to properly identify gap boundaries
   - Use window functions to detect transitions

6. **DISTINCT without considering time:**
   ```sql
   -- WRONG: Might miss multiple orders same day
   SELECT DISTINCT order_date FROM orders;

   -- CORRECT: Already handles multiple orders per day
   SELECT DISTINCT DATE(order_timestamp) FROM orders;
   ```

---

## Advanced Gap Analysis Patterns

```sql
-- Pattern 1: Find largest gap
WITH date_series AS (
    SELECT generate_series(
        '2023-01-01'::date,
        '2023-12-31'::date,
        '1 day'::interval
    )::date as date
),
sales_dates AS (
    SELECT DISTINCT order_date FROM orders
    WHERE EXTRACT(YEAR FROM order_date) = 2023
),
all_dates AS (
    SELECT
        date,
        EXISTS(SELECT 1 FROM sales_dates WHERE order_date = date) as has_sale
    FROM date_series
),
gap_runs AS (
    SELECT
        date,
        has_sale,
        COUNT(*) FILTER (WHERE has_sale) OVER (ORDER BY date) as run_group
    FROM all_dates
)
SELECT
    MIN(date) as gap_start,
    MAX(date) as gap_end,
    MAX(date) - MIN(date) + 1 as gap_days
FROM gap_runs
WHERE has_sale = false
GROUP BY run_group
ORDER BY gap_days DESC
LIMIT 1;

-- Pattern 2: Business days only (exclude weekends)
WITH date_series AS (
    SELECT generate_series(
        '2023-08-01'::date,
        '2023-08-31'::date,
        '1 day'::interval
    )::date as date
)
SELECT date as missing_business_day
FROM date_series
WHERE EXTRACT(DOW FROM date) NOT IN (0, 6)  -- Not Sunday or Saturday
  AND NOT EXISTS (
      SELECT 1 FROM orders
      WHERE DATE(order_date) = date
  )
ORDER BY date;

-- Pattern 3: Moving window analysis (7-day gaps)
WITH date_series AS (
    SELECT generate_series(
        '2023-01-01'::date,
        '2023-12-31'::date,
        '1 day'::interval
    )::date as date
),
daily_sales AS (
    SELECT
        ds.date,
        COALESCE(COUNT(o.id), 0) as order_count
    FROM date_series ds
    LEFT JOIN orders o ON DATE(o.order_date) = ds.date
    GROUP BY ds.date
)
SELECT
    date,
    order_count,
    SUM(order_count) OVER (
        ORDER BY date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as orders_last_7_days,
    CASE
        WHEN SUM(order_count) OVER (
            ORDER BY date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) = 0 THEN 'Dead Period'
        WHEN SUM(order_count) OVER (
            ORDER BY date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) < 10 THEN 'Low Activity'
        ELSE 'Normal'
    END as activity_status
FROM daily_sales
ORDER BY date;

-- Pattern 4: Identify islands (consecutive ranges WITH data)
WITH date_series AS (
    SELECT DISTINCT DATE(order_date) as date
    FROM orders
    WHERE order_date >= '2023-01-01'
      AND order_date < '2024-01-01'
),
with_row_numbers AS (
    SELECT
        date,
        ROW_NUMBER() OVER (ORDER BY date) as rn,
        date - ROW_NUMBER() OVER (ORDER BY date) * INTERVAL '1 day' as group_date
    FROM date_series
)
SELECT
    MIN(date) as island_start,
    MAX(date) as island_end,
    MAX(date) - MIN(date) + 1 as consecutive_days,
    COUNT(*) as sale_days
FROM with_row_numbers
GROUP BY group_date
HAVING COUNT(*) >= 7  -- Only islands of 7+ days
ORDER BY consecutive_days DESC;
```

---

## Performance Optimization

```sql
-- 1. Index on date columns
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_date_status ON orders(order_date, status)
WHERE status = 'completed';

-- 2. Limit series range
-- Don't generate unnecessary dates
WITH date_series AS (
    SELECT generate_series(
        (SELECT DATE_TRUNC('month', MIN(order_date)) FROM orders),
        (SELECT DATE_TRUNC('month', MAX(order_date)) FROM orders) + INTERVAL '1 month',
        '1 day'::interval
    )::date as date
)
-- Rest of query...

-- 3. Use materialized view for frequently accessed gaps
CREATE MATERIALIZED VIEW daily_sales_calendar AS
WITH date_series AS (
    SELECT generate_series(
        '2020-01-01'::date,
        CURRENT_DATE,
        '1 day'::interval
    )::date as date
)
SELECT
    ds.date,
    COALESCE(COUNT(o.id), 0) as order_count,
    COALESCE(SUM(o.amount), 0) as total_amount
FROM date_series ds
LEFT JOIN orders o ON DATE(o.order_date) = ds.date
GROUP BY ds.date;

-- Refresh daily
REFRESH MATERIALIZED VIEW daily_sales_calendar;
```

---

## Real-World Use Cases

1. **Data quality:** Identify missing data points in time series
2. **Inventory:** Find dates with no stock movements
3. **Monitoring:** Detect system downtime or missing logs
4. **Compliance:** Ensure continuous data collection
5. **Analytics:** Fill gaps for complete reporting periods
6. **Scheduling:** Find available time slots
7. **Sensor data:** Identify sensor failures or missing readings

---

## Related Problems

- **Previous:** [Problem 24 - Top Products Per Category](../24-top-products-per-category/)
- **Next:** [Problem 26 - Salary Quartiles](../26-salary-quartiles/)
- **Related:** Problem 14 (Date Analysis), Problem 11 (Moving Average), Problem 28 (Retention Analysis)

---

## Notes

```
Your notes here:




```

---

[← Previous](../24-top-products-per-category/) | [Back to Overview](../../README.md) | [Next Problem →](../26-salary-quartiles/)
