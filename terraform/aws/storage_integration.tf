# See docs/integrations/csp-crosswalk.md "Storage integration: S3 + IAM vs. GCS + service
# account" for the full narrative this module implements.

resource "aws_s3_bucket" "raw_landing" {
  bucket = "${var.org_prefix}-raw-landing"
}

resource "aws_s3_bucket_versioning" "raw_landing" {
  bucket = aws_s3_bucket.raw_landing.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "raw_landing" {
  bucket = aws_s3_bucket.raw_landing.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "raw_landing" {
  bucket                  = aws_s3_bucket.raw_landing.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "snowflake_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [var.snowflake_iam_user_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.snowflake_external_id]
    }
  }
}

data "aws_iam_policy_document" "snowflake_bucket_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:ListBucket"]
    resources = [aws_s3_bucket.raw_landing.arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.raw_landing.arn}/*"]
  }
}

resource "aws_iam_role" "snowflake_s3" {
  name               = "${var.org_prefix}-snowflake-s3-integration"
  assume_role_policy = data.aws_iam_policy_document.snowflake_trust.json
}

resource "aws_iam_role_policy" "snowflake_s3_access" {
  name   = "${var.org_prefix}-snowflake-s3-access"
  role   = aws_iam_role.snowflake_s3.id
  policy = data.aws_iam_policy_document.snowflake_bucket_access.json
}

resource "snowflake_storage_integration_aws" "s3" {
  name    = upper("${var.org_prefix}_s3_integration")
  enabled = true
  comment = "Storage integration for Harborline's raw data landing bucket."

  storage_provider          = "S3"
  storage_aws_role_arn      = aws_iam_role.snowflake_s3.arn
  storage_allowed_locations = ["s3://${aws_s3_bucket.raw_landing.bucket}/"]
}

output "storage_integration_iam_user_arn" {
  description = "Real IAM user ARN Snowflake generated for this integration. Feed back as -var snowflake_iam_user_arn to close the trust loop on a second apply."
  value       = snowflake_storage_integration_aws.s3.describe_output[0].iam_user_arn
}

output "storage_integration_external_id" {
  description = "Real external ID Snowflake generated for this integration. Feed back as -var snowflake_external_id on a second apply."
  value       = snowflake_storage_integration_aws.s3.describe_output[0].external_id
}
