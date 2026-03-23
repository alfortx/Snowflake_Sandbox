output "raw_db_name" {
  value = snowflake_database.raw_db.name
}

output "covid19_schema_name" {
  value = snowflake_schema.covid19.name
}

output "covid19_s3_stage_name" {
  value = snowflake_stage.covid19_s3_stage.name
}

output "covid19_world_testing_stage_name" {
  value = snowflake_stage.covid19_world_testing_stage.name
}

output "ext_jhu_timeseries_name" {
  value = snowflake_external_table.ext_jhu_timeseries.name
}

output "ext_covid19_world_testing_name" {
  value = snowflake_external_table.ext_covid19_world_testing.name
}

output "mv_wh_name" {
  value = snowflake_warehouse.mv_wh.name
}

output "mv_jhu_timeseries_name" {
  value = snowflake_materialized_view.mv_jhu_timeseries.name
}

output "mv_covid19_world_testing_name" {
  value = snowflake_materialized_view.mv_covid19_world_testing.name
}
