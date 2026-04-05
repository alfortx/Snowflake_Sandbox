#!/bin/bash
# Snowflake MCPサーバーへのmcp-remoteブリッジ
# PAT は .claude/settings.local.json の env.SNOWFLAKE_PAT から継承される
exec npx --yes mcp-remote \
  "https://JPDANRF-RH35392.snowflakecomputing.com/api/v2/databases/CORTEX_DB/schemas/SEMANTIC_MODELS/mcp-servers/ANALYST_MCP" \
  --header "Authorization:Bearer ${SNOWFLAKE_PAT}"
