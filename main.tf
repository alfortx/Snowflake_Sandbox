# =============================================================================
# データベースの作成
# =============================================================================
resource "snowflake_database" "sandbox" {
  name    = var.database_name
  comment = var.database_comment

  # データベースが削除されるのを防ぐ（本番環境では推奨）
  # lifecycle {
  #   prevent_destroy = true
  # }
}

# =============================================================================
# スキーマの作成
# =============================================================================
resource "snowflake_schema" "work" {
  database = snowflake_database.sandbox.name
  name     = var.schema_name
  comment  = var.schema_comment
}

# =============================================================================
# ウェアハウスの作成
# =============================================================================
resource "snowflake_warehouse" "sandbox" {
  name           = var.warehouse_name
  warehouse_size = var.warehouse_size
  comment        = var.warehouse_comment

  # コスト削減設定
  auto_suspend = var.warehouse_auto_suspend # 5分間未使用で自動停止
  auto_resume  = var.warehouse_auto_resume  # クエリ実行時に自動再開

  # 初期状態
  initially_suspended = true # 作成時は停止状態
}

# =============================================================================
# ロールの作成
# =============================================================================
resource "snowflake_role" "sandbox_role" {
  name    = var.role_name
  comment = "サンドボックス環境で作業するためのロール"
}

# =============================================================================
# ユーザーの作成
# =============================================================================
resource "snowflake_user" "sandbox_user" {
  name         = var.user_name
  password     = var.user_password
  comment      = "サンドボックス環境の作業用ユーザー"
  display_name = "Sandbox User"

  # デフォルトロールを設定
  default_role = snowflake_role.sandbox_role.name

  # ユーザーが最初にログインしたときのデフォルト設定
  default_warehouse = snowflake_warehouse.sandbox.name

  # パスワードポリシー
  must_change_password = false
}

# =============================================================================
# ロールへの権限付与
# =============================================================================

# データベースの使用権限
resource "snowflake_database_grant" "sandbox_role_usage" {
  database_name = snowflake_database.sandbox.name
  privilege     = "USAGE"
  roles         = [snowflake_role.sandbox_role.name]
}

# スキーマの使用権限
resource "snowflake_schema_grant" "sandbox_role_usage" {
  database_name = snowflake_database.sandbox.name
  schema_name   = snowflake_schema.work.name
  privilege     = "USAGE"
  roles         = [snowflake_role.sandbox_role.name]
}

# スキーマ内でのテーブル作成権限
resource "snowflake_schema_grant" "sandbox_role_create_table" {
  database_name = snowflake_database.sandbox.name
  schema_name   = snowflake_schema.work.name
  privilege     = "CREATE TABLE"
  roles         = [snowflake_role.sandbox_role.name]
}

# スキーマ内での各種オブジェクト作成権限
resource "snowflake_schema_grant" "sandbox_role_create_view" {
  database_name = snowflake_database.sandbox.name
  schema_name   = snowflake_schema.work.name
  privilege     = "CREATE VIEW"
  roles         = [snowflake_role.sandbox_role.name]
}

# 既存・今後作成されるテーブルへの全権限（SELECT, INSERT, UPDATE, DELETE等）
resource "snowflake_table_grant" "sandbox_role_all_tables" {
  database_name = snowflake_database.sandbox.name
  schema_name   = snowflake_schema.work.name
  privilege     = "SELECT"
  roles         = [snowflake_role.sandbox_role.name]

  on_future = true # 今後作成されるテーブルにも適用
}

# ウェアハウスの使用権限
resource "snowflake_warehouse_grant" "sandbox_role_usage" {
  warehouse_name = snowflake_warehouse.sandbox.name
  privilege      = "USAGE"
  roles          = [snowflake_role.sandbox_role.name]
}

# =============================================================================
# ユーザーへのロール付与
# =============================================================================
resource "snowflake_role_grants" "sandbox_user_role" {
  role_name = snowflake_role.sandbox_role.name
  users     = [snowflake_user.sandbox_user.name]
}
