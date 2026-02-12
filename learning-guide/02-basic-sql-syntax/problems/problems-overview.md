# Basic SQL Syntax - Practice Problems

Complete these problems using the sample e-commerce database below.

## Sample Database Schema

```sql
-- Create tables
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    city VARCHAR(50),
    country VARCHAR(50),
    signup_date DATE
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2),
    stock_quantity INTEGER
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    order_date DATE,
    total_amount DECIMAL(10,2),
    status VARCHAR(20)
);

-- Sample data
INSERT INTO customers (first_name, last_name, email, city, country, signup_date) VALUES
('John', 'Doe', 'john@email.com', 'New York', 'USA', '2023-01-15'),
('Jane', 'Smith', 'jane@email.com', 'London', 'UK', '2023-02-20'),
('Bob', 'Johnson', 'bob@email.com', 'Toronto', 'Canada', '2023-03-10'),
('Alice', 'Williams', 'alice@email.com', 'Sydney', 'Australia', '2023-01-25'),
('Charlie', 'Brown', 'charlie@email.com', 'New York', 'USA', '2023-04-05');

INSERT INTO products (product_name, category, price, stock_quantity) VALUES
('Laptop', 'Electronics', 999.99, 50),
('Mouse', 'Electronics', 29.99, 200),
('Desk Chair', 'Furniture', 199.99, 30),
('Monitor', 'Electronics', 299.99, 75),
('Keyboard', 'Electronics', 79.99, 150),
('Desk', 'Furniture', 399.99, 20),
('Headphones', 'Electronics', 149.99, 100),
('Lamp', 'Furniture', 49.99, 80);

INSERT INTO orders (customer_id, order_date, total_amount, status) VALUES
(1, '2024-01-10', 1029.98, 'delivered'),
(1, '2024-02-15', 199.99, 'shipped'),
(2, '2024-01-20', 449.98, 'delivered'),
(3, '2024-02-01', 999.99, 'processing'),
(4, '2024-01-25', 79.99, 'delivered'),
(5, '2024-02-10', 599.98, 'shipped');
```

## Problems

### Problem 1: SELECT and WHERE
Write queries to:
1. Select all customers from 'USA'
2. Find products priced between $50 and $200
3. Get orders with status 'delivered'
4. Find customers whose email contains 'john'
5. List products in the 'Electronics' category with stock > 100

<details>
<summary>Solutions</summary>

```sql
-- 1
SELECT * FROM customers WHERE country = 'USA';

-- 2
SELECT * FROM products WHERE price BETWEEN 50 AND 200;

-- 3
SELECT * FROM orders WHERE status = 'delivered';

-- 4
SELECT * FROM customers WHERE email LIKE '%john%';

-- 5
SELECT * FROM products WHERE category = 'Electronics' AND stock_quantity > 100;
```
</details>

### Problem 2: ORDER BY and LIMIT
Write queries to:
1. List all products ordered by price (highest first)
2. Get the 3 most recent orders
3. Find the 5 cheapest products
4. List customers alphabetically by last name
5. Get the top 3 most expensive Electronics products

<details>
<summary>Solutions</summary>

```sql
-- 1
SELECT * FROM products ORDER BY price DESC;

-- 2
SELECT * FROM orders ORDER BY order_date DESC LIMIT 3;

-- 3
SELECT * FROM products ORDER BY price LIMIT 5;

-- 4
SELECT * FROM customers ORDER BY last_name, first_name;

-- 5
SELECT * FROM products
WHERE category = 'Electronics'
ORDER BY price DESC
LIMIT 3;
```
</details>

### Problem 3: DISTINCT and Aggregation
Write queries to:
1. Find all unique cities where customers live
2. Count total number of orders
3. Find the highest priced product
4. Calculate average order amount
5. Count how many products are in each category

<details>
<summary>Solutions</summary>

```sql
-- 1
SELECT DISTINCT city FROM customers;

-- 2
SELECT COUNT(*) FROM orders;

-- 3
SELECT MAX(price) FROM products;

-- 4
SELECT AVG(total_amount) FROM orders;

-- 5
SELECT category, COUNT(*) as product_count
FROM products
GROUP BY category;
```
</details>

### Problem 4: Complex Filtering
Write queries to:
1. Find customers who signed up in 2023 Q1 (Jan-Mar)
2. Get orders over $500 that are either 'shipped' or 'delivered'
3. Find products that are either out of stock (0) or low stock (< 50)
4. List customers NOT from USA or UK
5. Find products whose name starts with 'M' or 'K'

<details>
<summary>Solutions</summary>

```sql
-- 1
SELECT * FROM customers
WHERE signup_date >= '2023-01-01' AND signup_date < '2023-04-01';

-- 2
SELECT * FROM orders
WHERE total_amount > 500
AND status IN ('shipped', 'delivered');

-- 3
SELECT * FROM products
WHERE stock_quantity = 0 OR stock_quantity < 50;

-- 4
SELECT * FROM customers
WHERE country NOT IN ('USA', 'UK');

-- 5
SELECT * FROM products
WHERE product_name LIKE 'M%' OR product_name LIKE 'K%';
```
</details>

### Problem 5: String Operations and Calculations
Write queries to:
1. Display customer full name (first_name + last_name)
2. Calculate price with 10% discount for all products
3. Show product names in uppercase
4. Find customers whose last name has exactly 5 letters
5. Calculate total inventory value per category (price × stock)

<details>
<summary>Solutions</summary>

```sql
-- 1
SELECT first_name || ' ' || last_name AS full_name FROM customers;

-- 2
SELECT product_name, price, price * 0.9 AS discounted_price FROM products;

-- 3
SELECT UPPER(product_name) FROM products;

-- 4
SELECT * FROM customers WHERE LENGTH(last_name) = 5;

-- 5
SELECT
    category,
    SUM(price * stock_quantity) AS total_value
FROM products
GROUP BY category;
```
</details>

## Challenge Problems

### Challenge 1: Pagination
Implement pagination to show products 10 at a time. Write queries for:
- Page 1 (products 1-10)
- Page 2 (products 11-20)

### Challenge 2: Complex Report
Create a query that shows:
- Product name
- Category
- Price
- Price rank within category (expensive to cheap)
- Whether it's in top 3 of its category

### Challenge 3: Data Cleanup
Write queries to:
- Find duplicate emails in customers
- Identify products with NULL values
- Find orders with invalid dates (future dates)

## Learning Objectives
- Master SELECT, WHERE, ORDER BY, LIMIT
- Use comparison and logical operators
- Work with LIKE, IN, BETWEEN
- Handle NULL values
- Perform string operations
- Calculate with arithmetic operators
