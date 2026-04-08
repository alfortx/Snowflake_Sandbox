# =============================================================================
# config モジュール: 設定・統合系リソース用 DB
#
# CONFIG_DB
# └── SESSION_POLICIES   ← セッションポリシー（セカンダリロール無効化など）
# └── （将来）NETWORK_POLICIES, INTEGRATIONS など
# =============================================================================

# -----------------------------------------------------------------------------
# CONFIG_DB: 設定・統合系リソースを横断的に格納する汎用DB
# -----------------------------------------------------------------------------
resource "snowflake_database" "config" {
  provider = snowflake.sysadmin
  name     = var.database_name
  comment  = "設定・統合系リソース用データベース（セッションポリシー、ネットワークポリシー等）"
}

# -----------------------------------------------------------------------------
# SESSION_POLICIES スキーマ
# -----------------------------------------------------------------------------
resource "snowflake_schema" "session_policies" {
  provider = snowflake.sysadmin
  database = snowflake_database.config.name
  name     = var.session_policies_schema
  comment  = "セッションポリシー格納スキーマ"
}

# -----------------------------------------------------------------------------
# BLOCK_SECONDARY_ROLES セッションポリシーを作成してアカウントに適用
#
# セカンダリロールとは: USE SECONDARY ROLES ALL で有効化できる追加ロール群
# ALLOWED_SECONDARY_ROLES = () にすることでアカウント全体でこれを禁止する
#
# snowflake_session_policy リソースは v2.x で廃止のため snowflake_execute で代替
# -----------------------------------------------------------------------------
resource "snowflake_execute" "create_session_policy" {
  provider   = snowflake.accountadmin
  depends_on = [snowflake_schema.session_policies]

  execute = "CREATE SESSION POLICY IF NOT EXISTS ${snowflake_database.config.name}.${snowflake_schema.session_policies.name}.${var.session_policy_name} ALLOWED_SECONDARY_ROLES = () COMMENT = 'セカンダリロールをアカウント全体で無効化するセッションポリシー'"
  revert  = "DROP SESSION POLICY IF EXISTS ${snowflake_database.config.name}.${snowflake_schema.session_policies.name}.${var.session_policy_name}"
}

resource "snowflake_execute" "set_account_session_policy" {
  provider   = snowflake.accountadmin
  depends_on = [snowflake_execute.create_session_policy]

  execute = "ALTER ACCOUNT SET SESSION POLICY ${snowflake_database.config.name}.${snowflake_schema.session_policies.name}.${var.session_policy_name}"
  revert  = "ALTER ACCOUNT UNSET SESSION POLICY"
}
