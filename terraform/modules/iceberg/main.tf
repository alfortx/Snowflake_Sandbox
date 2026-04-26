# =============================================================================
# iceberg モジュール: Iceberg Tables 学習用リソース
#
# 作成するリソース:
#   - S3 バケット（snowflake-sandbox-iceberg）
#   - IAM ポリシー（Iceberg 書き込み権限付き）
#   - IAM ロール（Iceberg 専用: snowflake-sandbox-iceberg-role）
#   - Snowflake External Volume（S3連携）
#   - ICEBERG_DB + WORK スキーマ
#
# 設計方針:
#   外部ステージ用の IAM ロール（snowflake-sandbox-s3-role）とは分離し、
#   Iceberg 専用ロールに最小権限（PutObject 含む読み書き）を付与する。
# =============================================================================

# -----------------------------------------------------------------------------
# S3 バケット
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "iceberg" {
  bucket = var.iceberg_s3_bucket_name

  tags = {
    Environment = var.environment
    Purpose     = "snowflake-iceberg-study"
  }
}

resource "aws_s3_bucket_versioning" "iceberg" {
  bucket = aws_s3_bucket.iceberg.id
  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------------------------------------------------------------
# IAM ポリシー（Iceberg 書き込み権限：PutObject 含む）
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "iceberg_s3_access" {
  name        = "${var.environment}-snowflake-iceberg-s3-access"
  description = "Snowflake が Iceberg 用 S3 バケットに読み書きするためのポリシー"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetBucketLocation",
          "s3:ListBucket",
        ]
        Resource = [
          aws_s3_bucket.iceberg.arn,
          "${aws_s3_bucket.iceberg.arn}/*",
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Snowflake External Volume（Iceberg Tables 用 S3 接続）
# ※ External Volume を先に作成し、払い出された IAM User ARN / External ID を
#   IAM ロールの信頼ポリシーに設定する（鶏と卵問題を Terraform の depends_on で解決）
# -----------------------------------------------------------------------------
resource "snowflake_external_volume" "iceberg" {
  provider = snowflake.accountadmin

  name    = var.external_volume_name
  comment = "Iceberg 学習用 S3 External Volume"

  storage_location {
    storage_location_name = "iceberg-s3-tokyo"
    storage_provider      = "S3"
    storage_base_url      = "s3://${aws_s3_bucket.iceberg.bucket}/"
    storage_aws_role_arn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.iceberg_iam_role_name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "sysadmin_usage_on_external_volume" {
  provider          = snowflake.accountadmin
  account_role_name = "SYSADMIN"
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "EXTERNAL VOLUME"
    object_name = snowflake_external_volume.iceberg.name
  }
}

# -----------------------------------------------------------------------------
# IAM ロール（Iceberg 専用）
# External Volume が払い出した IAM User ARN / External ID を信頼ポリシーに設定
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

locals {
  # describe_output から STORAGE_LOCATION_1 の value（JSON文字列）を取得して decode
  storage_location_json    = jsondecode([for o in snowflake_external_volume.iceberg.describe_output : o.value if o.name == "STORAGE_LOCATION_1"][0])
  storage_aws_iam_user_arn = local.storage_location_json["STORAGE_AWS_IAM_USER_ARN"]
  storage_aws_external_id  = local.storage_location_json["STORAGE_AWS_EXTERNAL_ID"]
}

resource "aws_iam_role" "iceberg" {
  name        = var.iceberg_iam_role_name
  description = "IAM Role for Snowflake to access Iceberg S3 bucket"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = local.storage_aws_iam_user_arn
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = local.storage_aws_external_id
          }
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Purpose     = "snowflake-iceberg"
  }
}

resource "aws_iam_role_policy_attachment" "iceberg_s3_attach" {
  role       = aws_iam_role.iceberg.name
  policy_arn = aws_iam_policy.iceberg_s3_access.arn
}

# -----------------------------------------------------------------------------
# ICEBERG_DB + WORK スキーマ
# -----------------------------------------------------------------------------
resource "snowflake_database" "iceberg" {
  provider = snowflake.sysadmin

  name    = var.iceberg_db_name
  comment = "Iceberg Tables 学習用データベース"
}

resource "snowflake_schema" "work" {
  provider = snowflake.sysadmin

  database = snowflake_database.iceberg.name
  name     = var.iceberg_work_schema_name
  comment  = "Iceberg Tables 実験用スキーマ"
}
