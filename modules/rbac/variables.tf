# =============================================================================
# foundation モジュール出力
# =============================================================================
variable "sandbox_wh_name" { type = string }
variable "sandbox_db_name" { type = string }
variable "work_schema_name" { type = string }
variable "developer_role_name" { type = string }
variable "viewer_role_name" { type = string }

# =============================================================================
# aws_integration モジュール出力
# =============================================================================
variable "external_s3_stage_database" { type = string }
variable "external_s3_stage_schema" { type = string }
variable "external_s3_stage_name" { type = string }

# =============================================================================
# covid19 モジュール出力
# =============================================================================
variable "mv_wh_name" { type = string }
variable "raw_db_name" { type = string }
variable "covid19_schema_name" { type = string }
variable "covid19_s3_stage_name" { type = string }
variable "covid19_world_testing_stage_name" { type = string }
variable "ext_jhu_timeseries_name" { type = string }
variable "ext_covid19_world_testing_name" { type = string }
variable "mv_jhu_timeseries_name" { type = string }
variable "mv_covid19_world_testing_name" { type = string }

# =============================================================================
# budget_book モジュール出力
# =============================================================================
variable "budget_book_schema_name" { type = string }
variable "budget_book_transactions_name" { type = string }
variable "budget_book_stage_name" { type = string }
variable "budget_book_csv_format_name" { type = string }

# =============================================================================
# cortex モジュール出力
# =============================================================================
variable "cortex_db_name" { type = string }
variable "semantic_models_schema_name" { type = string }
variable "search_services_schema_name" { type = string }
variable "agents_schema_name" { type = string }
variable "semantic_model_stage_database" { type = string }
variable "semantic_model_stage_schema" { type = string }
variable "semantic_model_stage_name" { type = string }

# =============================================================================
# managed_access モジュール出力
# =============================================================================
variable "managed_access_db_name" { type = string }
variable "managed_schema_name" { type = string }
variable "schema_owner_role_name" { type = string }

# =============================================================================
# FR_* 機能的ロール名
# =============================================================================
variable "fr_wh_sandbox_operate_role_name" { type = string }
variable "fr_wh_sandbox_use_role_name" { type = string }
variable "fr_wh_mv_operate_role_name" { type = string }
variable "fr_wh_mv_use_role_name" { type = string }
variable "fr_sandbox_work_write_role_name" { type = string }
variable "fr_sandbox_work_read_role_name" { type = string }
variable "fr_raw_covid19_write_role_name" { type = string }
variable "fr_raw_covid19_read_role_name" { type = string }
variable "fr_budget_book_write_role_name" { type = string }
variable "fr_budget_book_read_role_name" { type = string }
variable "fr_cortex_admin_role_name" { type = string }
variable "fr_cortex_use_role_name" { type = string }
variable "fr_managed_access_test_role_name" { type = string }
