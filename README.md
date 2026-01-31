# Snowflake Sandbox - Terraform環境構築

Snowflakeの学習用サンドボックス環境をTerraformで自動構築するプロジェクトです。

## 作成されるリソース

- **Database**: サンドボックス用データベース（SANDBOX_DB）
- **Schema**: 作業用スキーマ（WORK）
- **Role**: スキーマで作業可能なロール（SANDBOX_ROLE）
- **User**: サンドボックスユーザー（sandbox_user）
- **権限設定**: ロールへのスキーマ権限付与、ユーザーへのロール付与

## 前提条件

### 必要なツール
- Terraform（v1.0以上）
- Snowflakeアカウント

### 必要な権限
管理者ユーザーに以下のロールが必要です：
- **SYSADMIN**: Database、Schema、Warehouseの作成
- **SECURITYADMIN**: Roleの作成と権限付与
- **USERADMIN**: Userの作成

**注**: ACCOUNTADMINロールも持っている場合は、すべての操作が可能です。

### Terraformのインストール
```bash
# macOSの場合（Homebrew使用）
brew install terraform

# バージョン確認
terraform --version
```

## セットアップ手順

### 1. 環境変数の設定

`.env.example`を`.env`にコピーして、実際の値を設定します。

```bash
cp .env.example .env
```

`.env`ファイルを編集：
```bash
# Snowflakeアカウント識別子を確認する方法：
# Snowflake WebUIにログイン → 左下のアカウント名をクリック → 「Copy account identifier」
# 例: MYORG-MYACCOUNT の場合、組織名は MYORG、アカウント名は MYACCOUNT

SNOWFLAKE_ORGANIZATION_NAME=your-organization-name
SNOWFLAKE_ACCOUNT_NAME=your-account-name
SNOWFLAKE_USER=your-admin-user
SNOWFLAKE_PASSWORD=your-password
ENVIRONMENT=sandbox
```

環境変数を読み込み：
```bash
set -a && source .env && set +a
```

### 2. Terraformの初期化

```bash
terraform init
```

このコマンドで：
- Snowflakeプロバイダーがダウンロードされます
- `.terraform`ディレクトリが作成されます

### 3. 実行計画の確認

```bash
terraform plan
```

このコマンドで：
- どのリソースが作成されるか確認できます
- エラーがないかチェックできます

### 4. リソースの作成

```bash
terraform apply
```

- `yes`を入力して実行を確認します
- 数分で完了します

### 5. 作成されたリソースの確認

```bash
terraform output
```

接続情報が表示されます。

## 使い方

### Snowflakeへの接続

1. [Snowflake WebUI](https://app.snowflake.com/)にアクセス
2. 作成されたユーザーでログイン
   - ユーザー名: `sandbox_user`
   - パスワード: `.env`で設定した値
3. ロール`SANDBOX_ROLE`を選択
4. データベース`SANDBOX_DB`、スキーマ`WORK`で作業開始

### テーブルの作成例

```sql
USE ROLE SANDBOX_ROLE;
USE DATABASE SANDBOX_DB;
USE SCHEMA WORK;

CREATE TABLE users (
  id INT,
  name STRING,
  created_at TIMESTAMP
);

INSERT INTO users VALUES (1, 'Takahiro', CURRENT_TIMESTAMP());

SELECT * FROM users;
```

## カスタマイズ

`variables.tf`で設定を変更できます：

```hcl
variable "database_name" {
  default = "SANDBOX_DB"  # データベース名を変更
}

variable "user_name" {
  default = "sandbox_user"  # ユーザー名を変更
}
```

## リソースの削除

**注意**: すべてのデータが削除されます！

```bash
terraform destroy
```

## トラブルシューティング

### エラー: "Invalid credentials"
- `.env`の`SNOWFLAKE_USER`と`SNOWFLAKE_PASSWORD`を確認
- Snowflake WebUIで手動ログインできるか確認

### エラー: "Account identifier is invalid"
- `SNOWFLAKE_ORGANIZATION_NAME`と`SNOWFLAKE_ACCOUNT_NAME`の値を確認
- Snowflake WebUIの左下 → 「Copy account identifier」で確認
- 例: `MYORG-MYACCOUNT`の場合、組織名=`MYORG`、アカウント名=`MYACCOUNT`

### エラー: "Insufficient privileges"
- 使用している管理者ユーザーに`ACCOUNTADMIN`ロールがあるか確認

## 次のステップ

### 1. AWSリソースの追加準備

将来的にS3バケットやIAMロールを追加する場合：

1. `provider.tf`にAWSプロバイダーを追加
2. 新しいファイル`aws.tf`を作成
3. S3バケット、IAMロールなどを定義

### 2. Stateのリモート管理

本格的に使う場合は、stateをS3に保存：

```hcl
# provider.tfのbackendブロックを有効化
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "snowflake-sandbox/terraform.tfstate"
  region         = "ap-northeast-1"
  dynamodb_table = "terraform-state-lock"
  encrypt        = true
}
```

### 3. 認証方法の改善

セキュリティ向上のため、キーペア認証に移行：

```hcl
provider "snowflake" {
  account           = var.account
  user              = var.user
  private_key_path  = "~/.ssh/snowflake_key.p8"
}
```

## Terraformファイルの役割と関係性

### 各ファイルの役割

#### 1. **provider.tf** - どこに作るか
Terraformがどのクラウドサービスを使うか定義します。
- Snowflakeプロバイダーのバージョン指定
- 認証方法の設定（環境変数から読み込み）
- **ロール別プロバイダー**: SYSADMIN、SECURITYADMIN、USERADMINの3つのエイリアス
  - ACCOUNTADMINの使用を最小化し、セキュリティを向上
- 将来のS3バックエンド設定（コメントアウト済み）

#### 2. **variables.tf** - 何を変更できるか
カスタマイズ可能な設定値を定義します。
- データベース名、スキーマ名、ユーザー名など
- ウェアハウスのサイズや自動停止時間
- デフォルト値が設定されているので変更は任意

#### 3. **main.tf** - 何を作るか
実際に作成するSnowflakeリソースを定義します。
- **SYSADMIN**: データベース、スキーマ、ウェアハウス
- **SECURITYADMIN**: ロール、権限付与
- **USERADMIN**: ユーザー
- 各リソースに適切なロールを使用（ベストプラクティス）

#### 4. **outputs.tf** - 結果を表示
作成したリソースの情報を表示します。
- データベース名、ウェアハウス名など
- 接続情報のサマリー
- セットアップ完了メッセージ

#### 5. **.env** - 認証情報（Gitで管理しない）
Snowflakeへの接続情報を保存します。
- アカウント識別子、ユーザー名、パスワード
- 環境変数としてTerraformが読み込む
- **.gitignore**で除外されるので安全

### ファイル間の関係性と実行フロー

```
【準備】
.env（認証情報）
  ↓ export で環境変数化
  ↓
provider.tf（環境変数を読み込み）
  ↓
terraform init（プロバイダーダウンロード）

【設定】
variables.tf（変数定義）
  ↓ デフォルト値または上書き
  ↓
main.tf（リソース定義）
  ├─ var.database_name などを参照
  └─ リソース間の依存関係を自動解決

【実行】
terraform plan（実行計画表示）
  ↓
terraform apply（リソース作成）
  ↓
outputs.tf（結果表示）
```

### リソースの依存関係

main.tfでは、リソースが以下の順序で作成されます：

1. **Database** → 2. **Schema**（Databaseに依存）
3. **Warehouse**（独立）
4. **Role**（独立）
5. **User**（Role、Warehouseに依存）
6. **権限設定**（上記すべてに依存）

Terraformが自動的に依存関係を解決して、正しい順序で作成します。

## ファイル構成

```
Snowflake_Sandbox/
├── .gitignore          # Gitで管理しないファイル
├── .env.example        # 環境変数のサンプル
├── .env                # 環境変数（実際の値）※Gitで管理しない
├── README.md           # このファイル
├── provider.tf         # プロバイダー設定
├── variables.tf        # 変数定義
├── main.tf             # リソース定義
└── outputs.tf          # 出力値
```

## 参考リンク

- [Snowflake公式ドキュメント](https://docs.snowflake.com/)
- [Terraform Snowflake Provider](https://registry.terraform.io/providers/Snowflake-Labs/snowflake/latest/docs)
- [Terraform入門](https://developer.hashicorp.com/terraform/tutorials)
