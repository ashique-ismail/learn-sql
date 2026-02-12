# SQL Complete Learning Curriculum

**Comprehensive SQL learning from beginner to expert with 155 total problems**

> 📚 **Based on:** [roadmap.sh/sql](https://roadmap.sh/sql)

---

## 📊 Quick Overview

- **Learning Guide:** 17 sections, 125 focused problems
- **Comprehensive Problems:** 30 real-world challenges
- **Total Problems:** 155
- **Roadmap Coverage:** 100% ✅
- **Estimated Time:** 80-120 hours

---

## 🎯 Two-Track Learning System

### Track 1: [Learning Guide](learning-guide/) 📚
**Structured learning by topic**

- 17 sections (00-16)
- 125 focused problems
- 7-11 problems per topic
- Progressive difficulty
- Covers 100% of roadmap.sh

**Use for:** Systematic learning, concept mastery, building foundation

### Track 2: [Problems](problems/) 💡
**Comprehensive real-world challenges**

- 30 comprehensive problems
- Multi-concept scenarios
- Interview-style questions
- Real-world applications
- 4 difficulty phases

**Use for:** Practice, interviews, portfolio projects

---

## 🚀 Getting Started

### 1. Install PostgreSQL
```bash
# macOS
brew install postgresql

# Ubuntu/Debian
sudo apt-get install postgresql

# Windows
# Download from postgresql.org
```

### 2. Setup Database
```bash
# Create database
createdb sql_learning

# Load sample data
psql sql_learning < problems/setup-database.sql

# Verify
psql sql_learning -c "SELECT COUNT(*) FROM employees;"
```

### 3. Choose Your Path

**Beginner Path:**
```bash
cd learning-guide/00-cli-and-setup
# Master PostgreSQL CLI first
```

**Intermediate Path:**
```bash
cd learning-guide/08-join-queries
# Jump to advanced topics
```

**Interview Prep Path:**
```bash
cd problems/
# Start with real-world problems
```

---

## 📁 Structure

```
SQL/
├── learning-guide/              # Structured learning (125 problems)
│   ├── 00-cli-and-setup/
│   ├── 01-learn-the-basics/    (7 problems)
│   ├── 02-basic-sql-syntax/    (7 problems)
│   ├── 03-ddl/                 (7 problems)
│   ├── 04-dml/                 (10 problems)
│   ├── 05-aggregate-queries/   (8 problems)
│   ├── 06-data-constraints/    (7 problems)
│   ├── 07-views/               (7 problems)
│   ├── 08-join-queries/        (8 problems)
│   ├── 09-subqueries/          (9 problems)
│   ├── 10-advanced-functions/  (11 problems)
│   ├── 11-indexes/             (7 problems)
│   ├── 12-transactions-acid/   (7 problems)
│   ├── 13-data-integrity-security/ (7 problems)
│   ├── 14-stored-procedures-functions/ (8 problems)
│   ├── 15-performance-optimization/ (7 problems)
│   └── 16-advanced-sql-concepts/ (8 problems)
│
└── problems/                    # Comprehensive challenges (30 problems)
    ├── 01-basic-selection/ to 30-executive-dashboard/
    └── setup-database.sql
```

---

## 🎓 Learning Paths

### Path 1: Complete Mastery (16-20 weeks)
**All 155 problems + theory**

- Weeks 1-12: Complete learning-guide (all 17 sections)
- Weeks 13-16: Complete problems (all 30 challenges)
- Weeks 17-20: Build portfolio projects

**Best for:** Career change, comprehensive learning, database roles

---

### Path 2: Job Ready (10-12 weeks)
**Practical skills focus**

- Weeks 1-2: learning-guide sections 00-04 (basics)
- Weeks 3-5: learning-guide sections 05-09 (intermediate)
- Weeks 6-8: learning-guide sections 10-12 (advanced)
- Weeks 9-10: problems 1-20 (practice)
- Weeks 11-12: Interview prep + portfolio

**Best for:** Job seekers, bootcamp students

---

### Path 3: Interview Sprint (4-6 weeks)
**High-intensity preparation**

- Week 1: learning-guide sections 08-09 (JOINs, subqueries)
- Week 2: learning-guide section 10 (window functions)
- Week 3: problems 8-16 (intermediate challenges)
- Week 4: problems 17-26 (advanced challenges)
- Weeks 5-6: LeetCode SQL + mock interviews

**Best for:** Preparing for specific interviews

---

### Path 4: Concept-Specific
**Target specific gaps**

Choose sections based on your needs:
- Need JOINs? → learning-guide/08-join-queries + problems 6, 7, 19
- Need window functions? → learning-guide/10 + problems 10, 11, 22, 24, 26
- Need optimization? → learning-guide/11, 15 + problems 17, 23

**Best for:** Filling specific knowledge gaps

---

## 📚 What You'll Learn

### Core SQL (100% Roadmap.sh)
✅ DDL (CREATE, ALTER, DROP, TRUNCATE)
✅ DML (SELECT, INSERT, UPDATE, DELETE)
✅ Set Operations (UNION, INTERSECT, EXCEPT)
✅ Aggregate Functions (COUNT, SUM, AVG, MIN, MAX)
✅ GROUP BY, HAVING
✅ All Constraints (PK, FK, UNIQUE, CHECK, NOT NULL)
✅ Views and Materialized Views
✅ All JOIN types (INNER, LEFT, RIGHT, FULL, CROSS, SELF)
✅ Subqueries (Scalar, Column, Row, Table, Correlated)
✅ CTEs and Recursive CTEs
✅ Window Functions (RANK, ROW_NUMBER, LAG, LEAD, NTILE)
✅ String and Date Functions
✅ NULL Handling (COALESCE, NULLIF)
✅ Type Casting
✅ Indexes and Performance
✅ Transactions and ACID
✅ Stored Procedures and Functions
✅ Triggers

### Advanced PostgreSQL
✅ JSON/JSONB Operations
✅ Array Operations
✅ Full-Text Search
✅ LATERAL Joins
✅ DISTINCT ON (PostgreSQL-specific)
✅ Row-Level Security (RLS)
✅ Table Partitioning
✅ Advanced Aggregates

### Production Skills
✅ Query Optimization
✅ EXPLAIN and Query Plans
✅ Index Strategies
✅ Performance Tuning
✅ Data Integrity
✅ Security Best Practices
✅ Backup and Recovery
✅ User Management

---

## 🏆 What Makes This Complete

### 1. Dual-Track System
- **Focused Practice** (learning-guide): Master one concept at a time
- **Real-World Application** (problems): Apply multiple concepts together

### 2. 100% Roadmap Coverage
- Every topic from roadmap.sh/sql included
- Plus bonus advanced topics
- No critical gaps

### 3. Progressive Difficulty
- Start with SELECT, end with complex analytics
- Each problem builds on previous knowledge
- Clear difficulty markers

### 4. Production-Ready Skills
- Not just queries - includes security, performance, optimization
- Real-world scenarios
- Best practices throughout

### 5. Modern PostgreSQL
- Latest PostgreSQL features
- JSON, arrays, full-text search
- Advanced window functions

---

## 💡 How to Use This Curriculum

### For Complete Beginners
1. Start: learning-guide/00-cli-and-setup
2. Continue sequentially through learning-guide
3. After each section, try related problems from problems/
4. Build projects as you learn

### For Those with Basic SQL
1. Start: learning-guide/05-aggregate-queries
2. Work through intermediate sections (05-09)
3. Practice with problems/08-16
4. Focus on advanced sections (10-16)

### For Interview Preparation
1. Review: learning-guide sections 08, 09, 10
2. Practice: problems/08-26
3. Focus: Window functions, JOINs, Subqueries
4. Time yourself on problems
5. Can you explain solutions verbally?

### For On-the-Job Learning
1. Identify your gaps (JOINs? Performance? Security?)
2. Go to specific learning-guide sections
3. Practice with related problems
4. Apply to your real work scenarios

---

## 📊 Progress Tracking

### Learning Guide Progress
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

### Problems Progress
- [ ] Phase 1: Foundations (1-7)
- [ ] Phase 2: Intermediate (8-16)
- [ ] Phase 3: Advanced (17-26)
- [ ] Phase 4: Expert (27-30)

---

## 🎯 Quick Links

**Start Here:**
- [Learning Guide](learning-guide/) - Structured learning
- [Problems](problems/) - Comprehensive challenges
- [CLI Setup](learning-guide/00-cli-and-setup/) - First step

**Most Important Topics:**
- [JOINs](learning-guide/08-join-queries/)
- [Subqueries](learning-guide/09-subqueries/)
- [Window Functions](learning-guide/10-advanced-functions/)
- [Indexes](learning-guide/11-indexes/)
- [Performance](learning-guide/15-performance-optimization/)

**Interview Focus:**
- [Problems 8-16](problems/) - Intermediate challenges
- [Problems 17-26](problems/) - Advanced challenges
- [Window Functions Guide](learning-guide/10-advanced-functions/)

---

## 🔥 Tips for Success

1. **Consistency Over Intensity** - 1-2 hours daily beats 10 hours once a week
2. **Type Every Query** - Build muscle memory, don't copy-paste
3. **Use EXPLAIN** - Understand how queries execute
4. **Build Projects** - Apply skills to real scenarios
5. **Teach Others** - Best way to solidify understanding
6. **Review Regularly** - Revisit earlier problems
7. **Time Yourself** - Track improvement
8. **Join Community** - Learn with others

---

## 📈 After Completion

**You'll be able to:**
- Write complex SQL queries confidently
- Optimize slow queries
- Design database schemas
- Use advanced PostgreSQL features
- Pass SQL technical interviews
- Perform data analysis
- Build database-driven applications

**Next Steps:**
- Build portfolio projects
- Contribute to open-source
- Explore database administration
- Learn other databases (MySQL, MongoDB)
- Study distributed databases
- Advanced query optimization

---

## 🤝 Contributing

Found an issue or want to improve something?
- Create an issue
- Submit a pull request
- Share your solutions
- Help others learning

---

## 📚 Additional Resources

**Official Documentation:**
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [PostgreSQL Tutorial](https://www.postgresqltutorial.com/)

**Practice Platforms:**
- [LeetCode SQL](https://leetcode.com/problemset/database/)
- [HackerRank SQL](https://www.hackerrank.com/domains/sql)
- [SQLZoo](https://sqlzoo.net/)

**Books:**
- "SQL Queries for Mere Mortals" - John Viescas
- "SQL Performance Explained" - Markus Winand
- "The Art of PostgreSQL" - Dimitri Fontaine

---

**Ready to start?** → [Begin with CLI Setup](learning-guide/00-cli-and-setup/)

---

**Last Updated:** 2026-02-12
**Total Problems:** 155 (125 + 30)
**Sections:** 17
**Coverage:** 100% Roadmap.sh ✅
**Status:** Complete and Ready
