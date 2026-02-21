# =============================================================================
# Snowflake Intelligence / Cortex Agent
#
# 構成概要:
#   CORTEX_DB
#   ├── SEMANTIC_MODELS スキーマ
#   │   └── COVID19_SEMANTIC セマンティックビュー  ← Cortex Agent がデータ参照に使用
#   └── AGENTS スキーマ
#       └── COVID19_AGENT                         ← Snowflake Intelligence から呼び出せるエージェント
#
# 参照データ:
#   RAW_DB.COVID19.MV_JHU_TIMESERIES         (JHU 時系列)
#   RAW_DB.COVID19.MV_COVID19_WORLD_TESTING  (OWID ワクチン・検査)
#
# ⚠️ Semantic View は Preview リソース。
#    tables / dimensions / facts / metrics / relationships の変更は
#    destroy → recreate が発生します（データは消えません）。
# =============================================================================

# -----------------------------------------------------------------------------
# AGENTS スキーマ: Cortex Agent の配置先
# -----------------------------------------------------------------------------
resource "snowflake_schema" "agents" {
  provider = snowflake.sysadmin

  database = snowflake_database.cortex.name
  name     = var.cortex_agents_schema_name
  comment  = "Cortex Agent 配置スキーマ（Snowflake Intelligence 連携）"
}

# -----------------------------------------------------------------------------
# Semantic View: MV_JHU_TIMESERIES × MV_COVID19_WORLD_TESTING を統合
#   Cortex Agent の cortex_analyst_text_to_sql ツールがこのビューを使用する
# -----------------------------------------------------------------------------
resource "snowflake_semantic_view" "covid19" {
  provider = snowflake.sysadmin

  database = snowflake_database.cortex.name
  schema   = snowflake_schema.semantic_models.name
  name     = var.semantic_view_name
  comment  = "COVID-19分析用セマンティックビュー（JHU時系列 × OWID ワクチン・検査データ統合）"

  # --- 論理テーブル定義 ---
  tables {
    table_alias = "jhu"
    table_name  = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_materialized_view.mv_jhu_timeseries.name}\""
    primary_key = ["ISO3", "DATE"]
  }
  tables {
    table_alias = "world"
    table_name  = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_materialized_view.mv_covid19_world_testing.name}\""
    primary_key = ["ISO_CODE", "DATE"]
  }

  # --- テーブル間リレーション: jhu LEFT OUTER JOIN world on iso3=iso_code, date=date ---
  relationships {
    relationship_identifier = "jhu_to_world"
    table_name_or_alias {
      table_alias = "jhu"
    }
    referenced_table_name_or_alias {
      table_alias = "world"
    }
    relationship_columns            = ["ISO3", "DATE"]
    referenced_relationship_columns = ["ISO_CODE", "DATE"]
  }

  # --- ディメンション（絞り込み・グルーピング軸）---
  dimensions {
    qualified_expression_name = "\"jhu\".\"COUNTRY_REGION\""
    sql_expression            = "\"jhu\".\"COUNTRY_REGION\""
    comment                   = "国または地域の名前（例：Japan, US）"
    synonym                   = toset(["country", "nation", "国", "国名", "地域"])
  }
  dimensions {
    qualified_expression_name = "\"jhu\".\"PROVINCE_STATE\""
    sql_expression            = "\"jhu\".\"PROVINCE_STATE\""
    comment                   = "州・省の名前。NULL の場合は国全体の集計行"
    synonym                   = toset(["state", "province", "州", "省"])
  }
  dimensions {
    qualified_expression_name = "\"jhu\".\"ISO3\""
    sql_expression            = "\"jhu\".\"ISO3\""
    comment                   = "ISO 3文字国コード（例：JPN, USA）"
    synonym                   = toset(["iso code", "country code", "国コード"])
  }
  dimensions {
    qualified_expression_name = "\"world\".\"CONTINENT\""
    sql_expression            = "\"world\".\"CONTINENT\""
    comment                   = "大陸名（Asia, Europe 等）"
    synonym                   = toset(["大陸", "continent", "地域区分"])
  }

  # --- ファクト（生の数値列）---
  facts {
    qualified_expression_name = "\"jhu\".\"CONFIRMED\""
    sql_expression            = "\"jhu\".\"CONFIRMED\""
    comment                   = "累計感染確認者数"
    synonym                   = toset(["cases", "感染者数", "累計感染者数", "陽性者数"])
  }
  facts {
    qualified_expression_name = "\"jhu\".\"DEATHS\""
    sql_expression            = "\"jhu\".\"DEATHS\""
    comment                   = "累計死者数"
    synonym                   = toset(["fatalities", "死者数", "死亡者数", "累計死者数"])
  }
  facts {
    qualified_expression_name = "\"jhu\".\"RECOVERED\""
    sql_expression            = "\"jhu\".\"RECOVERED\""
    comment                   = "累計回復者数"
    synonym                   = toset(["recoveries", "回復者数", "完治者数"])
  }
  facts {
    qualified_expression_name = "\"world\".\"NEW_CASES\""
    sql_expression            = "\"world\".\"NEW_CASES\""
    comment                   = "日次新規感染者数"
    synonym                   = toset(["daily cases", "新規感染者数", "日次感染者数"])
  }
  facts {
    qualified_expression_name = "\"world\".\"NEW_DEATHS\""
    sql_expression            = "\"world\".\"NEW_DEATHS\""
    comment                   = "日次新規死者数"
    synonym                   = toset(["daily deaths", "新規死者数"])
  }
  facts {
    qualified_expression_name = "\"world\".\"TOTAL_VACCINATIONS\""
    sql_expression            = "\"world\".\"TOTAL_VACCINATIONS\""
    comment                   = "ワクチン接種総回数（累計）"
    synonym                   = toset(["累計ワクチン接種数", "ワクチン接種総数"])
  }
  facts {
    qualified_expression_name = "\"world\".\"PEOPLE_FULLY_VACCINATED\""
    sql_expression            = "\"world\".\"PEOPLE_FULLY_VACCINATED\""
    comment                   = "ワクチン接種シリーズを完了した人数"
    synonym                   = toset(["fully vaccinated", "ワクチン完全接種者数", "完全接種者数"])
  }
  facts {
    qualified_expression_name = "\"world\".\"POPULATION\""
    sql_expression            = "\"world\".\"POPULATION\""
    comment                   = "国の総人口"
    synonym                   = toset(["人口", "総人口", "population"])
  }
  facts {
    qualified_expression_name = "\"world\".\"TOTAL_TESTS\""
    sql_expression            = "\"world\".\"TOTAL_TESTS\""
    comment                   = "累計検査数"
    synonym                   = toset(["総検査数", "累計検査数"])
  }
  facts {
    qualified_expression_name = "\"world\".\"GDP_PER_CAPITA\""
    sql_expression            = "\"world\".\"GDP_PER_CAPITA\""
    comment                   = "一人当たりGDP（米ドル）"
    synonym                   = toset(["GDP", "一人当たりGDP"])
  }

  # --- メトリクス（集計計算式）---
  metrics {
    semantic_expression {
      qualified_expression_name = "\"jhu\".\"CASE_FATALITY_RATE\""
      sql_expression            = "CASE WHEN SUM(\"jhu\".\"CONFIRMED\") > 0 THEN ROUND(SUM(\"jhu\".\"DEATHS\") / SUM(\"jhu\".\"CONFIRMED\") * 100, 2) ELSE NULL END"
      comment                   = "感染確認者数に対する死者数の割合（%）"
      synonym                   = toset(["CFR", "致死率", "死亡率", "fatality rate"])
    }
  }
  metrics {
    semantic_expression {
      qualified_expression_name = "\"world\".\"VACCINATION_RATE_PCT\""
      sql_expression            = "CASE WHEN SUM(\"world\".\"POPULATION\") > 0 THEN ROUND(SUM(\"world\".\"PEOPLE_FULLY_VACCINATED\") / SUM(\"world\".\"POPULATION\") * 100, 1) ELSE NULL END"
      comment                   = "人口に対するワクチン完全接種者の割合（%）"
      synonym                   = toset(["ワクチン接種率", "vaccination rate", "完全接種率"])
    }
  }
}

# -----------------------------------------------------------------------------
# Semantic View への SELECT 権限（CORTEX_ROLE）
#   Provider が SEMANTIC VIEW オブジェクト型を未サポートの可能性があるため
#   snowflake_execute で GRANT SQL を直接実行する
# -----------------------------------------------------------------------------
resource "snowflake_execute" "semantic_view_grant" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_semantic_view.covid19]

  execute = "GRANT SELECT ON SEMANTIC VIEW \"${snowflake_database.cortex.name}\".\"${snowflake_schema.semantic_models.name}\".\"${var.semantic_view_name}\" TO ROLE ${var.cortex_role_name}"
  revert  = "REVOKE SELECT ON SEMANTIC VIEW \"${snowflake_database.cortex.name}\".\"${snowflake_schema.semantic_models.name}\".\"${var.semantic_view_name}\" FROM ROLE ${var.cortex_role_name}"
}

# -----------------------------------------------------------------------------
# AGENTS スキーマへの USAGE 権限（CORTEX_ROLE）
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "agents_schema_usage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.cortex_role.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "\"${snowflake_database.cortex.name}\".\"${snowflake_schema.agents.name}\""
  }
}

# -----------------------------------------------------------------------------
# SNOWFLAKE.CORTEX_AGENT_USER DB ロールを CORTEX_ROLE に付与
#   Cortex Agent の利用に必要なシステム DB ロール
# -----------------------------------------------------------------------------
resource "snowflake_grant_database_role" "cortex_agent_user" {
  provider = snowflake.accountadmin

  database_role_name = "\"SNOWFLAKE\".\"CORTEX_AGENT_USER\""
  parent_role_name   = snowflake_account_role.cortex_role.name
}

# -----------------------------------------------------------------------------
# Cortex Agent の作成（snowflake_execute 経由）
#   ネイティブの Terraform リソースが未実装のため、CREATE AGENT SQL を直接実行する
#   エージェント設定変更時は terraform apply で OR REPLACE により自動再作成される
# -----------------------------------------------------------------------------
locals {
  # Agent YAML 仕様
  agent_spec = <<-YAML
    models:
      orchestration: claude-4-sonnet
    orchestration:
      budget:
        seconds: 60
        tokens: 32000
    instructions:
      response: "日本語の質問には日本語で回答してください。データに基づいた正確な回答を提供してください。"
      system: "あなたはCOVID-19データアナリストです。JHU時系列データとOur World in Dataのデータを分析します。感染者数・死者数・ワクチン接種状況について質問に答えてください。"
      sample_questions:
        - question: "日本の月別感染者数の推移を教えてください"
          answer: "MV_JHU_TIMESERIESからJapanの月次集計を取得します"
        - question: "ワクチン接種率トップ10の国を教えてください"
          answer: "MV_COVID19_WORLD_TESTINGからPEOPLE_FULLY_VACCINATED/POPULATIONで計算します"
        - question: "大陸別のワクチン接種率を比較してください"
          answer: "CONTINENTでグループ化して接種率を集計します"
    tools:
      - tool_spec:
          type: cortex_analyst_text_to_sql
          name: covid19_analyst
          description: "COVID-19の感染者数・死者数・ワクチン接種データを自然言語で分析するツール。国別・大陸別・時系列での比較が可能。"
    tool_resources:
      covid19_analyst:
        semantic_view: "${snowflake_database.cortex.name}.${snowflake_schema.semantic_models.name}.${var.semantic_view_name}"
        execution_environment:
          type: warehouse
          warehouse: "${snowflake_warehouse.sandbox.name}"
  YAML
}

resource "snowflake_execute" "covid19_agent" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_semantic_view.covid19, snowflake_execute.semantic_view_grant]

  execute = <<-SQL
    CREATE OR REPLACE AGENT "${snowflake_database.cortex.name}"."${snowflake_schema.agents.name}"."${var.agent_name}"
      COMMENT = 'COVID-19パンデミックデータを自然言語で分析するCortexエージェント（Snowflake Intelligence連携）'
      FROM SPECIFICATION $$
${local.agent_spec}      $$
  SQL

  revert = "DROP AGENT IF EXISTS \"${snowflake_database.cortex.name}\".\"${snowflake_schema.agents.name}\".\"${var.agent_name}\""
}

# -----------------------------------------------------------------------------
# Agent への USAGE 権限（CORTEX_ROLE）
#   Snowflake Intelligence で sandbox_user がこのエージェントを使用するために必要
# -----------------------------------------------------------------------------
resource "snowflake_execute" "agent_usage_grant" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_execute.covid19_agent]

  execute = "GRANT USAGE ON AGENT \"${snowflake_database.cortex.name}\".\"${snowflake_schema.agents.name}\".\"${var.agent_name}\" TO ROLE ${var.cortex_role_name}"
  revert  = "REVOKE USAGE ON AGENT \"${snowflake_database.cortex.name}\".\"${snowflake_schema.agents.name}\".\"${var.agent_name}\" FROM ROLE ${var.cortex_role_name}"
}
