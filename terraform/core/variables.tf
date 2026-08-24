variable "org_prefix" {
  description = "Short prefix applied to every object name in this module. Keeps names collision-free across environments sharing one Snowflake account."
  type        = string
  default     = "harborline"
}

variable "warehouse_auto_suspend_seconds" {
  description = "Auto-suspend threshold in seconds for every warehouse this module creates. See docs/architecture/01-account-warehouse.md for why this should never be disabled."
  type        = number
  default     = 60
}

variable "elt_warehouse_size" {
  description = "Warehouse size for the ELT/transform warehouse."
  type        = string
  default     = "SMALL"
}

variable "bi_warehouse_size" {
  description = "Warehouse size for the BI/dashboard warehouse."
  type        = string
  default     = "SMALL"
}

variable "data_science_warehouse_size" {
  description = "Warehouse size for the data science / notebook warehouse."
  type        = string
  default     = "MEDIUM"
}

variable "monthly_credit_quota" {
  description = "Monthly credit quota for the account-wide resource monitor. Calibrated to Harborline's scale, not an enterprise/hyperscale default -- see docs/architecture/05-cost-governance.md."
  type        = number
  default     = 1000
}

variable "resource_monitor_notify_users" {
  description = "Snowflake usernames to notify as the resource monitor approaches its quota."
  type        = list(string)
  default     = []
}
