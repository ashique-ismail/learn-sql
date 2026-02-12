# Problem 2: Understanding Relationships

## Difficulty: Easy

## Problem Description
Design a database schema for a school system that demonstrates different types of relationships.

## Requirements

### One-to-One Relationship
Create tables to represent:
- `students` table with basic info
- `student_profiles` table with detailed personal information (one profile per student)

### One-to-Many Relationship
- `teachers` table
- `classes` table (each class has one teacher, but teachers can teach multiple classes)

### Many-to-Many Relationship
- `students` and `courses` (students can enroll in multiple courses, courses have multiple students)
- Create a junction table `enrollments`

## Schema Requirements

### Students Table
- student_id (PK)
- first_name
- last_name
- date_of_birth
- grade_level

### Student Profiles Table (One-to-One with Students)
- profile_id (PK)
- student_id (FK, UNIQUE - ensures one-to-one)
- address
- phone_number
- emergency_contact

### Teachers Table
- teacher_id (PK)
- first_name
- last_name
- subject_specialty
- hire_date

### Classes Table (One-to-Many with Teachers)
- class_id (PK)
- class_name
- teacher_id (FK)
- room_number
- schedule_time

### Courses Table
- course_id (PK)
- course_name
- course_code
- credits

### Enrollments Table (Many-to-Many: Students ↔ Courses)
- enrollment_id (PK)
- student_id (FK)
- course_id (FK)
- enrollment_date
- grade

## Tasks
1. Create all tables with appropriate relationships
2. Insert sample data:
   - 5 students with profiles
   - 3 teachers
   - 4 classes
   - 3 courses
   - 8 enrollment records

3. Write queries to demonstrate each relationship type

## Questions to Answer
1. What makes a relationship one-to-one vs one-to-many?
2. Why do we need a junction table for many-to-many relationships?
3. What constraint ensures a one-to-one relationship?
4. Can a student have multiple profiles in your design? Why or why not?

## Expected Queries
```sql
-- One-to-One: Get student with their profile
SELECT s.*, p.address, p.phone_number
FROM students s
JOIN student_profiles p ON s.student_id = p.student_id;

-- One-to-Many: Get all classes for each teacher
SELECT t.first_name, t.last_name, c.class_name
FROM teachers t
LEFT JOIN classes c ON t.teacher_id = c.teacher_id;

-- Many-to-Many: Get all courses for each student
SELECT s.first_name, s.last_name, co.course_name
FROM students s
JOIN enrollments e ON s.student_id = e.student_id
JOIN courses co ON e.course_id = co.course_id;
```

## Solution
<details>
<summary>Click to see solution</summary>

```sql
-- Students table
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE,
    grade_level INTEGER
);

-- Student profiles (One-to-One)
CREATE TABLE student_profiles (
    profile_id SERIAL PRIMARY KEY,
    student_id INTEGER UNIQUE REFERENCES students(student_id),  -- UNIQUE ensures 1-to-1
    address TEXT,
    phone_number VARCHAR(15),
    emergency_contact VARCHAR(100)
);

-- Teachers table
CREATE TABLE teachers (
    teacher_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    subject_specialty VARCHAR(50),
    hire_date DATE DEFAULT CURRENT_DATE
);

-- Classes table (One-to-Many with Teachers)
CREATE TABLE classes (
    class_id SERIAL PRIMARY KEY,
    class_name VARCHAR(100) NOT NULL,
    teacher_id INTEGER REFERENCES teachers(teacher_id),
    room_number VARCHAR(10),
    schedule_time VARCHAR(50)
);

-- Courses table
CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    course_name VARCHAR(100) NOT NULL,
    course_code VARCHAR(20) UNIQUE,
    credits INTEGER
);

-- Enrollments (Many-to-Many junction table)
CREATE TABLE enrollments (
    enrollment_id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES students(student_id),
    course_id INTEGER REFERENCES courses(course_id),
    enrollment_date DATE DEFAULT CURRENT_DATE,
    grade VARCHAR(2),
    UNIQUE(student_id, course_id)  -- Prevent duplicate enrollments
);

-- Insert sample data
INSERT INTO students (first_name, last_name, date_of_birth, grade_level) VALUES
('Alice', 'Johnson', '2010-05-15', 8),
('Bob', 'Williams', '2009-08-22', 9),
('Charlie', 'Brown', '2010-11-30', 8),
('Diana', 'Davis', '2009-03-10', 9),
('Eve', 'Miller', '2010-07-25', 8);

INSERT INTO student_profiles (student_id, address, phone_number, emergency_contact) VALUES
(1, '123 Main St', '555-0101', 'Parent: 555-0102'),
(2, '456 Oak Ave', '555-0201', 'Parent: 555-0202'),
(3, '789 Pine Rd', '555-0301', 'Parent: 555-0302'),
(4, '321 Elm St', '555-0401', 'Parent: 555-0402'),
(5, '654 Maple Dr', '555-0501', 'Parent: 555-0502');

INSERT INTO teachers (first_name, last_name, subject_specialty) VALUES
('Mr. John', 'Smith', 'Mathematics'),
('Ms. Sarah', 'Jones', 'English'),
('Dr. Robert', 'Garcia', 'Science');

INSERT INTO classes (class_name, teacher_id, room_number, schedule_time) VALUES
('Algebra I', 1, '101', 'Mon-Fri 9:00-10:00'),
('Geometry', 1, '101', 'Mon-Fri 10:00-11:00'),
('English Literature', 2, '205', 'Mon-Fri 11:00-12:00'),
('Biology', 3, '301', 'Mon-Fri 13:00-14:00');

INSERT INTO courses (course_name, course_code, credits) VALUES
('Mathematics', 'MATH101', 3),
('English', 'ENG101', 3),
('Science', 'SCI101', 4);

INSERT INTO enrollments (student_id, course_id) VALUES
(1, 1), (1, 2), (1, 3),
(2, 1), (2, 3),
(3, 2), (3, 3),
(4, 1);
```

**Query Results:**

```sql
-- One-to-One relationship
SELECT s.first_name, s.last_name, p.phone_number, p.emergency_contact
FROM students s
JOIN student_profiles p ON s.student_id = p.student_id;

-- One-to-Many relationship (teacher to classes)
SELECT
    t.first_name || ' ' || t.last_name AS teacher,
    COUNT(c.class_id) AS classes_taught,
    STRING_AGG(c.class_name, ', ') AS class_names
FROM teachers t
LEFT JOIN classes c ON t.teacher_id = c.teacher_id
GROUP BY t.teacher_id, t.first_name, t.last_name;

-- Many-to-Many relationship (students to courses)
SELECT
    s.first_name || ' ' || s.last_name AS student,
    STRING_AGG(co.course_name, ', ') AS enrolled_courses
FROM students s
JOIN enrollments e ON s.student_id = e.student_id
JOIN courses co ON e.course_id = co.course_id
GROUP BY s.student_id, s.first_name, s.last_name;
```
</details>

## Learning Objectives
- Understand one-to-one, one-to-many, and many-to-many relationships
- Learn how to implement each relationship type
- Practice using UNIQUE constraint for one-to-one
- Work with junction tables for many-to-many
- Query across multiple related tables
