# Problem 01: Time Series Basics

## Difficulty: ⭐⭐⭐ Advanced

## Learning Objectives
- Understand time series data fundamentals
- Work with TIMESTAMP and DATE data types
- Perform basic temporal queries
- Handle time zones correctly

---

## Concept Review

### What is Time Series Data?

Time series data consists of observations recorded at specific time intervals:
- **Stock prices** tracked minute-by-minute
- **Sensor readings** collected every second
- **Sales transactions** recorded daily
- **Website visits** logged continuously

### Key Characteristics
1. **Temporal ordering** - Data has a natural time-based sequence
2. **Regular/irregular intervals** - Fixed (hourly) or variable (event-driven)
3. **Trends** - Long-term increases or decreases
4. **Seasonality** - Repeating patterns (daily, weekly, yearly)

### PostgreSQL Temporal Types

```sql
-- DATE: Just the date (no time)
'2024-01-15'::DATE

-- TIMESTAMP: Date + time (no timezone)
'2024-01-15 14:30:00'::TIMESTAMP

-- TIMESTAMPTZ: Date + time with timezone (recommended)
'2024-01-15 14:30:00+00'::TIMESTAMPTZ

-- INTERVAL: Duration
'1 day'::INTERVAL
'2 hours 30 minutes'::INTERVAL
```

---

## Problem Statement

You're analyzing an e-commerce platform's order data. Write queries to:

1. Find all orders placed in January 2024
2. Calculate the number of hours between order creation and shipment
3. Group orders by hour of the day to find peak ordering times
4. Find the first and last order of each day
5. Identify orders placed on weekends

### Sample Data

```sql
CREATE TABLE orders (
  order_id SERIAL PRIMARY KEY,
  customer_id INT NOT NULL,
  order_date TIMESTAMP NOT NULL,
  shipped_date TIMESTAMP,
  amount DECIMAL(10, 2),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Sample data
INSERT INTO orders (customer_id, order_date, shipped_date, amount) VALUES
(1, '2024-01-15 09:30:00', '2024-01-15 14:30:00', 150.00),
(2, '2024-01-15 10:45:00', '2024-01-16 09:00:00', 89.99),
(3, '2024-01-20 14:20:00', '2024-01-21 11:30:00', 299.50),
(1, '2024-01-20 15:30:00', NULL, 45.00),
(4, '2024-02-01 08:00:00', '2024-02-01 16:00:00', 175.25);
```

---

## Hints

<details>
<summary>Hint 1: Filtering by Date Range</summary>

Use date comparison operators:
```sql
WHERE order_date >= '2024-01-01' AND order_date < '2024-02-01'
```

Or use BETWEEN:
```sql
WHERE order_date BETWEEN '2024-01-01' AND '2024-01-31 23:59:59'
```
</details>

<details>
<summary>Hint 2: Time Difference</summary>

Use `AGE()` or subtraction to calculate intervals:
```sql
SELECT AGE(shipped_date, order_date)
-- or
SELECT shipped_date - order_date
```

Extract hours using `EXTRACT()`:
```sql
SELECT EXTRACT(EPOCH FROM (shipped_date - order_date)) / 3600 AS hours
```
</details>

<details>
<summary>Hint 3: Extract Hour of Day</summary>

```sql
SELECT EXTRACT(HOUR FROM order_date) AS hour_of_day
```
</details>

<details>
<summary>Hint 4: Weekend Detection</summary>

Use `EXTRACT(DOW ...)` where 0=Sunday, 6=Saturday:
```sql
WHERE EXTRACT(DOW FROM order_date) IN (0, 6)
```
</details>

---

## Solutions

### Solution 1: Orders in January 2024

```sql
-- Method 1: Using comparison operators
SELECT *
FROM orders
WHERE order_date >= '2024-01-01'::TIMESTAMP
  AND order_date < '2024-02-01'::TIMESTAMP;

-- Method 2: Using date_trunc
SELECT *
FROM orders
WHERE date_trunc('month', order_date) = '2024-01-01'::TIMESTAMP;

-- Method 3: Using EXTRACT
SELECT *
FROM orders
WHERE EXTRACT(YEAR FROM order_date) = 2024
  AND EXTRACT(MONTH FROM order_date) = 1;
```

**Output:**
```
order_id | customer_id | order_date           | shipped_date         | amount
---------|-------------|---------------------|---------------------|--------
1        | 1           | 2024-01-15 09:30:00 | 2024-01-15 14:30:00 | 150.00
2        | 2           | 2024-01-15 10:45:00 | 2024-01-16 09:00:00 | 89.99
3        | 3           | 2024-01-20 14:20:00 | 2024-01-21 11:30:00 | 299.50
4        | 1           | 2024-01-20 15:30:00 | NULL                | 45.00
```

### Solution 2: Hours Between Order and Shipment

```sql
SELECT
  order_id,
  order_date,
  shipped_date,
  shipped_date - order_date AS time_diff,
  ROUND(
    EXTRACT(EPOCH FROM (shipped_date - order_date)) / 3600,
    2
  ) AS hours_to_ship
FROM orders
WHERE shipped_date IS NOT NULL
ORDER BY hours_to_ship DESC;
```

**Output:**
```
order_id | order_date           | shipped_date         | time_diff | hours_to_ship
---------|---------------------|---------------------|-----------|---------------
2        | 2024-01-15 10:45:00 | 2024-01-16 09:00:00 | 22:15:00  | 22.25
3        | 2024-01-20 14:20:00 | 2024-01-21 11:30:00 | 21:10:00  | 21.17
5        | 2024-02-01 08:00:00 | 2024-02-01 16:00:00 | 08:00:00  | 8.00
1        | 2024-01-15 09:30:00 | 2024-01-15 14:30:00 | 05:00:00  | 5.00
```

### Solution 3: Peak Ordering Times (By Hour)

```sql
SELECT
  EXTRACT(HOUR FROM order_date) AS hour_of_day,
  COUNT(*) AS order_count,
  SUM(amount) AS total_revenue,
  ROUND(AVG(amount), 2) AS avg_order_value
FROM orders
GROUP BY hour_of_day
ORDER BY order_count DESC, hour_of_day;
```

**Output:**
```
hour_of_day | order_count | total_revenue | avg_order_value
------------|-------------|---------------|----------------
9           | 2           | 239.99        | 119.99
14          | 1           | 299.50        | 299.50
15          | 1           | 45.00         | 45.00
10          | 1           | 89.99         | 89.99
8           | 1           | 175.25        | 175.25
```

### Solution 4: First and Last Order Each Day

```sql
SELECT
  DATE(order_date) AS order_day,
  MIN(order_date) AS first_order,
  MAX(order_date) AS last_order,
  COUNT(*) AS order_count,
  MAX(order_date) - MIN(order_date) AS time_span
FROM orders
GROUP BY order_day
ORDER BY order_day;
```

**Output:**
```
order_day  | first_order          | last_order           | order_count | time_span
-----------|---------------------|---------------------|-------------|----------
2024-01-15 | 2024-01-15 09:30:00 | 2024-01-15 10:45:00 | 2           | 01:15:00
2024-01-20 | 2024-01-20 14:20:00 | 2024-01-20 15:30:00 | 2           | 01:10:00
2024-02-01 | 2024-02-01 08:00:00 | 2024-02-01 08:00:00 | 1           | 00:00:00
```

### Solution 5: Weekend Orders

```sql
SELECT
  order_id,
  order_date,
  CASE EXTRACT(DOW FROM order_date)
    WHEN 0 THEN 'Sunday'
    WHEN 6 THEN 'Saturday'
  END AS day_name,
  amount
FROM orders
WHERE EXTRACT(DOW FROM order_date) IN (0, 6)
ORDER BY order_date;
```

---

## Key Takeaways

1. **TIMESTAMP vs TIMESTAMPTZ**: Always use TIMESTAMPTZ for timezone awareness
2. **Interval Arithmetic**: Subtract timestamps to get intervals
3. **EXTRACT()**: Powerful function for extracting date/time components
4. **Date Boundaries**: Be careful with inclusive/exclusive ranges
5. **NULL Handling**: Always consider NULL timestamps in calculations

---

## Practice Variations

1. Find orders placed between 2 PM and 6 PM
2. Calculate average shipping time by day of week
3. Identify the busiest hour of each day
4. Find gaps of more than 24 hours between consecutive orders
5. Calculate month-over-month order growth

---

## Common Mistakes

❌ **Not handling NULL timestamps:**
```sql
-- Wrong: will return NULL if shipped_date is NULL
SELECT shipped_date - order_date FROM orders;

-- Right: filter out NULLs
SELECT shipped_date - order_date
FROM orders
WHERE shipped_date IS NOT NULL;
```

❌ **Incorrect date ranges:**
```sql
-- Wrong: Misses orders on Jan 31 after midnight
WHERE order_date BETWEEN '2024-01-01' AND '2024-01-31'

-- Right: Use exclusive upper bound
WHERE order_date >= '2024-01-01' AND order_date < '2024-02-01'
```

❌ **Ignoring time zones:**
```sql
-- Wrong: Assumes local timezone
SELECT * FROM orders WHERE order_date::DATE = '2024-01-15';

-- Right: Use explicit date functions
SELECT * FROM orders WHERE DATE(order_date) = '2024-01-15';
```

---

## Next Steps

After mastering time series basics, proceed to:
- **[02-date-aggregations](../02-date-aggregations/)** - Group data by time periods
- **[03-time-windows](../03-time-windows/)** - Sliding window calculations

---

**Problem:** 01 of 07
**Difficulty:** ⭐⭐⭐ Advanced
**Estimated Time:** 45-60 minutes
