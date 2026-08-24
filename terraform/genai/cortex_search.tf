# Cortex Search over Harborline's carrier documents -- contracts, incident reports, SOPs.
# Getting that text into a queryable column in the first place (scanned/handwritten source
# PDFs -> structured text) is exactly the Document AI use case flagged as out of scope in
# docs/genai/00-overview.md -- this service assumes CARRIER_DOCUMENTS already exists with a
# text column, however it got there. Not created by this module.

resource "snowflake_cortex_search_service" "carrier_docs" {
  database = var.snowflake_database
  schema   = var.snowflake_schema
  name     = upper("${var.org_prefix}_search_carrier_docs")

  on         = "BODY_TEXT"
  attributes = ["CATEGORY"]

  query = <<-SQL
    SELECT DOC_ID, TITLE, CATEGORY, BODY_TEXT
    FROM ${var.snowflake_database}.${var.snowflake_schema}.CARRIER_DOCUMENTS
  SQL

  target_lag = "1 day"
  warehouse  = var.search_warehouse

  # Default embedding model, named explicitly rather than left to fall back silently --
  # snowflake-arctic-embed-l-v2.0 is the higher-quality/higher-cost alternative, worth
  # revisiting once there's a real query-quality signal to justify the tradeoff.
  embedding_model = "snowflake-arctic-embed-m-v1.5"

  comment = "Hybrid semantic + keyword search over Harborline carrier contracts, incident reports, and SOPs."
}
