# Problem 02: Date Aggregations

## Difficulty: ⭐⭐⭐ Advanced

## Learning Objectives
- Master `date_trunc()` for time bucketing
- Aggregate data by various time periods (daily, weekly, monthly)
- Calculate time-based metrics
- Handle fiscal years and custom periods

---

## Problem Statement

Aggregate sales data by different time periods:
1. Daily total sales
2. Weekly revenue trends
3. Monthly sales with year-over-year comparison
4. Quarterly performance metrics

Use `date_trunc()` to bucket timestamps into periods and calculate aggregates.

---

## Key Concepts

- `date_trunc('day', timestamp)` - Round down to start of day
- `date_trunc('week', timestamp)` - Round to start of week (Monday)
- `date_trunc('month', timestamp)` - Round to first day of month
- `date_trunc('quarter', timestamp)` - Round to first day of quarter
- `date_trunc('year', timestamp)` - Round to January 1st

---

**Problem:** 02 of 07
**Estimated Time:** 45-60 minutes
