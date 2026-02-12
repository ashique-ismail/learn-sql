# Problem 2: Altering Tables

## Difficulty: Medium

## Problem Description
Modify existing tables to add new columns, change data types, and add constraints.

## Tasks
1. Add `phone_number` column to students table
2. Change email column to allow 150 characters
3. Add CHECK constraint on credits (must be 1-5)
4. Rename course_code to code
5. Add a `status` column with DEFAULT 'active'

## Solution
<details>
<summary>Click to see solution</summary>

```sql
-- 1. Add phone column
ALTER TABLE students ADD COLUMN phone_number VARCHAR(15);

-- 2. Change email length
ALTER TABLE students ALTER COLUMN email TYPE VARCHAR(150);

-- 3. Add CHECK constraint
ALTER TABLE courses ADD CONSTRAINT check_credits CHECK (credits BETWEEN 1 AND 5);

-- 4. Rename column
ALTER TABLE courses RENAME COLUMN course_code TO code;

-- 5. Add status column
ALTER TABLE students ADD COLUMN status VARCHAR(20) DEFAULT 'active';
```
</details>
