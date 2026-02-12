# Problem 3: Dropping and Truncating

## Difficulty: Medium

## Problem Description
Practice safe deletion of tables and data.

## Tasks
1. Drop a temporary table if it exists
2. Truncate table while preserving structure
3. Drop table with CASCADE to remove dependencies
4. Create and drop a table in a transaction

## Solution
<details>
<summary>Click to see solution</summary>

```sql
-- 1. Safe drop
DROP TABLE IF EXISTS temp_data;

-- 2. Truncate (remove all data, keep structure)
TRUNCATE TABLE enrollments;

-- 3. Drop with CASCADE
DROP TABLE courses CASCADE;

-- 4. Transaction
BEGIN;
CREATE TABLE test_table (id SERIAL PRIMARY KEY);
-- If something goes wrong:
ROLLBACK;
-- Or if successful:
-- COMMIT;
```
</details>
