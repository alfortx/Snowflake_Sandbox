variable "environment" {
  description = "環境名（例: sandbox, dev, prod）"
  type        = string
  default     = "sandbox"
}

variable "database_name" {
  description = "作成するデータベース名"
  type        = string
  default     = "SANDBOX_DB"
}

variable "schema_name" {
  description = "作成するスキーマ名"
  type        = string
  default     = "WORK"
}

variable "user_name" {
  description = "作成するユーザー名"
  type        = string
  default     = "sandbox_user"
}

variable "user_password" {
  description = "ユーザーのパスワード"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!" # 本番環境では必ず変更してください
}

variable "developer_role_name" {
  description = "開発者用ロール名（読み書き権限）"
  type        = string
  default     = "DEVELOPER_ROLE"
}

variable "analyst_role_name" {
  description = "分析者用ロール名（読み取り専用）"
  type        = string
  default     = "ANALYST_ROLE"
}

variable "database_comment" {
  description = "データベースのコメント"
  type        = string
  default     = "Snowflake学習用サンドボックスデータベース"
}

variable "schema_comment" {
  description = "スキーマのコメント"
  type        = string
  default     = "作業用スキーマ"
}

variable "warehouse_name" {
  description = "作成するウェアハウス名"
  type        = string
  default     = "SANDBOX_WH"
}

variable "warehouse_size" {
  description = "ウェアハウスのサイズ（X-Small, Small, Medium等）"
  type        = string
  default     = "X-Small"
}

variable "warehouse_auto_suspend" {
  description = "自動サスペンドまでの秒数（300秒=5分）"
  type        = number
  default     = 300
}

variable "warehouse_auto_resume" {
  description = "クエリ実行時に自動再開するか"
  type        = bool
  default     = true
}

variable "warehouse_comment" {
  description = "ウェアハウスのコメント"
  type        = string
  default     = "サンドボックス環境用のX-Smallウェアハウス"
}

# =============================================================================
# Managed Access テスト用変数
# =============================================================================

variable "managed_access_db_name" {
  description = "Managed Access テスト用データベース名"
  type        = string
  default     = "MANAGED_ACCESS_DB"
}

variable "schema_owner_role_name" {
  description = "Managed Accessスキーマの所有者ロール名（provider.tf の role と一致させること）"
  type        = string
  default     = "SCHEMA_OWNER_ROLE"
}

variable "managed_schema_name" {
  description = "Managed Access スキーマ名"
  type        = string
  default     = "MANAGED_SCHEMA"
}

# =============================================================================
# AWS リソース変数（外部テーブル用）
# =============================================================================

variable "s3_bucket_name" {
  description = "外部テーブルデータ用 S3 バケット名（グローバルで一意にすること）"
  type        = string
  default     = "snowflake-sandbox-external-data"
}

variable "iam_role_name" {
  description = "Snowflake S3アクセス用 IAM ロール名"
  type        = string
  default     = "snowflake-sandbox-s3-role"
}

variable "storage_integration_name" {
  description = "Snowflake Storage Integration 名（S3連携用）"
  type        = string
  default     = "SANDBOX_S3_INTEGRATION"
}

variable "stage_name" {
  description = "外部ステージ名（S3を参照するSnowflakeのステージオブジェクト）"
  type        = string
  default     = "EXTERNAL_S3_STAGE"
}

# =============================================================================
# Cortex リソース変数
# =============================================================================

variable "cortex_db_name" {
  description = "Cortex関連リソースを配置するデータベース名"
  type        = string
  default     = "CORTEX_DB"
}

variable "cortex_analyst_schema_name" {
  description = "Cortex Analytistのセマンティックモデルを配置するスキーマ名"
  type        = string
  default     = "SEMANTIC_MODELS"
}

variable "cortex_search_schema_name" {
  description = "Cortex Searchサービスを配置するスキーマ名"
  type        = string
  default     = "SEARCH_SERVICES"
}

variable "semantic_model_stage_name" {
  description = "セマンティックモデルのYAMLファイルを格納するステージ名"
  type        = string
  default     = "SEMANTIC_MODEL_FILES"
}

variable "cortex_role_name" {
  description = "Cortexリソースの配置・変更・利用権限を持つロール名"
  type        = string
  default     = "CORTEX_ROLE"
}

# =============================================================================
# Snowflake Intelligence / Cortex Agent 変数
# =============================================================================

variable "cortex_agents_schema_name" {
  description = "Cortex Agent を配置するスキーマ名"
  type        = string
  default     = "AGENTS"
}

variable "semantic_view_name" {
  description = "Cortex Agent が使用する SQL ベースのセマンティックビュー名"
  type        = string
  default     = "COVID19_SEMANTIC"
}

variable "agent_name" {
  description = "Snowflake Intelligence から呼び出す Cortex Agent 名"
  type        = string
  default     = "COVID19_AGENT"
}

# =============================================================================
# 家計簿データ変数
# =============================================================================

variable "budget_book_schema_name" {
  description = "家計簿データ用スキーマ名"
  type        = string
  default     = "BUDGET_BOOK"
}

variable "budget_book_semantic_view_name" {
  description = "家計簿用セマンティックビュー名"
  type        = string
  default     = "BUDGET_BOOK_SEMANTIC"
}

variable "budget_book_search_service_name" {
  description = "家計簿用Cortex Searchサービス名"
  type        = string
  default     = "BUDGET_BOOK_SEARCH"
}

variable "budget_book_agent_name" {
  description = "家計簿用Cortex Agent名"
  type        = string
  default     = "BUDGET_BOOK_AGENT"
}
