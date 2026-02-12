# Aggregate Queries - Practice Problems

Sample database for practice:

```sql
CREATE TABLE sales (
    sale_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    sale_date DATE,
    quantity INTEGER,
    unit_price DECIMAL(10,2),
    customer_region VARCHAR(50)
);

INSERT INTO sales (product_name, category, sale_date, quantity, unit_price, customer_region) VALUES
('Laptop', 'Electronics', '2024-01-15', 2, 999.99, 'North'),
('Mouse', 'Electronics', '2024-01-16', 5, 29.99, 'South'),
('Desk Chair', 'Furniture', '2024-01-17', 1, 199.99, 'North'),
('Monitor', 'Electronics', '2024-01-18', 3, 299.99, 'East'),
('Keyboard', 'Electronics', '2024-01-19', 4, 79.99, 'West'),
('Desk', 'Furniture', '2024-01-20', 1, 399.99, 'South'),
('Headphones', 'Electronics', '2024-01-21', 2, 149.99, 'North'),
('Lamp', 'Furniture', '2024-01-22', 3, 49.99, 'East'),
('Laptop', 'Electronics', '2024-02-01', 1, 999.99, 'West'),
('Mouse', 'Electronics', '2024-02-02', 10, 29.99, 'North');
```

## Problem 1: Basic Aggregations
1. Count total number of sales
2. Calculate total revenue (quantity × unit_price)
3. Find average sale quantity
4. Find highest and lowest unit_price
5. Count distinct products sold

## Problem 2: GROUP BY
1. Total sales by category
2. Average unit price by region
3. Number of sales per month
4. Total quantity sold per product
5. Revenue by category and region

## Problem 3: HAVING Clause
1. Categories with total revenue > $1000
2. Products sold more than 5 times
3. Regions with average sale > $200
4. Months with more than 3 sales
5. Products with total quantity sold > 10

## Problem 4: Complex Aggregations
1. Running total of revenue by date
2. Percentage of total revenue by category
3. Moving average of sales (3-day window)
4. Rank categories by revenue
5. Find top 3 selling products

## Problem 5: Multiple Grouping Levels
1. Use GROUPING SETS for category and region
2. Use ROLLUP for hierarchical totals (year > quarter > month)
3. Use CUBE for all dimension combinations
4. Identify subtotal rows with GROUPING()

Solutions and more problems at: [Full Solutions](solutions.md)
