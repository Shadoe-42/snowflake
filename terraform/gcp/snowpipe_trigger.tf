# See docs/integrations/csp-crosswalk.md "Snowpipe auto-ingest triggers: SQS/SNS vs.
# Pub/Sub" -- GCP has one auto-ingest path (there's no direct-queue-to-Snowflake shortcut
# the way AWS's SQS path avoids a notification integration): GCS bucket notifications ->
# Pub/Sub topic -> a Snowflake-owned subscription pulled via a notification integration.
# That notification integration is why `snowflake_pipe.integration` is set below, unlike
# the AWS module.

data "google_storage_project_service_account" "gcs_sa" {
  project = var.gcp_project
}

resource "google_pubsub_topic" "raw_landing_events" {
  name = "${var.org_prefix}-raw-landing-events"
}

# GCS publishes bucket notifications as the project's own Cloud Storage service agent, not
# as a user-managed identity -- it needs publish rights on the topic before the
# notification will actually deliver anything.
resource "google_pubsub_topic_iam_member" "gcs_publishes" {
  topic  = google_pubsub_topic.raw_landing_events.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${data.google_storage_project_service_account.gcs_sa.email_address}"
}

resource "google_storage_notification" "raw_landing_to_topic" {
  bucket         = google_storage_bucket.raw_landing.name
  topic          = google_pubsub_topic.raw_landing_events.id
  payload_format = "JSON_API_V1"
  event_types    = ["OBJECT_FINALIZE"]

  depends_on = [google_pubsub_topic_iam_member.gcs_publishes]
}

resource "google_pubsub_subscription" "snowflake_pull" {
  name  = "${var.org_prefix}-raw-landing-snowpipe-sub"
  topic = google_pubsub_topic.raw_landing_events.name

  # Snowflake pulls this subscription itself; it doesn't need push delivery or ordering.
  ack_deadline_seconds = 60
}

resource "snowflake_notification_integration" "gcs_pubsub" {
  name                  = upper("${var.org_prefix}_notification_integration_gcs")
  enabled               = true
  notification_provider = "GCP_PUBSUB"

  gcp_pubsub_subscription_name = "projects/${var.gcp_project}/subscriptions/${google_pubsub_subscription.snowflake_pull.name}"

  comment = "Notification integration wiring the raw landing subscription to Snowpipe auto-ingest."
}

# Snowflake's generated Pub/Sub service account (from this integration) is the identity
# that actually pulls the subscription -- grant it subscriber rights, same pattern as
# granting the GCS storage integration's service account read access to the bucket.
resource "google_pubsub_subscription_iam_member" "snowflake_subscribes" {
  subscription = google_pubsub_subscription.snowflake_pull.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${snowflake_notification_integration.gcs_pubsub.gcp_pubsub_service_account}"
}

resource "snowflake_stage_external_gcs" "raw_landing" {
  database = var.snowflake_database
  schema   = var.snowflake_schema
  name     = upper("${var.org_prefix}_stage_raw_landing")

  url                 = "gcs://${google_storage_bucket.raw_landing.name}/"
  storage_integration = snowflake_storage_integration_gcs.gcs.name
  comment             = "External stage over Harborline's raw landing bucket (GCS)."
}

resource "snowflake_pipe" "raw_ingest" {
  database = var.snowflake_database
  schema   = var.snowflake_schema
  name     = upper("${var.org_prefix}_pipe_raw_ingest")

  auto_ingest = true
  integration = snowflake_notification_integration.gcs_pubsub.name

  # Same caveat as the AWS module: RAW_LANDING's DDL is out of scope here, this
  # copy_statement is illustrative of the pipe wiring only.
  copy_statement = "COPY INTO ${var.snowflake_database}.${var.snowflake_schema}.RAW_LANDING FROM @${snowflake_stage_external_gcs.raw_landing.name} FILE_FORMAT = (TYPE = 'JSON')"

  comment = "Auto-ingest pipe watching the Harborline raw landing bucket via GCS notification -> Pub/Sub -> notification integration."
}
