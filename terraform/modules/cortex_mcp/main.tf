# =============================================================================
# Snowflake マネージドMCPサーバー
#
# Cortex Analyst を MCP ツールとして公開する。
# Claude Code の settings.json に PAT を設定することで /analyst コマンドから利用できる。
#
# 注意: PAT（Programmatic Access Token）はTerraformで管理できないため手動発行が必要。
#   ALTER USER <USER> ADD PROGRAMMATIC ACCESS TOKEN analyst_mcp_token;
# =============================================================================

resource "snowflake_execute" "mcp_server" {
  provider = snowflake.sysadmin

  execute = <<-SQL
    CREATE OR REPLACE MCP SERVER "${var.cortex_db_name}"."${var.semantic_models_schema_name}"."${var.mcp_server_name}"
      FROM SPECIFICATION $$
        tools:
          - name: "covid19_analyst"
            type: "CORTEX_ANALYST_MESSAGE"
            identifier: "${var.cortex_db_name}.${var.semantic_models_schema_name}.${var.covid19_semantic_view_name}"
            description: "COVID-19データ分析"
            title: "COVID-19 Analyst"
          - name: "budget_book_analyst"
            type: "CORTEX_ANALYST_MESSAGE"
            identifier: "${var.cortex_db_name}.${var.semantic_models_schema_name}.${var.budget_book_semantic_view_name}"
            description: "家計簿データ分析"
            title: "Budget Book Analyst"
      $$
  SQL

  revert = "DROP MCP SERVER IF EXISTS \"${var.cortex_db_name}\".\"${var.semantic_models_schema_name}\".\"${var.mcp_server_name}\""
}

resource "snowflake_execute" "mcp_server_grant" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_execute.mcp_server]

  execute = "GRANT USAGE ON MCP SERVER \"${var.cortex_db_name}\".\"${var.semantic_models_schema_name}\".\"${var.mcp_server_name}\" TO ROLE \"${var.developer_role_name}\""
  revert  = "REVOKE USAGE ON MCP SERVER \"${var.cortex_db_name}\".\"${var.semantic_models_schema_name}\".\"${var.mcp_server_name}\" FROM ROLE \"${var.developer_role_name}\""

  lifecycle {
    replace_triggered_by = [snowflake_execute.mcp_server]
  }
}
