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
  comment  = "COVID-19分析用セマンティックビュー"

  # --- 論理テーブル定義 ---
  tables {
    table_alias = "JHU_TIMESERIES"
    table_name  = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_materialized_view.mv_jhu_timeseries.name}\""
    primary_key = ["ISO3", "DATE"]
  }
  tables {
    table_alias = "WORLD_TESTING"
    table_name  = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_materialized_view.mv_covid19_world_testing.name}\""
    primary_key = ["ISO_CODE", "DATE"]
  }

  # --- テーブル間リレーション: JHU_TIMESERIES LEFT OUTER JOIN WORLD_TESTING on iso3=iso_code, date=date ---
  relationships {
    relationship_identifier = "JHU_TO_WORLD"
    table_name_or_alias {
      table_alias = "JHU_TIMESERIES"
    }
    referenced_table_name_or_alias {
      table_alias = "WORLD_TESTING"
    }
    relationship_columns            = ["ISO3", "DATE"]
    referenced_relationship_columns = ["ISO_CODE", "DATE"]
  }

  # --- ディメンション（絞り込み・グルーピング軸）---
  dimensions {
    qualified_expression_name = "\"JHU_TIMESERIES\".\"COUNTRY_REGION\""
    sql_expression            = "\"JHU_TIMESERIES\".\"COUNTRY_REGION\""
    comment                   = "国または地域の名前"
    synonym                   = toset(["country", "nation", "国", "国名", "地域"])
  }
  dimensions {
    qualified_expression_name = "\"JHU_TIMESERIES\".\"ISO3\""
    sql_expression            = "\"JHU_TIMESERIES\".\"ISO3\""
    comment                   = "ISO 3文字国コード"
    synonym                   = toset(["country code", "iso code", "国コード"])
  }
  dimensions {
    qualified_expression_name = "\"JHU_TIMESERIES\".\"PROVINCE_STATE\""
    sql_expression            = "\"JHU_TIMESERIES\".\"PROVINCE_STATE\""
    comment                   = "州・省の名前。NULLは国全体"
    synonym                   = toset(["province", "state", "州", "省"])
  }
  dimensions {
    qualified_expression_name = "\"JHU_TIMESERIES\".\"DATE\""
    sql_expression            = "\"JHU_TIMESERIES\".\"DATE\""
    comment                   = "記録日"
  }
  dimensions {
    qualified_expression_name = "\"WORLD_TESTING\".\"CONTINENT\""
    sql_expression            = "\"WORLD_TESTING\".\"CONTINENT\""
    comment                   = "大陸名"
    synonym                   = toset(["continent", "大陸", "地域区分"])
  }

  # --- ファクト（生の数値列）---
  facts {
    qualified_expression_name = "\"JHU_TIMESERIES\".\"CONFIRMED\""
    sql_expression            = "\"JHU_TIMESERIES\".\"CONFIRMED\""
    comment                   = "累計感染確認者数"
    synonym                   = toset(["cases", "感染者数", "陽性者数", "累計感染者数"])
  }
  facts {
    qualified_expression_name = "\"JHU_TIMESERIES\".\"DEATHS\""
    sql_expression            = "\"JHU_TIMESERIES\".\"DEATHS\""
    comment                   = "累計死者数"
    synonym                   = toset(["fatalities", "死者数", "死亡者数", "累計死者数"])
  }
  facts {
    qualified_expression_name = "\"JHU_TIMESERIES\".\"RECOVERED\""
    sql_expression            = "\"JHU_TIMESERIES\".\"RECOVERED\""
    comment                   = "累計回復者数"
    synonym                   = toset(["recoveries", "回復者数", "完治者数"])
  }
  facts {
    qualified_expression_name = "\"WORLD_TESTING\".\"GDP_PER_CAPITA\""
    sql_expression            = "\"WORLD_TESTING\".\"GDP_PER_CAPITA\""
    comment                   = "一人当たりGDP"
    synonym                   = toset(["GDP", "一人当たりGDP"])
  }
  facts {
    qualified_expression_name = "\"WORLD_TESTING\".\"NEW_CASES\""
    sql_expression            = "\"WORLD_TESTING\".\"NEW_CASES\""
    comment                   = "日次新規感染者数"
    synonym                   = toset(["daily cases", "新規感染者数", "日次感染者数"])
  }
  facts {
    qualified_expression_name = "\"WORLD_TESTING\".\"NEW_DEATHS\""
    sql_expression            = "\"WORLD_TESTING\".\"NEW_DEATHS\""
    comment                   = "日次新規死者数"
    synonym                   = toset(["daily deaths", "新規死者数"])
  }
  facts {
    qualified_expression_name = "\"WORLD_TESTING\".\"PEOPLE_FULLY_VACCINATED\""
    sql_expression            = "\"WORLD_TESTING\".\"PEOPLE_FULLY_VACCINATED\""
    comment                   = "ワクチン接種完了者数"
    synonym                   = toset(["fully vaccinated", "ワクチン完全接種者数", "完全接種者数"])
  }
  facts {
    qualified_expression_name = "\"WORLD_TESTING\".\"POPULATION\""
    sql_expression            = "\"WORLD_TESTING\".\"POPULATION\""
    comment                   = "国の総人口"
    synonym                   = toset(["population", "人口", "総人口"])
  }
  facts {
    qualified_expression_name = "\"WORLD_TESTING\".\"TOTAL_TESTS\""
    sql_expression            = "\"WORLD_TESTING\".\"TOTAL_TESTS\""
    comment                   = "累計検査数"
    synonym                   = toset(["総検査数", "累計検査数"])
  }
  facts {
    qualified_expression_name = "\"WORLD_TESTING\".\"TOTAL_VACCINATIONS\""
    sql_expression            = "\"WORLD_TESTING\".\"TOTAL_VACCINATIONS\""
    comment                   = "ワクチン接種総回数"
    synonym                   = toset(["ワクチン接種総数", "累計ワクチン接種数"])
  }

  # --- メトリクス（集計計算式）---
  metrics {
    semantic_expression {
      qualified_expression_name = "\"JHU_TIMESERIES\".\"CASE_FATALITY_RATE\""
      sql_expression            = "CASE WHEN SUM(\"JHU_TIMESERIES\".\"CONFIRMED\") > 0 THEN ROUND(SUM(\"JHU_TIMESERIES\".\"DEATHS\") / SUM(\"JHU_TIMESERIES\".\"CONFIRMED\") * 100, 2) ELSE NULL END"
      comment                   = "致死率（%）"
      synonym                   = toset(["CFR", "fatality rate", "死亡率", "致死率"])
    }
  }
  metrics {
    semantic_expression {
      qualified_expression_name = "\"WORLD_TESTING\".\"VACCINATION_RATE_PCT\""
      sql_expression            = "CASE WHEN SUM(\"WORLD_TESTING\".\"POPULATION\") > 0 THEN ROUND(SUM(\"WORLD_TESTING\".\"PEOPLE_FULLY_VACCINATED\") / SUM(\"WORLD_TESTING\".\"POPULATION\") * 100, 1) ELSE NULL END"
      comment                   = "ワクチン接種率（%）"
      synonym                   = toset(["vaccination rate", "ワクチン接種率", "完全接種率"])
    }
  }
}

# -----------------------------------------------------------------------------
# Semantic View への SELECT 権限（FR_CORTEX_ADMIN）
#   Provider が SEMANTIC VIEW オブジェクト型を未サポートの可能性があるため
#   snowflake_execute で GRANT SQL を直接実行する
# -----------------------------------------------------------------------------
resource "snowflake_execute" "semantic_view_grant" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_semantic_view.covid19]

  execute = "GRANT SELECT ON SEMANTIC VIEW \"${snowflake_database.cortex.name}\".\"${snowflake_schema.semantic_models.name}\".\"${var.semantic_view_name}\" TO ROLE ${var.fr_cortex_admin_role_name}"
  revert  = "REVOKE SELECT ON SEMANTIC VIEW \"${snowflake_database.cortex.name}\".\"${snowflake_schema.semantic_models.name}\".\"${var.semantic_view_name}\" FROM ROLE ${var.fr_cortex_admin_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_semantic_view.covid19]
  }
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
# Agent への USAGE 権限（FR_CORTEX_ADMIN）
#   Snowflake Intelligence で sandbox_user がこのエージェントを使用するために必要
# -----------------------------------------------------------------------------
resource "snowflake_execute" "agent_usage_grant" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_execute.covid19_agent]

  execute = "GRANT USAGE ON AGENT \"${snowflake_database.cortex.name}\".\"${snowflake_schema.agents.name}\".\"${var.agent_name}\" TO ROLE ${var.fr_cortex_admin_role_name}"
  revert  = "REVOKE USAGE ON AGENT \"${snowflake_database.cortex.name}\".\"${snowflake_schema.agents.name}\".\"${var.agent_name}\" FROM ROLE ${var.fr_cortex_admin_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_execute.covid19_agent]
  }
}

# -----------------------------------------------------------------------------
# COVID19 Cortex リソース利用権限（FR_CORTEX_USE）
#   FR_CORTEX_USE を継承した DEVELOPER_ROLE / VIEWER_ROLE に適用される
# -----------------------------------------------------------------------------

# COVID19_SEMANTIC セマンティックビューへの SELECT 権限（FR_CORTEX_USE）
resource "snowflake_execute" "covid19_semantic_view_grant_use" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_semantic_view.covid19]

  execute = "GRANT SELECT ON SEMANTIC VIEW \"${snowflake_database.cortex.name}\".\"${snowflake_schema.semantic_models.name}\".\"${var.semantic_view_name}\" TO ROLE ${var.fr_cortex_use_role_name}"
  revert  = "REVOKE SELECT ON SEMANTIC VIEW \"${snowflake_database.cortex.name}\".\"${snowflake_schema.semantic_models.name}\".\"${var.semantic_view_name}\" FROM ROLE ${var.fr_cortex_use_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_semantic_view.covid19]
  }
}

# COVID19_AGENT への USAGE 権限（FR_CORTEX_USE）
resource "snowflake_execute" "covid19_agent_grant_use" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_execute.covid19_agent]

  execute = "GRANT USAGE ON AGENT \"${snowflake_database.cortex.name}\".\"${snowflake_schema.agents.name}\".\"${var.agent_name}\" TO ROLE ${var.fr_cortex_use_role_name}"
  revert  = "REVOKE USAGE ON AGENT \"${snowflake_database.cortex.name}\".\"${snowflake_schema.agents.name}\".\"${var.agent_name}\" FROM ROLE ${var.fr_cortex_use_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_execute.covid19_agent]
  }
}
