# =============================================================================
# COVID-19 Semantic View + Cortex Agent
#
# 注意: AGENTS スキーマは cortex モジュールで作成済み（var.agents_schema_name で受け取る）
# =============================================================================

resource "snowflake_semantic_view" "covid19" {
  provider = snowflake.sysadmin

  database = var.cortex_db_name
  schema   = var.semantic_models_schema_name
  name     = var.semantic_view_name
  comment  = "COVID-19分析用セマンティックビュー"

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

resource "snowflake_execute" "semantic_view_grant" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_semantic_view.covid19]

  execute = "GRANT SELECT ON SEMANTIC VIEW \"${var.cortex_db_name}\".\"${var.semantic_models_schema_name}\".\"${var.semantic_view_name}\" TO ROLE ${var.fr_cortex_admin_role_name}"
  revert  = "REVOKE SELECT ON SEMANTIC VIEW \"${var.cortex_db_name}\".\"${var.semantic_models_schema_name}\".\"${var.semantic_view_name}\" FROM ROLE ${var.fr_cortex_admin_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_semantic_view.covid19]
  }
}

locals {
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
        semantic_view: "${var.cortex_db_name}.${var.semantic_models_schema_name}.${var.semantic_view_name}"
        execution_environment:
          type: warehouse
          warehouse: "${var.sandbox_wh_name}"
  YAML
}

resource "snowflake_execute" "covid19_agent" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_semantic_view.covid19, snowflake_execute.semantic_view_grant]

  execute = <<-SQL
    CREATE OR REPLACE AGENT "${var.cortex_db_name}"."${var.agents_schema_name}"."${var.agent_name}"
      COMMENT = 'COVID-19パンデミックデータを自然言語で分析するCortexエージェント（Snowflake Intelligence連携）'
      FROM SPECIFICATION $$
${local.agent_spec}      $$
  SQL

  revert = "DROP AGENT IF EXISTS \"${var.cortex_db_name}\".\"${var.agents_schema_name}\".\"${var.agent_name}\""
}

resource "snowflake_execute" "agent_usage_grant" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_execute.covid19_agent]

  execute = "GRANT USAGE ON AGENT \"${var.cortex_db_name}\".\"${var.agents_schema_name}\".\"${var.agent_name}\" TO ROLE ${var.fr_cortex_admin_role_name}"
  revert  = "REVOKE USAGE ON AGENT \"${var.cortex_db_name}\".\"${var.agents_schema_name}\".\"${var.agent_name}\" FROM ROLE ${var.fr_cortex_admin_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_execute.covid19_agent]
  }
}

resource "snowflake_execute" "covid19_semantic_view_grant_use" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_semantic_view.covid19]

  execute = "GRANT SELECT ON SEMANTIC VIEW \"${var.cortex_db_name}\".\"${var.semantic_models_schema_name}\".\"${var.semantic_view_name}\" TO ROLE ${var.fr_cortex_use_role_name}"
  revert  = "REVOKE SELECT ON SEMANTIC VIEW \"${var.cortex_db_name}\".\"${var.semantic_models_schema_name}\".\"${var.semantic_view_name}\" FROM ROLE ${var.fr_cortex_use_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_semantic_view.covid19]
  }
}

resource "snowflake_execute" "covid19_agent_grant_use" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_execute.covid19_agent]

  execute = "GRANT USAGE ON AGENT \"${var.cortex_db_name}\".\"${var.agents_schema_name}\".\"${var.agent_name}\" TO ROLE ${var.fr_cortex_use_role_name}"
  revert  = "REVOKE USAGE ON AGENT \"${var.cortex_db_name}\".\"${var.agents_schema_name}\".\"${var.agent_name}\" FROM ROLE ${var.fr_cortex_use_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_execute.covid19_agent]
  }
}
