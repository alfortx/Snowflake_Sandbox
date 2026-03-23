output "fr_cortex_admin_role_name" {
  value = snowflake_account_role.fr_cortex_admin.name
}

output "fr_cortex_use_role_name" {
  value = snowflake_account_role.fr_cortex_use.name
}
