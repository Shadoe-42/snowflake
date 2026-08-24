# Architecture Overview

Status: draft (full prose, 2026-08-24) -- sections 01-07 written; CSP crosswalk,
sharing/clean rooms, and Terraform are still separate, not-yet-started pieces.

Scope: broad "does it all" Snowflake reference architecture. Built small and incremental --
this is the foundation Phase 2 (GenAI/Cortex) and Phase 3 (fin data warehouse) both branch
from later.

## Motivating scenario & scale calibration

This is not built for Amex- or Capital One-scale requirements on day one. The realistic
starting point for exploring Snowflake is an organization that already has meaningful data
volume and a platform that's straining under it -- not a greenfield toy, not a hyperscale
bank either. "Small and incremental" means: don't front-load every enterprise-grade control
as if it's required from the first deployment. Patterns in this doc set that scale up
(the full four-layer RBAC hierarchy, multi-cluster warehouses, Horizon Catalog) are noted
with an on-ramp where it matters -- what to start with vs. what you grow into.

## Ground rules for this doc set

- **CSP-neutral.** Worded as "integrates with your CSP's object storage / IAM / eventing,"
  never AWS- or GCP-specific. Cloud mechanics live in ../integrations/csp-crosswalk.md.
  Snowflake's SQL/RBAC/warehouse behavior is genuinely near-identical across clouds, so
  cloud specifics only belong at the integration seams.
- **Vendor material gets treated as a capability map, not gospel.** Several sections draw on
  Snowflake's own white papers ("Modern Data Platform Requirements," 2025, and others from a
  private, non-synced research directory). Useful for identifying capability categories and
  terminology; marketing claims (benchmark numbers, "near-instant" language) are flagged for
  verification against docs/behavior rather than repeated as fact.
- **Domain-agnostic on purpose.** No fake business scenario forced onto Phase 1. Phase 2 and
  Phase 3 pick concrete domains (GenAI use case, fin services) when they narrow.

## Sections

1. account-warehouse -- workload isolation, multi-cluster scaling, auto-suspend/resume
2. security-governance-rbac -- four-layer role hierarchy, Horizon Catalog, masking, SSO/MFA
3. data-modeling -- micro-partitions, clustering keys, when (not) to use them
4. ingestion-patterns -- COPY INTO, Snowpipe, Snowpipe Streaming, Dynamic Tables, Streams & Tasks
5. cost-governance -- resource monitors, usage-based pricing tie-in
6. open-table-formats -- Iceberg Tables, catalog choice (Snowflake / external / Polaris)
7. cross-cloud-resilience -- Snowgrid replication/failover (lighter-weight section)

## Open items

- Network policies / row-column security depth not fully scoped yet.
- Terraform provider coverage gaps not yet researched (Iceberg/Polaris and Horizon Catalog
  resources worth checking specifically -- newer capabilities, provider support tends to lag).
- Terraform sequencing (alongside docs vs. second pass) not yet decided.
