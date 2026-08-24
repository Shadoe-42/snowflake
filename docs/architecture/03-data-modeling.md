# Data Modeling

Status: draft, seeded from research (2026-08-24)

- Snowflake's storage model (micro-partitions, 50-500MB, columnar, automatic) means the usual
  star-schema-first instinct needs a caveat: query performance is the real target, not a
  textbook-perfect schema.
- Load data ordered along natural query dimensions (date, region, etc.) -- Snowflake captures
  this automatically without manual partitioning.
- Explicit clustering keys are the exception, not the default. Only add them when: table is
  multi-TB+, queries are selective/filtered, access patterns are consistent, and it's
  read-heavy. Priority for key columns: WHERE-filter columns, then JOIN columns, max 3-4
  columns total. Moderate cardinality -- enough for pruning, not so much it can't group rows.
- Explicitly do NOT cluster: small tables, tables with heavy DML, tables where queries don't
  filter/sort on candidate columns. Reclustering has real credit + storage cost (Time
  Travel/Fail-safe retention included).
- SYSTEM$CLUSTERING_DEPTH / SYSTEM$CLUSTERING_INFORMATION for monitoring, not a one-time
  setup step.

## Sources

- Micro-partitions & Data Clustering -- Snowflake Docs:
  https://docs.snowflake.com/en/user-guide/tables-clustering-micropartitions
- Clustering Keys & Clustered Tables -- Snowflake Docs:
  https://docs.snowflake.com/en/user-guide/tables-clustering-keys
