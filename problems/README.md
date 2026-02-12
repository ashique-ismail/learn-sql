# SQL Problems - Index

This directory contains 30 progressively challenging SQL problems, organized from beginner to expert level.

---

## How to Use This Directory

1. **Work sequentially** - Each problem builds on previous concepts
2. **Read the README** in each problem folder for detailed instructions
3. **Try solving** before looking at solutions
4. **Experiment** with the variations provided
5. **Take notes** in the notes section of each problem

---

## Problem Structure

Each problem folder contains:
- **README.md** - Complete problem guide with:
  - Learning objectives
  - Concept explanations
  - Problem statement
  - Hints
  - Solutions (multiple approaches)
  - Variations to practice
  - Common mistakes
  - Performance notes

---

## Phase 1: Foundations (Days 1-3)

### Basic Queries
- **[01 - Basic Selection](./01-basic-selection/)** ⭐
  - SELECT, FROM basics
  - Retrieving specific columns

- **[02 - Filtering Data](./02-filtering-data/)** ⭐
  - WHERE clause
  - Comparison and logical operators

- **[03 - Top Earners](./03-top-earners/)** ⭐
  - ORDER BY, LIMIT
  - Sorting and limiting results

---

## Phase 2: Intermediate Queries (Days 4-6)

### Aggregations & Grouping
- **[04 - Department Statistics](./04-department-statistics/)** ⭐
  - COUNT, SUM, AVG, MIN, MAX
  - Basic aggregate functions

- **[05 - Large Departments](./05-large-departments/)** ⭐
  - GROUP BY, HAVING
  - Filtering grouped data

### Joins
- **[06 - Employee Department Details](./06-employee-department-details/)** ⭐⭐
  - INNER JOIN, LEFT JOIN
  - Combining tables

- **[07 - Employee Manager Hierarchy](./07-employee-manager-hierarchy/)** ⭐⭐
  - Self JOIN
  - Hierarchical relationships

---

## Phase 3: Advanced Querying (Days 7-9)

### Subqueries & CTEs
- **[08 - Above Average Salary](./08-above-average-salary/)** ⭐⭐
  - Subqueries in WHERE
  - Correlated subqueries

- **[09 - Department Analysis](./09-department-analysis/)** ⭐⭐
  - Common Table Expressions (CTEs)
  - WITH clause, multiple CTEs

### Window Functions
- **[10 - Salary Ranking](./10-salary-ranking/)** ⭐⭐
  - Window functions
  - RANK(), PARTITION BY

- **[11 - Moving Average](./11-moving-average/)** ⭐⭐
  - Window frames
  - ROWS BETWEEN

---

## Phase 4: Data Manipulation (Days 10-11)

- **[12 - Salary Update](./12-salary-update/)** ⭐⭐
  - UPDATE statement
  - Modifying data safely

- **[27 - Multi-Table Update](./27-multi-table-update/)** ⭐⭐⭐
  - Complex UPDATE with JOINs
  - Updating from subqueries

---

## Phase 5: Database Design (Days 12-13)

- **[13 - Library Schema Design](./13-library-schema-design/)** ⭐⭐
  - CREATE TABLE
  - Constraints, foreign keys
  - Many-to-many relationships

---

## Phase 6: Advanced Features (Days 14-16)

### String & Date Functions
- **[14 - Monthly Revenue Analysis](./14-monthly-revenue-analysis/)** ⭐⭐
  - DATE_TRUNC, EXTRACT
  - Date arithmetic

- **[21 - Pattern Matching](./21-pattern-matching/)** ⭐⭐
  - LIKE, ILIKE, regex
  - String manipulation

### Conditional Logic
- **[15 - Categorize Salaries](./15-categorize-salaries/)** ⭐⭐
  - CASE expressions
  - Conditional logic

### Advanced Filtering
- **[16 - Orphaned Records](./16-orphaned-records/)** ⭐⭐
  - EXISTS, NOT EXISTS
  - Finding missing relationships

- **[22 - Latest Order Per Customer](./22-latest-order-per-customer/)** ⭐⭐⭐
  - DISTINCT ON (PostgreSQL)
  - Deduplication patterns

---

## Phase 7: Query Optimization (Days 17-18)

- **[17 - Query Optimization](./17-query-optimization/)** ⭐⭐⭐
  - Writing efficient queries
  - Avoiding common pitfalls

- **[23 - Index Usage Analysis](./23-index-usage-analysis/)** ⭐⭐⭐
  - EXPLAIN ANALYZE
  - Creating and using indexes

---

## Phase 8: Advanced Topics (Days 19-20)

### Recursive & Advanced Patterns
- **[18 - Organization Hierarchy](./18-organization-hierarchy/)** ⭐⭐⭐
  - Recursive CTEs
  - Tree traversal

- **[24 - Top Products Per Category](./24-top-products-per-category/)** ⭐⭐⭐
  - LATERAL joins
  - Top-N per group

- **[25 - Find Missing Days](./25-find-missing-days/)** ⭐⭐⭐
  - Generate series
  - Gap analysis

### Statistical Analysis
- **[26 - Salary Quartiles](./26-salary-quartiles/)** ⭐⭐⭐
  - PERCENTILE_CONT, NTILE
  - Statistical functions

### Complex Scenarios
- **[19 - Complex Join Challenge](./19-complex-join-challenge/)** ⭐⭐⭐
  - Multiple table joins
  - Complex filtering

---

## Phase 9: Real-World Scenarios (Days 21-25)

### Analytics & Business Intelligence
- **[20 - E-commerce Analytics](./20-ecommerce-analytics/)** ⭐⭐⭐⭐
  - Revenue analysis
  - Product performance
  - Customer insights

- **[28 - Customer Retention Analysis](./28-customer-retention-analysis/)** ⭐⭐⭐⭐
  - Cohort analysis
  - Retention metrics
  - CLV calculation

- **[30 - Executive Dashboard](./30-executive-dashboard/)** ⭐⭐⭐⭐
  - KPI calculations
  - Multi-section queries
  - Comprehensive reports

### Data Quality
- **[29 - Data Quality Audit](./29-data-quality-audit/)** ⭐⭐⭐⭐
  - Finding duplicates
  - Referential integrity
  - Validation rules

---

## Difficulty Legend

- ⭐ **Beginner** - Fundamental concepts
- ⭐⭐ **Intermediate** - Multiple concepts combined
- ⭐⭐⭐ **Advanced** - Complex queries, optimization
- ⭐⭐⭐⭐ **Expert** - Real-world analytics, comprehensive solutions

---

## Recommended Path

### Week 1: Foundations
Days 1-3: Problems 1-7

### Week 2: Intermediate Skills
Days 4-6: Problems 8-16

### Week 3: Advanced Techniques
Days 7-11: Problems 17-22

### Week 4: Expert Level
Days 12-13: Problems 23-26

### Week 5: Real-World Applications
Days 14-18: Problems 27-30

---

## Problem Topics Quick Reference

### By SQL Feature
**SELECT basics:** 1, 2, 3
**Aggregations:** 4, 5
**Joins:** 6, 7
**Subqueries:** 8
**CTEs:** 9, 18, 20, 28, 29, 30
**Window Functions:** 10, 11, 22, 26
**UPDATE/DELETE:** 12, 27
**CREATE TABLE:** 13
**Date Functions:** 14, 25
**String Functions:** 21
**CASE:** 15
**EXISTS:** 16
**Optimization:** 17, 23
**Recursive:** 18
**LATERAL:** 24
**Statistics:** 26
**Analytics:** 20, 28, 30
**Data Quality:** 29

### By Business Domain
**HR/Employee Management:** 1-12, 15, 16, 18, 26
**E-commerce:** 6, 14, 19, 20, 22, 24, 28
**Library System:** 13
**General Analytics:** 17, 23, 25, 29, 30

---

## Tips for Success

1. **Don't skip ahead** - Each problem builds on previous ones
2. **Type every query** - Don't copy-paste, build muscle memory
3. **Try variations** - Each problem includes 5+ variations to practice
4. **Use EXPLAIN** - Understand how your queries execute
5. **Take notes** - Use the notes section in each problem
6. **Review regularly** - Revisit problems after completing new ones
7. **Time yourself** - Track how long problems take to see progress
8. **Ask "what if"** - Modify problems to test edge cases

---

## Getting Help

If stuck on a problem:
1. Re-read the concept summary
2. Check the hint
3. Try to write pseudocode first
4. Look at simpler variations
5. Review related problems
6. Check the solution, understand each line
7. Close the solution and write it from memory

---

## Additional Resources

After completing problems, continue learning:
- Build your own database project
- Contribute solutions to community platforms
- Explore database-specific advanced features
- Learn query optimization deeply
- Study real production database schemas

---

[← Back to Main Guide](../README.md)
