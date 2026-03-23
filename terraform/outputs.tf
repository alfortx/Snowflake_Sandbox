# =============================================================================
# 作成したリソースの情報を出力（モジュール化後）
# =============================================================================

output "database_name" {
  description = "作成されたデータベース名"
  value       = module.foundation.sandbox_db_name
}

output "schema_name" {
  description = "作成されたスキーマ名"
  value       = module.foundation.work_schema_name
}

output "schema_full_name" {
  description = "完全修飾スキーマ名（データベース.スキーマ）"
  value       = "${module.foundation.sandbox_db_name}.${module.foundation.work_schema_name}"
}

output "developer_role_name" {
  description = "開発者用ロール名"
  value       = module.foundation.developer_role_name
}

output "viewer_role_name" {
  description = "閲覧者用ロール名"
  value       = module.foundation.viewer_role_name
}

output "user_name" {
  description = "作成されたユーザー名"
  value       = module.foundation.sandbox_user_name
}

output "warehouse_name" {
  description = "作成されたウェアハウス名"
  value       = module.foundation.sandbox_wh_name
}

output "warehouse_size" {
  description = "ウェアハウスのサイズ"
  value       = var.warehouse_size
}

output "connection_info" {
  description = "接続情報のサマリー"
  value = {
    user      = module.foundation.sandbox_user_name
    role      = module.foundation.developer_role_name
    database  = module.foundation.sandbox_db_name
    schema    = module.foundation.work_schema_name
    warehouse = module.foundation.sandbox_wh_name
  }
}

output "managed_access_test_instructions" {
  description = "Managed Access の権限制約を確認するためのSQL手順"
  value       = <<-EOT
    ─── Managed Access テスト手順 ───

    【1】テーブル作成（成功）
      USE ROLE ${module.foundation.developer_role_name};
      USE DATABASE ${module.managed_access.managed_access_db_name};
      USE SCHEMA ${module.managed_access.managed_schema_name};
      CREATE TABLE my_table (id INT);

    【2】オブジェクト所有者による GRANT（エラー）
      GRANT SELECT ON TABLE my_table TO ROLE ${module.foundation.developer_role_name};
      → Managed Access制約で失敗: スキーマ所有者以外はGRANT不可

    【3】スキーマ所有者による GRANT（成功）
      USE ROLE ${module.managed_access.schema_owner_role_name};
      GRANT SELECT ON TABLE ${module.managed_access.managed_access_db_name}.${module.managed_access.managed_schema_name}.my_table TO ROLE ${module.foundation.developer_role_name};
  EOT
}

output "iam_role_arn" {
  description = "Snowflake Storage Integration で使用する IAM Role ARN"
  value       = module.aws_integration.iam_role_arn
}

output "s3_bucket_arn" {
  description = "外部テーブルデータ用 S3 バケットの ARN"
  value       = module.aws_integration.s3_bucket_arn
}

output "external_stage_name" {
  description = "外部ステージの完全修飾名"
  value       = "${module.aws_integration.external_s3_stage_database}.${module.aws_integration.external_s3_stage_schema}.${module.aws_integration.external_s3_stage_name}"
}

output "external_stage_usage" {
  description = "外部ステージの動作確認用SQL"
  value       = <<-EOT
    ─── 外部ステージ 動作確認手順 ───

    USE ROLE ${module.foundation.developer_role_name};
    USE DATABASE ${module.foundation.sandbox_db_name};
    USE SCHEMA ${module.foundation.work_schema_name};
    USE WAREHOUSE ${module.foundation.sandbox_wh_name};

    LIST @${module.aws_integration.external_s3_stage_name};
  EOT
}

output "covid19_stage_name" {
  description = "COVID-19 外部ステージの完全修飾名"
  value       = "${module.covid19.raw_db_name}.${module.covid19.covid19_schema_name}.${module.covid19.covid19_s3_stage_name}"
}

output "covid19_external_table_name" {
  description = "COVID-19 外部テーブルの完全修飾名"
  value       = "${module.covid19.raw_db_name}.${module.covid19.covid19_schema_name}.${module.covid19.ext_jhu_timeseries_name}"
}

output "cortex_agent_info" {
  description = "Cortex Agent の接続・確認情報"
  value       = <<-EOT
    ─── Cortex Agent 確認手順 ───

    【Snowflake 上で確認】
      SHOW SEMANTIC VIEWS IN SCHEMA ${module.cortex.cortex_db_name}.${module.cortex.semantic_models_schema_name};
      SHOW AGENTS IN SCHEMA ${module.cortex.cortex_db_name}.${module.cortex.agents_schema_name};

    【Snowflake Intelligence から使う】
      1. Snowsight にログイン（ロール: DEVELOPER_ROLE）
      2. 左メニュー「AI & ML」→「Intelligence」を選択
      3. エージェント「${var.agent_name}」をクリック
      4. 日本語で質問を入力！
  EOT
}

output "setup_complete_message" {
  description = "セットアップ完了メッセージ"
  value       = <<-EOT
    ✅ Snowflakeサンドボックス環境のセットアップが完了しました！

    【作成されたリソース】
    - データベース: ${module.foundation.sandbox_db_name}
    - スキーマ: ${module.foundation.work_schema_name}
    - ウェアハウス: ${module.foundation.sandbox_wh_name} (${var.warehouse_size})
    - ロール: ${module.foundation.developer_role_name}
    - ユーザー: ${module.foundation.sandbox_user_name}
  EOT
}
