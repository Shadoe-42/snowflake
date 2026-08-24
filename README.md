# Snowflake Reference Architecture

Learning + reference-architecture project: modern Snowflake patterns, documented and backed
by Terraform, built incrementally.

## Roadmap

- **Phase 1 -- General architecture (in progress).** Broad "does it all" foundation: account/
  warehouse design, security & governance, data modeling, ingestion patterns, cost
  governance. Deliberately domain-agnostic -- no fake business scenario forced onto it.
- **Phase 2 -- GenAI/Cortex narrowing (not started).** Branches from Phase 1 into Cortex AI,
  LLM Functions, RAG, Snowflake ML.
- **Phase 3 -- Fin data warehouse variant (not started).** Branches from Phase 1 into a
  financial-services domain example; also where the Sharing & Data Clean Rooms doc lives.

## Layout

- docs/architecture/  -- the core reference architecture, one file per topic.
- docs/integrations/  -- CSP-specific mechanics (AWS vs. GCP) kept separate from the
  cloud-neutral core.
- docs/sharing/       -- Secure Data Sharing & Data Clean Rooms (Phase 3-linked).
- terraform/          -- not started yet; sequencing (build alongside docs vs. second pass)
  still an open decision.
- examples/           -- illustrative objects/SQL once the architecture docs are stable
  enough to demonstrate concretely.

## Source material

Vendor white papers and other reference docs live in the sibling snowflake_docs/ directory,
not in this repo -- this repo is what we build, not what we collect.

## Status

Draft. Architecture docs seeded from research (see each doc's own status line); Terraform,
examples, and the integration/sharing docs are placeholders pending their own research passes.
