# Problem 1: Inserting Data

## Difficulty: Easy

## Problem Description
Practice various INSERT operations including single row, multiple rows, and INSERT from SELECT.

## Tasks
1. Insert a single student
2. Insert 5 students in one statement
3. Insert course data with RETURNING clause
4. Copy data from one table to another

## Solution
<details>
<summary>Click to see solution</summary>

```sql
-- 1. Single insert
INSERT INTO students (first_name, last_name, email)
VALUES ('John', 'Doe', 'john.doe@university.edu');

-- 2. Multiple inserts
INSERT INTO students (first_name, last_name, email) VALUES
    ('Alice', 'Smith', 'alice.s@university.edu'),
    ('Bob', 'Johnson', 'bob.j@university.edu'),
    ('Carol', 'Williams', 'carol.w@university.edu'),
    ('David', 'Brown', 'david.b@university.edu'),
    ('Eve', 'Davis', 'eve.d@university.edu');

-- 3. Insert with RETURNING
INSERT INTO courses (code, course_name, credits)
VALUES ('CS101', 'Intro to Programming', 3)
RETURNING course_id, code;

-- 4. Insert from SELECT
INSERT INTO archive_students
SELECT * FROM students WHERE enrollment_date < '2020-01-01';
```
</details>
