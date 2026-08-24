# Ingestion Patterns

Status: draft, seeded from research (2026-08-24)

- **COPY INTO (batch)** -- bulk/initial loads, or when precise transactional control matters
  and a warehouse is already being managed for other work.
- **Snowpipe (auto-ingest or REST)** -- continuous file-based ingestion, serverless, no
  warehouse management overhead. Default choice for "new files show up in a stage
  continuously." Auto-ingest relies on cloud-native event notifications (CSP-neutral here --
  see ../integrations/csp-crosswalk.md for SQS/SNS vs. Pub/Sub specifics).
- **Snowpipe Streaming** -- row-level, low-latency streaming when file-based Snowpipe isn't
  fast enough.
- **Dynamic Tables** -- default for SQL-expressible transformations downstream of ingestion.
  If the logic fits in a SELECT, it's a Dynamic Table candidate. 60-second minimum lag is
  the hard constraint.
- **Streams & Tasks** -- reserved for procedural logic, sub-minute freshness, custom merge
  logic, or multi-step pipelines needing manual orchestration control. More power, more
  ops burden.
- Decision framework: default to Dynamic Tables; drop to Streams+Tasks only when SLA or
  logic complexity demands it.

## Sources

- Best Practices for Data Ingestion with Snowflake -- Snowflake Blog:
  https://www.snowflake.com/en/blog/best-practices-for-data-ingestion/
- Dynamic Tables vs Streams and Tasks -- Data Today:
  https://data-today.net/snowflake/snowflake-pipelines-streams-tasks/
