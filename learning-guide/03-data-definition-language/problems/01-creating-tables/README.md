# Problem 1: Creating Tables

## Difficulty: Easy

## Problem Description
Create a complete database schema for a university system with proper data types, primary keys, and foreign keys.

## Requirements
1. Create `students` table with: student_id, first_name, last_name, email, enrollment_date
2. Create `courses` table with: course_id, course_code, course_name, credits
3. Create `enrollments` junction table linking students and courses
4. Use appropriate data types and constraints

## Sample Schema
```sql
-- Your CREATE TABLE statements here
```

## Solution
<details>
<summary>Click to see solution</summary>

```sql
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    enrollment_date DATE DEFAULT CURRENT_DATE
);

CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    course_code VARCHAR(10) UNIQUE NOT NULL,
    course_name VARCHAR(100) NOT NULL,
    credits INTEGER CHECK (credits > 0)
);

CREATE TABLE enrollments (
    enrollment_id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES students(student_id),
    course_id INTEGER REFERENCES courses(course_id),
    enrollment_date DATE DEFAULT CURRENT_DATE,
    grade VARCHAR(2),
    UNIQUE(student_id, course_id)
);
```
</details>
