# 00 - CLI and Setup

## Overview
This section covers the essential setup and command-line interface (CLI) tools needed to work with SQL databases, specifically PostgreSQL.

## Contents

### [PostgreSQL CLI Basics](postgresql-cli-basics.md)
Learn how to use the PostgreSQL command-line interface (psql) including:
- Installation and setup
- Connecting to databases
- Basic psql commands
- Meta-commands (\d, \dt, \l, etc.)
- Running SQL scripts
- Importing and exporting data
- Configuration and customization

## Prerequisites
Before starting this section, ensure you have:
- Basic command-line/terminal knowledge
- A computer with admin/sudo access for installation
- Internet connection for downloading PostgreSQL

## Installation

### PostgreSQL Installation

**macOS:**
```bash
# Using Homebrew
brew install postgresql@16

# Start PostgreSQL
brew services start postgresql@16
```

**Linux (Ubuntu/Debian):**
```bash
# Add PostgreSQL repository
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Import repository signing key
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Update and install
sudo apt-get update
sudo apt-get install postgresql-16
```

**Windows:**
1. Download installer from https://www.postgresql.org/download/windows/
2. Run the installer
3. Follow setup wizard
4. Remember the password you set for the postgres user

### Verify Installation
```bash
# Check PostgreSQL version
psql --version

# Connect to default database
psql -U postgres
```

## Quick Start

### 1. Create Your First Database
```bash
# Connect as postgres user
psql -U postgres

# Create a database
CREATE DATABASE mydb;

# Connect to it
\c mydb

# Create a table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100)
);

# Insert data
INSERT INTO users (name, email) VALUES ('Alice', 'alice@example.com');

# Query data
SELECT * FROM users;
```

### 2. Common psql Meta-Commands
```
\l              List all databases
\c dbname       Connect to database
\dt             List tables
\d tablename    Describe table
\du             List users/roles
\q              Quit psql
\?              Help on meta-commands
\h SQL_COMMAND  Help on SQL command
```

## Environment Setup

### Setting Up Environment Variables
```bash
# Add to ~/.bashrc or ~/.zshrc

# PostgreSQL connection defaults
export PGHOST=localhost
export PGPORT=5432
export PGUSER=postgres
export PGDATABASE=mydb
```

### Creating a Configuration File
Create `~/.psqlrc` for custom psql settings:
```
-- Set prompt to show database name
\set PROMPT1 '%n@%/%R%# '

-- Enable timing
\timing

-- Set null display
\pset null '¤'

-- Use expanded display for wide tables
\x auto
```

## GUI Tools (Optional)

While this course focuses on CLI, these GUI tools can be helpful:

1. **pgAdmin** - Official PostgreSQL GUI
   - Download: https://www.pgadmin.org/

2. **DBeaver** - Universal database tool
   - Download: https://dbeaver.io/

3. **DataGrip** - JetBrains database IDE
   - Download: https://www.jetbrains.com/datagrip/

4. **TablePlus** - Modern database GUI
   - Download: https://tableplus.com/

## Docker Setup (Alternative)

If you prefer using Docker:

```bash
# Pull PostgreSQL image
docker pull postgres:16

# Run PostgreSQL container
docker run --name postgres-sql-learning \
    -e POSTGRES_PASSWORD=mypassword \
    -e POSTGRES_DB=learningdb \
    -p 5432:5432 \
    -d postgres:16

# Connect to it
docker exec -it postgres-sql-learning psql -U postgres -d learningdb
```

## Troubleshooting

### Connection Issues
```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql  # Linux
brew services list  # macOS

# Check PostgreSQL logs
# macOS: /usr/local/var/log/postgresql@16.log
# Linux: /var/log/postgresql/postgresql-16-main.log
```

### Permission Issues
```sql
-- Grant permissions to user
GRANT ALL PRIVILEGES ON DATABASE mydb TO myuser;

-- Create new user
CREATE USER myuser WITH PASSWORD 'mypassword';
```

### Reset Password
```bash
# Edit pg_hba.conf to use 'trust' temporarily
# Then connect and change password
ALTER USER postgres WITH PASSWORD 'newpassword';
# Change pg_hba.conf back to 'md5' or 'scram-sha-256'
```

## Next Steps

After completing this setup section:
1. Review [postgresql-cli-basics.md](postgresql-cli-basics.md) for detailed CLI usage
2. Move on to [01-learn-the-basics](../01-learn-the-basics/README.md) to start learning SQL
3. Keep this reference handy for CLI commands

## Additional Resources

- **Official Documentation**: https://www.postgresql.org/docs/
- **psql Documentation**: https://www.postgresql.org/docs/current/app-psql.html
- **PostgreSQL Tutorial**: https://www.postgresqltutorial.com/
- **Interactive Learning**: https://pgexercises.com/

## Tips

1. **Practice in a safe environment** - Always practice on test databases
2. **Use transactions** - Wrap experimental queries in BEGIN/ROLLBACK
3. **Keep backups** - Use pg_dump for important data
4. **Learn keyboard shortcuts** - They speed up workflow significantly
5. **Read error messages** - PostgreSQL provides helpful error messages

## Common Errors and Solutions

**Error: "psql: command not found"**
- Solution: Add PostgreSQL bin directory to PATH

**Error: "connection refused"**
- Solution: Ensure PostgreSQL service is running

**Error: "peer authentication failed"**
- Solution: Check pg_hba.conf authentication method

**Error: "too many connections"**
- Solution: Increase max_connections in postgresql.conf or close unused connections

## Practice Exercise

Complete this setup verification:

1. Install PostgreSQL
2. Connect using psql
3. Create a database called `learning_sql`
4. Create a simple table
5. Insert and query some data
6. Use at least 5 different \commands
7. Export your table data

Once you're comfortable with the CLI, proceed to the first SQL learning section!
