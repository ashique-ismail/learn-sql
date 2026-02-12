-- ============================================================================
-- SQL Learning Plan - PostgreSQL Database Setup
-- ============================================================================
-- This file creates all tables and inserts sample data for practice
-- Execute this entire file to set up your learning database
-- ============================================================================

-- Create database (uncomment if needed)
-- CREATE DATABASE sql_learning;
-- \c sql_learning;

-- ============================================================================
-- DROP TABLES (if re-running setup)
-- ============================================================================

DROP TABLE IF EXISTS borrowings CASCADE;
DROP TABLE IF EXISTS book_authors CASCADE;
DROP TABLE IF EXISTS books CASCADE;
DROP TABLE IF EXISTS authors CASCADE;
DROP TABLE IF EXISTS project_assignments CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS monthly_sales CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS employee_audit CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS categories CASCADE;

-- ============================================================================
-- PHASE 1-3: Core Learning Tables
-- ============================================================================

-- Departments table
CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL,
    location VARCHAR(100),
    budget DECIMAL(12, 2)
);

-- Employees table (main practice table)
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    email VARCHAR(200) UNIQUE,
    salary DECIMAL(10, 2) NOT NULL,
    department VARCHAR(100),
    dept_id INTEGER REFERENCES departments(id),
    manager_id INTEGER REFERENCES employees(id),
    hire_date DATE DEFAULT CURRENT_DATE,
    birth_date DATE,
    is_active BOOLEAN DEFAULT TRUE
);

-- Projects table
CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    project_name VARCHAR(200) NOT NULL,
    start_date DATE,
    end_date DATE,
    budget DECIMAL(12, 2),
    status VARCHAR(50) CHECK (status IN ('planning', 'in-progress', 'completed', 'on-hold'))
);

-- Project assignments (many-to-many)
CREATE TABLE project_assignments (
    employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
    project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
    role VARCHAR(100),
    assigned_date DATE DEFAULT CURRENT_DATE,
    hours_allocated INTEGER,
    PRIMARY KEY (employee_id, project_id)
);

-- Sales table for window functions
CREATE TABLE sales (
    id SERIAL PRIMARY KEY,
    month DATE NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    category VARCHAR(100),
    region VARCHAR(100)
);

CREATE TABLE monthly_sales (
    id SERIAL PRIMARY KEY,
    sale_month DATE NOT NULL,
    product_category VARCHAR(100),
    revenue DECIMAL(12, 2),
    units_sold INTEGER
);

-- ============================================================================
-- PHASE 4-5: E-commerce Tables
-- ============================================================================

-- Categories table
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

-- Products table
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(300) NOT NULL,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    category VARCHAR(100),
    category_id INTEGER REFERENCES categories(id),
    stock_quantity INTEGER DEFAULT 0,
    supplier VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Customers/Users table
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    email VARCHAR(200) UNIQUE NOT NULL,
    city VARCHAR(100),
    registration_date DATE DEFAULT CURRENT_DATE,
    total_purchases DECIMAL(12, 2) DEFAULT 0,
    loyalty_points INTEGER DEFAULT 0
);

-- Duplicate for some exercises
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    email VARCHAR(200) UNIQUE NOT NULL,
    city VARCHAR(100),
    registration_date DATE DEFAULT CURRENT_DATE,
    account_status VARCHAR(50) DEFAULT 'active'
);

-- Orders table
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id),
    user_id INTEGER REFERENCES users(id),
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(50) CHECK (status IN ('pending', 'processing', 'completed', 'cancelled')),
    amount DECIMAL(10, 2),
    shipping_fee DECIMAL(10, 2) DEFAULT 0
);

-- Order items (many-to-many)
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price DECIMAL(10, 2) NOT NULL
);

-- Inventory table
CREATE TABLE inventory (
    id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(id),
    warehouse_location VARCHAR(100),
    quantity INTEGER NOT NULL,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- PHASE 5: Library System Tables
-- ============================================================================

CREATE TABLE authors (
    author_id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    birth_year INTEGER,
    country VARCHAR(100)
);

CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(300) NOT NULL,
    isbn VARCHAR(13) UNIQUE,
    publication_year INTEGER,
    available_copies INTEGER DEFAULT 0,
    total_copies INTEGER DEFAULT 0,
    genre VARCHAR(100)
);

CREATE TABLE book_authors (
    book_id INTEGER REFERENCES books(book_id) ON DELETE CASCADE,
    author_id INTEGER REFERENCES authors(author_id) ON DELETE CASCADE,
    PRIMARY KEY (book_id, author_id)
);

CREATE TABLE borrowings (
    borrowing_id SERIAL PRIMARY KEY,
    book_id INTEGER REFERENCES books(book_id),
    borrower_name VARCHAR(200) NOT NULL,
    borrower_email VARCHAR(200),
    borrow_date DATE NOT NULL DEFAULT CURRENT_DATE,
    return_date DATE,
    due_date DATE NOT NULL,
    CHECK (return_date IS NULL OR return_date >= borrow_date)
);

-- Employee audit table for advanced exercises
CREATE TABLE employee_audit (
    audit_id SERIAL PRIMARY KEY,
    employee_id INTEGER,
    action VARCHAR(50),
    old_salary DECIMAL(10, 2),
    new_salary DECIMAL(10, 2),
    changed_by VARCHAR(200),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- INSERT SAMPLE DATA
-- ============================================================================

-- Departments
INSERT INTO departments (dept_name, location, budget) VALUES
('Engineering', 'San Francisco', 5000000.00),
('Sales', 'New York', 3000000.00),
('Marketing', 'Los Angeles', 2000000.00),
('Human Resources', 'Chicago', 1000000.00),
('Finance', 'New York', 2500000.00),
('Operations', 'Seattle', 1800000.00),
('Customer Support', 'Austin', 1200000.00),
('Research', 'Boston', 3500000.00);

-- Employees (with hierarchy)
INSERT INTO employees (name, email, salary, department, dept_id, manager_id, hire_date, birth_date) VALUES
-- Top Management
('Alice Johnson', 'alice.j@company.com', 150000, 'Engineering', 1, NULL, '2018-01-15', '1980-05-20'),
('Bob Smith', 'bob.s@company.com', 140000, 'Sales', 2, NULL, '2018-03-10', '1982-08-15'),
('Carol White', 'carol.w@company.com', 135000, 'Marketing', 3, NULL, '2019-06-01', '1985-03-12'),
('David Brown', 'david.b@company.com', 130000, 'Finance', 5, NULL, '2017-11-20', '1978-12-05'),

-- Engineering Team
('Emma Davis', 'emma.d@company.com', 95000, 'Engineering', 1, 1, '2019-02-15', '1990-07-22'),
('Frank Miller', 'frank.m@company.com', 88000, 'Engineering', 1, 1, '2020-01-10', '1992-04-18'),
('Grace Lee', 'grace.l@company.com', 92000, 'Engineering', 1, 1, '2019-08-22', '1988-11-30'),
('Henry Wilson', 'henry.w@company.com', 85000, 'Engineering', 1, 1, '2020-05-15', '1993-01-25'),
('Ivy Chen', 'ivy.c@company.com', 90000, 'Engineering', 1, 1, '2020-03-01', '1991-09-14'),
('Jack Taylor', 'jack.t@company.com', 78000, 'Engineering', 1, 5, '2021-01-20', '1994-06-08'),
('Kate Anderson', 'kate.a@company.com', 82000, 'Engineering', 1, 5, '2021-03-15', '1993-12-19'),
('Liam Martinez', 'liam.m@company.com', 75000, 'Engineering', 1, 6, '2021-06-01', '1995-02-28'),

-- Sales Team
('Mary Garcia', 'mary.g@company.com', 72000, 'Sales', 2, 2, '2019-04-10', '1989-08-17'),
('Nathan Rodriguez', 'nathan.r@company.com', 68000, 'Sales', 2, 2, '2019-09-15', '1991-05-23'),
('Olivia Hernandez', 'olivia.h@company.com', 70000, 'Sales', 2, 2, '2020-02-20', '1990-10-11'),
('Paul Lopez', 'paul.l@company.com', 65000, 'Sales', 2, 2, '2020-07-01', '1992-03-07'),
('Quinn Gonzalez', 'quinn.g@company.com', 71000, 'Sales', 2, 13, '2021-01-15', '1993-07-29'),
('Rachel Wilson', 'rachel.w@company.com', 67000, 'Sales', 2, 13, '2021-04-10', '1994-11-03'),

-- Marketing Team
('Sam Moore', 'sam.m@company.com', 76000, 'Marketing', 3, 3, '2019-07-01', '1987-04-15'),
('Tina Jackson', 'tina.j@company.com', 73000, 'Marketing', 3, 3, '2020-01-20', '1989-09-22'),
('Uma Martin', 'uma.m@company.com', 70000, 'Marketing', 3, 3, '2020-06-15', '1991-01-18'),
('Victor Lee', 'victor.l@company.com', 68000, 'Marketing', 3, 19, '2021-02-01', '1992-08-09'),

-- Finance Team
('Wendy Thomas', 'wendy.t@company.com', 85000, 'Finance', 5, 4, '2018-09-10', '1986-06-30'),
('Xander White', 'xander.w@company.com', 82000, 'Finance', 5, 4, '2019-03-15', '1988-12-14'),
('Yara Harris', 'yara.h@company.com', 80000, 'Finance', 5, 4, '2020-05-20', '1990-02-25'),

-- HR Team
('Zoe Clark', 'zoe.c@company.com', 72000, 'Human Resources', 4, NULL, '2019-10-01', '1987-11-08'),
('Aaron Lewis', 'aaron.l@company.com', 65000, 'Human Resources', 4, 26, '2020-08-15', '1991-04-12'),

-- Operations
('Beth Walker', 'beth.w@company.com', 70000, 'Operations', 6, NULL, '2019-11-01', '1988-07-19'),
('Chris Hall', 'chris.h@company.com', 67000, 'Operations', 6, 28, '2020-09-10', '1992-10-05'),

-- Customer Support
('Diana Allen', 'diana.a@company.com', 58000, 'Customer Support', 7, NULL, '2020-01-15', '1993-03-28'),
('Ethan Young', 'ethan.y@company.com', 55000, 'Customer Support', 7, 30, '2020-10-20', '1994-08-16'),
('Fiona King', 'fiona.k@company.com', 56000, 'Customer Support', 7, 30, '2021-02-15', '1995-01-22'),

-- Research
('George Wright', 'george.w@company.com', 98000, 'Research', 8, NULL, '2018-05-20', '1983-09-11'),
('Hannah Scott', 'hannah.s@company.com', 92000, 'Research', 8, 33, '2019-08-10', '1987-06-27'),
('Ian Green', 'ian.g@company.com', 89000, 'Research', 8, 33, '2020-04-15', '1989-12-03');

-- Projects
INSERT INTO projects (project_name, start_date, end_date, budget, status) VALUES
('Website Redesign', '2023-01-15', '2023-06-30', 250000, 'completed'),
('Mobile App Development', '2023-03-01', '2023-12-31', 500000, 'in-progress'),
('Data Migration', '2023-02-10', '2023-05-20', 180000, 'completed'),
('CRM Implementation', '2023-04-01', NULL, 350000, 'in-progress'),
('Marketing Campaign Q3', '2023-07-01', '2023-09-30', 120000, 'planning'),
('Security Audit', '2023-05-15', '2023-08-15', 90000, 'in-progress'),
('AI Integration', '2023-06-01', '2024-03-31', 800000, 'in-progress'),
('Cloud Migration', '2023-01-01', '2023-04-30', 450000, 'completed');

-- Project Assignments
INSERT INTO project_assignments (employee_id, project_id, role, assigned_date, hours_allocated) VALUES
(1, 2, 'Project Lead', '2023-03-01', 800),
(5, 1, 'Senior Developer', '2023-01-15', 600),
(5, 2, 'Senior Developer', '2023-03-01', 400),
(6, 1, 'Developer', '2023-01-15', 700),
(6, 3, 'Developer', '2023-02-10', 300),
(7, 2, 'Developer', '2023-03-01', 600),
(8, 2, 'Junior Developer', '2023-03-15', 500),
(9, 7, 'Lead Developer', '2023-06-01', 900),
(10, 2, 'Developer', '2023-04-01', 450),
(11, 7, 'Developer', '2023-06-01', 600),
(23, 4, 'Business Analyst', '2023-04-01', 400),
(24, 4, 'Financial Analyst', '2023-04-01', 350),
(19, 5, 'Campaign Manager', '2023-07-01', 500),
(20, 5, 'Content Creator', '2023-07-01', 450),
(33, 7, 'Research Lead', '2023-06-01', 700);

-- Sales data for window functions
INSERT INTO sales (month, amount, category, region) VALUES
('2023-01-01', 15000, 'Electronics', 'North'),
('2023-02-01', 18000, 'Electronics', 'North'),
('2023-03-01', 22000, 'Electronics', 'North'),
('2023-04-01', 25000, 'Electronics', 'North'),
('2023-05-01', 28000, 'Electronics', 'North'),
('2023-06-01', 30000, 'Electronics', 'North'),
('2023-01-01', 12000, 'Electronics', 'South'),
('2023-02-01', 13500, 'Electronics', 'South'),
('2023-03-01', 15000, 'Electronics', 'South'),
('2023-04-01', 17000, 'Electronics', 'South'),
('2023-05-01', 19000, 'Electronics', 'South'),
('2023-06-01', 21000, 'Electronics', 'South'),
('2023-01-01', 8000, 'Furniture', 'North'),
('2023-02-01', 9500, 'Furniture', 'North'),
('2023-03-01', 11000, 'Furniture', 'North'),
('2023-04-01', 10500, 'Furniture', 'North'),
('2023-05-01', 12000, 'Furniture', 'North'),
('2023-06-01', 13500, 'Furniture', 'North');

INSERT INTO monthly_sales (sale_month, product_category, revenue, units_sold) VALUES
('2023-01-01', 'Electronics', 125000, 450),
('2023-02-01', 'Electronics', 135000, 480),
('2023-03-01', 'Electronics', 142000, 510),
('2023-04-01', 'Electronics', 158000, 545),
('2023-05-01', 'Electronics', 167000, 580),
('2023-06-01', 'Electronics', 175000, 610),
('2023-07-01', 'Electronics', 182000, 635),
('2023-08-01', 'Electronics', 178000, 625),
('2023-09-01', 'Electronics', 195000, 675),
('2023-10-01', 'Electronics', 210000, 720),
('2023-11-01', 'Electronics', 245000, 825),
('2023-12-01', 'Electronics', 298000, 980);

-- Categories
INSERT INTO categories (category_name, description) VALUES
('Electronics', 'Electronic devices and gadgets'),
('Clothing', 'Apparel and fashion items'),
('Home & Garden', 'Home improvement and garden supplies'),
('Sports', 'Sports equipment and accessories'),
('Books', 'Physical and digital books'),
('Toys', 'Children toys and games');

-- Products
INSERT INTO products (name, price, category, category_id, stock_quantity, supplier) VALUES
('Laptop Pro 15', 1299.99, 'Electronics', 1, 50, 'TechSupply Co'),
('Wireless Mouse', 29.99, 'Electronics', 1, 200, 'TechSupply Co'),
('USB-C Cable', 12.99, 'Electronics', 1, 500, 'TechSupply Co'),
('Bluetooth Headphones', 89.99, 'Electronics', 1, 150, 'AudioMax'),
('4K Monitor', 399.99, 'Electronics', 1, 75, 'TechSupply Co'),
('Mechanical Keyboard', 129.99, 'Electronics', 1, 100, 'TechSupply Co'),
('Webcam HD', 79.99, 'Electronics', 1, 120, 'TechSupply Co'),
('External SSD 1TB', 149.99, 'Electronics', 1, 80, 'StorageKing'),
('T-Shirt Classic', 19.99, 'Clothing', 2, 300, 'FashionHub'),
('Jeans Denim', 49.99, 'Clothing', 2, 200, 'FashionHub'),
('Winter Jacket', 129.99, 'Clothing', 2, 100, 'FashionHub'),
('Running Shoes', 89.99, 'Clothing', 2, 150, 'SportWear Inc'),
('Garden Hose 50ft', 34.99, 'Home & Garden', 3, 80, 'HomeDepot'),
('Lawn Mower', 299.99, 'Home & Garden', 3, 30, 'GardenTools'),
('LED Bulbs Pack', 24.99, 'Home & Garden', 3, 250, 'HomeDepot'),
('Basketball', 24.99, 'Sports', 4, 100, 'SportWear Inc'),
('Yoga Mat', 29.99, 'Sports', 4, 120, 'SportWear Inc'),
('Dumbbell Set', 149.99, 'Sports', 4, 45, 'FitnessGear'),
('Fiction Novel', 14.99, 'Books', 5, 200, 'BookDistributors'),
('Programming Guide', 49.99, 'Books', 5, 100, 'TechBooks'),
('LEGO Set Classic', 59.99, 'Toys', 6, 85, 'ToyWorld'),
('Board Game Family', 34.99, 'Toys', 6, 110, 'ToyWorld');

-- Users
INSERT INTO users (name, email, city, registration_date) VALUES
('John Doe', 'john.doe@email.com', 'New York', '2023-01-15'),
('Jane Smith', 'jane.smith@email.com', 'Los Angeles', '2023-02-20'),
('Mike Johnson', 'mike.j@email.com', 'Chicago', '2023-03-10'),
('Sarah Williams', 'sarah.w@email.com', 'Houston', '2023-01-25'),
('Tom Brown', 'tom.b@email.com', 'Phoenix', '2023-04-05'),
('Emily Davis', 'emily.d@email.com', 'Philadelphia', '2023-02-14'),
('David Wilson', 'david.w@email.com', 'San Antonio', '2023-05-20'),
('Lisa Anderson', 'lisa.a@email.com', 'San Diego', '2023-03-30'),
('James Taylor', 'james.t@email.com', 'Dallas', '2023-04-12'),
('Mary Martinez', 'mary.m@email.com', 'San Jose', '2023-01-08');

-- Customers (for e-commerce scenarios)
INSERT INTO customers (name, email, city, registration_date, total_purchases, loyalty_points) VALUES
('Robert Chen', 'robert.c@email.com', 'San Francisco', '2023-01-10', 2450.75, 245),
('Jennifer Lopez', 'jennifer.l@email.com', 'Miami', '2023-02-15', 1820.50, 182),
('Michael Brown', 'michael.b@email.com', 'Seattle', '2023-01-20', 3250.25, 325),
('Amanda White', 'amanda.w@email.com', 'Boston', '2023-03-05', 1520.00, 152),
('Christopher Lee', 'chris.lee@email.com', 'Denver', '2023-02-28', 2890.80, 289),
('Jessica Taylor', 'jessica.t@email.com', 'Atlanta', '2023-04-10', 950.40, 95),
('Daniel Garcia', 'daniel.g@email.com', 'Portland', '2023-03-15', 4150.90, 415),
('Michelle Martin', 'michelle.m@email.com', 'Austin', '2023-01-30', 1680.30, 168),
('Ryan Anderson', 'ryan.a@email.com', 'Las Vegas', '2023-05-01', 720.50, 72),
('Laura Thomas', 'laura.t@email.com', 'Nashville', '2023-04-20', 2340.60, 234);

-- Orders
INSERT INTO orders (customer_id, user_id, order_date, status, amount, shipping_fee) VALUES
(1, 1, '2023-06-01', 'completed', 1329.98, 15.00),
(1, 1, '2023-07-15', 'completed', 89.99, 5.00),
(1, 1, '2023-08-20', 'completed', 179.98, 10.00),
(2, 2, '2023-06-10', 'completed', 549.98, 20.00),
(2, 2, '2023-08-05', 'completed', 299.99, 15.00),
(3, 3, '2023-06-15', 'completed', 1699.96, 0.00),
(3, 3, '2023-07-20', 'completed', 399.99, 20.00),
(3, 3, '2023-08-25', 'completed', 259.97, 10.00),
(3, 3, '2023-09-10', 'processing', 149.99, 10.00),
(4, 4, '2023-07-01', 'completed', 89.98, 8.00),
(4, 4, '2023-08-15', 'cancelled', 49.99, 5.00),
(5, 5, '2023-06-25', 'completed', 1829.95, 0.00),
(5, 5, '2023-08-30', 'completed', 179.98, 10.00),
(6, 6, '2023-07-10', 'completed', 119.97, 8.00),
(7, 7, '2023-06-20', 'completed', 2099.93, 0.00),
(7, 7, '2023-08-10', 'completed', 649.96, 20.00),
(8, 8, '2023-07-25', 'completed', 299.97, 15.00),
(9, 9, '2023-08-05', 'completed', 89.98, 8.00),
(10, 10, '2023-06-30', 'completed', 1449.94, 20.00);

-- Order Items
INSERT INTO order_items (order_id, product_id, quantity, price) VALUES
-- Order 1
(1, 1, 1, 1299.99),
(1, 3, 2, 12.99),
-- Order 2
(2, 4, 1, 89.99),
-- Order 3
(3, 2, 2, 29.99),
(3, 6, 1, 129.99),
-- Order 4
(4, 10, 11, 49.99),
-- Order 5
(5, 14, 1, 299.99),
-- Order 6
(6, 5, 2, 399.99),
(6, 7, 1, 79.99),
(6, 8, 5, 149.99),
-- Order 7
(7, 5, 1, 399.99),
-- Order 8
(8, 1, 2, 1299.99),
-- Order 9
(9, 8, 1, 149.99),
-- Order 10
(10, 9, 6, 19.99),
-- Order 11
(11, 10, 1, 49.99),
-- Order 12
(12, 1, 1, 1299.99),
(12, 5, 1, 399.99),
(12, 6, 1, 129.99),
-- Order 13
(13, 2, 3, 29.99),
(13, 3, 10, 12.99),
-- Order 14
(14, 4, 1, 89.99),
(14, 2, 1, 29.99),
-- Order 15
(15, 1, 1, 1299.99),
(15, 5, 2, 399.99),
-- Order 16
(16, 6, 5, 129.99),
-- Order 17
(17, 12, 3, 89.99),
(17, 9, 1, 19.99),
-- Order 18
(18, 2, 3, 29.99),
-- Order 19
(19, 1, 1, 1299.99),
(19, 8, 1, 149.99);

-- Inventory
INSERT INTO inventory (product_id, warehouse_location, quantity) VALUES
(1, 'Warehouse A', 30),
(1, 'Warehouse B', 20),
(2, 'Warehouse A', 150),
(2, 'Warehouse C', 50),
(3, 'Warehouse A', 300),
(3, 'Warehouse B', 200),
(4, 'Warehouse B', 80),
(4, 'Warehouse C', 70),
(5, 'Warehouse A', 45),
(5, 'Warehouse B', 30);

-- Library System Data
INSERT INTO authors (name, birth_year, country) VALUES
('George Orwell', 1903, 'United Kingdom'),
('Jane Austen', 1775, 'United Kingdom'),
('Mark Twain', 1835, 'United States'),
('Virginia Woolf', 1882, 'United Kingdom'),
('Ernest Hemingway', 1899, 'United States'),
('Agatha Christie', 1890, 'United Kingdom'),
('Leo Tolstoy', 1828, 'Russia'),
('F. Scott Fitzgerald', 1896, 'United States');

INSERT INTO books (title, isbn, publication_year, available_copies, total_copies, genre) VALUES
('1984', '9780451524935', 1949, 3, 5, 'Dystopian Fiction'),
('Animal Farm', '9780451526342', 1945, 2, 4, 'Political Satire'),
('Pride and Prejudice', '9780141439518', 1813, 4, 6, 'Romance'),
('The Adventures of Tom Sawyer', '9780486400778', 1876, 2, 3, 'Adventure'),
('Mrs Dalloway', '9780156628709', 1925, 3, 4, 'Modernist'),
('The Old Man and the Sea', '9780684801223', 1952, 1, 3, 'Literary Fiction'),
('Murder on the Orient Express', '9780062693662', 1934, 2, 5, 'Mystery'),
('War and Peace', '9780199232765', 1869, 1, 2, 'Historical Fiction'),
('The Great Gatsby', '9780743273565', 1925, 4, 7, 'Classic'),
('A Farewell to Arms', '9780684801469', 1929, 2, 4, 'War Fiction');

INSERT INTO book_authors (book_id, author_id) VALUES
(1, 1),
(2, 1),
(3, 2),
(4, 3),
(5, 4),
(6, 5),
(7, 6),
(8, 7),
(9, 8),
(10, 5);

INSERT INTO borrowings (book_id, borrower_name, borrower_email, borrow_date, return_date, due_date) VALUES
(1, 'Alice Cooper', 'alice.c@email.com', '2023-08-01', '2023-08-15', '2023-08-14'),
(3, 'Bob Dylan', 'bob.d@email.com', '2023-08-05', NULL, '2023-08-19'),
(5, 'Charlie Parker', 'charlie.p@email.com', '2023-08-10', '2023-08-22', '2023-08-24'),
(7, 'Diana Ross', 'diana.r@email.com', '2023-08-12', NULL, '2023-08-26'),
(9, 'Elvis Presley', 'elvis.p@email.com', '2023-08-15', '2023-08-25', '2023-08-29'),
(2, 'Frank Sinatra', 'frank.s@email.com', '2023-08-18', NULL, '2023-09-01'),
(6, 'Grace Jones', 'grace.j@email.com', '2023-08-20', NULL, '2023-09-03'),
(9, 'Hank Williams', 'hank.w@email.com', '2023-08-22', NULL, '2023-09-05');

-- ============================================================================
-- CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

-- Employee indexes
CREATE INDEX idx_employees_department ON employees(department);
CREATE INDEX idx_employees_salary ON employees(salary);
CREATE INDEX idx_employees_manager_id ON employees(manager_id);
CREATE INDEX idx_employees_hire_date ON employees(hire_date);

-- Orders indexes
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_order_date ON orders(order_date);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_date_status ON orders(order_date, status);

-- Products indexes
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_price ON products(price);

-- Order items indexes
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- Project assignments indexes
CREATE INDEX idx_project_assignments_employee ON project_assignments(employee_id);
CREATE INDEX idx_project_assignments_project ON project_assignments(project_id);

-- ============================================================================
-- CREATE VIEWS FOR CONVENIENCE
-- ============================================================================

-- View: Employee with department details
CREATE OR REPLACE VIEW employee_details AS
SELECT
    e.id,
    e.name,
    e.email,
    e.salary,
    e.department,
    d.location,
    d.budget as dept_budget,
    m.name as manager_name,
    e.hire_date,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, e.hire_date)) as years_employed
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.id
LEFT JOIN employees m ON e.manager_id = m.id;

-- View: Order summary
CREATE OR REPLACE VIEW order_summary AS
SELECT
    o.id as order_id,
    c.name as customer_name,
    c.email as customer_email,
    o.order_date,
    o.status,
    COUNT(oi.id) as item_count,
    SUM(oi.quantity * oi.price) as order_total,
    o.shipping_fee,
    SUM(oi.quantity * oi.price) + o.shipping_fee as grand_total
FROM orders o
JOIN customers c ON o.customer_id = c.id
JOIN order_items oi ON o.id = oi.order_id
GROUP BY o.id, c.name, c.email, o.order_date, o.status, o.shipping_fee;

-- View: Product inventory summary
CREATE OR REPLACE VIEW product_inventory_summary AS
SELECT
    p.id,
    p.name,
    p.price,
    p.category,
    p.stock_quantity as listed_stock,
    COALESCE(SUM(i.quantity), 0) as warehouse_stock,
    COUNT(i.warehouse_location) as warehouse_count
FROM products p
LEFT JOIN inventory i ON p.id = i.product_id
GROUP BY p.id, p.name, p.price, p.category, p.stock_quantity;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check record counts
SELECT 'employees' as table_name, COUNT(*) as record_count FROM employees
UNION ALL
SELECT 'departments', COUNT(*) FROM departments
UNION ALL
SELECT 'projects', COUNT(*) FROM projects
UNION ALL
SELECT 'project_assignments', COUNT(*) FROM project_assignments
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'books', COUNT(*) FROM books
UNION ALL
SELECT 'authors', COUNT(*) FROM authors
UNION ALL
SELECT 'borrowings', COUNT(*) FROM borrowings;

-- ============================================================================
-- SETUP COMPLETE
-- ============================================================================

SELECT '✓ Database setup complete!' as status;
SELECT '✓ Total tables created: 23' as info;
SELECT '✓ Sample data inserted for all tables' as info;
SELECT '✓ Indexes created for performance' as info;
SELECT '✓ Views created for convenience' as info;
SELECT '' as blank_line;
SELECT 'You are ready to start learning SQL!' as message;
SELECT 'Begin with: SELECT * FROM employees LIMIT 5;' as first_query;
