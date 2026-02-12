# Problem 3: Deleting Data

## Difficulty: Medium

## Problem Description
Practice safe data deletion with various WHERE conditions.

## Tasks
1. Delete students who haven't enrolled in any courses
2. Delete old enrollment records (before 2020)
3. Use DELETE with RETURNING
4. Implement soft delete pattern

## Solution
<details>
<summary>Click to see solution</summary>

```sql
-- 1. Delete with NOT EXISTS
DELETE FROM students s
WHERE NOT EXISTS (
    SELECT 1 FROM enrollments e WHERE e.student_id = s.student_id
);

-- 2. Delete with date filter
DELETE FROM enrollments
WHERE enrollment_date < '2020-01-01';

-- 3. Delete with RETURNING
DELETE FROM students
WHERE status = 'inactive'
RETURNING student_id, first_name, last_name;

-- 4. Soft delete (preferred for important data)
ALTER TABLE students ADD COLUMN deleted_at TIMESTAMP;

UPDATE students
SET deleted_at = CURRENT_TIMESTAMP
WHERE student_id = 5;

-- Query active records
SELECT * FROM students WHERE deleted_at IS NULL;
```
</details>
