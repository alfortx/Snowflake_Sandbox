#!/bin/bash
# =============================================================================
# セマンティックモデル YAML を Snowflake ステージにアップロードするスクリプト
# 使用方法: bash scripts/upload_semantic_model.sh
# =============================================================================
set -euo pipefail

# プロジェクトルートに移動
cd "$(dirname "$0")/.."

# .env を読み込む
if [ -f .env ]; then
  set -a && source .env && set +a
else
  echo "ERROR: .env ファイルが見つかりません"
  exit 1
fi

STAGE="@CORTEX_DB.SEMANTIC_MODELS.SEMANTIC_MODEL_FILES"
MODEL_FILE="scripts/semantic_model_covid19.yaml"
ROLE="SYSADMIN"
WAREHOUSE="SANDBOX_WH"

echo "======================================"
echo " セマンティックモデル アップロード"
echo "======================================"
echo " ファイル  : ${MODEL_FILE}"
echo " ステージ  : ${STAGE}"
echo " ロール    : ${ROLE}"
echo ""

# snow CLI を優先使用、なければ snowsql にフォールバック
if command -v snow &> /dev/null; then
  echo "[snow CLI] アップロード中..."
  snow stage copy "${MODEL_FILE}" "${STAGE}" \
    --temporary-connection \
    --account "${SNOWFLAKE_ORGANIZATION_NAME}-${SNOWFLAKE_ACCOUNT_NAME}" \
    --user "${SNOWFLAKE_USER}" \
    --password "${SNOWFLAKE_PASSWORD}" \
    --role "${ROLE}" \
    --warehouse "${WAREHOUSE}" \
    --overwrite

elif command -v snowsql &> /dev/null; then
  echo "[snowsql] アップロード中..."
  snowsql \
    -a "${SNOWFLAKE_ORGANIZATION_NAME}-${SNOWFLAKE_ACCOUNT_NAME}" \
    -u "${SNOWFLAKE_USER}" \
    -p "${SNOWFLAKE_PASSWORD}" \
    -r "${ROLE}" \
    -q "PUT file://${PWD}/${MODEL_FILE} ${STAGE} OVERWRITE = TRUE AUTO_COMPRESS = FALSE;"

else
  echo "ERROR: snow または snowsql がインストールされていません"
  echo ""
  echo "インストール方法:"
  echo "  Snowflake CLI: https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation"
  echo "  SnowSQL      : https://docs.snowflake.com/en/user-guide/snowsql-install-config"
  exit 1
fi

echo ""
echo "✅ アップロード完了！"
echo ""
echo "======================================"
echo " Cortex Analyst の使い方"
echo "======================================"
echo ""
echo "【Snowsight UI から使う場合】"
echo "  1. Snowsight にログイン"
echo "  2. 左メニュー「AI & ML」→「Cortex Analyst」を選択"
echo "  3. 「Select a semantic model file」をクリック"
echo "  4. ステージ: CORTEX_DB > SEMANTIC_MODELS > SEMANTIC_MODEL_FILES"
echo "  5. ファイル: semantic_model_covid19.yaml を選択"
echo "  6. 日本語で質問を入力！"
echo ""
echo "【API から使う場合】"
echo "  POST /api/v2/cortex/analyst/message"
echo "  semantic_model_file: '@CORTEX_DB.SEMANTIC_MODELS.SEMANTIC_MODEL_FILES/semantic_model_covid19.yaml'"
echo ""
echo "【サンプル質問】"
echo "  - 日本のCOVID-19感染者数の月別推移を教えてください"
echo "  - ワクチン完全接種率が高い国のトップ10を教えてください"
echo "  - 大陸ごとのワクチン接種状況を比較してください"
echo "  - アジア各国の感染者数とワクチン接種率を比較してください"
echo ""
