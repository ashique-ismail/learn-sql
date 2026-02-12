# Problem 26: Salary Quartiles

**Difficulty:** Advanced
**Concepts:** Statistical functions, PERCENTILE_CONT, PERCENTILE_DISC, NTILE, Standard deviation, Variance
**Phase:** Advanced Topics (Days 19-20)

---

## Learning Objectives

- Master statistical aggregate functions
- Calculate percentiles and quartiles
- Use NTILE for bucketing data
- Understand continuous vs discrete percentiles
- Analyze data distribution
- Calculate standard deviation and variance
- Create statistical reports

---

## Concept Summary

**Statistical functions** in SQL allow you to perform advanced data analysis including percentiles, quartiles, standard deviation, and variance. These are essential for understanding data distribution.

### Syntax

```sql
-- Percentile functions (ordered-set aggregates)
PERCENTILE_CONT(fraction) WITHIN GROUP (ORDER BY column)  -- Continuous
PERCENTILE_DISC(fraction) WITHIN GROUP (ORDER BY column)  -- Discrete

-- Examples
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary)  -- Median (continuous)
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY salary)  -- Median (discrete)
PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY salary) -- 25th percentile
PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY salary) -- 75th percentile

-- Window function for quartiles
NTILE(n) OVER (ORDER BY column)  -- Divides into n equal buckets

-- Statistical aggregates
STDDEV(column)          -- Standard deviation (sample)
STDDEV_POP(column)      -- Standard deviation (population)
VARIANCE(column)        -- Variance (sample)
VAR_POP(column)         -- Variance (population)
CORR(col1, col2)        -- Correlation coefficient
```

### PERCENTILE_CONT vs PERCENTILE_DISC

| PERCENTILE_CONT | PERCENTILE_DISC |
|-----------------|-----------------|
| Continuous interpolation | Discrete (actual values) |
| Can return non-existing values | Returns actual data values |
| More accurate for distributions | Better for categorical data |
| Example: 50000.50 | Example: 50000 |

### Understanding Quartiles

- **Q1 (25th percentile):** Bottom 25% cutoff
- **Q2 (50th percentile):** Median - middle value
- **Q3 (75th percentile):** Top 25% cutoff
- **IQR (Interquartile Range):** Q3 - Q1

---

## Problem Statement

**Task:** Analyze salary distribution with comprehensive statistics:
1. Calculate 25th, 50th (median), 75th, and 95th percentiles
2. Calculate standard deviation and variance
3. Assign each employee to a quartile
4. Show which quartile each employee falls into
5. Provide per-department quartile analysis

**Given:**
- employees table: (id, name, department, salary, hire_date)

**Requirements:**
- Overall salary statistics
- Per-employee quartile assignment
- Department-level analysis
- Identify outliers

---

## Hint

Use PERCENTILE_CONT for overall statistics, NTILE(4) for assigning quartiles, and combine with window functions for department analysis.

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

### Part 1: Overall Statistics

```sql
SELECT
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY salary), 2) as percentile_25,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY salary), 2) as median,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY salary), 2) as percentile_75,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY salary), 2) as percentile_95,
    ROUND(STDDEV(salary), 2) as std_deviation,
    ROUND(VARIANCE(salary), 2) as variance,
    ROUND(AVG(salary), 2) as mean_salary,
    MIN(salary) as min_salary,
    MAX(salary) as max_salary,
    COUNT(*) as total_employees
FROM employees;
```

### Part 2: Employees with Quartiles

```sql
WITH salary_stats AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY salary) as q1,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY salary) as median,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY salary) as q3
    FROM employees
)
SELECT
    e.id,
    e.name,
    e.department,
    e.salary,
    NTILE(4) OVER (ORDER BY e.salary) as quartile_ntile,
    CASE
        WHEN e.salary <= ss.q1 THEN 'Q1 (Bottom 25%)'
        WHEN e.salary <= ss.median THEN 'Q2 (Below Median)'
        WHEN e.salary <= ss.q3 THEN 'Q3 (Above Median)'
        ELSE 'Q4 (Top 25%)'
    END as quartile_range,
    ROUND(e.salary - ss.median, 2) as diff_from_median,
    ROUND((e.salary - ss.median) * 100.0 / ss.median, 2) as pct_diff_from_median
FROM employees e
CROSS JOIN salary_stats ss
ORDER BY e.salary DESC;
```

### Part 3: Department-Level Quartile Analysis

```sql
SELECT
    department,
    COUNT(*) as emp_count,
    ROUND(MIN(salary), 2) as min_salary,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY salary), 2) as q1,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY salary), 2) as median,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY salary), 2) as q3,
    ROUND(MAX(salary), 2) as max_salary,
    ROUND(AVG(salary), 2) as mean_salary,
    ROUND(STDDEV(salary), 2) as std_dev,
    -- Interquartile Range
    ROUND(
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY salary) -
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY salary),
        2
    ) as iqr,
    -- Coefficient of Variation (std_dev / mean)
    ROUND(STDDEV(salary) / AVG(salary) * 100, 2) as coeff_variation
FROM employees
GROUP BY department
ORDER BY median DESC;
```

### Complete Solution

```sql
-- Comprehensive salary quartile analysis
WITH salary_stats AS (
    -- Overall statistics
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY salary) as q1,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY salary) as median,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY salary) as q3,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY salary) as p95,
        AVG(salary) as mean,
        STDDEV(salary) as std_dev
    FROM employees
),
employee_quartiles AS (
    SELECT
        e.id,
        e.name,
        e.department,
        e.salary,
        NTILE(4) OVER (ORDER BY e.salary) as quartile,
        NTILE(10) OVER (ORDER BY e.salary) as decile,
        PERCENT_RANK() OVER (ORDER BY e.salary) as percentile_rank,
        ss.q1,
        ss.median,
        ss.q3,
        ss.mean,
        ss.std_dev
    FROM employees e
    CROSS JOIN salary_stats ss
)
SELECT
    name,
    department,
    salary,
    quartile,
    decile,
    ROUND(percentile_rank * 100, 2) as percentile,
    CASE
        WHEN salary <= q1 THEN 'Q1 (Bottom 25%)'
        WHEN salary <= median THEN 'Q2 (Below Median)'
        WHEN salary <= q3 THEN 'Q3 (Above Median)'
        ELSE 'Q4 (Top 25%)'
    END as quartile_label,
    ROUND(salary - median, 2) as diff_from_median,
    ROUND((salary - mean) / std_dev, 2) as z_score,
    CASE
        WHEN ABS((salary - mean) / std_dev) > 2 THEN 'Outlier'
        WHEN ABS((salary - mean) / std_dev) > 1 THEN 'Unusual'
        ELSE 'Normal'
    END as distribution_status
FROM employee_quartiles
ORDER BY salary DESC;
```

---

## Alternative Approaches

```sql
-- Method 1: Multiple percentiles at once
SELECT
    PERCENTILE_CONT(ARRAY[0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.99])
        WITHIN GROUP (ORDER BY salary) as percentiles
FROM employees;

-- Returns array: {p10, p25, p50, p75, p90, p95, p99}

-- Method 2: Using MODE (most common value)
SELECT
    MODE() WITHIN GROUP (ORDER BY salary) as most_common_salary
FROM employees;

-- Method 3: Histogram (frequency distribution)
WITH salary_buckets AS (
    SELECT
        WIDTH_BUCKET(salary, 30000, 200000, 10) as bucket,
        COUNT(*) as frequency
    FROM employees
    GROUP BY bucket
)
SELECT
    bucket,
    30000 + (bucket - 1) * 17000 as range_start,
    30000 + bucket * 17000 as range_end,
    frequency,
    REPEAT('*', frequency::int) as histogram
FROM salary_buckets
ORDER BY bucket;

-- Method 4: Quartile summary by department
SELECT
    department,
    JSON_BUILD_OBJECT(
        'count', COUNT(*),
        'min', MIN(salary),
        'q1', PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY salary),
        'median', PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY salary),
        'q3', PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY salary),
        'max', MAX(salary),
        'mean', ROUND(AVG(salary), 2),
        'stddev', ROUND(STDDEV(salary), 2)
    ) as statistics
FROM employees
GROUP BY department;
```

---

## Try These Variations

1. Find employees whose salary is more than 2 standard deviations from mean
2. Calculate salary percentile rank for each employee
3. Create salary bands and count employees in each band
4. Compare department medians to overall median
5. Find the most balanced department (lowest coefficient of variation)
6. Calculate moving percentiles by hire date
7. Identify salary compression issues

### Solutions to Variations

```sql
-- 1. Outliers (>2 standard deviations)
WITH stats AS (
    SELECT
        AVG(salary) as mean,
        STDDEV(salary) as std_dev
    FROM employees
)
SELECT
    e.name,
    e.department,
    e.salary,
    s.mean,
    ROUND((e.salary - s.mean) / s.std_dev, 2) as z_score,
    CASE
        WHEN (e.salary - s.mean) / s.std_dev > 2 THEN 'High Outlier'
        WHEN (e.salary - s.mean) / s.std_dev < -2 THEN 'Low Outlier'
        ELSE 'Normal'
    END as status
FROM employees e
CROSS JOIN stats s
WHERE ABS((e.salary - s.mean) / s.std_dev) > 2
ORDER BY z_score DESC;

-- 2. Percentile rank for each employee
SELECT
    name,
    department,
    salary,
    ROUND(PERCENT_RANK() OVER (ORDER BY salary) * 100, 2) as percentile_rank,
    ROUND(CUME_DIST() OVER (ORDER BY salary) * 100, 2) as cumulative_dist,
    ROUND(PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) * 100, 2) as dept_percentile
FROM employees
ORDER BY salary DESC;

-- 3. Salary bands
WITH salary_bands AS (
    SELECT
        CASE
            WHEN salary < 50000 THEN '< 50K'
            WHEN salary < 75000 THEN '50K-75K'
            WHEN salary < 100000 THEN '75K-100K'
            WHEN salary < 150000 THEN '100K-150K'
            ELSE '150K+'
        END as salary_band,
        salary
    FROM employees
)
SELECT
    salary_band,
    COUNT(*) as employee_count,
    ROUND(AVG(salary), 2) as avg_salary,
    MIN(salary) as min_salary,
    MAX(salary) as max_salary,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM salary_bands
GROUP BY salary_band
ORDER BY MIN(salary);

-- 4. Department vs overall median
WITH overall_median AS (
    SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) as median
    FROM employees
),
dept_medians AS (
    SELECT
        department,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) as dept_median,
        COUNT(*) as emp_count
    FROM employees
    GROUP BY department
)
SELECT
    dm.department,
    dm.emp_count,
    ROUND(dm.dept_median, 2) as dept_median,
    ROUND(om.median, 2) as overall_median,
    ROUND(dm.dept_median - om.median, 2) as diff_from_overall,
    ROUND((dm.dept_median - om.median) * 100.0 / om.median, 2) as pct_diff,
    CASE
        WHEN dm.dept_median > om.median * 1.1 THEN 'Above Market'
        WHEN dm.dept_median < om.median * 0.9 THEN 'Below Market'
        ELSE 'Market Rate'
    END as market_position
FROM dept_medians dm
CROSS JOIN overall_median om
ORDER BY dm.dept_median DESC;

-- 5. Most balanced department (lowest CV)
SELECT
    department,
    COUNT(*) as emp_count,
    ROUND(AVG(salary), 2) as mean_salary,
    ROUND(STDDEV(salary), 2) as std_dev,
    ROUND(STDDEV(salary) / AVG(salary) * 100, 2) as coefficient_of_variation,
    CASE
        WHEN STDDEV(salary) / AVG(salary) < 0.15 THEN 'Very Uniform'
        WHEN STDDEV(salary) / AVG(salary) < 0.25 THEN 'Balanced'
        WHEN STDDEV(salary) / AVG(salary) < 0.35 THEN 'Varied'
        ELSE 'Highly Varied'
    END as distribution_type
FROM employees
GROUP BY department
HAVING COUNT(*) >= 5  -- At least 5 employees
ORDER BY coefficient_of_variation ASC;

-- 6. Moving percentiles by hire date
SELECT
    hire_date,
    name,
    salary,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary)
        OVER (
            ORDER BY hire_date
            ROWS BETWEEN 50 PRECEDING AND CURRENT ROW
        ), 2
    ) as rolling_median_50_hires,
    ROUND(AVG(salary) OVER (
        ORDER BY hire_date
        ROWS BETWEEN 50 PRECEDING AND CURRENT ROW
    ), 2) as rolling_avg_50_hires
FROM employees
ORDER BY hire_date DESC;

-- 7. Salary compression (newer employees paid similar to veterans)
WITH tenure_salary AS (
    SELECT
        e.name,
        e.salary,
        e.hire_date,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, e.hire_date)) as years_tenure,
        NTILE(4) OVER (ORDER BY hire_date) as tenure_quartile,
        NTILE(4) OVER (ORDER BY salary) as salary_quartile
    FROM employees
)
SELECT
    name,
    salary,
    years_tenure,
    tenure_quartile,
    salary_quartile,
    CASE
        WHEN tenure_quartile = 4 AND salary_quartile <= 2 THEN 'Compressed (veteran underpaid)'
        WHEN tenure_quartile <= 2 AND salary_quartile >= 3 THEN 'Inverted (new hire overpaid)'
        ELSE 'Normal'
    END as compression_status
FROM tenure_salary
WHERE (tenure_quartile = 4 AND salary_quartile <= 2)
   OR (tenure_quartile <= 2 AND salary_quartile >= 3)
ORDER BY compression_status, years_tenure DESC;
```

---

## Sample Output

### Overall Statistics
```
 percentile_25 |  median  | percentile_75 | percentile_95 | std_deviation | variance  | mean_salary | min_salary | max_salary
---------------+----------+---------------+---------------+---------------+-----------+-------------+------------+------------
      52500.00 | 68000.00 |      89000.00 |     142500.00 |      28456.32 | 809760000 |    71234.56 |   35000.00 |  165000.00
```

### Employee Quartiles
```
     name      | department  | salary  | quartile | percentile | quartile_label  | diff_from_median | z_score
---------------+-------------+---------+----------+------------+-----------------+------------------+---------
 Alice Johnson | Executive   | 165000  |    4     |    99.12   | Q4 (Top 25%)    |      97000.00    |   3.29
 Bob Smith     | Executive   | 142000  |    4     |    95.67   | Q4 (Top 25%)    |      74000.00    |   2.49
 Carol White   | Engineering | 95000   |    3     |    78.45   | Q3 (Above Med)  |      27000.00    |   0.84
 Dave Brown    | Engineering | 68000   |    2     |    50.23   | Q2 (Below Med)  |          0.00    |  -0.11
 Emma Davis    | Sales       | 52000   |    1     |    23.56   | Q1 (Bottom 25%) |     -16000.00    |  -0.68
```

### Department Analysis
```
 department  | emp_count | min_salary |    q1     |  median   |    q3     | max_salary | mean_salary | std_dev |   iqr    | coeff_variation
-------------+-----------+------------+-----------+-----------+-----------+------------+-------------+---------+----------+----------------
 Executive   |    15     |  125000.00 | 135000.00 | 145000.00 | 152000.00 |  165000.00 |   144500.00 | 11234.5 | 17000.00 |      7.78
 Engineering |    50     |   45000.00 |  62000.00 |  72000.00 |  88000.00 |  125000.00 |    73450.00 | 18567.3 | 26000.00 |     25.28
 Sales       |    30     |   38000.00 |  48000.00 |  56000.00 |  65000.00 |   82000.00 |    56780.00 | 12345.6 | 17000.00 |     21.75
```

---

## Common Mistakes

1. **Confusing PERCENTILE_CONT and PERCENTILE_DISC:**
   - CONT interpolates, DISC returns actual values
   - Use CONT for continuous data (salary, age)
   - Use DISC for discrete/categorical data

2. **Wrong percentile fraction:**
   - 25th percentile = 0.25 (not 25)
   - Median = 0.50 (not 50)

3. **Not using WITHIN GROUP:**
   ```sql
   -- WRONG
   SELECT PERCENTILE_CONT(0.5, salary) FROM employees;

   -- CORRECT
   SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary)
   FROM employees;
   ```

4. **Forgetting NTILE partition:**
   - NTILE without PARTITION BY is company-wide
   - Add PARTITION BY for per-department quartiles

5. **Sample vs population functions:**
   - STDDEV = sample standard deviation (n-1)
   - STDDEV_POP = population standard deviation (n)
   - Use STDDEV for samples, STDDEV_POP for entire population

6. **Z-score interpretation:**
   - |z| > 2: ~5% of data (unusual)
   - |z| > 3: ~0.3% of data (outlier)

---

## Statistical Concepts Reference

### Measures of Central Tendency
```sql
-- Mean (average)
SELECT AVG(salary) FROM employees;

-- Median (middle value)
SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) FROM employees;

-- Mode (most common)
SELECT MODE() WITHIN GROUP (ORDER BY salary) FROM employees;
```

### Measures of Spread
```sql
-- Range
SELECT MAX(salary) - MIN(salary) as range FROM employees;

-- Interquartile Range (IQR)
SELECT
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY salary) -
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY salary) as iqr
FROM employees;

-- Standard Deviation
SELECT STDDEV(salary) FROM employees;

-- Variance
SELECT VARIANCE(salary) FROM employees;

-- Coefficient of Variation (relative variability)
SELECT STDDEV(salary) / AVG(salary) * 100 as cv FROM employees;
```

### Distribution Analysis
```sql
-- Skewness (approximate)
WITH stats AS (
    SELECT
        AVG(salary) as mean,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) as median,
        STDDEV(salary) as std_dev
    FROM employees
)
SELECT
    CASE
        WHEN mean > median THEN 'Right-skewed (high outliers)'
        WHEN mean < median THEN 'Left-skewed (low outliers)'
        ELSE 'Symmetric'
    END as distribution_shape
FROM stats;
```

---

## Real-World Use Cases

1. **Compensation analysis:** Benchmark salaries against market
2. **Performance review:** Identify outliers for further review
3. **Budget planning:** Understand salary distribution for forecasting
4. **Pay equity:** Analyze compensation fairness across demographics
5. **Hiring strategy:** Set salary ranges based on percentiles
6. **Retention analysis:** Identify flight risks (below market)
7. **Executive reporting:** KPIs and distribution metrics

---

## Related Problems

- **Previous:** [Problem 25 - Find Missing Days](../25-find-missing-days/)
- **Next:** [Problem 27 - Multi-Table Update](../27-multi-table-update/)
- **Related:** Problem 10 (Window Functions), Problem 15 (CASE Expressions), Problem 30 (Dashboard)

---

## Notes

```
Your notes here:




```

---

[← Previous](../25-find-missing-days/) | [Back to Overview](../../README.md) | [Next Problem →](../27-multi-table-update/)
