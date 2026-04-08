output "developer_db_name" {
  value = snowflake_database.developer.name
}

output "developer_work_schema_name" {
  value = snowflake_schema.work.name
}
