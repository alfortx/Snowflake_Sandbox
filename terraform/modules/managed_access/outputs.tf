output "managed_access_db_name" {
  value = snowflake_database.managed_access.name
}

output "managed_schema_name" {
  value = snowflake_schema.managed.name
}

output "schema_owner_role_name" {
  value = snowflake_account_role.schema_owner_role.name
}
