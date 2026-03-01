# =============================================================================
# moved ブロック: リソースアドレスをフラット → モジュール構造に移行
# terraform plan が "0 to add, 0 to change, 0 to destroy" になったら削除する
# =============================================================================

# --- module.foundation ---
moved {
  from = snowflake_database.sandbox
  to   = module.foundation.snowflake_database.sandbox
}
moved {
  from = snowflake_schema.work
  to   = module.foundation.snowflake_schema.work
}
moved {
  from = snowflake_warehouse.sandbox
  to   = module.foundation.snowflake_warehouse.sandbox
}
moved {
  from = snowflake_account_role.developer_role
  to   = module.foundation.snowflake_account_role.developer_role
}
moved {
  from = snowflake_account_role.viewer_role
  to   = module.foundation.snowflake_account_role.viewer_role
}
moved {
  from = snowflake_user.sandbox_user
  to   = module.foundation.snowflake_user.sandbox_user
}
moved {
  from = snowflake_grant_account_role.user_role
  to   = module.foundation.snowflake_grant_account_role.user_role
}
moved {
  from = snowflake_grant_account_role.user_viewer_role
  to   = module.foundation.snowflake_grant_account_role.user_viewer_role
}
moved {
  from = snowflake_grant_account_role.main_user_developer_role
  to   = module.foundation.snowflake_grant_account_role.main_user_developer_role
}
moved {
  from = snowflake_grant_account_role.main_user_viewer_role
  to   = module.foundation.snowflake_grant_account_role.main_user_viewer_role
}
moved {
  from = snowflake_execute.disable_secondary_roles_main_user
  to   = module.foundation.snowflake_execute.disable_secondary_roles_main_user
}
moved {
  from = snowflake_execute.disable_secondary_roles_sandbox_user
  to   = module.foundation.snowflake_execute.disable_secondary_roles_sandbox_user
}

# --- module.cortex ---
moved {
  from = snowflake_database.cortex
  to   = module.cortex.snowflake_database.cortex
}
moved {
  from = snowflake_schema.semantic_models
  to   = module.cortex.snowflake_schema.semantic_models
}
moved {
  from = snowflake_schema.search_services
  to   = module.cortex.snowflake_schema.search_services
}
moved {
  from = snowflake_stage.semantic_model_files
  to   = module.cortex.snowflake_stage.semantic_model_files
}
moved {
  from = snowflake_schema.agents
  to   = module.cortex.snowflake_schema.agents
}
moved {
  from = snowflake_current_account.account
  to   = module.cortex.snowflake_current_account.account
}

# --- module.aws_integration ---
moved {
  from = aws_s3_bucket.external_table_data
  to   = module.aws_integration.aws_s3_bucket.external_table_data
}
moved {
  from = snowflake_storage_integration.s3
  to   = module.aws_integration.snowflake_storage_integration.s3
}
moved {
  from = aws_iam_policy.snowflake_s3_access
  to   = module.aws_integration.aws_iam_policy.snowflake_s3_access
}
moved {
  from = aws_iam_role.snowflake_s3_role
  to   = module.aws_integration.aws_iam_role.snowflake_s3_role
}
moved {
  from = aws_iam_role_policy_attachment.snowflake_s3_attach
  to   = module.aws_integration.aws_iam_role_policy_attachment.snowflake_s3_attach
}
moved {
  from = snowflake_stage.external_s3
  to   = module.aws_integration.snowflake_stage.external_s3
}

# --- module.covid19 ---
moved {
  from = snowflake_database.raw_db
  to   = module.covid19.snowflake_database.raw_db
}
moved {
  from = snowflake_schema.covid19
  to   = module.covid19.snowflake_schema.covid19
}
moved {
  from = snowflake_file_format.csv_format
  to   = module.covid19.snowflake_file_format.csv_format
}
moved {
  from = snowflake_stage.covid19_s3_stage
  to   = module.covid19.snowflake_stage.covid19_s3_stage
}
moved {
  from = snowflake_execute.covid19_s3_stage_directory
  to   = module.covid19.snowflake_execute.covid19_s3_stage_directory
}
moved {
  from = snowflake_stage.covid19_world_testing_stage
  to   = module.covid19.snowflake_stage.covid19_world_testing_stage
}
moved {
  from = snowflake_execute.covid19_world_testing_stage_directory
  to   = module.covid19.snowflake_execute.covid19_world_testing_stage_directory
}
moved {
  from = snowflake_external_table.ext_jhu_timeseries
  to   = module.covid19.snowflake_external_table.ext_jhu_timeseries
}
moved {
  from = snowflake_external_table.ext_covid19_world_testing
  to   = module.covid19.snowflake_external_table.ext_covid19_world_testing
}
moved {
  from = snowflake_grant_ownership.ext_jhu_timeseries_to_sysadmin
  to   = module.covid19.snowflake_grant_ownership.ext_jhu_timeseries_to_sysadmin
}
moved {
  from = snowflake_warehouse.mv_wh
  to   = module.covid19.snowflake_warehouse.mv_wh
}
moved {
  from = snowflake_materialized_view.mv_jhu_timeseries
  to   = module.covid19.snowflake_materialized_view.mv_jhu_timeseries
}
moved {
  from = snowflake_materialized_view.mv_covid19_world_testing
  to   = module.covid19.snowflake_materialized_view.mv_covid19_world_testing
}
moved {
  from = snowflake_semantic_view.covid19
  to   = module.covid19.snowflake_semantic_view.covid19
}
moved {
  from = snowflake_execute.semantic_view_grant
  to   = module.covid19.snowflake_execute.semantic_view_grant
}
moved {
  from = snowflake_execute.covid19_agent
  to   = module.covid19.snowflake_execute.covid19_agent
}
moved {
  from = snowflake_execute.agent_usage_grant
  to   = module.covid19.snowflake_execute.agent_usage_grant
}
moved {
  from = snowflake_execute.covid19_semantic_view_grant_use
  to   = module.covid19.snowflake_execute.covid19_semantic_view_grant_use
}
moved {
  from = snowflake_execute.covid19_agent_grant_use
  to   = module.covid19.snowflake_execute.covid19_agent_grant_use
}

# --- module.budget_book ---
moved {
  from = snowflake_schema.budget_book
  to   = module.budget_book.snowflake_schema.budget_book
}
moved {
  from = snowflake_stage.budget_book_stage
  to   = module.budget_book.snowflake_stage.budget_book_stage
}
moved {
  from = snowflake_file_format.budget_book_csv_format
  to   = module.budget_book.snowflake_file_format.budget_book_csv_format
}
moved {
  from = snowflake_table.budget_book_transactions
  to   = module.budget_book.snowflake_table.budget_book_transactions
}
moved {
  from = snowflake_semantic_view.budget_book
  to   = module.budget_book.snowflake_semantic_view.budget_book
}
moved {
  from = snowflake_execute.budget_book_semantic_view_grant_cortex
  to   = module.budget_book.snowflake_execute.budget_book_semantic_view_grant_cortex
}
moved {
  from = snowflake_execute.budget_book_search_service
  to   = module.budget_book.snowflake_execute.budget_book_search_service
}
moved {
  from = snowflake_execute.budget_book_search_service_grant_cortex
  to   = module.budget_book.snowflake_execute.budget_book_search_service_grant_cortex
}
moved {
  from = snowflake_execute.budget_book_search_service_monitor_cortex
  to   = module.budget_book.snowflake_execute.budget_book_search_service_monitor_cortex
}
moved {
  from = snowflake_execute.budget_book_agent
  to   = module.budget_book.snowflake_execute.budget_book_agent
}
moved {
  from = snowflake_execute.budget_book_agent_grant_cortex
  to   = module.budget_book.snowflake_execute.budget_book_agent_grant_cortex
}
moved {
  from = snowflake_execute.budget_book_semantic_view_grant_use
  to   = module.budget_book.snowflake_execute.budget_book_semantic_view_grant_use
}
moved {
  from = snowflake_execute.budget_book_search_service_grant_use
  to   = module.budget_book.snowflake_execute.budget_book_search_service_grant_use
}
moved {
  from = snowflake_execute.budget_book_agent_grant_use
  to   = module.budget_book.snowflake_execute.budget_book_agent_grant_use
}

# --- module.managed_access ---
moved {
  from = snowflake_database.managed_access
  to   = module.managed_access.snowflake_database.managed_access
}
moved {
  from = snowflake_account_role.schema_owner_role
  to   = module.managed_access.snowflake_account_role.schema_owner_role
}
moved {
  from = snowflake_grant_account_role.sandbox_user_to_schema_owner
  to   = module.managed_access.snowflake_grant_account_role.sandbox_user_to_schema_owner
}
moved {
  from = snowflake_grant_privileges_to_account_role.schema_owner_db_usage
  to   = module.managed_access.snowflake_grant_privileges_to_account_role.schema_owner_db_usage
}
moved {
  from = snowflake_grant_privileges_to_account_role.schema_owner_wh_usage
  to   = module.managed_access.snowflake_grant_privileges_to_account_role.schema_owner_wh_usage
}
moved {
  from = snowflake_schema.managed
  to   = module.managed_access.snowflake_schema.managed
}
moved {
  from = snowflake_grant_ownership.managed_schema_to_schema_owner
  to   = module.managed_access.snowflake_grant_ownership.managed_schema_to_schema_owner
}

# --- module.rbac (functional_roles.tf) ---
moved {
  from = snowflake_account_role.fr_wh_sandbox_operate
  to   = module.rbac.snowflake_account_role.fr_wh_sandbox_operate
}
moved {
  from = snowflake_account_role.fr_wh_sandbox_use
  to   = module.rbac.snowflake_account_role.fr_wh_sandbox_use
}
moved {
  from = snowflake_account_role.fr_wh_mv_operate
  to   = module.rbac.snowflake_account_role.fr_wh_mv_operate
}
moved {
  from = snowflake_account_role.fr_wh_mv_use
  to   = module.rbac.snowflake_account_role.fr_wh_mv_use
}
moved {
  from = snowflake_account_role.fr_sandbox_work_write
  to   = module.rbac.snowflake_account_role.fr_sandbox_work_write
}
moved {
  from = snowflake_account_role.fr_sandbox_work_read
  to   = module.rbac.snowflake_account_role.fr_sandbox_work_read
}
moved {
  from = snowflake_account_role.fr_raw_covid19_write
  to   = module.rbac.snowflake_account_role.fr_raw_covid19_write
}
moved {
  from = snowflake_account_role.fr_raw_covid19_read
  to   = module.rbac.snowflake_account_role.fr_raw_covid19_read
}
moved {
  from = snowflake_account_role.fr_budget_book_write
  to   = module.rbac.snowflake_account_role.fr_budget_book_write
}
moved {
  from = snowflake_account_role.fr_budget_book_read
  to   = module.rbac.snowflake_account_role.fr_budget_book_read
}
moved {
  from = snowflake_account_role.fr_cortex_admin
  to   = module.rbac.snowflake_account_role.fr_cortex_admin
}
moved {
  from = snowflake_account_role.fr_cortex_use
  to   = module.rbac.snowflake_account_role.fr_cortex_use
}
moved {
  from = snowflake_account_role.fr_managed_access_test
  to   = module.rbac.snowflake_account_role.fr_managed_access_test
}
moved {
  from = snowflake_grant_account_role.fr_wh_sandbox_operate_to_sysadmin
  to   = module.rbac.snowflake_grant_account_role.fr_wh_sandbox_operate_to_sysadmin
}
moved {
  from = snowflake_grant_account_role.fr_wh_sandbox_use_to_sysadmin
  to   = module.rbac.snowflake_grant_account_role.fr_wh_sandbox_use_to_sysadmin
}
moved {
  from = snowflake_grant_account_role.fr_wh_mv_operate_to_sysadmin
  to   = module.rbac.snowflake_grant_account_role.fr_wh_mv_operate_to_sysadmin
}
moved {
  from = snowflake_grant_account_role.fr_wh_mv_use_to_sysadmin
  to   = module.rbac.snowflake_grant_account_role.fr_wh_mv_use_to_sysadmin
}
moved {
  from = snowflake_grant_account_role.fr_sandbox_work_write_to_sysadmin
  to   = module.rbac.snowflake_grant_account_role.fr_sandbox_work_write_to_sysadmin
}
moved {
  from = snowflake_grant_account_role.fr_sandbox_work_read_to_sysadmin
  to   = module.rbac.snowflake_grant_account_role.fr_sandbox_work_read_to_sysadmin
}
moved {
  from = snowflake_grant_account_role.fr_raw_covid19_write_to_sysadmin
  to   = module.rbac.snowflake_grant_account_role.fr_raw_covid19_write_to_sysadmin
}
moved {
  from = snowflake_grant_account_role.fr_raw_covid19_read_to_sysadmin
  to   = module.rbac.snowflake_grant_account_role.fr_raw_covid19_read_to_sysadmin
}
moved {
  from = snowflake_grant_account_role.fr_budget_book_write_to_sysadmin
  to   = module.rbac.snowflake_grant_account_role.fr_budget_book_write_to_sysadmin
}
moved {
  from = snowflake_grant_account_role.fr_budget_book_read_to_sysadmin
  to   = module.rbac.snowflake_grant_account_role.fr_budget_book_read_to_sysadmin
}
moved {
  from = snowflake_grant_account_role.fr_cortex_admin_to_sysadmin
  to   = module.rbac.snowflake_grant_account_role.fr_cortex_admin_to_sysadmin
}
moved {
  from = snowflake_grant_account_role.fr_cortex_use_to_sysadmin
  to   = module.rbac.snowflake_grant_account_role.fr_cortex_use_to_sysadmin
}
moved {
  from = snowflake_grant_account_role.fr_managed_access_test_to_sysadmin
  to   = module.rbac.snowflake_grant_account_role.fr_managed_access_test_to_sysadmin
}
moved {
  from = snowflake_grant_account_role.developer_role_to_sysadmin
  to   = module.rbac.snowflake_grant_account_role.developer_role_to_sysadmin
}
moved {
  from = snowflake_grant_account_role.viewer_role_to_sysadmin
  to   = module.rbac.snowflake_grant_account_role.viewer_role_to_sysadmin
}
moved {
  from = snowflake_grant_account_role.schema_owner_role_to_sysadmin
  to   = module.rbac.snowflake_grant_account_role.schema_owner_role_to_sysadmin
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_wh_sandbox_operate_grant
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_wh_sandbox_operate_grant
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_wh_sandbox_use_grant
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_wh_sandbox_use_grant
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_wh_mv_operate_grant
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_wh_mv_operate_grant
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_wh_mv_use_grant
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_wh_mv_use_grant
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_sandbox_work_write_db
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_sandbox_work_write_db
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_sandbox_work_write_schema
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_sandbox_work_write_schema
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_sandbox_work_write_future_tables
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_sandbox_work_write_future_tables
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_sandbox_work_write_stage
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_sandbox_work_write_stage
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_sandbox_work_read_db
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_sandbox_work_read_db
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_sandbox_work_read_schema
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_sandbox_work_read_schema
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_sandbox_work_read_future_tables
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_sandbox_work_read_future_tables
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_raw_covid19_write_db
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_raw_covid19_write_db
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_raw_covid19_write_schema
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_raw_covid19_write_schema
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_raw_covid19_write_future_tables
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_raw_covid19_write_future_tables
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_raw_covid19_write_jhu_stage
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_raw_covid19_write_jhu_stage
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_raw_covid19_write_world_testing_stage
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_raw_covid19_write_world_testing_stage
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_raw_covid19_write_ext_jhu
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_raw_covid19_write_ext_jhu
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_raw_covid19_write_ext_world_testing
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_raw_covid19_write_ext_world_testing
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_raw_covid19_write_mv_jhu
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_raw_covid19_write_mv_jhu
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_raw_covid19_write_mv_world_testing
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_raw_covid19_write_mv_world_testing
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_raw_covid19_read_db
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_raw_covid19_read_db
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_raw_covid19_read_schema
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_raw_covid19_read_schema
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_raw_covid19_read_future_tables
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_raw_covid19_read_future_tables
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_raw_covid19_read_jhu_stage
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_raw_covid19_read_jhu_stage
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_raw_covid19_read_world_testing_stage
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_raw_covid19_read_world_testing_stage
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_raw_covid19_read_ext_jhu
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_raw_covid19_read_ext_jhu
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_raw_covid19_read_ext_world_testing
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_raw_covid19_read_ext_world_testing
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_raw_covid19_read_mv_jhu
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_raw_covid19_read_mv_jhu
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_raw_covid19_read_mv_world_testing
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_raw_covid19_read_mv_world_testing
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_budget_book_write_db
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_budget_book_write_db
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_budget_book_write_schema
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_budget_book_write_schema
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_budget_book_write_transactions
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_budget_book_write_transactions
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_budget_book_write_future_tables
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_budget_book_write_future_tables
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_budget_book_write_stage
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_budget_book_write_stage
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_budget_book_write_file_format
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_budget_book_write_file_format
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_budget_book_read_db
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_budget_book_read_db
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_budget_book_read_schema
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_budget_book_read_schema
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_budget_book_read_transactions
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_budget_book_read_transactions
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_budget_book_read_future_tables
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_budget_book_read_future_tables
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_budget_book_read_stage
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_budget_book_read_stage
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_budget_book_read_file_format
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_budget_book_read_file_format
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_cortex_admin_db
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_cortex_admin_db
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_cortex_admin_semantic_models_schema
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_cortex_admin_semantic_models_schema
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_cortex_admin_search_services_schema
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_cortex_admin_search_services_schema
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_cortex_admin_agents_schema
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_cortex_admin_agents_schema
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_cortex_admin_stage
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_cortex_admin_stage
}
moved {
  from = snowflake_grant_database_role.fr_cortex_admin_cortex_user
  to   = module.rbac.snowflake_grant_database_role.fr_cortex_admin_cortex_user
}
moved {
  from = snowflake_grant_database_role.fr_cortex_admin_cortex_agent_user
  to   = module.rbac.snowflake_grant_database_role.fr_cortex_admin_cortex_agent_user
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_cortex_use_db
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_cortex_use_db
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_cortex_use_semantic_models_schema
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_cortex_use_semantic_models_schema
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_cortex_use_search_services_schema
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_cortex_use_search_services_schema
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_cortex_use_agents_schema
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_cortex_use_agents_schema
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_cortex_use_stage
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_cortex_use_stage
}
moved {
  from = snowflake_grant_database_role.fr_cortex_use_cortex_user
  to   = module.rbac.snowflake_grant_database_role.fr_cortex_use_cortex_user
}
moved {
  from = snowflake_grant_database_role.fr_cortex_use_cortex_agent_user
  to   = module.rbac.snowflake_grant_database_role.fr_cortex_use_cortex_agent_user
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_managed_access_test_db
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_managed_access_test_db
}
moved {
  from = snowflake_grant_privileges_to_account_role.fr_managed_access_test_schema
  to   = module.rbac.snowflake_grant_privileges_to_account_role.fr_managed_access_test_schema
}

# --- module.rbac (main.tf: 役割ロール継承) ---
moved {
  from = snowflake_grant_account_role.developer_inherits_wh_sandbox_operate
  to   = module.rbac.snowflake_grant_account_role.developer_inherits_wh_sandbox_operate
}
moved {
  from = snowflake_grant_account_role.developer_inherits_wh_mv_operate
  to   = module.rbac.snowflake_grant_account_role.developer_inherits_wh_mv_operate
}
moved {
  from = snowflake_grant_account_role.developer_inherits_sandbox_work_write
  to   = module.rbac.snowflake_grant_account_role.developer_inherits_sandbox_work_write
}
moved {
  from = snowflake_grant_account_role.developer_inherits_raw_covid19_write
  to   = module.rbac.snowflake_grant_account_role.developer_inherits_raw_covid19_write
}
moved {
  from = snowflake_grant_account_role.developer_inherits_budget_book_write
  to   = module.rbac.snowflake_grant_account_role.developer_inherits_budget_book_write
}
moved {
  from = snowflake_grant_account_role.developer_inherits_cortex_use
  to   = module.rbac.snowflake_grant_account_role.developer_inherits_cortex_use
}
moved {
  from = snowflake_grant_account_role.developer_inherits_cortex_admin
  to   = module.rbac.snowflake_grant_account_role.developer_inherits_cortex_admin
}
moved {
  from = snowflake_grant_account_role.developer_inherits_managed_access_test
  to   = module.rbac.snowflake_grant_account_role.developer_inherits_managed_access_test
}
moved {
  from = snowflake_grant_account_role.viewer_inherits_wh_sandbox_use
  to   = module.rbac.snowflake_grant_account_role.viewer_inherits_wh_sandbox_use
}
moved {
  from = snowflake_grant_account_role.viewer_inherits_wh_mv_use
  to   = module.rbac.snowflake_grant_account_role.viewer_inherits_wh_mv_use
}
moved {
  from = snowflake_grant_account_role.viewer_inherits_sandbox_work_read
  to   = module.rbac.snowflake_grant_account_role.viewer_inherits_sandbox_work_read
}
moved {
  from = snowflake_grant_account_role.viewer_inherits_raw_covid19_read
  to   = module.rbac.snowflake_grant_account_role.viewer_inherits_raw_covid19_read
}
moved {
  from = snowflake_grant_account_role.viewer_inherits_budget_book_read
  to   = module.rbac.snowflake_grant_account_role.viewer_inherits_budget_book_read
}
moved {
  from = snowflake_grant_account_role.viewer_inherits_cortex_use
  to   = module.rbac.snowflake_grant_account_role.viewer_inherits_cortex_use
}
