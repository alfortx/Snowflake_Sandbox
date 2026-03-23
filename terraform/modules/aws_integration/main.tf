# =============================================================================
# aws_integration モジュール: S3 / IAM / Storage Integration / External Stage
# =============================================================================

data "aws_caller_identity" "current" {}

locals {
  snowflake_iam_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.iam_role_name}"
}

resource "aws_s3_bucket" "external_table_data" {
  bucket = var.s3_bucket_name

  tags = {
    Environment = var.environment
    Purpose     = "snowflake-external-table"
  }
}

resource "snowflake_storage_integration" "s3" {
  provider = snowflake.accountadmin

  name    = var.storage_integration_name
  comment = "Snowflake サンドボックス用 S3 Storage Integration"
  type    = "EXTERNAL_STAGE"
  enabled = true

  storage_provider     = "S3"
  storage_aws_role_arn = local.snowflake_iam_role_arn

  storage_allowed_locations = ["s3://${aws_s3_bucket.external_table_data.bucket}/"]
}

resource "aws_iam_policy" "snowflake_s3_access" {
  name        = "${var.environment}-snowflake-s3-access"
  description = "Snowflake が S3 バケットにアクセスするためのポリシー"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetBucketLocation",
          "s3:ListBucket",
        ]
        Resource = [
          aws_s3_bucket.external_table_data.arn,
          "${aws_s3_bucket.external_table_data.arn}/*",
        ]
      }
    ]
  })
}

resource "aws_iam_role" "snowflake_s3_role" {
  name        = var.iam_role_name
  description = "IAM Role for Snowflake to access S3 via Storage Integration"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = snowflake_storage_integration.s3.storage_aws_iam_user_arn
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Environment = var.environment
    Purpose     = "snowflake-external-table"
  }
}

resource "aws_iam_role_policy_attachment" "snowflake_s3_attach" {
  role       = aws_iam_role.snowflake_s3_role.name
  policy_arn = aws_iam_policy.snowflake_s3_access.arn
}

resource "snowflake_stage" "external_s3" {
  provider = snowflake.sysadmin

  name                = var.stage_name
  url                 = "s3://${aws_s3_bucket.external_table_data.bucket}/"
  database            = var.sandbox_db_name
  schema              = var.work_schema_name
  storage_integration = snowflake_storage_integration.s3.name
  comment             = "S3外部データ用ステージ（Storage Integration経由）"
}
