variable "environment" {
  description = "環境名"
  type        = string
}

variable "duckdb_s3_bucket_name" {
  description = "DuckDB 学習用 S3 バケット名"
  type        = string
}

variable "duckdb_iam_user_name" {
  description = "DuckDB から S3 にアクセスするための IAM ユーザー名"
  type        = string
}
