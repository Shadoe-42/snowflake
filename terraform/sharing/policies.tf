# Masking policy: internal analysts see the real token, everyone else (including any role
# a share consumer could ever run under) sees a redacted form. CARD_TOKEN is already
# tokenized before it lands here, but redaction on top of tokenization costs nothing and
# means a masking policy misconfiguration doesn't become a cardholder-data exposure.

resource "snowflake_masking_policy" "card_token_mask" {
  database = var.snowflake_database
  schema   = var.snowflake_schema
  name     = upper("${var.org_prefix}_mask_card_token")

  argument {
    name = "VAL"
    type = "VARCHAR"
  }
  return_data_type = "VARCHAR"

  body = <<-SQL
    CASE
      WHEN CURRENT_ROLE() IN ('${upper(var.org_prefix)}_FR_ANALYST') THEN VAL
      ELSE '****' || RIGHT(VAL, 4)
    END
  SQL

  comment = "Redacts CARD_TOKEN to its last 4 characters for any role other than the internal analyst role."
}

# Row access policy: scopes which MERCHANT_ID rows are visible to a given caller, driven by
# an illustrative MERCHANT_ENTITLEMENTS mapping table (also not created by this module) that
# records which merchant a given consumer account is entitled to see. This is what makes a
# per-merchant share possible without a separate secure view per merchant.

resource "snowflake_row_access_policy" "merchant_partner_scope" {
  database = var.snowflake_database
  schema   = var.snowflake_schema
  name     = upper("${var.org_prefix}_rap_merchant_partner_scope")

  argument {
    name = "MERCHANT_ID"
    type = "VARCHAR"
  }

  body = <<-SQL
    EXISTS (
      SELECT 1
      FROM ${var.snowflake_database}.${var.snowflake_schema}.MERCHANT_ENTITLEMENTS e
      WHERE e.CONSUMER_ACCOUNT_LOCATOR = CURRENT_ACCOUNT()
        AND e.MERCHANT_ID = MERCHANT_ID
    )
    OR CURRENT_ROLE() = '${upper(var.org_prefix)}_FR_ANALYST'
  SQL

  comment = "Limits a share consumer to only the merchant(s) they're entitled to see; internal analysts see all rows."
}
