variable "environment" {
  description = "環境名"
  type        = string
}

variable "iceberg_s3_bucket_name" {
  description = "Iceberg 用 S3 バケット名"
  type        = string
}

variable "iceberg_iam_role_name" {
  description = "Iceberg 専用 IAM ロール名（外部ステージ用ロールとは分離）"
  type        = string
}

variable "external_volume_name" {
  description = "Snowflake External Volume 名"
  type        = string
}

variable "iceberg_db_name" {
  description = "Iceberg 学習用データベース名"
  type        = string
}

variable "iceberg_work_schema_name" {
  description = "Iceberg 学習用スキーマ名"
  type        = string
}
