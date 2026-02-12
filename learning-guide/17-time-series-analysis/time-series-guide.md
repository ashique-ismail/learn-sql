# 17 - Time Series Analysis

## Overview

Time series analysis involves working with data points indexed in time order. This section covers essential techniques for analyzing temporal data patterns, trends, and anomalies commonly used in business analytics, IoT systems, and financial applications.

---

## What You'll Learn

### Core Concepts
- Time series data fundamentals
- Temporal aggregations and grouping
- Gap detection and filling
- Moving averages and rolling calculations
- Seasonal pattern analysis
- Cumulative metrics over time

### PostgreSQL Features
- `generate_series()` for time ranges
- `date_trunc()` for time bucketing
- Window functions with time-based ordering
- `LAG()` and `LEAD()` for temporal comparisons
- Interval arithmetic
- Time zone handling

---

## Problems (7 total)

### 01 - Time Series Basics ⭐⭐⭐
**Concepts:** Time series fundamentals, temporal data types
- Understanding timestamp vs date
- Creating time series datasets
- Basic temporal queries

### 02 - Date Aggregations ⭐⭐⭐
**Concepts:** Grouping by time periods
- Daily, weekly, monthly aggregations
- `date_trunc()` for bucketing
- Time-based GROUP BY

### 03 - Time Windows ⭐⭐⭐
**Concepts:** Sliding and tumbling windows
- Window functions with time ranges
- `ROWS BETWEEN` with temporal data
- Rolling calculations

### 04 - Gap Detection ⭐⭐⭐
**Concepts:** Finding missing time periods
- `generate_series()` for expected ranges
- LEFT JOIN to find gaps
- Missing data identification

### 05 - Moving Averages Over Time ⭐⭐⭐⭐
**Concepts:** Temporal rolling calculations
- Moving averages (7-day, 30-day)
- Exponential smoothing
- Trend analysis

### 06 - Seasonal Analysis ⭐⭐⭐⭐
**Concepts:** Identifying periodic patterns
- Year-over-year comparisons
- Day of week patterns
- Seasonal decomposition

### 07 - Cumulative Metrics ⭐⭐⭐⭐
**Concepts:** Running totals over time
- Cumulative sums
- Year-to-date (YTD) calculations
- Growth rate analysis

---

## Key SQL Features Used

### Time Functions
```sql
-- Date truncation for bucketing
date_trunc('day', timestamp_column)
date_trunc('week', timestamp_column)
date_trunc('month', timestamp_column)

-- Extract components
EXTRACT(year FROM timestamp_column)
EXTRACT(dow FROM timestamp_column)  -- day of week

-- Generate time series
generate_series(
  '2024-01-01'::timestamp,
  '2024-12-31'::timestamp,
  '1 day'::interval
)
```

### Window Functions for Time Series
```sql
-- Moving average
AVG(value) OVER (
  ORDER BY timestamp
  ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
)

-- Lag/Lead for time comparisons
LAG(value, 1) OVER (ORDER BY timestamp)
LEAD(value, 1) OVER (ORDER BY timestamp)

-- Cumulative sum
SUM(value) OVER (ORDER BY timestamp)
```

---

## Real-World Applications

### Business Analytics
- Sales trends and forecasting
- Customer behavior over time
- Revenue growth analysis
- Churn rate tracking

### IoT & Monitoring
- Sensor data analysis
- System performance metrics
- Anomaly detection
- Downtime analysis

### Finance
- Stock price analysis
- Portfolio performance
- Trading volume patterns
- Risk metrics

### Web Analytics
- Traffic patterns
- User engagement trends
- Conversion rate analysis
- Session duration tracking

---

## Prerequisites

Before starting this section, you should be comfortable with:
- ✅ Window functions ([10-advanced-functions](../10-advanced-functions/))
- ✅ Date/time functions
- ✅ Aggregate queries ([05-aggregate-queries](../05-aggregate-queries/))
- ✅ Subqueries and CTEs ([09-subqueries](../09-subqueries/))

---

## Learning Path

### Recommended Order
1. Start with 01-time-series-basics
2. Master 02-date-aggregations
3. Practice 03-time-windows
4. Learn 04-gap-detection
5. Apply 05-moving-averages-time
6. Explore 06-seasonal-analysis
7. Complete 07-cumulative-metrics

### Time Estimate
- **Beginner to Intermediate:** 8-12 hours
- **Intermediate to Advanced:** 6-8 hours

---

## Practice Tips

1. **Use Real Data:** Work with actual time-stamped data
2. **Visualize Results:** Graph your time series queries
3. **Consider Time Zones:** Always be aware of timezone handling
4. **Test Edge Cases:** Month boundaries, leap years, DST changes
5. **Optimize for Scale:** Time series data grows quickly
6. **Index Timestamps:** Create indexes on time columns

---

## Common Patterns

### Daily Aggregation Pattern
```sql
SELECT
  date_trunc('day', created_at) AS day,
  COUNT(*) AS daily_count,
  SUM(amount) AS daily_total
FROM orders
GROUP BY day
ORDER BY day;
```

### Gap Detection Pattern
```sql
WITH expected_dates AS (
  SELECT generate_series(
    '2024-01-01'::date,
    '2024-12-31'::date,
    '1 day'::interval
  ) AS expected_date
)
SELECT ed.expected_date
FROM expected_dates ed
LEFT JOIN orders o ON ed.expected_date = o.order_date
WHERE o.order_date IS NULL;
```

### Moving Average Pattern
```sql
SELECT
  date,
  value,
  AVG(value) OVER (
    ORDER BY date
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) AS moving_avg_7day
FROM metrics
ORDER BY date;
```

---

## Performance Considerations

### Indexing Strategy
```sql
-- Index on timestamp columns
CREATE INDEX idx_orders_created_at ON orders(created_at);

-- Composite index for filtered time series
CREATE INDEX idx_orders_user_time ON orders(user_id, created_at);
```

### Partitioning for Large Datasets
```sql
-- Time-based partitioning
CREATE TABLE orders (
  id SERIAL,
  created_at TIMESTAMP,
  ...
) PARTITION BY RANGE (created_at);

CREATE TABLE orders_2024_01
PARTITION OF orders
FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

---

## Next Steps

After completing this section:
- Apply time series concepts to [Problems](../../problems/)
- Build a real-world analytics dashboard
- Explore advanced forecasting techniques
- Study time series databases (TimescaleDB)

---

**Ready to start?** → Begin with [01-time-series-basics](problems/01-time-series-basics/)

---

**Section:** 17 of 17
**Problems:** 7
**Difficulty:** ⭐⭐⭐ - ⭐⭐⭐⭐ (Advanced to Expert)
**Estimated Time:** 8-12 hours
