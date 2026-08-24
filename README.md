# Snowflake Reference Architecture

A worked example of a modern Snowflake platform for a company with real data volume and a
platform straining under it -- not a greenfield toy, not built for Amex- or Capital One-scale
requirements from day one. Covers account and warehouse architecture, security and
governance, data modeling, ingestion patterns, cost governance, open table formats, and
cross-cloud resilience, calibrated to what a growing organization actually needs first versus
what it grows into.

This repo builds in three phases: a general architecture foundation, a GenAI/Cortex-focused
narrowing of that same foundation, and a financial-services data warehouse variant. See
**Roadmap** below for what's built and what's still ahead.

## What this is, and is not

**Harborline Logistics is a fictional company**, built specifically for this project. It's a
mid-size logistics and distribution company -- real order, shipment, and inventory data
volume, not a hyperscale enterprise. Every technology named here (Snowflake, AWS, GCP) is
real and current; the company, its data, and its operations are not. Phase 3 introduces a
second, separate fictional company when the fin data warehouse variant needs a different
starting condition than Harborline's.

This is **reference architecture and reasoning**, not a production system. Nothing here has
been run against a live Snowflake account, reviewed by a third-party auditor, or checked by a
second practicing architect. Where Terraform exists, `terraform validate` passing means the
code is schema-correct, not that it would apply cleanly against a real account -- that gap
only closes by actually testing it against a sandbox environment. Treat this as a strong
starting point for real Snowflake architecture work, not as something already operated in
production.

Several sections draw on Snowflake's own white papers for capability categories and
terminology. That material is treated as a capability map, not independent verification --
marketing claims (benchmark numbers, "near-instant" language) are flagged for verification
against docs and behavior rather than repeated as fact. Source documents themselves live in a
local, private research directory that is not part of this repo and is not synced to GitHub.

## Structure

| Path | What is there |
|---|---|
| `docs/architecture/00-overview.md` | Scope, ground rules, Harborline Logistics, section index, open items |
| `docs/architecture/01-account-warehouse.md` | Workload isolation, multi-cluster scaling, auto-suspend/resume, warehouse access control |
| `docs/architecture/02-security-governance-rbac.md` | Four-layer RBAC hierarchy with scale on-ramp, Horizon Catalog, data masking, SSO/MFA |
| `docs/architecture/03-data-modeling.md` | Micro-partitions, clustering keys -- when to use them and when not to |
| `docs/architecture/04-ingestion-patterns.md` | COPY INTO, Snowpipe, Snowpipe Streaming, Dynamic Tables, Streams & Tasks -- a decision framework, not a feature list |
| `docs/architecture/05-cost-governance.md` | Resource monitors, usage-based pricing, and why auto-suspend actually matters |
| `docs/architecture/06-open-table-formats.md` | Iceberg Tables, catalog choice (Snowflake / external / Apache Polaris) |
| `docs/architecture/07-cross-cloud-resilience.md` | Snowgrid replication/failover -- deliberately lighter-weight, held to the same skepticism as the rest of this repo |
| `docs/integrations/csp-crosswalk.md` | AWS vs. GCP mechanics: storage integration (IAM role vs. service account), Snowpipe triggers (SQS/SNS vs. Pub/Sub), private connectivity (PrivateLink vs. Private Service Connect) |
| `docs/sharing/sharing-clean-rooms.md` | Placeholder -- Secure Data Sharing & Data Clean Rooms, sequenced with Phase 3 |
| `terraform/core/` | Cloud-agnostic Snowflake resources: resource monitor, warehouses, database/schemas, RBAC |
| `terraform/aws/` | S3 + IAM storage integration, direct S3-to-SQS Snowpipe auto-ingest |
| `terraform/gcp/` | GCS + service-account storage integration, GCS-notification-to-Pub/Sub Snowpipe auto-ingest |
| `examples/` | Placeholder -- empty until the architecture docs are stable enough to demonstrate concretely against Harborline |

## Roadmap

- **Phase 1 -- General architecture (in progress).** The seven architecture docs, the
  CSP crosswalk doc, and Terraform (core/aws/gcp, all `terraform validate`-clean) are
  built, with Harborline's examples woven through sections 01-04. Still open: an HLD
  diagram.
- **Phase 2 -- GenAI/Cortex narrowing (not started).** Branches from Phase 1 into Cortex AI,
  LLM Functions, RAG, and Snowflake ML, still on Harborline.
- **Phase 3 -- Fin data warehouse variant (not started).** A new fictional company, its own
  domain, and the Sharing & Data Clean Rooms doc.

## License

MIT. See `LICENSE`. Use the reasoning or any Terraform that lands here for your own Snowflake
work.
