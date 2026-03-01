output "cortex_db_name" {
  value = snowflake_database.cortex.name
}

output "semantic_models_schema_name" {
  value = snowflake_schema.semantic_models.name
}

output "search_services_schema_name" {
  value = snowflake_schema.search_services.name
}

output "agents_schema_name" {
  value = snowflake_schema.agents.name
}

output "semantic_model_stage_database" {
  value = snowflake_stage.semantic_model_files.database
}

output "semantic_model_stage_schema" {
  value = snowflake_stage.semantic_model_files.schema
}

output "semantic_model_stage_name" {
  value = snowflake_stage.semantic_model_files.name
}
