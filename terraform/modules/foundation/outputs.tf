output "sandbox_db_name" {
  value = snowflake_database.sandbox.name
}

output "work_schema_name" {
  value = snowflake_schema.work.name
}

output "sandbox_wh_name" {
  value = snowflake_warehouse.sandbox.name
}

output "developer_role_name" {
  value = snowflake_account_role.developer_role.name
}

output "viewer_role_name" {
  value = snowflake_account_role.viewer_role.name
}

output "sandbox_user_name" {
  value = snowflake_user.sandbox_user.name
}
