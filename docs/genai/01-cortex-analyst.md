# Cortex Analyst

Status: draft (full prose, 2026-08-24)

Cortex Analyst turns a natural-language question into a governed SQL query and runs it --
"how many shipments from the Denver facility were delayed last week" becomes a `SELECT`
against real Harborline data, not a hallucinated summary. It's a text-to-SQL engine, not a
chat model with the data pasted into its context: the SQL it generates actually executes,
against a real warehouse, under the caller's real privileges.

## Semantic views, not the legacy YAML

Cortex Analyst has always needed a semantic model to ground it -- a definition of what
tables, columns, and business terms mean, so "delayed" maps to an actual `STATUS_CODE`
value instead of the model guessing. The original mechanism was a YAML file uploaded to a
stage. Snowflake now recommends native SQL semantic views (`CREATE SEMANTIC VIEW`) instead,
and that's the approach this repo uses -- `terraform/genai/semantic_view.tf` defines one as
a real Terraform resource (`snowflake_semantic_view`), version-controlled and reviewable the
same way any other schema object in this repo is, rather than a YAML blob living outside
normal change management. The legacy YAML path still works and still has its place for
teams already invested in it, but there's no reason to start there in 2026.

A semantic view layers meaning on top of existing tables without duplicating any data: it
declares logical tables (an alias over a real table, with its primary key), facts (a raw
per-row value, like a shipment's weight), dimensions (a value to group or filter by, like
origin facility or status), and metrics (an aggregation, like total shipment count).
Synonyms attached to each let "weight" and "shipment weight" resolve to the same fact, which
matters more than it sounds like it should -- most of what makes a semantic view usable is
give it enough vocabulary that a dispatcher's actual phrasing lands on the right column.

## Harborline's semantic view

`terraform/genai/semantic_view.tf` builds one over the same illustrative `SHIPMENTS` table
introduced in `docs/architecture/03-data-modeling.md`: a logical table aliased `shipments`,
two facts (`total_weight_lbs`), three dimensions (`ship_date`, `origin_facility`, `status`),
and two metrics (`total_shipments`, `total_weight_shipped_lbs`). It's intentionally small --
enough to answer real dispatcher questions, not an attempt to model Harborline's entire
schema in one pass. `SHIPMENTS` itself isn't created by this module, the same scoping
decision made for `RAW_LANDING` in Phase 1's ingestion Terraform: the semantic view's shape
is real, the underlying table is illustrative until Harborline's actual data model exists.

## Access and cost

Cortex Analyst doesn't introduce a new privilege model -- it runs the SQL it generates
under the caller's existing roles, so a user needs `SELECT` on whatever the semantic view
references (here, `ANALYTICS.SHIPMENTS`, already covered by `HARBORLINE_AR_ANALYTICS_SELECT`
via `HARBORLINE_FR_ANALYST`) and `USAGE` on the semantic view itself. The query executes
against a real warehouse -- `terraform/genai/variables.tf` defaults that to
`HARBORLINE_WH_BI`, the same warehouse human dashboard queries already use. Natural-language
Q&A is an additional access pattern on governed data Harborline already has, not a new data
platform layered on top of it -- the RBAC and warehouse discipline from
`docs/architecture/01-account-warehouse.md` and `docs/architecture/02-security-governance-rbac.md`
carries forward unchanged.

## Sources

- Cortex Analyst -- Snowflake Docs: https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst
- Version Control for Snowflake Semantic Views with Terraform -- Snowflake Engineering
  Blog: https://www.snowflake.com/en/blog/engineering/version-control-semantic-views/
