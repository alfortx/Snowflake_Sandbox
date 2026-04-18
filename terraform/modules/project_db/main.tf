# =============================================================================
# project_db モジュール: Streamlit / DBT など作業物置き場
#
# 作成するリソース:
#   PROJECT_DB データベース
# =============================================================================

resource "snowflake_database" "project_db" {
  provider = snowflake.sysadmin
  name     = var.project_db_name
  comment  = "Streamlit / DBT など Snowflake オブジェクト置き場"
}
