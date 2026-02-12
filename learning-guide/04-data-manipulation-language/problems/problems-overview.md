# DML (Data Manipulation Language) - Practice Problems

Use this schema for all problems:

```sql
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    department VARCHAR(50),
    salary DECIMAL(10,2),
    hire_date DATE,
    manager_id INTEGER REFERENCES employees(employee_id)
);

CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(50) UNIQUE,
    budget DECIMAL(12,2),
    location VARCHAR(100)
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    start_date DATE,
    end_date DATE,
    budget DECIMAL(12,2),
    status VARCHAR(20) DEFAULT 'planning'
);

CREATE TABLE project_assignments (
    assignment_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(employee_id),
    project_id INTEGER REFERENCES projects(project_id),
    assigned_date DATE DEFAULT CURRENT_DATE,
    role VARCHAR(50),
    hours_allocated INTEGER
);
```

## Problem 1: INSERT Operations

1. Insert 10 employees across 3 departments
2. Insert 5 departments
3. Insert 3 projects
4. Assign 5 employees to projects
5. Use INSERT with RETURNING to get the generated IDs

<details>
<summary>Solution</summary>

```sql
-- Insert departments first
INSERT INTO departments (department_name, budget, location) VALUES
('Engineering', 500000, 'Building A'),
('Marketing', 200000, 'Building B'),
('Sales', 300000, 'Building C')
RETURNING *;

-- Insert employees
INSERT INTO employees (first_name, last_name, email, department, salary, hire_date) VALUES
('John', 'Doe', 'john.doe@company.com', 'Engineering', 85000, '2022-01-15'),
('Jane', 'Smith', 'jane.smith@company.com', 'Engineering', 90000, '2021-06-01'),
('Bob', 'Johnson', 'bob.j@company.com', 'Marketing', 65000, '2023-03-10'),
('Alice', 'Williams', 'alice.w@company.com', 'Marketing', 70000, '2022-08-20'),
('Charlie', 'Brown', 'charlie.b@company.com', 'Sales', 75000, '2021-11-05'),
('Diana', 'Davis', 'diana.d@company.com', 'Sales', 72000, '2023-01-15'),
('Eve', 'Miller', 'eve.m@company.com', 'Engineering', 95000, '2020-09-01'),
('Frank', 'Wilson', 'frank.w@company.com', 'Marketing', 68000, '2022-05-12'),
('Grace', 'Moore', 'grace.m@company.com', 'Sales', 78000, '2021-12-20'),
('Henry', 'Taylor', 'henry.t@company.com', 'Engineering', 88000, '2022-04-08')
RETURNING employee_id, first_name, last_name;

-- Insert projects
INSERT INTO projects (project_name, start_date, end_date, budget, status) VALUES
('Website Redesign', '2024-01-01', '2024-06-30', 150000, 'active'),
('Mobile App', '2024-02-01', '2024-12-31', 300000, 'active'),
('Marketing Campaign', '2024-03-01', '2024-05-31', 80000, 'planning');

-- Assign employees to projects
INSERT INTO project_assignments (employee_id, project_id, role, hours_allocated) VALUES
(1, 1, 'Lead Developer', 160),
(2, 1, 'Developer', 160),
(7, 2, 'Tech Lead', 160),
(3, 3, 'Marketing Lead', 120),
(4, 3, 'Marketing Specialist', 100);
```
</details>

## Problem 2: UPDATE Operations

1. Give all Engineering employees a 10% raise
2. Update project status from 'planning' to 'active'
3. Set manager_id for employees (employee 7 manages employees 1 and 2)
4. Update multiple columns: change an employee's department and salary
5. Update using subquery: set department budget to sum of salaries

<details>
<summary>Solution</summary>

```sql
-- 1. 10% raise for Engineering
UPDATE employees
SET salary = salary * 1.10
WHERE department = 'Engineering'
RETURNING employee_id, first_name, salary;

-- 2. Update project status
UPDATE projects
SET status = 'active'
WHERE status = 'planning';

-- 3. Set managers
UPDATE employees
SET manager_id = 7
WHERE employee_id IN (1, 2);

-- 4. Update multiple columns
UPDATE employees
SET department = 'Engineering',
    salary = 100000
WHERE employee_id = 5;

-- 5. Update with subquery
UPDATE departments d
SET budget = (
    SELECT COALESCE(SUM(salary), 0)
    FROM employees e
    WHERE e.department = d.department_name
);
```
</details>

## Problem 3: DELETE Operations

1. Delete employees with no project assignments
2. Delete projects that ended before 2023
3. Delete using subquery: remove employees earning below department average
4. Soft delete: add deleted_at column and update instead of delete

<details>
<summary>Solution</summary>

```sql
-- 1. Delete unassigned employees
DELETE FROM employees
WHERE employee_id NOT IN (
    SELECT DISTINCT employee_id FROM project_assignments
)
RETURNING *;

-- 2. Delete old projects
DELETE FROM projects
WHERE end_date < '2023-01-01';

-- 3. Delete below-average earners
DELETE FROM employees e1
WHERE salary < (
    SELECT AVG(salary)
    FROM employees e2
    WHERE e2.department = e1.department
);

-- 4. Soft delete implementation
ALTER TABLE employees ADD COLUMN deleted_at TIMESTAMP;

-- "Delete" employee (soft delete)
UPDATE employees
SET deleted_at = CURRENT_TIMESTAMP
WHERE employee_id = 5;

-- Create view for active employees
CREATE VIEW active_employees AS
SELECT * FROM employees WHERE deleted_at IS NULL;
```
</details>

## Problem 4: Upsert (INSERT ON CONFLICT)

1. Insert or update employee email
2. Insert or ignore duplicate entries
3. Conditional update on conflict

<details>
<summary>Solution</summary>

```sql
-- 1. Upsert employee
INSERT INTO employees (employee_id, first_name, last_name, email, department, salary)
VALUES (1, 'John', 'Doe', 'john.new@company.com', 'Engineering', 90000)
ON CONFLICT (employee_id)
DO UPDATE SET
    email = EXCLUDED.email,
    salary = EXCLUDED.salary;

-- 2. Insert or ignore
INSERT INTO departments (department_name, budget, location)
VALUES ('Engineering', 500000, 'Building A')
ON CONFLICT (department_name) DO NOTHING;

-- 3. Conditional update
INSERT INTO employees (email, first_name, last_name, department, salary)
VALUES ('jane.smith@company.com', 'Jane', 'Smith', 'Engineering', 95000)
ON CONFLICT (email)
DO UPDATE SET
    salary = GREATEST(employees.salary, EXCLUDED.salary),
    department = EXCLUDED.department
WHERE employees.salary < EXCLUDED.salary;
```
</details>

## Problem 5: Complex DML Operations

1. Bulk insert from SELECT
2. Update with FROM clause (PostgreSQL)
3. Delete cascading with RETURNING
4. Swap department assignments for two employees

<details>
<summary>Solution</summary>

```sql
-- 1. Copy high performers to new table
CREATE TABLE high_performers AS
SELECT * FROM employees WHERE salary > 80000;

-- Or INSERT INTO existing table
INSERT INTO high_performers
SELECT * FROM employees
WHERE salary > 80000
ON CONFLICT DO NOTHING;

-- 2. Update with FROM
UPDATE employees e
SET salary = salary * 1.05
FROM project_assignments pa
WHERE e.employee_id = pa.employee_id
AND pa.hours_allocated > 120;

-- 3. Delete with RETURNING
WITH deleted AS (
    DELETE FROM project_assignments
    WHERE assigned_date < '2023-01-01'
    RETURNING *
)
INSERT INTO project_assignments_archive
SELECT * FROM deleted;

-- 4. Swap departments
UPDATE employees
SET department = CASE
    WHEN employee_id = 1 THEN (SELECT department FROM employees WHERE employee_id = 2)
    WHEN employee_id = 2 THEN (SELECT department FROM employees WHERE employee_id = 1)
    ELSE department
END
WHERE employee_id IN (1, 2);
```
</details>

## Challenge Problems

### Challenge 1: Data Migration
Write a script that:
1. Creates archive tables
2. Moves old data (>1 year) to archive
3. Verifies data integrity
4. Deletes archived data from main tables

### Challenge 2: Audit Trail
Implement complete audit logging:
1. Create audit table
2. Create triggers for INSERT/UPDATE/DELETE
3. Store old and new values
4. Track user and timestamp

### Challenge 3: Batch Processing
Write queries to:
1. Process 1000 records at a time
2. Update in batches with commits
3. Handle errors gracefully
4. Log progress

## Learning Objectives
- Master INSERT (single, bulk, from SELECT)
- Perform UPDATE with calculations and subqueries
- Use DELETE safely with WHERE clauses
- Implement upserts with ON CONFLICT
- Use RETURNING clause effectively
- Handle soft deletes
- Work with transactions
- Maintain data integrity
