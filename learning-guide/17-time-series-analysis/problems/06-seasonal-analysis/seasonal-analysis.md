# Problem 06: Seasonal Analysis

## Difficulty: ⭐⭐⭐⭐ Expert

## Learning Objectives
- Identify seasonal patterns in time series
- Perform year-over-year (YoY) comparisons
- Analyze day-of-week and hour-of-day patterns
- Calculate seasonal indices

---

## Problem Statement

Analyze seasonal patterns in sales data:
1. Compare same month across different years (YoY)
2. Identify day-of-week patterns (weekday vs weekend)
3. Find peak hours for each day of the week
4. Calculate seasonal indices by month
5. Detect recurring patterns

Discover cyclical and seasonal trends in temporal data.

---

## Key Concepts

```sql
-- Year-over-year comparison
LAG(value, 12) OVER (ORDER BY month) AS same_month_last_year

-- Day of week patterns
EXTRACT(DOW FROM timestamp)

-- Seasonal decomposition
AVG(value) / overall_avg AS seasonal_index
```

---

**Problem:** 06 of 07
**Estimated Time:** 90 minutes
