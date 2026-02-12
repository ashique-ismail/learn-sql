# Problem 29: Data Quality Audit

**Difficulty:** Expert
**Concepts:** Data validation, Multiple CTEs, UNION, Regular expressions, Constraint checking, Data cleansing
**Phase:** Real-World Scenarios (Days 21-25)

---

## Learning Objectives

- Master data quality validation techniques
- Use regular expressions for pattern validation
- Combine multiple validation checks with UNION
- Identify referential integrity issues
- Detect anomalies and outliers
- Create comprehensive audit reports
- Implement data quality rules

---

## Concept Summary

**Data quality audits** systematically check data for completeness, accuracy, consistency, and validity. SQL provides powerful tools for identifying and reporting data quality issues.

### Data Quality Dimensions

1. **Completeness:** No missing required values
2. **Accuracy:** Values are correct and valid
3. **Consistency:** Data follows rules and formats
4. **Uniqueness:** No unwanted duplicates
5. **Integrity:** Relationships are valid
6. **Timeliness:** Data is up-to-date

### Common Validation Patterns

```sql
-- NULL checks
WHERE column IS NULL

-- Format validation (regex)
WHERE column !~ 'pattern'

-- Range validation
WHERE column < min_value OR column > max_value

-- Referential integrity
WHERE NOT EXISTS (SELECT 1 FROM parent WHERE parent.id = child.parent_id)

-- Duplicate detection
HAVING COUNT(*) > 1

-- Business rule validation
WHERE (condition1 AND NOT condition2)  -- Logical inconsistency
```

---

## Problem Statement

**Task:** Create a comprehensive data quality audit report:
1. Find duplicate emails in customers table
2. Find orders without order items (orphaned records)
3. Find products with negative or zero stock
4. Find employees with invalid email formats
5. Find circular manager relationships
6. Find missing foreign key references
7. Provide summary of all data quality issues

**Given:** All tables in the database (customers, orders, order_items, products, employees, departments)

**Requirements:**
- Identify all types of data quality issues
- Provide detailed examples
- Create executive summary
- Suggest remediation

---

## Hint

Use multiple CTEs for each validation check, combine with UNION ALL, and create summary statistics. Use regular expressions for email validation.

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

```sql
WITH
-- 1. Duplicate emails in customers
duplicate_emails AS (
    SELECT
        'Duplicate Email' as issue_type,
        'Customers' as table_name,
        email as identifier,
        COUNT(*) as occurrence_count,
        'Severity: High' as severity,
        STRING_AGG(name, ', ' ORDER BY id) as affected_records
    FROM customers
    GROUP BY email
    HAVING COUNT(*) > 1
),

-- 2. Orders without items
orphan_orders AS (
    SELECT
        'Order Without Items' as issue_type,
        'Orders' as table_name,
        o.id::TEXT as identifier,
        1 as occurrence_count,
        'Severity: High' as severity,
        'Order ID: ' || o.id || ', Customer: ' || c.name ||
        ', Date: ' || o.order_date || ', Amount: ' || o.amount as affected_records
    FROM orders o
    LEFT JOIN order_items oi ON o.id = oi.order_id
    JOIN customers c ON o.customer_id = c.id
    WHERE oi.id IS NULL
),

-- 3. Products with invalid stock
stock_issues AS (
    SELECT
        CASE
            WHEN stock_quantity < 0 THEN 'Negative Stock'
            ELSE 'Zero Stock with Orders'
        END as issue_type,
        'Products' as table_name,
        id::TEXT as identifier,
        1 as occurrence_count,
        'Severity: Medium' as severity,
        'Product: ' || name || ', Category: ' || category ||
        ', Stock: ' || stock_quantity || ', Price: ' || price as affected_records
    FROM products
    WHERE stock_quantity < 0
       OR (stock_quantity = 0 AND id IN (
           SELECT DISTINCT product_id
           FROM order_items oi
           JOIN orders o ON oi.order_id = o.id
           WHERE o.status IN ('pending', 'processing')
       ))
),

-- 4. Invalid email formats
invalid_emails AS (
    SELECT
        'Invalid Email Format' as issue_type,
        'Employees' as table_name,
        email as identifier,
        1 as occurrence_count,
        'Severity: Medium' as severity,
        'Employee: ' || name || ', Department: ' || department ||
        ', Email: ' || COALESCE(email, 'NULL') as affected_records
    FROM employees
    WHERE email IS NULL
       OR email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'
       OR email LIKE '%@%.%'  -- Multiple @ signs
       OR LENGTH(email) < 6
),

-- 5. Circular manager relationships
circular_managers AS (
    SELECT
        'Circular Management' as issue_type,
        'Employees' as table_name,
        e1.id::TEXT as identifier,
        1 as occurrence_count,
        'Severity: High' as severity,
        'Employee: ' || e1.name || ' (ID: ' || e1.id ||
        ') -> Manager: ' || e2.name || ' (ID: ' || e2.id ||
        ') -> Upper: ' || e3.name || ' (ID: ' || e3.id || ')' as affected_records
    FROM employees e1
    JOIN employees e2 ON e1.manager_id = e2.id
    JOIN employees e3 ON e2.manager_id = e3.id
    WHERE e3.id = e1.id  -- Circle detected
),

-- 6. Missing department references
missing_dept_refs AS (
    SELECT
        'Missing Department Reference' as issue_type,
        'Employees' as table_name,
        id::TEXT as identifier,
        1 as occurrence_count,
        'Severity: High' as severity,
        'Employee: ' || name || ', Dept ID: ' || COALESCE(dept_id::TEXT, 'NULL') ||
        ' (Department does not exist)' as affected_records
    FROM employees
    WHERE dept_id IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM departments d WHERE d.id = dept_id)
),

-- 7. Price inconsistencies
price_anomalies AS (
    SELECT
        'Price Anomaly' as issue_type,
        'Order Items' as table_name,
        oi.id::TEXT as identifier,
        1 as occurrence_count,
        'Severity: Medium' as severity,
        'Order Item ID: ' || oi.id || ', Product: ' || p.name ||
        ', Catalog Price: ' || p.price || ', Order Price: ' || oi.price ||
        ', Diff: ' || ABS(p.price - oi.price) as affected_records
    FROM order_items oi
    JOIN products p ON oi.product_id = p.id
    WHERE ABS(p.price - oi.price) > p.price * 0.20  -- More than 20% difference
),

-- 8. Future dated orders
future_orders AS (
    SELECT
        'Future Order Date' as issue_type,
        'Orders' as table_name,
        id::TEXT as identifier,
        1 as occurrence_count,
        'Severity: High' as severity,
        'Order ID: ' || id || ', Date: ' || order_date ||
        ', Customer ID: ' || customer_id as affected_records
    FROM orders
    WHERE order_date > CURRENT_DATE
),

-- 9. NULL in required fields
null_required_fields AS (
    SELECT
        'NULL in Required Field' as issue_type,
        'Products' as table_name,
        id::TEXT as identifier,
        1 as occurrence_count,
        'Severity: High' as severity,
        'Product ID: ' || id ||
        CASE
            WHEN name IS NULL THEN ' - Missing Name'
            WHEN price IS NULL THEN ' - Missing Price'
            WHEN category IS NULL THEN ' - Missing Category'
            ELSE ''
        END as affected_records
    FROM products
    WHERE name IS NULL OR price IS NULL OR category IS NULL

    UNION ALL

    SELECT
        'NULL in Required Field' as issue_type,
        'Customers' as table_name,
        id::TEXT as identifier,
        1 as occurrence_count,
        'Severity: High' as severity,
        'Customer ID: ' || id ||
        CASE
            WHEN name IS NULL THEN ' - Missing Name'
            WHEN email IS NULL THEN ' - Missing Email'
            ELSE ''
        END as affected_records
    FROM customers
    WHERE name IS NULL OR email IS NULL
),

-- 10. Outlier detection (unusually high values)
outliers AS (
    SELECT
        'Outlier Detected' as issue_type,
        'Orders' as table_name,
        o.id::TEXT as identifier,
        1 as occurrence_count,
        'Severity: Low' as severity,
        'Order ID: ' || o.id || ', Amount: ' || o.amount ||
        ' (Mean: ' || ROUND(avg_amount, 2) || ', StdDev: ' || ROUND(stddev_amount, 2) ||
        ', Z-score: ' || ROUND((o.amount - avg_amount) / stddev_amount, 2) || ')' as affected_records
    FROM orders o
    CROSS JOIN (
        SELECT AVG(amount) as avg_amount, STDDEV(amount) as stddev_amount
        FROM orders
        WHERE status = 'completed'
    ) stats
    WHERE o.status = 'completed'
      AND ABS(o.amount - stats.avg_amount) > 3 * stats.stddev_amount
),

-- Combine all issues
all_issues AS (
    SELECT * FROM duplicate_emails
    UNION ALL
    SELECT * FROM orphan_orders
    UNION ALL
    SELECT * FROM stock_issues
    UNION ALL
    SELECT * FROM invalid_emails
    UNION ALL
    SELECT * FROM circular_managers
    UNION ALL
    SELECT * FROM missing_dept_refs
    UNION ALL
    SELECT * FROM price_anomalies
    UNION ALL
    SELECT * FROM future_orders
    UNION ALL
    SELECT * FROM null_required_fields
    UNION ALL
    SELECT * FROM outliers
)

-- Executive Summary
SELECT
    issue_type,
    table_name,
    severity,
    COUNT(*) as total_issues,
    SUM(occurrence_count) as total_occurrences,
    STRING_AGG(
        SUBSTRING(affected_records, 1, 100),
        '; '
        ORDER BY identifier
    ) as sample_records
FROM all_issues
GROUP BY issue_type, table_name, severity

UNION ALL

-- Grand Total
SELECT
    'TOTAL ISSUES' as issue_type,
    'All Tables' as table_name,
    'Mixed' as severity,
    COUNT(DISTINCT issue_type) as issue_categories,
    SUM(occurrence_count) as total_problems,
    COUNT(*) || ' distinct issues found across ' ||
    COUNT(DISTINCT table_name) || ' tables' as summary
FROM all_issues

ORDER BY
    CASE severity
        WHEN 'Severity: High' THEN 1
        WHEN 'Severity: Medium' THEN 2
        WHEN 'Severity: Low' THEN 3
        ELSE 4
    END,
    total_issues DESC;
```

### Detailed Issue Report

```sql
-- Detailed view of all issues (for investigation)
WITH all_issues AS (
    -- [Same CTEs as above]
)
SELECT
    ROW_NUMBER() OVER (ORDER BY
        CASE severity
            WHEN 'Severity: High' THEN 1
            WHEN 'Severity: Medium' THEN 2
            WHEN 'Severity: Low' THEN 3
            ELSE 4
        END,
        issue_type
    ) as issue_number,
    issue_type,
    table_name,
    identifier,
    severity,
    affected_records,
    -- Suggested remediation
    CASE issue_type
        WHEN 'Duplicate Email' THEN 'Merge or remove duplicate accounts'
        WHEN 'Order Without Items' THEN 'Delete orphaned order or add items'
        WHEN 'Negative Stock' THEN 'Investigate inventory discrepancies'
        WHEN 'Invalid Email Format' THEN 'Request valid email from employee'
        WHEN 'Circular Management' THEN 'Fix organizational structure'
        WHEN 'Missing Department Reference' THEN 'Assign valid department'
        WHEN 'Price Anomaly' THEN 'Verify pricing and apply discounts correctly'
        WHEN 'Future Order Date' THEN 'Correct order date'
        WHEN 'NULL in Required Field' THEN 'Populate required field'
        WHEN 'Outlier Detected' THEN 'Verify large transaction is legitimate'
        ELSE 'Review and resolve'
    END as suggested_action
FROM all_issues
ORDER BY issue_number;
```

---

## Alternative Approaches

```sql
-- Method 1: Severity-based prioritization
WITH issues AS (
    -- ... all validation CTEs
),
severity_scores AS (
    SELECT
        *,
        CASE
            WHEN issue_type LIKE '%Duplicate%' THEN 10
            WHEN issue_type LIKE '%Missing%' THEN 10
            WHEN issue_type LIKE '%Circular%' THEN 9
            WHEN issue_type LIKE '%Orphan%' THEN 8
            WHEN issue_type LIKE '%Invalid%' THEN 7
            WHEN issue_type LIKE '%Negative%' THEN 6
            WHEN issue_type LIKE '%Anomaly%' THEN 5
            ELSE 3
        END as priority_score
    FROM issues
)
SELECT *
FROM severity_scores
ORDER BY priority_score DESC, table_name;

-- Method 2: Trend analysis (issues over time)
WITH issue_history AS (
    SELECT
        DATE_TRUNC('week', created_at) as week,
        issue_type,
        COUNT(*) as issue_count
    FROM data_quality_log  -- Historical log table
    GROUP BY DATE_TRUNC('week', created_at), issue_type
)
SELECT
    TO_CHAR(week, 'YYYY-MM-DD') as week,
    issue_type,
    issue_count,
    LAG(issue_count) OVER (PARTITION BY issue_type ORDER BY week) as prev_week,
    issue_count - LAG(issue_count) OVER (PARTITION BY issue_type ORDER BY week) as change
FROM issue_history
ORDER BY week DESC, issue_count DESC;

-- Method 3: Impact assessment
WITH issues AS (
    -- ... all validation CTEs
),
impact_analysis AS (
    SELECT
        issue_type,
        COUNT(*) as affected_records,
        CASE table_name
            WHEN 'Orders' THEN COUNT(*) * 100  -- High impact
            WHEN 'Customers' THEN COUNT(*) * 80
            WHEN 'Products' THEN COUNT(*) * 60
            ELSE COUNT(*) * 40
        END as impact_score
    FROM issues
    GROUP BY issue_type, table_name
)
SELECT
    issue_type,
    affected_records,
    impact_score,
    CASE
        WHEN impact_score > 500 THEN 'Critical'
        WHEN impact_score > 200 THEN 'High'
        WHEN impact_score > 100 THEN 'Medium'
        ELSE 'Low'
    END as impact_level
FROM impact_analysis
ORDER BY impact_score DESC;
```

---

## Try These Variations

1. Check for data type mismatches
2. Validate phone number formats
3. Find inconsistent naming conventions
4. Detect duplicate orders (same customer, date, amount)
5. Find customers with multiple default addresses
6. Validate date ranges (end date before start date)
7. Check for unrealistic values (age > 150, negative prices)

### Solutions to Variations

```sql
-- 1. Data type validation (values that can't be converted)
SELECT
    'Invalid Numeric Value' as issue_type,
    'Orders' as table_name,
    id as identifier,
    amount as problematic_value
FROM orders
WHERE amount::TEXT !~ '^[0-9]+\.?[0-9]*$'
   OR amount < 0;

-- 2. Phone number validation
SELECT
    'Invalid Phone Number' as issue_type,
    id,
    name,
    phone
FROM customers
WHERE phone IS NOT NULL
  AND phone !~ '^\+?[1-9]\d{1,14}$'  -- E.164 format
  AND phone !~ '^\([0-9]{3}\) [0-9]{3}-[0-9]{4}$'  -- US format
  AND phone !~ '^[0-9]{3}-[0-9]{3}-[0-9]{4}$';  -- US format

-- 3. Naming convention inconsistencies
WITH name_analysis AS (
    SELECT
        name,
        CASE
            WHEN name ~ '^[a-z]' THEN 'lowercase_start'
            WHEN name ~ '^[A-Z]' THEN 'uppercase_start'
            ELSE 'other'
        END as name_pattern,
        CASE
            WHEN name ~ '[^a-zA-Z\s-]' THEN 'contains_special'
            ELSE 'clean'
        END as special_chars
    FROM products
)
SELECT
    'Naming Inconsistency' as issue_type,
    name,
    name_pattern,
    special_chars
FROM name_analysis
WHERE special_chars = 'contains_special'
   OR name_pattern = 'lowercase_start';

-- 4. Duplicate orders
WITH order_fingerprints AS (
    SELECT
        customer_id,
        order_date,
        amount,
        COUNT(*) as duplicate_count,
        STRING_AGG(id::TEXT, ', ') as order_ids
    FROM orders
    GROUP BY customer_id, order_date, amount
    HAVING COUNT(*) > 1
)
SELECT
    'Duplicate Order' as issue_type,
    customer_id,
    order_date,
    amount,
    duplicate_count,
    order_ids
FROM order_fingerprints;

-- 5. Multiple default addresses
WITH default_address_count AS (
    SELECT
        customer_id,
        COUNT(*) as default_count
    FROM addresses
    WHERE is_default = true
    GROUP BY customer_id
    HAVING COUNT(*) > 1
)
SELECT
    'Multiple Default Addresses' as issue_type,
    c.name,
    dac.default_count,
    STRING_AGG(
        a.address_line1 || ', ' || a.city,
        '; '
    ) as addresses
FROM default_address_count dac
JOIN customers c ON dac.customer_id = c.id
JOIN addresses a ON c.id = a.customer_id AND a.is_default = true
GROUP BY c.id, c.name, dac.default_count;

-- 6. Invalid date ranges
SELECT
    'Invalid Date Range' as issue_type,
    'Projects' as table_name,
    id,
    name,
    start_date,
    end_date,
    end_date - start_date as duration
FROM projects
WHERE end_date < start_date
   OR start_date > CURRENT_DATE + INTERVAL '1 year'
   OR end_date < CURRENT_DATE - INTERVAL '10 years';

-- 7. Unrealistic values
WITH value_checks AS (
    SELECT
        'Unrealistic Age' as issue_type,
        'Employees' as table_name,
        id::TEXT as identifier,
        name,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) as age
    FROM employees
    WHERE birth_date IS NOT NULL
      AND (EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) < 16
           OR EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) > 100)

    UNION ALL

    SELECT
        'Negative Price' as issue_type,
        'Products' as table_name,
        id::TEXT,
        name,
        price
    FROM products
    WHERE price < 0

    UNION ALL

    SELECT
        'Unrealistic Price' as issue_type,
        'Products' as table_name,
        id::TEXT,
        name,
        price
    FROM products
    WHERE price > 1000000  -- Over $1M seems unrealistic

    UNION ALL

    SELECT
        'Unrealistic Quantity' as issue_type,
        'Order Items' as table_name,
        id::TEXT,
        product_id::TEXT,
        quantity
    FROM order_items
    WHERE quantity > 10000 OR quantity < 1
)
SELECT * FROM value_checks
ORDER BY issue_type, identifier;
```

---

## Sample Output

### Executive Summary
```
      issue_type        | table_name |   severity    | total_issues | sample_records
------------------------+------------+---------------+--------------+-------------------
 Duplicate Email        | Customers  | Severity: High|      15      | alice@ex.com, ...
 Missing Dept Reference | Employees  | Severity: High|       8      | Employee: John...
 Circular Management    | Employees  | Severity: High|       2      | Employee: Bob...
 Order Without Items    | Orders     | Severity: High|       5      | Order ID: 1234...
 Invalid Email Format   | Employees  | Severity: Med |      12      | Employee: Jane...
 Negative Stock         | Products   | Severity: Med |       3      | Product: USB...
 Price Anomaly          | Order Items| Severity: Med |      18      | Order Item...
 Outlier Detected       | Orders     | Severity: Low |       4      | Order ID: 5678...
 TOTAL ISSUES           | All Tables | Mixed         |       8      | 67 distinct...
```

### Detailed Report
```
 issue_number | issue_type         | identifier |  severity   | suggested_action
--------------+--------------------+------------+-------------+---------------------------
      1       | Duplicate Email    | alice@...  | High        | Merge or remove duplicates
      2       | Missing Dept Ref   | 42         | High        | Assign valid department
      3       | Circular Mgmt      | 15         | High        | Fix org structure
      4       | Order Without Items| 1234       | High        | Delete or add items
```

---

## Common Mistakes

1. **Not handling NULLs in comparisons:**
   ```sql
   -- WRONG: NULL = NULL returns NULL (not true)
   WHERE column = NULL

   -- CORRECT:
   WHERE column IS NULL
   ```

2. **Regex errors:**
   - Use `~` not `LIKE` for regex
   - Escape special characters properly
   - Test regex patterns thoroughly

3. **Performance issues:**
   - Large UNION queries can be slow
   - Index columns used in WHERE clauses
   - Consider running audits during off-peak hours

4. **Missing edge cases:**
   - Empty strings vs NULL
   - Whitespace-only values
   - Case sensitivity

5. **Not prioritizing issues:**
   - Not all issues are equal
   - Critical issues should be fixed first

6. **One-time check vs continuous monitoring:**
   - Set up automated data quality checks
   - Log issues for trend analysis

---

## Data Quality Automation

```sql
-- Create a data quality log table
CREATE TABLE data_quality_issues (
    id SERIAL PRIMARY KEY,
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    issue_type VARCHAR(100),
    table_name VARCHAR(100),
    identifier TEXT,
    severity VARCHAR(20),
    description TEXT,
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP
);

-- Insert current issues
INSERT INTO data_quality_issues (
    issue_type, table_name, identifier, severity, description
)
-- Run your audit CTEs and insert results

-- Create a scheduled job (using pg_cron or external scheduler)
-- to run audits regularly and log results

-- Monitor trends
SELECT
    DATE_TRUNC('day', detected_at) as day,
    issue_type,
    COUNT(*) as new_issues,
    SUM(CASE WHEN resolved THEN 1 ELSE 0 END) as resolved_issues
FROM data_quality_issues
WHERE detected_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', detected_at), issue_type
ORDER BY day DESC;
```

---

## Real-World Use Cases

1. **Data migration:** Validate data before/after migration
2. **Compliance:** Ensure data meets regulatory requirements
3. **Reporting:** Ensure accurate business intelligence
4. **API integration:** Validate external data sources
5. **ETL pipelines:** Data quality checks in transformation steps
6. **Customer support:** Identify data issues affecting users
7. **Database maintenance:** Regular health checks

---

## Related Problems

- **Previous:** [Problem 28 - Customer Retention Analysis](../28-customer-retention-analysis/)
- **Next:** [Problem 30 - Executive Dashboard](../30-executive-dashboard/)
- **Related:** Problem 21 (Pattern Matching), Problem 16 (NOT EXISTS), Problem 27 (Updates)

---

## Notes

```
Your notes here:




```

---

[← Previous](../28-customer-retention-analysis/) | [Back to Overview](../../README.md) | [Next Problem →](../30-executive-dashboard/)
