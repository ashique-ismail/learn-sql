# 12 - Transactions and ACID Properties

## Overview
Transactions are sequences of database operations that execute as a single logical unit. They ensure data consistency and integrity even during failures.

**ACID Properties:**
- **Atomicity** - All or nothing
- **Consistency** - Valid state to valid state
- **Isolation** - Concurrent transactions don't interfere
- **Durability** - Committed changes persist

## Transaction Basics

### BEGIN, COMMIT, ROLLBACK
```sql
-- Start transaction
BEGIN;

-- Perform operations
UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;

-- Commit (make changes permanent)
COMMIT;

-- Or rollback (undo all changes)
ROLLBACK;
```

### Transaction Example
```sql
-- Transfer money between accounts
BEGIN;

-- Check sufficient balance
SELECT balance FROM accounts WHERE account_id = 1;
-- If balance >= 100, proceed

-- Debit from account 1
UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;

-- Credit to account 2
UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;

-- Verify totals
SELECT SUM(balance) FROM accounts WHERE account_id IN (1, 2);

-- If everything looks good:
COMMIT;

-- If something went wrong:
-- ROLLBACK;
```

## ACID Properties Explained

### Atomicity
All operations in a transaction succeed or all fail.

```sql
BEGIN;

INSERT INTO orders (customer_id, total) VALUES (1, 100);
INSERT INTO order_items (order_id, product_id, quantity)
VALUES (CURRVAL('orders_order_id_seq'), 5, 2);

-- If either INSERT fails, both are rolled back
COMMIT;
```

### Consistency
Database moves from one valid state to another.

```sql
-- Constraints maintain consistency
BEGIN;

-- This violates foreign key constraint
INSERT INTO orders (customer_id, total)
VALUES (999, 100);  -- customer_id 999 doesn't exist

-- Transaction automatically rolled back
-- Database remains consistent
```

### Isolation
Transactions don't see each other's uncommitted changes.

```sql
-- Transaction 1
BEGIN;
UPDATE products SET stock = stock - 1 WHERE product_id = 1;
-- Not yet committed

-- Transaction 2 (at same time)
BEGIN;
SELECT stock FROM products WHERE product_id = 1;
-- Sees old value (before Transaction 1's update)
```

### Durability
Once committed, changes survive system failures.

```sql
BEGIN;
INSERT INTO critical_data VALUES (...);
COMMIT;

-- Power failure here
-- Data is still there after restart
```

## Isolation Levels

### READ UNCOMMITTED
Lowest isolation, allows dirty reads (not supported in PostgreSQL).

### READ COMMITTED (Default in PostgreSQL)
```sql
-- Set isolation level
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

BEGIN;
-- Can see committed changes from other transactions
-- Cannot see uncommitted changes
```

**Phenomena Prevented:**
- Dirty reads (reading uncommitted data)

**Phenomena Allowed:**
- Non-repeatable reads
- Phantom reads

### REPEATABLE READ
```sql
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

BEGIN;
SELECT * FROM accounts WHERE account_id = 1;
-- Returns: balance = 1000

-- Another transaction commits: UPDATE accounts SET balance = 2000 WHERE account_id = 1

SELECT * FROM accounts WHERE account_id = 1;
-- Still returns: balance = 1000 (snapshot isolation)
COMMIT;
```

**Phenomena Prevented:**
- Dirty reads
- Non-repeatable reads

**Phenomena Allowed:**
- Phantom reads (in theory, but PostgreSQL prevents them)

### SERIALIZABLE
Strictest isolation, transactions execute as if serial.

```sql
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

BEGIN;
-- Complete isolation
-- May cause serialization failures
COMMIT;
```

**Phenomena Prevented:**
- Dirty reads
- Non-repeatable reads
- Phantom reads

### Choosing Isolation Level
```sql
-- Most applications: READ COMMITTED (default)
-- Financial systems: REPEATABLE READ or SERIALIZABLE
-- Reporting: READ COMMITTED is usually fine

-- Set for specific transaction
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Set for session
SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL REPEATABLE READ;
```

## Savepoints

### Creating Savepoints
```sql
BEGIN;

INSERT INTO customers (name) VALUES ('Alice');
SAVEPOINT sp1;

INSERT INTO orders (customer_id, total) VALUES (1, 100);
SAVEPOINT sp2;

INSERT INTO order_items (order_id, product_id, quantity) VALUES (1, 5, 2);

-- Oops, error in order_items
ROLLBACK TO SAVEPOINT sp2;
-- order_items insert rolled back, but customer and order remain

-- Or rollback to earlier savepoint
ROLLBACK TO SAVEPOINT sp1;
-- Now only customer insert remains

COMMIT;
```

### Release Savepoints
```sql
BEGIN;

INSERT INTO customers (name) VALUES ('Bob');
SAVEPOINT sp1;

INSERT INTO orders (customer_id, total) VALUES (2, 200);

-- Savepoint no longer needed
RELEASE SAVEPOINT sp1;

COMMIT;
```

## Locking

### Row-Level Locks

#### FOR UPDATE
```sql
BEGIN;

-- Lock rows for update
SELECT * FROM accounts WHERE account_id = 1 FOR UPDATE;

-- Other transactions wait until this transaction commits
UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;

COMMIT;
```

#### FOR SHARE
```sql
BEGIN;

-- Lock rows to prevent updates but allow other shared locks
SELECT * FROM products WHERE product_id = 1 FOR SHARE;

-- Other transactions can read but not update
COMMIT;
```

#### FOR UPDATE SKIP LOCKED
```sql
-- Skip locked rows instead of waiting
BEGIN;

SELECT * FROM queue
WHERE status = 'pending'
ORDER BY created_at
LIMIT 1
FOR UPDATE SKIP LOCKED;

-- Process the row
UPDATE queue SET status = 'processing' WHERE id = ...;

COMMIT;
```

### Table-Level Locks
```sql
BEGIN;

-- Exclusive lock
LOCK TABLE accounts IN EXCLUSIVE MODE;

-- Operations on table
UPDATE accounts SET balance = balance * 1.05;

COMMIT;
```

## Deadlocks

### What is a Deadlock?
Two transactions waiting for each other.

```sql
-- Transaction 1
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
-- Waits for lock on account 2...
UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;

-- Transaction 2 (at same time)
BEGIN;
UPDATE accounts SET balance = balance - 50 WHERE account_id = 2;
-- Waits for lock on account 1...
UPDATE accounts SET balance = balance + 50 WHERE account_id = 1;

-- DEADLOCK! PostgreSQL automatically detects and aborts one transaction
```

### Preventing Deadlocks
```sql
-- 1. Always acquire locks in same order
-- Good practice: order by ID
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE account_id = LEAST(1, 2);
UPDATE accounts SET balance = balance + 100 WHERE account_id = GREATEST(1, 2);
COMMIT;

-- 2. Keep transactions short
-- 3. Use appropriate isolation levels
-- 4. Use NOWAIT or SKIP LOCKED
```

### Detecting Deadlocks
```sql
-- PostgreSQL automatically detects deadlocks
-- Aborts one transaction with error:
-- ERROR: deadlock detected

-- Retry the transaction in application code
```

## Transaction Best Practices

### 1. Keep Transactions Short
```sql
-- BAD: Long transaction
BEGIN;
SELECT * FROM large_table;  -- Takes 5 minutes
UPDATE accounts SET balance = balance + 1 WHERE account_id = 1;
COMMIT;

-- GOOD: Short transaction
-- Do read-only work outside transaction
SELECT * FROM large_table;  -- Takes 5 minutes

BEGIN;
UPDATE accounts SET balance = balance + 1 WHERE account_id = 1;
COMMIT;
```

### 2. Acquire Locks in Consistent Order
```sql
-- Prevents deadlocks
BEGIN;
-- Always lock lower ID first
SELECT * FROM accounts WHERE account_id IN (1, 5) ORDER BY account_id FOR UPDATE;
COMMIT;
```

### 3. Handle Errors Properly
```sql
DO $$
BEGIN
    BEGIN
        -- Transaction operations
        INSERT INTO orders VALUES (...);
        INSERT INTO order_items VALUES (...);
        COMMIT;
    EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        RAISE NOTICE 'Transaction failed: %', SQLERRM;
    END;
END $$;
```

### 4. Use Appropriate Isolation Level
```sql
-- Default READ COMMITTED for most cases
-- REPEATABLE READ for financial operations
-- SERIALIZABLE for critical consistency requirements
```

### 5. Avoid Unnecessary Locks
```sql
-- Use FOR SHARE instead of FOR UPDATE when only reading
SELECT * FROM products WHERE product_id = 1 FOR SHARE;
```

## Transaction Patterns

### Optimistic Locking
```sql
-- Use version column
UPDATE accounts
SET balance = balance + 100, version = version + 1
WHERE account_id = 1 AND version = 5;

-- Check affected rows
-- If 0, someone else updated the row
```

### Pessimistic Locking
```sql
BEGIN;
SELECT * FROM accounts WHERE account_id = 1 FOR UPDATE;
-- Prevents concurrent updates
UPDATE accounts SET balance = balance + 100 WHERE account_id = 1;
COMMIT;
```

### Queue Processing
```sql
-- Process queue items without conflicts
BEGIN;

SELECT * FROM jobs
WHERE status = 'pending'
ORDER BY created_at
LIMIT 10
FOR UPDATE SKIP LOCKED;

UPDATE jobs SET status = 'processing' WHERE id IN (...);

COMMIT;

-- Process jobs...

-- Mark complete
UPDATE jobs SET status = 'completed' WHERE id IN (...);
```

## Distributed Transactions

### Two-Phase Commit (2PC)
```sql
-- Phase 1: Prepare
PREPARE TRANSACTION 'tx_identifier';

-- All participants prepare

-- Phase 2: Commit or abort
COMMIT PREPARED 'tx_identifier';
-- Or
ROLLBACK PREPARED 'tx_identifier';
```

## Monitoring Transactions

### Active Transactions
```sql
-- PostgreSQL: View active transactions
SELECT
    pid,
    usename,
    state,
    query_start,
    NOW() - query_start AS duration,
    query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_start;
```

### Long-Running Transactions
```sql
-- Find transactions running > 5 minutes
SELECT
    pid,
    NOW() - query_start AS duration,
    query
FROM pg_stat_activity
WHERE state != 'idle'
AND NOW() - query_start > INTERVAL '5 minutes';
```

### Blocking Queries
```sql
-- Find blocking queries (PostgreSQL)
SELECT
    blocked_locks.pid AS blocked_pid,
    blocked_activity.query AS blocked_query,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.query AS blocking_query
FROM pg_locks blocked_locks
JOIN pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
JOIN pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted
AND blocking_locks.granted;
```

## Practice Problems
Check the `problems` directory for hands-on transaction exercises.

## Key Takeaways
- Transactions ensure ACID properties
- BEGIN starts, COMMIT saves, ROLLBACK undoes
- Isolation levels control transaction visibility
- READ COMMITTED is default and usually sufficient
- Use FOR UPDATE to lock rows for update
- Keep transactions short to avoid blocking
- Lock resources in consistent order to prevent deadlocks
- Use savepoints for partial rollbacks
- Monitor long-running transactions
- Handle transaction errors properly in application code

## Next Steps
Move on to [13-data-integrity-security](../13-data-integrity-security/README.md) to learn about securing your database.
