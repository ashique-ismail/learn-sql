# Problem 13: Library Schema Design

**Difficulty:** Intermediate
**Concepts:** CREATE TABLE, Constraints, Foreign keys, Many-to-many relationships, Database design
**Phase:** Database Design (Days 12-13)

---

## Learning Objectives

- Design normalized database schemas
- Create tables with appropriate data types
- Implement primary and foreign key constraints
- Handle many-to-many relationships with junction tables
- Apply constraints (NOT NULL, UNIQUE, CHECK, DEFAULT)
- Understand referential integrity

---

## Concept Summary

**Schema design** involves creating table structures that efficiently and accurately represent your data.

### Syntax

```sql
CREATE TABLE table_name (
    column1 datatype CONSTRAINTS,
    column2 datatype CONSTRAINTS,
    TABLE_CONSTRAINTS
);

-- Common data types
INTEGER, BIGINT, SMALLINT
DECIMAL(precision, scale), NUMERIC
FLOAT, REAL, DOUBLE PRECISION
VARCHAR(n), CHAR(n), TEXT
DATE, TIME, TIMESTAMP
BOOLEAN
JSON, JSONB

-- Column constraints
PRIMARY KEY
FOREIGN KEY (column) REFERENCES other_table(column)
UNIQUE
NOT NULL
CHECK (condition)
DEFAULT value
SERIAL, AUTO_INCREMENT  -- Auto-incrementing integers

-- Referential actions
ON DELETE CASCADE      -- Delete child rows when parent deleted
ON DELETE SET NULL     -- Set FK to NULL when parent deleted
ON DELETE RESTRICT     -- Prevent deletion if children exist
ON UPDATE CASCADE      -- Update FK when parent PK changes
```

---

## Problem Statement

**Task:** Create tables for a library system with the following requirements:

1. **Authors:** Store author information (name, birth year)
2. **Books:** Store book details (title, ISBN, publication year, available copies)
3. **Book-Author Relationship:** Books can have multiple authors, authors can write multiple books
4. **Borrowings:** Track who borrowed which book, when borrowed and returned

**Requirements:**
- Proper primary keys
- Foreign keys with referential integrity
- Appropriate data types
- NOT NULL where necessary
- UNIQUE constraints where appropriate
- CHECK constraints for data validation

---

## Hint

Use a junction table (book_authors) for the many-to-many relationship between books and authors.

---

## Your Solution

```sql
-- Write your CREATE TABLE statements here
-- Authors table:


-- Books table:


-- Book-Authors junction table:


-- Borrowings table:


```

---

## Solution

```sql
-- Authors table
CREATE TABLE authors (
    author_id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    birth_year INTEGER,
    biography TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (birth_year >= 1000 AND birth_year <= EXTRACT(YEAR FROM CURRENT_DATE))
);

-- Books table
CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(300) NOT NULL,
    isbn VARCHAR(13) UNIQUE,
    publication_year INTEGER,
    available_copies INTEGER DEFAULT 0,
    total_copies INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (publication_year >= 1450),  -- Gutenberg press invented ~1450
    CHECK (available_copies >= 0),
    CHECK (available_copies <= total_copies),
    CHECK (total_copies >= 0)
);

-- Book-Authors junction table (many-to-many)
CREATE TABLE book_authors (
    book_id INTEGER REFERENCES books(book_id) ON DELETE CASCADE,
    author_id INTEGER REFERENCES authors(author_id) ON DELETE CASCADE,
    author_order INTEGER DEFAULT 1,  -- For multiple authors, track order
    PRIMARY KEY (book_id, author_id),
    CHECK (author_order > 0)
);

-- Borrowings table
CREATE TABLE borrowings (
    borrowing_id SERIAL PRIMARY KEY,
    book_id INTEGER NOT NULL REFERENCES books(book_id),
    borrower_name VARCHAR(200) NOT NULL,
    borrower_email VARCHAR(255),
    borrow_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL DEFAULT (CURRENT_DATE + INTERVAL '14 days'),
    return_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (return_date IS NULL OR return_date >= borrow_date),
    CHECK (due_date > borrow_date)
);

-- Create indexes for foreign keys (improves JOIN performance)
CREATE INDEX idx_book_authors_book_id ON book_authors(book_id);
CREATE INDEX idx_book_authors_author_id ON book_authors(author_id);
CREATE INDEX idx_borrowings_book_id ON borrowings(book_id);
CREATE INDEX idx_borrowings_dates ON borrowings(borrow_date, return_date);

-- Create index for email lookups
CREATE INDEX idx_borrowings_email ON borrowings(borrower_email);
```

### Explanation

1. **SERIAL PRIMARY KEY:** Auto-incrementing integer ID
2. **VARCHAR with sizes:** Reasonable limits for text fields
3. **UNIQUE isbn:** Each book has unique ISBN
4. **CHECK constraints:** Validate data (e.g., available_copies >= 0)
5. **DEFAULT values:** Sensible defaults (e.g., borrow_date defaults to today)
6. **ON DELETE CASCADE:** Delete book_authors when book/author deleted
7. **Composite PRIMARY KEY:** (book_id, author_id) prevents duplicate associations
8. **Indexes:** Speed up common queries

---

## Enhanced Version with Additional Features

```sql
-- Add members table
CREATE TABLE members (
    member_id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    registration_date DATE DEFAULT CURRENT_DATE,
    membership_status VARCHAR(20) DEFAULT 'active',
    CHECK (membership_status IN ('active', 'suspended', 'cancelled'))
);

-- Add categories/genres
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT
);

-- Book-Category relationship
CREATE TABLE book_categories (
    book_id INTEGER REFERENCES books(book_id) ON DELETE CASCADE,
    category_id INTEGER REFERENCES categories(category_id) ON DELETE CASCADE,
    PRIMARY KEY (book_id, category_id)
);

-- Update borrowings to reference members
CREATE TABLE borrowings_v2 (
    borrowing_id SERIAL PRIMARY KEY,
    book_id INTEGER NOT NULL REFERENCES books(book_id),
    member_id INTEGER NOT NULL REFERENCES members(member_id),
    borrow_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL DEFAULT (CURRENT_DATE + INTERVAL '14 days'),
    return_date DATE,
    fine_amount DECIMAL(10,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'borrowed',
    notes TEXT,
    CHECK (return_date IS NULL OR return_date >= borrow_date),
    CHECK (due_date > borrow_date),
    CHECK (fine_amount >= 0),
    CHECK (status IN ('borrowed', 'returned', 'lost', 'damaged'))
);

-- Reviews table
CREATE TABLE reviews (
    review_id SERIAL PRIMARY KEY,
    book_id INTEGER NOT NULL REFERENCES books(book_id) ON DELETE CASCADE,
    member_id INTEGER NOT NULL REFERENCES members(member_id),
    rating INTEGER NOT NULL,
    review_text TEXT,
    review_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (rating >= 1 AND rating <= 5),
    UNIQUE (book_id, member_id)  -- One review per member per book
);
```

---

## Sample Data Insertion

```sql
-- Insert authors
INSERT INTO authors (name, birth_year) VALUES
    ('J.K. Rowling', 1965),
    ('George R.R. Martin', 1948),
    ('J.R.R. Tolkien', 1892);

-- Insert books
INSERT INTO books (title, isbn, publication_year, available_copies, total_copies) VALUES
    ('Harry Potter and the Philosopher''s Stone', '9780747532699', 1997, 3, 5),
    ('A Game of Thrones', '9780553103540', 1996, 2, 3),
    ('The Lord of the Rings', '9780544003415', 1954, 4, 4);

-- Link books to authors
INSERT INTO book_authors (book_id, author_id, author_order) VALUES
    (1, 1, 1),  -- Harry Potter by J.K. Rowling
    (2, 2, 1),  -- Game of Thrones by G.R.R. Martin
    (3, 3, 1);  -- LOTR by Tolkien

-- Insert borrowings
INSERT INTO borrowings (book_id, borrower_name, borrower_email) VALUES
    (1, 'John Smith', 'john@example.com'),
    (2, 'Jane Doe', 'jane@example.com');

-- Update available copies when borrowed
UPDATE books SET available_copies = available_copies - 1
WHERE book_id IN (1, 2);
```

---

## Useful Queries

```sql
-- 1. Find all books by an author
SELECT b.title, b.publication_year, b.isbn
FROM books b
JOIN book_authors ba ON b.book_id = ba.book_id
JOIN authors a ON ba.author_id = a.author_id
WHERE a.name = 'J.K. Rowling';

-- 2. Find available books
SELECT title, available_copies, total_copies
FROM books
WHERE available_copies > 0
ORDER BY title;

-- 3. Find overdue books
SELECT
    bo.borrowing_id,
    bo.borrower_name,
    b.title,
    bo.borrow_date,
    bo.due_date,
    CURRENT_DATE - bo.due_date as days_overdue
FROM borrowings bo
JOIN books b ON bo.book_id = b.book_id
WHERE bo.return_date IS NULL
  AND bo.due_date < CURRENT_DATE
ORDER BY days_overdue DESC;

-- 4. Books with multiple authors
SELECT b.title, STRING_AGG(a.name, ', ' ORDER BY ba.author_order) as authors
FROM books b
JOIN book_authors ba ON b.book_id = ba.book_id
JOIN authors a ON ba.author_id = a.author_id
GROUP BY b.book_id, b.title
HAVING COUNT(a.author_id) > 1;

-- 5. Borrowing history for a person
SELECT
    b.title,
    bo.borrow_date,
    bo.return_date,
    CASE
        WHEN bo.return_date IS NULL THEN 'Currently Borrowed'
        ELSE 'Returned'
    END as status
FROM borrowings bo
JOIN books b ON bo.book_id = b.book_id
WHERE bo.borrower_email = 'john@example.com'
ORDER BY bo.borrow_date DESC;
```

---

## Schema Modifications

```sql
-- Add new column to existing table
ALTER TABLE books ADD COLUMN publisher VARCHAR(200);
ALTER TABLE books ADD COLUMN language VARCHAR(50) DEFAULT 'English';

-- Add foreign key constraint
ALTER TABLE borrowings
ADD CONSTRAINT fk_book
FOREIGN KEY (book_id) REFERENCES books(book_id);

-- Add check constraint
ALTER TABLE books
ADD CONSTRAINT chk_publication_year
CHECK (publication_year <= EXTRACT(YEAR FROM CURRENT_DATE));

-- Drop constraint
ALTER TABLE books DROP CONSTRAINT chk_publication_year;

-- Modify column
ALTER TABLE authors ALTER COLUMN name TYPE VARCHAR(300);

-- Add unique constraint
ALTER TABLE books ADD CONSTRAINT unique_title_year UNIQUE (title, publication_year);
```

---

## Common Mistakes

1. **No primary keys:** Every table should have a primary key
2. **Wrong data types:** Using VARCHAR for numbers or dates
3. **Missing NOT NULL:** Allow NULLs where they shouldn't be allowed
4. **No foreign keys:** Orphaned data, no referential integrity
5. **Circular foreign keys:** Can cause insertion/deletion issues
6. **Too many columns:** May indicate need for normalization
7. **No indexes on foreign keys:** Poor JOIN performance
8. **VARCHAR without limit:** Use TEXT or specify reasonable limit
9. **Missing ON DELETE/UPDATE:** Default RESTRICT may not be intended behavior

---

## Design Best Practices

### Normalization Rules

1. **1NF (First Normal Form):**
   - Atomic values (no arrays or lists in single column)
   - Each row unique (primary key)

2. **2NF (Second Normal Form):**
   - Meet 1NF
   - No partial dependencies on composite keys

3. **3NF (Third Normal Form):**
   - Meet 2NF
   - No transitive dependencies

### Naming Conventions

```sql
-- Tables: plural nouns
books, authors, borrowings

-- Columns: singular nouns
book_id, name, publication_year

-- Foreign keys: table_name_id
author_id, book_id

-- Junction tables: table1_table2
book_authors, book_categories

-- Indexes: idx_table_column
idx_books_isbn, idx_borrowings_date

-- Constraints: chk_table_column
chk_books_copies, chk_borrowings_dates
```

---

## Real-World Extensions

1. **Reservation system:** Allow members to reserve books
2. **Fine calculation:** Automated overdue fines
3. **Book editions:** Track different editions of same book
4. **Staff management:** Librarians, checkouts, admin access
5. **Digital resources:** E-books, audiobooks
6. **Recommendation system:** Based on borrowing history
7. **Statistics tracking:** Popular books, peak borrowing times

---

## Related Problems

- **Previous:** [Problem 12 - Salary Update](../12-salary-update/)
- **Next:** [Problem 14 - Monthly Revenue Analysis](../14-monthly-revenue-analysis/)
- **Related:** Problem 6 (JOINs), Problem 16 (Orphaned Records), Problem 29 (Data Quality)

---

## Notes

```
Your notes here:




```

---

[← Previous](../12-salary-update/) | [Back to Overview](../../README.md) | [Next Problem →](../14-monthly-revenue-analysis/)
