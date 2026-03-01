# =============================================================================
# ルート main.tf: モジュール呼び出し
#
# 各モジュールの役割:
#   foundation      - SANDBOX_DB / SANDBOX_WH / DEVELOPER_ROLE / sandbox_user
#   cortex          - CORTEX_DB / スキーマ群 / アカウントパラメータ
#   aws_integration - S3 / IAM / Storage Integration / External Stage
#   covid19         - RAW_DB / COVID19 スキーマ / 外部テーブル / MV / Agent
#   budget_book     - BUDGET_BOOK スキーマ / TRANSACTIONS / Agent
#   rbac            - FR_* ロール 13個 + 全権限付与
#   managed_access  - MANAGED_ACCESS_DB / SCHEMA_OWNER_ROLE
# =============================================================================

module "foundation" {
  source = "./modules/foundation"

  providers = {
    snowflake.sysadmin      = snowflake.sysadmin
    snowflake.securityadmin = snowflake.securityadmin
    snowflake.useradmin     = snowflake.useradmin
    snowflake.accountadmin  = snowflake.accountadmin
  }

  environment            = var.environment
  database_name          = var.database_name
  schema_name            = var.schema_name
  user_name              = var.user_name
  user_password          = var.user_password
  developer_role_name    = var.developer_role_name
  viewer_role_name       = var.viewer_role_name
  database_comment       = var.database_comment
  schema_comment         = var.schema_comment
  warehouse_name         = var.warehouse_name
  warehouse_size         = var.warehouse_size
  warehouse_auto_suspend = var.warehouse_auto_suspend
  warehouse_auto_resume  = var.warehouse_auto_resume
  warehouse_comment      = var.warehouse_comment
}

module "cortex" {
  source = "./modules/cortex"

  providers = {
    snowflake.sysadmin     = snowflake.sysadmin
    snowflake.accountadmin = snowflake.accountadmin
  }

  cortex_db_name             = var.cortex_db_name
  cortex_analyst_schema_name = var.cortex_analyst_schema_name
  cortex_search_schema_name  = var.cortex_search_schema_name
  semantic_model_stage_name  = var.semantic_model_stage_name
  cortex_agents_schema_name  = var.cortex_agents_schema_name
}

module "aws_integration" {
  source = "./modules/aws_integration"

  providers = {
    snowflake.sysadmin     = snowflake.sysadmin
    snowflake.accountadmin = snowflake.accountadmin
    aws                    = aws
  }

  environment              = var.environment
  s3_bucket_name           = var.s3_bucket_name
  iam_role_name            = var.iam_role_name
  storage_integration_name = var.storage_integration_name
  stage_name               = var.stage_name
  sandbox_db_name          = module.foundation.sandbox_db_name
  work_schema_name         = module.foundation.work_schema_name
}

module "covid19" {
  source = "./modules/covid19"

  providers = {
    snowflake.sysadmin     = snowflake.sysadmin
    snowflake.accountadmin = snowflake.accountadmin
  }

  sandbox_wh_name             = module.foundation.sandbox_wh_name
  cortex_db_name              = module.cortex.cortex_db_name
  semantic_models_schema_name = module.cortex.semantic_models_schema_name
  agents_schema_name          = module.cortex.agents_schema_name
  semantic_view_name          = var.semantic_view_name
  agent_name                  = var.agent_name
  fr_cortex_admin_role_name   = var.fr_cortex_admin_role_name
  fr_cortex_use_role_name     = var.fr_cortex_use_role_name
}

module "budget_book" {
  source = "./modules/budget_book"

  providers = {
    snowflake.sysadmin = snowflake.sysadmin
  }

  raw_db_name                     = module.covid19.raw_db_name
  budget_book_schema_name         = var.budget_book_schema_name
  budget_book_semantic_view_name  = var.budget_book_semantic_view_name
  budget_book_search_service_name = var.budget_book_search_service_name
  budget_book_agent_name          = var.budget_book_agent_name
  cortex_db_name                  = module.cortex.cortex_db_name
  semantic_models_schema_name     = module.cortex.semantic_models_schema_name
  search_services_schema_name     = module.cortex.search_services_schema_name
  agents_schema_name              = module.cortex.agents_schema_name
  sandbox_wh_name                 = module.foundation.sandbox_wh_name
  fr_cortex_admin_role_name       = var.fr_cortex_admin_role_name
  fr_cortex_use_role_name         = var.fr_cortex_use_role_name
}

module "managed_access" {
  source = "./modules/managed_access"

  providers = {
    snowflake.sysadmin      = snowflake.sysadmin
    snowflake.securityadmin = snowflake.securityadmin
  }

  managed_access_db_name = var.managed_access_db_name
  schema_owner_role_name = var.schema_owner_role_name
  managed_schema_name    = var.managed_schema_name
  sandbox_user_name      = module.foundation.sandbox_user_name
  sandbox_wh_name        = module.foundation.sandbox_wh_name
}

module "rbac" {
  source = "./modules/rbac"

  providers = {
    snowflake.securityadmin = snowflake.securityadmin
    snowflake.accountadmin  = snowflake.accountadmin
  }

  # foundation
  sandbox_wh_name     = module.foundation.sandbox_wh_name
  sandbox_db_name     = module.foundation.sandbox_db_name
  work_schema_name    = module.foundation.work_schema_name
  developer_role_name = module.foundation.developer_role_name
  viewer_role_name    = module.foundation.viewer_role_name

  # aws_integration
  external_s3_stage_database = module.aws_integration.external_s3_stage_database
  external_s3_stage_schema   = module.aws_integration.external_s3_stage_schema
  external_s3_stage_name     = module.aws_integration.external_s3_stage_name

  # covid19
  mv_wh_name                       = module.covid19.mv_wh_name
  raw_db_name                      = module.covid19.raw_db_name
  covid19_schema_name              = module.covid19.covid19_schema_name
  covid19_s3_stage_name            = module.covid19.covid19_s3_stage_name
  covid19_world_testing_stage_name = module.covid19.covid19_world_testing_stage_name
  ext_jhu_timeseries_name          = module.covid19.ext_jhu_timeseries_name
  ext_covid19_world_testing_name   = module.covid19.ext_covid19_world_testing_name
  mv_jhu_timeseries_name           = module.covid19.mv_jhu_timeseries_name
  mv_covid19_world_testing_name    = module.covid19.mv_covid19_world_testing_name

  # budget_book
  budget_book_schema_name       = module.budget_book.budget_book_schema_name
  budget_book_transactions_name = module.budget_book.budget_book_transactions_name
  budget_book_stage_name        = module.budget_book.budget_book_stage_name
  budget_book_csv_format_name   = module.budget_book.budget_book_csv_format_name

  # cortex
  cortex_db_name                = module.cortex.cortex_db_name
  semantic_models_schema_name   = module.cortex.semantic_models_schema_name
  search_services_schema_name   = module.cortex.search_services_schema_name
  agents_schema_name            = module.cortex.agents_schema_name
  semantic_model_stage_database = module.cortex.semantic_model_stage_database
  semantic_model_stage_schema   = module.cortex.semantic_model_stage_schema
  semantic_model_stage_name     = module.cortex.semantic_model_stage_name

  # managed_access
  managed_access_db_name = module.managed_access.managed_access_db_name
  managed_schema_name    = module.managed_access.managed_schema_name
  schema_owner_role_name = module.managed_access.schema_owner_role_name

  # FR_* role name variables
  fr_wh_sandbox_operate_role_name  = var.fr_wh_sandbox_operate_role_name
  fr_wh_sandbox_use_role_name      = var.fr_wh_sandbox_use_role_name
  fr_wh_mv_operate_role_name       = var.fr_wh_mv_operate_role_name
  fr_wh_mv_use_role_name           = var.fr_wh_mv_use_role_name
  fr_sandbox_work_write_role_name  = var.fr_sandbox_work_write_role_name
  fr_sandbox_work_read_role_name   = var.fr_sandbox_work_read_role_name
  fr_raw_covid19_write_role_name   = var.fr_raw_covid19_write_role_name
  fr_raw_covid19_read_role_name    = var.fr_raw_covid19_read_role_name
  fr_budget_book_write_role_name   = var.fr_budget_book_write_role_name
  fr_budget_book_read_role_name    = var.fr_budget_book_read_role_name
  fr_cortex_admin_role_name        = var.fr_cortex_admin_role_name
  fr_cortex_use_role_name          = var.fr_cortex_use_role_name
  fr_managed_access_test_role_name = var.fr_managed_access_test_role_name
}
