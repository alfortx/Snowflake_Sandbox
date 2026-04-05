output "company_matching_schema_name" {
  value = snowflake_schema.company_matching.name
}

output "ext_edinet_table_name" {
  value = snowflake_external_table.ext_edinet_companies.name
}

output "ext_jpx_table_name" {
  value = snowflake_external_table.ext_jpx_companies.name
}

output "ext_nta_table_name" {
  value = snowflake_external_table.ext_nta_companies.name
}
