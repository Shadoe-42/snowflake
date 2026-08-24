# Open Table Formats & Interoperability

Status: draft (full prose, 2026-08-24)

Open table formats matter to this architecture for one reason above all others: lock-in
avoidance. A table stored purely in Snowflake's native format is only ever readable by
Snowflake; a table stored as an Iceberg Table is readable by any engine that speaks the
Iceberg format, Snowflake included. That distinction becomes important the moment an
organization wants to query the same data from more than one engine, or wants the option to
move off Snowflake without a full data migration.

## Iceberg Tables

Snowflake's Iceberg Tables combine external cloud storage -- data the organization manages
and controls the location of -- with the same query semantics and performance characteristics
as native Snowflake tables. The practical effect is that adopting Iceberg doesn't mean
sacrificing the query experience described elsewhere in this architecture; it means the
underlying data isn't captive to Snowflake's own storage format. This is also the natural
point of comparison against Databricks' Delta Lake approach once that repo exists --both
platforms have converged on "open storage format, proprietary query engine on top" as the
answer to the lock-in question, just with different formats.

## Catalog choice

Adopting Iceberg tables introduces a decision that doesn't exist with native tables: which
catalog tracks the tables and their metadata. Three options exist -- Snowflake can act as the
catalog itself, an external catalog can be used, or Apache Polaris (an open REST catalog,
either self-hosted or delivered as the managed Snowflake Open Catalog) can sit in the middle.
This is a real architectural decision, not a footnote: using Snowflake as the catalog is
simplest operationally but reintroduces a form of lock-in at the catalog layer even though
the underlying data is in an open format. Polaris exists specifically to avoid that --
Snowflake co-developed and donated it to the Apache Software Foundation to provide genuinely
cross-vendor catalog interoperability, rather than keeping catalog control proprietary while
the storage format is open. Which option makes sense depends on whether the organization
actually anticipates reading these tables from a non-Snowflake engine, or whether Iceberg is
being adopted purely for the storage-format flexibility with no near-term multi-engine plan.

## Sources

- "Modern Data Platform Requirements" white paper, Snowflake Inc., 2025 (private research
  directory, not part of this repo) -- vendor material, treated as a capability map, not
  independent verification.
