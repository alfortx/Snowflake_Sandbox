# =============================================================================
# 機能的ロール（FR_*）定義
#
# 設計方針（Snowflake RBAC ベストプラクティス）:
#   機能的ロール（FR_*）  … オブジェクト権限を保持（ユーザーには直接付与しない）
#   役割ロール（DEVELOPER/VIEWER/CORTEX）… FR_* を束ねてユーザーに付与
#   全カスタムロール → SYSADMIN に継承（透過的な権限管理）
#
# 権限マトリクスは docs/rbac_matrix.md を参照
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
# ② 全カスタムロール → SYSADMIN への継承（17個）
#    SYSADMIN が全権限を透過的に把握・管理できるようにする
# =============================================================================

# --- FR_ ロール 13個 ---
resource "snowflake_grant_account_role" "fr_wh_sandbox_operate_to_sysadmin" {
  provider  = snowflake.securityadmin
  role_name = snowflake_account_role.fr_wh_sandbox_operate.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_wh_sandbox_use_to_sysadmin" {
  provider  = snowflake.securityadmin
  role_name = snowflake_account_role.fr_wh_sandbox_use.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_wh_mv_operate_to_sysadmin" {
  provider  = snowflake.securityadmin
  role_name = snowflake_account_role.fr_wh_mv_operate.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_wh_mv_use_to_sysadmin" {
  provider  = snowflake.securityadmin
  role_name = snowflake_account_role.fr_wh_mv_use.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_sandbox_work_write_to_sysadmin" {
  provider  = snowflake.securityadmin
  role_name = snowflake_account_role.fr_sandbox_work_write.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_sandbox_work_read_to_sysadmin" {
  provider  = snowflake.securityadmin
  role_name = snowflake_account_role.fr_sandbox_work_read.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_raw_covid19_write_to_sysadmin" {
  provider  = snowflake.securityadmin
  role_name = snowflake_account_role.fr_raw_covid19_write.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_raw_covid19_read_to_sysadmin" {
  provider  = snowflake.securityadmin
  role_name = snowflake_account_role.fr_raw_covid19_read.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_budget_book_write_to_sysadmin" {
  provider  = snowflake.securityadmin
  role_name = snowflake_account_role.fr_budget_book_write.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_budget_book_read_to_sysadmin" {
  provider  = snowflake.securityadmin
  role_name = snowflake_account_role.fr_budget_book_read.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_cortex_admin_to_sysadmin" {
  provider  = snowflake.securityadmin
  role_name = snowflake_account_role.fr_cortex_admin.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_cortex_use_to_sysadmin" {
  provider  = snowflake.securityadmin
  role_name = snowflake_account_role.fr_cortex_use.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fr_managed_access_test_to_sysadmin" {
  provider  = snowflake.securityadmin
  role_name = snowflake_account_role.fr_managed_access_test.name
  parent_role_name = "SYSADMIN"
}

# --- 役割ロール 4個 ---
resource "snowflake_grant_account_role" "developer_role_to_sysadmin" {
  provider  = snowflake.securityadmin
  role_name = snowflake_account_role.developer_role.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "viewer_role_to_sysadmin" {
  provider  = snowflake.securityadmin
  role_name = snowflake_account_role.viewer_role.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "cortex_role_to_sysadmin" {
  provider  = snowflake.securityadmin
  role_name = snowflake_account_role.cortex_role.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "schema_owner_role_to_sysadmin" {
  provider  = snowflake.securityadmin
  role_name = snowflake_account_role.schema_owner_role.name
  parent_role_name = "SYSADMIN"
}

# =============================================================================
# ③ マトリクス①: FR_ ロールへのオブジェクト権限付与
# =============================================================================

# -----------------------------------------------------------------------------
# FR_WH_SANDBOX_OPERATE: SANDBOX_WH USAGE + OPERATE
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "fr_wh_sandbox_operate_grant" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_wh_sandbox_operate.name
  privileges        = ["USAGE", "OPERATE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.sandbox.name
  }
}

# -----------------------------------------------------------------------------
# FR_WH_SANDBOX_USE: SANDBOX_WH USAGE のみ
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "fr_wh_sandbox_use_grant" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_wh_sandbox_use.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.sandbox.name
  }
}

# -----------------------------------------------------------------------------
# FR_WH_MV_OPERATE: MV_WH USAGE + OPERATE
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "fr_wh_mv_operate_grant" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_wh_mv_operate.name
  privileges        = ["USAGE", "OPERATE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.mv_wh.name
  }
}

# -----------------------------------------------------------------------------
# FR_WH_MV_USE: MV_WH USAGE のみ
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "fr_wh_mv_use_grant" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_wh_mv_use.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.mv_wh.name
  }
}

# -----------------------------------------------------------------------------
# FR_SANDBOX_WORK_WRITE: SANDBOX_DB + WORK スキーマ + future tables + EXTERNAL_S3_STAGE
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "fr_sandbox_work_write_db" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_sandbox_work_write.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.sandbox.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_sandbox_work_write_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_sandbox_work_write.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW"]

  on_schema {
    schema_name = "\"${snowflake_database.sandbox.name}\".\"${snowflake_schema.work.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_sandbox_work_write_future_tables" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_sandbox_work_write.name
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${snowflake_database.sandbox.name}\".\"${snowflake_schema.work.name}\""
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_sandbox_work_write_stage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_sandbox_work_write.name
  privileges        = ["USAGE"]

  on_schema_object {
    object_type = "STAGE"
    object_name = "\"${snowflake_stage.external_s3.database}\".\"${snowflake_stage.external_s3.schema}\".\"${snowflake_stage.external_s3.name}\""
  }
}

# -----------------------------------------------------------------------------
# FR_SANDBOX_WORK_READ: SANDBOX_DB + WORK スキーマ + future tables
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "fr_sandbox_work_read_db" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_sandbox_work_read.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.sandbox.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_sandbox_work_read_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_sandbox_work_read.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "\"${snowflake_database.sandbox.name}\".\"${snowflake_schema.work.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_sandbox_work_read_future_tables" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_sandbox_work_read.name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${snowflake_database.sandbox.name}\".\"${snowflake_schema.work.name}\""
    }
  }
}

# -----------------------------------------------------------------------------
# FR_RAW_COVID19_WRITE: RAW_DB + COVID19 スキーマ + ステージ + 外部テーブル + MV
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_write_db" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_write.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.raw_db.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_write_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_write.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW"]

  on_schema {
    schema_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_write_future_tables" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_write.name
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\""
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_write_jhu_stage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_write.name
  privileges        = ["USAGE"]

  on_schema_object {
    object_type = "STAGE"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_stage.covid19_s3_stage.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_write_world_testing_stage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_write.name
  privileges        = ["USAGE"]

  on_schema_object {
    object_type = "STAGE"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_stage.covid19_world_testing_stage.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_write_ext_jhu" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_write.name
  privileges        = ["SELECT"]

  on_schema_object {
    object_type = "EXTERNAL TABLE"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_external_table.ext_jhu_timeseries.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_write_ext_world_testing" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_write.name
  privileges        = ["SELECT"]

  on_schema_object {
    object_type = "EXTERNAL TABLE"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_external_table.ext_covid19_world_testing.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_write_mv_jhu" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_write.name
  privileges        = ["SELECT"]

  on_schema_object {
    object_type = "MATERIALIZED VIEW"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_materialized_view.mv_jhu_timeseries.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_write_mv_world_testing" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_write.name
  privileges        = ["SELECT"]

  on_schema_object {
    object_type = "MATERIALIZED VIEW"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_materialized_view.mv_covid19_world_testing.name}\""
  }
}

# -----------------------------------------------------------------------------
# FR_RAW_COVID19_READ: RAW_DB + COVID19 スキーマ + ステージ + 外部テーブル + MV (READ)
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_read_db" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_read.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.raw_db.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_read_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_read.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_read_future_tables" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_read.name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\""
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_read_jhu_stage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_read.name
  privileges        = ["USAGE"]

  on_schema_object {
    object_type = "STAGE"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_stage.covid19_s3_stage.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_read_world_testing_stage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_read.name
  privileges        = ["USAGE"]

  on_schema_object {
    object_type = "STAGE"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_stage.covid19_world_testing_stage.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_read_ext_jhu" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_read.name
  privileges        = ["SELECT"]

  on_schema_object {
    object_type = "EXTERNAL TABLE"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_external_table.ext_jhu_timeseries.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_read_ext_world_testing" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_read.name
  privileges        = ["SELECT"]

  on_schema_object {
    object_type = "EXTERNAL TABLE"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_external_table.ext_covid19_world_testing.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_read_mv_jhu" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_read.name
  privileges        = ["SELECT"]

  on_schema_object {
    object_type = "MATERIALIZED VIEW"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_materialized_view.mv_jhu_timeseries.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_raw_covid19_read_mv_world_testing" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_raw_covid19_read.name
  privileges        = ["SELECT"]

  on_schema_object {
    object_type = "MATERIALIZED VIEW"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_materialized_view.mv_covid19_world_testing.name}\""
  }
}

# -----------------------------------------------------------------------------
# FR_BUDGET_BOOK_WRITE: RAW_DB + BUDGET_BOOK スキーマ + テーブル + ステージ + ファイルフォーマット
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_write_db" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_write.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.raw_db.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_write_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_write.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW", "CREATE STAGE"]

  on_schema {
    schema_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.budget_book.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_write_transactions" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_write.name
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]

  on_schema_object {
    object_type = "TABLE"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.budget_book.name}\".\"${snowflake_table.budget_book_transactions.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_write_future_tables" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_write.name
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.budget_book.name}\""
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_write_stage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_write.name
  privileges        = ["READ", "WRITE"]

  on_schema_object {
    object_type = "STAGE"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.budget_book.name}\".\"${snowflake_stage.budget_book_stage.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_write_file_format" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_write.name
  privileges        = ["USAGE"]

  on_schema_object {
    object_type = "FILE FORMAT"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.budget_book.name}\".\"${snowflake_file_format.budget_book_csv_format.name}\""
  }
}

# -----------------------------------------------------------------------------
# FR_BUDGET_BOOK_READ: RAW_DB + BUDGET_BOOK スキーマ + テーブル + ステージ + ファイルフォーマット (READ)
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_read_db" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_read.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.raw_db.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_read_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_read.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.budget_book.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_read_transactions" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_read.name
  privileges        = ["SELECT"]

  on_schema_object {
    object_type = "TABLE"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.budget_book.name}\".\"${snowflake_table.budget_book_transactions.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_read_future_tables" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_read.name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.budget_book.name}\""
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_read_stage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_read.name
  privileges        = ["READ"]

  on_schema_object {
    object_type = "STAGE"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.budget_book.name}\".\"${snowflake_stage.budget_book_stage.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_budget_book_read_file_format" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_budget_book_read.name
  privileges        = ["USAGE"]

  on_schema_object {
    object_type = "FILE FORMAT"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.budget_book.name}\".\"${snowflake_file_format.budget_book_csv_format.name}\""
  }
}

# -----------------------------------------------------------------------------
# FR_CORTEX_ADMIN: CORTEX_DB 全スキーマ + ステージ WRITE + CREATE CORTEX SEARCH SERVICE
#                  + SNOWFLAKE DB ロール
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "fr_cortex_admin_db" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_cortex_admin.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.cortex.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_cortex_admin_semantic_models_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_cortex_admin.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "\"${snowflake_database.cortex.name}\".\"${snowflake_schema.semantic_models.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_cortex_admin_search_services_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_cortex_admin.name
  privileges        = ["USAGE", "CREATE CORTEX SEARCH SERVICE"]

  on_schema {
    schema_name = "\"${snowflake_database.cortex.name}\".\"${snowflake_schema.search_services.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_cortex_admin_agents_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_cortex_admin.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "\"${snowflake_database.cortex.name}\".\"${snowflake_schema.agents.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_cortex_admin_stage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_cortex_admin.name
  privileges        = ["READ", "WRITE"]

  on_schema_object {
    object_type = "STAGE"
    object_name = "\"${snowflake_stage.semantic_model_files.database}\".\"${snowflake_stage.semantic_model_files.schema}\".\"${snowflake_stage.semantic_model_files.name}\""
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

# -----------------------------------------------------------------------------
# FR_CORTEX_USE: CORTEX_DB 全スキーマ + ステージ READ + SNOWFLAKE DB ロール
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "fr_cortex_use_db" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_cortex_use.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.cortex.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_cortex_use_semantic_models_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_cortex_use.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "\"${snowflake_database.cortex.name}\".\"${snowflake_schema.semantic_models.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_cortex_use_search_services_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_cortex_use.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "\"${snowflake_database.cortex.name}\".\"${snowflake_schema.search_services.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_cortex_use_agents_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_cortex_use.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "\"${snowflake_database.cortex.name}\".\"${snowflake_schema.agents.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_cortex_use_stage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_cortex_use.name
  privileges        = ["READ"]

  on_schema_object {
    object_type = "STAGE"
    object_name = "\"${snowflake_stage.semantic_model_files.database}\".\"${snowflake_stage.semantic_model_files.schema}\".\"${snowflake_stage.semantic_model_files.name}\""
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

# -----------------------------------------------------------------------------
# FR_MANAGED_ACCESS_TEST: MANAGED_ACCESS_DB + MANAGED_SCHEMA
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "fr_managed_access_test_db" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_managed_access_test.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.managed_access.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "fr_managed_access_test_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.fr_managed_access_test.name
  privileges        = ["USAGE", "CREATE TABLE"]

  depends_on = [snowflake_grant_ownership.managed_schema_to_schema_owner]

  on_schema {
    schema_name = "\"${snowflake_database.managed_access.name}\".\"${snowflake_schema.managed.name}\""
  }
}

# =============================================================================
# ④ マトリクス②: 役割ロールが FR_ ロールを継承
# =============================================================================

# --- DEVELOPER_ROLE が継承する FR_ ロール ---
resource "snowflake_grant_account_role" "developer_inherits_wh_sandbox_operate" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_wh_sandbox_operate.name
  parent_role_name = snowflake_account_role.developer_role.name
}

resource "snowflake_grant_account_role" "developer_inherits_wh_mv_operate" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_wh_mv_operate.name
  parent_role_name = snowflake_account_role.developer_role.name
}

resource "snowflake_grant_account_role" "developer_inherits_sandbox_work_write" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_sandbox_work_write.name
  parent_role_name = snowflake_account_role.developer_role.name
}

resource "snowflake_grant_account_role" "developer_inherits_raw_covid19_write" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_raw_covid19_write.name
  parent_role_name = snowflake_account_role.developer_role.name
}

resource "snowflake_grant_account_role" "developer_inherits_budget_book_write" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_budget_book_write.name
  parent_role_name = snowflake_account_role.developer_role.name
}

resource "snowflake_grant_account_role" "developer_inherits_cortex_use" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_cortex_use.name
  parent_role_name = snowflake_account_role.developer_role.name
}

resource "snowflake_grant_account_role" "developer_inherits_managed_access_test" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_managed_access_test.name
  parent_role_name = snowflake_account_role.developer_role.name
}

# --- VIEWER_ROLE が継承する FR_ ロール ---
resource "snowflake_grant_account_role" "viewer_inherits_wh_sandbox_use" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_wh_sandbox_use.name
  parent_role_name = snowflake_account_role.viewer_role.name
}

resource "snowflake_grant_account_role" "viewer_inherits_wh_mv_use" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_wh_mv_use.name
  parent_role_name = snowflake_account_role.viewer_role.name
}

resource "snowflake_grant_account_role" "viewer_inherits_sandbox_work_read" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_sandbox_work_read.name
  parent_role_name = snowflake_account_role.viewer_role.name
}

resource "snowflake_grant_account_role" "viewer_inherits_raw_covid19_read" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_raw_covid19_read.name
  parent_role_name = snowflake_account_role.viewer_role.name
}

resource "snowflake_grant_account_role" "viewer_inherits_budget_book_read" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_budget_book_read.name
  parent_role_name = snowflake_account_role.viewer_role.name
}

resource "snowflake_grant_account_role" "viewer_inherits_cortex_use" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_cortex_use.name
  parent_role_name = snowflake_account_role.viewer_role.name
}

# --- CORTEX_ROLE が継承する FR_ ロール ---
resource "snowflake_grant_account_role" "cortex_inherits_wh_sandbox_operate" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_wh_sandbox_operate.name
  parent_role_name = snowflake_account_role.cortex_role.name
}

resource "snowflake_grant_account_role" "cortex_inherits_wh_mv_operate" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_wh_mv_operate.name
  parent_role_name = snowflake_account_role.cortex_role.name
}

resource "snowflake_grant_account_role" "cortex_inherits_raw_covid19_read" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_raw_covid19_read.name
  parent_role_name = snowflake_account_role.cortex_role.name
}

resource "snowflake_grant_account_role" "cortex_inherits_budget_book_read" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_budget_book_read.name
  parent_role_name = snowflake_account_role.cortex_role.name
}

resource "snowflake_grant_account_role" "cortex_inherits_cortex_admin" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_cortex_admin.name
  parent_role_name = snowflake_account_role.cortex_role.name
}
