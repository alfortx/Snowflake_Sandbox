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
