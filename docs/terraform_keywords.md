# Terraform キーワード解説

本PJ（Snowflake Sandbox）のコードを例に、使用しているTerraformのキーワードを解説します。

---

## トップレベルブロック（ファイルの一番外側に書くもの）

### `terraform` — Terraformの設定そのもの

バージョンや使用するプロバイダーを宣言します。(`provider.tf`)

```hcl
terraform {
  required_version = ">= 1.0"        # Terraformのバージョン制約
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.1"             # 2.1以上3.0未満を使う
    }
  }
}
```

---

### `provider` — 外部サービスへの接続設定

「どのサービスに、どんな権限で接続するか」を定義します。(`provider.tf`)

```hcl
provider "snowflake" {
  alias = "sysadmin"   # 複数のプロバイダーを区別するための名前
  role  = "SYSADMIN"   # Snowflake接続時のロール
}
```

本PJは **Snowflake × 4種類 + AWS × 1種類** の合計5つのプロバイダーを使っています。

---

### `resource` — 実際に作るもの

最もよく使うブロック。「何を」「どんな名前で」作るかを定義します。

```hcl
resource "snowflake_database" "sandbox" {
#        ↑リソースの種類         ↑Terraform内での名前（参照用）
  provider = snowflake.sysadmin
  name     = var.database_name
}
```

作った後は `snowflake_database.sandbox.name` のように参照できます。

---

### `module` — 部品を呼び出す

別フォルダのTerraformコードをまとめて実行します。(`main.tf`)

```hcl
module "foundation" {
  source = "./modules/foundation"   # 使う部品の場所
  database_name = var.database_name # 部品への入力
}
```

---

### `variable` — 入力の定義

モジュールが受け取る「引数」を定義します。(`modules/foundation/variables.tf`)

```hcl
variable "warehouse_size" {
  type    = string        # 型（string/number/bool）
  default = "X-Small"    # デフォルト値（省略可）
}

variable "user_password" {
  type      = string
  sensitive = true        # ログや出力に表示しない
}
```

呼び出す側では `var.warehouse_size` で参照します。

---

### `output` — 出力の定義

他のモジュールや `terraform apply` 後に表示する値を定義します。(`modules/foundation/outputs.tf`)

```hcl
output "sandbox_db_name" {
  value = snowflake_database.sandbox.name  # 作ったリソースの値を公開
}
```

他モジュールからは `module.foundation.sandbox_db_name` で参照できます。

---

### `locals` — 内部の変数（使い回し用）

モジュール内で繰り返し使う値を一か所にまとめます。(`modules/aws_integration/main.tf`)

```hcl
locals {
  snowflake_iam_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.iam_role_name}"
}
```

`local.snowflake_iam_role_arn` で参照します。`var`（外からの入力）と違い、**外からは変更できない**のが特徴です。

---

### `data` — 既存リソースの取得

Terraformで**作らずに**、すでに存在するものの情報を取得します。(`modules/aws_integration/main.tf`)

```hcl
data "aws_caller_identity" "current" {}
# → 現在ログイン中のAWSアカウントIDを取得する
```

`data.aws_caller_identity.current.account_id` で値を参照できます。

---

## メタ引数（ブロック内に書く特別なキーワード）

### `provider` / `providers` — どのプロバイダーを使うか指定

```hcl
# resourceの中では "provider"（単数）
resource "snowflake_database" "sandbox" {
  provider = snowflake.sysadmin   # このリソースはSYSADMINで作る
}

# moduleの中では "providers"（複数）
module "foundation" {
  providers = {
    snowflake.sysadmin = snowflake.sysadmin   # エイリアスを渡す
  }
}
```

---

### `depends_on` — 実行順序の明示

Terraformが自動検出できない依存関係を手動で指定します。(`modules/covid19/main.tf`)

```hcl
resource "snowflake_stage" "covid19_s3_stage" {
  depends_on = [snowflake_file_format.csv_format]  # これが先に作られることを保証
}
```

---

### `lifecycle` — リソースの更新・削除の制御

(`modules/covid19/main.tf`)

```hcl
lifecycle {
  ignore_changes = [directory]   # directoryが変わっても無視（再作成しない）
}

lifecycle {
  replace_triggered_by = [snowflake_semantic_view.covid19]   # このリソースが変わったら再作成
}
```

---

## 特殊な構文

### 文字列補間 `${...}` — 文字列に変数を埋め込む

```hcl
name = "${var.database_name}_SCHEMA"
# → "SANDBOX_DB_SCHEMA" のように展開される
```

---

### Heredoc `<<-SQL` — 複数行テキスト

SQLやYAMLのような長い文字列を見やすく書けます。(`modules/covid19/materialized_views.tf`)

```hcl
statement = <<-SQL
  SELECT
    UID, FIPS, COUNTRY_REGION, DATE, CONFIRMED, DEATHS
  FROM RAW_DB.COVID19.EXT_JHU_TIMESERIES
  WHERE DATE IS NOT NULL
SQL
```

---

### `configuration_aliases` — モジュール内でプロバイダーを宣言

モジュールが受け取るプロバイダーのエイリアスをあらかじめ宣言します。(`modules/foundation/providers.tf`)

```hcl
terraform {
  required_providers {
    snowflake = {
      configuration_aliases = [
        snowflake.sysadmin,
        snowflake.securityadmin,
      ]
    }
  }
}
```

---

### 組み込み関数

| 関数 | 用途 | 使用例 |
|------|------|--------|
| `toset()` | リスト→セット変換（重複排除） | `synonym = toset(["country", "nation", "国"])` |
| `jsonencode()` | HCLオブジェクト→JSON文字列 | IAMポリシーの定義に使用 |

---

## ソースコードの読み方

### ファイルを読む順番

```
① provider.tf          ← 「どんな外部サービスを使うか」全体像を把握
② variables.tf         ← 「設定できる値の一覧」を把握
③ main.tf              ← 「どのモジュールを呼んでいるか」依存関係を把握
④ modules/〇〇/main.tf ← 「実際に何を作っているか」詳細を確認
⑤ modules/〇〇/outputs.tf ← 「他モジュールに何を渡しているか」確認
```

### ひとつのファイルを読むときのキーワード順

**まず「何を作るか」を掴む**

```hcl
resource "snowflake_database" "sandbox" {   # ① リソース種類と名前
  provider = snowflake.sysadmin             # ② どのプロバイダー（権限）で作るか
  name     = var.database_name              # ③ 実際の値（var.〇〇を追う）
}
```

**次に「依存関係」を追う**

```hcl
depends_on = [snowflake_file_format.csv_format]  # 何が先に必要か
```

**最後に「例外・制御」を確認**

```hcl
lifecycle {
  ignore_changes = [directory]  # 何を無視しているか（なぜ？）
}
```

### 本PJの具体的な読み方

**Step 1: 全体構造を把握（`main.tf`）**

```
module "foundation" → module "cortex" → module "aws_integration"
→ module "covid19" → module "budget_book" → module "rbac"
```

モジュールの呼び出し順 = だいたい依存関係の順番。

**Step 2: 気になるモジュールに入る**（例: `budget_book`）

| 順番 | ファイル | 確認すること |
|------|---------|------------|
| 1 | `modules/budget_book/variables.tf` | 何を入力として受け取るか |
| 2 | `modules/budget_book/main.tf` | 実際に何を作るか |
| 3 | `modules/budget_book/outputs.tf` | 何を外に出力するか |

**Step 3: 値を追う**

- `var.〇〇` → ルートの `variables.tf` で定義を確認
- `module.〇〇.△△` → そのモジュールの `outputs.tf` で定義を確認

### まとめ：「外から内へ」「入力→処理→出力の順」

```
provider.tf（接続）
  → main.tf（全体構造）
    → variables.tf（入力）
      → main.tf各モジュール（処理）
        → outputs.tf（出力）
```

---

## キーワード一覧まとめ

```
【ブロック】
terraform   - バージョン・プロバイダー宣言
provider    - 外部サービスへの接続設定
resource    - 作るもの
module      - 部品の呼び出し
variable    - 外からの入力
output      - 外への出力
locals      - 内部変数
data        - 既存リソースの取得

【メタ引数】
source          - モジュールの場所
provider(s)     - プロバイダーの指定
depends_on      - 依存関係の明示
lifecycle       - ライフサイクル制御
  ignore_changes        - 変更を無視
  replace_triggered_by  - 変更トリガー

【特殊構文】
${}       - 文字列補間
<<-EOF    - Heredoc（複数行テキスト）
sensitive - センシティブ値フラグ
```
