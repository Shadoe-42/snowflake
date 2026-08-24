# The object actually exposed to a share consumer is this secure, pre-aggregated view --
# never the base TRANSACTIONS table, and never a per-cardholder row. Aggregation to
# merchant/MCC/day is the privacy boundary itself, not a policy layered on top of raw data:
# there is no cardholder-level join surface here for a consumer to reach even if every
# policy below were misconfigured. The row access policy is still attached as defense in
# depth, scoping which MERCHANT_ID rows a given consumer's aggregates cover.

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
  SQL

  row_access_policy {
    policy_name = snowflake_row_access_policy.merchant_partner_scope.fully_qualified_name
    on          = ["MERCHANT_ID"]
  }

  comment = "Pre-aggregated, merchant/MCC/day-level purchase insights -- no cardholder-level data reachable through this view."
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
