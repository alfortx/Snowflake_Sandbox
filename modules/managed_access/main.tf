# =============================================================================
# managed_access モジュール: Managed Access テスト用リソース
# =============================================================================

resource "snowflake_database" "managed_access" {
  provider = snowflake.sysadmin

  name    = var.managed_access_db_name
  comment = "Managed Accessテスト用データベース"
}

resource "snowflake_account_role" "schema_owner_role" {
  provider = snowflake.securityadmin

  name    = var.schema_owner_role_name
  comment = "Managed Accessスキーマの所有者ロール"
}

resource "snowflake_grant_account_role" "sandbox_user_to_schema_owner" {
  provider = snowflake.securityadmin

  role_name = snowflake_account_role.schema_owner_role.name
  user_name = var.sandbox_user_name
}

resource "snowflake_grant_privileges_to_account_role" "schema_owner_db_usage" {
  provider = snowflake.securityadmin

  account_role_name = snowflake_account_role.schema_owner_role.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.managed_access.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "schema_owner_wh_usage" {
  provider = snowflake.securityadmin

  account_role_name = snowflake_account_role.schema_owner_role.name
  privileges        = ["USAGE", "OPERATE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = var.sandbox_wh_name
  }
}

resource "snowflake_schema" "managed" {
  provider = snowflake.sysadmin

  depends_on = [
    snowflake_grant_account_role.sandbox_user_to_schema_owner,
    snowflake_grant_privileges_to_account_role.schema_owner_db_usage,
  ]

  database            = snowflake_database.managed_access.name
  name                = var.managed_schema_name
  with_managed_access = true
  comment             = "Managed Accessテスト用スキーマ（オブジェクト所有者はGRANTできない）"
}

resource "snowflake_grant_ownership" "managed_schema_to_schema_owner" {
  provider = snowflake.sysadmin

  account_role_name = snowflake_account_role.schema_owner_role.name

  on {
    object_type = "SCHEMA"
    object_name = "\"${snowflake_database.managed_access.name}\".\"${snowflake_schema.managed.name}\""
  }
}
