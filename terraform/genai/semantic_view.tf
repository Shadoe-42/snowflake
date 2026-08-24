# Cortex Analyst's recommended backing is a native SQL semantic view, not the legacy
# YAML-in-a-stage approach -- see docs/genai/01-cortex-analyst.md. This defines one over an
# illustrative SHIPMENTS table (the same illustrative table used in
# docs/architecture/03-data-modeling.md) so the semantic view's shape is grounded in
# something already documented, not invented fresh here.
#
# SHIPMENTS itself is not created by this module or by terraform/core -- same scoping
# choice as RAW_LANDING in terraform/aws/snowpipe_trigger.tf. This resource assumes the
# table already exists with the columns referenced below.

resource "snowflake_semantic_view" "shipments" {
  database = var.snowflake_database
  schema   = var.snowflake_schema
  name     = upper("${var.org_prefix}_sv_shipments")
  comment  = "Semantic layer over ANALYTICS.SHIPMENTS for Cortex Analyst natural-language queries."

  tables {
    table_name  = "\"${var.snowflake_database}\".\"${var.snowflake_schema}\".\"SHIPMENTS\""
    table_alias = "shipments"
    primary_key = ["\"SHIPMENT_ID\""]
    comment     = "One row per shipment."
  }

  facts {
    qualified_expression_name = "\"shipments\".\"total_weight_lbs\""
    sql_expression            = "WEIGHT_LBS"
    comment                   = "Shipment weight in pounds."
    synonym                   = ["weight", "shipment weight"]
  }

  dimensions {
    qualified_expression_name = "\"shipments\".\"ship_date\""
    sql_expression            = "SHIP_DATE"
    comment                   = "Date the shipment left its origin facility."
  }

  dimensions {
    qualified_expression_name = "\"shipments\".\"origin_facility\""
    sql_expression            = "ORIGIN_FACILITY_ID"
    comment                   = "Origin distribution center -- the same clustering-key column discussed in 03-data-modeling.md."
    synonym                   = ["origin", "origin dc", "distribution center"]
  }

  dimensions {
    qualified_expression_name = "\"shipments\".\"status\""
    sql_expression            = "STATUS_CODE"
    comment                   = "Current shipment status, e.g. IN_TRANSIT, DELIVERED, DELAYED."
  }

  metrics {
    semantic_expression {
      qualified_expression_name = "\"shipments\".\"total_shipments\""
      sql_expression            = "COUNT(*)"
      comment                   = "Total shipment count."
      synonym                   = ["shipment count", "number of shipments"]
    }
  }

  metrics {
    semantic_expression {
      qualified_expression_name = "\"shipments\".\"total_weight_shipped_lbs\""
      sql_expression            = "SUM(WEIGHT_LBS)"
      comment                   = "Total weight shipped, in pounds."
    }
  }
}
