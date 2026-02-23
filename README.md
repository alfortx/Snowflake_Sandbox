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

## STEP 6: Cortex Analyst のセットアップ

> ⚠️ **STEP 6 はユーザー自身が端末で実行する手順です。** Terraform では自動化できません。

Cortex Analyst を使うと、自然言語（日本語）で COVID-19 データに質問できます。
セマンティックモデル（データの意味を定義した YAML ファイル）を Snowflake ステージにアップロードして使います。

### 6-1. Snowflake CLI をインストールする（初回のみ）

`snow` CLI（推奨）または `snowsql` のどちらかをインストールします。

#### snow CLI（推奨）

```bash
# macOS (Homebrew)
brew install snowflake-cli

# インストール確認
snow --version
```

#### snowsql（代替）

```bash
# macOS (Homebrew)
brew install --cask snowflake-snowsql

# インストール確認
snowsql --version
```

> どちらかが入っていれば OK です。すでにインストール済みの場合はスキップしてください。

---

### 6-2. スクリプトに実行権限を付与する

**リポジトリをクローン・コピーした直後、または端末が変わった際に1回実行してください。**

```bash
chmod +x scripts/upload_semantic_model.sh
```

> Git はファイルの実行権限を保持しますが、macOS の一部の環境や別の端末ではリセットされることがあります。

---

### 6-3. セマンティックモデルをアップロードする

環境変数を読み込んだ状態でスクリプトを実行します。

```bash
set -a && source .env && set +a
bash scripts/upload_semantic_model.sh
```

---

### 6-3. Snowsight から Cortex Analyst を使う

1. [Snowflake WebUI](https://app.snowflake.com/) にログイン
2. ロールを **`CORTEX_ROLE`** に切り替える
3. 左メニュー「**AI & ML**」→「**Cortex Analyst**」を選択
4. 「Select a semantic model file」をクリック
5. `CORTEX_DB` → `SEMANTIC_MODELS` → `SEMANTIC_MODEL_FILES` を選択
6. `semantic_model_covid19.yaml` を選択
7. 日本語で質問を入力！

**サンプル質問:**
- 日本のCOVID-19感染者数の月別推移を教えてください
- ワクチン完全接種率が高い国のトップ10を教えてください
- 大陸ごとのワクチン接種状況を比較してください
- アジア各国の感染者数とワクチン接種率を比較してください

---

## リソースの削除

**⚠️ 注意: すべてのリソースとデータが削除されます。**

```bash
terraform destroy
```

---

## アカウント再構築（Stateリセット手順）

Snowflakeアカウントが削除されて新しいアカウントに再構築する場合など、
「TerraformのStateにはリソースが存在する記録があるが、Snowflakeは空の状態」というズレが生じることがあります。
この状態でそのまま `terraform apply` しても、Terraformは「すでに作成済み」と判断して何もしません。

> **なぜStateを削除するのか？**
> 旧アカウントが完全に消滅しているため、State内の全リソース情報が無効です。
> `terraform destroy`（Stateを元に削除）も実行できないため、Stateをリセットするのが最も確実な対処法です。

---

### 手順

#### 1. 認証情報を更新する

`.env` を開き、新しいSnowflakeアカウントの情報に書き換えます。

```bash
SNOWFLAKE_ORGANIZATION_NAME=新しい組織名
SNOWFLAKE_ACCOUNT_NAME=新しいアカウント名
SNOWFLAKE_USER=管理者ユーザー名
SNOWFLAKE_PASSWORD=管理者パスワード
```

取得方法はSTEP 2-1を参照してください。

#### 2. Stateファイルをバックアップして削除する

万が一のためにバックアップを取ってから削除します。

```bash
# バックアップ作成
cp terraform.tfstate terraform.tfstate.old_account_backup

# Stateファイルを削除
rm terraform.tfstate terraform.tfstate.backup
```

> `terraform.tfstate.*.backup` など他のバックアップファイルは残しておいても問題ありません。

#### 3. 環境変数を読み込む

```bash
set -a && source .env && set +a
```

#### 4. Terraformを初期化する

```bash
terraform init
```

#### 5. 実行計画を確認する（任意）

Stateが空になったため、今度は全リソースが「新規作成」として表示されます。

```bash
terraform plan
# Plan: XX to add, 0 to change, 0 to destroy. と表示されるはず
```

#### 6. リソースを再作成する

```bash
terraform apply
```

`yes` と入力して実行します。完了後、Cortex AnalystのセットアップはSTEP 6を参照してください。

---

## Snowflakeのみ再構築（AWSリソースはそのまま）

Snowflakeアカウントを再作成したが、AWSのS3バケットやIAMロールはそのまま残っている場合の手順です。

> **前のセクションの手順（Stateファイルをまるごと削除）は使えません。**
> Stateを全削除すると、Terraformが「S3バケット/IAMロールがまだない」と判断して再作成しようとしますが、
> AWSには実物が既に存在するためエラーになります。

**SnowflakeリソースのみStateから削除する**のが正しい対処法です。

### Terraformが自動で行うこと

Snowflake側の Storage Integration を再作成すると、SnowflakeのIAMユーザーARNが変わります。
`aws.tf`のIAMロールtrust policyはそのARNを直接参照しているため、Terraformが変化を検出して**IAMロールのtrust policyを自動更新**します。手動での修正は不要です。

---

### 手順

#### 1. 認証情報を更新して環境変数を読み込む

`.env` を新しいSnowflakeアカウントの情報に書き換えてから読み込みます。

```bash
set -a && source .env && set +a
```

#### 2. Stateに登録されているリソースを確認する

```bash
terraform state list
```

`snowflake_` で始まるリソースと `aws_` で始まるリソースが混在して表示されます。

#### 3. SnowflakeリソースのみStateから削除する

```bash
terraform state list | grep "^snowflake_" | xargs terraform state rm
```

> **何をしているか：**
> `terraform state list` で全リソース名を取得 → `grep "^snowflake_"` でSnowflakeリソースのみ抽出 →
> `xargs terraform state rm` で1件ずつStateから削除

#### 4. 削除結果を確認する（任意）

```bash
terraform state list
# aws_ リソースのみ表示されればOK
```

#### 5. 実行計画を確認する

```bash
terraform plan
```

以下のような内容が表示されるはずです。

```
# snowflake_database.sandbox    → will be created  （Snowflakeリソースは新規作成）
# aws_iam_role.snowflake_s3_role → will be updated  （trust policyのARN更新）
# aws_s3_bucket.external_table_data → no changes    （S3バケットは変更なし）
```

#### 6. リソースを再作成する

```bash
terraform apply
```

`yes` と入力して実行します。完了後、Cortex AnalystのセットアップはSTEP 6を参照してください。

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
