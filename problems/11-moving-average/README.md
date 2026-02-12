# Problem 11: Moving Average

**Difficulty:** Intermediate
**Concepts:** Window frames, ROWS BETWEEN, Moving aggregates, Time series analysis
**Phase:** Advanced Querying (Days 7-9)

---

## Learning Objectives

- Master window frame specifications
- Calculate moving averages for time series data
- Use ROWS BETWEEN and RANGE BETWEEN
- Understand different frame types and their applications
- Apply sliding window calculations

---

## Concept Summary

**Window frames** define which rows are included in window function calculations relative to the current row.

### Syntax

```sql
-- Frame specifications
ROWS BETWEEN start AND end
RANGE BETWEEN start AND end

-- Common frames
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW     -- All previous + current
ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING     -- Current + all following
ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING             -- Previous, current, next
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW             -- 3-row moving window

-- Start/End options
UNBOUNDED PRECEDING   -- First row in partition
UNBOUNDED FOLLOWING   -- Last row in partition
CURRENT ROW          -- Current row
n PRECEDING          -- n rows before current
n FOLLOWING          -- n rows after current
```

### ROWS vs RANGE

| ROWS | RANGE |
|------|-------|
| Physical row positions | Logical value ranges |
| Exact row counts | Includes all rows with same value |
| More predictable | Better for handling ties |
| Generally faster | Database-dependent behavior |

---

## Problem Statement

**Given:** sales(month DATE, amount DECIMAL)

**Task:** Calculate 3-month moving average of sales. Show each month with its sales amount and the moving average.

---

## Hint

Use AVG() with ROWS BETWEEN to define a window of 2 preceding rows plus current row.

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

```sql
SELECT
    month,
    amount,
    AVG(amount) OVER (
        ORDER BY month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) as moving_avg_3month
FROM sales
ORDER BY month;
```

### Explanation

1. `AVG(amount) OVER (...)` - Calculates average within defined window
2. `ORDER BY month` - Orders rows chronologically for proper window
3. `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` - Defines 3-row window
4. For first month: avg of 1 value (only current)
5. For second month: avg of 2 values (1 preceding + current)
6. From third month on: avg of 3 values (2 preceding + current)

### Alternative Solutions

```sql
-- 7-day moving average
SELECT
    date,
    sales,
    AVG(sales) OVER (
        ORDER BY date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as moving_avg_7day
FROM daily_sales
ORDER BY date;

-- Centered moving average (previous, current, next)
SELECT
    month,
    amount,
    AVG(amount) OVER (
        ORDER BY month
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) as centered_avg
FROM sales
ORDER BY month;

-- Using RANGE for date-based window (PostgreSQL)
SELECT
    order_date,
    amount,
    AVG(amount) OVER (
        ORDER BY order_date
        RANGE BETWEEN INTERVAL '30 days' PRECEDING AND CURRENT ROW
    ) as rolling_30day_avg
FROM orders
ORDER BY order_date;

-- Multiple window aggregates
SELECT
    month,
    amount,
    AVG(amount) OVER w3 as ma_3month,
    AVG(amount) OVER w6 as ma_6month,
    SUM(amount) OVER w3 as rolling_sum_3month,
    MIN(amount) OVER w3 as min_3month,
    MAX(amount) OVER w3 as max_3month
FROM sales
WINDOW w3 AS (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),
       w6 AS (ORDER BY month ROWS BETWEEN 5 PRECEDING AND CURRENT ROW)
ORDER BY month;
```

---

## Try These Variations

1. Calculate 6-month moving average
2. Find months where sales exceeded 3-month moving average
3. Calculate moving sum instead of moving average
4. Create weighted moving average (more weight on recent months)
5. Calculate exponential moving average

### Solutions to Variations

```sql
-- 1. 6-month moving average
SELECT
    month,
    amount,
    AVG(amount) OVER (
        ORDER BY month
        ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
    ) as moving_avg_6month
FROM sales
ORDER BY month;

-- 2. Sales exceeding moving average
WITH moving_avg AS (
    SELECT
        month,
        amount,
        AVG(amount) OVER (
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as ma_3month
    FROM sales
)
SELECT
    month,
    amount,
    ma_3month,
    amount - ma_3month as diff
FROM moving_avg
WHERE amount > ma_3month
ORDER BY month;

-- 3. Moving sum
SELECT
    month,
    amount,
    SUM(amount) OVER (
        ORDER BY month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) as rolling_sum_3month
FROM sales
ORDER BY month;

-- 4. Weighted moving average (simple linear weights)
SELECT
    month,
    amount,
    (
        LAG(amount, 2) OVER (ORDER BY month) * 1 +
        LAG(amount, 1) OVER (ORDER BY month) * 2 +
        amount * 3
    ) / 6.0 as weighted_ma
FROM sales
ORDER BY month;

-- 5. Exponential moving average (simplified)
WITH recursive ema AS (
    SELECT
        month,
        amount,
        amount as ema_value,
        ROW_NUMBER() OVER (ORDER BY month) as rn
    FROM sales
    WHERE month = (SELECT MIN(month) FROM sales)

    UNION ALL

    SELECT
        s.month,
        s.amount,
        0.3 * s.amount + 0.7 * e.ema_value as ema_value,
        e.rn + 1
    FROM sales s
    JOIN ema e ON s.month > e.month
    WHERE s.month = (
        SELECT MIN(month) FROM sales WHERE month > e.month
    )
)
SELECT month, amount, ROUND(ema_value, 2) as ema
FROM ema
ORDER BY month;
```

---

## Sample Output

```
   month    | amount  | moving_avg_3month
------------+---------+-------------------
 2023-01-01 | 10000.00|     10000.00
 2023-02-01 | 12000.00|     11000.00
 2023-03-01 | 11000.00|     11000.00
 2023-04-01 | 13000.00|     12000.00
 2023-05-01 | 14000.00|     12666.67
 2023-06-01 | 12500.00|     13166.67
 2023-07-01 | 15000.00|     13833.33
 2023-08-01 | 16000.00|     14500.00
```

---

## Common Mistakes

1. **Wrong window size:** `ROWS BETWEEN 3 PRECEDING` includes 4 rows (3 + current)
2. **Missing ORDER BY:** Window frames require ordering
3. **Not handling edge cases:** First few rows have smaller windows
4. **Using RANGE instead of ROWS:** Different semantics can give unexpected results
5. **Forgetting to round:** Moving averages may need rounding for display
6. **Performance issues:** Large windows on big tables can be slow

---

## Frame Specification Examples

```sql
-- Different frame types demonstrated
SELECT
    month,
    amount,
    -- Running total (unbounded preceding)
    SUM(amount) OVER (
        ORDER BY month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as running_total,

    -- Fixed 3-month window
    AVG(amount) OVER (
        ORDER BY month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) as ma_3,

    -- Centered window
    AVG(amount) OVER (
        ORDER BY month
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) as centered_avg,

    -- Forward-looking window
    AVG(amount) OVER (
        ORDER BY month
        ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING
    ) as forward_avg,

    -- Full partition (no frame needed)
    AVG(amount) OVER (
        ORDER BY month
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as overall_avg
FROM sales
ORDER BY month;
```

---

## Performance Note

- Window functions with frames can be expensive on large datasets
- Indexes on ORDER BY columns improve performance
- Consider materialized views for frequently-used moving averages
- ROWS frames are generally faster than RANGE frames
- Multiple windows with same specification are optimized together

```sql
-- Efficient: Reuse window definition
SELECT
    month,
    amount,
    AVG(amount) OVER w as moving_avg,
    SUM(amount) OVER w as moving_sum,
    COUNT(*) OVER w as window_size
FROM sales
WINDOW w AS (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
ORDER BY month;
```

---

## Real-World Use Cases

1. **Financial analysis:** Stock price moving averages (MA50, MA200)
2. **Sales forecasting:** Trend analysis with smoothed data
3. **Website analytics:** Rolling 7-day active users
4. **Inventory management:** Moving average costs
5. **Quality control:** Rolling defect rates
6. **Weather analysis:** Temperature trends and anomaly detection

---

## Related Problems

- **Previous:** [Problem 10 - Salary Ranking](../10-salary-ranking/)
- **Next:** [Problem 12 - Salary Update](../12-salary-update/)
- **Related:** Problem 10 (Window Functions), Problem 14 (Date Analysis), Problem 26 (Statistical Functions)

---

## Notes

```
Your notes here:




```

---

[← Previous](../10-salary-ranking/) | [Back to Overview](../../README.md) | [Next Problem →](../12-salary-update/)
