# =============================================================================
# 家計簿 Cortex リソース: Semantic View + Search Service + Agent
# =============================================================================

resource "snowflake_semantic_view" "budget_book" {
  provider = snowflake.sysadmin

  database = var.cortex_db_name
  schema   = var.semantic_models_schema_name
  name     = var.budget_book_semantic_view_name
  comment  = "家計簿分析用セマンティックビュー（Cortex Analyst連携）"

  tables {
    table_alias = "MF"
    table_name  = "\"${var.raw_db_name}\".\"${snowflake_schema.budget_book.name}\".\"${snowflake_table.budget_book_transactions.name}\""
    primary_key = ["ID"]
  }

  dimensions {
    qualified_expression_name = "\"MF\".\"TRANSACTION_DATE\""
    sql_expression            = "\"MF\".\"TRANSACTION_DATE\""
    comment                   = "取引日"
    synonym                   = toset(["日付", "取引日", "date", "購入日", "支払日"])
  }
  dimensions {
    qualified_expression_name = "\"MF\".\"DESCRIPTION\""
    sql_expression            = "\"MF\".\"DESCRIPTION\""
    comment                   = "取引内容・店舗名"
    synonym                   = toset(["内容", "取引内容", "店舗名", "店名", "description"])
  }
  dimensions {
    qualified_expression_name = "\"MF\".\"INSTITUTION\""
    sql_expression            = "\"MF\".\"INSTITUTION\""
    comment                   = "保有金融機関・カード名"
    synonym                   = toset(["金融機関", "銀行", "カード", "クレジットカード", "口座", "保有金融機関"])
  }
  dimensions {
    qualified_expression_name = "\"MF\".\"MAJOR_CATEGORY\""
    sql_expression            = "\"MF\".\"MAJOR_CATEGORY\""
    comment                   = "大項目カテゴリ（食費・交通費等）"
    synonym                   = toset(["大項目", "カテゴリ", "category", "支出種別", "費目"])
  }
  dimensions {
    qualified_expression_name = "\"MF\".\"MINOR_CATEGORY\""
    sql_expression            = "\"MF\".\"MINOR_CATEGORY\""
    comment                   = "中項目カテゴリ（外食・コンビニ等）"
    synonym                   = toset(["中項目", "サブカテゴリ", "subcategory", "細目"])
  }
  dimensions {
    qualified_expression_name = "\"MF\".\"CALCULATION_TARGET\""
    sql_expression            = "\"MF\".\"CALCULATION_TARGET\""
    comment                   = "計算対象フラグ（1=対象, 0=対象外）"
    synonym                   = toset(["計算対象", "集計対象", "対象フラグ"])
  }
  dimensions {
    qualified_expression_name = "\"MF\".\"TRANSFER_FLAG\""
    sql_expression            = "\"MF\".\"TRANSFER_FLAG\""
    comment                   = "振替フラグ（1=振替取引, 0=通常取引）"
    synonym                   = toset(["振替", "振替フラグ", "資産移動"])
  }

  facts {
    qualified_expression_name = "\"MF\".\"AMOUNT\""
    sql_expression            = "\"MF\".\"AMOUNT\""
    comment                   = "金額（円）。負数=支出、正数=収入"
    synonym                   = toset(["金額", "支出", "収入", "amount", "円", "お金"])
  }

  metrics {
    semantic_expression {
      qualified_expression_name = "\"MF\".\"MONTHLY_SPENDING\""
      sql_expression            = "SUM(CASE WHEN \"MF\".\"AMOUNT\" < 0 AND \"MF\".\"CALCULATION_TARGET\" = 1 AND \"MF\".\"TRANSFER_FLAG\" = 0 AND \"MF\".\"MAJOR_CATEGORY\" != '現金・ATM' THEN ABS(\"MF\".\"AMOUNT\") ELSE 0 END)"
      comment                   = "月別支出合計（計算対象かつ振替除外・ATM引き出し除外）"
      synonym                   = toset(["月別支出", "月の支出合計", "月次支出", "monthly spending"])
    }
  }
  metrics {
    semantic_expression {
      qualified_expression_name = "\"MF\".\"CATEGORY_SPENDING\""
      sql_expression            = "SUM(CASE WHEN \"MF\".\"AMOUNT\" < 0 AND \"MF\".\"CALCULATION_TARGET\" = 1 AND \"MF\".\"TRANSFER_FLAG\" = 0 AND \"MF\".\"MAJOR_CATEGORY\" != '現金・ATM' THEN ABS(\"MF\".\"AMOUNT\") ELSE 0 END)"
      comment                   = "カテゴリ別支出合計（計算対象かつ振替除外・ATM引き出し除外）"
      synonym                   = toset(["カテゴリ別支出", "費目別支出", "項目別支出", "category spending"])
    }
  }
  metrics {
    semantic_expression {
      qualified_expression_name = "\"MF\".\"MONTHLY_INCOME\""
      sql_expression            = "SUM(CASE WHEN \"MF\".\"AMOUNT\" > 0 AND \"MF\".\"CALCULATION_TARGET\" = 1 AND \"MF\".\"TRANSFER_FLAG\" = 0 THEN \"MF\".\"AMOUNT\" ELSE 0 END)"
      comment                   = "月別収入合計（計算対象かつ振替除外）"
      synonym                   = toset(["月別収入", "月次収入", "monthly income", "収入合計"])
    }
  }

  depends_on = [snowflake_table.budget_book_transactions]
}

resource "snowflake_execute" "budget_book_semantic_view_grant_cortex" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_semantic_view.budget_book]

  execute = "GRANT SELECT ON SEMANTIC VIEW \"${var.cortex_db_name}\".\"${var.semantic_models_schema_name}\".\"${var.budget_book_semantic_view_name}\" TO ROLE ${var.fr_cortex_admin_role_name}"
  revert  = "REVOKE SELECT ON SEMANTIC VIEW \"${var.cortex_db_name}\".\"${var.semantic_models_schema_name}\".\"${var.budget_book_semantic_view_name}\" FROM ROLE ${var.fr_cortex_admin_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_semantic_view.budget_book]
  }
}

resource "snowflake_execute" "budget_book_search_service" {
  provider = snowflake.sysadmin
  depends_on = [
    snowflake_table.budget_book_transactions,
  ]

  execute = <<-SQL
    CREATE OR REPLACE CORTEX SEARCH SERVICE "${var.cortex_db_name}"."${var.search_services_schema_name}"."${var.budget_book_search_service_name}"
      ON SEARCH_TEXT
      ATTRIBUTES MINOR_CATEGORY, MAJOR_CATEGORY
      WAREHOUSE = ${var.sandbox_wh_name}
      TARGET_LAG = '1 hour'
      EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
      COMMENT = '家計簿取引の内容・カテゴリ検索（CONCAT_WS + arctic-embed-l-v2.0）'
    AS (
      SELECT
        *,
        CONCAT_WS(' ', DESCRIPTION, MAJOR_CATEGORY, MINOR_CATEGORY) AS SEARCH_TEXT
      FROM "${var.raw_db_name}"."${snowflake_schema.budget_book.name}"."${snowflake_table.budget_book_transactions.name}"
      WHERE CALCULATION_TARGET = 1
        AND TRANSFER_FLAG = 0
    )
  SQL

  revert = "DROP CORTEX SEARCH SERVICE IF EXISTS \"${var.cortex_db_name}\".\"${var.search_services_schema_name}\".\"${var.budget_book_search_service_name}\""
}

resource "snowflake_execute" "budget_book_search_service_grant_cortex" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_execute.budget_book_search_service]

  execute = "GRANT USAGE ON CORTEX SEARCH SERVICE \"${var.cortex_db_name}\".\"${var.search_services_schema_name}\".\"${var.budget_book_search_service_name}\" TO ROLE ${var.fr_cortex_admin_role_name}"
  revert  = "REVOKE USAGE ON CORTEX SEARCH SERVICE \"${var.cortex_db_name}\".\"${var.search_services_schema_name}\".\"${var.budget_book_search_service_name}\" FROM ROLE ${var.fr_cortex_admin_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_execute.budget_book_search_service]
  }
}

resource "snowflake_execute" "budget_book_search_service_monitor_cortex" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_execute.budget_book_search_service]

  execute = "GRANT MONITOR ON CORTEX SEARCH SERVICE \"${var.cortex_db_name}\".\"${var.search_services_schema_name}\".\"${var.budget_book_search_service_name}\" TO ROLE ${var.fr_cortex_admin_role_name}"
  revert  = "REVOKE MONITOR ON CORTEX SEARCH SERVICE \"${var.cortex_db_name}\".\"${var.search_services_schema_name}\".\"${var.budget_book_search_service_name}\" FROM ROLE ${var.fr_cortex_admin_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_execute.budget_book_search_service]
  }
}

locals {
  budget_book_agent_spec = <<-YAML
    models:
      orchestration: claude-4-sonnet
    orchestration:
      budget:
        seconds: 60
        tokens: 32000
    instructions:
      response: "日本語で回答してください。金額は円表記で、カテゴリ名はそのまま使用してください。"
      system: "あなたはMoneyForwardの家計簿データアナリストです。支出・収入の分析、カテゴリ別集計、月次トレンドの把握を支援します。振替取引（TRANSFER_FLAG=1）と計算対象外（CALCULATION_TARGET=0）は集計から除外してください。"
      sample_questions:
        - question: "今月の支出合計を教えてください"
          answer: "MONTHLY_SPENDINGメトリクスで当月のAMOUNTを集計します"
        - question: "食費の月別推移を教えてください"
          answer: "MAJOR_CATEGORY='食費'でフィルタして月次集計します"
        - question: "どのカテゴリに一番お金を使っていますか"
          answer: "CATEGORY_SPENDINGをMAJOR_CATEGORYでグループ化して降順ソートします"
        - question: "コンビニでの支出を調べてください"
          answer: "Cortex SearchでDESCRIPTIONからコンビニ関連の取引を検索します"
    tools:
      - tool_spec:
          type: cortex_analyst_text_to_sql
          name: budget_book_analyst
          description: "家計簿の支出・収入データを自然言語でSQL分析するツール。月次集計・カテゴリ別集計・トレンド分析が可能。"
      - tool_spec:
          type: cortex_search
          name: budget_book_search
          description: "家計簿の取引内容・カテゴリ名をキーワード検索するツール。特定の店舗名や費目の推論、金融機関・日付でのフィルターが可能。"
    tool_resources:
      budget_book_analyst:
        semantic_view: "${var.cortex_db_name}.${var.semantic_models_schema_name}.${var.budget_book_semantic_view_name}"
        execution_environment:
          type: warehouse
          warehouse: "${var.sandbox_wh_name}"
      budget_book_search:
        search_service: "${var.cortex_db_name}.${var.search_services_schema_name}.${var.budget_book_search_service_name}"
        max_results: 10
  YAML
}

resource "snowflake_execute" "budget_book_agent" {
  provider = snowflake.sysadmin
  depends_on = [
    snowflake_semantic_view.budget_book,
    snowflake_execute.budget_book_semantic_view_grant_cortex,
    snowflake_execute.budget_book_search_service,
    snowflake_execute.budget_book_search_service_grant_cortex,
  ]

  execute = <<-SQL
    CREATE OR REPLACE AGENT "${var.cortex_db_name}"."${var.agents_schema_name}"."${var.budget_book_agent_name}"
      COMMENT = '家計簿データを自然言語で分析するCortexエージェント（Analyst + Search）'
      FROM SPECIFICATION $$
${local.budget_book_agent_spec}      $$
  SQL

  revert = "DROP AGENT IF EXISTS \"${var.cortex_db_name}\".\"${var.agents_schema_name}\".\"${var.budget_book_agent_name}\""
}

resource "snowflake_execute" "budget_book_agent_grant_cortex" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_execute.budget_book_agent]

  execute = "GRANT USAGE ON AGENT \"${var.cortex_db_name}\".\"${var.agents_schema_name}\".\"${var.budget_book_agent_name}\" TO ROLE ${var.fr_cortex_admin_role_name}"
  revert  = "REVOKE USAGE ON AGENT \"${var.cortex_db_name}\".\"${var.agents_schema_name}\".\"${var.budget_book_agent_name}\" FROM ROLE ${var.fr_cortex_admin_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_execute.budget_book_agent]
  }
}

resource "snowflake_execute" "budget_book_semantic_view_grant_use" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_semantic_view.budget_book]

  execute = "GRANT SELECT ON SEMANTIC VIEW \"${var.cortex_db_name}\".\"${var.semantic_models_schema_name}\".\"${var.budget_book_semantic_view_name}\" TO ROLE ${var.fr_cortex_use_role_name}"
  revert  = "REVOKE SELECT ON SEMANTIC VIEW \"${var.cortex_db_name}\".\"${var.semantic_models_schema_name}\".\"${var.budget_book_semantic_view_name}\" FROM ROLE ${var.fr_cortex_use_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_semantic_view.budget_book]
  }
}

resource "snowflake_execute" "budget_book_search_service_grant_use" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_execute.budget_book_search_service]

  execute = "GRANT USAGE ON CORTEX SEARCH SERVICE \"${var.cortex_db_name}\".\"${var.search_services_schema_name}\".\"${var.budget_book_search_service_name}\" TO ROLE ${var.fr_cortex_use_role_name}"
  revert  = "REVOKE USAGE ON CORTEX SEARCH SERVICE \"${var.cortex_db_name}\".\"${var.search_services_schema_name}\".\"${var.budget_book_search_service_name}\" FROM ROLE ${var.fr_cortex_use_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_execute.budget_book_search_service]
  }
}

resource "snowflake_execute" "budget_book_agent_grant_use" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_execute.budget_book_agent]

  execute = "GRANT USAGE ON AGENT \"${var.cortex_db_name}\".\"${var.agents_schema_name}\".\"${var.budget_book_agent_name}\" TO ROLE ${var.fr_cortex_use_role_name}"
  revert  = "REVOKE USAGE ON AGENT \"${var.cortex_db_name}\".\"${var.agents_schema_name}\".\"${var.budget_book_agent_name}\" FROM ROLE ${var.fr_cortex_use_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_execute.budget_book_agent]
  }
}
