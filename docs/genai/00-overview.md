# GenAI / Cortex Overview

Status: draft (full prose, 2026-09-01)

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

## Business case: why Cortex, not a standalone agent platform

Worth answering directly rather than leaving implicit: Harborline is not standing up a
separate agent platform for this use case, and that is a build-versus-buy decision, not an
oversight. Cortex Analyst, Search, and Agents run inside Snowflake, against data already
under Snowflake's governed access model -- no new runtime to provision, no separate identity
system to wire up, no data leaving the platform Harborline already trusts for shipment
records in order to reach an agent. A platform like Google Cloud's Gemini Enterprise Agent
Platform or IBM's watsonx.governance-orchestrated agents would mean adopting a genuinely
separate agent platform, plus the governance apparatus that platform requires to run
responsibly -- covered in real depth in a companion reference repo,
`ai_agent_governance_patterns` (see `docs/genai/04-cortex-governance.md`). That apparatus
earns its cost at the AI-adoption stages where agents take actions with real financial or
operational consequences across multiple systems. Harborline's dispatch assistant does not
reach that bar -- it answers questions against data it already has governed access to, and
stops there. The right call at Harborline's actual stage is to use the platform-native
capability already inside the data platform, not to build or adopt a second one the use case
does not yet justify.

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
4. cortex-governance -- where Harborline's agent sits on an AI-adoption maturity model, what
   Cortex governs natively versus what a dedicated agent-governance platform would add

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
- `ai_agent_governance_patterns` -- https://github.com/Shadoe-42/ai_agent_governance_patterns
  -- companion repo, source of the AI-adoption maturity framing used in
  `docs/genai/04-cortex-governance.md`.
