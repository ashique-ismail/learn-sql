# Problem 30: Executive Dashboard Query

**Difficulty:** Expert
**Concepts:** Comprehensive analytics, Complex CTEs, Dashboard queries, KPIs, Business intelligence
**Phase:** Real-World Scenarios (Days 21-25)

---

## Learning Objectives

- Master complex multi-CTE queries
- Calculate business KPIs and metrics
- Create comprehensive analytical reports
- Combine multiple data sources
- Format data for dashboard consumption
- Understand business metrics
- Optimize complex analytical queries

---

## Concept Summary

**Executive dashboards** provide high-level business metrics and KPIs in a single view. SQL can power these dashboards by combining multiple data sources, calculating derived metrics, and presenting data in a structured format.

### Common Dashboard Components

1. **KPIs:** Revenue, orders, customers, growth rates
2. **Trends:** Period-over-period comparisons
3. **Rankings:** Top performers by various metrics
4. **Distributions:** Segmentation and breakdown
5. **Health Metrics:** System and business health indicators

### Query Patterns

```sql
-- Multi-section dashboard pattern
WITH
  section1 AS (SELECT ...),
  section2 AS (SELECT ...),
  section3 AS (SELECT ...)
SELECT * FROM section1
UNION ALL
SELECT * FROM section2
UNION ALL
SELECT * FROM section3;

-- KPI calculation pattern
current_period AS (
    SELECT metric FROM table WHERE date >= period_start
),
previous_period AS (
    SELECT metric FROM table WHERE date >= prev_start AND date < period_start
)
SELECT
    current.metric,
    previous.metric,
    (current.metric - previous.metric) / previous.metric * 100 as growth_pct
FROM current_period current, previous_period previous;
```

---

## Problem Statement

**Task:** Create a comprehensive executive dashboard with:
1. **KPIs:** Total revenue, orders, customers (current month vs last month)
2. **Top Performers:** Top 5 employees by project hours
3. **Department Budget:** Budget utilization by department
4. **Product Performance:** Category performance trends
5. **Customer Metrics:** Order completion rate, customer satisfaction
6. **Revenue Forecast:** Based on recent trends

All in a single, structured query result set.

**Given:** All database tables (customers, orders, order_items, products, employees, departments, projects, project_assignments)

**Requirements:**
- Single query with multiple sections
- Period-over-period comparisons
- Formatted output ready for dashboard
- Include growth rates and percentages
- Provide actionable insights

---

## Hint

Use multiple CTEs for each dashboard section, calculate current vs previous periods, and combine with UNION ALL. Format numbers and percentages for display.

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

```sql
-- Comprehensive Executive Dashboard Query
WITH
-- Define date ranges for comparisons
date_ranges AS (
    SELECT
        DATE_TRUNC('month', CURRENT_DATE) as current_month_start,
        DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' as current_month_end,
        DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month' as prev_month_start,
        DATE_TRUNC('month', CURRENT_DATE) as prev_month_end,
        CURRENT_DATE - INTERVAL '30 days' as last_30_days,
        CURRENT_DATE - INTERVAL '90 days' as last_90_days
),

-- Section 1: Revenue KPIs
revenue_kpis AS (
    SELECT
        1 as sort_order,
        'KPI' as section,
        'Revenue' as metric,
        TO_CHAR(SUM(CASE
            WHEN o.order_date >= dr.current_month_start THEN oi.quantity * oi.price
            ELSE 0
        END), 'FM$999,999,990.00') as current_period,
        TO_CHAR(SUM(CASE
            WHEN o.order_date >= dr.prev_month_start AND o.order_date < dr.prev_month_end
            THEN oi.quantity * oi.price
            ELSE 0
        END), 'FM$999,999,990.00') as previous_period,
        TO_CHAR(ROUND(
            (SUM(CASE WHEN o.order_date >= dr.current_month_start THEN oi.quantity * oi.price ELSE 0 END) -
             SUM(CASE WHEN o.order_date >= dr.prev_month_start AND o.order_date < dr.prev_month_end
                 THEN oi.quantity * oi.price ELSE 0 END)) /
            NULLIF(SUM(CASE WHEN o.order_date >= dr.prev_month_start AND o.order_date < dr.prev_month_end
                THEN oi.quantity * oi.price ELSE 0 END), 0) * 100, 2
        ), 'FM990.00') || '%' as growth_rate
    FROM orders o
    JOIN order_items oi ON o.id = oi.order_id
    CROSS JOIN date_ranges dr
    WHERE o.status = 'completed'
    GROUP BY dr.current_month_start, dr.current_month_end, dr.prev_month_start, dr.prev_month_end
),

-- Section 2: Order KPIs
order_kpis AS (
    SELECT
        2 as sort_order,
        'KPI' as section,
        'Total Orders' as metric,
        COUNT(CASE WHEN o.order_date >= dr.current_month_start THEN 1 END)::TEXT as current_period,
        COUNT(CASE WHEN o.order_date >= dr.prev_month_start AND o.order_date < dr.prev_month_end
              THEN 1 END)::TEXT as previous_period,
        TO_CHAR(ROUND(
            (COUNT(CASE WHEN o.order_date >= dr.current_month_start THEN 1 END)::NUMERIC -
             COUNT(CASE WHEN o.order_date >= dr.prev_month_start AND o.order_date < dr.prev_month_end THEN 1 END)) /
            NULLIF(COUNT(CASE WHEN o.order_date >= dr.prev_month_start AND o.order_date < dr.prev_month_end
                THEN 1 END), 0) * 100, 2
        ), 'FM990.00') || '%' as growth_rate
    FROM orders o
    CROSS JOIN date_ranges dr
    WHERE o.status = 'completed'
    GROUP BY dr.current_month_start, dr.prev_month_start, dr.prev_month_end
),

-- Section 3: Customer KPIs
customer_kpis AS (
    SELECT
        3 as sort_order,
        'KPI' as section,
        'Active Customers' as metric,
        COUNT(DISTINCT CASE WHEN o.order_date >= dr.last_30_days THEN o.customer_id END)::TEXT as current_period,
        COUNT(DISTINCT CASE WHEN o.order_date >= dr.last_90_days AND o.order_date < dr.last_30_days
              THEN o.customer_id END)::TEXT as previous_period,
        TO_CHAR(ROUND(
            (COUNT(DISTINCT CASE WHEN o.order_date >= dr.last_30_days THEN o.customer_id END)::NUMERIC -
             COUNT(DISTINCT CASE WHEN o.order_date >= dr.last_90_days AND o.order_date < dr.last_30_days
                 THEN o.customer_id END)) /
            NULLIF(COUNT(DISTINCT CASE WHEN o.order_date >= dr.last_90_days AND o.order_date < dr.last_30_days
                THEN o.customer_id END), 0) * 100, 2
        ), 'FM990.00') || '%' as growth_rate
    FROM orders o
    CROSS JOIN date_ranges dr
    WHERE o.status = 'completed'
    GROUP BY dr.last_30_days, dr.last_90_days
),

-- Section 4: Average Order Value
aov_kpis AS (
    SELECT
        4 as sort_order,
        'KPI' as section,
        'Avg Order Value' as metric,
        TO_CHAR(AVG(CASE WHEN o.order_date >= dr.current_month_start THEN o.amount END),
                'FM$999,990.00') as current_period,
        TO_CHAR(AVG(CASE WHEN o.order_date >= dr.prev_month_start AND o.order_date < dr.prev_month_end
                    THEN o.amount END), 'FM$999,990.00') as previous_period,
        TO_CHAR(ROUND(
            (AVG(CASE WHEN o.order_date >= dr.current_month_start THEN o.amount END) -
             AVG(CASE WHEN o.order_date >= dr.prev_month_start AND o.order_date < dr.prev_month_end
                 THEN o.amount END)) /
            NULLIF(AVG(CASE WHEN o.order_date >= dr.prev_month_start AND o.order_date < dr.prev_month_end
                THEN o.amount END), 0) * 100, 2
        ), 'FM990.00') || '%' as growth_rate
    FROM orders o
    CROSS JOIN date_ranges dr
    WHERE o.status = 'completed'
    GROUP BY dr.current_month_start, dr.prev_month_start, dr.prev_month_end
),

-- Section 5: Top Performing Employees
top_employees AS (
    SELECT
        10 as sort_order,
        'Top Performers' as section,
        e.name as metric,
        SUM(pa.hours_allocated)::TEXT || ' hrs' as current_period,
        COUNT(DISTINCT pa.project_id)::TEXT || ' projects' as previous_period,
        CASE
            WHEN AVG(COALESCE(pr.rating, 4.0)) >= 4.5 THEN 'Excellent'
            WHEN AVG(COALESCE(pr.rating, 4.0)) >= 4.0 THEN 'Very Good'
            WHEN AVG(COALESCE(pr.rating, 4.0)) >= 3.5 THEN 'Good'
            ELSE 'Average'
        END as growth_rate
    FROM employees e
    JOIN project_assignments pa ON e.id = pa.employee_id
    LEFT JOIN performance_reviews pr ON e.id = pr.employee_id
        AND pr.review_date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY e.id, e.name
    ORDER BY SUM(pa.hours_allocated) DESC
    LIMIT 5
),

-- Section 6: Department Budget Utilization
dept_budget AS (
    SELECT
        20 as sort_order,
        'Department Budget' as section,
        d.dept_name as metric,
        TO_CHAR(SUM(e.salary), 'FM$999,999,990') as current_period,
        TO_CHAR(d.budget, 'FM$999,999,990') as previous_period,
        TO_CHAR(ROUND(SUM(e.salary) / NULLIF(d.budget, 0) * 100, 2), 'FM990.00') || '%' as growth_rate
    FROM departments d
    LEFT JOIN employees e ON d.id = e.dept_id
    WHERE d.budget > 0
    GROUP BY d.id, d.dept_name, d.budget
    ORDER BY SUM(e.salary) / NULLIF(d.budget, 0) DESC
    LIMIT 5
),

-- Section 7: Product Category Performance
category_performance AS (
    SELECT
        30 as sort_order,
        'Category Performance' as section,
        p.category as metric,
        TO_CHAR(SUM(oi.quantity * oi.price), 'FM$999,999,990') as current_period,
        SUM(oi.quantity)::TEXT || ' units' as previous_period,
        TO_CHAR(ROUND(AVG(oi.price), 2), 'FM$990.00') as growth_rate
    FROM products p
    JOIN order_items oi ON p.id = oi.product_id
    JOIN orders o ON oi.order_id = o.id
    CROSS JOIN date_ranges dr
    WHERE o.status = 'completed'
      AND o.order_date >= dr.last_90_days
    GROUP BY p.category
    ORDER BY SUM(oi.quantity * oi.price) DESC
    LIMIT 5
),

-- Section 8: Order Fulfillment Metrics
fulfillment_metrics AS (
    SELECT
        40 as sort_order,
        'Fulfillment' as section,
        'Completion Rate' as metric,
        TO_CHAR(ROUND(
            COUNT(CASE WHEN status = 'completed' THEN 1 END)::NUMERIC /
            NULLIF(COUNT(*), 0) * 100, 2
        ), 'FM990.00') || '%' as current_period,
        COUNT(*)::TEXT || ' orders' as previous_period,
        TO_CHAR(ROUND(AVG(
            EXTRACT(EPOCH FROM (updated_at - created_at)) / 3600
        ), 1), 'FM990.0') || ' hrs' as growth_rate
    FROM orders
    CROSS JOIN date_ranges dr
    WHERE order_date >= dr.current_month_start
),

-- Section 9: Customer Satisfaction (based on repeat orders)
customer_satisfaction AS (
    SELECT
        41 as sort_order,
        'Satisfaction' as section,
        'Repeat Customer Rate' as metric,
        TO_CHAR(ROUND(
            COUNT(DISTINCT CASE WHEN order_count > 1 THEN customer_id END)::NUMERIC /
            NULLIF(COUNT(DISTINCT customer_id), 0) * 100, 2
        ), 'FM990.00') || '%' as current_period,
        COUNT(DISTINCT customer_id)::TEXT || ' customers' as previous_period,
        TO_CHAR(ROUND(AVG(order_count), 2), 'FM990.00') as growth_rate
    FROM (
        SELECT
            customer_id,
            COUNT(*) as order_count
        FROM orders o
        CROSS JOIN date_ranges dr
        WHERE o.status = 'completed'
          AND o.order_date >= dr.last_90_days
        GROUP BY customer_id
    ) customer_orders
),

-- Section 10: Revenue Forecast (simple linear projection)
revenue_forecast AS (
    SELECT
        50 as sort_order,
        'Forecast' as section,
        'Next Month Projection' as metric,
        TO_CHAR(
            ROUND(
                AVG(daily_revenue) * 30,  -- 30 days projection
                2
            ),
            'FM$999,999,990.00'
        ) as current_period,
        'Based on last 30 days' as previous_period,
        TO_CHAR(ROUND(
            (AVG(daily_revenue) * 30 - SUM(CASE WHEN oi.order_date >= dr.prev_month_start
                AND oi.order_date < dr.prev_month_end THEN oi.quantity * oi.price ELSE 0 END)) /
            NULLIF(SUM(CASE WHEN oi.order_date >= dr.prev_month_start AND oi.order_date < dr.prev_month_end
                THEN oi.quantity * oi.price ELSE 0 END), 0) * 100,
            2
        ), 'FM990.00') || '%' as growth_rate
    FROM (
        SELECT
            DATE(o.order_date) as order_date,
            SUM(oi.quantity * oi.price) as daily_revenue
        FROM orders o
        JOIN order_items oi ON o.id = oi.order_id
        CROSS JOIN date_ranges dr
        WHERE o.status = 'completed'
          AND o.order_date >= dr.last_30_days
        GROUP BY DATE(o.order_date)
    ) daily_data
    CROSS JOIN (
        SELECT
            o.order_date,
            oi.quantity * oi.price
        FROM orders o
        JOIN order_items oi ON o.id = oi.order_id
        CROSS JOIN date_ranges dr
        WHERE o.status = 'completed'
    ) oi
    CROSS JOIN date_ranges dr
    GROUP BY dr.prev_month_start, dr.prev_month_end
),

-- Section 11: Inventory Health
inventory_health AS (
    SELECT
        60 as sort_order,
        'Inventory' as section,
        CASE
            WHEN stock_quantity = 0 THEN 'Out of Stock'
            WHEN stock_quantity < 10 THEN 'Low Stock'
            ELSE 'Adequate Stock'
        END as metric,
        COUNT(*)::TEXT as current_period,
        TO_CHAR(
            ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2),
            'FM990.00'
        ) || '%' as previous_period,
        TO_CHAR(SUM(price * stock_quantity), 'FM$999,999,990') as growth_rate
    FROM products
    GROUP BY CASE
        WHEN stock_quantity = 0 THEN 'Out of Stock'
        WHEN stock_quantity < 10 THEN 'Low Stock'
        ELSE 'Adequate Stock'
    END
)

-- Combine all sections
SELECT
    section,
    metric,
    current_period,
    previous_period,
    growth_rate
FROM revenue_kpis

UNION ALL SELECT section, metric, current_period, previous_period, growth_rate FROM order_kpis
UNION ALL SELECT section, metric, current_period, previous_period, growth_rate FROM customer_kpis
UNION ALL SELECT section, metric, current_period, previous_period, growth_rate FROM aov_kpis
UNION ALL SELECT section, metric, current_period, previous_period, growth_rate FROM top_employees
UNION ALL SELECT section, metric, current_period, previous_period, growth_rate FROM dept_budget
UNION ALL SELECT section, metric, current_period, previous_period, growth_rate FROM category_performance
UNION ALL SELECT section, metric, current_period, previous_period, growth_rate FROM fulfillment_metrics
UNION ALL SELECT section, metric, current_period, previous_period, growth_rate FROM customer_satisfaction
UNION ALL SELECT section, metric, current_period, previous_period, growth_rate FROM revenue_forecast
UNION ALL SELECT section, metric, current_period, previous_period, growth_rate FROM inventory_health

ORDER BY sort_order, metric;
```

### Simplified Version (for learning)

```sql
-- Simplified Executive Dashboard
WITH
date_ranges AS (
    SELECT
        DATE_TRUNC('month', CURRENT_DATE) as current_month,
        DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month' as prev_month
),

-- Current month metrics
current_metrics AS (
    SELECT
        COUNT(DISTINCT o.id) as orders,
        COUNT(DISTINCT o.customer_id) as customers,
        SUM(o.amount) as revenue
    FROM orders o
    CROSS JOIN date_ranges dr
    WHERE o.status = 'completed'
      AND o.order_date >= dr.current_month
),

-- Previous month metrics
previous_metrics AS (
    SELECT
        COUNT(DISTINCT o.id) as orders,
        COUNT(DISTINCT o.customer_id) as customers,
        SUM(o.amount) as revenue
    FROM orders o
    CROSS JOIN date_ranges dr
    WHERE o.status = 'completed'
      AND o.order_date >= dr.prev_month
      AND o.order_date < dr.current_month
)

-- Summary output
SELECT
    'Orders' as metric,
    c.orders as current_value,
    p.orders as previous_value,
    ROUND((c.orders - p.orders) * 100.0 / p.orders, 2) as growth_pct
FROM current_metrics c, previous_metrics p

UNION ALL

SELECT
    'Customers',
    c.customers,
    p.customers,
    ROUND((c.customers - p.customers) * 100.0 / p.customers, 2)
FROM current_metrics c, previous_metrics p

UNION ALL

SELECT
    'Revenue',
    c.revenue,
    p.revenue,
    ROUND((c.revenue - p.revenue) * 100.0 / p.revenue, 2)
FROM current_metrics c, previous_metrics p;
```

---

## Sample Output

```
     section      |         metric          | current_period  | previous_period | growth_rate
------------------+-------------------------+-----------------+-----------------+-------------
 KPI              | Revenue                 | $1,245,678.90   | $1,123,456.00   | +10.88%
 KPI              | Total Orders            | 1,456           | 1,234           | +18.00%
 KPI              | Active Customers        | 892             | 823             | +8.39%
 KPI              | Avg Order Value         | $855.50         | $910.50         | -6.04%
 Top Performers   | Alice Johnson           | 180 hrs         | 12 projects     | Excellent
 Top Performers   | Bob Smith               | 165 hrs         | 10 projects     | Very Good
 Top Performers   | Carol White             | 152 hrs         | 9 projects      | Very Good
 Department Budget| Engineering             | $2,450,000      | $2,800,000      | 87.50%
 Department Budget| Sales                   | $1,230,000      | $1,500,000      | 82.00%
 Category Performance | Electronics          | $456,789        | 1,234 units     | $370.25
 Category Performance | Furniture            | $234,567        | 567 units       | $413.75
 Fulfillment      | Completion Rate         | 94.50%          | 1,456 orders    | 24.5 hrs
 Satisfaction     | Repeat Customer Rate    | 67.80%          | 892 customers   | 2.45
 Forecast         | Next Month Projection   | $1,350,000.00   | Based on last 30| +12.50%
 Inventory        | Out of Stock            | 15              | 3.50%           | $0
 Inventory        | Low Stock               | 42              | 9.80%           | $42,350
 Inventory        | Adequate Stock          | 371             | 86.70%          | $2,456,780
```

---

## Alternative Approaches

```sql
-- Method 1: JSON output for APIs
WITH dashboard_data AS (
    -- ... all your CTEs
)
SELECT JSON_BUILD_OBJECT(
    'kpis', (SELECT JSON_AGG(row_to_json(t)) FROM (
        SELECT metric, current_period, growth_rate
        FROM dashboard_data
        WHERE section = 'KPI'
    ) t),
    'top_performers', (SELECT JSON_AGG(row_to_json(t)) FROM (
        SELECT metric, current_period
        FROM dashboard_data
        WHERE section = 'Top Performers'
    ) t),
    'categories', (SELECT JSON_AGG(row_to_json(t)) FROM (
        SELECT metric, current_period, growth_rate
        FROM dashboard_data
        WHERE section = 'Category Performance'
    ) t)
) as dashboard_json;

-- Method 2: Materialized view for performance
CREATE MATERIALIZED VIEW dashboard_cache AS
-- ... your full dashboard query

-- Refresh strategy
REFRESH MATERIALIZED VIEW dashboard_cache;

-- Or concurrent refresh (doesn't block reads)
REFRESH MATERIALIZED VIEW CONCURRENTLY dashboard_cache;

-- Method 3: Parameterized date ranges
CREATE OR REPLACE FUNCTION get_dashboard(
    p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
    p_end_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    section TEXT,
    metric TEXT,
    value NUMERIC,
    formatted_value TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH date_range AS (
        SELECT p_start_date as start_date, p_end_date as end_date
    )
    -- ... rest of dashboard query using date_range CTE
    ;
END;
$$ LANGUAGE plpgsql;

-- Usage
SELECT * FROM get_dashboard('2024-01-01', '2024-01-31');
```

---

## Performance Optimization

```sql
-- 1. Create summary tables for historical data
CREATE TABLE daily_summary (
    summary_date DATE PRIMARY KEY,
    total_revenue DECIMAL(12,2),
    total_orders INTEGER,
    unique_customers INTEGER,
    avg_order_value DECIMAL(10,2),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Populate daily (via scheduled job)
INSERT INTO daily_summary
SELECT
    DATE(order_date) as summary_date,
    SUM(amount) as total_revenue,
    COUNT(*) as total_orders,
    COUNT(DISTINCT customer_id) as unique_customers,
    AVG(amount) as avg_order_value,
    CURRENT_TIMESTAMP
FROM orders
WHERE status = 'completed'
  AND order_date >= CURRENT_DATE - INTERVAL '1 day'
  AND order_date < CURRENT_DATE
GROUP BY DATE(order_date)
ON CONFLICT (summary_date)
DO UPDATE SET
    total_revenue = EXCLUDED.total_revenue,
    total_orders = EXCLUDED.total_orders,
    unique_customers = EXCLUDED.unique_customers,
    avg_order_value = EXCLUDED.avg_order_value,
    updated_at = CURRENT_TIMESTAMP;

-- 2. Use appropriate indexes
CREATE INDEX idx_orders_date_status ON orders(order_date, status);
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);
CREATE INDEX idx_order_items_order ON order_items(order_id);

-- 3. Partition large tables by date
CREATE TABLE orders_partitioned (
    -- columns
) PARTITION BY RANGE (order_date);

CREATE TABLE orders_2024_01 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

-- 4. Monitor query performance
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
-- your dashboard query
```

---

## Common Mistakes

1. **Incorrect date comparisons:**
   - Be careful with timezone handling
   - Use DATE_TRUNC for consistent period boundaries

2. **Division by zero:**
   - Always use NULLIF for denominators
   - Handle cases where previous period has no data

3. **Performance issues:**
   - Complex dashboard queries can be slow
   - Consider caching/materialized views
   - Use appropriate indexes

4. **Inconsistent metrics:**
   - Ensure all sections use same date ranges
   - Be consistent with status filtering

5. **Missing NULL handling:**
   - Use COALESCE for metrics that might be NULL
   - Handle customers/products with no activity

6. **Overcomplicated queries:**
   - Break complex calculations into CTEs
   - Comment your code well
   - Consider creating helper functions

---

## Real-World Use Cases

1. **Executive reporting:** C-level monthly business review
2. **Sales dashboard:** Team performance and pipeline
3. **Operations dashboard:** Fulfillment and inventory
4. **Marketing dashboard:** Campaign performance and ROI
5. **Financial dashboard:** Revenue, costs, profitability
6. **Customer success:** Health scores and churn risk
7. **Product analytics:** Usage and engagement metrics

---

## Dashboard Best Practices

1. **Keep it simple:** 5-7 key metrics maximum
2. **Be consistent:** Same time periods, same definitions
3. **Provide context:** Show trends, not just numbers
4. **Make it actionable:** Highlight what needs attention
5. **Update regularly:** Real-time or scheduled refreshes
6. **Optimize performance:** Cache when possible
7. **Document metrics:** Define how each is calculated

---

## Testing Your Dashboard

```sql
-- Test with known data
BEGIN;

-- Insert test data
INSERT INTO orders (customer_id, order_date, status, amount)
VALUES (1, CURRENT_DATE, 'completed', 100.00);

-- Run dashboard query
-- ... your dashboard query

-- Verify results
-- Check that new order appears in metrics

ROLLBACK;  -- Don't commit test data

-- Test date ranges
SELECT * FROM your_dashboard_function(
    '2024-01-01'::DATE,
    '2024-01-31'::DATE
);

-- Test performance
EXPLAIN ANALYZE
-- your dashboard query
```

---

## Congratulations!

You've completed all 30 SQL problems! You've learned:

- Basic SQL fundamentals (SELECT, WHERE, JOIN)
- Advanced querying (CTEs, window functions, subqueries)
- Data manipulation (INSERT, UPDATE, DELETE, transactions)
- Database design (tables, indexes, constraints)
- Query optimization (EXPLAIN, indexes, performance)
- Real-world analytics (dashboards, metrics, reporting)

**Next Steps:**
1. Review problems you found challenging
2. Apply these skills to your own projects
3. Explore advanced topics (stored procedures, triggers, partitioning)
4. Practice on real datasets
5. Contribute to open-source projects
6. Keep learning and experimenting!

---

## Related Problems

- **Previous:** [Problem 29 - Data Quality Audit](../29-data-quality-audit/)
- **Review:** [Problem 1 - Basic Select](../01-basic-select/) | [Problem 10 - Window Functions](../10-salary-ranking/) | [Problem 20 - E-commerce Analytics](../20-ecommerce-analytics/)
- **Summary:** [Overview](../../README.md) | [All Problems](../../README.md#summary-of-all-30-problems)

---

## Notes

```
Your notes here:

What did you learn from this journey?

What was your favorite problem?

What will you work on next?


```

---

[← Previous](../29-data-quality-audit/) | [Back to Overview](../../README.md) | [🎉 Completed!](../../README.md)
