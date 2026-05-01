output "bucket_name" {
  description = "DuckDB 学習用 S3 バケット名"
  value       = aws_s3_bucket.duckdb.bucket
}

output "bucket_arn" {
  description = "DuckDB 学習用 S3 バケット ARN"
  value       = aws_s3_bucket.duckdb.arn
}

output "iam_access_key_id" {
  description = "DuckDB 用 IAM アクセスキー ID"
  value       = aws_iam_access_key.duckdb.id
  sensitive   = true
}

output "iam_secret_access_key" {
  description = "DuckDB 用 IAM シークレットアクセスキー"
  value       = aws_iam_access_key.duckdb.secret
  sensitive   = true
}
