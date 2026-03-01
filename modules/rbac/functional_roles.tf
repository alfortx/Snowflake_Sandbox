# =============================================================================
# 機能的ロール（FR_*）定義 + SYSADMIN継承 + 権限マトリクス①
# =============================================================================

# =============================================================================
# ① FR_ ロールの作成（13個）
# =============================================================================

resource "snowflake_account_role" "fr_wh_sandbox_operate" {
  provider = snowflake.securityadmin
  name     = var.fr_wh_sandbox_operate_role_name
  comment  = "SANDBOX_WH の USAGE + OPERATE 権限"
}

resource "snowflake_account_role" "fr_wh_sandbox_use" {
  provider = snowflake.securityadmin
  name     = var.fr_wh_sandbox_use_role_name
  comment  = "SANDBOX_WH の USAGE 権限のみ"
}

resource "snowflake_account_role" "fr_wh_mv_operate" {
  provider = snowflake.securityadmin
  name     = var.fr_wh_mv_operate_role_name
  comment  = "MV_WH の USAGE + OPERATE 権限"
}

resource "snowflake_account_role" "fr_wh_mv_use" {
  provider = snowflake.securityadmin
  name     = var.fr_wh_mv_use_role_name
  comment  = "MV_WH の USAGE 権限のみ"
}

resource "snowflake_account_role" "fr_sandbox_work_write" {
  provider = snowflake.securityadmin
  name     = var.fr_sandbox_work_write_role_name
  comment  = "SANDBOX_DB.WORK への読み書き権限（EXTERNAL_S3_STAGE 含む）"
}

resource "snowflake_account_role" "fr_sandbox_work_read" {
  provider = snowflake.securityadmin
  name     = var.fr_sandbox_work_read_role_name
  comment  = "SANDBOX_DB.WORK への読み取り権限"
}

resource "snowflake_account_role" "fr_raw_covid19_write" {
  provider = snowflake.securityadmin
  name     = var.fr_raw_covid19_write_role_name
  comment  = "RAW_DB.COVID19 への読み書き権限"
}

resource "snowflake_account_role" "fr_raw_covid19_read" {
  provider = snowflake.securityadmin
  name     = var.fr_raw_covid19_read_role_name
  comment  = "RAW_DB.COVID19 への読み取り権限"
}

resource "snowflake_account_role" "fr_budget_book_write" {
  provider = snowflake.securityadmin
  name     = var.fr_budget_book_write_role_name
  comment  = "RAW_DB.BUDGET_BOOK への読み書き権限"
}

resource "snowflake_account_role" "fr_budget_book_read" {
  provider = snowflake.securityadmin
  name     = var.fr_budget_book_read_role_name
  comment  = "RAW_DB.BUDGET_BOOK への読み取り権限"
}

resource "snowflake_account_role" "fr_cortex_admin" {
  provider = snowflake.securityadmin
  name     = var.fr_cortex_admin_role_name
  comment  = "Cortex Search Service作成・YAMLファイル更新が可能な管理者ロール"
}

resource "snowflake_account_role" "fr_cortex_use" {
  provider = snowflake.securityadmin
  name     = var.fr_cortex_use_role_name
  comment  = "既存Cortexリソース（Agent/Search/SemanticView）の利用権限"
}

resource "snowflake_account_role" "fr_managed_access_test" {
  provider = snowflake.securityadmin
  name     = var.fr_managed_access_test_role_name
  comment  = "MANAGED_ACCESS_DB のテスト用権限"
}

# =============================================================================
# ② 全カスタムロール → SYSADMIN への継承
# =============================================================================

resource "snowflake_grant_account_role" "fr_wh_sandbox_operate_to_sysadmin" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_wh_sandbox_operate.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_wh_sandbox_use_to_sysadmin" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_wh_sandbox_use.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_wh_mv_operate_to_sysadmin" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_wh_mv_operate.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_wh_mv_use_to_sysadmin" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_wh_mv_use.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_sandbox_work_write_to_sysadmin" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_sandbox_work_write.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_sandbox_work_read_to_sysadmin" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_sandbox_work_read.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_raw_covid19_write_to_sysadmin" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_raw_covid19_write.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_raw_covid19_read_to_sysadmin" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_raw_covid19_read.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_budget_book_write_to_sysadmin" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_budget_book_write.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_budget_book_read_to_sysadmin" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_budget_book_read.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_cortex_admin_to_sysadmin" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_cortex_admin.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_cortex_use_to_sysadmin" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_cortex_use.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_managed_access_test_to_sysadmin" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_managed_access_test.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "developer_role_to_sysadmin" {
  provider         = snowflake.securityadmin
  role_name        = var.developer_role_name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "viewer_role_to_sysadmin" {
  provider         = snowflake.securityadmin
  role_name        = var.viewer_role_name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "schema_owner_role_to_sysadmin" {
  provider         = snowflake.securityadmin
  role_name        = var.schema_owner_role_name
  parent_role_name = "SYSADMIN"
}

# =============================================================================
# ③ マトリクス①: FR_ ロールへのオブジェクト権限付与
# =============================================================================

# --- FR_WH_SANDBOX_OPERATE ---
resource "snowflake_grant_privileges_to_account_role" "fr_wh_sandbox_operate_grant" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_wh_sandbox_operate.name
  privileges        = ["USAGE", "OPERATE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = var.sandbox_wh_name
  }
}

# --- FR_WH_SANDBOX_USE ---
resource "snowflake_grant_privileges_to_account_role" "fr_wh_sandbox_use_grant" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_wh_sandbox_use.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = var.sandbox_wh_name
  }
}

# --- FR_WH_MV_OPERATE ---
resource "snowflake_grant_privileges_to_account_role" "fr_wh_mv_operate_grant" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_wh_mv_operate.name
  privileges        = ["USAGE", "OPERATE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = var.mv_wh_name
  }
}

# --- FR_WH_MV_USE ---
resource "snowflake_grant_privileges_to_account_role" "fr_wh_mv_use_grant" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_wh_mv_use.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = var.mv_wh_name
  }
}

# --- FR_SANDBOX_WORK_WRITE ---
resource "snowflake_grant_privileges_to_account_role" "fr_sandbox_work_write_db" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_sandbox_work_write.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = var.sandbox_db_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_sandbox_work_write_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_sandbox_work_write.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW"]
  on_schema {
    schema_name = "\"${var.sandbox_db_name}\".\"${var.work_schema_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_sandbox_work_write_future_tables" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_sandbox_work_write.name
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE"]
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${var.sandbox_db_name}\".\"${var.work_schema_name}\""
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_sandbox_work_write_stage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_sandbox_work_write.name
  privileges        = ["USAGE"]
  on_schema_object {
    object_type = "STAGE"
    object_name = "\"${var.external_s3_stage_database}\".\"${var.external_s3_stage_schema}\".\"${var.external_s3_stage_name}\""
  }
}

# --- FR_SANDBOX_WORK_READ ---
resource "snowflake_grant_privileges_to_account_role" "fr_sandbox_work_read_db" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_sandbox_work_read.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = var.sandbox_db_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_sandbox_work_read_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_sandbox_work_read.name
  privileges        = ["USAGE"]
  on_schema {
    schema_name = "\"${var.sandbox_db_name}\".\"${var.work_schema_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_sandbox_work_read_future_tables" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_sandbox_work_read.name
  privileges        = ["SELECT"]
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${var.sandbox_db_name}\".\"${var.work_schema_name}\""
    }
  }
}

# --- FR_RAW_COVID19_WRITE ---
resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_write_db" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_write.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = var.raw_db_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_write_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_write.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW"]
  on_schema {
    schema_name = "\"${var.raw_db_name}\".\"${var.covid19_schema_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_write_future_tables" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_write.name
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE"]
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${var.raw_db_name}\".\"${var.covid19_schema_name}\""
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_write_jhu_stage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_write.name
  privileges        = ["USAGE"]
  on_schema_object {
    object_type = "STAGE"
    object_name = "\"${var.raw_db_name}\".\"${var.covid19_schema_name}\".\"${var.covid19_s3_stage_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_write_world_testing_stage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_write.name
  privileges        = ["USAGE"]
  on_schema_object {
    object_type = "STAGE"
    object_name = "\"${var.raw_db_name}\".\"${var.covid19_schema_name}\".\"${var.covid19_world_testing_stage_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_write_ext_jhu" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_write.name
  privileges        = ["SELECT"]
  on_schema_object {
    object_type = "EXTERNAL TABLE"
    object_name = "\"${var.raw_db_name}\".\"${var.covid19_schema_name}\".\"${var.ext_jhu_timeseries_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_write_ext_world_testing" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_write.name
  privileges        = ["SELECT"]
  on_schema_object {
    object_type = "EXTERNAL TABLE"
    object_name = "\"${var.raw_db_name}\".\"${var.covid19_schema_name}\".\"${var.ext_covid19_world_testing_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_write_mv_jhu" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_write.name
  privileges        = ["SELECT"]
  on_schema_object {
    object_type = "MATERIALIZED VIEW"
    object_name = "\"${var.raw_db_name}\".\"${var.covid19_schema_name}\".\"${var.mv_jhu_timeseries_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_write_mv_world_testing" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_write.name
  privileges        = ["SELECT"]
  on_schema_object {
    object_type = "MATERIALIZED VIEW"
    object_name = "\"${var.raw_db_name}\".\"${var.covid19_schema_name}\".\"${var.mv_covid19_world_testing_name}\""
  }
}

# --- FR_RAW_COVID19_READ ---
resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_read_db" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_read.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = var.raw_db_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_read_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_read.name
  privileges        = ["USAGE"]
  on_schema {
    schema_name = "\"${var.raw_db_name}\".\"${var.covid19_schema_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_read_future_tables" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_read.name
  privileges        = ["SELECT"]
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${var.raw_db_name}\".\"${var.covid19_schema_name}\""
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_read_jhu_stage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_read.name
  privileges        = ["USAGE"]
  on_schema_object {
    object_type = "STAGE"
    object_name = "\"${var.raw_db_name}\".\"${var.covid19_schema_name}\".\"${var.covid19_s3_stage_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_read_world_testing_stage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_read.name
  privileges        = ["USAGE"]
  on_schema_object {
    object_type = "STAGE"
    object_name = "\"${var.raw_db_name}\".\"${var.covid19_schema_name}\".\"${var.covid19_world_testing_stage_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_read_ext_jhu" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_read.name
  privileges        = ["SELECT"]
  on_schema_object {
    object_type = "EXTERNAL TABLE"
    object_name = "\"${var.raw_db_name}\".\"${var.covid19_schema_name}\".\"${var.ext_jhu_timeseries_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_read_ext_world_testing" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_read.name
  privileges        = ["SELECT"]
  on_schema_object {
    object_type = "EXTERNAL TABLE"
    object_name = "\"${var.raw_db_name}\".\"${var.covid19_schema_name}\".\"${var.ext_covid19_world_testing_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_read_mv_jhu" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_read.name
  privileges        = ["SELECT"]
  on_schema_object {
    object_type = "MATERIALIZED VIEW"
    object_name = "\"${var.raw_db_name}\".\"${var.covid19_schema_name}\".\"${var.mv_jhu_timeseries_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_read_mv_world_testing" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_read.name
  privileges        = ["SELECT"]
  on_schema_object {
    object_type = "MATERIALIZED VIEW"
    object_name = "\"${var.raw_db_name}\".\"${var.covid19_schema_name}\".\"${var.mv_covid19_world_testing_name}\""
  }
}

# --- FR_BUDGET_BOOK_WRITE ---
resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_write_db" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_write.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = var.raw_db_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_write_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_write.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW", "CREATE STAGE"]
  on_schema {
    schema_name = "\"${var.raw_db_name}\".\"${var.budget_book_schema_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_write_transactions" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_write.name
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]
  on_schema_object {
    object_type = "TABLE"
    object_name = "\"${var.raw_db_name}\".\"${var.budget_book_schema_name}\".\"${var.budget_book_transactions_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_write_future_tables" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_write.name
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${var.raw_db_name}\".\"${var.budget_book_schema_name}\""
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_write_stage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_write.name
  privileges        = ["READ", "WRITE"]
  on_schema_object {
    object_type = "STAGE"
    object_name = "\"${var.raw_db_name}\".\"${var.budget_book_schema_name}\".\"${var.budget_book_stage_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_write_file_format" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_write.name
  privileges        = ["USAGE"]
  on_schema_object {
    object_type = "FILE FORMAT"
    object_name = "\"${var.raw_db_name}\".\"${var.budget_book_schema_name}\".\"${var.budget_book_csv_format_name}\""
  }
}

# --- FR_BUDGET_BOOK_READ ---
resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_read_db" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_read.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = var.raw_db_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_read_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_read.name
  privileges        = ["USAGE"]
  on_schema {
    schema_name = "\"${var.raw_db_name}\".\"${var.budget_book_schema_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_read_transactions" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_read.name
  privileges        = ["SELECT"]
  on_schema_object {
    object_type = "TABLE"
    object_name = "\"${var.raw_db_name}\".\"${var.budget_book_schema_name}\".\"${var.budget_book_transactions_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_read_future_tables" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_read.name
  privileges        = ["SELECT"]
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${var.raw_db_name}\".\"${var.budget_book_schema_name}\""
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_read_stage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_read.name
  privileges        = ["READ"]
  on_schema_object {
    object_type = "STAGE"
    object_name = "\"${var.raw_db_name}\".\"${var.budget_book_schema_name}\".\"${var.budget_book_stage_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_read_file_format" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_read.name
  privileges        = ["USAGE"]
  on_schema_object {
    object_type = "FILE FORMAT"
    object_name = "\"${var.raw_db_name}\".\"${var.budget_book_schema_name}\".\"${var.budget_book_csv_format_name}\""
  }
}

# --- FR_CORTEX_ADMIN ---
resource "snowflake_grant_privileges_to_account_role" "fr_cortex_admin_db" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_cortex_admin.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = var.cortex_db_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_cortex_admin_semantic_models_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_cortex_admin.name
  privileges        = ["USAGE"]
  on_schema {
    schema_name = "\"${var.cortex_db_name}\".\"${var.semantic_models_schema_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_cortex_admin_search_services_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_cortex_admin.name
  privileges        = ["USAGE", "CREATE CORTEX SEARCH SERVICE"]
  on_schema {
    schema_name = "\"${var.cortex_db_name}\".\"${var.search_services_schema_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_cortex_admin_agents_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_cortex_admin.name
  privileges        = ["USAGE"]
  on_schema {
    schema_name = "\"${var.cortex_db_name}\".\"${var.agents_schema_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_cortex_admin_stage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_cortex_admin.name
  privileges        = ["READ", "WRITE"]
  on_schema_object {
    object_type = "STAGE"
    object_name = "\"${var.semantic_model_stage_database}\".\"${var.semantic_model_stage_schema}\".\"${var.semantic_model_stage_name}\""
  }
}

resource "snowflake_grant_database_role" "fr_cortex_admin_cortex_user" {
  provider           = snowflake.accountadmin
  database_role_name = "\"SNOWFLAKE\".\"CORTEX_USER\""
  parent_role_name   = snowflake_account_role.fr_cortex_admin.name
}

resource "snowflake_grant_database_role" "fr_cortex_admin_cortex_agent_user" {
  provider           = snowflake.accountadmin
  database_role_name = "\"SNOWFLAKE\".\"CORTEX_AGENT_USER\""
  parent_role_name   = snowflake_account_role.fr_cortex_admin.name
}

# --- FR_CORTEX_USE ---
resource "snowflake_grant_privileges_to_account_role" "fr_cortex_use_db" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_cortex_use.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = var.cortex_db_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_cortex_use_semantic_models_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_cortex_use.name
  privileges        = ["USAGE"]
  on_schema {
    schema_name = "\"${var.cortex_db_name}\".\"${var.semantic_models_schema_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_cortex_use_search_services_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_cortex_use.name
  privileges        = ["USAGE"]
  on_schema {
    schema_name = "\"${var.cortex_db_name}\".\"${var.search_services_schema_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_cortex_use_agents_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_cortex_use.name
  privileges        = ["USAGE"]
  on_schema {
    schema_name = "\"${var.cortex_db_name}\".\"${var.agents_schema_name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_cortex_use_stage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_cortex_use.name
  privileges        = ["READ"]
  on_schema_object {
    object_type = "STAGE"
    object_name = "\"${var.semantic_model_stage_database}\".\"${var.semantic_model_stage_schema}\".\"${var.semantic_model_stage_name}\""
  }
}

resource "snowflake_grant_database_role" "fr_cortex_use_cortex_user" {
  provider           = snowflake.accountadmin
  database_role_name = "\"SNOWFLAKE\".\"CORTEX_USER\""
  parent_role_name   = snowflake_account_role.fr_cortex_use.name
}

resource "snowflake_grant_database_role" "fr_cortex_use_cortex_agent_user" {
  provider           = snowflake.accountadmin
  database_role_name = "\"SNOWFLAKE\".\"CORTEX_AGENT_USER\""
  parent_role_name   = snowflake_account_role.fr_cortex_use.name
}

# --- FR_MANAGED_ACCESS_TEST ---
resource "snowflake_grant_privileges_to_account_role" "fr_managed_access_test_db" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_managed_access_test.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = var.managed_access_db_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_managed_access_test_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_managed_access_test.name
  privileges        = ["USAGE", "CREATE TABLE"]
  on_schema {
    schema_name = "\"${var.managed_access_db_name}\".\"${var.managed_schema_name}\""
  }
}
