# /analyst — 擬似 Snowflake Intelligence

Cortex Analyst を使って Snowflake の COVID-19 データに自然言語で質問し、
Claude Code が結果を解釈・追加クエリしながら回答を組み立てる。

## 使い方

```
/analyst <質問>
```

例:
- `/analyst 日本のCOVID-19感染者数の月別推移を教えて`
- `/analyst 2020年に最も感染者が多かった国は？`

---

## 実行手順（Claude Code はこの手順に従うこと）

### STEP 1: Cortex Analyst を呼び出す

モデルは常に `COVID19_SEMANTIC` を使用する。

```bash
venv/bin/python scripts/cortex_analyst.py \
  --question "<質問文>" \
  --model COVID19_SEMANTIC \
  --execute
```

- 出力は JSON 形式で `sql`、`analyst_text`、`results`、`row_count` が含まれる
- エラーの場合は `error` フィールドが含まれる

### STEP 2: 結果を評価する

取得した結果を見て以下を判断する：

- **十分な場合**: STEP 3 へ進む
- **不十分な場合**（データが空 / 質問の一部しかカバーできていない）:
  - 補足の質問を生成して STEP 1 を再実行（最大 **3回** まで）

追加クエリが必要なケースの例：
- 「推移を教えて」に対して1時点のデータしか返らなかった
- 「比較して」という質問に対して1カテゴリのデータしか返らなかった

### STEP 3: 最終回答を日本語で合成する

収集した全データを統合して、ユーザーの元の質問に答える。
- 数値は具体的に示す
- テーブルや箇条書きを活用して見やすく整理する
- SQL は折りたたんで（コードブロックで）表示する

---

## 注意事項

- 仮想環境 `venv/` を必ず使うこと（`venv/bin/python`）
- `.env` が存在しない場合はエラーになる（ユーザーに作成を促す）
