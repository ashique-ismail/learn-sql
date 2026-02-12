# Problem 05: Moving Averages Over Time

## Difficulty: ⭐⭐⭐⭐ Expert

## Learning Objectives
- Calculate simple moving averages (SMA)
- Implement weighted moving averages
- Apply exponential smoothing concepts
- Analyze trends using moving averages

---

## Problem Statement

Calculate various moving averages for trend analysis:
1. Simple 7-day moving average of sales
2. 30-day weighted moving average
3. Moving average crossover signals (short-term vs long-term)
4. Identify uptrends and downtrends

Implement different averaging techniques to smooth time series data.

---

## Key Concepts

```sql
-- Simple moving average (SMA)
AVG(value) OVER (
  ORDER BY date
  ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
) AS sma_7

-- Weighted moving average
SUM(value * weight) OVER (...) / SUM(weight) OVER (...)
```

---

**Problem:** 05 of 07
**Estimated Time:** 90 minutes
