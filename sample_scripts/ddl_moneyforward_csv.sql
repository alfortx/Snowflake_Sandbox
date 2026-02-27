-- =============================================================================
-- MoneyForward 家計簿データ DDL（Snowflake用）
-- Terraform管理: moneyforward.tf
-- =============================================================================

-- スキーマ作成（Terraformで管理するため参考用）
-- CREATE SCHEMA IF NOT EXISTS RAW_DB.BUDGET_BOOK;

-- ファイルフォーマット（CP932/Shift_JIS、ダブルクォート囲み）
-- CREATE OR REPLACE FILE FORMAT RAW_DB.BUDGET_BOOK.BUDGET_BOOK_CSV_FORMAT
--   TYPE = 'CSV'
--   ENCODING = 'SHIFT_JIS'
--   SKIP_HEADER = 1
--   FIELD_OPTIONALLY_ENCLOSED_BY = '"'
--   NULL_IF = ('');

-- 内部ステージ（URLなし = 内部ステージ）
-- CREATE OR REPLACE STAGE RAW_DB.BUDGET_BOOK.BUDGET_BOOK_STAGE;

-- =============================================================================
-- テーブル定義（Snowflake）
--   列名は英語化。セマンティックビューのsynonymで日本語対応
--   CSVの列順: 計算対象, 日付, 内容, 金額（円）, 保有金融機関, 大項目, 中項目, メモ, 振替, ID
-- =============================================================================
CREATE OR REPLACE TABLE RAW_DB.BUDGET_BOOK.TRANSACTIONS (
    ID                 VARCHAR(50)   NOT NULL  COMMENT 'マネーフォワード固有のトランザクションID',
    CALCULATION_TARGET NUMBER(1,0)             COMMENT '計算対象フラグ（1=対象, 0=対象外）',
    TRANSACTION_DATE   DATE                    COMMENT '取引日（CSVのYYYY/MM/DD文字列をDATEに変換）',
    DESCRIPTION        VARCHAR(500)            COMMENT '取引内容・店舗名等',
    AMOUNT             NUMBER(15,0)            COMMENT '金額（円）。負数=支出、正数=収入',
    INSTITUTION        VARCHAR(200)            COMMENT '保有金融機関・カード名',
    MAJOR_CATEGORY     VARCHAR(100)            COMMENT '大項目カテゴリ（食費・交通費等）',
    MINOR_CATEGORY     VARCHAR(100)            COMMENT '中項目カテゴリ（外食・コンビニ等）',
    MEMO               VARCHAR(500)            COMMENT 'メモ（ほぼ空）',
    TRANSFER_FLAG      NUMBER(1,0)             COMMENT '振替フラグ（1=振替取引, 0=通常取引）'
);

-- =============================================================================
-- データロード手順
-- =============================================================================

-- Step 1: ローカルCSVをステージへアップロード（SnowSQLまたはSnowflake CLI）
-- PUT file:///path/to/収入・支出詳細_*.csv @RAW_DB.BUDGET_BOOK.BUDGET_BOOK_STAGE
--   AUTO_COMPRESS = FALSE;

-- Step 2: ステージからテーブルへCOPY
-- CSVの列順に合わせて明示的に列マッピング + 日付変換
COPY INTO RAW_DB.BUDGET_BOOK.TRANSACTIONS (
    CALCULATION_TARGET,
    TRANSACTION_DATE,
    DESCRIPTION,
    AMOUNT,
    INSTITUTION,
    MAJOR_CATEGORY,
    MINOR_CATEGORY,
    MEMO,
    TRANSFER_FLAG,
    ID
)
FROM (
    SELECT
        $1::NUMBER(1,0),                    -- 計算対象
        TRY_TO_DATE($2, 'YYYY/MM/DD'),      -- 日付 → DATE型（例: 2025/11/30）
        $3::VARCHAR(500),                   -- 内容
        $4::NUMBER(15,0),                   -- 金額（円）
        $5::VARCHAR(200),                   -- 保有金融機関
        $6::VARCHAR(100),                   -- 大項目
        $7::VARCHAR(100),                   -- 中項目
        $8::VARCHAR(500),                   -- メモ
        $9::NUMBER(1,0),                    -- 振替
        $10::VARCHAR(50)                    -- ID
    FROM @RAW_DB.BUDGET_BOOK.BUDGET_BOOK_STAGE
)
FILE_FORMAT = (FORMAT_NAME = 'RAW_DB.BUDGET_BOOK.BUDGET_BOOK_CSV_FORMAT')
ON_ERROR = 'CONTINUE';

-- =============================================================================
-- 確認クエリ
-- =============================================================================

-- ロード件数と期間確認
SELECT
    COUNT(*)              AS total_rows,
    MIN(TRANSACTION_DATE) AS oldest_date,
    MAX(TRANSACTION_DATE) AS latest_date
FROM RAW_DB.BUDGET_BOOK.TRANSACTIONS;

-- カテゴリ別支出サマリー（計算対象・振替除外）
SELECT
    MAJOR_CATEGORY,
    SUM(ABS(AMOUNT)) AS total_spending
FROM RAW_DB.BUDGET_BOOK.TRANSACTIONS
WHERE AMOUNT < 0
  AND CALCULATION_TARGET = 1
  AND TRANSFER_FLAG = 0
GROUP BY MAJOR_CATEGORY
ORDER BY total_spending DESC;
