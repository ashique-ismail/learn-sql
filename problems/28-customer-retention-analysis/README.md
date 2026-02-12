# Problem 28: Customer Retention Analysis

**Difficulty:** Expert
**Concepts:** Cohort analysis, Retention metrics, LAG/LEAD, Date calculations, Customer lifecycle
**Phase:** Real-World Scenarios (Days 21-25)

---

## Learning Objectives

- Master cohort analysis techniques
- Calculate retention and churn rates
- Use window functions for customer lifecycle analysis
- Understand customer lifetime value (CLV)
- Work with date-based cohorts
- Create actionable business metrics
- Analyze customer behavior patterns

---

## Concept Summary

**Cohort analysis** groups customers by shared characteristics (usually registration date) and tracks their behavior over time. **Retention analysis** measures how many customers continue to engage with your business over time periods.

### Key Metrics

```sql
-- Customer Lifetime Value (CLV)
CLV = Total Revenue from Customer / Customer Lifespan

-- Retention Rate
Retention Rate = (Customers at End - New Customers) / Customers at Start * 100

-- Churn Rate
Churn Rate = Customers Lost / Customers at Start * 100
Churn Rate = 1 - Retention Rate

-- Cohort Retention
Month N Retention = Active in Month N / Total in Cohort * 100
```

### Cohort Analysis Pattern

1. **Define cohort** (e.g., registration month)
2. **Track activity** over time periods
3. **Calculate retention** for each period
4. **Visualize** retention curves
5. **Identify** patterns and trends

---

## Problem Statement

**Task:** Perform comprehensive customer retention analysis:
1. Calculate customer lifetime value (CLV)
2. Identify cohorts by registration month
3. Calculate monthly retention rate per cohort
4. Find churned customers (no orders in last 90 days)
5. Segment customers by activity level
6. Predict customer risk

**Given:**
- customers table: (id, name, email, registration_date, city)
- orders table: (id, customer_id, order_date, status, amount)
- order_items table: (id, order_id, product_id, quantity, price)

**Requirements:**
- Complete CLV calculation
- Cohort-based retention metrics
- Customer segmentation
- Churn analysis

---

## Hint

Use DATE_TRUNC to create cohorts, window functions for cumulative analysis, and CASE for customer segmentation. Calculate intervals between orders to identify churn.

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

### Part 1: Customer Lifetime Value

```sql
WITH customer_clv AS (
    SELECT
        c.id,
        c.name,
        c.email,
        c.registration_date,
        COUNT(DISTINCT o.id) as total_orders,
        SUM(oi.quantity * oi.price) as lifetime_value,
        MIN(o.order_date) as first_order_date,
        MAX(o.order_date) as last_order_date,
        MAX(o.order_date) - MIN(o.order_date) as customer_lifespan_days,
        ROUND(
            AVG(oi.quantity * oi.price),
            2
        ) as avg_order_value
    FROM customers c
    LEFT JOIN orders o ON c.id = o.customer_id AND o.status = 'completed'
    LEFT JOIN order_items oi ON o.id = oi.order_id
    GROUP BY c.id, c.name, c.email, c.registration_date
)
SELECT
    name,
    email,
    registration_date,
    total_orders,
    ROUND(COALESCE(lifetime_value, 0), 2) as clv,
    customer_lifespan_days,
    CASE
        WHEN customer_lifespan_days > 0
        THEN ROUND(lifetime_value / (customer_lifespan_days + 1), 2)
        ELSE COALESCE(lifetime_value, 0)
    END as daily_value,
    avg_order_value,
    last_order_date,
    CURRENT_DATE - last_order_date as days_since_last_order,
    CASE
        WHEN last_order_date IS NULL THEN 'Never Ordered'
        WHEN CURRENT_DATE - last_order_date > 90 THEN 'Churned'
        WHEN CURRENT_DATE - last_order_date > 30 THEN 'At Risk'
        WHEN CURRENT_DATE - last_order_date > 7 THEN 'Active'
        ELSE 'Very Active'
    END as customer_status
FROM customer_clv
ORDER BY lifetime_value DESC NULLS LAST;
```

### Part 2: Cohort Analysis

```sql
WITH cohorts AS (
    SELECT
        c.id as customer_id,
        DATE_TRUNC('month', c.registration_date) as cohort_month,
        DATE_TRUNC('month', o.order_date) as order_month
    FROM customers c
    LEFT JOIN orders o ON c.id = o.customer_id AND o.status = 'completed'
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) as cohort_size
    FROM cohorts
    GROUP BY cohort_month
),
cohort_activity AS (
    SELECT
        c.cohort_month,
        c.order_month,
        COUNT(DISTINCT c.customer_id) as active_customers,
        EXTRACT(MONTH FROM AGE(c.order_month, c.cohort_month)) as months_since_registration
    FROM cohorts c
    WHERE c.order_month IS NOT NULL
    GROUP BY c.cohort_month, c.order_month
)
SELECT
    TO_CHAR(ca.cohort_month, 'YYYY-MM') as cohort,
    cs.cohort_size,
    ca.months_since_registration as month_number,
    ca.active_customers,
    ROUND(100.0 * ca.active_customers / cs.cohort_size, 2) as retention_rate,
    ROUND(100.0 * (1 - ca.active_customers::DECIMAL / cs.cohort_size), 2) as churn_rate
FROM cohort_activity ca
JOIN cohort_sizes cs ON ca.cohort_month = cs.cohort_month
WHERE ca.cohort_month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '12 months')
ORDER BY ca.cohort_month, ca.months_since_registration;
```

### Part 3: Customer Segmentation (RFM Analysis)

```sql
WITH customer_metrics AS (
    SELECT
        c.id,
        c.name,
        c.email,
        -- Recency: Days since last order
        CURRENT_DATE - MAX(o.order_date) as days_since_last_order,
        -- Frequency: Number of orders
        COUNT(DISTINCT o.id) as order_count,
        -- Monetary: Total spent
        COALESCE(SUM(oi.quantity * oi.price), 0) as total_spent
    FROM customers c
    LEFT JOIN orders o ON c.id = o.customer_id AND o.status = 'completed'
    LEFT JOIN order_items oi ON o.id = oi.order_id
    GROUP BY c.id, c.name, c.email
),
rfm_scores AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY days_since_last_order ASC NULLS LAST) as recency_score,
        NTILE(5) OVER (ORDER BY order_count DESC) as frequency_score,
        NTILE(5) OVER (ORDER BY total_spent DESC) as monetary_score
    FROM customer_metrics
)
SELECT
    name,
    email,
    days_since_last_order,
    order_count,
    ROUND(total_spent, 2) as total_spent,
    recency_score,
    frequency_score,
    monetary_score,
    recency_score + frequency_score + monetary_score as rfm_total,
    CASE
        WHEN recency_score >= 4 AND frequency_score >= 4 THEN 'Champions'
        WHEN recency_score >= 3 AND frequency_score >= 3 THEN 'Loyal Customers'
        WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'Promising'
        WHEN recency_score >= 3 AND frequency_score <= 2 THEN 'Needs Attention'
        WHEN recency_score <= 2 AND frequency_score >= 3 THEN 'At Risk'
        WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'Lost'
        ELSE 'Regular'
    END as customer_segment
FROM rfm_scores
ORDER BY rfm_total DESC;
```

### Complete Comprehensive Solution

```sql
-- Executive Summary: Customer Retention Dashboard
WITH
-- 1. Customer base metrics
customer_base AS (
    SELECT
        COUNT(*) as total_customers,
        COUNT(CASE WHEN registration_date >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as new_customers_30d,
        COUNT(CASE WHEN registration_date >= CURRENT_DATE - INTERVAL '90 days' THEN 1 END) as new_customers_90d
    FROM customers
),

-- 2. Activity metrics
customer_activity AS (
    SELECT
        c.id,
        c.registration_date,
        COUNT(DISTINCT o.id) as order_count,
        MAX(o.order_date) as last_order_date,
        SUM(oi.quantity * oi.price) as lifetime_value
    FROM customers c
    LEFT JOIN orders o ON c.id = o.customer_id AND o.status = 'completed'
    LEFT JOIN order_items oi ON o.id = oi.order_id
    GROUP BY c.id, c.registration_date
),

-- 3. Customer status
customer_status AS (
    SELECT
        COUNT(*) as total,
        COUNT(CASE WHEN last_order_date IS NULL THEN 1 END) as never_ordered,
        COUNT(CASE WHEN CURRENT_DATE - last_order_date <= 30 THEN 1 END) as active_30d,
        COUNT(CASE WHEN CURRENT_DATE - last_order_date <= 90 THEN 1 END) as active_90d,
        COUNT(CASE WHEN CURRENT_DATE - last_order_date > 90 OR last_order_date IS NULL THEN 1 END) as churned
    FROM customer_activity
),

-- 4. Revenue metrics
revenue_metrics AS (
    SELECT
        SUM(lifetime_value) as total_revenue,
        AVG(lifetime_value) as avg_clv,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY lifetime_value) as median_clv
    FROM customer_activity
    WHERE lifetime_value > 0
),

-- 5. Cohort retention (last 6 months)
cohort_data AS (
    SELECT
        DATE_TRUNC('month', c.registration_date) as cohort_month,
        DATE_TRUNC('month', o.order_date) as activity_month,
        c.id
    FROM customers c
    LEFT JOIN orders o ON c.id = o.customer_id AND o.status = 'completed'
    WHERE c.registration_date >= CURRENT_DATE - INTERVAL '6 months'
),
cohort_retention AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT CASE WHEN activity_month IS NOT NULL THEN id END)::DECIMAL /
        COUNT(DISTINCT id) as month_0_retention,
        COUNT(DISTINCT CASE WHEN activity_month >= cohort_month + INTERVAL '1 month' THEN id END)::DECIMAL /
        COUNT(DISTINCT id) as month_1_retention,
        COUNT(DISTINCT CASE WHEN activity_month >= cohort_month + INTERVAL '2 months' THEN id END)::DECIMAL /
        COUNT(DISTINCT id) as month_2_retention
    FROM cohort_data
    GROUP BY cohort_month
)

-- Final output
SELECT
    'Customer Base' as metric_category,
    'Total Customers' as metric_name,
    total_customers as value
FROM customer_base

UNION ALL

SELECT 'Customer Base', 'New (30 days)', new_customers_30d
FROM customer_base

UNION ALL

SELECT 'Activity', 'Active (30 days)', active_30d::TEXT
FROM customer_status

UNION ALL

SELECT 'Activity', 'Active (90 days)', active_90d::TEXT
FROM customer_status

UNION ALL

SELECT 'Activity', 'Churned', churned::TEXT
FROM customer_status

UNION ALL

SELECT 'Activity', 'Never Ordered', never_ordered::TEXT
FROM customer_status

UNION ALL

SELECT 'Revenue', 'Total Revenue', ROUND(total_revenue, 2)::TEXT
FROM revenue_metrics

UNION ALL

SELECT 'Revenue', 'Average CLV', ROUND(avg_clv, 2)::TEXT
FROM revenue_metrics

UNION ALL

SELECT 'Revenue', 'Median CLV', ROUND(median_clv, 2)::TEXT
FROM revenue_metrics

ORDER BY metric_category, metric_name;
```

---

## Try These Variations

1. Calculate monthly recurring revenue (MRR)
2. Identify customers with declining order frequency
3. Predict churn probability
4. Calculate customer acquisition cost (CAC) recovery time
5. Find best customer cohorts
6. Analyze reactivation campaigns
7. Compare weekend vs weekday customers

### Solutions to Variations

```sql
-- 1. Monthly Recurring Revenue (for subscription-like business)
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date) as month,
        COUNT(DISTINCT o.customer_id) as active_customers,
        SUM(oi.quantity * oi.price) as revenue
    FROM orders o
    JOIN order_items oi ON o.id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT
    TO_CHAR(month, 'YYYY-MM') as month,
    active_customers,
    ROUND(revenue, 2) as total_revenue,
    ROUND(revenue / active_customers, 2) as revenue_per_customer,
    LAG(revenue) OVER (ORDER BY month) as prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month)) /
        LAG(revenue) OVER (ORDER BY month) * 100,
        2
    ) as mom_growth_pct
FROM monthly_revenue
ORDER BY month DESC;

-- 2. Declining order frequency
WITH customer_orders AS (
    SELECT
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) as prev_order_date
    FROM orders
    WHERE status = 'completed'
),
order_intervals AS (
    SELECT
        customer_id,
        order_date - prev_order_date as days_between_orders,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) as order_recency
    FROM customer_orders
    WHERE prev_order_date IS NOT NULL
),
declining_frequency AS (
    SELECT
        o1.customer_id,
        AVG(CASE WHEN o1.order_recency <= 3 THEN o1.days_between_orders END) as recent_avg_days,
        AVG(CASE WHEN o1.order_recency > 3 THEN o1.days_between_orders END) as historical_avg_days
    FROM order_intervals o1
    GROUP BY o1.customer_id
    HAVING COUNT(*) >= 6  -- At least 6 orders
       AND AVG(CASE WHEN o1.order_recency <= 3 THEN o1.days_between_orders END) >
           AVG(CASE WHEN o1.order_recency > 3 THEN o1.days_between_orders END) * 1.5
)
SELECT
    c.name,
    c.email,
    ROUND(df.historical_avg_days, 1) as was_ordering_every_n_days,
    ROUND(df.recent_avg_days, 1) as now_ordering_every_n_days,
    ROUND(df.recent_avg_days - df.historical_avg_days, 1) as frequency_decline_days
FROM declining_frequency df
JOIN customers c ON df.customer_id = c.id
ORDER BY frequency_decline_days DESC;

-- 3. Churn probability score
WITH customer_features AS (
    SELECT
        c.id,
        c.name,
        EXTRACT(DAY FROM CURRENT_DATE - MAX(o.order_date)) as days_since_last_order,
        COUNT(DISTINCT o.id) as total_orders,
        COUNT(DISTINCT DATE_TRUNC('month', o.order_date)) as active_months,
        EXTRACT(DAY FROM CURRENT_DATE - c.registration_date) as customer_age_days,
        AVG(o.amount) as avg_order_value,
        STDDEV(EXTRACT(DAY FROM o.order_date - LAG(o.order_date) OVER (PARTITION BY c.id ORDER BY o.order_date))) as order_regularity
    FROM customers c
    LEFT JOIN orders o ON c.id = o.customer_id AND o.status = 'completed'
    GROUP BY c.id, c.name, c.registration_date
)
SELECT
    name,
    days_since_last_order,
    total_orders,
    ROUND(avg_order_value, 2) as avg_order_value,
    -- Simple churn probability model
    CASE
        WHEN days_since_last_order IS NULL THEN 100
        WHEN days_since_last_order > 180 THEN 90
        WHEN days_since_last_order > 90 THEN 70
        WHEN days_since_last_order > 60 AND total_orders < 3 THEN 60
        WHEN days_since_last_order > 45 AND total_orders < 5 THEN 50
        WHEN days_since_last_order > 30 THEN 30
        ELSE 10
    END as churn_probability_pct,
    CASE
        WHEN days_since_last_order > 90 OR days_since_last_order IS NULL THEN 'High Risk'
        WHEN days_since_last_order > 30 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END as risk_level
FROM customer_features
WHERE CASE
        WHEN days_since_last_order IS NULL THEN 100
        WHEN days_since_last_order > 180 THEN 90
        WHEN days_since_last_order > 90 THEN 70
        WHEN days_since_last_order > 60 AND total_orders < 3 THEN 60
        WHEN days_since_last_order > 45 AND total_orders < 5 THEN 50
        WHEN days_since_last_order > 30 THEN 30
        ELSE 10
    END >= 50
ORDER BY churn_probability_pct DESC;

-- 4. CAC recovery time
WITH customer_revenue AS (
    SELECT
        c.id,
        c.registration_date,
        o.order_date,
        o.amount,
        SUM(o.amount) OVER (
            PARTITION BY c.id
            ORDER BY o.order_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) as cumulative_revenue
    FROM customers c
    JOIN orders o ON c.id = o.customer_id
    WHERE o.status = 'completed'
),
cac_recovery AS (
    SELECT
        id,
        registration_date,
        MIN(CASE WHEN cumulative_revenue >= 100 THEN order_date END) as recovered_cac_date,
        -- Assuming CAC = $100
        MIN(CASE WHEN cumulative_revenue >= 100 THEN order_date END) - registration_date as days_to_recover
    FROM customer_revenue
    GROUP BY id, registration_date
)
SELECT
    COUNT(*) as customers_analyzed,
    COUNT(recovered_cac_date) as customers_who_recovered_cac,
    ROUND(
        COUNT(recovered_cac_date)::DECIMAL / COUNT(*) * 100,
        2
    ) as recovery_rate_pct,
    ROUND(AVG(days_to_recover), 1) as avg_days_to_recover,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_to_recover) as median_days_to_recover
FROM cac_recovery
WHERE registration_date >= CURRENT_DATE - INTERVAL '1 year';

-- 5. Best customer cohorts
WITH cohort_performance AS (
    SELECT
        DATE_TRUNC('month', c.registration_date) as cohort_month,
        COUNT(DISTINCT c.id) as cohort_size,
        COUNT(DISTINCT o.id) as total_orders,
        SUM(oi.quantity * oi.price) as total_revenue,
        AVG(oi.quantity * oi.price) as avg_order_value,
        COUNT(DISTINCT o.id)::DECIMAL / COUNT(DISTINCT c.id) as orders_per_customer
    FROM customers c
    LEFT JOIN orders o ON c.id = o.customer_id AND o.status = 'completed'
    LEFT JOIN order_items oi ON o.id = oi.order_id
    WHERE c.registration_date >= CURRENT_DATE - INTERVAL '2 years'
    GROUP BY DATE_TRUNC('month', c.registration_date)
)
SELECT
    TO_CHAR(cohort_month, 'YYYY-MM') as cohort,
    cohort_size,
    total_orders,
    ROUND(total_revenue, 2) as revenue,
    ROUND(avg_order_value, 2) as aov,
    ROUND(orders_per_customer, 2) as orders_per_customer,
    ROUND(total_revenue / cohort_size, 2) as revenue_per_customer,
    DENSE_RANK() OVER (ORDER BY total_revenue / cohort_size DESC) as rank
FROM cohort_performance
WHERE cohort_size >= 10  -- Minimum cohort size
ORDER BY revenue_per_customer DESC;

-- 6. Reactivation success (customers who came back)
WITH customer_gaps AS (
    SELECT
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) as prev_order_date,
        order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) as gap_days
    FROM orders
    WHERE status = 'completed'
),
reactivations AS (
    SELECT
        customer_id,
        order_date as reactivation_date,
        gap_days
    FROM customer_gaps
    WHERE gap_days > 90  -- Considered churned after 90 days
)
SELECT
    DATE_TRUNC('month', reactivation_date) as month,
    COUNT(*) as reactivations,
    ROUND(AVG(gap_days), 1) as avg_gap_days,
    COUNT(DISTINCT customer_id) as unique_customers_reactivated
FROM reactivations
WHERE reactivation_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', reactivation_date)
ORDER BY month DESC;

-- 7. Weekend vs weekday behavior
SELECT
    CASE
        WHEN EXTRACT(DOW FROM o.order_date) IN (0, 6) THEN 'Weekend'
        ELSE 'Weekday'
    END as day_type,
    COUNT(DISTINCT o.customer_id) as unique_customers,
    COUNT(*) as total_orders,
    ROUND(AVG(o.amount), 2) as avg_order_value,
    ROUND(SUM(o.amount), 2) as total_revenue
FROM orders o
WHERE status = 'completed'
  AND order_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY CASE WHEN EXTRACT(DOW FROM o.order_date) IN (0, 6) THEN 'Weekend' ELSE 'Weekday' END;
```

---

## Sample Output

### Customer Lifetime Value
```
     name      | registration_date | total_orders |    clv     | customer_status
---------------+-------------------+--------------+------------+-----------------
 Alice Johnson | 2022-01-15        |      28      | 12450.50   | Very Active
 Bob Smith     | 2022-03-20        |      15      |  8920.75   | Active
 Carol White   | 2023-01-10        |       8      |  3200.00   | At Risk
 David Brown   | 2023-06-05        |       2      |   650.50   | Churned
 Emma Davis    | 2023-08-12        |       0      |     0.00   | Never Ordered
```

### Cohort Retention
```
  cohort   | cohort_size | month_number | active_customers | retention_rate | churn_rate
-----------+-------------+--------------+------------------+----------------+------------
 2023-01   |     150     |      0       |       142        |     94.67      |    5.33
 2023-01   |     150     |      1       |       118        |     78.67      |   21.33
 2023-01   |     150     |      2       |        98        |     65.33      |   34.67
 2023-01   |     150     |      3       |        85        |     56.67      |   43.33
 2023-02   |     175     |      0       |       168        |     96.00      |    4.00
 2023-02   |     175     |      1       |       135        |     77.14      |   22.86
```

### RFM Segmentation
```
     name      | days_since_last_order | order_count | total_spent | customer_segment
---------------+-----------------------+-------------+-------------+------------------
 Alice Johnson |          5            |     28      |  12450.50   | Champions
 Bob Smith     |         12            |     15      |   8920.75   | Loyal Customers
 Carol White   |         45            |      8      |   3200.00   | Needs Attention
 David Brown   |        120            |      2      |    650.50   | Lost
```

---

## Common Mistakes

1. **Not handling NULL values:**
   - Customers with no orders need special handling
   - Use COALESCE or LEFT JOIN properly

2. **Incorrect cohort definitions:**
   - Use DATE_TRUNC for consistent monthly cohorts
   - Don't mix registration and first purchase date

3. **Wrong retention calculation:**
   - Retention = Active / Original Cohort Size
   - Not Active / Previous Period Active

4. **Ignoring time zones:**
   - Use consistent timezone for all date calculations

5. **Performance issues:**
   - Large cohort analysis can be slow
   - Consider materialized views for dashboards

6. **Survivorship bias:**
   - Include churned customers in analysis
   - Don't only analyze active customers

---

## Real-World Use Cases

1. **Marketing:** Identify best acquisition channels by cohort
2. **Product:** Understand feature adoption over customer lifecycle
3. **Finance:** Forecast revenue based on retention curves
4. **Customer Success:** Prioritize at-risk customers
5. **Strategy:** Compare business model changes
6. **Growth:** Measure impact of retention initiatives

---

## Related Problems

- **Previous:** [Problem 27 - Multi-Table Update](../27-multi-table-update/)
- **Next:** [Problem 29 - Data Quality Audit](../29-data-quality-audit/)
- **Related:** Problem 20 (Analytics), Problem 25 (Date Series), Problem 26 (Statistics)

---

## Notes

```
Your notes here:




```

---

[← Previous](../27-multi-table-update/) | [Back to Overview](../../README.md) | [Next Problem →](../29-data-quality-audit/)
