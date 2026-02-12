# Problem 1: Database Basics

## Difficulty: Easy

## Problem Description
Create a simple database schema for a library system. You need to understand basic table structure, primary keys, and relationships.

## Requirements
1. Create a `books` table with:
   - book_id (primary key, auto-increment)
   - title (required)
   - author (required)
   - isbn (unique, 13 characters)
   - publication_year (integer)
   - pages (integer)

2. Create a `members` table with:
   - member_id (primary key, auto-increment)
   - first_name (required)
   - last_name (required)
   - email (unique, required)
   - join_date (date, default current date)

3. Create a `borrowings` table with:
   - borrowing_id (primary key, auto-increment)
   - book_id (foreign key to books)
   - member_id (foreign key to members)
   - borrow_date (date, default current date)
   - return_date (date, nullable)

## Sample Data
Insert at least:
- 5 books
- 3 members
- 4 borrowing records (some returned, some not)

## Questions to Answer
1. What is a primary key and why is it important?
2. What is a foreign key and what does it enforce?
3. What is the relationship between books and members? (One-to-Many, Many-to-Many)
4. Why do we need a separate `borrowings` table?

## Expected Output
After creating the schema and inserting data, run these queries:
```sql
-- List all books
SELECT * FROM books;

-- List all members
SELECT * FROM members;

-- List all current borrowings (not returned)
SELECT * FROM borrowings WHERE return_date IS NULL;
```

## Hints
- Use SERIAL or AUTO_INCREMENT for auto-incrementing IDs
- Use VARCHAR for text fields
- Use DATE for date fields
- REFERENCES keyword creates foreign keys

## Solution
<details>
<summary>Click to see solution</summary>

```sql
-- Create books table
CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    author VARCHAR(100) NOT NULL,
    isbn CHAR(13) UNIQUE,
    publication_year INTEGER,
    pages INTEGER
);

-- Create members table
CREATE TABLE members (
    member_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    join_date DATE DEFAULT CURRENT_DATE
);

-- Create borrowings table
CREATE TABLE borrowings (
    borrowing_id SERIAL PRIMARY KEY,
    book_id INTEGER REFERENCES books(book_id),
    member_id INTEGER REFERENCES members(member_id),
    borrow_date DATE DEFAULT CURRENT_DATE,
    return_date DATE
);

-- Insert sample data
INSERT INTO books (title, author, isbn, publication_year, pages) VALUES
('The Great Gatsby', 'F. Scott Fitzgerald', '9780743273565', 1925, 180),
('To Kill a Mockingbird', 'Harper Lee', '9780060935467', 1960, 324),
('1984', 'George Orwell', '9780451524935', 1949, 328),
('Pride and Prejudice', 'Jane Austen', '9780141439518', 1813, 432),
('The Catcher in the Rye', 'J.D. Salinger', '9780316769174', 1951, 277);

INSERT INTO members (first_name, last_name, email) VALUES
('John', 'Doe', 'john.doe@email.com'),
('Jane', 'Smith', 'jane.smith@email.com'),
('Bob', 'Johnson', 'bob.johnson@email.com');

INSERT INTO borrowings (book_id, member_id, borrow_date, return_date) VALUES
(1, 1, '2024-01-15', '2024-01-29'),
(2, 1, '2024-02-01', NULL),
(3, 2, '2024-02-05', NULL),
(4, 3, '2024-01-20', '2024-02-03');
```
</details>

## Learning Objectives
- Understand table structure
- Learn about primary and foreign keys
- Practice creating relationships
- Work with different data types
- Insert sample data
