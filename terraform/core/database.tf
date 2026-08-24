# A single database as Harborline's landing/transform surface. RAW is where ingestion
# patterns (docs/architecture/04-ingestion-patterns.md) land data; ANALYTICS is what the BI
# and data science warehouses actually query. This intentionally does not attempt full data
# modeling (docs/architecture/03-data-modeling.md) -- clustering keys, if any, get added to
# real tables once Harborline's examples exist, not speculatively here.

resource "snowflake_database" "harborline" {
  name    = upper(var.org_prefix)
  comment = "Harborline Logistics primary database."
}

resource "snowflake_schema" "raw" {
  database = snowflake_database.harborline.name
  name     = "RAW"
  comment  = "Landing zone for ingested data before transformation."
}

resource "snowflake_schema" "analytics" {
  database = snowflake_database.harborline.name
  name     = "ANALYTICS"
  comment  = "Transformed, query-ready data."
}
