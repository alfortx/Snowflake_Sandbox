# Iceberg 学習実験

Snowflake から S3 へ Iceberg 形式でデータを書き込み・読み取る実験。物理ファイルの構造や挙動を理解することを目的とする。

## 学習目標

**第１弾（本ディレクトリ）**
- Snowflake から Iceberg Table に書き込み、S3 上の物理ファイル構造を理解する
- Snowflake から Iceberg Table を読み取り、スナップショット・タイムトラベルの挙動を理解する
- Iceberg ファイルの実体（metadata / manifest / data）と仕組みを理解する

**第２弾（今後）**
- Snowflake 以外のサービス（Spark等）からの書き込み・読み取りと機能差の理解

## インフラ構成

| リソース | 値 |
|---------|---|
| S3バケット | `snowflake-sandbox-iceberg` |
| External Volume | `ICEBERG_S3_VOLUME` |
| DB / Schema | `ICEBERG_DB.WORK` |
| WH | `SANDBOX_WH` |
| 書き込みロール | `DEVELOPER_ROLE`（→ `FR_ICEBERG_WRITE`） |
| 読み取りロール | `VIEWER_ROLE`（→ `FR_ICEBERG_READ`） |

## ファイル構成

```
experiments/iceberg/
├── README.md
├── 01_write_and_structure.ipynb  # 書き込み・S3物理構造の確認
└── 02_read_and_timetravel.ipynb  # 読み取り・スナップショット・タイムトラベル
```

## Iceberg ファイル構造（学習メモ）

Snowflake が Iceberg Table にデータを書き込むと、S3 上に以下の構造が作られる。

```
s3://snowflake-sandbox-iceberg/
└── <table_path>/
    ├── metadata/
    │   ├── v1.metadata.json      # テーブルのスキーマ・スナップショット情報
    │   ├── v2.metadata.json      # 更新のたびに新バージョンが追加される
    │   ├── snap-<id>.avro        # スナップショットのマニフェストリスト
    │   └── <uuid>-m0.avro        # マニフェストファイル（どのdataファイルがあるか）
    └── data/
        └── <partition>/
            └── <uuid>.parquet    # 実データ（Parquet形式）
```

- **metadata.json**: テーブル定義・スキーマ・パーティション情報・スナップショット一覧
- **manifest list（avro）**: スナップショットが参照するマニフェストファイルの一覧
- **manifest file（avro）**: 各 Parquet ファイルのパス・行数・統計情報
- **data（parquet）**: 実際のデータ
