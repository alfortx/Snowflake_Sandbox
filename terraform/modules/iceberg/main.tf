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
# Storage Integration（外部ステージ用・Iceberg S3 バケット専用）
#
# 用途:
#   実験用外部ステージ（ICEBERG_WORK_STAGE）が Iceberg S3 バケットに
#   アクセスするための Storage Integration。
#
# 設計:
#   External Volume 用 IAM ロール（iceberg-role）との循環参照を避けるため、
#   Storage Integration 専用の IAM ロール（iceberg-stage-role）を別途作成する。
#   これにより「Storage Integration → IAM ロール → Storage Integration」の
#   循環依存が発生しない。
#
# 鶏卵問題の解消:
#   1. Storage Integration を先に作成（IAM ロールは未作成でも Snowflake 側は OK）
#   2. 払い出された storage_aws_iam_user_arn を IAM ロールの trust policy に設定
#   3. terraform apply を 1 回で完結（depends_on で順序制御）
# -----------------------------------------------------------------------------
resource "snowflake_storage_integration" "iceberg" {
  provider = snowflake.accountadmin

  name    = var.iceberg_storage_integration_name
  comment = "[実験用] Iceberg S3 バケットへの外部ステージアクセス用 Storage Integration"
  type    = "EXTERNAL_STAGE"
  enabled = true

  storage_provider     = "S3"
  storage_aws_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.iceberg_stage_iam_role_name}"

  storage_allowed_locations = ["s3://${aws_s3_bucket.iceberg.bucket}/"]
}

resource "snowflake_grant_privileges_to_account_role" "sysadmin_usage_on_iceberg_integration" {
  provider          = snowflake.accountadmin
  account_role_name = "SYSADMIN"
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "INTEGRATION"
    object_name = snowflake_storage_integration.iceberg.name
  }
}

# Storage Integration 専用 IAM ロール
# Storage Integration が払い出した IAM User ARN を trust policy に設定（鶏卵問題を depends_on で解決）
resource "aws_iam_role" "iceberg_stage" {
  name        = var.iceberg_stage_iam_role_name
  description = "IAM Role for Snowflake Storage Integration to access Iceberg S3 bucket (for external stage)"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "StorageIntegrationAccess"
        Effect = "Allow"
        Principal = {
          AWS = snowflake_storage_integration.iceberg.storage_aws_iam_user_arn
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Environment = var.environment
    Purpose     = "snowflake-iceberg-stage"
  }

  depends_on = [snowflake_storage_integration.iceberg]
}

resource "aws_iam_role_policy_attachment" "iceberg_stage_s3_attach" {
  role       = aws_iam_role.iceberg_stage.name
  policy_arn = aws_iam_policy.iceberg_s3_access.arn
}

# -----------------------------------------------------------------------------
# 外部ステージ（実験用 Notebook からの S3 ファイルアクセス用）
#
# 用途:
#   Snowflake Notebook（experiments/iceberg/ 配下）から External Volume の
#   S3 バケットに対してツリー取得（LIST）・ファイルリードを行うための外部ステージ。
#   本ステージは実験・学習目的であり、本番運用には使用しないこと。
# -----------------------------------------------------------------------------
resource "snowflake_stage" "iceberg_work" {
  provider = snowflake.sysadmin

  database            = snowflake_database.iceberg.name
  schema              = snowflake_schema.work.name
  name                = var.iceberg_stage_name
  storage_integration = snowflake_storage_integration.iceberg.name
  url                 = "s3://${aws_s3_bucket.iceberg.bucket}/"

  comment = "[実験用] External Volume（${var.external_volume_name}）の S3 バケットを参照する外部ステージ。Notebook からのツリー取得・ファイルリードに使用する。"

  depends_on = [
    snowflake_schema.work,
    snowflake_storage_integration.iceberg,
    snowflake_grant_privileges_to_account_role.sysadmin_usage_on_iceberg_integration,
  ]
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
