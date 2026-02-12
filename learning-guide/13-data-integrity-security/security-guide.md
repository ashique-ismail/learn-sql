# 13 - Data Integrity and Security

## Overview
Data integrity and security are critical for protecting sensitive information and maintaining data accuracy. This section covers security best practices, user management, and data protection strategies.

## User Management

### Creating Users/Roles
```sql
-- Create user with password
CREATE USER john_doe WITH PASSWORD 'secure_password';

-- Create role (group of permissions)
CREATE ROLE developers;

-- Create user with options
CREATE USER admin_user WITH
    PASSWORD 'secure_password'
    CREATEDB
    CREATEROLE
    LOGIN;
```

### Altering Users
```sql
-- Change password
ALTER USER john_doe WITH PASSWORD 'new_password';

-- Grant superuser
ALTER USER john_doe WITH SUPERUSER;

-- Set connection limit
ALTER USER john_doe CONNECTION LIMIT 5;

-- Rename user
ALTER USER john_doe RENAME TO john_smith;
```

### Dropping Users
```sql
-- Drop user
DROP USER john_doe;

-- Reassign owned objects first
REASSIGN OWNED BY john_doe TO postgres;
DROP OWNED BY john_doe;
DROP USER john_doe;
```

## Permissions and Privileges

### GRANT Permissions
```sql
-- Grant table privileges
GRANT SELECT ON employees TO john_doe;
GRANT SELECT, INSERT, UPDATE ON orders TO john_doe;
GRANT ALL PRIVILEGES ON products TO admin_user;

-- Grant database privileges
GRANT CONNECT ON DATABASE company TO john_doe;
GRANT TEMP ON DATABASE company TO john_doe;

-- Grant schema privileges
GRANT USAGE ON SCHEMA public TO john_doe;
GRANT CREATE ON SCHEMA public TO developers;

-- Grant on all tables in schema
GRANT SELECT ON ALL TABLES IN SCHEMA public TO john_doe;

-- Grant future privileges
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO john_doe;
```

### REVOKE Permissions
```sql
-- Revoke specific privilege
REVOKE INSERT ON employees FROM john_doe;

-- Revoke all privileges
REVOKE ALL PRIVILEGES ON products FROM john_doe;

-- Revoke with CASCADE (removes dependent privileges)
REVOKE ALL PRIVILEGES ON DATABASE company FROM john_doe CASCADE;
```

### Role-Based Access Control (RBAC)
```sql
-- Create roles for different access levels
CREATE ROLE read_only;
CREATE ROLE read_write;
CREATE ROLE admin;

-- Grant privileges to roles
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO read_write;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin;

-- Assign roles to users
GRANT read_only TO john_doe;
GRANT read_write TO jane_smith;
GRANT admin TO admin_user;

-- User can switch to role
SET ROLE read_write;

-- Reset to original role
RESET ROLE;
```

## Row-Level Security (PostgreSQL)

### Enabling RLS
```sql
-- Enable row-level security on table
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;

-- Create policy
CREATE POLICY employee_isolation_policy ON employees
    FOR SELECT
    USING (department_id = current_setting('app.current_department')::int);

-- Users can only see rows matching policy
```

### Policy Examples
```sql
-- Managers see all in their department
CREATE POLICY manager_policy ON employees
    FOR ALL
    TO managers
    USING (department_id = current_setting('app.current_department')::int);

-- Users see only their own record
CREATE POLICY user_isolation_policy ON employees
    FOR SELECT
    USING (employee_id = current_setting('app.current_user_id')::int);

-- Policy for INSERT
CREATE POLICY insert_own_dept ON employees
    FOR INSERT
    WITH CHECK (department_id = current_setting('app.current_department')::int);

-- Policy for UPDATE
CREATE POLICY update_own_record ON employees
    FOR UPDATE
    USING (employee_id = current_setting('app.current_user_id')::int)
    WITH CHECK (employee_id = current_setting('app.current_user_id')::int);
```

### Managing Policies
```sql
-- Drop policy
DROP POLICY employee_isolation_policy ON employees;

-- Disable RLS
ALTER TABLE employees DISABLE ROW LEVEL SECURITY;

-- Force RLS even for table owner
ALTER TABLE employees FORCE ROW LEVEL SECURITY;
```

## Data Encryption

### Encryption at Rest
```sql
-- PostgreSQL: Enable encryption at tablespace level
-- (Requires pgcrypto extension)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Encrypt column data
CREATE TABLE secure_data (
    id SERIAL PRIMARY KEY,
    sensitive_data BYTEA
);

-- Insert encrypted data
INSERT INTO secure_data (sensitive_data)
VALUES (pgp_sym_encrypt('secret information', 'encryption_key'));

-- Query encrypted data
SELECT pgp_sym_decrypt(sensitive_data, 'encryption_key')
FROM secure_data;
```

### Hashing Passwords
```sql
-- Never store plain text passwords!
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Hash password
INSERT INTO users (username, password_hash)
VALUES ('john_doe', crypt('user_password', gen_salt('bf')));

-- Verify password
SELECT * FROM users
WHERE username = 'john_doe'
AND password_hash = crypt('user_password', password_hash);
```

## Connection Security

### SSL/TLS Connections
```sql
-- Require SSL connections
ALTER USER john_doe WITH CONNECTION LIMIT 10 IN GROUP ssl_users;

-- PostgreSQL pg_hba.conf
-- hostssl all all 0.0.0.0/0 md5

-- Check if connection is SSL
SELECT * FROM pg_stat_ssl WHERE pid = pg_backend_pid();
```

### Connection Limits
```sql
-- Limit connections per user
ALTER USER john_doe CONNECTION LIMIT 5;

-- View current connections
SELECT usename, COUNT(*)
FROM pg_stat_activity
GROUP BY usename;
```

## Auditing and Logging

### Audit Trail Table
```sql
-- Create audit table
CREATE TABLE audit_log (
    audit_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50),
    operation VARCHAR(10),
    user_name VARCHAR(50),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    old_data JSONB,
    new_data JSONB
);

-- Trigger for auditing
CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, operation, user_name, new_data)
        VALUES (TG_TABLE_NAME, TG_OP, current_user, row_to_json(NEW));
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, operation, user_name, old_data, new_data)
        VALUES (TG_TABLE_NAME, TG_OP, current_user, row_to_json(OLD), row_to_json(NEW));
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, operation, user_name, old_data)
        VALUES (TG_TABLE_NAME, TG_OP, current_user, row_to_json(OLD));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger to table
CREATE TRIGGER employees_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON employees
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();
```

### Query Logging
```sql
-- PostgreSQL logging configuration
-- log_statement = 'all'  # Log all statements
-- log_duration = on      # Log query duration
-- log_min_duration_statement = 1000  # Log queries > 1 second
```

## Data Validation

### Check Constraints
```sql
-- Validate data at insert/update
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    email VARCHAR(100) CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    age INTEGER CHECK (age >= 18 AND age <= 100),
    salary DECIMAL(10,2) CHECK (salary > 0),
    hire_date DATE CHECK (hire_date <= CURRENT_DATE)
);
```

### Domain Types
```sql
-- Create reusable domain with constraints
CREATE DOMAIN email_address AS VARCHAR(100)
    CHECK (VALUE ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

CREATE DOMAIN positive_amount AS DECIMAL(10,2)
    CHECK (VALUE > 0);

-- Use domains in tables
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    email email_address NOT NULL,
    credit_limit positive_amount
);
```

## SQL Injection Prevention

### Parameterized Queries (Best Practice)
```python
# Python example using psycopg2
# GOOD: Parameterized query
cursor.execute(
    "SELECT * FROM users WHERE username = %s AND password_hash = crypt(%s, password_hash)",
    (username, password)
)

# BAD: String concatenation (SQL injection risk!)
cursor.execute(
    f"SELECT * FROM users WHERE username = '{username}' AND password = '{password}'"
)
# If username = "admin' OR '1'='1", this bypasses authentication!
```

### Prepared Statements
```sql
-- PostgreSQL prepared statements
PREPARE get_employee (INTEGER) AS
    SELECT * FROM employees WHERE employee_id = $1;

EXECUTE get_employee(123);

DEALLOCATE get_employee;
```

## Backup and Recovery

### Logical Backups (pg_dump)
```bash
# Backup single database
pg_dump dbname > backup.sql

# Backup all databases
pg_dumpall > all_dbs_backup.sql

# Compressed backup
pg_dump -Fc dbname > backup.dump

# Restore
psql dbname < backup.sql
pg_restore -d dbname backup.dump
```

### Physical Backups
```bash
# PostgreSQL: Base backup
pg_basebackup -D /backup/location -Ft -z -P

# Continuous archiving (WAL)
# Configure in postgresql.conf:
# wal_level = replica
# archive_mode = on
# archive_command = 'cp %p /archive_location/%f'
```

### Point-in-Time Recovery (PITR)
```bash
# Restore base backup
tar -xzf base.tar.gz -C /data

# Configure recovery
cat > recovery.conf << EOF
restore_command = 'cp /archive_location/%f %p'
recovery_target_time = '2024-02-12 10:00:00'
EOF

# Start PostgreSQL (will recover to specified time)
```

## Security Best Practices

### 1. Principle of Least Privilege
```sql
-- Give users minimum necessary permissions
GRANT SELECT ON products TO sales_user;
-- Don't grant: GRANT ALL PRIVILEGES
```

### 2. Use Roles, Not Individual User Grants
```sql
-- Easier to manage
CREATE ROLE app_user;
GRANT SELECT, INSERT ON orders TO app_user;
GRANT app_user TO user1, user2, user3;
```

### 3. Separate Read and Write Access
```sql
CREATE ROLE read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;

CREATE ROLE read_write;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO read_write;
```

### 4. Protect Sensitive Data
```sql
-- Create views that exclude sensitive columns
CREATE VIEW employees_public AS
SELECT employee_id, first_name, last_name, department_id
FROM employees;
-- Excludes salary, ssn, etc.

GRANT SELECT ON employees_public TO general_users;
REVOKE ALL ON employees FROM general_users;
```

### 5. Regular Security Audits
```sql
-- Review granted permissions
SELECT grantee, table_name, privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'public';

-- Find superusers
SELECT usename FROM pg_user WHERE usesuper = true;
```

### 6. Use Strong Passwords
```sql
-- Enforce password policies (PostgreSQL extension)
CREATE EXTENSION IF NOT EXISTS passwordcheck;

-- Set password requirements in postgresql.conf
-- password_encryption = scram-sha-256
```

### 7. Enable Auditing
```sql
-- Log all DDL statements
-- log_statement = 'ddl'

-- Log all connections
-- log_connections = on
-- log_disconnections = on
```

## Common Security Vulnerabilities

### 1. SQL Injection
```sql
-- VULNERABLE
query = "SELECT * FROM users WHERE username = '" + username + "'"

-- SAFE: Use parameterized queries
-- See examples above
```

### 2. Weak Authentication
```sql
-- BAD: Storing passwords in plain text
CREATE TABLE users (password VARCHAR(50));

-- GOOD: Hash passwords
CREATE TABLE users (password_hash TEXT);
INSERT INTO users VALUES (crypt('password', gen_salt('bf')));
```

### 3. Excessive Privileges
```sql
-- BAD: Granting unnecessary privileges
GRANT ALL PRIVILEGES ON DATABASE company TO app_user;

-- GOOD: Grant only what's needed
GRANT SELECT, INSERT, UPDATE ON orders TO app_user;
```

## Practice Problems
Check the `problems` directory for hands-on security exercises.

## Key Takeaways
- Use role-based access control (RBAC)
- Apply principle of least privilege
- Hash passwords, never store plain text
- Use parameterized queries to prevent SQL injection
- Enable row-level security for multi-tenant apps
- Implement audit logging for sensitive operations
- Regularly backup data and test recovery
- Use SSL/TLS for connections
- Review and audit permissions regularly
- Protect sensitive data with views or encryption

## Next Steps
Move on to [14-stored-procedures-functions](../14-stored-procedures-functions/README.md) to learn about creating custom database logic.
