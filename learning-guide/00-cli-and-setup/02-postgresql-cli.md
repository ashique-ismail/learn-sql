# PostgreSQL Command Line Interface (psql) Guide

Complete reference for working with PostgreSQL from the command line.

---

## Table of Contents
1. [Getting Started](#getting-started)
2. [Connection Commands](#connection-commands)
3. [Meta-Commands](#meta-commands)
4. [Query Execution](#query-execution)
5. [Output Formatting](#output-formatting)
6. [Import/Export Data](#importexport-data)
7. [Useful Tips & Tricks](#useful-tips--tricks)
8. [Troubleshooting](#troubleshooting)

---

## Getting Started

### Installation Verification
```bash
# Check PostgreSQL version
psql --version

# Check if PostgreSQL server is running
pg_isready

# Check server status (macOS)
brew services list | grep postgresql

# Check server status (Linux)
sudo systemctl status postgresql
```

### Starting PostgreSQL Server
```bash
# macOS (Homebrew)
brew services start postgresql@14

# Linux (systemd)
sudo systemctl start postgresql

# Docker
docker run --name postgres -e POSTGRES_PASSWORD=password -p 5432:5432 -d postgres
```

---

## Connection Commands

### Basic Connection
```bash
# Connect to default database
psql

# Connect to specific database
psql sql_learning

# Connect with specific user
psql -U username -d database_name

# Connect to remote database
psql -h hostname -p 5432 -U username -d database_name

# Connect with password prompt
psql -U username -d database_name -W

# Connection string format
psql postgresql://username:password@localhost:5432/database_name
```

### Connection Examples
```bash
# Local connection
psql -U postgres -d sql_learning

# Remote connection with SSL
psql "postgresql://user@host:5432/dbname?sslmode=require"

# Connection via environment variable
export PGDATABASE=sql_learning
export PGUSER=postgres
psql  # Uses environment variables
```

---

## Meta-Commands

### Database Information

```sql
-- List all databases
\l
\list

-- Connect to database
\c database_name
\connect database_name

-- Show current database
SELECT current_database();

-- Database size
\l+
SELECT pg_database.datname, pg_size_pretty(pg_database_size(pg_database.datname))
FROM pg_database;
```

### Table Information

```sql
-- List all tables
\dt

-- List tables with details (sizes)
\dt+

-- List all tables in all schemas
\dt *.*

-- Describe table structure
\d table_name

-- Detailed table description
\d+ table_name

-- List only table names
\dt *.* | grep tablename

-- Show table indexes
\di table_name

-- Show table size
\dt+ table_name
```

### Schema Information

```sql
-- List all schemas
\dn

-- List schemas with details
\dn+

-- Set search path
SET search_path TO schema_name, public;

-- Show current schema
SELECT current_schema();
```

### View Information

```sql
-- List all views
\dv

-- List views with details
\dv+

-- Describe view
\d+ view_name
```

### Index Information

```sql
-- List all indexes
\di

-- List indexes with details
\di+

-- Show indexes on specific table
\d table_name  -- includes indexes
```

### Function Information

```sql
-- List all functions
\df

-- List functions with details
\df+

-- List specific function
\df function_name
```

### User & Permission Information

```sql
-- List all users/roles
\du

-- List roles with details
\du+

-- Show current user
SELECT current_user;

-- Show table permissions
\dp table_name
\z table_name
```

### Sequence Information

```sql
-- List all sequences
\ds

-- Show sequence details
\d sequence_name
```

---

## Query Execution

### Running Queries

```sql
-- Single line query
SELECT * FROM employees LIMIT 5;

-- Multi-line query (end with semicolon)
SELECT name, salary
FROM employees
WHERE salary > 50000
ORDER BY salary DESC;

-- Query without semicolon (use \g to execute)
SELECT * FROM employees LIMIT 5 \g

-- Run and show query execution time
\timing on
SELECT COUNT(*) FROM employees;
\timing off
```

### Executing SQL Files

```bash
# Execute SQL file from shell
psql -d sql_learning -f script.sql

# Execute file from within psql
\i /path/to/script.sql
\include /path/to/script.sql

# Execute file with relative path
\i ../scripts/setup.sql

# Execute and show each command
\i script.sql \echo 'Script completed'
```

### Transaction Control

```sql
-- Start transaction
BEGIN;

-- Make changes
UPDATE employees SET salary = salary * 1.1 WHERE dept_id = 1;

-- Check changes
SELECT * FROM employees WHERE dept_id = 1;

-- Commit or rollback
COMMIT;
-- or
ROLLBACK;

-- Savepoints
BEGIN;
UPDATE employees SET salary = 50000 WHERE id = 1;
SAVEPOINT my_savepoint;
UPDATE employees SET salary = 60000 WHERE id = 2;
ROLLBACK TO SAVEPOINT my_savepoint;
COMMIT;
```

---

## Output Formatting

### Display Modes

```sql
-- Aligned columns (default)
\pset format aligned
SELECT * FROM employees LIMIT 3;

-- Unaligned (CSV-like)
\pset format unaligned
SELECT * FROM employees LIMIT 3;

-- HTML format
\pset format html
SELECT * FROM employees LIMIT 3;

-- Expanded display (vertical)
\x
SELECT * FROM employees LIMIT 1;
\x  -- toggle off

-- Auto expanded (use when output is wide)
\x auto

-- Wrapped display
\pset format wrapped
```

### Output Settings

```sql
-- Show/hide column headers
\pset tuples_only on   -- hide headers
\pset tuples_only off  -- show headers

-- Set null display
\pset null '(null)'

-- Set field separator
\pset fieldsep ','

-- Set border style
\pset border 0  -- none
\pset border 1  -- internal lines
\pset border 2  -- full box

-- Line style
\pset linestyle ascii
\pset linestyle unicode
\pset linestyle old-ascii

-- Pager control
\pset pager off  -- disable pager
\pset pager on   -- enable pager
```

### Saving Output

```bash
# Redirect output to file
\o output.txt
SELECT * FROM employees;
\o  -- stop redirecting

# Copy query results to CSV
\copy (SELECT * FROM employees) TO '/path/to/employees.csv' CSV HEADER

# Copy with custom delimiter
\copy employees TO 'employees.tsv' DELIMITER E'\t' CSV HEADER
```

---

## Import/Export Data

### Export Data

```bash
# Export entire database
pg_dump sql_learning > backup.sql

# Export specific table
pg_dump sql_learning -t employees > employees.sql

# Export as CSV
\copy (SELECT * FROM employees) TO 'employees.csv' CSV HEADER

# Export with psql
psql -d sql_learning -c "COPY employees TO STDOUT CSV HEADER" > employees.csv

# Export schema only
pg_dump sql_learning --schema-only > schema.sql

# Export data only
pg_dump sql_learning --data-only > data.sql

# Compressed backup
pg_dump sql_learning | gzip > backup.sql.gz
```

### Import Data

```bash
# Import SQL file
psql sql_learning < backup.sql

# Import from within psql
\i backup.sql

# Import CSV
\copy employees FROM 'employees.csv' CSV HEADER

# Import with specific columns
\copy employees(name, email, salary) FROM 'employees.csv' CSV HEADER

# Restore from pg_dump
psql sql_learning < backup.sql

# Restore compressed backup
gunzip -c backup.sql.gz | psql sql_learning
```

### COPY Command

```sql
-- Copy from CSV (must be superuser or use \copy)
COPY employees FROM '/path/to/employees.csv' CSV HEADER;

-- Copy to CSV
COPY employees TO '/path/to/employees.csv' CSV HEADER;

-- Copy query results
COPY (SELECT * FROM employees WHERE salary > 50000) TO '/path/to/high_earners.csv' CSV HEADER;

-- Copy with custom delimiter
COPY employees FROM '/path/to/employees.txt' DELIMITER '|' NULL 'N/A';
```

---

## Useful Tips & Tricks

### History & Editing

```sql
-- Show command history
\s

-- Save history to file
\s history.txt

-- Edit query in external editor
\e

-- Edit specific function
\ef function_name

-- Re-execute last query
\g

-- Clear screen
\! clear  -- Unix/Linux
\! cls    -- Windows
```

### Variables

```sql
-- Set variable
\set myvar 100

-- Use variable in query
SELECT * FROM employees WHERE id = :myvar;

-- Special variables
\set AUTOCOMMIT off
\set ON_ERROR_STOP on
\set ON_ERROR_ROLLBACK on

-- Show all variables
\set

-- Unset variable
\unset myvar
```

### Shell Commands

```bash
-- Execute shell command
\! ls -la

-- Execute and show output
\! pwd

-- Change directory (psql context)
\cd /path/to/directory

-- Show current directory
\! pwd
```

### Watch Queries

```sql
-- Run query every 2 seconds
\watch 2
SELECT COUNT(*) FROM employees;

-- Run with interval (Ctrl+C to stop)
\watch 5
SELECT pg_database_size(current_database());
```

### Query Planning

```sql
-- Show query execution plan
\timing on
EXPLAIN SELECT * FROM employees WHERE salary > 50000;

-- Show actual execution
EXPLAIN ANALYZE SELECT * FROM employees WHERE salary > 50000;

-- Verbose explain
EXPLAIN (ANALYZE, VERBOSE, BUFFERS) SELECT * FROM employees WHERE salary > 50000;
```

---

## Troubleshooting

### Connection Issues

```bash
# Check if PostgreSQL is running
pg_isready

# Check connection
psql -U postgres -d postgres -c "SELECT 1;"

# View connection settings
psql -d postgres -c "SHOW all;"

# Check port
psql -h localhost -p 5432 -U postgres

# Connection troubleshooting
tail -f /usr/local/var/log/postgresql.log  # macOS
tail -f /var/log/postgresql/postgresql-14-main.log  # Linux
```

### Common Errors

**Error: "psql: FATAL: database does not exist"**
```bash
# Create the database
createdb sql_learning

# Or connect to postgres database first
psql -d postgres
CREATE DATABASE sql_learning;
```

**Error: "psql: FATAL: role does not exist"**
```bash
# Create user
createuser -s username

# Or as superuser
psql -d postgres
CREATE ROLE username WITH LOGIN PASSWORD 'password';
```

**Error: "permission denied for table"**
```sql
-- Grant permissions
GRANT ALL PRIVILEGES ON TABLE employees TO username;
GRANT ALL PRIVILEGES ON DATABASE sql_learning TO username;
```

**Error: "could not connect to server"**
```bash
# Start PostgreSQL
brew services start postgresql@14  # macOS
sudo systemctl start postgresql     # Linux

# Check if port is in use
lsof -i :5432
```

### Performance Queries

```sql
-- Show active queries
SELECT pid, usename, application_name, state, query
FROM pg_stat_activity
WHERE state != 'idle';

-- Kill long-running query
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE pid = <process_id>;

-- Show database size
SELECT pg_size_pretty(pg_database_size(current_database()));

-- Show largest tables
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;

-- Show cache hit ratio
SELECT
    sum(heap_blks_read) as heap_read,
    sum(heap_blks_hit)  as heap_hit,
    sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as ratio
FROM pg_statio_user_tables;
```

---

## Quick Reference Card

### Essential Commands
```
\?              - Help on meta-commands
\h              - Help on SQL commands
\q              - Quit psql
\l              - List databases
\c dbname       - Connect to database
\dt             - List tables
\d tablename    - Describe table
\du             - List users
\x              - Toggle expanded display
\timing         - Toggle timing
\i file.sql     - Execute SQL file
\o file.txt     - Redirect output
\! command      - Execute shell command
\q              - Quit
```

### Common Patterns
```bash
# Quick table check
\dt
\d+ tablename

# Quick query with timing
\timing on
SELECT ...;

# Export results
\o output.txt
SELECT ...;
\o

# Watch live data
\watch 2
SELECT COUNT(*) FROM table;
```

---

## Best Practices

1. **Always use transactions for data changes**
   ```sql
   BEGIN;
   -- your changes
   COMMIT;
   ```

2. **Use EXPLAIN before running expensive queries**
   ```sql
   EXPLAIN ANALYZE SELECT ...;
   ```

3. **Set ON_ERROR_ROLLBACK in interactive sessions**
   ```sql
   \set ON_ERROR_ROLLBACK on
   ```

4. **Use aliases for better readability**
   ```bash
   alias pglocal='psql -h localhost -U postgres'
   ```

5. **Save frequently used queries**
   ```bash
   # Create a .psqlrc file in home directory
   echo "\set AUTOCOMMIT off" >> ~/.psqlrc
   echo "\set ON_ERROR_ROLLBACK on" >> ~/.psqlrc
   echo "\x auto" >> ~/.psqlrc
   echo "\set VERBOSITY verbose" >> ~/.psqlrc
   echo "\pset null '(null)'" >> ~/.psqlrc
   ```

---

## Configuration File (.psqlrc)

Create `~/.psqlrc` for custom settings:

```sql
-- Automatically rollback on error in interactive mode
\set ON_ERROR_ROLLBACK interactive

-- Show query execution time
\timing on

-- Use best available output format
\x auto

-- Verbose error messages
\set VERBOSITY verbose

-- Show NULL values clearly
\pset null '∅'

-- Better prompt showing database and user
\set PROMPT1 '%[%033[1m%]%M %n@%/%R%[%033[0m%]%# '

-- Handy shortcuts
\set uptime 'SELECT now() - pg_postmaster_start_time() AS uptime;'
\set show_slow_queries 'SELECT (total_time / 1000 / 60) as total_minutes, mean_time as average_time, query FROM pg_stat_statements ORDER BY 1 DESC LIMIT 20;'
```

---

## Resources

- [Official psql Documentation](https://www.postgresql.org/docs/current/app-psql.html)
- [PostgreSQL Command Line Cheat Sheet](https://postgrescheatsheet.com/)
- [psql Tips and Tricks](https://www.postgresql.org/docs/current/app-psql.html#APP-PSQL-TIPS)

---

**Next:** [SQL Debugging Guide](SQL-Debugging-Guide.md)
