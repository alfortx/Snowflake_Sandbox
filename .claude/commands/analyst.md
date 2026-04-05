# /analyst — 擬似 Snowflake Intelligence

Snowflake マネージドMCPサーバー（`snowflake-analyst`）を通じて Cortex Analyst を呼び出し、
Claude Code が結果を解釈・追加クエリしながら回答を組み立てる。

## 使い方

```
/analyst <質問> [--model covid19|budget_book]
```

例:
- `/analyst 日本のCOVID-19感染者数の月別推移を教えて`
- `/analyst 2020年に最も感染者が多かった国は？`
- `/analyst 先月の食費を教えて --model budget_book`

デフォルトモデルは `covid19`。

---

## 事前セットアップ（初回のみ）

MCPサーバーの設定は `.mcp.json`（接続先URL）と `.claude/settings.local.json`（PAT・承認）に分かれています。

**`.mcp.json`**（git管理済み・変更不要）:
```json
{
  "mcpServers": {
    "snowflake-analyst": {
      "type": "http",
      "url": "https://JPDANRF-RH35392.snowflakecomputing.com/api/v2/databases/CORTEX_DB/schemas/SEMANTIC_MODELS/mcp-servers/ANALYST_MCP",
      "headers": { "Authorization": "Bearer ${SNOWFLAKE_PAT}" }
    }
  }
}
```

**`.claude/settings.local.json`**（gitignore済み・各自で設定）:
```json
{
  "env": { "SNOWFLAKE_PAT": "<発行したPAT>" },
  "enabledMcpjsonServers": ["snowflake-analyst"]
}
```

PATの発行方法：
```sql
ALTER USER <USER> ADD PROGRAMMATIC ACCESS TOKEN analyst_mcp_token
  COMMENT = 'Claude Code MCP access';
```

---

## 実行手順（Claude Code はこの手順に従うこと）

### STEP 1: MCPツール（snowflake-analyst）を呼び出す

`snowflake-analyst` MCPサーバーの Cortex Analyst ツールを使って質問する。

- `--model covid19`（デフォルト）→ `covid19_analyst` サービスを使用
- `--model budget_book` → `budget_book_analyst` サービスを使用

MCPサーバーが未設定・未接続の場合はフォールバックとして以下を実行：

```bash
venv/bin/python scripts/cortex_analyst.py \
  --question "<質問文>" \
  --model COVID19_SEMANTIC \
  --execute
```

### STEP 2: 結果を評価する

取得した結果を見て以下を判断する：

- **十分な場合**: STEP 3 へ進む
- **不十分な場合**（データが空 / 質問の一部しかカバーできていない）:
  - 補足の質問を生成して STEP 1 を再実行（最大 **3回** まで）

### STEP 3: 最終回答を日本語で合成する

収集した全データを統合して、ユーザーの元の質問に答える。
- 数値は具体的に示す
- テーブルや箇条書きを活用して見やすく整理する
- SQL は折りたたんで（コードブロックで）表示する
