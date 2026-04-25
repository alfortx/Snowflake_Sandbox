# 企業名名寄せ実験（EDINET × JPX）

Snowflake **Cortex Search Service** を使って、EDINET と JPX の企業名表記揺れを吸収しながら名寄せする実験。証券コードによる完全一致をグランドトゥルースとし、Precision@1 / Recall@3 で精度を定量評価する。

## ディレクトリ構成

```
experiments/company_matching/
├── company_name_matching_experiment.ipynb  # メイン実験Notebook（実データ）
├── convert_jpx.py                          # JPX Excel → CSV 変換スクリプト
├── check_source_tables/
│   └── 01_setup_tables.sql                # サンプルデータ用テーブル作成
├── experiments_for_sample_data/
│   ├── 00_check_jpx_code.sql              # JPX証券コードの型変換・品質確認
│   ├── 02_create_search_service.sql       # Cortex Search Service 作成
│   └── 03_matching_analysis.sql           # 名寄せ実行・結果分析
└── Cortex Search Overview _standalone_.html  # 参考資料
```

## 実験フロー

| STEP | 処理 | 出力テーブル |
|------|------|-------------|
| 0 | データ品質確認（件数・NULL率・証券コード保有率） | — |
| 1 | 正解データ作成（SECURITIES_CODE 完全一致結合） | `SANDBOX_DB.WORK.EDINET_JPX_GROUND_TRUTH` |
| 2 | Cortex Search Service 作成（EDINET 社名をインデックス化） | `CORTEX_DB.SEARCH_SERVICES.EDINET_COMPANY_SEARCH` |
| 3 | 単件確認（任意の社名で動作確認） | — |
| 4 | 全件マッチング（`CORTEX_SEARCH_BATCH` で一括処理） | `SANDBOX_DB.WORK.EDINET_JPX_MATCH_RESULT` |
| 5 | 精度評価（Precision@1 / Recall@3） | — |

## 各ファイルの説明

### `company_name_matching_experiment.ipynb`
実データ（EDINET × JPX 約3,600社）を対象とした実験メインNotebook。上記6ステップを通しで実行できる。

### `convert_jpx.py`
JPX が公開する上場銘柄一覧 Excel（`data_j.xls`）を CSV に変換するスクリプト。数値セルの `.0` 除去（例: `1301.0` → `1301`）を行い、`~/Downloads/data_j.csv` に出力する。S3 アップロード前の前処理として使用。

### `check_source_tables/`
サンプルデータを使った動作確認用。トヨタ・NTT 等 15 社の社名を `SALES_INFO`（正式名）と `SALES_ACTIVITY`（表記揺れ）の 2 テーブルに分けて格納し、名寄せの挙動を小規模で確認できる。

### `experiments_for_sample_data/`
サンプルデータを対象に Cortex Search Service の作成・名寄せ・分析を実行する SQL 一式。実データ用の Notebook と同じ処理を SQL 単体で試す用途。

## 名寄せの課題

同一企業でも社名の表記が異なるケースが多い。

| パターン | JPX 表記例 | EDINET 表記例 |
|----------|-----------|---------------|
| 株式会社の位置 | マルハニチロ | 株式会社マルハニチロ |
| 略称 vs 正式名 | ＳＧＨＤ | ＳＧホールディングス株式会社 |
| 全角/半角混在 | ＡＮＡホールディングス | ANAホールディングス株式会社 |

Cortex Search Service のセマンティック検索でこの表記揺れを吸収し、証券コード一致を正解ラベルとして精度を測定する。
