# Account-wide cost backstop. See docs/architecture/05-cost-governance.md -- this exists
# alongside warehouse-level auto-suspend/resume, not instead of it.
resource "snowflake_resource_monitor" "account" {
  name            = upper("${var.org_prefix}_rm_account")
  credit_quota    = var.monthly_credit_quota
  frequency       = "MONTHLY"
  start_timestamp = "IMMEDIATELY"

  notify_triggers           = [75, 90]
  suspend_trigger           = 100
  suspend_immediate_trigger = 110

  notify_users = var.resource_monitor_notify_users
}
