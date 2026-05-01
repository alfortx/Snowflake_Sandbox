# =============================================================================
# duckdb モジュール: DuckDB 学習用 S3 リソース
#
# 作成するリソース:
#   - S3 バケット（DuckDB から Parquet を直接クエリする用途）
#   - IAM ユーザー（DuckDB は IAM ロールを引き受けられないため、ユーザー + アクセスキーで認証）
#   - IAM ポリシー（S3 読み書き権限）
#   - IAM アクセスキー（Notebook の環境変数として使用）
#
# 設計方針:
#   Snowflake 連携なし。DuckDB がローカルから直接 S3 にアクセスする構成。
#   IAM ロールではなく IAM ユーザーを使う理由:
#     DuckDB の httpfs 拡張はアクセスキー認証のみサポートしており、
#     IAM ロールの AssumeRole には対応していないため。
# =============================================================================

# -----------------------------------------------------------------------------
# S3 バケット
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "duckdb" {
  bucket = var.duckdb_s3_bucket_name

  tags = {
    Environment = var.environment
    Purpose     = "duckdb-study"
  }
}

# -----------------------------------------------------------------------------
# IAM ポリシー（S3 読み書き権限）
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "duckdb_s3_access" {
  name        = "${var.environment}-duckdb-s3-access"
  description = "DuckDB が学習用 S3 バケットに読み書きするためのポリシー"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
        ]
        Resource = [
          aws_s3_bucket.duckdb.arn,
          "${aws_s3_bucket.duckdb.arn}/*",
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# IAM ユーザー
# -----------------------------------------------------------------------------
resource "aws_iam_user" "duckdb" {
  name = var.duckdb_iam_user_name

  tags = {
    Environment = var.environment
    Purpose     = "duckdb-study"
  }
}

resource "aws_iam_user_policy_attachment" "duckdb" {
  user       = aws_iam_user.duckdb.name
  policy_arn = aws_iam_policy.duckdb_s3_access.arn
}

# -----------------------------------------------------------------------------
# IAM アクセスキー（Notebook の環境変数として使用）
# -----------------------------------------------------------------------------
resource "aws_iam_access_key" "duckdb" {
  user = aws_iam_user.duckdb.name
}
