# Data Modeling

Status: draft (full prose, 2026-08-24)

Data modeling in Snowflake requires unlearning one instinct before learning what to do
instead: the traditional star-schema-first, partition-everything-manually approach doesn't
map cleanly onto how Snowflake actually stores data. The target is query performance, and
Snowflake's storage engine gets you most of the way there automatically before you've made
any modeling decisions at all.

## How storage actually works

Snowflake automatically divides every table into micro-partitions -- contiguous, immutable
units of roughly 50-500MB of uncompressed data, organized organically based on insertion
order rather than a schema someone designed by hand. Storage within each partition is
columnar, so individual columns compress independently and a query that only references a
few columns only reads those columns' data, not the whole row. Each micro-partition also
carries metadata -- value ranges, distinct counts -- that lets Snowflake skip partitions
entirely when a query's filters make it clear they can't contain relevant rows. This is the
mechanism, not clustering keys, that does most of the performance work in Snowflake, and it
requires no configuration to get.

The practical implication: load data ordered along the dimensions queries actually filter on
-- date, region, whatever the natural access pattern is. Snowflake captures that ordering in
the micro-partition metadata automatically, without anyone defining a manual partition
scheme. This is also why "perfect" clustering isn't the goal, and isn't necessary --
`SYSTEM$CLUSTERING_DEPTH` and `SYSTEM$CLUSTERING_INFORMATION` exist to monitor how well-
organized a table's partitions are over time, but the real measure of success is query
performance, not a metric approaching some theoretical ideal.

## When to add explicit clustering keys

Explicit clustering keys are the exception, not the default -- most tables never need one.
They're worth adding when a table meets several criteria at once: it's genuinely large (multi-
terabyte, spanning many micro-partitions), queries against it are selective (filtering down
to a small fraction of rows, or sorting), the access pattern is consistent across most
queries rather than varying widely, and the workload is read-heavy with infrequent updates.

When those conditions hold, key selection follows a priority order: columns used heavily in
`WHERE` filters come first, then columns used in `JOIN` predicates, capped at three or four
columns total -- more than that dilutes the benefit. Cardinality matters too: a clustering key
needs enough distinct values to actually enable partition pruning, but not so many that
Snowflake can't effectively group related rows together. A column with only a handful of
distinct values (like a boolean flag) won't help; a column that's nearly unique per row
(like a UUID) won't either.

## When not to cluster

Just as important as knowing when to add a clustering key is knowing when not to. Small
tables, tables with few micro-partitions, tables where queries don't actually filter or sort
on the candidate key columns, and tables under heavy DML load are all poor fits. That last
point deserves emphasis: reclustering is not free. It consumes real credits and storage, and
because Snowflake's Time Travel and Fail-safe retention preserve historical states, frequent
reclustering on a high-write table compounds that cost rather than being a one-time expense.
The credit and storage cost of clustering should be weighed against the query-performance
gain before it's added, not treated as a default optimization to apply everywhere large
tables exist.

Once a clustering key is defined, no additional administration is required day to day --
Snowflake handles reclustering automatically in the background. The ongoing responsibility is
monitoring, not maintenance: periodically checking clustering effectiveness via
`SYSTEM$CLUSTERING_INFORMATION` to confirm the key is still earning its cost as data and
query patterns evolve, rather than setting it once and assuming it stays optimal forever.

## Sources

- Micro-partitions & Data Clustering -- Snowflake Docs:
  https://docs.snowflake.com/en/user-guide/tables-clustering-micropartitions
- Clustering Keys & Clustered Tables -- Snowflake Docs:
  https://docs.snowflake.com/en/user-guide/tables-clustering-keys
