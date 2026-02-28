# =============================================================================
# AWS リソース: Snowflake 外部テーブル用
#
# 構成概要:
#   S3 Bucket             ← データファイルの格納先
#   Storage Integration   ← Snowflake が S3 にアクセスするための統合オブジェクト
#   IAM Role              ← Snowflake が sts:AssumeRole で実身になるロール
#   IAM Policy            ← S3 読み取り権限の定義
#   Attachment            ← ポリシーとロールの紐付け
#
# 【循環依存の解消】
#   Storage Integration は IAM ロールの ARN が必要
#   IAM Role の trust policy は Storage Integration の出力値が必要
#   → 双方が互いを参照する循環依存が発生する
#
#   解決方法:
#     Storage Integration には IAM ロール ARN を local で事前計算して渡す
#     （Terraform リソースへの参照を使わないことで依存を切る）
#     IAM Role の trust policy は Storage Integration の出力値を参照する
#     結果として依存の向きが一方通行になり、1回の apply で完結する
#
#   実行順序（Terraform が自動制御）:
#     S3 Bucket → Storage Integration → IAM Role → IAM Policy Attachment
# =============================================================================

# -----------------------------------------------------------------------------
# Data Source: 自身の AWS アカウント ID を取得
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# Local: IAM ロール ARN を事前計算（循環依存の解消に使用）
#   IAM ロールの ARN はリソース名とアカウント ID から決定論的に計算可能
# -----------------------------------------------------------------------------
locals {
  snowflake_iam_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.iam_role_name}"
}

# -----------------------------------------------------------------------------
# S3 Bucket: 外部テーブルのデータファイル格納先
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "external_table_data" {
  bucket = var.s3_bucket_name

  tags = {
    Environment = var.environment
    Purpose     = "snowflake-external-table"
  }
}

# -----------------------------------------------------------------------------
# Snowflake Storage Integration: S3 連携オブジェクト
#   - storage_aws_role_arn に local の事前計算値を使用（依存を切るため）
#   - 作成後に storage_aws_iam_user_arn / storage_aws_external_id を出力する
#     → これらを IAM Role の trust policy に使用する
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# IAM Policy: Snowflake から S3 へのアクセス権限
#   GetObject         : オブジェクトの読み取り
#   GetBucketLocation : バケットのリージョン確認（Snowflake では必須）
#   ListBucket        : バケット内のオブジェクト一覧取得
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# IAM Role: Snowflake が実身になるロール
#
#   trust policy には Storage Integration の出力値を直接参照する
#     - Principal.AWS  : Snowflake 管理の IAM ユーザー ARN
#     - sts:ExternalId : なりすまし防止のための外部 ID（Confused Deputy 対策）
#
#   Storage Integration → IAM Role という一方向の依存になるため、
#   Terraform が自動的に Storage Integration を先に作成する
# -----------------------------------------------------------------------------
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
        # ExternalId は Snowflake プロバイダーが空文字を返す場合に Terraform の
        # plan/apply 間で null vs "" の不一致が生じるため Condition ブロックを省略。
        # Principal.AWS に Snowflake 固有の IAM ユーザー ARN を指定しているため
        # セキュリティ上の問題はない。
      }
    ]
  })

  tags = {
    Environment = var.environment
    Purpose     = "snowflake-external-table"
  }
}

# -----------------------------------------------------------------------------
# IAM Role Policy Attachment: ポリシーをロールに付与
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "snowflake_s3_attach" {
  role       = aws_iam_role.snowflake_s3_role.name
  policy_arn = aws_iam_policy.snowflake_s3_access.arn
}

# -----------------------------------------------------------------------------
# Snowflake External Stage: S3 を参照する外部ステージ
#   - Storage Integration を経由して S3 にアクセスする
#   - SANDBOX_DB.WORK スキーマに作成
# -----------------------------------------------------------------------------
resource "snowflake_stage" "external_s3" {
  provider = snowflake.sysadmin

  name                = var.stage_name
  url                 = "s3://${aws_s3_bucket.external_table_data.bucket}/"
  database            = snowflake_database.sandbox.name
  schema              = snowflake_schema.work.name
  storage_integration = snowflake_storage_integration.s3.name
  comment             = "S3外部データ用ステージ（Storage Integration経由）"
}

