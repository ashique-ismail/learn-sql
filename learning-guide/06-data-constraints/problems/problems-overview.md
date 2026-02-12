# Data Constraints - Practice Problems

## Problem 1: NOT NULL Constraints
Create a `users` table where:
- email, username must not be NULL
- first_name, last_name must not be NULL
- phone can be NULL
Test by trying to insert NULL values

## Problem 2: UNIQUE Constraints
Create a `products` table with:
- Unique product_code
- Unique (brand, model) combination
- Email unique but case-insensitive
Test duplicate insertions

## Problem 3: CHECK Constraints
Create an `orders` table with:
- price > 0
- quantity between 1 and 1000
- status in ('pending', 'shipped', 'delivered')
- order_date <= delivery_date
- discount between 0 and 100

## Problem 4: Foreign Key Actions
Create tables demonstrating:
- ON DELETE CASCADE (delete child records)
- ON DELETE SET NULL (nullify reference)
- ON DELETE RESTRICT (prevent deletion)
- ON UPDATE CASCADE (update references)

## Problem 5: Complex Business Rules
Implement these rules:
1. Employee salary between $30k-$300k
2. Project end_date must be after start_date
3. Order total must equal sum of item prices
4. Student age must be 18+ for adult courses
5. Credit card expiry must be future date

## Problem 6: Domain Types
Create custom domains for:
- email_address (with regex validation)
- positive_integer
- percentage (0-100)
- phone_number
- postal_code
