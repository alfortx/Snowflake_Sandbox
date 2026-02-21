# Snowflake Sandbox - Terraform 実行手順書

Snowflake（＋AWS）のサンドボックス環境をTerraformで自動構築するプロジェクトです。
この手順書に沿って進めれば、コマンド1回でSnowflakeとAWSのリソースが一括で作成されます。

---

## 作成されるリソース

| サービス | リソース | 説明 |
|---------|---------|------|
| Snowflake | Database / Schema / Warehouse | 作業用の基本オブジェクト |
| Snowflake | Role / User / 権限設定 | サンドボックス用のユーザー環境 |
| Snowflake | Managed Accessスキーマ | 権限管理の学習用 |
| Snowflake | Storage Integration | S3との連携設定 |
| AWS | S3バケット | Snowflake外部テーブルのデータ格納先 |
| AWS | IAMロール / IAMポリシー | SnowflakeがS3にアクセスするための権限 |

---

## STEP 1: ツールの準備

Terraform がインストール済みか確認します。

```bash
terraform --version
# Terraform v1.0.0 以上が表示されればOK
```

インストールされていない場合（macOS）：

```bash
brew install terraform
```

---

## STEP 2: 認証情報の取得

Terraform実行前に、SnowflakeとAWSそれぞれの接続情報を手元に控えておきます。
**これらはTerraform自体を動かすために必要な情報で、Terraformでは作成できません（手作業が必須）。**

---

### 2-1. Snowflake の情報を取得する

#### 必要な情報

| 項目 | 変数名 | 取得場所 |
|------|--------|---------|
| 組織名 | `SNOWFLAKE_ORGANIZATION_NAME` | WebUI左下 |
| アカウント名 | `SNOWFLAKE_ACCOUNT_NAME` | WebUI左下 |
| 管理者ユーザー名 | `SNOWFLAKE_USER` | 自分で把握しているはず |
| 管理者パスワード | `SNOWFLAKE_PASSWORD` | 自分で把握しているはず |

#### 取得手順

1. [Snowflake WebUI](https://app.snowflake.com/) にログイン
2. 画面**左下**のアカウント名をクリック
3. 「**Copy account identifier**」を選択
4. `MYORG-MYACCOUNT` の形式でクリップボードにコピーされる
   - `-` より左が **組織名**（SNOWFLAKE_ORGANIZATION_NAME）
   - `-` より右が **アカウント名**（SNOWFLAKE_ACCOUNT_NAME）

> **必要なロール**: ログインする管理者ユーザーが **ACCOUNTADMINロール** を持っている必要があります。
> Snowflake WebUIで `USE ROLE ACCOUNTADMIN;` が実行できるか確認してください。

---

### 2-2. AWS の情報を取得する

#### 必要な情報

| 項目 | 変数名 | 取得場所 |
|------|--------|---------|
| アクセスキーID | `AWS_ACCESS_KEY_ID` | IAMコンソール |
| シークレットアクセスキー | `AWS_SECRET_ACCESS_KEY` | IAMコンソール（作成時のみ表示） |

#### 取得手順

1. [AWS マネジメントコンソール](https://console.aws.amazon.com/) にログイン
2. 右上のユーザー名 → 「**セキュリティ認証情報**」をクリック
   （または IAM → ユーザー → 対象ユーザー → 「セキュリティ認証情報」タブ）
3. 「**アクセスキーを作成**」をクリック
4. 用途は「**コマンドラインインターフェイス（CLI）**」を選択
5. アクセスキーIDとシークレットアクセスキーをメモ
   - ⚠️ シークレットアクセスキーは**作成時にしか表示されません**。必ず控えること。

#### 必要なIAM権限

Terraform がS3とIAMを操作するため、使用するIAMユーザーに以下のポリシーが必要です。

| ポリシー名 | 必要な理由 |
|-----------|----------|
| `AmazonS3FullAccess` | S3バケットの作成・管理 |
| `IAMFullAccess` | IAMロール・ポリシーの作成・管理 |

> 簡単にするなら `AdministratorAccess` を付与してもOKです（学習用サンドボックスの場合）。

---

## STEP 3: .env ファイルの作成

テンプレートをコピーして、STEP 2で控えた値を記入します。

```bash
cp .env.example .env
```

`.env` を開いて、各行の `your-xxx` 部分を実際の値に書き換えます。

```bash
# 例（値はダミー）
SNOWFLAKE_ORGANIZATION_NAME=MYORG
SNOWFLAKE_ACCOUNT_NAME=MYACCOUNT
SNOWFLAKE_USER=admin
SNOWFLAKE_PASSWORD=MyPassword123!
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
ENVIRONMENT=sandbox
```

> ⚠️ `.env` ファイルには認証情報が入っています。`.gitignore` で除外済みですが、
> 絶対に Git にコミットしないよう注意してください。

---

## STEP 4: Terraformの実行

### 4-1. 環境変数を読み込む

`.env` の内容を環境変数としてターミナルに読み込みます。
**このコマンドはターミナルを開き直すたびに毎回実行が必要です。**

```bash
set -a && source .env && set +a
```

> `set -a` ：以降のコマンドで定義した変数を自動的にexport（環境変数化）する設定
> `source .env` ：.envの内容を読み込む
> `set +a` ：`set -a` の設定を元に戻す

読み込めたか確認する場合（任意）：

```bash
echo $SNOWFLAKE_ORGANIZATION_NAME
# 組織名が表示されればOK
```

---

### 4-2. Terraformを初期化する

Terraformの動作に必要なプロバイダー（Snowflake/AWSへの接続ライブラリ）をダウンロードします。
**初回1回だけ実行が必要です。**

```bash
terraform init
```

`Terraform has been successfully initialized!` と表示されれば成功です。

---

### 4-3. 実行計画を確認する（任意）

実際には何も作成せず、「これから何が作られるか」をプレビューできます。

```bash
terraform plan
```

エラーが表示されなければ問題ありません。
`Plan: XX to add, 0 to change, 0 to destroy.` のように表示されます。

---

### 4-4. リソースを作成する

```bash
terraform apply
```

途中で確認を求められます。内容を確認して `yes` と入力してください。

```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes   ← これを入力してEnter
```

数分で完了し、作成されたリソースの情報が表示されます。

---

### 4-5. 作成内容を確認する（任意）

```bash
terraform output
```

Snowflake接続情報やリソース名が一覧表示されます。

---

## STEP 5: 動作確認

[Snowflake WebUI](https://app.snowflake.com/) に作成されたユーザーでログインして確認します。

| 項目 | 値 |
|------|---|
| ユーザー名 | `sandbox_user`（variables.tfのデフォルト値） |
| パスワード | `ChangeMe123!`（variables.tfのデフォルト値） |
| ロール | `SANDBOX_ROLE` |
| データベース | `SANDBOX_DB` |
| スキーマ | `WORK` |

---

## トラブルシューティング

### Snowflake 関連

**`Error: Invalid credentials`**
- `.env` の `SNOWFLAKE_USER` / `SNOWFLAKE_PASSWORD` が正しいか確認
- Snowflake WebUIで手動ログインできるか確認

**`Error: Account identifier is invalid`**
- `SNOWFLAKE_ORGANIZATION_NAME` と `SNOWFLAKE_ACCOUNT_NAME` の値を確認
- WebUIの「Copy account identifier」で `MYORG-MYACCOUNT` の形式でコピーし、`-` で分割して設定する

**`Error: Insufficient privileges`**
- 管理者ユーザーに `ACCOUNTADMIN` ロールがあるか確認
- Snowflake WebUI で `USE ROLE ACCOUNTADMIN;` が実行できるか試す

### AWS 関連

**`Error: NoCredentialProviders`**
- `set -a && source .env && set +a` を実行したか確認
- `echo $AWS_ACCESS_KEY_ID` で値が表示されるか確認

**`Error: AccessDenied`**
- IAMユーザーに `AmazonS3FullAccess` と `IAMFullAccess` が付与されているか確認

---

## リソースの削除

**⚠️ 注意: すべてのリソースとデータが削除されます。**

```bash
terraform destroy
```

---

## ファイル構成

```
Snowflake_Sandbox/
├── .env.example        # 認証情報のテンプレート（Gitで管理）
├── .env                # 認証情報の実際の値（Gitで管理しない）
├── .gitignore          # Gitの除外設定
├── README.md           # この手順書
├── provider.tf         # Snowflake/AWSへの接続設定（ロール別プロバイダー）
├── variables.tf        # カスタマイズ可能な変数定義
├── main.tf             # Snowflakeリソース定義（DB/Schema/WH/Role/User）
├── managed_access.tf   # Managed Accessスキーマの学習用リソース
├── aws.tf              # AWSリソース定義（S3/IAM/Storage Integration）
└── outputs.tf          # 実行後の出力情報
```
