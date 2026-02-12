# Problem 3: Complex Constraints

## Difficulty: Hard

## Tasks
1. Multi-column constraints
2. Conditional constraints
3. Business rule enforcement

## Solution
<details>
<summary>Click to see solution</summary>

```sql
ALTER TABLE orders
ADD CONSTRAINT check_dates CHECK (end_date > start_date);

ALTER TABLE products
ADD CONSTRAINT check_discount CHECK (
    (discount_pct IS NOT NULL AND discount_amt IS NULL) OR
    (discount_pct IS NULL AND discount_amt IS NOT NULL)
);
```
</details>
