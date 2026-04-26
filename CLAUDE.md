# プロジェクト名
Snowflake_Sandbox

## 目的
Snowflakeのサンドボックス環境用のリソース（関連するAWS含む）をTerraformで管理する。

## 設計方針
- Terraform applyを1回だけ実行すれば、コードと実機の状態が一致するようにする。Terraformの実行に必要なリソースはTerraformでは作成できない（鶏卵の関係）ため、手作成しておく前提とする。

## ドキュメンテーション
- Terraformの実行前に手作業で準備すべき内容（アカウント情報を控える、Terraform管理対象リソースの作成に必要なリソースを手作成しておく など）は、Terraformの実行手順と合わせて、手順書にドキュメント化する
- 開発時に生成AIが行う作業のうち、ユーザーが実行する内容は必ず手順書に記載し、手順書通りに実行すれば再現できるようにする。

## RBAC 管理ルール
- 機能的ロール（FR_*）が権限を保持し、役割ロールがそれを継承する設計を維持すること


## Snowflakeへの接続情報
- `.env` に記載している。Terraform、SnowCLIやその他スクリプトでの接続時はこのファイルを参照すること


## 注意事項
- **SnowflakeおよびAWSの接続情報などは、環境変数ファイルで管理し、Git対象外とすること**
- **必ずterraform planを行い正しく反映されることを確認してからapplyすること！**

## Notebook 作成後の自動デプロイ

`experiments/` 配下に `.ipynb` ファイルを新規作成・更新したら、
以下のコマンドを実行して Snowflake Workspace にアップロードすること。

```bash
bash scripts/deploy-notebooks.sh <対象ディレクトリ>
# 例: bash scripts/deploy-notebooks.sh experiments/iceberg
```