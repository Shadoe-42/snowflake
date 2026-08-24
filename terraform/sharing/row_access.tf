# Per-consumer scoping on shared data, corrected to match Snowflake's actual documented
# mechanism (verified against docs.snowflake.com/en/user-guide/data-sharing-policy-protected-data
# after an earlier draft of this module used CURRENT_ACCOUNT() -- that is not how this
# works). The real pattern: grant a distinct database role to each consumer through the
# share, and have the row access policy check IS_DATABASE_ROLE_IN_SESSION() against it --
# not account identity. One share, multiple database roles granted to it, multiple
# visibility levels.
#
# LANTERNES_DBROLE_PARTNER_ACME illustrates the per-partner shape: in reality, Lanternes
# would create one such database role per onboarded merchant partner, following this same
# pattern, and grant it to that partner's consumer account via the share. Only one is built
# here to demonstrate the mechanism, not to enumerate real partners.

resource "snowflake_database_role" "partner_acme" {
  database = var.snowflake_database
  name     = upper("${var.org_prefix}_dbrole_partner_acme")
  comment  = "Illustrative per-partner database role -- one of these per onboarded merchant partner in a real deployment."
}

resource "snowflake_grant_database_role" "partner_acme_to_share" {
  database_role_name = snowflake_database_role.partner_acme.fully_qualified_name
  share_name         = snowflake_share.merchant_insights.fully_qualified_name
}

# Internal analyst database role -- full visibility, never granted to a share. Not wired to
# any account role or user here: Lanternes' broader RBAC (the terraform/core equivalent
# Harborline has) wasn't built for this phase, per docs/fin-warehouse/00-overview.md's
# scoping note. This resource exists so the row access policy below has something real to
# reference instead of a functional role this repo never creates -- grant it to whatever
# internal account role Lanternes ends up building, once that layer exists.

resource "snowflake_database_role" "internal_analyst" {
  database = var.snowflake_database
  name     = upper("${var.org_prefix}_dbrole_internal_analyst")
  comment  = "Full visibility across all merchants -- for internal Lanternes analysts, not granted to any share."
}

# MERCHANT_ENTITLEMENTS maps which merchant(s) a given partner database role is entitled to
# see. Illustrative, not created by this module -- same scoping choice as TRANSACTIONS.

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
      WHERE e.MERCHANT_ID = MERCHANT_ID
        AND IS_DATABASE_ROLE_IN_SESSION(e.DATABASE_ROLE_NAME)
    )
    OR IS_DATABASE_ROLE_IN_SESSION('${snowflake_database_role.internal_analyst.name}')
  SQL

  comment = "Scopes MERCHANT_ID visibility by active database role (IS_DATABASE_ROLE_IN_SESSION), not account identity -- see docs/sharing/sharing-clean-rooms.md for why."
}
