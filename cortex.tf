# =============================================================================
# Cortex リソース
#
# 構成概要:
#   CORTEX_DB
#   ├── SEMANTIC_MODELS スキーマ  ← Cortex Analyst のセマンティックモデル配置先
#   │   └── SEMANTIC_MODEL_FILES ステージ（YAMLファイル格納用）
#   └── SEARCH_SERVICES スキーマ  ← Cortex Search サービス配置先
#
#   CORTEX_ROLE ← 上記リソースの配置・変更・利用権限を持つロール
#     - SNOWFLAKE.CORTEX_USER DB ロール（Cortex ML 関数の使用権限）
#     - CORTEX_DB 以下への各種権限
#     - SANDBOX_WH の使用権限
#   sandbox_user に CORTEX_ROLE を付与
# =============================================================================

# -----------------------------------------------------------------------------
# Database: Cortex 関連リソースの格納先
# -----------------------------------------------------------------------------
resource "snowflake_database" "cortex" {
  provider = snowflake.sysadmin

  name    = var.cortex_db_name
  comment = "Cortex Analyst・Cortex Search のリソースを管理するデータベース"
}

# -----------------------------------------------------------------------------
# Schema: Cortex Analyst セマンティックモデル配置先
# -----------------------------------------------------------------------------
resource "snowflake_schema" "semantic_models" {
  provider = snowflake.sysadmin

  database = snowflake_database.cortex.name
  name     = var.cortex_analyst_schema_name
  comment  = "Cortex Analyst 用セマンティックモデル（YAML）を管理するスキーマ"
}

# -----------------------------------------------------------------------------
# Schema: Cortex Search サービス配置先
# -----------------------------------------------------------------------------
resource "snowflake_schema" "search_services" {
  provider = snowflake.sysadmin

  database = snowflake_database.cortex.name
  name     = var.cortex_search_schema_name
  comment  = "Cortex Search サービスを管理するスキーマ"
}

# -----------------------------------------------------------------------------
# Internal Stage: セマンティックモデルの YAML ファイル格納先
#   Cortex Analyst はこのステージに置いた YAML を読み込んでクエリを解釈する
# -----------------------------------------------------------------------------
resource "snowflake_stage" "semantic_model_files" {
  provider = snowflake.sysadmin

  name             = var.semantic_model_stage_name
  database         = snowflake_database.cortex.name
  schema           = snowflake_schema.semantic_models.name
  comment          = "Cortex Analyst 用セマンティックモデル YAML ファイルを格納する内部ステージ"
  directory        = "ENABLE = true"
}

# -----------------------------------------------------------------------------
# Role: Cortex リソースの操作権限を持つロール
# -----------------------------------------------------------------------------
resource "snowflake_account_role" "cortex_role" {
  provider = snowflake.securityadmin

  name    = var.cortex_role_name
  comment = "Cortex Analyst・Cortex Search のリソースを配置・変更・利用できるロール"
}

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# CORTEX_ROLE を sandbox_user に付与
# -----------------------------------------------------------------------------
resource "snowflake_grant_account_role" "cortex_role_to_user" {
  provider  = snowflake.securityadmin
  role_name = snowflake_account_role.cortex_role.name
  user_name = snowflake_user.sandbox_user.name
}
