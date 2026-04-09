以下の手順でSnowflake Sandbox環境を立ち上げてください。

## 前提確認

1. `.env` ファイルが存在するか確認する
   - 存在しない場合: `cp .env.example .env` を案内して中断する
   - 存在する場合: 認証情報が記入済みか（`your-xxx` のままでないか）確認する
   - 未記入の場合: STEP 2（README）を参照して認証情報を設定するよう案内して中断する

## 実行手順

2. `terraform/` ディレクトリ内の `.terraform/` が存在しない場合のみ初期化する
   ```
   terraform -chdir=terraform init
   ```

3. 実行計画を確認する
   ```
   bash scripts/tf-plan.sh
   ```
   - エラーがあれば内容を日本語で説明して中断する

4. ユーザーに apply を実行してよいか確認してから実行する
   ```
   bash scripts/tf-apply.sh
   ```

5. 完了後、以下を報告する
   - 作成されたリソース数
   - `terraform output` の結果（Snowflake接続情報など）
   - 次のステップ（README の STEP 5 / STEP 6）への案内
