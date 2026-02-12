# Problem 07: Cumulative Metrics

## Difficulty: ⭐⭐⭐⭐ Expert

## Learning Objectives
- Calculate running totals over time
- Implement year-to-date (YTD) calculations
- Compute growth rates and percentage changes
- Track cumulative performance metrics

---

## Problem Statement

Calculate cumulative metrics for business analytics:
1. Running total of sales (cumulative revenue)
2. Year-to-date (YTD) sales by month
3. Month-over-month growth rate
4. Cumulative customer acquisition count
5. Running average order value

Implement cumulative calculations for tracking performance over time.

---

## Key Concepts

```sql
-- Running total
SUM(value) OVER (ORDER BY date) AS cumulative_sum

-- Year-to-date
SUM(value) OVER (
  PARTITION BY EXTRACT(YEAR FROM date)
  ORDER BY date
) AS ytd_total

-- Growth rate
(current_value - previous_value) / previous_value * 100
```

---

**Problem:** 07 of 07
**Estimated Time:** 90 minutes
