# The object actually exposed to a share consumer is this secure, pre-aggregated view --
# never the base TRANSACTIONS table, and never a per-cardholder row. Aggregation to
# merchant/MCC/day is the privacy boundary itself, not a policy layered on top of raw data:
# there is no cardholder-level join surface here for a consumer to reach even if every
# policy below were misconfigured. The HAVING clause is basic small-cell suppression --
# aggregation alone doesn't prevent a low-volume cell (a single-transaction day for a small
# merchant) from leaking that transaction's amount; this isn't a rigorous privacy guarantee,
# just a floor. The row access policy is attached as a second, independent control, scoping
# which MERCHANT_ID rows a given consumer's aggregates cover by their granted database role
# (see row_access.tf) -- not the same thing as the aggregation boundary, and not a
# substitute for it.

resource "snowflake_view" "merchant_insights" {
  database  = var.snowflake_database
  schema    = var.snowflake_schema
  name      = upper("${var.org_prefix}_v_merchant_insights")
  is_secure = "true"

  statement = <<-SQL
    SELECT
      MERCHANT_ID,
      MCC,
      DATE_TRUNC('DAY', TXN_TIMESTAMP) AS TXN_DATE,
      TXN_GEOGRAPHY,
      COUNT(*) AS TRANSACTION_COUNT,
      SUM(AMOUNT) AS TOTAL_AMOUNT
    FROM ${var.snowflake_database}.${var.snowflake_schema}.TRANSACTIONS
    GROUP BY MERCHANT_ID, MCC, DATE_TRUNC('DAY', TXN_TIMESTAMP), TXN_GEOGRAPHY
    HAVING COUNT(*) >= ${var.min_aggregation_cell_size}
  SQL

  row_access_policy {
    policy_name = snowflake_row_access_policy.merchant_partner_scope.fully_qualified_name
    on          = ["MERCHANT_ID"]
  }

  comment = "Pre-aggregated, merchant/MCC/day-level purchase insights with small-cell suppression -- no cardholder-level data reachable through this view."
}

resource "snowflake_share" "merchant_insights" {
  name    = upper("${var.org_prefix}_share_merchant_insights")
  comment = "Shares aggregated purchase-behavior insights with a merchant/advertiser partner -- never raw transactions."
}

resource "snowflake_grant_privileges_to_share" "database_usage" {
  to_share    = snowflake_share.merchant_insights.name
  privileges  = ["USAGE"]
  on_database = var.snowflake_database
}

resource "snowflake_grant_privileges_to_share" "schema_usage" {
  to_share   = snowflake_share.merchant_insights.name
  privileges = ["USAGE"]
  on_schema  = "${var.snowflake_database}.${var.snowflake_schema}"
}

resource "snowflake_grant_privileges_to_share" "view_select" {
  to_share   = snowflake_share.merchant_insights.name
  privileges = ["SELECT"]
  on_view    = "${var.snowflake_database}.${var.snowflake_schema}.${snowflake_view.merchant_insights.name}"
}
