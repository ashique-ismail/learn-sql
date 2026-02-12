# Problem 2: CHECK and UNIQUE Constraints

## Difficulty: Medium

## Tasks
1. Add CHECK constraints for data validation
2. Create UNIQUE constraints
3. Test constraint violations

## Solution
<details>
<summary>Click to see solution</summary>

```sql
ALTER TABLE employees
ADD CONSTRAINT check_salary CHECK (salary > 0);

ALTER TABLE employees
ADD CONSTRAINT unique_email UNIQUE (email);
```
</details>
