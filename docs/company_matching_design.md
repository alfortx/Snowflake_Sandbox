# ベクトル類似度による企業名名寄せ実験

Cortex Search Service を使って、表記揺れのある社名を持つ2テーブルを意味的に紐付ける実験的実装。

---

## 全体フロー図

```mermaid
flowchart TD
    subgraph SRC["SANDBOX_DB.WORK（ソースデータ）"]
        direction LR
        SI["SALES_INFO\n─────────────\nCOMPANY_NAME ★索引対象\nCOMPANY_CANONICAL\nAMOUNT / SALES_DATE\n─────────────\n正式社名 15件"]
        SA["SALES_ACTIVITY\n─────────────\nCOMPANY_NAME ★クエリ\nACTIVITY_TYPE\nACTIVITY_DATE / MEMO\n─────────────\n表記揺れ社名 18件"]
    end

    subgraph CSS_BOX["CORTEX_DB.SEARCH_SERVICES"]
        CSS["COMPANY_NAME_SEARCH\n─────────────────────\nON: COMPANY_NAME\nEMBEDDING_MODEL:\n  arctic-embed-l-v2.0\nTARGET_LAG: 1 hour\n─────────────────────\n内部ベクトルインデックス\n※ユーザーからは見えない"]
    end

    subgraph PROC_BOX["ストアドプロシージャ（MATCH_ALL_COMPANIES）"]
        PROC["① SALES_ACTIVITY を1社ずつ取り出す\n② 社名をJSON文字列に埋め込む\n③ SEARCH_PREVIEW に投げる\n④ 返却JSONをLATERAL FLATTENで行に展開\n⑤ COMPANY_MATCH_RESULT へ INSERT"]
    end

    subgraph RESULT_BOX["SANDBOX_DB.WORK（名寄せ結果）"]
        MR["COMPANY_MATCH_RESULT\n─────────────────────\nACTIVITY_ID\nACTIVITY_COMPANY  ← 元の表記揺れ社名\nMATCHED_SALES_ID\nMATCHED_COMPANY   ← マッチした正式社名\nRELEVANCE_SCORE   ← cosine_similarity\nMATCH_RANK        ← 1=ベストマッチ\n─────────────────────\n18社 × 3候補 = 54行"]
    end

    subgraph ANA["分析クエリ（STEP 3）"]
        direction LR
        A1["ベストマッチ\n一覧"]
        A2["スコア\n分布"]
        A3["売上×営業\nクロス集計"]
        A4["非マッチ\n検出"]
    end

    SI -- "②\n02_create_search_service.sql\nCOMPANY_NAME を自動EMBED\n→ 内部インデックスに保存" --> CSS
    SA -- "③\n03_matching_analysis.sql STEP2\nCALL MATCH_ALL_COMPANIES()" --> PROC
    PROC -- "SEARCH_PREVIEW()\nクエリをベクトル化\nANNで高速サーチ" --> CSS
    CSS -- "上位3件\n+ cosine_similarity" --> PROC
    PROC -- "INSERT" --> MR
    MR --> A1
    MR --> A2
    MR --> A3
    MR --> A4

    style SI fill:#dbeafe,stroke:#3b82f6
    style SA fill:#dcfce7,stroke:#22c55e
    style CSS fill:#fef9c3,stroke:#eab308
    style MR fill:#f3e8ff,stroke:#a855f7
```

---

## データフロー

| ステップ | ファイル | やること |
|---------|---------|---------|
| ① | `01_setup_tables.sql` | 3テーブルのDDL + サンプルデータINSERT |
| ② | `02_create_search_service.sql` | SALES_INFO 社名を自動ベクトル化して索引化 |
| ③ | `03_matching_analysis.sql` STEP1 | 個別クエリで動作確認 |
| ④ | `03_matching_analysis.sql` STEP2 | SALES_ACTIVITY 全件クエリ → COMPANY_MATCH_RESULT へ保存 |
| ⑤ | `03_matching_analysis.sql` STEP3 | 紐付き結果でビジネス分析 |

---

## Cortex Search Service のインデックス化の仕組み

```
SALES_INFO テーブル
    ↓ CREATE CORTEX SEARCH SERVICE 時
COMPANY_NAME 列を自動で EMBED（ベクトル化）
    ↓ 内部ベクトルストアに保存（ユーザーからは見えない）
    ↓ TARGET_LAG に従って定期的に差分更新

クエリ（SALES_ACTIVITY の COMPANY_NAME）
    ↓ 同じモデルで EMBED → クエリベクトル生成
    ↓ ANN（近似最近傍探索）でインデックスを高速サーチ
結果: relevance_score 付きの候補リスト
```

### 通常の CROSS JOIN との違い

| 観点 | CROSS JOIN + VECTOR_COSINE_SIMILARITY | Cortex Search Service |
|------|--------------------------------------|----------------------|
| ベクトル保存 | 自分でテーブルに保存 | サービス内部に自動管理 |
| 検索方式 | 全件総当り | ANN インデックス（高速）|
| スケール | 数百件まで | 数億件まで対応 |
| 更新 | 手動で再 INSERT | TARGET_LAG で自動差分更新 |

---

## テーブル設計

### SALES_INFO（売上情報）

- `COMPANY_NAME`（`ON` 句）: Search Service がベクトルインデックスを作成する対象列
- `COMPANY_CANONICAL`: 正規化社名。グループ集計（トヨタグループ全体の売上合計など）に活用
- `ATTRIBUTES` に指定した列（SALES_ID, AMOUNT, SALES_DATE）: フィルタや返却値として使用可能

### SALES_ACTIVITY（営業活動情報）

- `COMPANY_NAME`: Search Service への検索クエリ文字列として使用
- Search Service を作成しない（クエリを投げる側）

### COMPANY_MATCH_RESULT（名寄せ結果テーブル）

- 名寄せ実行のたびに INSERT（もしくは MERGE で更新）
- `MATCH_RANK = 1` がベストマッチ、`2` 以降は次点候補
- 分析クエリのベーステーブルとなる

---

## 実行手順

```sql
-- 1. テーブル作成・サンプルデータ投入
-- experiments/company_matching/01_setup_tables.sql を実行

-- 2. Search Service 作成（数分待機）
-- experiments/company_matching/02_create_search_service.sql を実行
-- SHOW CORTEX SEARCH SERVICES で ACTIVE になるまで待つ

-- 3. 名寄せ実行・分析
-- experiments/company_matching/03_matching_analysis.sql を順番に実行
```

---

## 注意事項

- `SEARCH_PREVIEW` は SQL 実験用 API → 本番では Python / REST API を推奨
- `LATERAL FLATTEN` の展開結果は `:results` キー配下を指定すること
- `FR_CORTEX_ADMIN` ロールが `DEVELOPER_ROLE` に付与済みのため追加権限設定は不要
