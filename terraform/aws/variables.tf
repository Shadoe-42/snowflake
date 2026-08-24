variable "org_prefix" {
  description = "Short prefix applied to every resource name in this module."
  type        = string
  default     = "harborline"
}

variable "aws_region" {
  description = "AWS region the landing bucket and its supporting resources live in."
  type        = string
  default     = "us-east-1"
}

variable "snowflake_database" {
  description = "Snowflake database the stage and pipe are created in -- matches the core module's docs/architecture-driven database, passed in rather than referenced directly so this module stays independently deployable. See docs/integrations/csp-crosswalk.md."
  type        = string
  default     = "HARBORLINE"
}

variable "snowflake_schema" {
  description = "Snowflake schema the stage and pipe are created in."
  type        = string
  default     = "RAW"
}

# --- Two-phase trust policy variables ---
# CREATE STORAGE INTEGRATION and the IAM role's trust policy have a circular dependency in
# principle: the role needs to trust the IAM user Snowflake generates, but that identity
# doesn't exist until the integration itself is created. Snowflake's own docs resolve this
# with a manual two-step process (create with a placeholder, then update the trust policy).
# This module captures the same two-phase reality as Terraform variables instead of manual
# console clicks -- see README.md for the exact apply sequence.

variable "snowflake_iam_user_arn" {
  description = "The IAM user ARN Snowflake generated for this storage integration (from this module's `storage_integration_iam_user_arn` output, after a first apply). Placeholder default until then -- the trust policy isn't real until this is supplied."
  type        = string
  default     = "arn:aws:iam::000000000000:root"
}

variable "snowflake_external_id" {
  description = "The external ID Snowflake generated for this storage integration (from this module's `storage_integration_external_id` output, after a first apply). Same two-phase caveat as snowflake_iam_user_arn."
  type        = string
  default     = "placeholder-external-id"
}
