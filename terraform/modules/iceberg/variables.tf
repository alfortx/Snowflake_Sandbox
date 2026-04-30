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

variable "iceberg_stage_name" {
  description = "Iceberg External Volume を参照する外部ステージ名（実験用 Notebook からのツリー取得・ファイルリード用）"
  type        = string
}

variable "iceberg_storage_integration_name" {
  description = "外部ステージ用 Storage Integration 名（Iceberg S3 バケット専用）"
  type        = string
}

variable "iceberg_stage_iam_role_name" {
  description = "Storage Integration 専用 IAM ロール名（External Volume 用ロールとは分離）"
  type        = string
}
