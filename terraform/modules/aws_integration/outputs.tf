output "iam_role_arn" {
  value = aws_iam_role.snowflake_s3_role.arn
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.external_table_data.arn
}

