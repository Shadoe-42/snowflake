# Open Table Formats & Interoperability

Status: draft, seeded from white paper research (2026-08-24)

- Apache Iceberg support (Iceberg Tables) -- external cloud storage with Snowflake table
  query semantics. Relevant for avoiding lock-in and for eventual comparison against
  Databricks' Delta Lake approach once the Databricks repo exists.
- Catalog choice matters: Snowflake as catalog, an external catalog, or Apache Polaris (open
  REST catalog, self-hosted or as Snowflake Open Catalog). Real architectural decision point
  -- affects portability if you ever need to read the same tables from a non-Snowflake engine.

## Sources

- "Modern Data Platform Requirements" white paper, Snowflake Inc., 2025 (snowflake_docs/) --
  vendor material, treated as a capability map, not independent verification.
