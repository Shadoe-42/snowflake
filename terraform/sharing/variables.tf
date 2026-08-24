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
