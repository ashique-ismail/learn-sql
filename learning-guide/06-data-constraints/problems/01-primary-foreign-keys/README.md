# Problem 1: Primary and Foreign Keys

## Difficulty: Easy

## Tasks
1. Create tables with primary keys
2. Add foreign key relationships
3. Test referential integrity

## Solution
<details>
<summary>Click to see solution</summary>

```sql
CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(100) UNIQUE
);

CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    emp_name VARCHAR(100),
    dept_id INTEGER REFERENCES departments(dept_id)
);
```
</details>
