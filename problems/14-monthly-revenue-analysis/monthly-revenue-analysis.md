# Problem 14: Monthly Revenue Analysis

**Difficulty:** Intermediate
**Concepts:** Date functions, DATE_TRUNC, EXTRACT, Date arithmetic, Time-based aggregation
**Phase:** Advanced Features (Days 14-16)

---

## Learning Objectives

- Master date and time functions
- Use DATE_TRUNC for time period grouping
- Extract date parts (year, month, day) from timestamps
- Perform date arithmetic and interval calculations
- Aggregate data by time periods
- Handle timezone considerations

---

## Concept Summary

**Date/Time functions** allow manipulation and extraction of temporal data for analysis.

### Syntax

```sql
-- Current date/time
CURRENT_DATE                    -- 2024-01-15
CURRENT_TIME                    -- 14:30:45.123456
CURRENT_TIMESTAMP               -- 2024-01-15 14:30:45.123456
NOW()                          -- Same as CURRENT_TIMESTAMP

-- Extract parts (PostgreSQL)
DATE_PART('year', date)        -- Extract year
EXTRACT(YEAR FROM date)        -- Same as DATE_PART
EXTRACT(MONTH FROM date)       -- Month (1-12)
EXTRACT(DAY FROM date)         -- Day of month
EXTRACT(DOW FROM date)         -- Day of week (0=Sunday)
EXTRACT(QUARTER FROM date)     -- Quarter (1-4)

-- Truncate to period (PostgreSQL)
DATE_TRUNC('month', timestamp) -- First day of month
DATE_TRUNC('year', timestamp)  -- First day of year
DATE_TRUNC('week', timestamp)  -- First day of week
DATE_TRUNC('day', timestamp)   -- Midnight of that day
DATE_TRUNC('hour', timestamp)  -- Start of hour
DATE_TRUNC('quarter', timestamp) -- First day of quarter

-- Date arithmetic (PostgreSQL)
date + INTERVAL '1 day'
date - INTERVAL '3 months'
date + INTERVAL '2 years'
timestamp + INTERVAL '1 hour 30 minutes'
AGE(timestamp1, timestamp2)    -- Interval between dates

-- Format dates
TO_CHAR(date, 'YYYY-MM-DD')
TO_CHAR(date, 'Month DD, YYYY')
TO_CHAR(date, 'Day')

-- MySQL equivalents
DATE_FORMAT(date, '%Y-%m-%d')
YEAR(date), MONTH(date), DAY(date)
DATE_ADD(date, INTERVAL 1 DAY)
DATE_SUB(date, INTERVAL 1 MONTH)
DATEDIFF(date1, date2)
```

---

## Problem Statement

**Given:** orders(order_id INTEGER, customer_id INTEGER, order_date DATE, amount DECIMAL)

**Task:** Find monthly revenue for the last 6 months. Show month, total revenue, number of orders, and average order value.

---

## Hint

Use DATE_TRUNC('month', order_date) to group by month, then aggregate with SUM, COUNT, and AVG.

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

```sql
-- PostgreSQL
SELECT
    DATE_TRUNC('month', order_date) as month,
    SUM(amount) as total_revenue,
    COUNT(*) as order_count,
    ROUND(AVG(amount), 2) as avg_order_value
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;

-- Alternative: Using EXTRACT for display
SELECT
    TO_CHAR(DATE_TRUNC('month', order_date), 'YYYY-MM') as month,
    SUM(amount) as total_revenue,
    COUNT(*) as order_count,
    ROUND(AVG(amount), 2) as avg_order_value
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY DATE_TRUNC('month', order_date);
```

### MySQL Version

```sql
SELECT
    DATE_FORMAT(order_date, '%Y-%m') as month,
    SUM(amount) as total_revenue,
    COUNT(*) as order_count,
    ROUND(AVG(amount), 2) as avg_order_value
FROM orders
WHERE order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 6 MONTH)
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;
```

### Explanation

1. `DATE_TRUNC('month', order_date)` - Truncates to first day of month
2. `WHERE order_date >= CURRENT_DATE - INTERVAL '6 months'` - Last 6 months
3. `GROUP BY DATE_TRUNC(...)` - Groups all orders in same month
4. `SUM(amount)` - Total revenue per month
5. `COUNT(*)` - Number of orders per month
6. `AVG(amount)` - Average order value per month

---

## Enhanced Solutions

```sql
-- With month-over-month growth
WITH monthly_stats AS (
    SELECT
        DATE_TRUNC('month', order_date) as month,
        SUM(amount) as revenue,
        COUNT(*) as orders
    FROM orders
    WHERE order_date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT
    TO_CHAR(month, 'YYYY-MM') as month,
    revenue,
    orders,
    LAG(revenue) OVER (ORDER BY month) as prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month)) /
        LAG(revenue) OVER (ORDER BY month) * 100,
        2
    ) as growth_rate_pct
FROM monthly_stats
ORDER BY month;

-- Daily revenue for current month
SELECT
    order_date::DATE as date,
    SUM(amount) as daily_revenue,
    COUNT(*) as orders,
    SUM(SUM(amount)) OVER (ORDER BY order_date::DATE) as running_total
FROM orders
WHERE DATE_TRUNC('month', order_date) = DATE_TRUNC('month', CURRENT_DATE)
GROUP BY order_date::DATE
ORDER BY order_date;

-- Quarterly analysis
SELECT
    EXTRACT(YEAR FROM order_date) as year,
    EXTRACT(QUARTER FROM order_date) as quarter,
    'Q' || EXTRACT(QUARTER FROM order_date) || ' ' || EXTRACT(YEAR FROM order_date) as period,
    SUM(amount) as revenue,
    COUNT(*) as orders,
    COUNT(DISTINCT customer_id) as unique_customers
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '2 years'
GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(QUARTER FROM order_date)
ORDER BY year, quarter;

-- Year-over-year comparison
SELECT
    EXTRACT(MONTH FROM order_date) as month_num,
    TO_CHAR(order_date, 'Month') as month_name,
    EXTRACT(YEAR FROM order_date) as year,
    SUM(amount) as revenue
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '2 years'
GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date), TO_CHAR(order_date, 'Month')
ORDER BY month_num, year;

-- Pivot for year-over-year
SELECT
    TO_CHAR(order_date, 'Month') as month,
    SUM(CASE WHEN EXTRACT(YEAR FROM order_date) = 2023 THEN amount ELSE 0 END) as revenue_2023,
    SUM(CASE WHEN EXTRACT(YEAR FROM order_date) = 2024 THEN amount ELSE 0 END) as revenue_2024,
    ROUND(
        (SUM(CASE WHEN EXTRACT(YEAR FROM order_date) = 2024 THEN amount ELSE 0 END) -
         SUM(CASE WHEN EXTRACT(YEAR FROM order_date) = 2023 THEN amount ELSE 0 END)) /
        NULLIF(SUM(CASE WHEN EXTRACT(YEAR FROM order_date) = 2023 THEN amount ELSE 0 END), 0) * 100,
        2
    ) as growth_pct
FROM orders
WHERE EXTRACT(YEAR FROM order_date) IN (2023, 2024)
GROUP BY EXTRACT(MONTH FROM order_date), TO_CHAR(order_date, 'Month')
ORDER BY EXTRACT(MONTH FROM order_date);
```

---

## Try These Variations

1. Find busiest day of week for orders
2. Calculate weekly revenue for last 12 weeks
3. Find months with revenue above average
4. Show revenue by hour of day
5. Calculate same-day-last-year comparison

### Solutions to Variations

```sql
-- 1. Busiest day of week
SELECT
    TO_CHAR(order_date, 'Day') as day_of_week,
    EXTRACT(DOW FROM order_date) as day_num,
    COUNT(*) as order_count,
    SUM(amount) as total_revenue
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '3 months'
GROUP BY EXTRACT(DOW FROM order_date), TO_CHAR(order_date, 'Day')
ORDER BY day_num;

-- 2. Weekly revenue
SELECT
    DATE_TRUNC('week', order_date) as week_start,
    TO_CHAR(DATE_TRUNC('week', order_date), 'YYYY-MM-DD') as week,
    SUM(amount) as weekly_revenue,
    COUNT(*) as orders
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '12 weeks'
GROUP BY DATE_TRUNC('week', order_date)
ORDER BY week_start;

-- 3. Above average months
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', order_date) as month,
        SUM(amount) as revenue
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT
    TO_CHAR(month, 'YYYY-MM') as month,
    revenue,
    (SELECT AVG(revenue) FROM monthly_revenue) as avg_revenue
FROM monthly_revenue
WHERE revenue > (SELECT AVG(revenue) FROM monthly_revenue)
ORDER BY month;

-- 4. Revenue by hour of day
SELECT
    EXTRACT(HOUR FROM order_timestamp) as hour,
    COUNT(*) as order_count,
    SUM(amount) as revenue,
    ROUND(AVG(amount), 2) as avg_order_value
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '1 month'
GROUP BY EXTRACT(HOUR FROM order_timestamp)
ORDER BY hour;

-- 5. Same-day-last-year comparison
SELECT
    o1.order_date as current_date,
    SUM(o1.amount) as current_revenue,
    (
        SELECT SUM(amount)
        FROM orders o2
        WHERE o2.order_date = o1.order_date - INTERVAL '1 year'
    ) as last_year_revenue,
    SUM(o1.amount) - COALESCE((
        SELECT SUM(amount)
        FROM orders o2
        WHERE o2.order_date = o1.order_date - INTERVAL '1 year'
    ), 0) as difference
FROM orders o1
WHERE o1.order_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY o1.order_date
ORDER BY o1.order_date;
```

---

## Sample Output

```
    month    | total_revenue | order_count | avg_order_value
-------------+---------------+-------------+-----------------
 2023-08-01  |    245000.00  |     156     |     1570.51
 2023-09-01  |    267500.00  |     178     |     1502.81
 2023-10-01  |    298000.00  |     192     |     1552.08
 2023-11-01  |    312000.00  |     205     |     1521.95
 2023-12-01  |    385000.00  |     248     |     1552.42
 2024-01-01  |    178000.00  |     112     |     1589.29
(6 rows)
```

---

## Common Mistakes

1. **Forgetting timezone:** CURRENT_TIMESTAMP vs CURRENT_DATE
   ```sql
   -- May exclude today if using timestamp comparison
   WHERE order_timestamp >= CURRENT_DATE - INTERVAL '30 days'
   ```

2. **Wrong date arithmetic:**
   ```sql
   -- Wrong: Subtracts 6 days, not 6 months
   WHERE order_date >= CURRENT_DATE - 6

   -- Correct:
   WHERE order_date >= CURRENT_DATE - INTERVAL '6 months'
   ```

3. **GROUP BY mismatch:**
   ```sql
   -- Error: Must GROUP BY exact expression used in SELECT
   SELECT DATE_TRUNC('month', order_date), SUM(amount)
   FROM orders
   GROUP BY order_date;  -- Wrong!
   ```

4. **Not handling NULL dates:**
   ```sql
   -- May return unexpected results
   SELECT COUNT(*) FROM orders WHERE order_date > '2023-01-01';
   -- NULLs are excluded
   ```

5. **Incorrect date formats:**
   ```sql
   -- Ambiguous: Is this Jan 2 or Feb 1?
   WHERE order_date = '01/02/2023'
   -- Use: '2023-01-02' (ISO 8601)
   ```

6. **Timezone issues:** Especially with international data

---

## Date Arithmetic Examples

```sql
-- Add/subtract intervals
SELECT
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '1 day' as tomorrow,
    CURRENT_DATE - INTERVAL '1 week' as last_week,
    CURRENT_DATE + INTERVAL '3 months' as in_3_months,
    CURRENT_DATE - INTERVAL '1 year' as last_year;

-- Calculate age
SELECT
    name,
    birth_date,
    AGE(birth_date) as age,
    EXTRACT(YEAR FROM AGE(birth_date)) as age_years
FROM people;

-- Days between dates
SELECT
    order_date,
    ship_date,
    ship_date - order_date as days_to_ship,
    AGE(ship_date, order_date) as time_to_ship
FROM orders;

-- First and last day of month
SELECT
    DATE_TRUNC('month', CURRENT_DATE) as first_day_of_month,
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day' as last_day_of_month;

-- Generate date series
SELECT generate_series(
    '2024-01-01'::date,
    '2024-12-31'::date,
    '1 day'::interval
)::date as date;
```

---

## Performance Note

- Index date columns used in WHERE and GROUP BY
- `DATE_TRUNC` on indexed column can prevent index usage
- Consider computed columns or materialized views for common truncations
- Partitioning by date range can improve performance on large tables

```sql
-- Index on date column
CREATE INDEX idx_orders_date ON orders(order_date);

-- Partial index for recent data
CREATE INDEX idx_orders_recent ON orders(order_date)
WHERE order_date >= CURRENT_DATE - INTERVAL '1 year';

-- Index on extracted part (PostgreSQL)
CREATE INDEX idx_orders_month ON orders(DATE_TRUNC('month', order_date));
```

---

## Real-World Use Cases

1. **Sales reports:** Daily, weekly, monthly, quarterly revenue
2. **Trend analysis:** Year-over-year, month-over-month growth
3. **Seasonality detection:** Identify peak and slow periods
4. **Business metrics:** Average order value by time period
5. **Forecasting:** Based on historical time-series data
6. **SLA monitoring:** Time-based service level agreements

---

## Related Problems

- **Previous:** [Problem 13 - Library Schema Design](../13-library-schema-design/)
- **Next:** [Problem 15 - Categorize Salaries](../15-categorize-salaries/)
- **Related:** Problem 11 (Moving Average), Problem 20 (E-commerce Analytics), Problem 25 (Missing Days)

---

## Notes

```
Your notes here:




```

---

[← Previous](../13-library-schema-design/) | [Back to Overview](../../README.md) | [Next Problem →](../15-categorize-salaries/)
