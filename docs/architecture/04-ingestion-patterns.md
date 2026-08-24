# Ingestion Patterns

Status: draft (full prose, 2026-08-24)

Snowflake offers several distinct ways to get data in and several distinct ways to transform
it once it's landed, and the temptation is to treat them as interchangeable. They're not --
each exists for a specific latency and control tradeoff, and picking the wrong one either
over-engineers a simple problem or under-delivers on a real freshness requirement. The
decision framework below is meant to be applied top-down: default to the simplest option that
meets the actual requirement, and only reach for more operational complexity when the
requirement genuinely demands it.

## Getting data in

**COPY INTO** is the batch-loading workhorse: it loads files from cloud storage or an
internal stage using a customer-managed virtual warehouse, synchronously, with immediate
status feedback and file-level transactional guarantees. It's the right choice for initial
bulk loads, or for any situation where precise control over the load and a warehouse that's
already being managed for other work make sense together.

**Snowpipe** handles continuous, file-based ingestion without any of that warehouse
management overhead -- it's a serverless service built on top of `COPY INTO` that
automatically detects and loads new files as they arrive. It comes in two flavors: auto-
ingest, which reacts to cloud storage event notifications (the CSP-specific mechanics --
SQS/SNS on AWS, Pub/Sub on GCP -- live in `../integrations/csp-crosswalk.md`, not here), and
a REST API variant for triggering ingestion programmatically when event notifications aren't
available or practical. Snowpipe is the default answer to "new files show up in a stage
continuously and we want them loaded without babysitting a warehouse."

**Snowpipe Streaming** exists for the cases where even Snowpipe's file-based latency isn't
fast enough -- it handles row-level ingestion for genuinely low-latency streaming scenarios,
at the cost of more operational surface area than file-based Snowpipe.

## Transforming data downstream

Once data has landed, the same top-down logic applies to transformation. **Dynamic Tables**
should be the default: if a transformation can be expressed as a single SQL `SELECT`, it's a
Dynamic Table candidate, and Snowflake manages the refresh automatically based on a declared
target lag. The one hard constraint is that target lag can't go below 60 seconds -- Dynamic
Tables are not a fit for genuinely sub-minute freshness requirements, and multi-step
pipelines get automatic dependency tracking between tables without anyone hand-wiring the
sequencing.

**Streams & Tasks** are the fallback for the cases Dynamic Tables can't cover: procedural
logic that doesn't fit in a `SELECT`, custom merge operations, sub-minute freshness
requirements, or multi-step pipelines where the orchestration itself needs to be explicit and
imperative rather than declarative. This is real power, but it comes with real operational
cost -- orchestration, failure handling, and sequencing all become the pipeline owner's
responsibility rather than Snowflake's.

The decision framework to carry forward: default to Dynamic Tables for anything SQL-
expressible, and drop down to Streams & Tasks only when the SLA or the logic complexity
genuinely demands it -- not because Streams & Tasks feels like the more "proper" engineering
choice. On cost, both approaches charge similarly for compute and storage; the actual waste
shows up when target lag is set tighter than the use case needs -- a one-minute target lag on
a table that's queried once a day burns credits for freshness nobody's using.

## Sources

- Best Practices for Data Ingestion with Snowflake -- Snowflake Blog:
  https://www.snowflake.com/en/blog/best-practices-for-data-ingestion/
- Dynamic Tables vs Streams and Tasks -- Data Today:
  https://data-today.net/snowflake/snowflake-pipelines-streams-tasks/
