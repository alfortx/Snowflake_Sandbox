output "config_db_name" {
  value = snowflake_database.config.name
}

output "session_policies_schema_name" {
  value = snowflake_schema.session_policies.name
}

output "session_policy_name" {
  value = var.session_policy_name
}
