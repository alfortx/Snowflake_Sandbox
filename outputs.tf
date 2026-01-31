# =============================================================================
# 作成したリソースの情報を出力
# =============================================================================

output "database_name" {
  description = "作成されたデータベース名"
  value       = snowflake_database.sandbox.name
}

output "schema_name" {
  description = "作成されたスキーマ名"
  value       = snowflake_schema.work.name
}

output "schema_full_name" {
  description = "完全修飾スキーマ名（データベース.スキーマ）"
  value       = "${snowflake_database.sandbox.name}.${snowflake_schema.work.name}"
}

output "role_name" {
  description = "作成されたロール名"
  value       = snowflake_account_role.sandbox_role.name
}

output "user_name" {
  description = "作成されたユーザー名"
  value       = snowflake_user.sandbox_user.name
}

output "warehouse_name" {
  description = "作成されたウェアハウス名"
  value       = snowflake_warehouse.sandbox.name
}

output "warehouse_size" {
  description = "ウェアハウスのサイズ"
  value       = snowflake_warehouse.sandbox.warehouse_size
}

output "connection_info" {
  description = "接続情報のサマリー"
  value = {
    user      = snowflake_user.sandbox_user.name
    role      = snowflake_account_role.sandbox_role.name
    database  = snowflake_database.sandbox.name
    schema    = snowflake_schema.work.name
    warehouse = snowflake_warehouse.sandbox.name
  }
}

output "setup_complete_message" {
  description = "セットアップ完了メッセージ"
  value       = <<-EOT
    ✅ Snowflakeサンドボックス環境のセットアップが完了しました！

    【作成されたリソース】
    - データベース: ${snowflake_database.sandbox.name}
    - スキーマ: ${snowflake_schema.work.name}
    - ウェアハウス: ${snowflake_warehouse.sandbox.name} (${snowflake_warehouse.sandbox.warehouse_size})
    - ロール: ${snowflake_account_role.sandbox_role.name}
    - ユーザー: ${snowflake_user.sandbox_user.name}

    【次のステップ】
    1. SnowflakeのWebUIにログイン
    2. ユーザー: ${snowflake_user.sandbox_user.name} でログイン
    3. ロール: ${snowflake_account_role.sandbox_role.name} を選択
    4. ウェアハウス: ${snowflake_warehouse.sandbox.name} を使用
    5. データベース: ${snowflake_database.sandbox.name} で作業開始
  EOT
}
