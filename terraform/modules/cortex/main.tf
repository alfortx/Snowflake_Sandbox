# =============================================================================
# Cortex 基盤リソース
#
# 構成:
#   CORTEX_DB
#   ├── SEMANTIC_MODELS スキーマ
#   │   └── SEMANTIC_MODEL_FILES ステージ
#   ├── SEARCH_SERVICES スキーマ
#   └── AGENTS スキーマ  ← Cortex Agent の配置先
#
# アカウントパラメータ（クロスリージョン推論）も本モジュールで管理
# =============================================================================

resource "snowflake_database" "cortex" {
  provider = snowflake.sysadmin

  name    = var.cortex_db_name
  comment = "Cortex Analyst・Cortex Search のリソースを管理するデータベース"
}

resource "snowflake_schema" "semantic_models" {
  provider = snowflake.sysadmin

  database = snowflake_database.cortex.name
  name     = var.cortex_analyst_schema_name
  comment  = "Cortex Analyst 用セマンティックモデル（YAML）を管理するスキーマ"
}

resource "snowflake_schema" "search_services" {
  provider = snowflake.sysadmin

  database = snowflake_database.cortex.name
  name     = var.cortex_search_schema_name
  comment  = "Cortex Search サービスを管理するスキーマ"
}

resource "snowflake_stage" "semantic_model_files" {
  provider = snowflake.sysadmin

  name      = var.semantic_model_stage_name
  database  = snowflake_database.cortex.name
  schema    = snowflake_schema.semantic_models.name
  comment   = "Cortex Analyst 用セマンティックモデル YAML ファイルを格納する内部ステージ"
  directory = "ENABLE = true"
}

# AGENTS スキーマ: Cortex Agent の配置先（intelligence.tf から移動）
resource "snowflake_schema" "agents" {
  provider = snowflake.sysadmin

  database = snowflake_database.cortex.name
  name     = var.cortex_agents_schema_name
  comment  = "Cortex Agent 配置スキーマ（Snowflake Intelligence 連携）"
}

# =============================================================================
# アカウントレベルのパラメータ設定
# Cortex クロスリージョン推論の有効化
# =============================================================================
resource "snowflake_current_account" "account" {
  provider = snowflake.accountadmin

  cortex_enabled_cross_region = "ANY_REGION"
}
