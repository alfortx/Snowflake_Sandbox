#!/bin/bash
set -euo pipefail
set -a && source "$(dirname "$0")/../.env" && set +a

# main.tf に書かれた全モジュール名が modules.json に登録済みか確認し、
# 未登録があれば init を実行（新モジュール追加後の再 init に対応）
MODULES_JSON="terraform/.terraform/modules/modules.json"
NEED_INIT=false
while IFS= read -r mod; do
  if [ -f "$MODULES_JSON" ]; then
    if ! python3 -c "import json,sys; d=json.load(open('$MODULES_JSON')); sys.exit(0 if '$mod' in [m['Key'] for m in d['Modules']] else 1)" 2>/dev/null; then
      NEED_INIT=true
      break
    fi
  else
    NEED_INIT=true
    break
  fi
done < <(grep '^module "' terraform/main.tf | sed 's/module "\(.*\)".*/\1/')
if [ "$NEED_INIT" = "true" ]; then
  terraform -chdir=terraform init
fi

terraform -chdir=terraform apply -auto-approve
