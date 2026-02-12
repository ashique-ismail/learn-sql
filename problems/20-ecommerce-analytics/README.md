# Problem 20: E-commerce Analytics

**Difficulty:** Advanced
**Concepts:** Complex analytics, Multiple CTEs, Window functions, Aggregations, Business intelligence
**Phase:** Real-World Scenarios (Days 21-25)

---

## Learning Objectives

- Combine multiple advanced SQL techniques
- Build comprehensive analytical reports
- Use multiple CTEs for complex business logic
- Calculate growth rates and trends
- Perform product basket analysis
- Create executive-level insights

---

## Concept Summary

**Complex analytics** queries combine multiple SQL techniques to answer sophisticated business questions, often involving temporal analysis, cohort analysis, and multi-dimensional aggregations.

---

## Problem Statement

**Given tables:**
- users(id, name, email, city)
- products(id, name, price, category)
- orders(id, user_id, order_date, status)  -- status: completed, cancelled, pending
- order_items(order_id, product_id, quantity)

**Task:** Create a comprehensive report showing:
1. Top 10 products by revenue (only completed orders)
2. Month-over-month growth rate for last 6 months
3. Average order value by city
4. Products frequently bought together (>= 10 times)

---

## Hint

Break the problem into multiple CTEs, one for each requirement, then combine with UNION ALL or present separately.

---

## Your Solution

```sql
-- Write your comprehensive analytics query here




```

---

## Solution

```sql
-- Part 1: Top 10 products by revenue
WITH product_revenue AS (
    SELECT
        p.id,
        p.name,
        p.category,
        SUM(oi.quantity * p.price) as revenue,
        SUM(oi.quantity) as units_sold,
        COUNT(DISTINCT o.id) as order_count
    FROM products p
    JOIN order_items oi ON p.id = oi.product_id
    JOIN orders o ON oi.order_id = o.id
    WHERE o.status = 'completed'
    GROUP BY p.id, p.name, p.category
    ORDER BY revenue DESC
    LIMIT 10
),

-- Part 2: Monthly revenue and growth
monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date) as month,
        SUM(oi.quantity * p.price) as revenue,
        COUNT(DISTINCT o.id) as order_count,
        COUNT(DISTINCT o.user_id) as customer_count
    FROM orders o
    JOIN order_items oi ON o.id = oi.order_id
    JOIN products p ON oi.product_id = p.id
    WHERE o.status = 'completed'
      AND o.order_date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY DATE_TRUNC('month', o.order_date)
),
monthly_growth AS (
    SELECT
        month,
        revenue,
        order_count,
        customer_count,
        LAG(revenue) OVER (ORDER BY month) as prev_month_revenue,
        ROUND(
            ((revenue - LAG(revenue) OVER (ORDER BY month)) /
             NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100),
            2
        ) as growth_rate_pct
    FROM monthly_revenue
),

-- Part 3: Average order value by city
city_aov AS (
    SELECT
        u.city,
        COUNT(DISTINCT o.id) as order_count,
        COUNT(DISTINCT o.user_id) as customer_count,
        ROUND(AVG(order_total.total), 2) as avg_order_value,
        ROUND(SUM(order_total.total), 2) as total_revenue
    FROM users u
    JOIN orders o ON u.id = o.user_id
    JOIN (
        SELECT
            oi.order_id,
            SUM(oi.quantity * p.price) as total
        FROM order_items oi
        JOIN products p ON oi.product_id = p.id
        GROUP BY oi.order_id
    ) order_total ON o.id = order_total.order_id
    WHERE o.status = 'completed'
    GROUP BY u.city
    HAVING COUNT(DISTINCT o.id) >= 5  -- Cities with at least 5 orders
),

-- Part 4: Frequently bought together
product_pairs AS (
    SELECT
        oi1.product_id as product1_id,
        p1.name as product1_name,
        p1.category as product1_category,
        oi2.product_id as product2_id,
        p2.name as product2_name,
        p2.category as product2_category,
        COUNT(*) as times_together
    FROM order_items oi1
    JOIN order_items oi2 ON oi1.order_id = oi2.order_id
                         AND oi1.product_id < oi2.product_id  -- Avoid duplicates
    JOIN products p1 ON oi1.product_id = p1.id
    JOIN products p2 ON oi2.product_id = p2.id
    JOIN orders o ON oi1.order_id = o.id
    WHERE o.status = 'completed'
    GROUP BY oi1.product_id, p1.name, p1.category, oi2.product_id, p2.name, p2.category
    HAVING COUNT(*) >= 10
    ORDER BY times_together DESC
)

-- Present all results
SELECT 'Top Products' as report_section, * FROM (
    SELECT
        name as detail,
        category as metric1,
        CAST(revenue as TEXT) as value1,
        CAST(units_sold as TEXT) as value2
    FROM product_revenue
) top_products

UNION ALL

SELECT 'Monthly Growth' as report_section, * FROM (
    SELECT
        TO_CHAR(month, 'YYYY-MM') as detail,
        'Revenue: $' || revenue as metric1,
        'Growth: ' || COALESCE(growth_rate_pct::TEXT, 'N/A') || '%' as value1,
        'Orders: ' || order_count as value2
    FROM monthly_growth
    ORDER BY month
) monthly

UNION ALL

SELECT 'City Performance' as report_section, * FROM (
    SELECT
        city as detail,
        'AOV: $' || avg_order_value as metric1,
        'Revenue: $' || total_revenue as value1,
        'Customers: ' || customer_count as value2
    FROM city_aov
    ORDER BY total_revenue DESC
) cities

UNION ALL

SELECT 'Product Pairs' as report_section, * FROM (
    SELECT
        product1_name || ' + ' || product2_name as detail,
        product1_category || ' & ' || product2_category as metric1,
        'Bought together: ' || times_together || ' times' as value1,
        '' as value2
    FROM product_pairs
) pairs

ORDER BY report_section, detail;
```

---

## Alternative: Separate Reports

### Report 1: Product Performance Dashboard

```sql
WITH product_metrics AS (
    SELECT
        p.id,
        p.name,
        p.category,
        p.price,
        SUM(oi.quantity) as units_sold,
        SUM(oi.quantity * p.price) as total_revenue,
        COUNT(DISTINCT oi.order_id) as order_count,
        COUNT(DISTINCT o.user_id) as unique_customers,
        ROUND(AVG(oi.quantity), 2) as avg_quantity_per_order
    FROM products p
    LEFT JOIN order_items oi ON p.id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.id AND o.status = 'completed'
    GROUP BY p.id, p.name, p.category, p.price
)
SELECT
    name,
    category,
    price,
    COALESCE(units_sold, 0) as units_sold,
    COALESCE(total_revenue, 0) as revenue,
    COALESCE(order_count, 0) as orders,
    COALESCE(unique_customers, 0) as customers,
    COALESCE(avg_quantity_per_order, 0) as avg_qty_per_order,
    RANK() OVER (ORDER BY total_revenue DESC NULLS LAST) as revenue_rank,
    RANK() OVER (PARTITION BY category ORDER BY total_revenue DESC NULLS LAST) as category_rank,
    CASE
        WHEN units_sold > 100 THEN 'Best Seller'
        WHEN units_sold > 50 THEN 'Popular'
        WHEN units_sold > 10 THEN 'Moderate'
        WHEN units_sold > 0 THEN 'Slow Moving'
        ELSE 'No Sales'
    END as performance_tier
FROM product_metrics
ORDER BY revenue DESC;
```

### Report 2: Customer Cohort Analysis

```sql
WITH customer_first_order AS (
    SELECT
        user_id,
        DATE_TRUNC('month', MIN(order_date)) as cohort_month
    FROM orders
    WHERE status = 'completed'
    GROUP BY user_id
),
cohort_activity AS (
    SELECT
        cfo.cohort_month,
        DATE_TRUNC('month', o.order_date) as activity_month,
        COUNT(DISTINCT o.user_id) as active_users,
        SUM(oi.quantity * p.price) as revenue
    FROM customer_first_order cfo
    JOIN orders o ON cfo.user_id = o.user_id
    JOIN order_items oi ON o.id = oi.order_id
    JOIN products p ON oi.product_id = p.id
    WHERE o.status = 'completed'
    GROUP BY cfo.cohort_month, DATE_TRUNC('month', o.order_date)
),
cohort_size AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT user_id) as cohort_size
    FROM customer_first_order
    GROUP BY cohort_month
)
SELECT
    TO_CHAR(ca.cohort_month, 'YYYY-MM') as cohort,
    TO_CHAR(ca.activity_month, 'YYYY-MM') as month,
    EXTRACT(MONTH FROM AGE(ca.activity_month, ca.cohort_month)) as months_since_first,
    cs.cohort_size,
    ca.active_users,
    ROUND(100.0 * ca.active_users / cs.cohort_size, 2) as retention_rate,
    ROUND(ca.revenue, 2) as revenue
FROM cohort_activity ca
JOIN cohort_size cs ON ca.cohort_month = cs.cohort_month
WHERE ca.cohort_month >= CURRENT_DATE - INTERVAL '12 months'
ORDER BY ca.cohort_month, ca.activity_month;
```

### Report 3: Category Performance Trends

```sql
WITH monthly_category_stats AS (
    SELECT
        DATE_TRUNC('month', o.order_date) as month,
        p.category,
        SUM(oi.quantity * p.price) as revenue,
        SUM(oi.quantity) as units_sold,
        COUNT(DISTINCT o.id) as order_count,
        COUNT(DISTINCT o.user_id) as customer_count
    FROM orders o
    JOIN order_items oi ON o.id = oi.order_id
    JOIN products p ON oi.product_id = p.id
    WHERE o.status = 'completed'
      AND o.order_date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY DATE_TRUNC('month', o.order_date), p.category
)
SELECT
    TO_CHAR(month, 'YYYY-MM') as month,
    category,
    revenue,
    units_sold,
    order_count,
    customer_count,
    LAG(revenue) OVER (PARTITION BY category ORDER BY month) as prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (PARTITION BY category ORDER BY month)) /
        NULLIF(LAG(revenue) OVER (PARTITION BY category ORDER BY month), 0) * 100,
        2
    ) as mom_growth_pct,
    SUM(revenue) OVER (PARTITION BY category ORDER BY month) as cumulative_revenue,
    ROUND(
        revenue / SUM(revenue) OVER (PARTITION BY month) * 100,
        2
    ) as pct_of_month_total
FROM monthly_category_stats
ORDER BY month, revenue DESC;
```

### Report 4: Customer Lifetime Value (CLV)

```sql
WITH customer_metrics AS (
    SELECT
        u.id,
        u.name,
        u.email,
        u.city,
        MIN(o.order_date) as first_order_date,
        MAX(o.order_date) as last_order_date,
        COUNT(DISTINCT o.id) as total_orders,
        SUM(oi.quantity * p.price) as lifetime_value,
        AVG(oi.quantity * p.price) as avg_order_value,
        MAX(o.order_date) - MIN(o.order_date) as customer_lifespan_days,
        CURRENT_DATE - MAX(o.order_date) as days_since_last_order
    FROM users u
    LEFT JOIN orders o ON u.id = o.user_id AND o.status = 'completed'
    LEFT JOIN order_items oi ON o.id = oi.order_id
    LEFT JOIN products p ON oi.product_id = p.id
    GROUP BY u.id, u.name, u.email, u.city
)
SELECT
    name,
    email,
    city,
    first_order_date,
    last_order_date,
    total_orders,
    ROUND(lifetime_value, 2) as clv,
    ROUND(avg_order_value, 2) as aov,
    customer_lifespan_days,
    days_since_last_order,
    CASE
        WHEN total_orders = 0 THEN 'Never Purchased'
        WHEN days_since_last_order > 180 THEN 'Churned'
        WHEN days_since_last_order > 90 THEN 'At Risk'
        WHEN days_since_last_order > 30 THEN 'Inactive'
        ELSE 'Active'
    END as customer_status,
    CASE
        WHEN lifetime_value > 5000 THEN 'VIP'
        WHEN lifetime_value > 2000 THEN 'High Value'
        WHEN lifetime_value > 500 THEN 'Medium Value'
        WHEN lifetime_value > 0 THEN 'Low Value'
        ELSE 'No Value'
    END as value_segment,
    NTILE(10) OVER (ORDER BY lifetime_value DESC NULLS LAST) as decile
FROM customer_metrics
ORDER BY lifetime_value DESC NULLS LAST;
```

---

## Sample Output

### Top Products Report
```
      name       | category    | revenue  | units_sold | orders
-----------------+-------------+----------+------------+--------
 iPhone 14 Pro   | Electronics | 45230.00 |     45     |   42
 MacBook Air     | Electronics | 38990.00 |     31     |   30
 AirPods Pro     | Electronics | 12450.00 |     50     |   47
 Gaming Laptop   | Electronics | 11200.00 |      8     |    8
 Wireless Mouse  | Accessories |  2340.00 |     78     |   65
```

### Monthly Growth Report
```
  month   | revenue   | growth_rate_pct | orders | customers
----------+-----------+-----------------+--------+-----------
 2023-08  | 125430.50 |      N/A       |   245  |    156
 2023-09  | 142680.75 |     13.75      |   287  |    178
 2023-10  | 138920.25 |     -2.64      |   265  |    162
 2023-11  | 156780.00 |     12.86      |   312  |    195
 2023-12  | 198450.50 |     26.58      |   421  |    267
 2024-01  |  89230.00 |    -55.03      |   178  |    112
```

### City Performance Report
```
    city     | order_count | customers | avg_order_value | total_revenue
-------------+-------------+-----------+-----------------+---------------
 New York    |     456     |    234    |     315.75      |  143982.00
 Los Angeles |     389     |    201    |     298.50      |  116116.50
 Chicago     |     234     |    145    |     287.25      |   67216.50
 Houston     |     198     |    102    |     312.80      |   61934.40
```

### Product Pairs Report
```
         product_pair          | times_together
-------------------------------+----------------
 iPhone 14 Pro + AirPods Pro   |      45
 MacBook Air + Magic Mouse     |      28
 Gaming Laptop + Gaming Mouse  |      23
 iPhone 14 Pro + Phone Case    |      22
 iPad Air + Apple Pencil       |      18
```

---

## Try These Variations

1. Add RFM (Recency, Frequency, Monetary) analysis
2. Calculate cart abandonment rate
3. Find products with declining sales
4. Analyze order patterns by day of week
5. Calculate customer acquisition cost by city

### Solutions

```sql
-- 1. RFM Analysis
WITH rfm_calc AS (
    SELECT
        u.id,
        u.name,
        CURRENT_DATE - MAX(o.order_date) as recency_days,
        COUNT(DISTINCT o.id) as frequency,
        SUM(oi.quantity * p.price) as monetary
    FROM users u
    LEFT JOIN orders o ON u.id = o.user_id AND o.status = 'completed'
    LEFT JOIN order_items oi ON o.id = oi.order_id
    LEFT JOIN products p ON oi.product_id = p.id
    GROUP BY u.id, u.name
),
rfm_scores AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency_days) as r_score,
        NTILE(5) OVER (ORDER BY frequency DESC) as f_score,
        NTILE(5) OVER (ORDER BY monetary DESC) as m_score
    FROM rfm_calc
    WHERE monetary > 0
)
SELECT
    name,
    recency_days,
    frequency,
    ROUND(monetary, 2) as monetary,
    r_score,
    f_score,
    m_score,
    (r_score + f_score + m_score) as rfm_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 THEN 'Recent Customers'
        WHEN r_score <= 2 AND f_score >= 4 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'Potential'
    END as customer_segment
FROM rfm_scores
ORDER BY rfm_score DESC;

-- 2. Cart abandonment (pending/cancelled vs completed)
SELECT
    DATE_TRUNC('month', order_date) as month,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed,
    COUNT(CASE WHEN status IN ('pending', 'cancelled') THEN 1 END) as abandoned,
    ROUND(
        100.0 * COUNT(CASE WHEN status IN ('pending', 'cancelled') THEN 1 END) /
        COUNT(*),
        2
    ) as abandonment_rate_pct
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;

-- 3. Products with declining sales
WITH monthly_product_sales AS (
    SELECT
        p.id,
        p.name,
        DATE_TRUNC('month', o.order_date) as month,
        SUM(oi.quantity) as units_sold
    FROM products p
    JOIN order_items oi ON p.id = oi.product_id
    JOIN orders o ON oi.order_id = o.id
    WHERE o.status = 'completed'
      AND o.order_date >= CURRENT_DATE - INTERVAL '3 months'
    GROUP BY p.id, p.name, DATE_TRUNC('month', o.order_date)
)
SELECT
    name,
    month,
    units_sold,
    LAG(units_sold) OVER (PARTITION BY id ORDER BY month) as prev_month,
    units_sold - LAG(units_sold) OVER (PARTITION BY id ORDER BY month) as change,
    ROUND(
        (units_sold - LAG(units_sold) OVER (PARTITION BY id ORDER BY month)) * 100.0 /
        NULLIF(LAG(units_sold) OVER (PARTITION BY id ORDER BY month), 0),
        2
    ) as pct_change
FROM monthly_product_sales
WHERE LAG(units_sold) OVER (PARTITION BY id ORDER BY month) IS NOT NULL
  AND units_sold < LAG(units_sold) OVER (PARTITION BY id ORDER BY month)
ORDER BY pct_change;
```

---

## Common Mistakes

1. **Not filtering order status:** Including cancelled orders in revenue
2. **Forgetting DISTINCT:** Overcounting with multiple joins
3. **NULL handling:** Not using COALESCE for LEFT JOINs
4. **Timezone issues:** Comparing dates across timezones
5. **Performance:** Running expensive queries without indexes
6. **Ambiguous metrics:** Not defining metrics clearly

---

## Performance Optimization

```sql
-- Create materialized view for frequently-used metrics
CREATE MATERIALIZED VIEW product_revenue_summary AS
SELECT
    p.id,
    p.name,
    p.category,
    SUM(oi.quantity * p.price) as total_revenue,
    SUM(oi.quantity) as units_sold,
    COUNT(DISTINCT oi.order_id) as order_count
FROM products p
JOIN order_items oi ON p.id = oi.product_id
JOIN orders o ON oi.order_id = o.id
WHERE o.status = 'completed'
GROUP BY p.id, p.name, p.category;

-- Refresh periodically
REFRESH MATERIALIZED VIEW product_revenue_summary;

-- Create helpful indexes
CREATE INDEX idx_orders_date_status ON orders(order_date, status);
CREATE INDEX idx_order_items_product ON order_items(product_id);
CREATE INDEX idx_orders_user_date ON orders(user_id, order_date);
```

---

## Real-World Use Cases

1. **Executive dashboards:** High-level business metrics
2. **Marketing analytics:** Customer segmentation and targeting
3. **Inventory planning:** Product demand forecasting
4. **Sales performance:** Territory and period analysis
5. **Customer success:** Churn prediction and prevention
6. **Product development:** Feature popularity and usage

---

## Related Problems

- **Previous:** [Problem 19 - Complex Join Challenge](../19-complex-join-challenge/)
- **Next:** [Problem 21 - Pattern Matching](../21-pattern-matching/)
- **Related:** All previous problems combined into real-world scenarios

---

## Notes

```
Your notes here:




```

---

[← Previous](../19-complex-join-challenge/) | [Back to Overview](../../README.md) | [Next Problem →](../21-pattern-matching/)
