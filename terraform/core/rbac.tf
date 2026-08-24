# Access Roles + Functional Roles only -- the scale on-ramp from
# docs/architecture/02-security-governance-rbac.md. Service Roles are deliberately not
# built yet: Harborline doesn't have multiple automated pipelines/tools that need isolated
# identities. Add that layer when it does, not preemptively.
#
# The rule that holds regardless of layer count: privileges go to roles, never to users.
# Every grant below targets an Access Role; every Access Role is only ever granted to a
# Functional Role, never directly to a person.

# --- Access Roles: atomic, one schema + one privilege each ---

resource "snowflake_account_role" "ar_raw_select" {
  name    = upper("${var.org_prefix}_ar_raw_select")
  comment = "Access Role: SELECT on all tables in RAW. Atomic -- holds exactly one privilege on exactly one schema."
}

resource "snowflake_grant_privileges_to_account_role" "ar_raw_select_grant" {
  account_role_name = snowflake_account_role.ar_raw_select.name
  privileges        = ["SELECT"]

  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = "${snowflake_database.harborline.name}.${snowflake_schema.raw.name}"
    }
  }
}

resource "snowflake_account_role" "ar_analytics_select" {
  name    = upper("${var.org_prefix}_ar_analytics_select")
  comment = "Access Role: SELECT on all tables in ANALYTICS."
}

resource "snowflake_grant_privileges_to_account_role" "ar_analytics_select_grant" {
  account_role_name = snowflake_account_role.ar_analytics_select.name
  privileges        = ["SELECT"]

  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = "${snowflake_database.harborline.name}.${snowflake_schema.analytics.name}"
    }
  }
}

resource "snowflake_account_role" "ar_raw_write" {
  name    = upper("${var.org_prefix}_ar_raw_write")
  comment = "Access Role: INSERT + UPDATE on all tables in RAW -- for ELT jobs landing data, not for interactive use."
}

resource "snowflake_grant_privileges_to_account_role" "ar_raw_write_grant" {
  account_role_name = snowflake_account_role.ar_raw_write.name
  privileges        = ["INSERT", "UPDATE"]

  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = "${snowflake_database.harborline.name}.${snowflake_schema.raw.name}"
    }
  }
}

# --- Functional Roles: bundle Access Roles, map to how Harborline actually organizes work ---
# These hold no direct object privileges of their own -- they only inherit from Access Roles.

resource "snowflake_account_role" "fr_analyst" {
  name    = upper("${var.org_prefix}_fr_analyst")
  comment = "Functional Role: read-only access to ANALYTICS. Granted to BI/reporting users."
}

resource "snowflake_grant_account_role" "fr_analyst_inherits_analytics_select" {
  role_name        = snowflake_account_role.ar_analytics_select.name
  parent_role_name = snowflake_account_role.fr_analyst.name
}

resource "snowflake_account_role" "fr_elt" {
  name    = upper("${var.org_prefix}_fr_elt")
  comment = "Functional Role: ELT pipeline access -- write to RAW, read ANALYTICS to validate transforms."
}

resource "snowflake_grant_account_role" "fr_elt_inherits_raw_write" {
  role_name        = snowflake_account_role.ar_raw_write.name
  parent_role_name = snowflake_account_role.fr_elt.name
}

resource "snowflake_grant_account_role" "fr_elt_inherits_raw_select" {
  role_name        = snowflake_account_role.ar_raw_select.name
  parent_role_name = snowflake_account_role.fr_elt.name
}

resource "snowflake_grant_account_role" "fr_elt_inherits_analytics_select" {
  role_name        = snowflake_account_role.ar_analytics_select.name
  parent_role_name = snowflake_account_role.fr_elt.name
}

# --- Warehouse USAGE: granted directly to Functional Roles (warehouses are account
#     objects, not schema objects -- this is the one privilege type that reasonably skips
#     the Access Role layer, since there's nothing more atomic to bundle). ---

resource "snowflake_grant_privileges_to_account_role" "fr_analyst_warehouse_usage" {
  account_role_name = snowflake_account_role.fr_analyst.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.bi.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_elt_warehouse_usage" {
  account_role_name = snowflake_account_role.fr_elt.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.elt.name
  }
}
