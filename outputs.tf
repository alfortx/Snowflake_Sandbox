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

output "developer_role_name" {
  description = "開発者用ロール名"
  value       = snowflake_account_role.developer_role.name
}

output "analyst_role_name" {
  description = "分析者用ロール名"
  value       = snowflake_account_role.analyst_role.name
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
    role      = snowflake_account_role.developer_role.name
    database  = snowflake_database.sandbox.name
    schema    = snowflake_schema.work.name
    warehouse = snowflake_warehouse.sandbox.name
  }
}

# =============================================================================
# Managed Access テスト手順
# =============================================================================
output "managed_access_test_instructions" {
  description = "Managed Access の権限制約を確認するためのSQL手順"
  value       = <<-EOT
    ─── Managed Access テスト手順 ───

    【1】テーブル作成（成功）
      USE ROLE ${snowflake_account_role.developer_role.name};
      USE DATABASE ${snowflake_database.managed_access.name};
      USE SCHEMA ${snowflake_schema.managed.name};
      CREATE TABLE my_table (id INT);

    【2】オブジェクト所有者による GRANT（エラー）
      GRANT SELECT ON TABLE my_table TO ROLE ${snowflake_account_role.developer_role.name};
      → Managed Access制約で失敗: スキーマ所有者以外はGRANT不可

    【3】スキーマ所有者による GRANT（成功）
      USE ROLE ${snowflake_account_role.schema_owner_role.name};
      GRANT SELECT ON TABLE ${snowflake_database.managed_access.name}.${snowflake_schema.managed.name}.my_table TO ROLE ${snowflake_account_role.developer_role.name};
  EOT
}

# =============================================================================
# AWS リソース出力（次の Snowflake storage_integration で使用）
# =============================================================================
output "iam_role_arn" {
  description = "Snowflake Storage Integration で使用する IAM Role ARN"
  value       = aws_iam_role.snowflake_s3_role.arn
}

output "s3_bucket_arn" {
  description = "外部テーブルデータ用 S3 バケットの ARN"
  value       = aws_s3_bucket.external_table_data.arn
}

output "external_stage_name" {
  description = "外部ステージの完全修飾名"
  value       = "${snowflake_stage.external_s3.database}.${snowflake_stage.external_s3.schema}.${snowflake_stage.external_s3.name}"
}

output "external_stage_usage" {
  description = "外部ステージの動作確認用SQL"
  value       = <<-EOT
    ─── 外部ステージ 動作確認手順 ───

    USE ROLE ${snowflake_account_role.developer_role.name};
    USE DATABASE ${snowflake_database.sandbox.name};
    USE SCHEMA ${snowflake_schema.work.name};
    USE WAREHOUSE ${snowflake_warehouse.sandbox.name};

    -- ステージの内容を確認（S3バケットのファイル一覧）
    LIST @${snowflake_stage.external_s3.name};

    -- ファイルを S3 にアップロード後、外部テーブルを作成する例
    CREATE EXTERNAL TABLE ext_sample (
      id   NUMBER  AS (VALUE:c1::NUMBER),
      name STRING  AS (VALUE:c2::STRING)
    )
    WITH LOCATION = @${snowflake_stage.external_s3.name}
    FILE_FORMAT = (TYPE = JSON);
  EOT
}

# =============================================================================
# COVID-19 データロード関連の出力
# =============================================================================
output "covid19_stage_name" {
  description = "COVID-19 外部ステージの完全修飾名"
  value       = "${snowflake_database.raw_db.name}.${snowflake_schema.covid19.name}.${snowflake_stage.covid19_s3_stage.name}"
}

output "covid19_external_table_name" {
  description = "COVID-19 外部テーブルの完全修飾名"
  value       = "${snowflake_database.raw_db.name}.${snowflake_schema.covid19.name}.${snowflake_external_table.ext_jhu_timeseries.name}"
}

output "covid19_external_table_usage" {
  description = "COVID-19 外部テーブル動作確認SQL"
  value       = <<-EOT
    ─── COVID-19 外部テーブル 動作確認手順 ───

    USE DATABASE ${snowflake_database.raw_db.name};
    USE SCHEMA ${snowflake_schema.covid19.name};
    USE WAREHOUSE ${snowflake_warehouse.sandbox.name};
    USE ROLE ${snowflake_account_role.developer_role.name};

    -- 1. ステージ確認（S3のファイル一覧）
    LIST @${snowflake_stage.covid19_s3_stage.name};

    -- 2. 外部テーブルのクエリ（COPY不要・S3を直接参照）
    SELECT COUNT(*) FROM ${snowflake_external_table.ext_jhu_timeseries.name};

    -- 3. データ確認（先頭10件）
    SELECT * FROM ${snowflake_external_table.ext_jhu_timeseries.name} LIMIT 10;

    -- 4. 国別・最新日付の感染者数サマリー
    SELECT
        COUNTRY_REGION,
        MAX(DATE) AS latest_date,
        MAX(CONFIRMED) AS total_confirmed,
        MAX(DEATHS) AS total_deaths
    FROM ${snowflake_external_table.ext_jhu_timeseries.name}
    WHERE PROVINCE_STATE IS NULL
    GROUP BY COUNTRY_REGION
    ORDER BY total_confirmed DESC
    LIMIT 20;
  EOT
}

output "covid19_load_instructions" {
  description = "COVID-19 データロード手順（COPY INTO方式・参考用）"
  value       = <<-EOT
    ─── COVID-19 データロード手順（COPY INTO方式・参考用） ───

    USE DATABASE ${snowflake_database.raw_db.name};
    USE SCHEMA ${snowflake_schema.covid19.name};
    USE WAREHOUSE ${snowflake_warehouse.sandbox.name};

    -- 1. ステージ確認
    LIST @${snowflake_stage.covid19_s3_stage.name};

    -- 2. Rawテーブルへのロード（テーブルはdbtで作成後に実行）
    COPY INTO RAW_JHU_TIMESERIES (
      UID, FIPS, ISO2, ISO3, CODE3, ADMIN2,
      LATITUDE, LONGITUDE, PROVINCE_STATE, COUNTRY_REGION,
      DATE, CONFIRMED, DEATHS, RECOVERED
    )
    FROM @${snowflake_stage.covid19_s3_stage.name}
    PATTERN = '.*jhu_csse_covid_19_timeseries_merged\\.csv'
    FILE_FORMAT = (FORMAT_NAME = '${snowflake_database.raw_db.name}.${snowflake_schema.covid19.name}.${snowflake_file_format.csv_format.name}')
    ON_ERROR = CONTINUE;

    -- 3. 件数確認
    SELECT COUNT(*) FROM RAW_JHU_TIMESERIES;

    ※ 外部テーブル（EXT_JHU_TIMESERIES）を使用する場合、この手順は不要です
  EOT
}

# =============================================================================
# Snowflake Intelligence / Cortex Agent
# =============================================================================
output "cortex_agent_info" {
  description = "Cortex Agent の接続・確認情報"
  value       = <<-EOT
    ─── Cortex Agent 確認手順 ───

    【Snowflake 上で確認】
      -- セマンティックビューの確認
      SHOW SEMANTIC VIEWS IN SCHEMA ${snowflake_database.cortex.name}.${snowflake_schema.semantic_models.name};

      -- エージェントの確認
      SHOW AGENTS IN SCHEMA ${snowflake_database.cortex.name}.${var.cortex_agents_schema_name};

    【Snowflake Intelligence から使う】
      1. Snowsight にログイン（ロール: ${var.cortex_role_name}）
      2. 左メニュー「AI & ML」→「Intelligence」を選択
      3. エージェント「${var.agent_name}」をクリック
      4. 日本語で質問を入力！

    【サンプル質問】
      - 日本の月別感染者数の推移を教えてください
      - ワクチン接種率トップ10の国はどこですか？
      - 大陸別のワクチン接種率を比較してください
      - アジアの致死率を国別に教えてください
  EOT
}

output "setup_complete_message" {
  description = "セットアップ完了メッセージ"
  value       = <<-EOT
    ✅ Snowflakeサンドボックス環境のセットアップが完了しました！

    【作成されたリソース】
    - データベース: ${snowflake_database.sandbox.name}
    - スキーマ: ${snowflake_schema.work.name}
    - ウェアハウス: ${snowflake_warehouse.sandbox.name} (${snowflake_warehouse.sandbox.warehouse_size})
    - ロール: ${snowflake_account_role.developer_role.name}
    - ユーザー: ${snowflake_user.sandbox_user.name}

    【次のステップ】
    1. SnowflakeのWebUIにログイン
    2. ユーザー: ${snowflake_user.sandbox_user.name} でログイン
    3. ロール: ${snowflake_account_role.developer_role.name} を選択
    4. ウェアハウス: ${snowflake_warehouse.sandbox.name} を使用
    5. データベース: ${snowflake_database.sandbox.name} で作業開始
  EOT
}
