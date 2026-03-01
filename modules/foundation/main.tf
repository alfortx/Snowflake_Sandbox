# =============================================================================
# foundation モジュール: Snowflake 基盤リソース
#
# 作成するリソース:
#   - SANDBOX_DB + WORK スキーマ
#   - SANDBOX_WH ウェアハウス
#   - DEVELOPER_ROLE / VIEWER_ROLE
#   - sandbox_user（+ MAIN ユーザーへのロール付与）
#   - セカンダリーロール無効化
# =============================================================================

resource "snowflake_database" "sandbox" {
  provider = snowflake.sysadmin

  name    = var.database_name
  comment = var.database_comment
}

resource "snowflake_schema" "work" {
  provider = snowflake.sysadmin

  database = snowflake_database.sandbox.name
  name     = var.schema_name
  comment  = var.schema_comment
}

resource "snowflake_warehouse" "sandbox" {
  provider = snowflake.sysadmin

  name           = var.warehouse_name
  warehouse_size = var.warehouse_size
  comment        = var.warehouse_comment

  auto_suspend = var.warehouse_auto_suspend
  auto_resume  = var.warehouse_auto_resume

  initially_suspended = true
}

resource "snowflake_account_role" "developer_role" {
  provider = snowflake.securityadmin

  name    = var.developer_role_name
  comment = "開発者用ロール（読み書き権限）"
}

resource "snowflake_account_role" "viewer_role" {
  provider = snowflake.securityadmin

  name    = var.viewer_role_name
  comment = "閲覧者用ロール（読み取り専用）"
}

resource "snowflake_user" "sandbox_user" {
  provider = snowflake.useradmin

  name         = var.user_name
  password     = var.user_password
  comment      = "サンドボックス環境の作業用ユーザー"
  display_name = "Sandbox User"

  default_role      = snowflake_account_role.developer_role.name
  default_warehouse = snowflake_warehouse.sandbox.name

  must_change_password = false
}

resource "snowflake_grant_account_role" "user_role" {
  provider = snowflake.securityadmin

  role_name = snowflake_account_role.developer_role.name
  user_name = snowflake_user.sandbox_user.name
}

resource "snowflake_grant_account_role" "user_viewer_role" {
  provider = snowflake.securityadmin

  role_name = snowflake_account_role.viewer_role.name
  user_name = snowflake_user.sandbox_user.name
}

resource "snowflake_grant_account_role" "main_user_developer_role" {
  provider = snowflake.securityadmin

  role_name = snowflake_account_role.developer_role.name
  user_name = "MAIN"
}

resource "snowflake_grant_account_role" "main_user_viewer_role" {
  provider = snowflake.securityadmin

  role_name = snowflake_account_role.viewer_role.name
  user_name = "MAIN"
}

# セカンダリーロールのデフォルト無効化
resource "snowflake_execute" "disable_secondary_roles_sandbox_user" {
  provider   = snowflake.accountadmin
  depends_on = [snowflake_user.sandbox_user]

  execute = "ALTER USER \"${snowflake_user.sandbox_user.name}\" SET DEFAULT_SECONDARY_ROLES = ()"
  revert  = "ALTER USER \"${snowflake_user.sandbox_user.name}\" SET DEFAULT_SECONDARY_ROLES = ('ALL')"
}

resource "snowflake_execute" "disable_secondary_roles_main_user" {
  provider = snowflake.accountadmin

  execute = "ALTER USER MAIN SET DEFAULT_SECONDARY_ROLES = ()"
  revert  = "ALTER USER MAIN SET DEFAULT_SECONDARY_ROLES = ('ALL')"
}
