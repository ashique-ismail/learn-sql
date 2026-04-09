# PARTITION BY - Complete Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Basic Syntax](#basic-syntax)
3. [How PARTITION BY Works](#how-partition-by-works)
4. [Visual Examples](#visual-examples)
5. [Common Use Cases](#common-use-cases)
6. [PARTITION BY vs GROUP BY](#partition-by-vs-group-by)
7. [Multiple Partitions](#multiple-partitions)
8. [Advanced Examples](#advanced-examples)
9. [Performance Considerations](#performance-considerations)

---

## Introduction

`PARTITION BY` is a clause used with **window functions** that divides your result set into logical groups (partitions) and performs calculations **independently within each group**. Unlike `GROUP BY`, it **preserves all rows** in your result set.

**Key Concept:** Think of PARTITION BY as creating invisible sub-tables where each window function operates independently.

---

## Basic Syntax

```sql
window_function() OVER (
    PARTITION BY column1, column2, ...
    ORDER BY column3
)
```

**Components:**
- `window_function()` - RANK(), ROW_NUMBER(), SUM(), AVG(), etc.
- `PARTITION BY` - Defines how to group rows
- `ORDER BY` - Defines order within each partition (optional for some functions)

---

## How PARTITION BY Works

### Example Dataset
```sql
CREATE TABLE employees (
    id INT,
    name VARCHAR(50),
    department VARCHAR(50),
    salary DECIMAL(10,2),
    hire_date DATE
);

INSERT INTO employees VALUES
(1, 'Alice', 'Sales', 95000, '2020-01-15'),
(2, 'Bob', 'Sales', 90000, '2019-06-20'),
(3, 'Carol', 'Sales', 85000, '2021-03-10'),
(4, 'Dave', 'Engineering', 120000, '2018-11-05'),
(5, 'Eve', 'Engineering', 115000, '2019-02-14'),
(6, 'Frank', 'Engineering', 110000, '2020-07-22'),
(7, 'Grace', 'HR', 85000, '2020-05-18'),
(8, 'Henry', 'HR', 80000, '2021-01-09');
```

### Without PARTITION BY
```sql
SELECT name, department, salary,
       RANK() OVER (ORDER BY salary DESC) as overall_rank
FROM employees;
```

**Result:**
| name  | department   | salary  | overall_rank |
|-------|--------------|---------|--------------|
| Dave  | Engineering  | 120000  | 1            |
| Eve   | Engineering  | 115000  | 2            |
| Frank | Engineering  | 110000  | 3            |
| Alice | Sales        | 95000   | 4            |
| Bob   | Sales        | 90000   | 5            |
| Carol | Sales        | 85000   | 6            |
| Grace | HR           | 85000   | 6            |
| Henry | HR           | 80000   | 8            |

*All employees ranked together*

### With PARTITION BY
```sql
SELECT name, department, salary,
       RANK() OVER (PARTITION BY department ORDER BY salary DESC) as dept_rank
FROM employees;
```

**Result:**
| name  | department   | salary  | dept_rank |
|-------|--------------|---------|-----------|
| Dave  | Engineering  | 120000  | **1**     |
| Eve   | Engineering  | 115000  | **2**     |
| Frank | Engineering  | 110000  | **3**     |
| Grace | HR           | 85000   | **1**     |
| Henry | HR           | 80000   | **2**     |
| Alice | Sales        | 95000   | **1**     |
| Bob   | Sales        | 90000   | **2**     |
| Carol | Sales        | 85000   | **3**     |

*Rank resets for each department - employees ranked within their department*

---

## Visual Examples

### Conceptual Visualization

**Step 1: Data is partitioned**
```
Original Table
┌──────────────────────────────────────┐
│  All Employees (8 rows)              │
└──────────────────────────────────────┘
                 ↓
        PARTITION BY department
                 ↓
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│Engineering  │  │    Sales    │  │     HR      │
│  Dave       │  │   Alice     │  │   Grace     │
│  Eve        │  │   Bob       │  │   Henry     │
│  Frank      │  │   Carol     │  │             │
└─────────────┘  └─────────────┘  └─────────────┘
```

**Step 2: Function applied to each partition**
```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│Engineering  │  │    Sales    │  │     HR      │
│Dave    (1)  │  │Alice   (1)  │  │Grace   (1)  │
│Eve     (2)  │  │Bob     (2)  │  │Henry   (2)  │
│Frank   (3)  │  │Carol   (3)  │  │             │
└─────────────┘  └─────────────┘  └─────────────┘
```

**Step 3: Results recombined**
```
┌──────────────────────────────────────┐
│  All rows with dept_rank calculated  │
│  (8 rows preserved)                  │
└──────────────────────────────────────┘
```

---

## Common Use Cases

### 1. Top N per Group

**Find top 3 highest paid employees in each department:**

```sql
WITH ranked_employees AS (
    SELECT name, department, salary,
           RANK() OVER (PARTITION BY department ORDER BY salary DESC) as rank
    FROM employees
)
SELECT name, department, salary, rank
FROM ranked_employees
WHERE rank <= 3
ORDER BY department, rank;
```

**Result:**
| name  | department   | salary  | rank |
|-------|--------------|---------|------|
| Dave  | Engineering  | 120000  | 1    |
| Eve   | Engineering  | 115000  | 2    |
| Frank | Engineering  | 110000  | 3    |
| Grace | HR           | 85000   | 1    |
| Henry | HR           | 80000   | 2    |
| Alice | Sales        | 95000   | 1    |
| Bob   | Sales        | 90000   | 2    |
| Carol | Sales        | 85000   | 3    |

### 2. Running Totals per Group

**Calculate running total of sales by region:**

```sql
CREATE TABLE sales (
    id INT,
    region VARCHAR(50),
    sale_date DATE,
    amount DECIMAL(10,2)
);

INSERT INTO sales VALUES
(1, 'North', '2024-01-01', 1000),
(2, 'North', '2024-01-02', 1500),
(3, 'North', '2024-01-03', 2000),
(4, 'South', '2024-01-01', 800),
(5, 'South', '2024-01-02', 1200),
(6, 'South', '2024-01-03', 1000);

SELECT region, sale_date, amount,
       SUM(amount) OVER (
           PARTITION BY region
           ORDER BY sale_date
       ) as running_total
FROM sales
ORDER BY region, sale_date;
```

**Result:**
| region | sale_date  | amount | running_total |
|--------|------------|--------|---------------|
| North  | 2024-01-01 | 1000   | 1000          |
| North  | 2024-01-02 | 1500   | 2500          |
| North  | 2024-01-03 | 2000   | 4500          |
| South  | 2024-01-01 | 800    | 800           |
| South  | 2024-01-02 | 1200   | 2000          |
| South  | 2024-01-03 | 1000   | 3000          |

### 3. Row Numbers per Group

**Number orders for each customer:**

```sql
CREATE TABLE orders (
    order_id INT,
    customer_id INT,
    order_date DATE,
    amount DECIMAL(10,2)
);

SELECT customer_id, order_date, amount,
       ROW_NUMBER() OVER (
           PARTITION BY customer_id
           ORDER BY order_date
       ) as order_number
FROM orders;
```

**Result:**
| customer_id | order_date | amount | order_number |
|-------------|------------|--------|--------------|
| 101         | 2024-01-05 | 50     | 1            |
| 101         | 2024-01-15 | 75     | 2            |
| 101         | 2024-02-01 | 100    | 3            |
| 102         | 2024-01-10 | 200    | 1            |
| 102         | 2024-01-20 | 150    | 2            |

### 4. Percentage Within Group

**Calculate each employee's salary as percentage of department total:**

```sql
SELECT name, department, salary,
       ROUND(
           salary * 100.0 / SUM(salary) OVER (PARTITION BY department),
           2
       ) as pct_of_dept_total
FROM employees
ORDER BY department, salary DESC;
```

**Result:**
| name  | department   | salary  | pct_of_dept_total |
|-------|--------------|---------|-------------------|
| Dave  | Engineering  | 120000  | 34.78             |
| Eve   | Engineering  | 115000  | 33.33             |
| Frank | Engineering  | 110000  | 31.88             |
| Grace | HR           | 85000   | 51.52             |
| Henry | HR           | 80000   | 48.48             |
| Alice | Sales        | 95000   | 35.19             |
| Bob   | Sales        | 90000   | 33.33             |
| Carol | Sales        | 85000   | 31.48             |

### 5. Compare to Group Average

**Show each employee's salary vs department average:**

```sql
SELECT name, department, salary,
       ROUND(AVG(salary) OVER (PARTITION BY department), 2) as dept_avg,
       ROUND(salary - AVG(salary) OVER (PARTITION BY department), 2) as diff_from_avg
FROM employees
ORDER BY department, salary DESC;
```

**Result:**
| name  | department   | salary  | dept_avg  | diff_from_avg |
|-------|--------------|---------|-----------|---------------|
| Dave  | Engineering  | 120000  | 115000.00 | 5000.00       |
| Eve   | Engineering  | 115000  | 115000.00 | 0.00          |
| Frank | Engineering  | 110000  | 115000.00 | -5000.00      |
| Grace | HR           | 85000   | 82500.00  | 2500.00       |
| Henry | HR           | 80000   | 82500.00  | -2500.00      |
| Alice | Sales        | 95000   | 90000.00  | 5000.00       |
| Bob   | Sales        | 90000   | 90000.00  | 0.00          |
| Carol | Sales        | 85000   | 90000.00  | -5000.00      |

---

## PARTITION BY vs GROUP BY

| Feature | PARTITION BY | GROUP BY |
|---------|--------------|----------|
| **Purpose** | Window calculations per group | Aggregate data into groups |
| **Row Count** | Preserves all rows | Reduces rows (one per group) |
| **Usage** | With window functions | With aggregate functions |
| **Columns** | Can select any column | Must select grouped/aggregated columns only |
| **Functions** | RANK(), ROW_NUMBER(), LEAD(), LAG() | COUNT(), SUM(), AVG(), MIN(), MAX() |

### Example Comparison

**Using GROUP BY:**
```sql
SELECT department, AVG(salary) as avg_salary
FROM employees
GROUP BY department;
```

**Result (3 rows):**
| department   | avg_salary |
|--------------|------------|
| Engineering  | 115000.00  |
| HR           | 82500.00   |
| Sales        | 90000.00   |

**Using PARTITION BY:**
```sql
SELECT name, department, salary,
       AVG(salary) OVER (PARTITION BY department) as dept_avg
FROM employees;
```

**Result (8 rows - all preserved):**
| name  | department   | salary  | dept_avg  |
|-------|--------------|---------|-----------|
| Dave  | Engineering  | 120000  | 115000.00 |
| Eve   | Engineering  | 115000  | 115000.00 |
| Frank | Engineering  | 110000  | 115000.00 |
| Grace | HR           | 85000   | 82500.00  |
| Henry | HR           | 80000   | 82500.00  |
| Alice | Sales        | 95000   | 90000.00  |
| Bob   | Sales        | 90000   | 90000.00  |
| Carol | Sales        | 85000   | 90000.00  |

---

## Multiple Partitions

You can partition by **multiple columns** to create more granular groups:

```sql
SELECT name, department, location, salary,
       RANK() OVER (
           PARTITION BY department, location
           ORDER BY salary DESC
       ) as rank_in_dept_location
FROM employees;
```

This creates separate partitions for each **combination**:
- Engineering + New York
- Engineering + London
- Sales + New York
- Sales + London
- etc.

### Example with Multiple Partitions

```sql
CREATE TABLE regional_employees (
    name VARCHAR(50),
    department VARCHAR(50),
    location VARCHAR(50),
    salary DECIMAL(10,2)
);

INSERT INTO regional_employees VALUES
('Alice', 'Sales', 'New York', 95000),
('Bob', 'Sales', 'New York', 90000),
('Carol', 'Sales', 'London', 85000),
('Dave', 'Engineering', 'New York', 120000),
('Eve', 'Engineering', 'London', 115000),
('Frank', 'Engineering', 'London', 110000);

SELECT name, department, location, salary,
       RANK() OVER (
           PARTITION BY department, location
           ORDER BY salary DESC
       ) as rank
FROM regional_employees
ORDER BY department, location, rank;
```

**Result:**
| name  | department   | location | salary  | rank |
|-------|--------------|----------|---------|------|
| Dave  | Engineering  | London   | 120000  | 1    |
| Eve   | Engineering  | London   | 115000  | 1    |
| Frank | Engineering  | London   | 110000  | 2    |
| Dave  | Engineering  | New York | 120000  | 1    |
| Alice | Sales        | London   | 85000   | 1    |
| Bob   | Sales        | New York | 95000   | 1    |
| Carol | Sales        | New York | 90000   | 2    |

---

## Advanced Examples

### 1. First and Last Value in Partition

**Get highest and lowest paid employee in each department:**

```sql
SELECT DISTINCT
    department,
    FIRST_VALUE(name) OVER (
        PARTITION BY department
        ORDER BY salary DESC
    ) as highest_paid,
    LAST_VALUE(name) OVER (
        PARTITION BY department
        ORDER BY salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as lowest_paid
FROM employees;
```

### 2. Moving Average per Group

**Calculate 3-day moving average of sales per region:**

```sql
SELECT region, sale_date, amount,
       AVG(amount) OVER (
           PARTITION BY region
           ORDER BY sale_date
           ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ) as moving_avg_3day
FROM sales;
```

### 3. Gap and Island Problem

**Find consecutive days of sales per region:**

```sql
WITH numbered_sales AS (
    SELECT region, sale_date,
           ROW_NUMBER() OVER (PARTITION BY region ORDER BY sale_date) as rn,
           sale_date - INTERVAL ROW_NUMBER() OVER (PARTITION BY region ORDER BY sale_date) DAY as grp
    FROM sales
)
SELECT region, MIN(sale_date) as streak_start, MAX(sale_date) as streak_end,
       COUNT(*) as consecutive_days
FROM numbered_sales
GROUP BY region, grp
ORDER BY region, streak_start;
```

### 4. Cumulative Distribution

**Calculate cumulative distribution of salaries within department:**

```sql
SELECT name, department, salary,
       ROUND(
           CUME_DIST() OVER (PARTITION BY department ORDER BY salary) * 100,
           2
       ) as percentile
FROM employees;
```

---

## Performance Considerations

### 1. Indexing
Create indexes on partition columns for better performance:
```sql
CREATE INDEX idx_dept ON employees(department);
CREATE INDEX idx_dept_salary ON employees(department, salary);
```

### 2. Partition Pruning
When filtering on partition columns, the optimizer can skip irrelevant partitions:
```sql
-- Efficient: Only processes Engineering partition
SELECT name, salary,
       RANK() OVER (PARTITION BY department ORDER BY salary DESC) as rank
FROM employees
WHERE department = 'Engineering';
```

### 3. Avoid Multiple Window Definitions
Reuse window definitions when possible:
```sql
-- Inefficient
SELECT name, department, salary,
       RANK() OVER (PARTITION BY department ORDER BY salary DESC) as rank,
       DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) as dense_rank
FROM employees;

-- Better
SELECT name, department, salary,
       RANK() OVER w as rank,
       DENSE_RANK() OVER w as dense_rank
FROM employees
WINDOW w AS (PARTITION BY department ORDER BY salary DESC);
```

### 4. Materialized Views
For frequently used partition calculations, consider materialized views:
```sql
CREATE MATERIALIZED VIEW dept_rankings AS
SELECT name, department, salary,
       RANK() OVER (PARTITION BY department ORDER BY salary DESC) as rank
FROM employees;
```

---

## Summary

**Key Takeaways:**

1. `PARTITION BY` divides data into groups for independent window function calculations
2. Unlike `GROUP BY`, it preserves all original rows
3. Perfect for rankings, running totals, and comparisons within groups
4. Can partition by multiple columns for granular grouping
5. Works with various window functions: RANK(), ROW_NUMBER(), SUM(), AVG(), etc.
6. Essential for "Top N per group" queries

**Remember:** Think of PARTITION BY as creating invisible sub-tables where each window function operates independently, then reassembling all rows into the final result.
