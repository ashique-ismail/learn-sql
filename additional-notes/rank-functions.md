# SQL Ranking Functions - Complete Guide

## Table of Contents
1. [Introduction](#introduction)
2. [The Three Main Ranking Functions](#the-three-main-ranking-functions)
3. [RANK()](#rank)
4. [DENSE_RANK()](#dense_rank)
5. [ROW_NUMBER()](#row_number)
6. [Comparison Chart](#comparison-chart)
7. [Advanced Examples](#advanced-examples)
8. [Other Ranking Functions](#other-ranking-functions)
9. [Common Use Cases](#common-use-cases)
10. [Performance Tips](#performance-tips)

---

## Introduction

SQL ranking functions are **window functions** that assign a rank or sequential number to rows within a result set. They're essential for:
- Finding top N records
- Removing duplicates
- Numbering rows within groups
- Calculating percentiles and distributions

**Basic Syntax:**
```sql
RANKING_FUNCTION() OVER (
    [PARTITION BY column1, column2, ...]
    ORDER BY column3 [ASC|DESC]
)
```

---

## The Three Main Ranking Functions

### Quick Overview

| Function | Handles Ties? | Gaps After Ties? | Always Unique? |
|----------|---------------|------------------|----------------|
| `RANK()` | Yes (same rank) | Yes | No |
| `DENSE_RANK()` | Yes (same rank) | No | No |
| `ROW_NUMBER()` | No (arbitrary order) | N/A | Yes |

---

## RANK()

### Description
Assigns ranks to rows with **gaps** after tied values. If two rows tie for rank 2, the next rank is 4 (skipping 3).

### Syntax
```sql
RANK() OVER (
    [PARTITION BY partition_columns]
    ORDER BY order_columns
)
```

### Example Dataset
```sql
CREATE TABLE students (
    student_id INT,
    name VARCHAR(50),
    class VARCHAR(20),
    score INT
);

INSERT INTO students VALUES
(1, 'Alice', 'Math', 95),
(2, 'Bob', 'Math', 90),
(3, 'Carol', 'Math', 90),
(4, 'Dave', 'Math', 85),
(5, 'Eve', 'Science', 98),
(6, 'Frank', 'Science', 95),
(7, 'Grace', 'Science', 95),
(8, 'Henry', 'Science', 92);
```

### Basic RANK() Example
```sql
SELECT name, class, score,
       RANK() OVER (ORDER BY score DESC) as overall_rank
FROM students;
```

**Result:**
| name  | class   | score | overall_rank |
|-------|---------|-------|--------------|
| Eve   | Science | 98    | 1            |
| Alice | Math    | 95    | 2            |
| Frank | Science | 95    | 2            |
| Grace | Science | 95    | 2            |
| Henry | Science | 92    | **5**        | ← Gap! (skipped 3 and 4)
| Bob   | Math    | 90    | 6            |
| Carol | Math    | 90    | 6            |
| Dave  | Math    | 85    | **8**        | ← Gap! (skipped 7)

**Notice:**
- Three students tied at rank 2 (score 95)
- Next rank is 5 (not 3) - gaps of 3 and 4
- Two students tied at rank 6 (score 90)
- Next rank is 8 (not 7) - gap of 7

### RANK() with PARTITION BY
```sql
SELECT name, class, score,
       RANK() OVER (PARTITION BY class ORDER BY score DESC) as class_rank
FROM students
ORDER BY class, class_rank;
```

**Result:**
| name  | class   | score | class_rank |
|-------|---------|-------|------------|
| Alice | Math    | 95    | 1          |
| Bob   | Math    | 90    | 2          |
| Carol | Math    | 90    | 2          |
| Dave  | Math    | 85    | **4**      | ← Gap after tie
| Eve   | Science | 98    | 1          |
| Frank | Science | 95    | 2          |
| Grace | Science | 95    | 2          |
| Henry | Science | 92    | **4**      | ← Gap after tie

### When to Use RANK()
- ✅ **Standard competition ranking** (like Olympic medals: gold, silver, bronze)
- ✅ When you want to show **how many people performed better**
- ✅ Top N queries where ties should count against the limit
- ❌ When you need consecutive numbers (use ROW_NUMBER)
- ❌ When gaps are confusing for users (use DENSE_RANK)

---

## DENSE_RANK()

### Description
Assigns ranks to rows **without gaps**. If two rows tie for rank 2, the next rank is 3 (no skipping).

### Syntax
```sql
DENSE_RANK() OVER (
    [PARTITION BY partition_columns]
    ORDER BY order_columns
)
```

### Basic DENSE_RANK() Example
```sql
SELECT name, class, score,
       DENSE_RANK() OVER (ORDER BY score DESC) as overall_dense_rank
FROM students;
```

**Result:**
| name  | class   | score | overall_dense_rank |
|-------|---------|-------|--------------------|
| Eve   | Science | 98    | 1                  |
| Alice | Math    | 95    | 2                  |
| Frank | Science | 95    | 2                  |
| Grace | Science | 95    | 2                  |
| Henry | Science | 92    | **3**              | ← No gap!
| Bob   | Math    | 90    | 4                  |
| Carol | Math    | 90    | 4                  |
| Dave  | Math    | 85    | **5**              | ← No gap!

**Notice:**
- Three students tied at rank 2 (score 95)
- Next rank is 3 (continuous) - no gaps
- Ranks represent **distinct score values**, not position

### Comparison: RANK() vs DENSE_RANK()
```sql
SELECT name, score,
       RANK() OVER (ORDER BY score DESC) as rank,
       DENSE_RANK() OVER (ORDER BY score DESC) as dense_rank
FROM students;
```

**Result:**
| name  | score | rank | dense_rank |
|-------|-------|------|------------|
| Eve   | 98    | 1    | 1          |
| Alice | 95    | 2    | 2          |
| Frank | 95    | 2    | 2          |
| Grace | 95    | 2    | 2          |
| Henry | 92    | 5    | **3**      | ← Key difference
| Bob   | 90    | 6    | **4**      |
| Carol | 90    | 6    | **4**      |
| Dave  | 85    | 8    | **5**      |

### DENSE_RANK() with PARTITION BY
```sql
SELECT name, class, score,
       DENSE_RANK() OVER (PARTITION BY class ORDER BY score DESC) as class_dense_rank
FROM students
ORDER BY class, class_dense_rank;
```

**Result:**
| name  | class   | score | class_dense_rank |
|-------|---------|-------|------------------|
| Alice | Math    | 95    | 1                |
| Bob   | Math    | 90    | 2                |
| Carol | Math    | 90    | 2                |
| Dave  | Math    | 85    | **3**            | ← No gap
| Eve   | Science | 98    | 1                |
| Frank | Science | 95    | 2                |
| Grace | Science | 95    | 2                |
| Henry | Science | 92    | **3**            | ← No gap

### When to Use DENSE_RANK()
- ✅ When you need **consecutive rank numbers** (no gaps)
- ✅ Counting **distinct levels of performance**
- ✅ Creating "grade bands" or "tier systems"
- ✅ When gaps would confuse end users
- ❌ When you need unique numbers for each row (use ROW_NUMBER)

---

## ROW_NUMBER()

### Description
Assigns a **unique sequential integer** to each row, even for tied values. Ties are broken arbitrarily (or by additional ORDER BY columns).

### Syntax
```sql
ROW_NUMBER() OVER (
    [PARTITION BY partition_columns]
    ORDER BY order_columns
)
```

### Basic ROW_NUMBER() Example
```sql
SELECT name, class, score,
       ROW_NUMBER() OVER (ORDER BY score DESC) as row_num
FROM students;
```

**Result:**
| name  | class   | score | row_num |
|-------|---------|-------|---------|
| Eve   | Science | 98    | 1       |
| Alice | Math    | 95    | 2       |
| Frank | Science | 95    | 3       | ← Unique numbers
| Grace | Science | 95    | 4       | ← even for ties
| Henry | Science | 92    | 5       |
| Bob   | Math    | 90    | 6       |
| Carol | Math    | 90    | 7       |
| Dave  | Math    | 85    | 8       |

**Notice:**
- Every row gets a unique number
- Tied values (95, 90) get different numbers
- Order within ties is **arbitrary** unless specified

### Controlling Tie-Breaking
Add additional ORDER BY columns to control tie-breaking:

```sql
SELECT name, class, score,
       ROW_NUMBER() OVER (ORDER BY score DESC, name ASC) as row_num
FROM students;
```

**Result:**
| name  | class   | score | row_num |
|-------|---------|-------|---------|
| Eve   | Science | 98    | 1       |
| Alice | Math    | 95    | 2       | ← Alphabetical
| Frank | Science | 95    | 3       | ← tie-breaking
| Grace | Science | 95    | 4       | ← by name
| Henry | Science | 92    | 5       |
| Bob   | Math    | 90    | 6       |
| Carol | Math    | 90    | 7       |
| Dave  | Math    | 85    | 8       |

### ROW_NUMBER() with PARTITION BY
```sql
SELECT name, class, score,
       ROW_NUMBER() OVER (PARTITION BY class ORDER BY score DESC) as row_in_class
FROM students
ORDER BY class, row_in_class;
```

**Result:**
| name  | class   | score | row_in_class |
|-------|---------|-------|--------------|
| Alice | Math    | 95    | 1            |
| Bob   | Math    | 90    | 2            |
| Carol | Math    | 90    | 3            | ← Unique in partition
| Dave  | Math    | 85    | 4            |
| Eve   | Science | 98    | 1            |
| Frank | Science | 95    | 2            |
| Grace | Science | 95    | 3            | ← Unique in partition
| Henry | Science | 92    | 4            |

### When to Use ROW_NUMBER()
- ✅ **De-duplicating data** (keep first/last occurrence)
- ✅ **Pagination** (skip N rows, take M rows)
- ✅ Assigning **unique identifiers**
- ✅ When every row **must have a different number**
- ❌ When ties should get the same rank (use RANK or DENSE_RANK)

---

## Comparison Chart

### Side-by-Side Comparison
```sql
SELECT name, score,
       RANK() OVER (ORDER BY score DESC) as rank,
       DENSE_RANK() OVER (ORDER BY score DESC) as dense_rank,
       ROW_NUMBER() OVER (ORDER BY score DESC) as row_num
FROM students;
```

**Result:**
| name  | score | rank | dense_rank | row_num |
|-------|-------|------|------------|---------|
| Eve   | 98    | 1    | 1          | 1       |
| Alice | 95    | 2    | 2          | 2       |
| Frank | 95    | 2    | 2          | 3       | ← Different!
| Grace | 95    | 2    | 2          | 4       | ← Different!
| Henry | 92    | 5    | 3          | 5       | ← Different!
| Bob   | 90    | 6    | 4          | 6       |
| Carol | 90    | 6    | 4          | 7       | ← Different!
| Dave  | 85    | 8    | 5          | 8       | ← Different!

### Visual Representation

```
Score: 98  95  95  95  92  90  90  85
       ↓   ↓   ↓   ↓   ↓   ↓   ↓   ↓
RANK:  1   2   2   2   5   6   6   8    (gaps after ties)
DENSE: 1   2   2   2   3   4   4   5    (no gaps)
ROW#:  1   2   3   4   5   6   7   8    (always unique)
```

### Decision Tree

```
Do you need unique numbers for EVERY row?
├─ YES → Use ROW_NUMBER()
└─ NO (ties should share rank)
   └─ Do you want gaps after ties?
      ├─ YES → Use RANK()
      └─ NO → Use DENSE_RANK()
```

---

## Advanced Examples

### 1. Top N Per Group

**Find top 2 students in each class:**

```sql
WITH ranked_students AS (
    SELECT name, class, score,
           RANK() OVER (PARTITION BY class ORDER BY score DESC) as rank
    FROM students
)
SELECT name, class, score, rank
FROM ranked_students
WHERE rank <= 2
ORDER BY class, rank;
```

**Result:**
| name  | class   | score | rank |
|-------|---------|-------|------|
| Alice | Math    | 95    | 1    |
| Bob   | Math    | 90    | 2    |
| Carol | Math    | 90    | 2    |
| Eve   | Science | 98    | 1    |
| Frank | Science | 95    | 2    |
| Grace | Science | 95    | 2    |

**Note:** Using RANK() includes all ties, so you might get more than 2 rows per class.

**If you want EXACTLY 2 rows:**
```sql
WITH numbered_students AS (
    SELECT name, class, score,
           ROW_NUMBER() OVER (PARTITION BY class ORDER BY score DESC) as row_num
    FROM students
)
SELECT name, class, score
FROM numbered_students
WHERE row_num <= 2
ORDER BY class, score DESC;
```

### 2. De-duplication

**Keep only the first occurrence of each email:**

```sql
CREATE TABLE users (
    user_id INT,
    email VARCHAR(100),
    created_at TIMESTAMP
);

WITH numbered_users AS (
    SELECT user_id, email, created_at,
           ROW_NUMBER() OVER (PARTITION BY email ORDER BY created_at ASC) as row_num
    FROM users
)
DELETE FROM users
WHERE user_id IN (
    SELECT user_id
    FROM numbered_users
    WHERE row_num > 1
);
```

Or keep first occurrence:
```sql
WITH numbered_users AS (
    SELECT user_id, email, created_at,
           ROW_NUMBER() OVER (PARTITION BY email ORDER BY created_at ASC) as row_num
    FROM users
)
SELECT user_id, email, created_at
FROM numbered_users
WHERE row_num = 1;
```

### 3. Pagination

**Get page 3 (rows 21-30) of results:**

```sql
WITH numbered_products AS (
    SELECT product_id, product_name, price,
           ROW_NUMBER() OVER (ORDER BY product_name) as row_num
    FROM products
)
SELECT product_id, product_name, price
FROM numbered_products
WHERE row_num BETWEEN 21 AND 30;
```

**Or using OFFSET/LIMIT (simpler):**
```sql
SELECT product_id, product_name, price
FROM products
ORDER BY product_name
LIMIT 10 OFFSET 20;  -- Page 3: skip 20, take 10
```

### 4. Percentile Rankings

**Calculate which percentile each student is in:**

```sql
SELECT name, score,
       RANK() OVER (ORDER BY score DESC) as rank,
       COUNT(*) OVER () as total_students,
       ROUND(
           (RANK() OVER (ORDER BY score DESC) * 100.0) / COUNT(*) OVER (),
           1
       ) as percentile
FROM students;
```

**Result:**
| name  | score | rank | total_students | percentile |
|-------|-------|------|----------------|------------|
| Eve   | 98    | 1    | 8              | 12.5       |
| Alice | 95    | 2    | 8              | 25.0       |
| Frank | 95    | 2    | 8              | 25.0       |
| Grace | 95    | 2    | 8              | 25.0       |
| Henry | 92    | 5    | 8              | 62.5       |
| Bob   | 90    | 6    | 8              | 75.0       |
| Carol | 90    | 6    | 8              | 75.0       |
| Dave  | 85    | 8    | 8              | 100.0      |

### 5. Ranking with Multiple Criteria

**Rank by score first, then by age if tied:**

```sql
CREATE TABLE employees (
    emp_id INT,
    name VARCHAR(50),
    department VARCHAR(50),
    performance_score INT,
    years_of_service INT
);

SELECT name, department, performance_score, years_of_service,
       RANK() OVER (
           PARTITION BY department
           ORDER BY performance_score DESC, years_of_service DESC
       ) as rank
FROM employees;
```

### 6. Gap Analysis

**Find gaps in ranking (positions with no one):**

```sql
WITH all_ranks AS (
    SELECT DENSE_RANK() OVER (ORDER BY score DESC) as rank
    FROM students
),
expected_ranks AS (
    SELECT generate_series(1, (SELECT MAX(rank) FROM all_ranks)) as rank
)
SELECT er.rank as missing_rank
FROM expected_ranks er
LEFT JOIN all_ranks ar ON er.rank = ar.rank
WHERE ar.rank IS NULL;
```

---

## Other Ranking Functions

### NTILE()

Divides rows into N approximately equal groups:

```sql
SELECT name, score,
       NTILE(4) OVER (ORDER BY score DESC) as quartile
FROM students;
```

**Result:**
| name  | score | quartile |
|-------|-------|----------|
| Eve   | 98    | 1        | ← Top 25%
| Alice | 95    | 1        |
| Frank | 95    | 2        | ← 25-50%
| Grace | 95    | 2        |
| Henry | 92    | 3        | ← 50-75%
| Bob   | 90    | 3        |
| Carol | 90    | 4        | ← Bottom 25%
| Dave  | 85    | 4        |

### PERCENT_RANK()

Calculates relative rank (0 to 1):

```sql
SELECT name, score,
       PERCENT_RANK() OVER (ORDER BY score DESC) as pct_rank,
       ROUND(PERCENT_RANK() OVER (ORDER BY score DESC) * 100, 1) as percentile
FROM students;
```

**Formula:** `(rank - 1) / (total_rows - 1)`

**Result:**
| name  | score | pct_rank | percentile |
|-------|-------|----------|------------|
| Eve   | 98    | 0.0000   | 0.0        |
| Alice | 95    | 0.1429   | 14.3       |
| Frank | 95    | 0.1429   | 14.3       |
| Grace | 95    | 0.1429   | 14.3       |
| Henry | 92    | 0.5714   | 57.1       |
| Bob   | 90    | 0.7143   | 71.4       |
| Carol | 90    | 0.7143   | 71.4       |
| Dave  | 85    | 1.0000   | 100.0      |

### CUME_DIST()

Calculates cumulative distribution (percentage of rows <= current row):

```sql
SELECT name, score,
       CUME_DIST() OVER (ORDER BY score DESC) as cum_dist,
       ROUND(CUME_DIST() OVER (ORDER BY score DESC) * 100, 1) as pct_below_or_equal
FROM students;
```

**Formula:** `(number of rows <= current row) / (total rows)`

**Result:**
| name  | score | cum_dist | pct_below_or_equal |
|-------|-------|----------|--------------------|
| Eve   | 98    | 0.1250   | 12.5               |
| Alice | 95    | 0.5000   | 50.0               |
| Frank | 95    | 0.5000   | 50.0               |
| Grace | 95    | 0.5000   | 50.0               |
| Henry | 92    | 0.6250   | 62.5               |
| Bob   | 90    | 0.8750   | 87.5               |
| Carol | 90    | 0.8750   | 87.5               |
| Dave  | 85    | 1.0000   | 100.0              |

---

## Common Use Cases

### 1. Leaderboard Systems

```sql
-- Gaming leaderboard
SELECT username, total_points,
       RANK() OVER (ORDER BY total_points DESC) as rank,
       DENSE_RANK() OVER (ORDER BY total_points DESC) as level
FROM player_stats;
```

### 2. Sales Rankings

```sql
-- Top salespeople per region
WITH sales_ranks AS (
    SELECT salesperson_name, region, total_sales,
           RANK() OVER (PARTITION BY region ORDER BY total_sales DESC) as regional_rank
    FROM sales_summary
)
SELECT *
FROM sales_ranks
WHERE regional_rank <= 10;
```

### 3. Product Popularity

```sql
-- Most viewed products
SELECT product_name, view_count,
       ROW_NUMBER() OVER (ORDER BY view_count DESC) as popularity_rank
FROM product_analytics
LIMIT 100;
```

### 4. Time-Based Sequences

```sql
-- Number transactions per customer chronologically
SELECT customer_id, transaction_date, amount,
       ROW_NUMBER() OVER (
           PARTITION BY customer_id
           ORDER BY transaction_date
       ) as transaction_number
FROM transactions;
```

### 5. Finding Duplicates

```sql
-- Find duplicate records
WITH duplicates AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY email, phone
               ORDER BY created_at DESC
           ) as duplicate_num
    FROM contacts
)
SELECT *
FROM duplicates
WHERE duplicate_num > 1;
```

---

## Performance Tips

### 1. Index Order By Columns

```sql
-- Create index on columns used in ORDER BY
CREATE INDEX idx_score ON students(score DESC);
CREATE INDEX idx_dept_score ON students(department, score DESC);
```

### 2. Filter Before Ranking

```sql
-- Better: Filter first, then rank
WITH filtered AS (
    SELECT * FROM students WHERE class = 'Math'
)
SELECT name, score,
       RANK() OVER (ORDER BY score DESC) as rank
FROM filtered;

-- Worse: Rank all, then filter
SELECT name, score, rank
FROM (
    SELECT name, class, score,
           RANK() OVER (PARTITION BY class ORDER BY score DESC) as rank
    FROM students
) ranked
WHERE class = 'Math';
```

### 3. Reuse Window Definitions

```sql
-- Efficient: Define window once
SELECT name, score,
       RANK() OVER w as rank,
       DENSE_RANK() OVER w as dense_rank,
       ROW_NUMBER() OVER w as row_num
FROM students
WINDOW w AS (ORDER BY score DESC);

-- Less efficient: Repeat window definition
SELECT name, score,
       RANK() OVER (ORDER BY score DESC) as rank,
       DENSE_RANK() OVER (ORDER BY score DESC) as dense_rank,
       ROW_NUMBER() OVER (ORDER BY score DESC) as row_num
FROM students;
```

### 4. Limit Early When Possible

```sql
-- Get top 10 without ranking all rows (if database supports it)
SELECT name, score
FROM students
ORDER BY score DESC
LIMIT 10;

-- Only use ranking if you need the actual rank value
SELECT name, score,
       RANK() OVER (ORDER BY score DESC) as rank
FROM students
WHERE score >= (SELECT MIN(score) FROM (
    SELECT score FROM students ORDER BY score DESC LIMIT 10
) top10);
```

---

## Summary

### Quick Reference

| Function | Result | Use Case |
|----------|--------|----------|
| `RANK()` | 1, 2, 2, **4** | Competition ranking (with gaps) |
| `DENSE_RANK()` | 1, 2, 2, **3** | Level/tier systems (no gaps) |
| `ROW_NUMBER()` | 1, 2, 3, 4 | Unique numbering, pagination, de-duplication |
| `NTILE(n)` | 1, 1, 2, 2 | Divide into N equal groups |
| `PERCENT_RANK()` | 0.0, 0.33, 0.67, 1.0 | Relative rank (0-1) |
| `CUME_DIST()` | 0.25, 0.5, 0.75, 1.0 | Cumulative distribution |

### Remember

1. **RANK()** - Use for standard competition ranking (gold, silver, bronze)
2. **DENSE_RANK()** - Use when you need consecutive numbers without gaps
3. **ROW_NUMBER()** - Use when every row must be unique
4. Always combine with **PARTITION BY** for group-wise ranking
5. Use **ORDER BY** to define ranking criteria
6. Index appropriately for better performance

**The Golden Rule:** Choose based on how you want to handle ties:
- Same rank with gaps → `RANK()`
- Same rank without gaps → `DENSE_RANK()`
- Different ranks (no ties) → `ROW_NUMBER()`
