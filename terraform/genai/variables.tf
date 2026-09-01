variable "org_prefix" {
  description = "Short prefix applied to created resource names (e.g. \"harborline\")."
  type        = string
  default     = "harborline"
}

variable "snowflake_database" {
  description = "Database the semantic view, search service, and agent are created in. Matches terraform/core's HARBORLINE database, passed in independently rather than referenced -- this module doesn't couple to terraform/core via Terraform state, only by convention."
  type        = string
  default     = "HARBORLINE"
}

variable "snowflake_schema" {
  description = "Schema the semantic view and search service are created in -- ANALYTICS, since both sit on top of already-governed, query-ready data, not RAW."
  type        = string
  default     = "ANALYTICS"
}

# No analyst_warehouse variable here. An earlier draft declared one, described as the
# warehouse Cortex Analyst's generated SQL runs against -- but snowflake_semantic_view has
# no warehouse attribute (confirmed against the live provider schema), and the variable was
# never referenced by any resource in this module. Caught during an adversarial
# self-review: docs/genai/01-cortex-analyst.md repeated the false claim as fact. Removed
# rather than wired to something that doesn't exist -- Cortex Analyst's generated SQL runs
# under the caller's session, on whatever warehouse that role already has USAGE on
# (HARBORLINE_WH_BI for HARBORLINE_FR_ANALYST, granted in terraform/core/rbac.tf). That is
# an RBAC/session property, not something this module configures.

variable "search_warehouse" {
  description = "Warehouse that (re)indexes the Cortex Search service on its target_lag schedule."
  type        = string
  default     = "HARBORLINE_WH_BI"
}
