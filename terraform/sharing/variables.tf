variable "org_prefix" {
  description = "Short prefix applied to created resource names (e.g. \"lanternes\")."
  type        = string
  default     = "lanternes"
}

variable "snowflake_database" {
  description = "Database the tag, policies, secure view, and share are created in."
  type        = string
  default     = "LANTERNES"
}

variable "snowflake_schema" {
  description = "Schema the tag, policies, and secure view are created in -- ANALYTICS, same convention as terraform/genai and terraform/core."
  type        = string
  default     = "ANALYTICS"
}

variable "min_aggregation_cell_size" {
  description = "Minimum row count a merchant/MCC/day/geography cell must have before it's included in the shared view. Basic small-cell suppression against re-identification from low-volume cells (e.g. a single-transaction day for a small merchant leaking that transaction's amount) -- not a formal differential-privacy guarantee, and the specific threshold is illustrative, not derived from any rigorous privacy analysis. See docs/sharing/sharing-clean-rooms.md."
  type        = number
  default     = 10
}
