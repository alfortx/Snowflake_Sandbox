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

output "edinet_s3_stage_name" {
  value = snowflake_stage.edinet_s3_stage.name
}

output "jpx_s3_stage_name" {
  value = snowflake_stage.jpx_s3_stage.name
}

output "nta_s3_stage_name" {
  value = snowflake_stage.nta_s3_stage.name
}

output "mv_edinet_companies_name" {
  value = snowflake_materialized_view.mv_edinet_companies.name
}

output "mv_jpx_companies_name" {
  value = snowflake_materialized_view.mv_jpx_companies.name
}

output "mv_nta_companies_name" {
  value = snowflake_materialized_view.mv_nta_companies.name
}
