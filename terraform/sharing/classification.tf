# Tag-driven classification, same Horizon Catalog pattern documented in
# docs/architecture/02-security-governance-rbac.md: tag the sensitive column once, let
# policy attach to the tag rather than being configured per-object. Both values declared
# here are actually used below -- CARD_TOKEN as cardholder_data, the secure view itself as
# aggregated -- rather than a wider enum left partly decorative.
#
# Assumes an illustrative TRANSACTIONS table (TRANSACTION_ID, CARD_TOKEN, MERCHANT_ID, MCC,
# AMOUNT, TXN_TIMESTAMP, TXN_GEOGRAPHY) already exists in this schema, not created by this
# module -- same scoping choice as SHIPMENTS in terraform/genai and RAW_LANDING in
# terraform/aws. CARD_TOKEN is a tokenized reference, not a raw card number -- tokenization
# happens upstream in the payment processing path, out of scope here.

resource "snowflake_tag" "data_classification" {
  database = var.snowflake_database
  schema   = var.snowflake_schema
  name     = upper("${var.org_prefix}_tag_data_classification")
  comment  = "Data classification for privacy-sensitive and derived objects -- drives row access policy application, not masking (see terraform/README.md for why this module has no masking policy)."

  ordered_allowed_values = ["cardholder_data", "aggregated"]
}

resource "snowflake_tag_association" "card_token_classification" {
  object_type        = "COLUMN"
  object_identifiers = ["\"${var.snowflake_database}\".\"${var.snowflake_schema}\".\"TRANSACTIONS\".\"CARD_TOKEN\""]
  tag_id             = snowflake_tag.data_classification.fully_qualified_name
  tag_value          = "cardholder_data"
}

resource "snowflake_tag_association" "merchant_insights_classification" {
  object_type        = "VIEW"
  object_identifiers = ["\"${var.snowflake_database}\".\"${var.snowflake_schema}\".\"${snowflake_view.merchant_insights.name}\""]
  tag_id             = snowflake_tag.data_classification.fully_qualified_name
  tag_value          = "aggregated"
}
