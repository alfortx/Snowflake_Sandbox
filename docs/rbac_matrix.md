# RBAC 権限マトリクス

Snowflake RBAC ベストプラクティスに基づき、**機能的ロール（FR_*）** がオブジェクト権限を保持し、**役割ロール** が機能的ロールを束ねてユーザーに付与する設計。

> **重要**: リソース・ロールを作成/変更/削除した際は、このファイルを必ず更新すること。

---

## 役割ロール一覧

| ロール名 | 用途 | 付与ユーザー |
|---------|------|-----------|
| `DEVELOPER_ROLE` | 開発者（読み書き + Cortex 管理含む） | sandbox_user, MAIN |
| `VIEWER_ROLE` | 閲覧者（読み取り専用 + Cortex 利用） | sandbox_user, MAIN |
| `SCHEMA_OWNER_ROLE` | Managed Access スキーマ所有者 | sandbox_user |

---

## マトリクス ①: 機能的ロール × リソース権限

### Warehouse

| リソース | FR_WH_SANDBOX_OPERATE | FR_WH_SANDBOX_USE | FR_WH_MV_OPERATE | FR_WH_MV_USE |
|---------|:--------------------:|:-----------------:|:---------------:|:-----------:|
| SANDBOX_WH | USAGE + OPERATE | USAGE | — | — |
| MV_WH | — | — | USAGE + OPERATE | USAGE |

### SANDBOX_DB（作業領域）

| リソース | FR_SANDBOX_WORK_WRITE | FR_SANDBOX_WORK_READ |
|---------|:--------------------:|:-------------------:|
| SANDBOX_DB（DB 本体） | USAGE | USAGE |
| SANDBOX_DB.WORK スキーマ | USAGE + CREATE TABLE + CREATE VIEW | USAGE |
| WORK 内テーブル（future 含む） | SELECT + INSERT + UPDATE + DELETE | SELECT |
| EXTERNAL_S3_STAGE（aws.tf） | USAGE | — |

### RAW_DB: COVID19 データ

| リソース | FR_RAW_COVID19_WRITE | FR_RAW_COVID19_READ |
|---------|:-------------------:|:------------------:|
| RAW_DB（DB 本体） | USAGE | USAGE |
| RAW_DB.COVID19 スキーマ | USAGE + CREATE TABLE + CREATE VIEW | USAGE |
| COVID19_S3_STAGE | USAGE | USAGE |
| COVID19_WORLD_TESTING_STAGE | USAGE | USAGE |
| EXT_JHU_TIMESERIES（外部テーブル） | SELECT | SELECT |
| EXT_COVID19_WORLD_TESTING（外部テーブル） | SELECT | SELECT |
| MV_JHU_TIMESERIES（マテビュー） | SELECT | SELECT |
| MV_COVID19_WORLD_TESTING（マテビュー） | SELECT | SELECT |

### RAW_DB: 家計簿データ

| リソース | FR_BUDGET_BOOK_WRITE | FR_BUDGET_BOOK_READ |
|---------|:-------------------:|:------------------:|
| RAW_DB（DB 本体） | USAGE | USAGE |
| RAW_DB.BUDGET_BOOK スキーマ | USAGE + CREATE TABLE + CREATE VIEW + CREATE STAGE | USAGE |
| TRANSACTIONS テーブル | SELECT + INSERT + UPDATE + DELETE + TRUNCATE | SELECT |
| BUDGET_BOOK_STAGE | READ + WRITE | READ |
| BUDGET_BOOK_CSV_FORMAT | USAGE | USAGE |

### CORTEX_DB（AI 機能）

> **Snowflake Cortex 権限の考え方**
> - `SNOWFLAKE.CORTEX_USER` / `CORTEX_AGENT_USER` は DB ロール。付与しないと Cortex ML 関数・Agent が一切使えない。
> - `CREATE CORTEX SEARCH SERVICE` = 新しい検索サービスを作る権限（FR_CORTEX_ADMIN のみ）。
> - ステージの作成は Terraform (SYSADMIN) が担うため `CREATE STAGE` は不要。YAML 更新には既存ステージへの `WRITE` で十分。
> - Semantic View・Agent の作成も Terraform (SYSADMIN) が担う。

| リソース | FR_CORTEX_ADMIN | FR_CORTEX_USE |
|---------|:--------------:|:-------------:|
| CORTEX_DB（DB 本体） | USAGE | USAGE |
| SEMANTIC_MODELS スキーマ | USAGE | USAGE |
| SEARCH_SERVICES スキーマ | **USAGE + CREATE CORTEX SEARCH SERVICE** | USAGE |
| AGENTS スキーマ | USAGE | USAGE |
| SEMANTIC_MODEL_FILES ステージ | **READ + WRITE** | READ |
| COVID19_SEMANTIC（セマンティックビュー） | SELECT | SELECT |
| BUDGET_BOOK_SEMANTIC（セマンティックビュー） | SELECT | SELECT |
| COVID19_AGENT | USAGE | USAGE |
| BUDGET_BOOK_AGENT | USAGE | USAGE |
| BUDGET_BOOK_SEARCH | USAGE + MONITOR | USAGE |
| SNOWFLAKE.CORTEX_USER（DB ロール） | ✓ | ✓ |
| SNOWFLAKE.CORTEX_AGENT_USER（DB ロール） | ✓ | ✓ |

> **FR_CORTEX_ADMIN** = Search Service を新規作成できる + YAML ファイルを更新できる Cortex 管理者
> **FR_CORTEX_USE** = 既存の AI 機能（Agent / Search / Semantic View）を使うだけのユーザー

### MANAGED_ACCESS_DB（Managed Access テスト）

| リソース | FR_MANAGED_ACCESS_TEST |
|---------|:---------------------:|
| MANAGED_ACCESS_DB（DB 本体） | USAGE |
| MANAGED_ACCESS_DB.MANAGED_SCHEMA | USAGE + CREATE TABLE |

---

## マトリクス ②: 役割ロール × 機能的ロール（継承関係）

| 機能的ロール（FR_） | DEVELOPER | VIEWER |
|--------------------|:---------:|:------:|
| FR_WH_SANDBOX_OPERATE | ✓ | — |
| FR_WH_SANDBOX_USE | — | ✓ |
| FR_WH_MV_OPERATE | ✓ | — |
| FR_WH_MV_USE | — | ✓ |
| FR_SANDBOX_WORK_WRITE | ✓ | — |
| FR_SANDBOX_WORK_READ | — | ✓ |
| FR_RAW_COVID19_WRITE | ✓ | — |
| FR_RAW_COVID19_READ | — | ✓ |
| FR_BUDGET_BOOK_WRITE | ✓ | — |
| FR_BUDGET_BOOK_READ | — | ✓ |
| FR_CORTEX_USE | ✓ | ✓ |
| FR_CORTEX_ADMIN | ✓ | — |
| FR_MANAGED_ACCESS_TEST | ✓ | — |

> SCHEMA_OWNER_ROLE はすでに機能的ロールとして独立しているため対象外。

---

## SYSADMIN 継承

全カスタムロール（FR_ × 13個 + DEVELOPER / VIEWER / SCHEMA_OWNER）を `SYSADMIN` に継承。
これにより SYSADMIN は全権限を透過的に把握・管理できる。
