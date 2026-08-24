# CSP Integration Crosswalk (AWS vs. GCP)

Status: PLACEHOLDER -- not yet researched/drafted

Standalone integration reference, side by side by integration point. Not part of the
cloud-neutral core architecture docs -- this is where cloud specifics actually live.

Planned rows:

- **Storage integration** -- S3 bucket + IAM role/policy (AWS) vs. GCS bucket + service
  account (GCP): how Snowflake gets scoped, least-privilege access to external stages.
- **Snowpipe auto-ingest triggers** -- SQS/SNS event notifications (AWS) vs. Pub/Sub (GCP).
- **Private connectivity** -- PrivateLink (AWS) vs. Private Service Connect (GCP).

Both clouds get built out fully here -- not AWS-primary or GCP-primary. Each row should
eventually map to a Terraform submodule (terraform/aws/ and terraform/gcp/ variants).
