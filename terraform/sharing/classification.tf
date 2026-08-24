# Tag-driven classification, same Horizon Catalog pattern documented in
# docs/architecture/02-security-governance-rbac.md: tag the sensitive column once, let
# policy attach to the tag rather than being configured per-object. This is the first link
# in the chain that ends at the share -- see docs/sharing/sharing-clean-rooms.md for the
# full walkthrough.
#
# Assumes an illustrative TRANSACTIONS table (TRANSACTION_ID, CARD_TOKEN, MERCHANT_ID, MCC,
# AMOUNT, TXN_TIMESTAMP, TXN_GEOGRAPHY) already exists in this schema, not created by this
# module -- same scoping choice as SHIPMENTS in terraform/genai and RAW_LANDING in
# terraform/aws. CARD_TOKEN is a tokenized reference, not a raw card number -- tokenization
# happens upstream of Snowflake, in the payment processing path itself, not documented here.

resource "snowflake_tag" "data_classification" {
  database = var.snowflake_database
  schema   = var.snowflake_schema
  name     = upper("${var.org_prefix}_tag_data_classification")
  comment  = "Data classification for privacy-sensitive columns -- drives masking and row access policy application."

  ordered_allowed_values = ["cardholder_data", "aggregated", "public"]
}

resource "snowflake_tag_association" "card_token_classification" {
  object_type        = "COLUMN"
  object_identifiers = ["\"${var.snowflake_database}\".\"${var.snowflake_schema}\".\"TRANSACTIONS\".\"CARD_TOKEN\""]
  tag_id             = snowflake_tag.data_classification.fully_qualified_name
  tag_value          = "cardholder_data"
}
