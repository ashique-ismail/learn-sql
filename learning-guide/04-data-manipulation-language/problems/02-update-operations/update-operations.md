# Problem 2: Updating Data

## Difficulty: Medium

## Problem Description
Practice UPDATE statements with various conditions and calculations.

## Tasks
1. Update a single student's email
2. Give all CS courses 1 additional credit
3. Update with subquery to set grade based on score
4. Use UPDATE with FROM clause

## Solution
<details>
<summary>Click to see solution</summary>

```sql
-- 1. Simple update
UPDATE students
SET email = 'new.email@university.edu'
WHERE student_id = 1;

-- 2. Conditional update with calculation
UPDATE courses
SET credits = credits + 1
WHERE code LIKE 'CS%';

-- 3. Update with subquery
UPDATE enrollments
SET grade = CASE
    WHEN score >= 90 THEN 'A'
    WHEN score >= 80 THEN 'B'
    WHEN score >= 70 THEN 'C'
    ELSE 'F'
END;

-- 4. Update with FROM
UPDATE enrollments e
SET grade = 'A'
FROM students s
WHERE e.student_id = s.student_id
AND s.email LIKE '%@honors.university.edu';
```
</details>
