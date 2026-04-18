# =============================================================================
# foundation モジュール出力
# =============================================================================
variable "sandbox_wh_name" { type = string }
variable "sandbox_db_name" { type = string }
variable "work_schema_name" { type = string }
variable "developer_role_name" { type = string }
variable "viewer_role_name" { type = string }

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
# company_matching モジュール出力
# =============================================================================
variable "company_matching_schema_name" { type = string }
variable "edinet_s3_stage_name" { type = string }
variable "jpx_s3_stage_name" { type = string }
variable "nta_s3_stage_name" { type = string }
variable "ext_edinet_table_name" { type = string }
variable "ext_jpx_table_name" { type = string }
variable "ext_nta_table_name" { type = string }
variable "mv_edinet_companies_name" { type = string }
variable "mv_jpx_companies_name" { type = string }
variable "mv_nta_companies_name" { type = string }

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
variable "fr_raw_company_matching_write_role_name" { type = string }
variable "fr_raw_company_matching_read_role_name" { type = string }
variable "fr_cortex_admin_role_name" { type = string }
variable "fr_cortex_use_role_name" { type = string }
variable "fr_managed_access_test_role_name" { type = string }

# =============================================================================
# developer モジュール出力
# =============================================================================
variable "developer_db_name" { type = string }
variable "developer_work_schema_name" { type = string }

variable "fr_developer_db_write_role_name" { type = string }
variable "fr_developer_db_read_role_name" { type = string }

# =============================================================================
# project_db モジュール出力
# =============================================================================
variable "project_db_name" { type = string }
