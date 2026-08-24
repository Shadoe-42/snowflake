# Cortex Search

Status: draft (full prose, 2026-08-24)

Where Cortex Analyst answers questions against structured data, Cortex Search answers
questions against text: carrier contracts, incident reports, standard operating procedures
-- the documents Harborline's dispatchers currently find by asking around or digging
through a shared drive. It's a hybrid semantic-plus-keyword search service, not a one-time
index: it stays current against its source query on a declared schedule, the same
target-lag idea Dynamic Tables use in `docs/architecture/04-ingestion-patterns.md`, applied
here to a search index instead of a transformed table.

## How it stays fresh

`terraform/genai/cortex_search.tf` defines `HARBORLINE_SEARCH_CARRIER_DOCS` against a
`query` -- a plain `SELECT` over an illustrative `CARRIER_DOCUMENTS` table -- and a
`target_lag` of one day. Snowflake reruns that query on schedule and keeps the search
index in sync with it automatically; there's no separate reindexing job to own or forget
about. `on` designates which column actually gets searched (`BODY_TEXT` here), and
`attributes` lists columns available to filter on without being part of the searchable text
itself (`CATEGORY`, so a query can be scoped to "incident reports only" without that
category name needing to appear in the matched text).

Embedding model choice is explicit rather than left to whatever the provider defaults to:
`snowflake-arctic-embed-m-v1.5` here, Snowflake's default and the right starting point.
`snowflake-arctic-embed-l-v2.0` is the higher-quality, higher-cost alternative, worth
revisiting once there's an actual query-quality signal (dispatchers reporting bad matches,
not a guess) to justify the tradeoff -- not a default optimization to reach for
speculatively, the same discipline Phase 1 applied to clustering keys and multi-cluster
warehouses.

## Where the text actually comes from

This service assumes `CARRIER_DOCUMENTS` already has clean, extracted text in a column --
it says nothing about how a scanned PDF or a handwritten incident report becomes that text
in the first place. That's exactly the gap Document AI (Arctic-TILT) is built to close, per
Snowflake's own DoD Document AI white paper, and it's exactly why that capability is flagged
as a deliberate open item in `00-overview.md` rather than pulled into this phase: building
the search service against text that doesn't yet exist would mean guessing at Document AI's
output shape instead of grounding it in a real extraction pass. `CARRIER_DOCUMENTS` isn't
created by this module, the same scoping choice made for `SHIPMENTS` in the Cortex Analyst
doc and for `RAW_LANDING` in Phase 1.

## Access

`USAGE` on the search service is what actually gates who can query it -- a grantable schema
object like any other, which in a real deployment means a new Access Role
(`AR_ANALYTICS_SEARCH_USAGE` or similar) added to `terraform/core/rbac.tf` once
`CARRIER_DOCUMENTS` is real. Not built here for the same reason the table itself isn't:
adding RBAC for an object that doesn't exist yet would be speculative, not governance.

## Sources

- Cortex Search Overview -- Snowflake Docs: https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-search/cortex-search-overview
- CREATE CORTEX SEARCH SERVICE -- Snowflake Docs: https://docs.snowflake.com/en/sql-reference/sql/create-cortex-search
