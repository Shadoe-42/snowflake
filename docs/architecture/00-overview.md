# Architecture Overview

Status: draft (full prose, 2026-08-24, status line refreshed 2026-09-01) -- sections 01-07
written, CSP crosswalk doc written, Terraform (core/aws/gcp) built and validate-clean,
Harborline woven through 01-04. Phase 2 (GenAI/Cortex, `docs/genai/`) and Phase 3 (fin data
warehouse variant plus Sharing/Clean Rooms, `docs/fin-warehouse/` and `docs/sharing/`) are
both complete for their chosen scope -- see the root README's Roadmap for what each phase
actually covers.

Scope: broad "does it all" Snowflake reference architecture. Built small and incremental --
this is the foundation Phase 2 (GenAI/Cortex) and Phase 3 (fin data warehouse) both branch
from later.

## Motivating scenario & scale calibration

**Harborline Logistics** is the fictional company this architecture is built around, starting
from this doc forward. Harborline is a mid-size logistics and distribution company: real
order, shipment, and inventory volume, a platform straining under growth, not a greenfield
toy and not an Amex- or Capital One-scale requirement on day one. That's a deliberate choice --
"small and incremental" means don't front-load every enterprise-grade control as if it's
required from the first deployment. Patterns in this doc set that scale up (the full
four-layer RBAC hierarchy, multi-cluster warehouses, Horizon Catalog) are noted with an
on-ramp where it matters -- what Harborline starts with vs. what it grows into as the
platform matures.

Harborline anchors Phase 1 and Phase 2 (GenAI/Cortex narrowing). Phase 3 introduces a
separate fictional company when it picks up the fin data warehouse variant, rather than
stretching Harborline into a domain it was never meant to represent -- the same pattern used
elsewhere for scenario-specific fictional companies.

Docs 01-04 each carry a "Harborline in practice" section grounding the general
principles in Harborline's actual setup -- its three warehouses, its RBAC roles, a couple of
its tables, its ingestion sources. Docs 05-07 (cost governance, open table formats,
cross-cloud resilience) don't yet, since Harborline hasn't grown into a second region or
adopted Iceberg tables in this narrative -- that's an open item for whenever those sections
have something concrete to hang an example on, not an oversight.

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

- Network policies / row-column security depth not fully scoped yet -- the one remaining
  Phase 1 gap, left flagged rather than guessed at.
- Iceberg/Polaris and Horizon Catalog Terraform resource coverage not yet researched --
  only matters once those sections get Terraform of their own.
