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
resource "snowflake_account_role" "sandbox_role" {
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
  default_role = snowflake_account_role.sandbox_role.name

  # ユーザーが最初にログインしたときのデフォルト設定
  default_warehouse = snowflake_warehouse.sandbox.name

  # パスワードポリシー
  must_change_password = false
}

# =============================================================================
# ロールへの権限付与
# =============================================================================

# データベースの使用権限
resource "snowflake_grant_privileges_to_account_role" "database_usage" {
  account_role_name = snowflake_account_role.sandbox_role.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.sandbox.name
  }
}

# スキーマの権限（USAGE, CREATE TABLE, CREATE VIEW）
resource "snowflake_grant_privileges_to_account_role" "schema_privileges" {
  account_role_name = snowflake_account_role.sandbox_role.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW"]

  on_schema {
    schema_name = "\"${snowflake_database.sandbox.name}\".\"${snowflake_schema.work.name}\""
  }
}

# 今後作成されるテーブルへのSELECT権限
resource "snowflake_grant_privileges_to_account_role" "future_tables_select" {
  account_role_name = snowflake_account_role.sandbox_role.name
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${snowflake_database.sandbox.name}\".\"${snowflake_schema.work.name}\""
    }
  }
}

# ウェアハウスの使用権限
resource "snowflake_grant_privileges_to_account_role" "warehouse_usage" {
  account_role_name = snowflake_account_role.sandbox_role.name
  privileges        = ["USAGE", "OPERATE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.sandbox.name
  }
}

# =============================================================================
# ユーザーへのロール付与
# =============================================================================
resource "snowflake_grant_account_role" "user_role" {
  role_name = snowflake_account_role.sandbox_role.name
  user_name = snowflake_user.sandbox_user.name
}
