# SQL Learning Guide

**Complete structured learning path from beginner to advanced SQL mastery**

> 📚 **Based on:** [roadmap.sh/sql](https://roadmap.sh/sql)

---

## 📊 Overview

- **Total Sections:** 17 (00-16)
- **Total Practice Problems:** 125
- **Roadmap Coverage:** 100% ✅
- **Estimated Time:** 60-100 hours

---

## 📁 Structure

```
00 - CLI and Setup              (Prerequisite)
01 - Learn the Basics           (7 problems)
02 - Basic SQL Syntax           (7 problems)
03 - DDL                        (7 problems)
04 - DML                        (10 problems)
05 - Aggregate Queries          (8 problems)
06 - Data Constraints           (7 problems)
07 - Views                      (7 problems)
08 - JOIN Queries               (8 problems)
09 - Subqueries                 (9 problems)
10 - Advanced Functions         (11 problems)
11 - Indexes                    (7 problems)
12 - Transactions + ACID        (7 problems)
13 - Data Integrity & Security  (7 problems)
14 - Stored Procedures/Functions(8 problems)
15 - Performance Optimization   (7 problems)
16 - Advanced SQL Concepts      (8 problems)
```

---

## 🎯 Learning Paths

### Path 1: Complete Mastery (16-20 weeks)
**All 125 problems + theory**

Work through all sections sequentially for comprehensive SQL mastery.

### Path 2: Job Ready (10-12 weeks)
**Focus on practical skills**

Skip theory-heavy sections, focus on problem-solving and real-world scenarios.

### Path 3: Interview Prep (4-6 weeks)
**Core problem-solving**

Focus on: JOINs, Subqueries, Window Functions, Performance, and common interview patterns.

---

## 🚀 Getting Started

### Prerequisites
1. PostgreSQL installed
2. Database created: `createdb sql_learning`
3. Sample data loaded: `psql sql_learning < ../problems/setup-database.sql`

### Start Learning
```bash
cd 00-cli-and-setup
# Learn PostgreSQL CLI basics

cd ../01-learn-the-basics
# Start with fundamentals
```

---

## 📖 How to Use

Each section contains:
- `problems/` - 7-11 practice problems
- Each problem folder has:
  - `README.md` - Problem statement and solution
  - `solution.sql` - Executable SQL code
  - `test-data.sql` - Sample data (if needed)

**Learning Flow:**
1. Read section concepts
2. Attempt problems without looking at solutions
3. Check solutions and understand approaches
4. Try problem variations

---

## ✅ Progress Tracking

Track your progress:
- [ ] 00-cli-and-setup
- [ ] 01-learn-the-basics (7/7)
- [ ] 02-basic-sql-syntax (7/7)
- [ ] 03-ddl (7/7)
- [ ] 04-dml (10/10)
- [ ] 05-aggregate-queries (8/8)
- [ ] 06-data-constraints (7/7)
- [ ] 07-views (7/7)
- [ ] 08-join-queries (8/8)
- [ ] 09-subqueries (9/9)
- [ ] 10-advanced-functions (11/11)
- [ ] 11-indexes (7/7)
- [ ] 12-transactions-acid (7/7)
- [ ] 13-data-integrity-security (7/7)
- [ ] 14-stored-procedures-functions (8/8)
- [ ] 15-performance-optimization (7/7)
- [ ] 16-advanced-sql-concepts (8/8)

---

## 🔗 Integration with Main Problems

**Two-track system:**

1. **learning-guide/** (This folder)
   - Structured learning by topic
   - 125 focused problems
   - Progressive difficulty

2. **../problems/** (Main folder)
   - 30 comprehensive challenges
   - Real-world scenarios
   - Interview-style problems

**Recommendation:** Use both for complete mastery!

---

## 📚 Section Details

### 🟢 Beginner (Sections 00-04)
**Foundation building**
- CLI setup and basics
- SQL syntax and data types
- DDL: Creating tables and schemas
- DML: Querying and modifying data
- **Time:** 20-30 hours

### 🟡 Intermediate (Sections 05-09)
**Core SQL skills**
- Aggregate functions and grouping
- Data constraints
- Views
- All JOIN types
- Subqueries and CTEs
- **Time:** 25-35 hours

### 🔴 Advanced (Sections 10-16)
**Professional skills**
- Window functions and advanced features
- Indexes and performance
- Transactions and ACID
- Security and integrity
- Stored procedures and functions
- Performance optimization
- Advanced PostgreSQL features
- **Time:** 30-40 hours

---

## 🎯 Key Topics Covered

**Core SQL (100% roadmap.sh):**
- ✅ DDL (CREATE, ALTER, DROP, TRUNCATE)
- ✅ DML (SELECT, INSERT, UPDATE, DELETE)
- ✅ Set Operations (UNION, INTERSECT, EXCEPT)
- ✅ Aggregate Functions (COUNT, SUM, AVG, MIN, MAX)
- ✅ GROUP BY, HAVING
- ✅ All Constraints (PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK, NOT NULL)
- ✅ Views and Materialized Views
- ✅ All JOIN types (INNER, LEFT, RIGHT, FULL, CROSS, SELF)
- ✅ Subqueries (Scalar, Column, Row, Table, Correlated)
- ✅ CTEs and Recursive CTEs
- ✅ Window Functions (RANK, ROW_NUMBER, LAG, LEAD, NTILE)
- ✅ String Functions
- ✅ Date/Time Functions
- ✅ NULL Handling (COALESCE, NULLIF)
- ✅ Type Casting
- ✅ Indexes and Performance
- ✅ Transactions and ACID
- ✅ Stored Procedures and Functions
- ✅ Triggers

**Beyond Roadmap (Bonus):**
- ✅ Data Integrity and Security
- ✅ Row-Level Security (RLS)
- ✅ Performance Optimization
- ✅ Query Tuning
- ✅ JSON/JSONB Operations
- ✅ Array Operations
- ✅ Full-Text Search
- ✅ LATERAL Joins
- ✅ Table Partitioning

---

## 💡 Tips for Success

1. **Don't Skip Problems** - Each problem builds on previous concepts
2. **Write SQL by Hand** - Don't just read solutions
3. **Use EXPLAIN** - Understand query execution plans
4. **Practice Daily** - 1-2 hours consistently beats cramming
5. **Build Projects** - Apply skills to real-world scenarios
6. **Review Regularly** - Revisit earlier sections
7. **Join Community** - Discuss solutions with others

---

## 🔥 Quick Reference

**Most Important Sections for Interviews:**
- 08-join-queries (All JOIN types)
- 09-subqueries (CTEs and subqueries)
- 10-advanced-functions (Window functions)
- 11-indexes (Performance)

**Most Important for Production:**
- 11-indexes (Query optimization)
- 12-transactions-acid (Data integrity)
- 13-data-integrity-security (Security)
- 15-performance-optimization (Tuning)

---

## 📊 Difficulty Levels

Each problem is marked with difficulty:
- ⭐ Beginner (Sections 01-04)
- ⭐⭐ Intermediate (Sections 05-09)
- ⭐⭐⭐ Advanced (Sections 10-14)
- ⭐⭐⭐⭐ Expert (Sections 15-16)

---

**Ready to start?** → Begin with [00-cli-and-setup](00-cli-and-setup/)

**Questions?** Create an issue or contribute improvements!

---

**Last Updated:** 2026-02-12
**Sections:** 17
**Problems:** 125
**Status:** ✅ Complete
