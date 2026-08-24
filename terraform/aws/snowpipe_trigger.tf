# See docs/integrations/csp-crosswalk.md "Snowpipe auto-ingest triggers: SQS/SNS vs.
# Pub/Sub" -- this implements the simpler of the two documented AWS paths: direct S3-to-SQS,
# with Snowflake managing the SQS queue itself (no aws_sqs_queue resource needed here). The
# SNS fan-out variant is documented but not built -- Harborline doesn't yet have another
# system that needs to react to the same S3 events, so the extra broadcast layer isn't
# earning its complexity yet.

resource "snowflake_stage_external_s3" "raw_landing" {
  database = var.snowflake_database
  schema   = var.snowflake_schema
  name     = upper("${var.org_prefix}_stage_raw_landing")

  url                 = "s3://${aws_s3_bucket.raw_landing.bucket}/"
  storage_integration = snowflake_storage_integration_aws.s3.name
  comment             = "External stage over Harborline's raw landing bucket."
}

resource "snowflake_pipe" "raw_ingest" {
  database = var.snowflake_database
  schema   = var.snowflake_schema
  name     = upper("${var.org_prefix}_pipe_raw_ingest")

  auto_ingest = true

  # No `integration` argument here -- that field wires a *notification* integration, which
  # this simple direct S3-to-SQS path doesn't use (it's needed for the SNS fan-out variant,
  # and required on GCP/Azure). Snowflake infers everything it needs for this path from the
  # stage's own storage_integration above.

  # The target table's own DDL is intentionally out of scope for this crosswalk module --
  # it belongs with concrete examples/ once Harborline's data model exists. This
  # copy_statement is illustrative of the pipe wiring, not a claim that RAW_LANDING exists
  # yet.
  copy_statement = "COPY INTO ${var.snowflake_database}.${var.snowflake_schema}.RAW_LANDING FROM @${snowflake_stage_external_s3.raw_landing.name} FILE_FORMAT = (TYPE = 'JSON')"

  comment = "Auto-ingest pipe watching the Harborline raw landing bucket via direct S3-to-SQS (Snowflake-managed queue)."
}

resource "aws_s3_bucket_notification" "raw_landing_to_snowpipe" {
  bucket = aws_s3_bucket.raw_landing.id

  queue {
    queue_arn = snowflake_pipe.raw_ingest.notification_channel
    events    = ["s3:ObjectCreated:*"]
  }
}
