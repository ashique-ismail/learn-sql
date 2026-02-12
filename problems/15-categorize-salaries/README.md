# Problem 15: Categorize Salaries

**Difficulty:** Intermediate
**Concepts:** CASE expressions, Conditional logic, Computed columns, Data categorization
**Phase:** Advanced Features (Days 14-16)

---

## Learning Objectives

- Master CASE expressions for conditional logic
- Understand simple vs searched CASE
- Use CASE in SELECT, WHERE, ORDER BY clauses
- Create dynamic categories from continuous data
- Combine CASE with aggregate functions

---

## Concept Summary

**CASE expressions** provide if-then-else logic in SQL, similar to switch statements or if-else in programming.

### Syntax

```sql
-- Searched CASE (most flexible)
CASE
    WHEN condition1 THEN result1
    WHEN condition2 THEN result2
    WHEN condition3 THEN result3
    ELSE default_result
END

-- Simple CASE (equality comparison)
CASE column
    WHEN value1 THEN result1
    WHEN value2 THEN result2
    ELSE default_result
END

-- CASE can be used anywhere an expression is valid:
-- SELECT, WHERE, ORDER BY, GROUP BY, HAVING, etc.
```

### Key Points

- CASE is an expression, not a statement (returns a value)
- Evaluates conditions in order, returns first match
- ELSE is optional (defaults to NULL)
- All result expressions must have compatible types
- Can be nested

---

## Problem Statement

**Task:** Categorize employees as 'Low', 'Medium', or 'High' earners based on salary:
- Low: salary < $50,000
- Medium: salary between $50,000 and $100,000
- High: salary > $100,000

Show employee name, salary, and category.

---

## Hint

Use CASE with WHEN conditions to test salary ranges.

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

```sql
SELECT
    name,
    salary,
    CASE
        WHEN salary < 50000 THEN 'Low'
        WHEN salary BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'High'
    END as salary_category
FROM employees
ORDER BY salary;
```

### Explanation

1. `CASE` begins the conditional expression
2. `WHEN salary < 50000 THEN 'Low'` - First condition checked
3. `WHEN salary BETWEEN 50000 AND 100000` - Second condition if first fails
4. `ELSE 'High'` - Default for all remaining cases (> 100000)
5. `END as salary_category` - End expression and alias result
6. Conditions evaluated in order; first match returns

---

## Alternative Solutions

```sql
-- Using simple CASE for exact matches
SELECT
    name,
    department,
    CASE department
        WHEN 'Engineering' THEN 'Technical'
        WHEN 'Sales' THEN 'Revenue'
        WHEN 'Marketing' THEN 'Revenue'
        WHEN 'HR' THEN 'Support'
        ELSE 'Other'
    END as department_category
FROM employees;

-- Multiple criteria with AND/OR
SELECT
    name,
    salary,
    department,
    CASE
        WHEN salary > 100000 AND department = 'Engineering' THEN 'Senior Engineer'
        WHEN salary > 100000 AND department = 'Sales' THEN 'Senior Sales'
        WHEN salary > 80000 THEN 'Mid-Level'
        WHEN salary > 50000 THEN 'Junior'
        ELSE 'Entry-Level'
    END as level
FROM employees;

-- Nested CASE
SELECT
    name,
    salary,
    department,
    CASE department
        WHEN 'Engineering' THEN
            CASE
                WHEN salary > 120000 THEN 'Senior Engineer'
                WHEN salary > 80000 THEN 'Mid-Level Engineer'
                ELSE 'Junior Engineer'
            END
        WHEN 'Sales' THEN
            CASE
                WHEN salary > 100000 THEN 'Senior Sales'
                ELSE 'Sales Rep'
            END
        ELSE 'Staff'
    END as job_level
FROM employees;

-- CASE in WHERE clause
SELECT name, salary
FROM employees
WHERE
    CASE
        WHEN department = 'Engineering' THEN salary > 80000
        WHEN department = 'Sales' THEN salary > 70000
        ELSE salary > 60000
    END;

-- CASE in ORDER BY
SELECT name, salary, department
FROM employees
ORDER BY
    CASE department
        WHEN 'Executive' THEN 1
        WHEN 'Engineering' THEN 2
        WHEN 'Sales' THEN 3
        ELSE 4
    END,
    salary DESC;
```

---

## Advanced Examples

```sql
-- With aggregate functions
SELECT
    department,
    COUNT(*) as total_employees,
    SUM(CASE WHEN salary < 50000 THEN 1 ELSE 0 END) as low_earners,
    SUM(CASE WHEN salary BETWEEN 50000 AND 100000 THEN 1 ELSE 0 END) as medium_earners,
    SUM(CASE WHEN salary > 100000 THEN 1 ELSE 0 END) as high_earners,
    ROUND(AVG(CASE WHEN salary < 50000 THEN salary END), 2) as avg_low_salary,
    ROUND(AVG(CASE WHEN salary BETWEEN 50000 AND 100000 THEN salary END), 2) as avg_medium_salary,
    ROUND(AVG(CASE WHEN salary > 100000 THEN salary END), 2) as avg_high_salary
FROM employees
GROUP BY department;

-- Pivot-style transformation
SELECT
    name,
    SUM(CASE WHEN year = 2021 THEN sales ELSE 0 END) as sales_2021,
    SUM(CASE WHEN year = 2022 THEN sales ELSE 0 END) as sales_2022,
    SUM(CASE WHEN year = 2023 THEN sales ELSE 0 END) as sales_2023
FROM sales_data
GROUP BY name;

-- Complex business logic
SELECT
    order_id,
    order_date,
    total_amount,
    customer_type,
    CASE
        -- Premium customers get best discount
        WHEN customer_type = 'Premium' AND total_amount > 1000 THEN total_amount * 0.80
        WHEN customer_type = 'Premium' THEN total_amount * 0.90
        -- Regular customers get standard discount
        WHEN customer_type = 'Regular' AND total_amount > 500 THEN total_amount * 0.95
        -- New customers get welcome discount
        WHEN customer_type = 'New' AND total_amount > 100 THEN total_amount * 0.92
        -- No discount for small orders
        ELSE total_amount
    END as final_amount,
    CASE
        WHEN customer_type = 'Premium' AND total_amount > 1000 THEN '20% VIP Discount'
        WHEN customer_type = 'Premium' THEN '10% VIP Discount'
        WHEN customer_type = 'Regular' AND total_amount > 500 THEN '5% Loyalty Discount'
        WHEN customer_type = 'New' AND total_amount > 100 THEN '8% Welcome Discount'
        ELSE 'No Discount'
    END as discount_type
FROM orders;

-- Performance rating
SELECT
    employee_name,
    sales_target,
    actual_sales,
    CASE
        WHEN actual_sales >= sales_target * 1.2 THEN 'Exceptional'
        WHEN actual_sales >= sales_target THEN 'Meets Expectations'
        WHEN actual_sales >= sales_target * 0.8 THEN 'Needs Improvement'
        ELSE 'Unsatisfactory'
    END as performance_rating,
    CASE
        WHEN actual_sales >= sales_target * 1.2 THEN sales_target * 0.20
        WHEN actual_sales >= sales_target THEN sales_target * 0.10
        WHEN actual_sales >= sales_target * 0.8 THEN sales_target * 0.05
        ELSE 0
    END as bonus_amount
FROM sales_performance;
```

---

## Try These Variations

1. Add an 'Executive' category for salaries over $150,000
2. Categorize by both salary and department
3. Create salary quintiles (5 equal groups)
4. Flag employees for review based on multiple criteria
5. Calculate bonuses based on performance tiers

### Solutions to Variations

```sql
-- 1. Four-tier categorization
SELECT
    name,
    salary,
    CASE
        WHEN salary > 150000 THEN 'Executive'
        WHEN salary > 100000 THEN 'High'
        WHEN salary >= 50000 THEN 'Medium'
        ELSE 'Low'
    END as salary_category
FROM employees;

-- 2. Department and salary combined
SELECT
    name,
    department,
    salary,
    CASE
        WHEN department = 'Engineering' AND salary > 120000 THEN 'Senior Engineer'
        WHEN department = 'Engineering' AND salary > 80000 THEN 'Engineer'
        WHEN department = 'Engineering' THEN 'Junior Engineer'
        WHEN department = 'Sales' AND salary > 100000 THEN 'Senior Sales'
        WHEN department = 'Sales' THEN 'Sales Rep'
        WHEN salary > 100000 THEN 'Senior ' || department
        ELSE department || ' Staff'
    END as job_level
FROM employees;

-- 3. Salary quintiles
WITH salary_stats AS (
    SELECT
        PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY salary) as p20,
        PERCENTILE_CONT(0.4) WITHIN GROUP (ORDER BY salary) as p40,
        PERCENTILE_CONT(0.6) WITHIN GROUP (ORDER BY salary) as p60,
        PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY salary) as p80
    FROM employees
)
SELECT
    e.name,
    e.salary,
    CASE
        WHEN e.salary <= s.p20 THEN 'Q1 (Bottom 20%)'
        WHEN e.salary <= s.p40 THEN 'Q2 (20-40%)'
        WHEN e.salary <= s.p60 THEN 'Q3 (40-60%)'
        WHEN e.salary <= s.p80 THEN 'Q4 (60-80%)'
        ELSE 'Q5 (Top 20%)'
    END as salary_quintile
FROM employees e
CROSS JOIN salary_stats s;

-- 4. Review flags
SELECT
    name,
    salary,
    hire_date,
    last_review_date,
    performance_score,
    CASE
        WHEN last_review_date < CURRENT_DATE - INTERVAL '1 year' THEN 'Review Overdue'
        WHEN performance_score < 3 AND salary > 80000 THEN 'High Salary, Low Performance'
        WHEN performance_score >= 4 AND salary < 60000 THEN 'Raise Candidate'
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date)) > 5
             AND last_review_date < CURRENT_DATE - INTERVAL '6 months' THEN 'Tenure Review'
        ELSE 'No Action'
    END as review_flag
FROM employees;

-- 5. Performance-based bonuses
SELECT
    name,
    salary,
    performance_score,
    years_of_service,
    CASE
        WHEN performance_score >= 4.5 AND years_of_service >= 5 THEN salary * 0.15
        WHEN performance_score >= 4.5 THEN salary * 0.12
        WHEN performance_score >= 4.0 AND years_of_service >= 5 THEN salary * 0.10
        WHEN performance_score >= 4.0 THEN salary * 0.08
        WHEN performance_score >= 3.5 THEN salary * 0.05
        WHEN performance_score >= 3.0 THEN salary * 0.02
        ELSE 0
    END as bonus
FROM employees;
```

---

## Sample Output

```
      name       | salary  | salary_category
-----------------+---------+-----------------
 John Smith      |  45000  | Low
 Jane Doe        |  48000  | Low
 Mike Johnson    |  65000  | Medium
 Sarah Williams  |  75000  | Medium
 Chris Brown     |  95000  | Medium
 Emma Davis      | 105000  | High
 Alice Anderson  | 150000  | High
(7 rows)
```

---

## Common Mistakes

1. **Missing ELSE:** Returns NULL for unmatched cases
   ```sql
   -- May return unexpected NULLs
   CASE
       WHEN salary < 50000 THEN 'Low'
       WHEN salary < 100000 THEN 'Medium'
       -- Missing ELSE for salary >= 100000
   END
   ```

2. **Wrong order of conditions:**
   ```sql
   -- All salaries match first condition!
   CASE
       WHEN salary < 100000 THEN 'Not High'  -- Catches 50000
       WHEN salary < 50000 THEN 'Low'        -- Never reached
   END
   ```

3. **Type mismatch in results:**
   ```sql
   -- Error: mixing types
   CASE
       WHEN salary < 50000 THEN 'Low'
       WHEN salary < 100000 THEN 50000  -- Number, not string!
   END
   ```

4. **Using = instead of BETWEEN:**
   ```sql
   -- Doesn't include 50000 or 100000
   WHEN salary > 50000 AND salary < 100000 THEN 'Medium'
   -- Better:
   WHEN salary BETWEEN 50000 AND 100000 THEN 'Medium'
   ```

5. **Forgetting END keyword:**
   ```sql
   -- Syntax error
   CASE WHEN salary < 50000 THEN 'Low'  -- Missing END
   ```

6. **NULL handling:**
   ```sql
   -- NULL values don't match any WHEN
   CASE
       WHEN salary < 50000 THEN 'Low'
       WHEN salary IS NULL THEN 'Unknown'  -- Must explicitly check
       ELSE 'Other'
   END
   ```

---

## CASE vs Other Approaches

### Using CASE

```sql
SELECT
    name,
    CASE
        WHEN age < 18 THEN 'Minor'
        WHEN age < 65 THEN 'Adult'
        ELSE 'Senior'
    END as age_group
FROM people;
```

### Using Multiple Queries (inefficient)

```sql
SELECT name, 'Minor' as age_group FROM people WHERE age < 18
UNION ALL
SELECT name, 'Adult' FROM people WHERE age BETWEEN 18 AND 64
UNION ALL
SELECT name, 'Senior' FROM people WHERE age >= 65;
```

CASE is more efficient - single table scan vs three.

---

## Performance Note

- CASE expressions are generally efficient
- Multiple CASEs on same column can be optimized by database
- In WHERE clause, CASE can prevent index usage
- Consider computed/generated columns for frequently-used CASE logic

```sql
-- May not use index
WHERE CASE WHEN salary > 50000 THEN 1 ELSE 0 END = 1

-- Better
WHERE salary > 50000
```

---

## Real-World Use Cases

1. **Customer segmentation:** VIP, Regular, New customers
2. **Product categorization:** Price tiers, size categories
3. **Report formatting:** Status indicators, colored flags
4. **Business rules:** Discount calculations, approval workflows
5. **Data quality:** Flag anomalies and outliers
6. **Compliance:** Risk levels, regulatory categories

---

## Related Problems

- **Previous:** [Problem 14 - Monthly Revenue Analysis](../14-monthly-revenue-analysis/)
- **Next:** [Problem 16 - Orphaned Records](../16-orphaned-records/)
- **Related:** Problem 8 (Subqueries), Problem 12 (UPDATE with CASE), Problem 26 (Quartiles)

---

## Notes

```
Your notes here:




```

---

[← Previous](../14-monthly-revenue-analysis/) | [Back to Overview](../../README.md) | [Next Problem →](../16-orphaned-records/)
