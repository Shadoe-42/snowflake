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

variable "analyst_warehouse" {
  description = "Warehouse Cortex Analyst's generated SQL runs against. Defaults to the same HARBORLINE_WH_BI used by human BI/dashboard queries in terraform/core -- natural-language Q&A is an additional access pattern on the same warehouse, not a new one."
  type        = string
  default     = "HARBORLINE_WH_BI"
}

variable "search_warehouse" {
  description = "Warehouse that (re)indexes the Cortex Search service on its target_lag schedule."
  type        = string
  default     = "HARBORLINE_WH_BI"
}
