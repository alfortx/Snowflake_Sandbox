# =============================================================================
# 家計簿データ (MoneyForward) - Cortex リソース
#
# 構成:
#   CORTEX_DB.SEMANTIC_MODELS.BUDGET_BOOK_SEMANTIC  (Cortex Analyst用)
#   CORTEX_DB.SEARCH_SERVICES.BUDGET_BOOK_SEARCH    (Cortex Search)
#   CORTEX_DB.AGENTS.BUDGET_BOOK_AGENT              (2ツール構成 Agent)
#
# 依存関係:
#   moneyforward.tf の TRANSACTIONS テーブルが先に作成されている必要がある
# =============================================================================

# =============================================================================
# Semantic View: BUDGET_BOOK_SEMANTIC
#   Cortex Analyst の cortex_analyst_text_to_sql ツールが使用するビュー
#   TRANSACTIONS テーブルの列名（英語）に日本語 synonym を付与
# =============================================================================
resource "snowflake_semantic_view" "budget_book" {
  provider = snowflake.sysadmin

  database = snowflake_database.cortex.name
  schema   = snowflake_schema.semantic_models.name
  name     = var.budget_book_semantic_view_name
  comment  = "家計簿分析用セマンティックビュー（Cortex Analyst連携）"

  tables {
    table_alias = "MF"
    table_name  = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.budget_book.name}\".\"${snowflake_table.budget_book_transactions.name}\""
    primary_key = ["ID"]
  }

  # --- ディメンション（絞り込み・グルーピング軸）---
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

  # --- ファクト（生の数値列）---
  facts {
    qualified_expression_name = "\"MF\".\"AMOUNT\""
    sql_expression            = "\"MF\".\"AMOUNT\""
    comment                   = "金額（円）。負数=支出、正数=収入"
    synonym                   = toset(["金額", "支出", "収入", "amount", "円", "お金"])
  }

  # --- メトリクス（集計計算式）---
  # 振替取引(TRANSFER_FLAG=1)と計算対象外(CALCULATION_TARGET=0)を自動除外
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

# セマンティックビューへの SELECT 権限（CORTEX_ROLE）
resource "snowflake_execute" "budget_book_semantic_view_grant_cortex" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_semantic_view.budget_book]

  execute = "GRANT SELECT ON SEMANTIC VIEW \"${snowflake_database.cortex.name}\".\"${snowflake_schema.semantic_models.name}\".\"${var.budget_book_semantic_view_name}\" TO ROLE ${var.cortex_role_name}"
  revert  = "REVOKE SELECT ON SEMANTIC VIEW \"${snowflake_database.cortex.name}\".\"${snowflake_schema.semantic_models.name}\".\"${var.budget_book_semantic_view_name}\" FROM ROLE ${var.cortex_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_semantic_view.budget_book]
  }
}

# =============================================================================
# CORTEX_ROLEへの RAW_DB.BUDGET_BOOK アクセス権限
#   セマンティックビューとCortex SearchがTRANSACTIONSテーブルを参照するために必要
# =============================================================================

resource "snowflake_grant_privileges_to_account_role" "cortex_budget_book_schema_usage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.cortex_role.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.budget_book.name}\""
  }
}

resource "snowflake_grant_privileges_to_account_role" "cortex_budget_book_transactions_select" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.cortex_role.name
  privileges        = ["SELECT"]

  on_schema_object {
    object_type = "TABLE"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.budget_book.name}\".\"${snowflake_table.budget_book_transactions.name}\""
  }
}

# =============================================================================
# Cortex Search サービス: BUDGET_BOOK_SEARCH
#   内容・カテゴリ名の全文検索、金融機関・日付・大項目でフィルター可能
# =============================================================================
resource "snowflake_execute" "budget_book_search_service" {
  provider = snowflake.sysadmin
  depends_on = [
    snowflake_table.budget_book_transactions,
    snowflake_grant_privileges_to_account_role.cortex_budget_book_schema_usage,
    snowflake_grant_privileges_to_account_role.cortex_budget_book_transactions_select,
  ]

  execute = <<-SQL
    CREATE OR REPLACE CORTEX SEARCH SERVICE "${snowflake_database.cortex.name}"."${snowflake_schema.search_services.name}"."${var.budget_book_search_service_name}"
      ON SEARCH_TEXT
      ATTRIBUTES MINOR_CATEGORY, MAJOR_CATEGORY
      WAREHOUSE = ${snowflake_warehouse.sandbox.name}
      TARGET_LAG = '1 hour'
      EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
      COMMENT = '家計簿取引の内容・カテゴリ検索（CONCAT_WS + arctic-embed-l-v2.0）'
    AS (
      SELECT
        *,
        CONCAT_WS(' ', DESCRIPTION, MAJOR_CATEGORY, MINOR_CATEGORY) AS SEARCH_TEXT
      FROM "${snowflake_database.raw_db.name}"."${snowflake_schema.budget_book.name}"."${snowflake_table.budget_book_transactions.name}"
      WHERE CALCULATION_TARGET = 1
        AND TRANSFER_FLAG = 0
    )
  SQL

  revert = "DROP CORTEX SEARCH SERVICE IF EXISTS \"${snowflake_database.cortex.name}\".\"${snowflake_schema.search_services.name}\".\"${var.budget_book_search_service_name}\""
}

# Cortex Search サービスへの USAGE 権限（CORTEX_ROLE）
resource "snowflake_execute" "budget_book_search_service_grant_cortex" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_execute.budget_book_search_service]

  execute = "GRANT USAGE ON CORTEX SEARCH SERVICE \"${snowflake_database.cortex.name}\".\"${snowflake_schema.search_services.name}\".\"${var.budget_book_search_service_name}\" TO ROLE ${var.cortex_role_name}"
  revert  = "REVOKE USAGE ON CORTEX SEARCH SERVICE \"${snowflake_database.cortex.name}\".\"${snowflake_schema.search_services.name}\".\"${var.budget_book_search_service_name}\" FROM ROLE ${var.cortex_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_execute.budget_book_search_service]
  }
}

# =============================================================================
# Cortex Agent: BUDGET_BOOK_AGENT
#   cortex_analyst_text_to_sql + cortex_search の2ツール構成
# =============================================================================
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
        semantic_view: "${snowflake_database.cortex.name}.${snowflake_schema.semantic_models.name}.${var.budget_book_semantic_view_name}"
        execution_environment:
          type: warehouse
          warehouse: "${snowflake_warehouse.sandbox.name}"
      budget_book_search:
        search_service: "${snowflake_database.cortex.name}.${snowflake_schema.search_services.name}.${var.budget_book_search_service_name}"
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
    CREATE OR REPLACE AGENT "${snowflake_database.cortex.name}"."${snowflake_schema.agents.name}"."${var.budget_book_agent_name}"
      COMMENT = '家計簿データを自然言語で分析するCortexエージェント（Analyst + Search）'
      FROM SPECIFICATION $$
${local.budget_book_agent_spec}      $$
  SQL

  revert = "DROP AGENT IF EXISTS \"${snowflake_database.cortex.name}\".\"${snowflake_schema.agents.name}\".\"${var.budget_book_agent_name}\""
}

# Agent への USAGE 権限（CORTEX_ROLE）
resource "snowflake_execute" "budget_book_agent_grant_cortex" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_execute.budget_book_agent]

  execute = "GRANT USAGE ON AGENT \"${snowflake_database.cortex.name}\".\"${snowflake_schema.agents.name}\".\"${var.budget_book_agent_name}\" TO ROLE ${var.cortex_role_name}"
  revert  = "REVOKE USAGE ON AGENT \"${snowflake_database.cortex.name}\".\"${snowflake_schema.agents.name}\".\"${var.budget_book_agent_name}\" FROM ROLE ${var.cortex_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_execute.budget_book_agent]
  }
}

# =============================================================================
# DEVELOPER_ROLE への CORTEX_DB 権限付与
# =============================================================================

# CORTEX_DB への USAGE 権限
resource "snowflake_grant_privileges_to_account_role" "sandbox_cortex_db_usage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.developer_role.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.cortex.name
  }
}

# CORTEX_DB.SEMANTIC_MODELS スキーマへの USAGE 権限
resource "snowflake_grant_privileges_to_account_role" "sandbox_semantic_models_usage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.developer_role.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "\"${snowflake_database.cortex.name}\".\"${snowflake_schema.semantic_models.name}\""
  }
}

# CORTEX_DB.SEARCH_SERVICES スキーマへの USAGE 権限
resource "snowflake_grant_privileges_to_account_role" "sandbox_search_services_usage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.developer_role.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "\"${snowflake_database.cortex.name}\".\"${snowflake_schema.search_services.name}\""
  }
}

# CORTEX_DB.AGENTS スキーマへの USAGE 権限
resource "snowflake_grant_privileges_to_account_role" "sandbox_agents_schema_usage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.developer_role.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "\"${snowflake_database.cortex.name}\".\"${snowflake_schema.agents.name}\""
  }
}

# BUDGET_BOOK_SEMANTIC セマンティックビューへの SELECT 権限（DEVELOPER_ROLE）
resource "snowflake_execute" "budget_book_semantic_view_grant_sandbox" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_semantic_view.budget_book]

  execute = "GRANT SELECT ON SEMANTIC VIEW \"${snowflake_database.cortex.name}\".\"${snowflake_schema.semantic_models.name}\".\"${var.budget_book_semantic_view_name}\" TO ROLE ${var.developer_role_name}"
  revert  = "REVOKE SELECT ON SEMANTIC VIEW \"${snowflake_database.cortex.name}\".\"${snowflake_schema.semantic_models.name}\".\"${var.budget_book_semantic_view_name}\" FROM ROLE ${var.developer_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_semantic_view.budget_book]
  }
}

# BUDGET_BOOK_SEARCH への USAGE 権限（DEVELOPER_ROLE）
resource "snowflake_execute" "budget_book_search_service_grant_sandbox" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_execute.budget_book_search_service]

  execute = "GRANT USAGE ON CORTEX SEARCH SERVICE \"${snowflake_database.cortex.name}\".\"${snowflake_schema.search_services.name}\".\"${var.budget_book_search_service_name}\" TO ROLE ${var.developer_role_name}"
  revert  = "REVOKE USAGE ON CORTEX SEARCH SERVICE \"${snowflake_database.cortex.name}\".\"${snowflake_schema.search_services.name}\".\"${var.budget_book_search_service_name}\" FROM ROLE ${var.developer_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_execute.budget_book_search_service]
  }
}

# BUDGET_BOOK_SEARCH への MONITOR 権限（DEVELOPER_ROLE）
resource "snowflake_execute" "budget_book_search_monitor_sandbox" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_execute.budget_book_search_service]

  execute = "GRANT MONITOR ON CORTEX SEARCH SERVICE \"${snowflake_database.cortex.name}\".\"${snowflake_schema.search_services.name}\".\"${var.budget_book_search_service_name}\" TO ROLE ${var.developer_role_name}"
  revert  = "REVOKE MONITOR ON CORTEX SEARCH SERVICE \"${snowflake_database.cortex.name}\".\"${snowflake_schema.search_services.name}\".\"${var.budget_book_search_service_name}\" FROM ROLE ${var.developer_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_execute.budget_book_search_service]
  }
}

# BUDGET_BOOK_AGENT への USAGE 権限（DEVELOPER_ROLE）
resource "snowflake_execute" "budget_book_agent_grant_sandbox" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_execute.budget_book_agent]

  execute = "GRANT USAGE ON AGENT \"${snowflake_database.cortex.name}\".\"${snowflake_schema.agents.name}\".\"${var.budget_book_agent_name}\" TO ROLE ${var.developer_role_name}"
  revert  = "REVOKE USAGE ON AGENT \"${snowflake_database.cortex.name}\".\"${snowflake_schema.agents.name}\".\"${var.budget_book_agent_name}\" FROM ROLE ${var.developer_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_execute.budget_book_agent]
  }
}

# SNOWFLAKE.CORTEX_USER DB ロールを DEVELOPER_ROLE に付与（Cortex ML関数の使用）
resource "snowflake_grant_database_role" "sandbox_cortex_user" {
  provider = snowflake.accountadmin

  database_role_name = "\"SNOWFLAKE\".\"CORTEX_USER\""
  parent_role_name   = snowflake_account_role.developer_role.name
}

# SNOWFLAKE.CORTEX_AGENT_USER DB ロールを DEVELOPER_ROLE に付与（Agent呼び出し）
resource "snowflake_grant_database_role" "sandbox_cortex_agent_user" {
  provider = snowflake.accountadmin

  database_role_name = "\"SNOWFLAKE\".\"CORTEX_AGENT_USER\""
  parent_role_name   = snowflake_account_role.developer_role.name
}

# =============================================================================
# ANALYST_ROLE への CORTEX_DB 権限付与
# =============================================================================

# CORTEX_DB への USAGE 権限
resource "snowflake_grant_privileges_to_account_role" "analyst_cortex_db_usage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.analyst_role.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.cortex.name
  }
}

# CORTEX_DB.SEMANTIC_MODELS スキーマへの USAGE 権限
resource "snowflake_grant_privileges_to_account_role" "analyst_semantic_models_usage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.analyst_role.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "\"${snowflake_database.cortex.name}\".\"${snowflake_schema.semantic_models.name}\""
  }
}

# CORTEX_DB.SEARCH_SERVICES スキーマへの USAGE 権限
resource "snowflake_grant_privileges_to_account_role" "analyst_search_services_usage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.analyst_role.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "\"${snowflake_database.cortex.name}\".\"${snowflake_schema.search_services.name}\""
  }
}

# CORTEX_DB.AGENTS スキーマへの USAGE 権限
resource "snowflake_grant_privileges_to_account_role" "analyst_agents_schema_usage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.analyst_role.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "\"${snowflake_database.cortex.name}\".\"${snowflake_schema.agents.name}\""
  }
}

# BUDGET_BOOK_SEMANTIC セマンティックビューへの SELECT 権限（ANALYST_ROLE）
resource "snowflake_execute" "budget_book_semantic_view_grant_analyst" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_semantic_view.budget_book]

  execute = "GRANT SELECT ON SEMANTIC VIEW \"${snowflake_database.cortex.name}\".\"${snowflake_schema.semantic_models.name}\".\"${var.budget_book_semantic_view_name}\" TO ROLE ${var.analyst_role_name}"
  revert  = "REVOKE SELECT ON SEMANTIC VIEW \"${snowflake_database.cortex.name}\".\"${snowflake_schema.semantic_models.name}\".\"${var.budget_book_semantic_view_name}\" FROM ROLE ${var.analyst_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_semantic_view.budget_book]
  }
}

# BUDGET_BOOK_SEARCH への USAGE 権限（ANALYST_ROLE）
resource "snowflake_execute" "budget_book_search_service_grant_analyst" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_execute.budget_book_search_service]

  execute = "GRANT USAGE ON CORTEX SEARCH SERVICE \"${snowflake_database.cortex.name}\".\"${snowflake_schema.search_services.name}\".\"${var.budget_book_search_service_name}\" TO ROLE ${var.analyst_role_name}"
  revert  = "REVOKE USAGE ON CORTEX SEARCH SERVICE \"${snowflake_database.cortex.name}\".\"${snowflake_schema.search_services.name}\".\"${var.budget_book_search_service_name}\" FROM ROLE ${var.analyst_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_execute.budget_book_search_service]
  }
}

# BUDGET_BOOK_SEARCH への MONITOR 権限（ANALYST_ROLE）
resource "snowflake_execute" "budget_book_search_monitor_analyst" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_execute.budget_book_search_service]

  execute = "GRANT MONITOR ON CORTEX SEARCH SERVICE \"${snowflake_database.cortex.name}\".\"${snowflake_schema.search_services.name}\".\"${var.budget_book_search_service_name}\" TO ROLE ${var.analyst_role_name}"
  revert  = "REVOKE MONITOR ON CORTEX SEARCH SERVICE \"${snowflake_database.cortex.name}\".\"${snowflake_schema.search_services.name}\".\"${var.budget_book_search_service_name}\" FROM ROLE ${var.analyst_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_execute.budget_book_search_service]
  }
}

# BUDGET_BOOK_AGENT への USAGE 権限（ANALYST_ROLE）
resource "snowflake_execute" "budget_book_agent_grant_analyst" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_execute.budget_book_agent]

  execute = "GRANT USAGE ON AGENT \"${snowflake_database.cortex.name}\".\"${snowflake_schema.agents.name}\".\"${var.budget_book_agent_name}\" TO ROLE ${var.analyst_role_name}"
  revert  = "REVOKE USAGE ON AGENT \"${snowflake_database.cortex.name}\".\"${snowflake_schema.agents.name}\".\"${var.budget_book_agent_name}\" FROM ROLE ${var.analyst_role_name}"

  lifecycle {
    replace_triggered_by = [snowflake_execute.budget_book_agent]
  }
}

# SNOWFLAKE.CORTEX_USER DB ロールを ANALYST_ROLE に付与（Cortex ML関数の使用）
resource "snowflake_grant_database_role" "analyst_cortex_user" {
  provider = snowflake.accountadmin

  database_role_name = "\"SNOWFLAKE\".\"CORTEX_USER\""
  parent_role_name   = snowflake_account_role.analyst_role.name
}

# SNOWFLAKE.CORTEX_AGENT_USER DB ロールを ANALYST_ROLE に付与（Agent呼び出し）
resource "snowflake_grant_database_role" "analyst_cortex_agent_user" {
  provider = snowflake.accountadmin

  database_role_name = "\"SNOWFLAKE\".\"CORTEX_AGENT_USER\""
  parent_role_name   = snowflake_account_role.analyst_role.name
}
