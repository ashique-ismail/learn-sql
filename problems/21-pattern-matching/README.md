# Problem 21: Pattern Matching

**Difficulty:** Intermediate
**Concepts:** LIKE, ILIKE, String functions, SPLIT_PART, Pattern matching, Regular expressions
**Phase:** Advanced Features (Days 14-16)

---

## Learning Objectives

- Master pattern matching with LIKE and ILIKE operators
- Use wildcards (% and _) for flexible string matching
- Extract substrings using SPLIT_PART and SUBSTRING
- Apply string functions for data transformation
- Understand case-sensitive vs case-insensitive matching
- Work with regular expressions for advanced patterns

---

## Concept Summary

**String pattern matching** allows you to search for patterns in text data. SQL provides several operators and functions for working with strings.

### Syntax

```sql
-- Pattern matching
LIKE 'pattern'          -- Case-sensitive (most databases)
ILIKE 'pattern'         -- Case-insensitive (PostgreSQL)
NOT LIKE 'pattern'      -- Negation

-- Wildcards
%  -- Matches any sequence of characters (0 or more)
_  -- Matches exactly one character

-- String functions
CONCAT(str1, str2)                  -- Concatenate strings
UPPER(str), LOWER(str)              -- Case conversion
LENGTH(str)                         -- String length
SUBSTRING(str, start, len)          -- Extract substring
TRIM(str)                           -- Remove leading/trailing spaces
REPLACE(str, old, new)              -- Replace occurrences
POSITION(substr IN str)             -- Find position of substring
SPLIT_PART(str, delim, n)           -- Split string by delimiter
LEFT(str, n), RIGHT(str, n)         -- First/last n characters

-- PostgreSQL regex
~   -- Matches regex (case-sensitive)
~*  -- Matches regex (case-insensitive)
!~  -- Does not match regex (case-sensitive)
!~* -- Does not match regex (case-insensitive)
```

### Pattern Examples

```sql
-- Match emails ending with .com
WHERE email LIKE '%.com'

-- Match phone numbers (pattern: XXX-XXX-XXXX)
WHERE phone LIKE '___-___-____'

-- Match names starting with vowels
WHERE name ~* '^[AEIOU]'

-- Find records with specific word
WHERE description LIKE '%urgent%'
```

---

## Problem Statement

**Task:** Find employees whose email domain is 'company.com' and whose name starts with a vowel (A, E, I, O, U). Show name, email, and extract the username from email.

**Given:** employees table with columns (id, name, email, department, salary)

**Requirements:**
1. Filter by email domain: @company.com
2. Filter by name starting with vowel
3. Extract username (part before @) from email
4. Show name, email, and username

---

## Hint

Use LIKE for email pattern matching, ILIKE or regex for vowel matching, and SPLIT_PART to extract username before @.

---

## Your Solution

```sql
-- Write your solution here




```

---

## Solution

```sql
SELECT
    name,
    email,
    SPLIT_PART(email, '@', 1) as username
FROM employees
WHERE email LIKE '%@company.com'
  AND (name ILIKE 'A%' OR name ILIKE 'E%' OR name ILIKE 'I%'
       OR name ILIKE 'O%' OR name ILIKE 'U%')
ORDER BY name;
```

### Explanation

1. `email LIKE '%@company.com'` - Matches emails ending with @company.com
2. Multiple `ILIKE` conditions - Case-insensitive match for names starting with vowels
3. `SPLIT_PART(email, '@', 1)` - Splits email by '@' and returns first part (username)
4. `ORDER BY name` - Sorts results alphabetically by name

### Alternative Solutions

```sql
-- Method 1: Using regex (PostgreSQL) - More elegant
SELECT
    name,
    email,
    SPLIT_PART(email, '@', 1) as username
FROM employees
WHERE email LIKE '%@company.com'
  AND name ~* '^[AEIOU]'
ORDER BY name;

-- Method 2: Using SUBSTRING with POSITION
SELECT
    name,
    email,
    SUBSTRING(email FROM 1 FOR POSITION('@' IN email) - 1) as username
FROM employees
WHERE email LIKE '%@company.com'
  AND SUBSTRING(UPPER(name), 1, 1) IN ('A', 'E', 'I', 'O', 'U')
ORDER BY name;

-- Method 3: Extract domain and compare
SELECT
    name,
    email,
    SPLIT_PART(email, '@', 1) as username,
    SPLIT_PART(email, '@', 2) as domain
FROM employees
WHERE SPLIT_PART(email, '@', 2) = 'company.com'
  AND name ~* '^[AEIOU]'
ORDER BY name;

-- Method 4: Using LEFT for first character
SELECT
    name,
    email,
    SPLIT_PART(email, '@', 1) as username
FROM employees
WHERE email LIKE '%@company.com'
  AND UPPER(LEFT(name, 1)) IN ('A', 'E', 'I', 'O', 'U')
ORDER BY name;
```

---

## Try These Variations

1. Find employees with Gmail addresses
2. Find names containing exactly 5 characters
3. Find emails with numbers in the username
4. Extract and display both username and domain separately
5. Find employees whose names end with 'son'
6. Find phone numbers in format (XXX) XXX-XXXX
7. Find employees with hyphenated last names

### Solutions to Variations

```sql
-- 1. Gmail addresses
SELECT name, email
FROM employees
WHERE email LIKE '%@gmail.com'
   OR email LIKE '%@googlemail.com';

-- 2. Names with exactly 5 characters
SELECT name, LENGTH(name) as name_length
FROM employees
WHERE LENGTH(name) = 5;

-- Alternative with wildcards
SELECT name
FROM employees
WHERE name LIKE '_____'  -- Five underscores
  AND name NOT LIKE '% %';  -- Exclude spaces

-- 3. Emails with numbers in username
SELECT name, email, SPLIT_PART(email, '@', 1) as username
FROM employees
WHERE SPLIT_PART(email, '@', 1) ~ '[0-9]';

-- Alternative without regex
SELECT name, email
FROM employees
WHERE email SIMILAR TO '%[0-9]%@%';

-- 4. Extract username and domain
SELECT
    name,
    email,
    SPLIT_PART(email, '@', 1) as username,
    SPLIT_PART(email, '@', 2) as domain,
    CASE
        WHEN SPLIT_PART(email, '@', 2) LIKE '%.com' THEN 'Commercial'
        WHEN SPLIT_PART(email, '@', 2) LIKE '%.org' THEN 'Organization'
        WHEN SPLIT_PART(email, '@', 2) LIKE '%.edu' THEN 'Educational'
        ELSE 'Other'
    END as domain_type
FROM employees
ORDER BY domain, name;

-- 5. Names ending with 'son'
SELECT name
FROM employees
WHERE name LIKE '%son'
ORDER BY name;

-- 6. Phone numbers in specific format
SELECT name, phone
FROM employees
WHERE phone LIKE '(___) ___-____'
  AND phone ~ '^\([0-9]{3}\) [0-9]{3}-[0-9]{4}$';

-- 7. Hyphenated last names
SELECT name
FROM employees
WHERE name LIKE '%-%'
  AND name ~ '^[A-Za-z]+-[A-Za-z]+$';
```

---

## Sample Output

```
      name       |          email           |   username
-----------------+--------------------------+-------------
 Alice Johnson   | alice.j@company.com      | alice.j
 Emma Davis      | emma.davis@company.com   | emma.davis
 Ian Thompson    | ithompson@company.com    | ithompson
 Oliver Martinez | oliver.m@company.com     | oliver.m
 Uma Patel       | upatel@company.com       | upatel
```

---

## Common Mistakes

1. **Case sensitivity confusion:**
   - `LIKE` is case-sensitive in PostgreSQL
   - Use `ILIKE` for case-insensitive matching
   - Or use `UPPER(name) LIKE 'A%'`

2. **Forgetting wildcards:**
   - `email LIKE 'company.com'` matches exactly (wrong)
   - `email LIKE '%@company.com'` matches ending (correct)

3. **SPLIT_PART index confusion:**
   - Indexes start at 1, not 0
   - `SPLIT_PART('a@b', '@', 1)` returns 'a'
   - `SPLIT_PART('a@b', '@', 2)` returns 'b'

4. **Escaping special characters:**
   - To match literal %, use `LIKE '%\%%' ESCAPE '\'`
   - Or use different escape character

5. **Performance issues:**
   - Leading wildcards (`LIKE '%text'`) cannot use indexes
   - Consider full-text search for complex patterns
   - Regex can be slow on large datasets

6. **NULL handling:**
   - `NULL LIKE '%'` returns NULL (not true)
   - Use `COALESCE(column, '')` or `column IS NOT NULL`

---

## Pattern Matching Cheat Sheet

```sql
-- Basic patterns
'A%'        -- Starts with A
'%Z'        -- Ends with Z
'%SQL%'     -- Contains SQL
'_A%'       -- Second character is A
'A%Z'       -- Starts with A and ends with Z

-- Multiple patterns (OR)
WHERE name LIKE 'A%' OR name LIKE 'B%'
WHERE name ~ '^[AB]'  -- More efficient with regex

-- Negation
WHERE name NOT LIKE 'A%'
WHERE name !~ '^[AB]'

-- Case-insensitive
WHERE name ILIKE 'john%'
WHERE UPPER(name) LIKE 'JOHN%'
WHERE name ~* '^john'
```

---

## Regular Expression Examples

```sql
-- Email validation
WHERE email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'

-- Phone number (US format)
WHERE phone ~ '^\([0-9]{3}\) [0-9]{3}-[0-9]{4}$'

-- Alphanumeric only
WHERE username ~ '^[A-Za-z0-9]+$'

-- Password strength (at least one digit, one letter, min 8 chars)
WHERE password ~ '^(?=.*[A-Za-z])(?=.*\d).{8,}$'

-- Extract numbers from string
SELECT regexp_replace(text, '[^0-9]', '', 'g') as numbers_only
FROM table;

-- Split string into array
SELECT regexp_split_to_array(text, '\s+') as words
FROM table;
```

---

## Performance Notes

### Good for Performance
- `email LIKE 'john%'` - Can use index (prefix match)
- `email = 'john@example.com'` - Fastest (exact match)
- Simple patterns with known prefixes

### Bad for Performance
- `email LIKE '%@example.com'` - Cannot use regular B-tree index
- Complex regex on millions of rows
- Multiple OR conditions with LIKE

### Optimization Strategies
```sql
-- Create indexes
CREATE INDEX idx_email ON employees(email);
CREATE INDEX idx_email_domain ON employees((SPLIT_PART(email, '@', 2)));

-- Use trigram indexes for LIKE with leading wildcards (PostgreSQL)
CREATE EXTENSION pg_trgm;
CREATE INDEX idx_email_trgm ON employees USING gin(email gin_trgm_ops);

-- For regex patterns
CREATE INDEX idx_email_pattern ON employees(email text_pattern_ops);
```

---

## Real-World Use Cases

1. **Email validation:** Verify email format before processing
2. **Phone number formatting:** Extract and standardize phone numbers
3. **Data cleansing:** Find and fix inconsistent data formats
4. **Search functionality:** Implement "contains" or "starts with" search
5. **URL parsing:** Extract domain, protocol, or path from URLs
6. **Log analysis:** Parse log entries for specific patterns
7. **Data migration:** Transform data from one format to another

---

## String Function Reference

```sql
-- Extraction
SUBSTRING('Hello World', 1, 5)                  -- 'Hello'
LEFT('Hello World', 5)                          -- 'Hello'
RIGHT('Hello World', 5)                         -- 'World'
SPLIT_PART('a,b,c', ',', 2)                    -- 'b'

-- Transformation
UPPER('hello')                                  -- 'HELLO'
LOWER('HELLO')                                  -- 'hello'
INITCAP('hello world')                         -- 'Hello World'
REVERSE('hello')                               -- 'olleh'

-- Searching
POSITION('or' IN 'Hello World')                -- 7
STRPOS('Hello World', 'or')                    -- 7 (PostgreSQL)

-- Modification
CONCAT('Hello', ' ', 'World')                  -- 'Hello World'
REPLACE('Hello World', 'World', 'SQL')         -- 'Hello SQL'
TRIM('  hello  ')                              -- 'hello'
LPAD('5', 3, '0')                              -- '005'
RPAD('5', 3, '0')                              -- '500'

-- Analysis
LENGTH('Hello')                                 -- 5
CHAR_LENGTH('Hello')                           -- 5
```

---

## Related Problems

- **Previous:** [Problem 20 - E-commerce Analytics](../20-ecommerce-analytics/)
- **Next:** [Problem 22 - Latest Order Per Customer](../22-latest-order-per-customer/)
- **Related:** Problem 29 (Data Quality Audit - email validation), Problem 23 (Index Usage)

---

## Notes

```
Your notes here:




```

---

[← Previous](../20-ecommerce-analytics/) | [Back to Overview](../../README.md) | [Next Problem →](../22-latest-order-per-customer/)
