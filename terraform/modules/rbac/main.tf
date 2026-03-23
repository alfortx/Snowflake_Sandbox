# =============================================================================
# rbac モジュール: マトリクス②
# 役割ロール（DEVELOPER_ROLE / VIEWER_ROLE）が FR_* を継承
# =============================================================================

# --- DEVELOPER_ROLE が継承する FR_ ロール ---
resource "snowflake_grant_account_role" "developer_inherits_wh_sandbox_operate" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_wh_sandbox_operate.name
  parent_role_name = var.developer_role_name
}

resource "snowflake_grant_account_role" "developer_inherits_wh_mv_operate" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_wh_mv_operate.name
  parent_role_name = var.developer_role_name
}

resource "snowflake_grant_account_role" "developer_inherits_sandbox_work_write" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_sandbox_work_write.name
  parent_role_name = var.developer_role_name
}

resource "snowflake_grant_account_role" "developer_inherits_raw_covid19_write" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_raw_covid19_write.name
  parent_role_name = var.developer_role_name
}

resource "snowflake_grant_account_role" "developer_inherits_budget_book_write" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_budget_book_write.name
  parent_role_name = var.developer_role_name
}

resource "snowflake_grant_account_role" "developer_inherits_cortex_use" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_cortex_use.name
  parent_role_name = var.developer_role_name
}

resource "snowflake_grant_account_role" "developer_inherits_cortex_admin" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_cortex_admin.name
  parent_role_name = var.developer_role_name
}

resource "snowflake_grant_account_role" "developer_inherits_managed_access_test" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_managed_access_test.name
  parent_role_name = var.developer_role_name
}

# --- VIEWER_ROLE が継承する FR_ ロール ---
resource "snowflake_grant_account_role" "viewer_inherits_wh_sandbox_use" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_wh_sandbox_use.name
  parent_role_name = var.viewer_role_name
}

resource "snowflake_grant_account_role" "viewer_inherits_wh_mv_use" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_wh_mv_use.name
  parent_role_name = var.viewer_role_name
}

resource "snowflake_grant_account_role" "viewer_inherits_sandbox_work_read" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_sandbox_work_read.name
  parent_role_name = var.viewer_role_name
}

resource "snowflake_grant_account_role" "viewer_inherits_raw_covid19_read" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_raw_covid19_read.name
  parent_role_name = var.viewer_role_name
}

resource "snowflake_grant_account_role" "viewer_inherits_budget_book_read" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_budget_book_read.name
  parent_role_name = var.viewer_role_name
}

resource "snowflake_grant_account_role" "viewer_inherits_cortex_use" {
  provider         = snowflake.securityadmin
  role_name        = snowflake_account_role.fr_cortex_use.name
  parent_role_name = var.viewer_role_name
}
