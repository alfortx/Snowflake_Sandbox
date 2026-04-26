output "iceberg_db_name" {
  description = "Iceberg 学習用データベース名"
  value       = snowflake_database.iceberg.name
}

output "iceberg_work_schema_name" {
  description = "Iceberg 学習用スキーマ名"
  value       = snowflake_schema.work.name
}

output "external_volume_name" {
  description = "Snowflake External Volume 名"
  value       = snowflake_external_volume.iceberg.name
}

output "iceberg_s3_bucket_name" {
  description = "Iceberg 用 S3 バケット名"
  value       = aws_s3_bucket.iceberg.bucket
}
