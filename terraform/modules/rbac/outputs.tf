output "fr_cortex_admin_role_name" {
  value = snowflake_account_role.fr_cortex_admin.name
}

output "fr_cortex_use_role_name" {
  value = snowflake_account_role.fr_cortex_use.name
}

output "fr_raw_company_matching_write_role_name" {
  value = snowflake_account_role.fr_raw_company_matching_write.name
}

output "fr_raw_company_matching_read_role_name" {
  value = snowflake_account_role.fr_raw_company_matching_read.name
}
