# =============================================================================
# developer モジュール: DEVELOPER_DB + WORK スキーマ
# =============================================================================

resource "snowflake_database" "developer" {
  provider = snowflake.sysadmin
  name     = var.developer_db_name
  comment  = "開発者作業用データベース"
}

resource "snowflake_schema" "work" {
  provider = snowflake.sysadmin
  database = snowflake_database.developer.name
  name     = var.developer_work_schema_name
  comment  = "開発者作業用スキーマ"
}
