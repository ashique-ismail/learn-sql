# Indexes - Practice Problems

## Problem 1: Identify Slow Queries
1. Use EXPLAIN to find seq scans
2. Measure query cost before/after index
3. Identify missing indexes
4. Find unused indexes
5. Analyze table statistics

## Problem 2: Create Basic Indexes
1. Index foreign keys
2. Index frequently queried columns
3. Index columns in WHERE clauses
4. Index columns in ORDER BY
5. Index columns in JOIN conditions

## Problem 3: Composite Indexes
1. Multi-column index for common query pattern
2. Determine optimal column order
3. Test index usage with EXPLAIN
4. Measure performance improvement
5. Covering index for index-only scan

## Problem 4: Partial Indexes
1. Index only active records
2. Index recent data only
3. Index by common filter values
4. Compare size: full vs partial index

## Problem 5: Special Index Types
1. GIN index for array/JSONB
2. Full-text search index
3. Expression index for calculated columns
4. Case-insensitive index
5. Hash index (when appropriate)

## Problem 6: Index Maintenance
1. Identify bloated indexes
2. Reindex tables
3. Analyze index usage statistics
4. Drop unused indexes
5. Monitor index size growth
