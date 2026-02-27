# データロード設計書

## 概要

COVID-19 Data Lake（AWS公開S3）からSnowflakeへデータを取り込み、スタースキーマで管理するサンドボックス環境のデータロード設計。

---

## 技術スタック

| 役割 | ツール |
|------|--------|
| インフラ管理 | Terraform |
| データソース | COVID-19 Data Lake（AWS公開S3） |
| データロード | SnowSQL / Snowflake SQL スクリプト |
| データ変換（後続） | dbt（本設計書のスコープ外） |

---

## データソース詳細

| 項目 | 内容 |
|------|------|
| S3バケット | `s3://covid19-lake/` |
| 使用データセット | `enigma-jhu-timeseries`（JHU CSSE 感染者数時系列） |
| S3パス | `s3://covid19-lake/enigma-jhu-timeseries/csv/` |
| ファイル名 | `jhu_csse_covid_19_timeseries_merged.csv` |
| 形式 | CSV（ヘッダーあり） |
| 認証 | 不要（公開バケット） |
| リージョン | `us-east-1` |

---

## Snowflakeリソース設計

### Database / Schema

| リソース | 名前 | 用途 |
|----------|------|------|
| Database | `RAW_DB` | 全リソースの格納先 |
| Schema | `COVID19` | ステージ・ファイルフォーマット・テーブルを格納 |

### ファイルフォーマット

| 項目 | 設定値 |
|------|--------|
| 名前 | `RAW_DB.COVID19.CSV_FORMAT` |
| 種別 | `CSV` |
| ヘッダースキップ | `SKIP_HEADER = 1` |
| クォート | `FIELD_OPTIONALLY_ENCLOSED_BY = '"'` |
| NULL処理 | `NULL_IF = ('', 'NA', 'NULL')` |

### 外部ステージ

| 項目 | 設定値 |
|------|--------|
| 名前 | `RAW_DB.COVID19.COVID19_S3_STAGE` |
| S3 URL | `s3://covid19-lake/enigma-jhu-timeseries/csv/` |
| 認証 | 不要（公開バケット） |
| ファイルフォーマット | `RAW_DB.COVID19.CSV_FORMAT` |

---

## テーブル設計

テーブルはdbt管理のためTerraformスコープ外。参考情報として設計を記載する。

### テーブル一覧

| テーブル名 | 種別 | 概要 | 想定レコード数 |
|-----------|------|------|----------------|
| `RAW_JHU_TIMESERIES` | Rawテーブル | S3からの直接ロード先 | 数十万件 |
| `FACT_COVID_CASES` | ファクト | 地域×日付単位の感染者数 | 数十万件 |
| `DIM_DATE` | ディメンション | 日付の時間軸 | ～2,000件（日単位） |
| `DIM_LOCATION` | ディメンション | 国・州・地域情報 | 数千件 |

### Rawテーブル（`RAW_JHU_TIMESERIES`）

S3のCSVをそのままロードするステージングテーブル。カラム名はソースに準拠。

| カラム名 | 型 | 備考 |
|----------|----|------|
| `UID` | NUMBER | 地域識別子 |
| `FIPS` | NUMBER | 米国FIPS地域コード |
| `ISO2` | VARCHAR(2) | ISO 3166-1 alpha-2 国コード |
| `ISO3` | VARCHAR(3) | ISO 3166-1 alpha-3 国コード |
| `CODE3` | NUMBER | 国コード数値 |
| `ADMIN2` | VARCHAR(100) | 郡・市区町村名（米国のみ） |
| `LATITUDE` | FLOAT | 緯度 |
| `LONGITUDE` | FLOAT | 経度 |
| `PROVINCE_STATE` | VARCHAR(100) | 州・省名 |
| `COUNTRY_REGION` | VARCHAR(100) | 国・地域名 |
| `DATE` | DATE | 日付 |
| `CONFIRMED` | NUMBER | 累計感染確認数 |
| `DEATHS` | NUMBER | 累計死亡数 |
| `RECOVERED` | NUMBER | 累計回復数 |

### ディメンション・ファクトテーブル（dbt管理）

**`DIM_LOCATION`**

| カラム名 | 型 | 備考 |
|----------|----|------|
| `LOCATION_ID` | NUMBER | PK（サロゲート） |
| `UID` | NUMBER | JHUソースキー |
| `ISO2` | VARCHAR(2) | |
| `ISO3` | VARCHAR(3) | |
| `COUNTRY_REGION` | VARCHAR(100) | 国名 |
| `PROVINCE_STATE` | VARCHAR(100) | 州・省名 |
| `ADMIN2` | VARCHAR(100) | 郡・市区町村名 |
| `LATITUDE` | FLOAT | |
| `LONGITUDE` | FLOAT | |

**`DIM_DATE`**（Rawテーブルの `DATE` カラムからdbtで生成）

| カラム名 | 型 | 備考 |
|----------|----|------|
| `DATE_ID` | NUMBER | PK |
| `DATE` | DATE | |
| `YEAR` | NUMBER | |
| `MONTH` | NUMBER | |
| `DAY` | NUMBER | |
| `DAY_OF_WEEK` | NUMBER | |
| `DAY_NAME` | VARCHAR(20) | |
| `IS_WEEKEND` | BOOLEAN | |
| `QUARTER` | NUMBER | |

**`FACT_COVID_CASES`**

| カラム名 | 型 | 分類 |
|----------|----|------|
| `CASE_ID` | NUMBER | PK（サロゲート） |
| `DATE_ID` | NUMBER | FK → DIM_DATE |
| `LOCATION_ID` | NUMBER | FK → DIM_LOCATION |
| `CONFIRMED` | NUMBER | メジャー（累計感染数） |
| `DEATHS` | NUMBER | メジャー（累計死亡数） |
| `RECOVERED` | NUMBER | メジャー（累計回復数） |
| `NEW_CONFIRMED` | NUMBER | メジャー（前日比・dbtで算出） |
| `NEW_DEATHS` | NUMBER | メジャー（前日比・dbtで算出） |

---

## Terraform実装

```hcl
# ─── File Format ────────────────────────────────────────
resource "snowflake_file_format" "csv_format" {
  database                      = snowflake_database.raw_db.name
  schema                        = snowflake_schema.covid19.name
  name                          = "CSV_FORMAT"
  format_type                   = "CSV"
  skip_header                   = 1
  field_optionally_enclosed_by  = "\""
  null_if                       = ["", "NA", "NULL"]
  comment                       = "CSV format for COVID-19 Data Lake"
}

# ─── External Stage ─────────────────────────────────────
resource "snowflake_stage" "covid19_s3_stage" {
  database    = snowflake_database.raw_db.name
  schema      = snowflake_schema.covid19.name
  name        = "COVID19_S3_STAGE"
  url         = "s3://covid19-lake/enigma-jhu-timeseries/csv/"
  file_format = "FORMAT_NAME = RAW_DB.COVID19.CSV_FORMAT"
  comment     = "Public S3 stage for JHU COVID-19 timeseries data (no credentials required)"

  depends_on = [snowflake_file_format.csv_format]
}
```

---

## データロードスクリプト（`scripts/load_data.sql`）

`terraform apply` 完了後、かつdbtによるテーブル作成完了後に実行する。

```sql
-- ================================================================
-- COVID-19 JHU Timeseries データロードスクリプト
-- ソース: s3://covid19-lake/enigma-jhu-timeseries/csv/
-- ================================================================

USE DATABASE RAW_DB;
USE SCHEMA COVID19;

-- ─── 1. ステージ確認 ──────────────────────────────────────────
LIST @COVID19_S3_STAGE;

-- ─── 2. Rawテーブルへのデータロード ─────────────────────────
COPY INTO RAW_JHU_TIMESERIES (
  UID, FIPS, ISO2, ISO3, CODE3, ADMIN2,
  LATITUDE, LONGITUDE, PROVINCE_STATE, COUNTRY_REGION,
  DATE, CONFIRMED, DEATHS, RECOVERED
)
FROM @COVID19_S3_STAGE
PATTERN = '.*jhu_csse_covid_19_timeseries_merged\.csv'
FILE_FORMAT = (FORMAT_NAME = 'RAW_DB.COVID19.CSV_FORMAT')
ON_ERROR = CONTINUE;

-- ─── 3. ロード件数確認 ───────────────────────────────────────
SELECT COUNT(*) FROM RAW_JHU_TIMESERIES;

-- ─── 4. データ確認（先頭10件） ───────────────────────────────
SELECT * FROM RAW_JHU_TIMESERIES LIMIT 10;
```

---

## 外部テーブル設計

COPY INTO によるデータ移動を省略し、S3上のCSVをSnowflakeのテーブルとして直接参照する方式。

### COPY INTO との比較

| 項目 | COPY INTO | 外部テーブル |
|------|-----------|-------------|
| データ移動 | あり（S3→Snowflake） | なし（S3を直接参照） |
| クエリ速度 | 速い（ネイティブ） | 遅い（毎回S3読み込み） |
| ストレージコスト | Snowflake分が発生 | S3のみ |
| データ鮮度 | ロード時点で固定 | 常に最新 |
| 向いているケース | 繰り返し分析、大規模変換 | 静的データ、軽量参照 |

> 今回のCOVID-19データは更新停止済みの静的データのため、外部テーブルが適している。

### テーブル設計

| 項目 | 設定値 |
|------|--------|
| テーブル名 | `RAW_DB.COVID19.EXT_JHU_TIMESERIES` |
| ステージ | `@RAW_DB.COVID19.COVID19_S3_STAGE` |
| ファイルフォーマット | `RAW_DB.COVID19.CSV_FORMAT` |
| AUTO_REFRESH | `FALSE`（静的データのため不要） |
| 管理方法 | SQLスクリプト（Terraformスコープ外） |

### カラム定義

外部テーブルはCSVの列を位置（`c1`, `c2` ...）で参照する。

| カラム名 | 型 | CSVの列位置 |
|----------|----|------------|
| `UID` | NUMBER | c1（1列目） |
| `FIPS` | NUMBER | c2 |
| `ISO2` | VARCHAR(2) | c3 |
| `ISO3` | VARCHAR(3) | c4 |
| `CODE3` | NUMBER | c5 |
| `ADMIN2` | VARCHAR(100) | c6 |
| `LATITUDE` | FLOAT | c7 |
| `LONGITUDE` | FLOAT | c8 |
| `PROVINCE_STATE` | VARCHAR(100) | c9 |
| `COUNTRY_REGION` | VARCHAR(100) | c10 |
| `DATE` | DATE | c11 |
| `CONFIRMED` | NUMBER | c12 |
| `DEATHS` | NUMBER | c13 |
| `RECOVERED` | NUMBER | c14 |

### SQLスクリプト（`scripts/create_external_table.sql`）

```sql
USE DATABASE RAW_DB;
USE SCHEMA COVID19;
USE WAREHOUSE SANDBOX_WH;
USE ROLE SYSADMIN;

CREATE OR REPLACE EXTERNAL TABLE EXT_JHU_TIMESERIES (
  UID            NUMBER        AS (VALUE:c1::NUMBER),
  FIPS           NUMBER        AS (VALUE:c2::NUMBER),
  ISO2           VARCHAR(2)    AS (VALUE:c3::VARCHAR),
  ISO3           VARCHAR(3)    AS (VALUE:c4::VARCHAR),
  CODE3          NUMBER        AS (VALUE:c5::NUMBER),
  ADMIN2         VARCHAR(100)  AS (VALUE:c6::VARCHAR),
  LATITUDE       FLOAT         AS (VALUE:c7::FLOAT),
  LONGITUDE      FLOAT         AS (VALUE:c8::FLOAT),
  PROVINCE_STATE VARCHAR(100)  AS (VALUE:c9::VARCHAR),
  COUNTRY_REGION VARCHAR(100)  AS (VALUE:c10::VARCHAR),
  DATE           DATE          AS (VALUE:c11::DATE),
  CONFIRMED      NUMBER        AS (VALUE:c12::NUMBER),
  DEATHS         NUMBER        AS (VALUE:c13::NUMBER),
  RECOVERED      NUMBER        AS (VALUE:c14::NUMBER)
)
WITH LOCATION = @COVID19_S3_STAGE
FILE_FORMAT = (FORMAT_NAME = 'RAW_DB.COVID19.CSV_FORMAT')
AUTO_REFRESH = FALSE;

-- 動作確認
SELECT COUNT(*) FROM EXT_JHU_TIMESERIES;
SELECT * FROM EXT_JHU_TIMESERIES LIMIT 10;
```

### dbt連携（`sources.yml`）

dbtから外部テーブルをソースとして参照する設定。

```yaml
sources:
  - name: covid19
    database: RAW_DB
    schema: COVID19
    tables:
      - name: ext_jhu_timeseries
        description: "JHU COVID-19 時系列データ（S3外部テーブル）"
```

dbtモデル内では `{{ source('covid19', 'ext_jhu_timeseries') }}` で参照する。

---

## 注意事項

| 項目 | 内容 |
|------|------|
| S3リージョン | `us-east-1`。Snowflakeアカウントが別リージョンでも公開バケットからのIngestは無料 |
| 累計値に注意 | `CONFIRMED` / `DEATHS` / `RECOVERED` は累計値。前日比（新規数）はdbtで算出する |
| データ更新停止 | JHUは2023年3月にデータ更新を停止。過去データとして扱うこと |
| NULL処理 | `ADMIN2`（郡名）は米国以外はNULL。`RECOVERED` は後期データでNULLあり |
