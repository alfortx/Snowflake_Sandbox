#!/bin/bash
# =============================================================================
# deploy-notebooks.sh: experiments/ 配下の Notebook を Snowflake Workspace に配置
#
# 使い方:
#   bash scripts/deploy-notebooks.sh [notebook_dir]
#
#   notebook_dir: 対象ディレクトリ（省略時: experiments/iceberg）
#
# 仕組み:
#   .env から Snowflake 接続情報を読み込み、snow stage copy で
#   個人ワークスペースに .ipynb ファイルをアップロードする
#
# 前提:
#   - Snowflake CLI (snow) がインストール済みであること
#   - .env に SNOWFLAKE_ORGANIZATION_NAME / SNOWFLAKE_ACCOUNT_NAME /
#     SNOWFLAKE_USER / SNOWFLAKE_PASSWORD が設定済みであること
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# .env 読み込み
set -a
source "${ROOT_DIR}/.env"
set +a

# 対象ディレクトリ（引数で上書き可能）
NOTEBOOK_DIR="${1:-experiments/iceberg}"
TARGET_DIR="${ROOT_DIR}/${NOTEBOOK_DIR}"

# snow CLI の接続オプション（.env の値を使用）
# パスワードは環境変数 SNOWFLAKE_PASSWORD を snow CLI が自動で読み取るため CLI 引数に含めない
ACCOUNT="${SNOWFLAKE_ORGANIZATION_NAME}-${SNOWFLAKE_ACCOUNT_NAME}"
SNOW_OPTS="--account ${ACCOUNT} --user ${SNOWFLAKE_USER} --authenticator snowflake"

# ワークスペースのパス（個人ワークスペース / デフォルト）
WORKSPACE_PATH="snow://workspace/USER\$.PUBLIC.DEFAULT\$/versions/live/"

echo "================================================================"
echo "  Snowflake Notebook デプロイ"
echo "  対象ディレクトリ : ${TARGET_DIR}"
echo "  アップロード先   : ${WORKSPACE_PATH}"
echo "================================================================"

# .ipynb ファイルを列挙してアップロード
UPLOADED=0
for notebook in "${TARGET_DIR}"/*.ipynb; do
  [ -f "${notebook}" ] || continue
  filename="$(basename "${notebook}")"
  echo ""
  echo "▶ アップロード: ${filename}"
  snow stage copy "${notebook}" "${WORKSPACE_PATH}" \
    ${SNOW_OPTS} \
    --overwrite 2>&1
  UPLOADED=$((UPLOADED + 1))
done

echo ""
if [ "${UPLOADED}" -eq 0 ]; then
  echo "⚠ .ipynb ファイルが見つかりませんでした: ${TARGET_DIR}"
  exit 1
fi

echo "================================================================"
echo "  完了: ${UPLOADED} 件のNotebookをアップロードしました"
echo "  Snowsight > Projects > Workspaces で確認してください"
echo "================================================================"
