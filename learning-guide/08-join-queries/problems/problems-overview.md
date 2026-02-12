# Join Queries - Practice Problems

Schema for all problems:

```sql
CREATE TABLE customers (customer_id SERIAL PRIMARY KEY, name VARCHAR(100), city VARCHAR(50));
CREATE TABLE orders (order_id SERIAL PRIMARY KEY, customer_id INT, order_date DATE, amount DECIMAL);
CREATE TABLE products (product_id SERIAL PRIMARY KEY, name VARCHAR(100), price DECIMAL);
CREATE TABLE order_items (order_id INT, product_id INT, quantity INT);
CREATE TABLE employees (employee_id SERIAL PRIMARY KEY, name VARCHAR(100), manager_id INT);
```

## Problem 1: INNER JOIN
1. List orders with customer names
2. Show order items with product details
3. Find employees with their manager names
4. List products ordered with customer info
5. Multi-table join: orders with customer, items, and products

## Problem 2: LEFT JOIN
1. All customers with their orders (including customers with no orders)
2. Products with order count (including products never ordered)
3. Employees with their direct reports count
4. Find customers who never ordered
5. Products never purchased

## Problem 3: RIGHT and FULL JOIN
1. All orders with customers (including orphaned orders)
2. FULL JOIN to find unmatched records in both tables
3. Find customers without orders AND orders without customers

## Problem 4: SELF JOIN
1. Employees with their managers
2. Products in same price range
3. Customers in same city
4. Find employee hierarchy (multiple levels)
5. Compare sales between consecutive months

## Problem 5: CROSS JOIN
1. Generate all product-customer combinations
2. Create date series cross products
3. Generate test data combinations
4. All possible employee pairings

## Problem 6: Advanced JOIN Patterns
1. Find top 3 products per category
2. Running totals with self-join
3. Find gaps in sequences
4. Detect duplicates across tables
5. Hierarchical data with recursive JOIN
