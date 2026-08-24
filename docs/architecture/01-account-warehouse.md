# Account & Warehouse Architecture

Status: draft, seeded from research (2026-08-24)

- Workload isolation via separate virtual warehouses per function (ELT/transform, BI/query,
  data science, GenAI/Cortex later) rather than one shared warehouse -- avoids resource
  contention and makes cost attribution clean.
- Multi-cluster warehouses as the default answer to "how do we handle bursty/concurrent load"
  instead of manual resizing -- scales automatically as concurrency fluctuates. Not a day-one requirement for
  every warehouse -- start single-cluster where concurrency is genuinely low, and reach for
  multi-cluster on the warehouses that actually see contention. The point is having the lever
  available and understood, not turning it on everywhere by default.
- Auto-suspend + auto-resume on every warehouse, no exceptions. Lock down who can disable
  either setting.
- CREATE WAREHOUSE and MODIFY privileges restricted to a small admin set -- prevents
  warehouse sprawl and accidental upsizing.
- STATEMENT_TIMEOUT_IN_SECONDS and STATEMENT_QUEUED_TIMEOUT_IN_SECONDS set at the warehouse
  level to kill runaway/stale queries before they burn credits.
- Storage/compute separation is architecturally why most of the above works (independent
  scaling on both axes) -- worth stating explicitly as the reason the rest of this holds,
  not just a fact on its own.

## Sources

- Cost controls for warehouses -- Snowflake Docs: https://docs.snowflake.com/en/user-guide/cost-controlling-controls
