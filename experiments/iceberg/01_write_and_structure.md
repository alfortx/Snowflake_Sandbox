---
title: 'Snowflake Managed Iceberg Table の書き込みで S3 に何が起きるか実際に確認してみた'
tags:
  - Snowflake
  - ApacheIceberg
  - DataLake
  - AWS
  - S3
private: false
updated_at: ''
id: null
organization_url_name: null
slide: false
ignorePublish: false
---

## TL;DR

- Snowflake Managed Iceberg Table に INSERT / UPDATE するたびに、S3 上で metadata.json → manifest list → manifest file → data file の階層構造が更新される
- External Stage を同じバケットに向けることで、Snowflake SQL から S3 のファイル一覧やメタデータ JSON の中身を直接確認できる
- UPDATE は Iceberg 内部では `delete` オペレーションとして記録される（Copy-on-Write）

## 環境

| 項目 | 値 |
|---|---|
| Snowflake Edition | Enterprise |
| クラウド / リージョン | AWS / ap-northeast-1 |
| Iceberg Format Version | 2 |
| カタログ | Snowflake Managed (`CATALOG = 'SNOWFLAKE'`) |
| データソース | `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS` |

## 背景・課題

Snowflake の Iceberg Table は「Snowflake からオープンフォーマットのデータレイクに直接書き込める」便利な機能だが、実際に S3 上にどんなファイルが作られ、DML のたびにどう変化するのかはドキュメントだけでは掴みにくい。

本記事では、Snowflake Notebook 上で **CREATE TABLE → INSERT × 2 → UPDATE** を順に実行し、各操作後の S3 ファイル構造と `metadata.json` の中身を実際に確認した。

## 実装手順

### 1. 前提：External Volume と External Stage の準備

Iceberg Table の作成には External Volume が必要。

加えて今回は、**S3 上の Iceberg ファイル構造を Snowflake SQL だけで観察するため**、同じバケットを指す External Stage を作成した。これは純粋に実験・学習目的の設定であり、通常の Iceberg Table 運用では不要。実務では AWS コンソールや CLI で S3 を直接確認するのが一般的だろう。

> **⚠️ 注意：** 以降の `LIST @stage` / `SELECT $1 FROM @stage` による S3 ファイル確認は、全てこの「実験用 External Stage」経由で行っている。Iceberg Table の動作自体には External Stage は一切関係しない。

```sql
-- External Volume（事前作成済み・Iceberg Table に必須）
-- STORAGE_BASE_URL = 's3://snowflake-sandbox-iceberg/'

-- [実験用] S3 のファイルを Snowflake から覗くための External Stage
-- ※ Iceberg Table の運用には不要。学習・デバッグ目的で作成
CREATE STAGE ICEBERG_DB.WORK.ICEBERG_WORK_STAGE
  STORAGE_INTEGRATION = ICEBERG_S3_INTEGRATION
  URL = 's3://snowflake-sandbox-iceberg/';

-- [実験用] metadata.json を SQL で読み取るためのファイルフォーマット
CREATE FILE FORMAT IF NOT EXISTS ICEBERG_DB.WORK.JSON_FF TYPE = JSON;
```

### 2. リセット & Iceberg Table の作成

繰り返し実験できるよう、最初にテーブルを削除してから作り直す。

```sql
-- リセット
ALTER ICEBERG TABLE IF EXISTS ICEBERG_DB.WORK.ORDERS_ICEBERG
  SET DATA_RETENTION_TIME_IN_DAYS = 0;
DROP ICEBERG TABLE IF EXISTS ICEBERG_DB.WORK.ORDERS_ICEBERG;
```

```sql
-- Iceberg Table の作成
CREATE OR REPLACE ICEBERG TABLE ICEBERG_DB.WORK.ORDERS_ICEBERG (
    O_ORDERKEY      NUMBER(38, 0),
    O_CUSTKEY       NUMBER(38, 0),
    O_ORDERSTATUS   STRING,
    O_TOTALPRICE    NUMBER(12, 2),
    O_ORDERDATE     DATE,
    O_ORDERPRIORITY STRING,
    O_CLERK         STRING,
    O_SHIPPRIORITY  NUMBER(38, 0),
    O_COMMENT       STRING
)
EXTERNAL_VOLUME = 'ICEBERG_S3_VOLUME'
CATALOG = 'SNOWFLAKE'
BASE_LOCATION = 'orders_iceberg/';
```

> **注意：** Iceberg Table では `VARCHAR(N)` は使えない。`STRING`（最大長）のみ対応。

### 3. base_location の動的取得

`CREATE TABLE` のたびに `BASE_LOCATION` 配下にランダムサフィックス付きのサブディレクトリが作られる（例: `orders_iceberg.HsW2o7Tu/`）。前述の実験用 External Stage で `LIST` する際にこのパスが必要になるため、Python セルで動的に取得し、以降の SQL セルで Jinja 変数として参照する。こちらも S3 ファイル観察のための実験用コードであり、通常の Iceberg Table 利用では不要。

```python
row = session.sql(
    "SHOW ICEBERG TABLES LIKE 'ORDERS_ICEBERG' IN SCHEMA ICEBERG_DB.WORK"
).collect()
base_location = row[0]['base_location']
stage_path = f'@ICEBERG_DB.WORK.ICEBERG_WORK_STAGE/{base_location}'
```

### 4. S3 ファイル確認の方法

各 DML 操作後に以下の 2 クエリで S3 の状態を確認する。

```sql
-- ファイル一覧
LIST {{stage_path}};

-- 最新 metadata.json の中身
SELECT $1 AS metadata_json
FROM {{stage_path}}metadata/
  (FILE_FORMAT => 'ICEBERG_DB.WORK.JSON_FF',
   PATTERN => '.*metadata\\.json')
ORDER BY METADATA$FILENAME DESC
LIMIT 1;
```

### 5. CREATE TABLE 直後の S3

```
orders_iceberg.XXXXXXXX/
└── metadata/
    └── 00000-...metadata.json   (1.3 KiB)
```

以下は CREATE TABLE 直後の `metadata.json` の全プロパティ解説。

#### トップレベルプロパティ

| プロパティ | 型 | 今回の値 | 説明 |
|---|---|---|---|
| `format-version` | int | `2` | Iceberg テーブル仕様のバージョン。v2 は row-level deletes をサポート |
| `table-uuid` | string | `479c7d33-...` | テーブルのグローバル一意識別子。CREATE ごとに新規生成 |
| `location` | string | `s3://...` | テーブルのルートディレクトリ（data/ と metadata/ の親） |
| `last-sequence-number` | long | `0` | 最後に採番されたシーケンス番号。DML ごとに +1 |
| `last-updated-ms` | long | `1777433391668` | メタデータ最終更新のエポックミリ秒 |
| `last-column-id` | int | `9` | スキーマ内のカラム ID の最大値 |
| `current-schema-id` | int | `0` | 現在有効なスキーマの ID |
| `current-snapshot-id` | long | `-1` | 現在のスナップショット ID。`-1` = スナップショットなし |
| `default-spec-id` | int | `0` | デフォルトのパーティション仕様 ID |
| `last-partition-id` | int | `999` | パーティションフィールド ID の最大値（Snowflake 既定） |
| `default-sort-order-id` | int | `0` | デフォルトのソート順 ID |

#### schemas（スキーマ定義）

テーブルのカラム定義の配列。スキーマ進化（ALTER TABLE ADD COLUMN 等）時に新しいエントリが追加される。

```json
{
  "type": "struct",
  "schema-id": 0,
  "fields": [
    {"id": 1, "name": "O_ORDERKEY", "required": false, "type": "decimal(38, 0)"},
    {"id": 2, "name": "O_CUSTKEY",  "required": false, "type": "decimal(38, 0)"},
    ...
  ]
}
```

| フィールド | 説明 |
|---|---|
| `id` | カラムの一意 ID（スキーマ進化で不変） |
| `name` | カラム名 |
| `required` | NOT NULL 制約。Snowflake では常に `false` |
| `type` | Iceberg データ型（`decimal`, `string`, `date` など） |

#### partition-specs（パーティション仕様）

```json
[{"spec-id": 0, "fields": []}]
```

パーティションなしの場合 `fields` は空配列。パーティション有りの場合、`source-id`（元カラムID）、`transform`（`year`, `month`, `day`, `bucket` 等）、`name` が含まれる。

#### sort-orders（ソート順）

```json
[{"order-id": 0, "fields": []}]
```

ソート指定なしの場合 `fields` は空配列。

#### properties（テーブルプロパティ）

| キー | 今回の値 | 説明 |
|---|---|---|
| `history.expire.max-snapshot-age-ms` | `86400000` | スナップショットの最大保持期間（ミリ秒）。24時間 |
| `snowflake.operation.1.0` | `{"ts":...}` | Snowflake 固有のオペレーション追跡メタデータ |

#### snapshots（スナップショット配列）

CREATE TABLE 直後は `[]`（空）。DML 実行後に以下の構造で追加される：

| フィールド | 型 | 説明 |
|---|---|---|
| `snapshot-id` | long | スナップショットの一意 ID |
| `parent-snapshot-id` | long | 親スナップショット ID（チェーン構造を形成） |
| `sequence-number` | long | スナップショットのシーケンス番号 |
| `timestamp-ms` | long | コミット時刻（エポックミリ秒） |
| `manifest-list` | string | マニフェストリストファイルの S3 パス |
| `schema-id` | int | このスナップショットが参照するスキーマ ID |
| `summary` | object | 操作のサマリー（下表参照） |

##### summary の主要フィールド

| フィールド | 説明 |
|---|---|
| `operation` | `append`（INSERT）/ `delete`（UPDATE/DELETE）/ `overwrite` |
| `added-data-files` | 追加されたデータファイル数 |
| `added-records` | 追加されたレコード数 |
| `added-files-size` | 追加ファイルの合計バイト数 |
| `total-records` | テーブル全体の累計レコード数 |
| `total-data-files` | テーブル全体の累計データファイル数 |
| `total-delete-files` | 削除ファイル数（v2 の position/equality deletes） |
| `total-position-deletes` | position delete の累計行数 |
| `total-equality-deletes` | equality delete の累計行数 |

#### refs（ブランチ・タグ参照）

```json
{}
```

Iceberg v2 ではブランチやタグで特定スナップショットに名前を付けられる。Snowflake Managed ではデフォルト空。

#### metadata-log（メタデータ履歴）

```json
[]
```

過去の `metadata.json` ファイルへの参照リスト。DML のたびに直前の metadata ファイルが追加される。

| フィールド | 説明 |
|---|---|
| `timestamp-ms` | そのメタデータファイルが作成された時刻 |
| `metadata-file` | S3 上のフルパス |

#### snapshot-log / statistics / partition-statistics

いずれも CREATE TABLE 直後は `[]`（空配列）。`snapshot-log` はスナップショット履歴の簡易ログ、`statistics` / `partition-statistics` は統計情報の参照先。

---

テーブル定義（スキーマ）のみが記録され、データもスナップショットもまだない。

### 6. 1回目 INSERT 後の S3

```sql
INSERT INTO ICEBERG_DB.WORK.ORDERS_ICEBERG
SELECT O_ORDERKEY, O_CUSTKEY, O_ORDERSTATUS, O_TOTALPRICE,
       O_ORDERDATE, O_ORDERPRIORITY, O_CLERK, O_SHIPPRIORITY, O_COMMENT
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS
WHERE YEAR(O_ORDERDATE) = 1996
  AND O_ORDERKEY <= 40000;
```

```
orders_iceberg.XXXXXXXX/
├── data/
│   └── XX/
│       └── snow_..._002.parquet          (41.0 KiB)
└── metadata/
    ├── 00000-...metadata.json            (1.3 KiB)  ← CREATE TABLE 時
    ├── 00001-...metadata.json            (2.3 KiB)  ← INSERT 後（最新）
    ├── XXXXXXXX-...-m0.avro              (7.5 KiB)  ← manifest file
    └── snap-XXXX...-XXXXXXXX-...avro     (4.4 KiB)  ← manifest list
```

| プロパティ | CREATE 直後 → INSERT 後 |
|---|---|
| last-sequence-number | 0 → **1** |
| current-snapshot-id | -1 → **新規 ID** |
| snapshots | 空 → **1件（operation: append, 1,524 records）** |

### 7. 2回目 INSERT 後の S3

```sql
INSERT INTO ICEBERG_DB.WORK.ORDERS_ICEBERG
SELECT ...
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS
WHERE YEAR(O_ORDERDATE) = 1997
  AND O_ORDERKEY <= 40000;
```

新しいデータファイル（`.parquet`）が 1 つ追加され、metadata は `00002` にインクリメント。

| プロパティ | 1回目 INSERT 後 → 2回目 INSERT 後 |
|---|---|
| last-sequence-number | 1 → **2** |
| snapshots | 1件 → **2件** |
| total-records | 1,524 → **3,045** |
| total-data-files | 1 → **2** |

2件目のスナップショットは `parent-snapshot-id` で1件目を参照しており、スナップショットチェーンが形成されている。

### 8. UPDATE 後の S3

```sql
UPDATE ICEBERG_DB.WORK.ORDERS_ICEBERG
SET O_ORDERSTATUS = 'X'
WHERE YEAR(O_ORDERDATE) = 1996
  AND O_ORDERKEY < 30000;
```

| プロパティ | 2回目 INSERT 後 → UPDATE 後 |
|---|---|
| last-sequence-number | 2 → **3** |
| snapshots | 2件 → **3件** |
| 3件目の operation | — | **delete** |

**ポイント：** UPDATE なのに operation が `delete` と記録される。Iceberg v2 では UPDATE は Copy-on-Write（COW）方式で、旧データの削除 + 新データの追加として処理される。

## ハマったポイントと解決策

### 1. `VARCHAR(N)` が使えない

```
SQL Compilation error:
For Iceberg tables, only max length (134,217,728) is supported for 'VARCHAR(L)/STRING(L)'
```

**解決策：** 全て `STRING` に変更。Iceberg テーブルでは長さ制限付き VARCHAR は非対応。

### 2. `SYSTEM$GET_ICEBERG_TABLE_INFORMATION` の戻り値が JSON でない場合がある

テーブル状態が不正（メタデータファイル欠損など）だと、`Failed to generate Iceberg metadata...` というプレーンテキストが返る。`PARSE_JSON()` がエラーになる。

**解決策：** `TRY_PARSE_JSON()` を使うか、`PARSE_JSON` を外して生文字列で確認する。

### 3. External Volume を `LIST` できない

`LIST 'snow://iceberg_s3_volume/...'` は `Unsupported feature` エラーになる。

**解決策：** 同じ S3 バケットを指す **External Stage** を別途作成し、そちらで `LIST` / `SELECT $1 FROM @stage` する。

### 4. `DROP ICEBERG TABLE` 後も S3 にファイルが残る

`DATA_RETENTION_TIME_IN_DAYS = 0` に設定してから DROP しても、S3 ファイルの削除は非同期。数分待つと削除される。

### 5. `CREATE OR REPLACE` の挙動

`CREATE OR REPLACE` は毎回新しいサブディレクトリ（ランダムサフィックス付き）を生成するため、旧ファイルが S3 に残っていても新テーブルの動作には影響しない。ただし孤立ファイルとしてストレージコストがかかる。

## Iceberg メタデータの階層構造（まとめ）

```
metadata.json          ← テーブルの現在の状態を定義するエントリポイント
  ├── snapshot(s)          ← 各 DML 操作の時点
  │     └── manifest list (.avro)   ← マニフェストリストファイル
  │           └── manifest file(s) (.avro)  ← マニフェストファイル（データファイル一覧）
  │                 └── data file(s) (.parquet)  ← 実データ
```

DML のたびに `metadata.json` のバージョン番号がインクリメントされ（`00000` → `00001` → `00002` → ...）、新しいスナップショットが追加される。

## まとめ

- Snowflake Managed Iceberg Table は **S3 上にオープンフォーマット（Parquet + Iceberg metadata）** でデータを書き込む
- 各 DML 操作ごとにスナップショットが作成され、`metadata.json` が更新される
- External Stage を活用すれば、**Snowflake SQL だけで S3 のファイル一覧やメタデータ JSON を直接確認**できる
- 次回（第2弾）は Time Travel と読み取り側の挙動を確認予定
