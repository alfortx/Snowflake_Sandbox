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

variable "viewer_role_name" {
  description = "閲覧者用ロール名（読み取り専用）"
  type        = string
  default     = "VIEWER_ROLE"
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

# =============================================================================
# 機能的ロール（FR_*）変数
# =============================================================================

variable "fr_wh_sandbox_operate_role_name" {
  description = "SANDBOX_WH USAGE+OPERATE を持つ機能的ロール名"
  type        = string
  default     = "FR_WH_SANDBOX_OPERATE"
}

variable "fr_wh_sandbox_use_role_name" {
  description = "SANDBOX_WH USAGE のみを持つ機能的ロール名"
  type        = string
  default     = "FR_WH_SANDBOX_USE"
}

variable "fr_wh_mv_operate_role_name" {
  description = "MV_WH USAGE+OPERATE を持つ機能的ロール名"
  type        = string
  default     = "FR_WH_MV_OPERATE"
}

variable "fr_wh_mv_use_role_name" {
  description = "MV_WH USAGE のみを持つ機能的ロール名"
  type        = string
  default     = "FR_WH_MV_USE"
}

variable "fr_sandbox_work_write_role_name" {
  description = "SANDBOX_DB.WORK への読み書き権限を持つ機能的ロール名"
  type        = string
  default     = "FR_SANDBOX_WORK_WRITE"
}

variable "fr_sandbox_work_read_role_name" {
  description = "SANDBOX_DB.WORK への読み取り権限を持つ機能的ロール名"
  type        = string
  default     = "FR_SANDBOX_WORK_READ"
}

variable "fr_raw_covid19_write_role_name" {
  description = "RAW_DB.COVID19 への読み書き権限を持つ機能的ロール名"
  type        = string
  default     = "FR_RAW_COVID19_WRITE"
}

variable "fr_raw_covid19_read_role_name" {
  description = "RAW_DB.COVID19 への読み取り権限を持つ機能的ロール名"
  type        = string
  default     = "FR_RAW_COVID19_READ"
}

variable "fr_budget_book_write_role_name" {
  description = "RAW_DB.BUDGET_BOOK への読み書き権限を持つ機能的ロール名"
  type        = string
  default     = "FR_BUDGET_BOOK_WRITE"
}

variable "fr_budget_book_read_role_name" {
  description = "RAW_DB.BUDGET_BOOK への読み取り権限を持つ機能的ロール名"
  type        = string
  default     = "FR_BUDGET_BOOK_READ"
}

variable "fr_cortex_admin_role_name" {
  description = "Cortex Search Service作成・YAML更新権限を持つ機能的ロール名"
  type        = string
  default     = "FR_CORTEX_ADMIN"
}

variable "fr_cortex_use_role_name" {
  description = "既存Cortexリソース（Agent/Search/SemanticView）の利用権限を持つ機能的ロール名"
  type        = string
  default     = "FR_CORTEX_USE"
}

variable "fr_managed_access_test_role_name" {
  description = "MANAGED_ACCESS_DB のテスト権限を持つ機能的ロール名"
  type        = string
  default     = "FR_MANAGED_ACCESS_TEST"
}

# =============================================================================
# DEVELOPER_DB 変数
# =============================================================================

variable "developer_db_name" {
  description = "開発者作業用データベース名"
  type        = string
  default     = "DEVELOPER_DB"
}

variable "developer_work_schema_name" {
  description = "DEVELOPER_DB の作業用スキーマ名"
  type        = string
  default     = "WORK"
}

variable "fr_developer_db_write_role_name" {
  description = "DEVELOPER_DB.WORK への読み書き権限を持つ機能的ロール名"
  type        = string
  default     = "FR_DEVELOPER_DB_WRITE"
}

variable "fr_developer_db_read_role_name" {
  description = "DEVELOPER_DB.WORK への読み取り権限を持つ機能的ロール名"
  type        = string
  default     = "FR_DEVELOPER_DB_READ"
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

# =============================================================================
# 企業名名寄せ実験変数
# =============================================================================

variable "company_matching_schema_name" {
  description = "企業名名寄せ実験用スキーマ名（RAW_DB 配下）"
  type        = string
  default     = "COMPANY_MATCHING"
}

variable "ext_edinet_table_name" {
  description = "EDINETコードリスト外部テーブル名"
  type        = string
  default     = "EXT_EDINET_COMPANIES"
}

variable "ext_jpx_table_name" {
  description = "JPX上場銘柄一覧外部テーブル名"
  type        = string
  default     = "EXT_JPX_COMPANIES"
}

variable "ext_nta_table_name" {
  description = "国税庁法人番号公表データ外部テーブル名"
  type        = string
  default     = "EXT_NTA_COMPANIES"
}

variable "fr_raw_company_matching_write_role_name" {
  description = "RAW_DB.COMPANY_MATCHING への読み書き機能的ロール名"
  type        = string
  default     = "FR_RAW_COMPANY_MATCHING_WRITE"
}

variable "fr_raw_company_matching_read_role_name" {
  description = "RAW_DB.COMPANY_MATCHING への読み取り機能的ロール名"
  type        = string
  default     = "FR_RAW_COMPANY_MATCHING_READ"
}

# =============================================================================
# CONFIG_DB 変数（設定・統合系リソース用）
# =============================================================================

# =============================================================================
# PROJECT_DB 変数
# =============================================================================

variable "project_db_name" {
  description = "Streamlit / DBT など作業物置き場 DB名"
  type        = string
  default     = "PROJECT_DB"
}

# =============================================================================
# CONFIG_DB 変数（設定・統合系リソース用）
# =============================================================================

variable "config_db_name" {
  description = "設定・統合系リソース用データベース名（セッションポリシー、ネットワークポリシー等を格納）"
  type        = string
  default     = "CONFIG_DB"
}

variable "config_session_policies_schema" {
  description = "CONFIG_DB 内のセッションポリシー用スキーマ名"
  type        = string
  default     = "SESSION_POLICIES"
}

variable "config_session_policy_name" {
  description = "セカンダリロール無効化セッションポリシー名"
  type        = string
  default     = "BLOCK_SECONDARY_ROLES"
}

# =============================================================================
# Iceberg 学習用変数
# =============================================================================

variable "iceberg_s3_bucket_name" {
  description = "Iceberg Tables 用 S3 バケット名"
  type        = string
  default     = "snowflake-sandbox-iceberg"
}

variable "iceberg_iam_role_name" {
  description = "Iceberg 専用 IAM ロール名（外部ステージ用ロールとは分離）"
  type        = string
  default     = "snowflake-sandbox-iceberg-role"
}

variable "iceberg_external_volume_name" {
  description = "Snowflake External Volume 名（Iceberg Tables 用）"
  type        = string
  default     = "ICEBERG_S3_VOLUME"
}

variable "iceberg_db_name" {
  description = "Iceberg 学習用データベース名"
  type        = string
  default     = "ICEBERG_DB"
}

variable "iceberg_work_schema_name" {
  description = "Iceberg 学習用スキーマ名"
  type        = string
  default     = "WORK"
}

variable "fr_iceberg_write_role_name" {
  description = "ICEBERG_DB.WORK への読み書き権限を持つ機能的ロール名"
  type        = string
  default     = "FR_ICEBERG_WRITE"
}

variable "fr_iceberg_read_role_name" {
  description = "ICEBERG_DB.WORK への読み取り権限を持つ機能的ロール名"
  type        = string
  default     = "FR_ICEBERG_READ"
}

variable "iceberg_stage_name" {
  description = "Iceberg S3 バケットを参照する外部ステージ名（実験用 Notebook からのツリー取得・ファイルリード用）"
  type        = string
  default     = "ICEBERG_WORK_STAGE"
}

variable "iceberg_storage_integration_name" {
  description = "外部ステージ用 Storage Integration 名（Iceberg S3 バケット専用）"
  type        = string
  default     = "ICEBERG_S3_INTEGRATION"
}

variable "iceberg_stage_iam_role_name" {
  description = "Storage Integration 専用 IAM ロール名（External Volume 用 iceberg-role とは分離）"
  type        = string
  default     = "snowflake-sandbox-iceberg-stage-role"
}

# =============================================================================
# DuckDB 学習用変数
# =============================================================================

variable "duckdb_s3_bucket_name" {
  description = "DuckDB 学習用 S3 バケット名（Parquet ファイルを置き DuckDB から直接クエリする）"
  type        = string
  default     = "duckdb-study-sandbox"
}

variable "duckdb_iam_user_name" {
  description = "DuckDB から S3 にアクセスするための IAM ユーザー名（DuckDB は IAM ロール AssumeRole 非対応のためユーザー認証を使用）"
  type        = string
  default     = "duckdb-study-user"
}
