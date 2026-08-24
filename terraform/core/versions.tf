terraform {
  required_version = ">= 1.5.0"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.20"
    }
  }
}

# Authenticates via SNOWFLAKE_* environment variables (account identifier, user, private key,
# role) -- see README.md. Nothing account-specific is hardcoded in this module.
provider "snowflake" {}
