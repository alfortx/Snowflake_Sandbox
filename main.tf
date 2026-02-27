# =============================================================================
# データベースの作成
# SYSADMIN: Database, Schema, Warehouseなどのオブジェクト管理
# =============================================================================
resource "snowflake_database" "sandbox" {
  provider = snowflake.sysadmin

  name    = var.database_name
  comment = var.database_comment

  # データベースが削除されるのを防ぐ（本番環境では推奨）
  # lifecycle {
  #   prevent_destroy = true
  # }
}

# =============================================================================
# スキーマの作成
# SYSADMIN: Database配下のSchemaを作成
# =============================================================================
resource "snowflake_schema" "work" {
  provider = snowflake.sysadmin

  database = snowflake_database.sandbox.name
  name     = var.schema_name
  comment  = var.schema_comment
}

# =============================================================================
# ウェアハウスの作成
# SYSADMIN: Warehouseの作成と管理
# =============================================================================
resource "snowflake_warehouse" "sandbox" {
  provider = snowflake.sysadmin

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
# SECURITYADMIN: Roleの作成と管理
# =============================================================================
resource "snowflake_account_role" "developer_role" {
  provider = snowflake.securityadmin

  name    = var.developer_role_name
  comment = "開発者用ロール（読み書き権限）"
}

resource "snowflake_account_role" "analyst_role" {
  provider = snowflake.securityadmin

  name    = var.analyst_role_name
  comment = "分析者用ロール（読み取り専用）"
}

# =============================================================================
# ユーザーの作成
# USERADMIN: Userの作成と管理
# =============================================================================
resource "snowflake_user" "sandbox_user" {
  provider = snowflake.useradmin

  name         = var.user_name
  password     = var.user_password
  comment      = "サンドボックス環境の作業用ユーザー"
  display_name = "Sandbox User"

  # デフォルトロールを設定
  default_role = snowflake_account_role.developer_role.name

  # ユーザーが最初にログインしたときのデフォルト設定
  default_warehouse = snowflake_warehouse.sandbox.name

  # パスワードポリシー
  must_change_password = false
}

# =============================================================================
# ロールへの権限付与
# SECURITYADMIN: 権限の付与と管理
# =============================================================================

# =============================================================================
# DEVELOPER_ROLE への権限付与
# =============================================================================

# データベースの使用権限
resource "snowflake_grant_privileges_to_account_role" "database_usage" {
  provider = snowflake.securityadmin

  account_role_name = snowflake_account_role.developer_role.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.sandbox.name
  }
}

# スキーマの権限（USAGE, CREATE TABLE, CREATE VIEW）
resource "snowflake_grant_privileges_to_account_role" "schema_privileges" {
  provider = snowflake.securityadmin

  account_role_name = snowflake_account_role.developer_role.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW"]

  on_schema {
    schema_name = "\"${snowflake_database.sandbox.name}\".\"${snowflake_schema.work.name}\""
  }
}

# 今後作成されるテーブルへの権限（読み書き）
resource "snowflake_grant_privileges_to_account_role" "future_tables_select" {
  provider = snowflake.securityadmin

  account_role_name = snowflake_account_role.developer_role.name
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${snowflake_database.sandbox.name}\".\"${snowflake_schema.work.name}\""
    }
  }
}

# ウェアハウスの使用権限（読み書き）
resource "snowflake_grant_privileges_to_account_role" "warehouse_usage" {
  provider = snowflake.securityadmin

  account_role_name = snowflake_account_role.developer_role.name
  privileges        = ["USAGE", "OPERATE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.sandbox.name
  }
}

# =============================================================================
# ANALYST_ROLE への権限付与
# =============================================================================

# データベースの使用権限
resource "snowflake_grant_privileges_to_account_role" "analyst_database_usage" {
  provider = snowflake.securityadmin

  account_role_name = snowflake_account_role.analyst_role.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.sandbox.name
  }
}

# スキーマの権限（USAGE のみ）
resource "snowflake_grant_privileges_to_account_role" "analyst_schema_usage" {
  provider = snowflake.securityadmin

  account_role_name = snowflake_account_role.analyst_role.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "\"${snowflake_database.sandbox.name}\".\"${snowflake_schema.work.name}\""
  }
}

# 今後作成されるテーブルへの権限（読み取りのみ）
resource "snowflake_grant_privileges_to_account_role" "analyst_future_tables_select" {
  provider = snowflake.securityadmin

  account_role_name = snowflake_account_role.analyst_role.name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${snowflake_database.sandbox.name}\".\"${snowflake_schema.work.name}\""
    }
  }
}

# ウェアハウスの使用権限（USAGE のみ）
resource "snowflake_grant_privileges_to_account_role" "analyst_warehouse_usage" {
  provider = snowflake.securityadmin

  account_role_name = snowflake_account_role.analyst_role.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.sandbox.name
  }
}

# =============================================================================
# ユーザーへのロール付与
# SECURITYADMIN: ユーザーへのロール付与
# =============================================================================

# sandbox_user に DEVELOPER_ROLE を付与
resource "snowflake_grant_account_role" "user_role" {
  provider = snowflake.securityadmin

  role_name = snowflake_account_role.developer_role.name
  user_name = snowflake_user.sandbox_user.name
}

# sandbox_user に ANALYST_ROLE を付与
resource "snowflake_grant_account_role" "user_analyst_role" {
  provider = snowflake.securityadmin

  role_name = snowflake_account_role.analyst_role.name
  user_name = snowflake_user.sandbox_user.name
}

# アカウント管理者ユーザー（MAIN）へ DEVELOPER_ROLE を付与
resource "snowflake_grant_account_role" "main_user_developer_role" {
  provider = snowflake.securityadmin

  role_name = snowflake_account_role.developer_role.name
  user_name = "MAIN"
}

# アカウント管理者ユーザー（MAIN）へ ANALYST_ROLE を付与
resource "snowflake_grant_account_role" "main_user_analyst_role" {
  provider = snowflake.securityadmin

  role_name = snowflake_account_role.analyst_role.name
  user_name = "MAIN"
}

# =============================================================================
# セキュリティ設定: セカンダリーロールのデフォルト無効化
#
# DEFAULT_SECONDARY_ROLES はユーザーレベルのパラメータ（アカウントレベルへの設定は不可）。
# Snowflake には「新規ユーザーへ自動適用するアカウントデフォルト」の仕組みが存在しないため、
# 既存ユーザー1人ずつに設定し、新規ユーザー追加時は snowflake_user リソースに
# 同様の snowflake_execute を追加すること。
# =============================================================================

# sandbox_user のセカンダリーロール無効化
resource "snowflake_execute" "disable_secondary_roles_sandbox_user" {
  provider   = snowflake.accountadmin
  depends_on = [snowflake_user.sandbox_user]

  execute = "ALTER USER \"${snowflake_user.sandbox_user.name}\" SET DEFAULT_SECONDARY_ROLES = ()"
  revert  = "ALTER USER \"${snowflake_user.sandbox_user.name}\" SET DEFAULT_SECONDARY_ROLES = ('ALL')"
}

# MAIN（管理者ユーザー）のセカンダリーロール無効化
resource "snowflake_execute" "disable_secondary_roles_main_user" {
  provider = snowflake.accountadmin

  execute = "ALTER USER MAIN SET DEFAULT_SECONDARY_ROLES = ()"
  revert  = "ALTER USER MAIN SET DEFAULT_SECONDARY_ROLES = ('ALL')"
}
