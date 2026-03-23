output "iam_role_arn" {
  value = aws_iam_role.snowflake_s3_role.arn
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.external_table_data.arn
}

output "external_s3_stage_database" {
  value = snowflake_stage.external_s3.database
}

output "external_s3_stage_schema" {
  value = snowflake_stage.external_s3.schema
}

output "external_s3_stage_name" {
  value = snowflake_stage.external_s3.name
}
