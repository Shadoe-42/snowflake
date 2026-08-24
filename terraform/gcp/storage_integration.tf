# See docs/integrations/csp-crosswalk.md "Storage integration: S3 + IAM role vs. GCS +
# service account" -- unlike the AWS side, GCP has no circular trust-policy dependency to
# work around. Snowflake generates its own service account when the storage integration is
# created, and that identity is granted access to the bucket in a single apply.

resource "google_storage_bucket" "raw_landing" {
  name     = "${var.org_prefix}-raw-landing-${var.gcp_project}"
  location = var.gcp_region

  uniform_bucket_level_access = true
  force_destroy               = false

  versioning {
    enabled = true
  }
}

resource "snowflake_storage_integration_gcs" "gcs" {
  name    = upper("${var.org_prefix}_storage_integration_gcs")
  enabled = true

  storage_allowed_locations = ["gcs://${google_storage_bucket.raw_landing.name}/"]

  comment = "GCS storage integration for Harborline's raw landing bucket."
}

# Snowflake's generated service account (from describe_output) is the identity that needs
# read access to the bucket -- this is the GCS equivalent of granting the AWS IAM role
# access to the S3 bucket.
resource "google_storage_bucket_iam_member" "snowflake_read" {
  bucket = google_storage_bucket.raw_landing.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${snowflake_storage_integration_gcs.gcs.describe_output[0].service_account}"
}

output "storage_integration_service_account" {
  value       = snowflake_storage_integration_gcs.gcs.describe_output[0].service_account
  description = "Snowflake-generated service account for the GCS storage integration -- shown here for parity with the AWS module's two-phase-apply outputs, though GCS doesn't require a second apply."
}
