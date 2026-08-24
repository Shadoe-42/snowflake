variable "org_prefix" {
  description = "Short prefix applied to created resource names (e.g. \"harborline\")."
  type        = string
  default     = "harborline"
}

variable "gcp_project" {
  description = "GCP project ID that owns the landing bucket, Pub/Sub topic, and subscription."
  type        = string
}

variable "gcp_region" {
  description = "GCP region for the landing bucket and Pub/Sub resources."
  type        = string
  default     = "us-central1"
}

variable "snowflake_database" {
  description = "Snowflake database the stage and pipe are created in. Passed in independently of terraform/core so this module can be applied on its own."
  type        = string
}

variable "snowflake_schema" {
  description = "Snowflake schema the stage and pipe are created in."
  type        = string
}
