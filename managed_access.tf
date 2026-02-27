# =============================================================================
# Managed Access テスト用リソース
#
# 目的: Managed Accessスキーマの権限制約を体験・確認するためのリソース
#   - オブジェクト所有者はGRANTが制限される
#   - スキーマ所有者のみがGRANTを実行できる
# =============================================================================

# =============================================================================
# Managed Access テスト用データベース
# SYSADMIN: Database作成
# =============================================================================
resource "snowflake_database" "managed_access" {
  provider = snowflake.sysadmin

  name    = var.managed_access_db_name
  comment = "Managed Accessテスト用データベース"
}

# =============================================================================
# SCHEMA_OWNER_ROLE の作成と権限設定
# SECURITYADMIN: ロール作成と権限付与
# =============================================================================
resource "snowflake_account_role" "schema_owner_role" {
  provider = snowflake.securityadmin

  name    = var.schema_owner_role_name
  comment = "Managed Accessスキーマの所有者ロール"
}

# sandbox_user に SCHEMA_OWNER_ROLE を付与
# → テスト時に USE ROLE SCHEMA_OWNER_ROLE で実行するため
resource "snowflake_grant_account_role" "sandbox_user_to_schema_owner" {
  provider = snowflake.securityadmin

  role_name = snowflake_account_role.schema_owner_role.name
  user_name = snowflake_user.sandbox_user.name
}

# Managed Access DB の USAGE 権限
resource "snowflake_grant_privileges_to_account_role" "schema_owner_db_usage" {
  provider = snowflake.securityadmin

  account_role_name = snowflake_account_role.schema_owner_role.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.managed_access.name
  }
}

# ウェアハウスの USAGE + OPERATE 権限
resource "snowflake_grant_privileges_to_account_role" "schema_owner_wh_usage" {
  provider = snowflake.securityadmin

  account_role_name = snowflake_account_role.schema_owner_role.name
  privileges        = ["USAGE", "OPERATE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.sandbox.name
  }
}

# =============================================================================
# Managed Access スキーマの作成と所有権移譲
# SYSADMIN で作成 → SCHEMA_OWNER_ROLE に所有権移譲
# =============================================================================
resource "snowflake_schema" "managed" {
  provider = snowflake.sysadmin

  # ロール作成と付与が完了してからスキーマを作成する
  depends_on = [
    snowflake_grant_account_role.sandbox_user_to_schema_owner,
    snowflake_grant_privileges_to_account_role.schema_owner_db_usage,
  ]

  database            = snowflake_database.managed_access.name
  name                = var.managed_schema_name
  with_managed_access = true
  comment             = "Managed Accessテスト用スキーマ（オブジェクト所有者はGRANTできない）"
}

# スキーマ所有権を SCHEMA_OWNER_ROLE に移譲
# → Managed Accessスキーマのオブジェクト権限付与は所有者ロールのみ可能
resource "snowflake_grant_ownership" "managed_schema_to_schema_owner" {
  provider = snowflake.sysadmin

  account_role_name = snowflake_account_role.schema_owner_role.name

  on {
    object_type = "SCHEMA"
    object_name = "\"${snowflake_database.managed_access.name}\".\"${snowflake_schema.managed.name}\""
  }
}

# =============================================================================
# SANDBOX_ROLE の権限設定（既存ロールに新規リソースへの権限を付与）
# =============================================================================

# Managed Access DB の USAGE 権限（DEVELOPER_ROLE）
resource "snowflake_grant_privileges_to_account_role" "sandbox_managed_db_usage" {
  provider = snowflake.securityadmin

  account_role_name = snowflake_account_role.developer_role.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.managed_access.name
  }
}

# Managed Schema の USAGE + CREATE TABLE 権限（DEVELOPER_ROLE）
resource "snowflake_grant_privileges_to_account_role" "sandbox_managed_schema" {
  provider = snowflake.securityadmin

  depends_on = [snowflake_grant_ownership.managed_schema_to_schema_owner]

  account_role_name = snowflake_account_role.developer_role.name
  privileges        = ["USAGE", "CREATE TABLE"]

  on_schema {
    schema_name = "\"${snowflake_database.managed_access.name}\".\"${snowflake_schema.managed.name}\""
  }
}
