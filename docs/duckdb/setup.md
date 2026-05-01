# DuckDB 環境セットアップ手順

## 前提

- Python 3.x がインストール済み
- プロジェクトルート（`Snowflake_Sandbox/`）で作業すること

---

## 初回セットアップ

### 1. 仮想環境を作成（未作成の場合のみ）

```bash
python3 -m venv venv
```

### 2. 仮想環境を有効化

```bash
# Mac/Linux
source venv/bin/activate

# Windows
venv\Scripts\activate
```

### 3. パッケージをインストール

```bash
pip install -r requirements.txt
```

これで DuckDB・Jupyter・Snowflake Connector など全パッケージが入る。

---

## サンプルデータの生成

Notebook で使用するCSV・Parquetファイルはスクリプトで生成します。
データファイルはGit管理外のため、**初回クローン後に必ず実行**してください。

```bash
# CSVを生成（duckdb/data/ に customers.csv / products.csv / sales.csv が作成される）
python3 duckdb/data/generate_sample.py
```

次に `02_parquet.ipynb` の変換セルを実行すると `duckdb/data/parquet/` 配下のParquetファイルが生成されます。
または以下のコマンドでまとめて変換できます。

```bash
python3 -c "
import duckdb, os
con = duckdb.connect()
os.makedirs('duckdb/data/parquet/monthly', exist_ok=True)
for t in ['customers','products','sales']:
    con.execute(f\"COPY (SELECT * FROM read_csv_auto('duckdb/data/{t}.csv')) TO 'duckdb/data/parquet/{t}.parquet' (FORMAT PARQUET)\")
    print(f'✓ {t}.parquet')
months = con.execute(\"SELECT DISTINCT strftime(sale_date,'%Y-%m') AS ym FROM read_parquet('duckdb/data/parquet/sales.parquet') ORDER BY ym\").fetchall()
for (ym,) in months:
    con.execute(f\"COPY (SELECT * FROM read_parquet('duckdb/data/parquet/sales.parquet') WHERE strftime(sale_date,'%Y-%m')='{ym}') TO 'duckdb/data/parquet/monthly/sales_{ym}.parquet' (FORMAT PARQUET)\")
    print(f'✓ sales_{ym}.parquet')
"
```

---

## Jupyter Notebook の起動

```bash
# プロジェクトルートで実行
source venv/bin/activate
jupyter notebook duckdb/notebooks/
```

ブラウザが自動で開く。`01_basics.ipynb` から学習スタート。

---

## パッケージを追加したいとき

```bash
# インストール
pip install <パッケージ名>

# requirements.txt に反映（バージョン固定して追記）
pip freeze | grep <パッケージ名> >> requirements.txt
```

---

## ディレクトリ構成

```
Snowflake_Sandbox/
├── requirements.txt       # 依存パッケージ一覧
├── venv/                  # 仮想環境（Git管理外）
├── duckdb/
│   ├── data/              # サンプルCSVデータ
│   └── notebooks/         # Jupyter Notebook（学習用）
└── docs/duckdb/
    ├── setup.md           # このファイル
    └── study_guide.md     # 学習計画メモ
```
