# DDL (Data Definition Language) - Practice Problems

## Problem 1: Create E-Commerce Database Schema

Create a complete e-commerce database with the following tables:

**Tables to Create:**
1. `categories` - product categories
2. `products` - products with prices and stock
3. `customers` - customer information
4. `addresses` - customer shipping addresses
5. `orders` - order information
6. `order_items` - items in each order

**Requirements:**
- Use appropriate data types
- Add PRIMARY KEY constraints
- Add FOREIGN KEY constraints with appropriate referential actions
- Add CHECK constraints for prices and quantities
- Add DEFAULT values where appropriate
- Include created_at/updated_at timestamps

<details>
<summary>Solution</summary>

```sql
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    category_id INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    cost DECIMAL(10,2) CHECK (cost >= 0),
    stock_quantity INTEGER DEFAULT 0 CHECK (stock_quantity >= 0),
    sku VARCHAR(50) UNIQUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE addresses (
    address_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id) ON DELETE CASCADE,
    address_line1 VARCHAR(200) NOT NULL,
    address_line2 VARCHAR(200),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) NOT NULL,
    is_default BOOLEAN DEFAULT FALSE
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id) ON DELETE RESTRICT,
    shipping_address_id INTEGER REFERENCES addresses(address_id),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
    total_amount DECIMAL(12,2) CHECK (total_amount >= 0)
);

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(product_id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    subtotal DECIMAL(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED
);
```
</details>

## Problem 2: Modify Existing Schema

Given the schema from Problem 1, make these modifications:

1. Add a `discount_percentage` column to products (0-100)
2. Add `phone_verified` boolean column to customers
3. Rename `sku` to `product_code` in products
4. Change `phone` in customers to allow longer numbers (30 chars)
5. Add a `notes` TEXT column to orders
6. Drop the `address_line2` column from addresses
7. Add a UNIQUE constraint on (customer_id, is_default) in addresses where is_default = TRUE

<details>
<summary>Solution</summary>

```sql
-- 1. Add discount column
ALTER TABLE products
ADD COLUMN discount_percentage DECIMAL(5,2) DEFAULT 0 CHECK (discount_percentage >= 0 AND discount_percentage <= 100);

-- 2. Add phone_verified
ALTER TABLE customers
ADD COLUMN phone_verified BOOLEAN DEFAULT FALSE;

-- 3. Rename sku
ALTER TABLE products
RENAME COLUMN sku TO product_code;

-- 4. Change phone length
ALTER TABLE customers
ALTER COLUMN phone TYPE VARCHAR(30);

-- 5. Add notes to orders
ALTER TABLE orders
ADD COLUMN notes TEXT;

-- 6. Drop address_line2
ALTER TABLE addresses
DROP COLUMN address_line2;

-- 7. Partial unique constraint (PostgreSQL)
CREATE UNIQUE INDEX idx_unique_default_address
ON addresses(customer_id)
WHERE is_default = TRUE;
```
</details>

## Problem 3: Data Types Exercise

Create a `products_extended` table demonstrating various data types:

**Requirements:**
- product_id (auto-increment)
- product_name (variable text, max 200)
- description (unlimited text)
- price (decimal, 2 decimal places)
- weight (decimal, 3 decimal places)
- dimensions (store as JSON: {"length": 10, "width": 5, "height": 3})
- tags (array of text)
- is_featured (boolean)
- launch_date (date only)
- created_at (timestamp with timezone)
- sku (UUID)

<details>
<summary>Solution</summary>

```sql
CREATE TABLE products_extended (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    weight DECIMAL(8,3),
    dimensions JSONB,
    tags TEXT[],
    is_featured BOOLEAN DEFAULT FALSE,
    launch_date DATE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    sku UUID DEFAULT gen_random_uuid()
);

-- Insert example
INSERT INTO products_extended (product_name, price, dimensions, tags)
VALUES (
    'Premium Laptop',
    1299.99,
    '{"length": 35, "width": 24, "height": 2}'::jsonb,
    ARRAY['electronics', 'computers', 'featured']
);
```
</details>

## Problem 4: Temporary Tables and CTAS

1. Create a temporary table for session shopping cart
2. Create a permanent table from query results (CTAS)
3. Create a table to archive old orders (orders older than 1 year)

<details>
<summary>Solution</summary>

```sql
-- 1. Temporary shopping cart
CREATE TEMP TABLE shopping_cart (
    cart_item_id SERIAL PRIMARY KEY,
    session_id VARCHAR(100),
    product_id INTEGER,
    quantity INTEGER,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Create table from query (popular products)
CREATE TABLE popular_products AS
SELECT
    p.product_id,
    p.product_name,
    COUNT(oi.order_item_id) AS times_ordered,
    SUM(oi.quantity) AS total_quantity_sold
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
HAVING COUNT(oi.order_item_id) > 10;

-- 3. Archive table
CREATE TABLE orders_archive (LIKE orders INCLUDING ALL);
INSERT INTO orders_archive
SELECT * FROM orders
WHERE order_date < CURRENT_DATE - INTERVAL '1 year';
```
</details>

## Problem 5: Complex Constraints

Create a `promotions` table with complex business rules:

**Rules:**
- Promotion has start_date and end_date
- end_date must be after start_date
- discount_percentage OR discount_amount (not both)
- minimum_order_amount must be positive if set
- max_uses must be positive if set

<details>
<summary>Solution</summary>

```sql
CREATE TABLE promotions (
    promotion_id SERIAL PRIMARY KEY,
    promotion_code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    discount_percentage DECIMAL(5,2),
    discount_amount DECIMAL(10,2),
    minimum_order_amount DECIMAL(10,2),
    max_uses INTEGER,
    current_uses INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Check end_date after start_date
    CONSTRAINT check_dates CHECK (end_date > start_date),

    -- Either discount_percentage OR discount_amount, not both
    CONSTRAINT check_discount_type CHECK (
        (discount_percentage IS NOT NULL AND discount_amount IS NULL) OR
        (discount_percentage IS NULL AND discount_amount IS NOT NULL)
    ),

    -- Validate discount ranges
    CONSTRAINT check_discount_percentage CHECK (
        discount_percentage IS NULL OR
        (discount_percentage > 0 AND discount_percentage <= 100)
    ),
    CONSTRAINT check_discount_amount CHECK (
        discount_amount IS NULL OR discount_amount > 0
    ),

    -- Positive values
    CONSTRAINT check_minimum_order CHECK (
        minimum_order_amount IS NULL OR minimum_order_amount > 0
    ),
    CONSTRAINT check_max_uses CHECK (
        max_uses IS NULL OR max_uses > 0
    ),
    CONSTRAINT check_current_uses CHECK (
        current_uses >= 0 AND (max_uses IS NULL OR current_uses <= max_uses)
    )
);
```
</details>

## Challenge: Design Your Own Schema

Design a complete database schema for one of:
1. Hotel booking system
2. Restaurant reservation and ordering
3. Fitness gym membership and classes
4. Car rental service
5. Online learning platform

Include:
- At least 6 tables
- All appropriate constraints
- Proper relationships
- Timestamps and audit fields
- At least 3 CHECK constraints
- Sample data insertion

## Learning Objectives
- CREATE, ALTER, DROP table operations
- Choose appropriate data types
- Implement PRIMARY and FOREIGN keys
- Use CHECK, UNIQUE, DEFAULT constraints
- Handle referential actions (CASCADE, RESTRICT)
- Work with temporary tables
- Create tables from queries (CTAS)
