# Problem 04: Gap Detection

## Difficulty: ⭐⭐⭐ Advanced

## Learning Objectives
- Use `generate_series()` to create expected date ranges
- Identify missing dates in time series
- Find gaps and continuity breaks
- Handle irregular time series data

---

## Problem Statement

Detect gaps in time series data:
1. Find dates with no sales transactions
2. Identify missing days in a continuous series
3. Detect gaps longer than N days
4. Fill missing dates with zero values

Use `generate_series()` to create expected date ranges and LEFT JOIN to find gaps.

---

## Key Concepts

```sql
-- Generate date series
SELECT generate_series(
  '2024-01-01'::date,
  '2024-12-31'::date,
  '1 day'::interval
) AS expected_date;

-- Find gaps
WITH expected AS (...)
SELECT e.expected_date
FROM expected e
LEFT JOIN actual a ON e.expected_date = a.actual_date
WHERE a.actual_date IS NULL;
```

---

**Problem:** 04 of 07
**Estimated Time:** 60 minutes
