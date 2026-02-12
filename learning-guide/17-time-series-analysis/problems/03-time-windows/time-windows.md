# Problem 03: Time Windows

## Difficulty: ⭐⭐⭐ Advanced

## Learning Objectives
- Use window functions with temporal ordering
- Implement sliding time windows
- Calculate rolling statistics
- Apply `ROWS BETWEEN` with time-based data

---

## Problem Statement

Calculate rolling metrics for time series data:
1. 7-day rolling average of daily sales
2. 30-day rolling sum of orders
3. Compare current day to previous day (day-over-day change)
4. Find running maximum over time

Use window functions with time-based ordering and frame specifications.

---

## Key Concepts

```sql
-- Rolling average
AVG(value) OVER (
  ORDER BY date
  ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
)

-- Running total
SUM(value) OVER (ORDER BY date)

-- Day-over-day comparison
LAG(value) OVER (ORDER BY date)
```

---

**Problem:** 03 of 07
**Estimated Time:** 60 minutes
