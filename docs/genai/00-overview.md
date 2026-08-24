# GenAI / Cortex Overview

Status: draft (full prose, 2026-08-24)

Scope: Phase 2 narrows Phase 1's general Snowflake foundation into Harborline Logistics'
actual GenAI use case set, rather than surveying everything Cortex can do. "Small and
incremental" applies here exactly as it did in Phase 1: this is not an attempt to stand up
every AI capability Snowflake ships, it is the two or three that answer a real Harborline
need -- dispatchers asking questions about shipments in plain language, and finding the
right carrier SOP or incident report without grepping through a shared drive.

## What Phase 2 covers, and what it deliberately doesn't

This phase covers three capabilities that compose into one working system: Cortex Analyst
(natural-language questions answered against governed structured data), Cortex Search
(hybrid semantic and keyword search over unstructured text), and Cortex Agents
(orchestration that routes a question to whichever of the two actually answers it). All
three have real Terraform coverage in the pinned provider (`snowflakedb/snowflake` ~> 2.20)
-- see `terraform/genai/`.

Three adjacent capabilities were considered and left out, deliberately, not by oversight:

- **Document AI** (Arctic-TILT) is a strong fit for Harborline's actual paperwork --
  scanned or handwritten bills of lading, proof-of-delivery forms, maintenance logs are
  exactly the document class it's built for, per Snowflake's own DoD Document AI white
  paper (unstructured, form-heavy, exactly the maintenance-log example in that paper). It
  stays out of this phase because model training is a Snowsight UI workflow, not something
  this repo's Terraform-first approach captures well, and because Cortex Search in this
  phase assumes the text it indexes already exists in a table column -- Document AI is what
  would put it there. Worth a future pass once there's a concrete document set to point it
  at.
- **Cortex Functions** (`COMPLETE` and friends) are simple built-in SQL functions -- calling
  one is a one-line `SELECT`, not an architectural decision. Not enough surface area to
  justify a section of its own; used inline wherever a doc below needs one.
- **Snowflake ML** (feature store, model registry) ties naturally to the
  `HARBORLINE_WH_DATA_SCIENCE` warehouse and route-optimization notebooks already
  referenced in `docs/architecture/01-account-warehouse.md`, but it's managed through the
  Python API (`snowflake-ml-python`), not SQL or Terraform -- a different enough surface
  that it deserves its own pass rather than being squeezed into this one.

## Ground rules carried forward from Phase 1

Cortex is Snowflake-native compute -- there's no CSP divergence the way ingestion had one
in Phase 1, so the CSP-neutral framing doesn't apply here; nothing in this phase differs by
cloud. Vendor-material skepticism does carry forward, and applies with extra weight to one
source in particular: the Capgemini/Snowflake "agentic AI" white paper referenced below is
substantially product marketing for a third-party platform built on top of Snowflake, not
Snowflake's own technical documentation. It's useful for the Cortex Agents concept and for
one governance framing worth keeping (agents should be governed the way a new class of
workforce would be, not treated as a black box), but its benchmark numbers and ROI claims
are Capgemini's, not independently verified, and are not repeated as fact anywhere in this
doc set.

## Sections

1. cortex-analyst -- semantic views, natural-language-to-SQL over governed data
2. cortex-search -- hybrid search over unstructured text
3. cortex-agents -- orchestration, tool routing, agent security

## Open items

- Document AI, Cortex Functions, and Snowflake ML remain out of scope for this phase, per
  above -- not gaps, deliberate sequencing.
- No new RBAC layer built for Cortex Search's source table (`CARRIER_DOCUMENTS` doesn't
  exist yet, same scoping choice as `SHIPMENTS` in Phase 1) -- when it does, it needs its
  own Access Role in `terraform/core/rbac.tf`, not a bolt-on here.

## Sources

- Cortex Analyst -- Snowflake Docs: https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst
- Cortex Search Overview -- Snowflake Docs: https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-search/cortex-search-overview
- Cortex Agents -- Snowflake Docs: https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents
- CREATE AGENT -- Snowflake Docs: https://docs.snowflake.com/en/sql-reference/sql/create-agent
- "From prompt to purpose: Unlocking business value with agentic AI," Capgemini x
  Snowflake, 2025 (private research directory, not part of this repo) -- vendor/partner
  marketing material, treated as a capability pointer, not independent verification.
- "How the Department of Defense Can Leverage Snowflake Document AI to Support the DoD AI
  Records Strategy," Snowflake Inc., 2024 (private research directory, not part of this
  repo) -- Snowflake's own material, more substantive than the above, still a vendor
  document.
