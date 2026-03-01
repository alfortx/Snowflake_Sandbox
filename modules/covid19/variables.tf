variable "sandbox_wh_name" {
  description = "SANDBOX_WH 名（Agent の execution_environment に使用）"
  type        = string
}

variable "cortex_db_name" {
  description = "Cortex リソースを配置するデータベース名"
  type        = string
}

variable "semantic_models_schema_name" {
  description = "Semantic View を配置するスキーマ名"
  type        = string
}

variable "agents_schema_name" {
  description = "Cortex Agent を配置するスキーマ名"
  type        = string
}

variable "semantic_view_name" {
  description = "COVID19 セマンティックビュー名"
  type        = string
}

variable "agent_name" {
  description = "COVID19 Cortex Agent 名"
  type        = string
}

variable "fr_cortex_admin_role_name" {
  description = "Cortex Admin 機能的ロール名"
  type        = string
}

variable "fr_cortex_use_role_name" {
  description = "Cortex Use 機能的ロール名"
  type        = string
}
