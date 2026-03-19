-- ============================================================
-- 02_create_search_service.sql
-- Cortex Search Service の作成（インデックス化）
--
-- [仕組み]
-- CREATE 時に COMPANY_NAME 列が自動でベクトル化され、
-- 内部インデックスに保存される（ユーザーには見えない）。
-- SALES_INFO に変更があれば TARGET_LAG 内に自動差分更新される。
-- ============================================================

USE ROLE DEVELOPER_ROLE;
USE WAREHOUSE SANDBOX_WH;

-- CORTEX_DB.SEARCH_SERVICES スキーマに作成（既存スキーマを活用）
CREATE OR REPLACE CORTEX SEARCH SERVICE CORTEX_DB.SEARCH_SERVICES.COMPANY_NAME_SEARCH
    ON COMPANY_NAME                                            -- ★ここがベクトルインデックスになる列
    ATTRIBUTES SALES_ID, COMPANY_CANONICAL, AMOUNT, SALES_DATE -- フィルタや返却値として使える列
    WAREHOUSE  = SANDBOX_WH
    TARGET_LAG = '1 hour'                                      -- SALES_INFO 更新時の反映遅延
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'          -- budget_book と同じモデル
    COMMENT = '企業名名寄せ実験用 Search Service（SALES_INFO の社名を索引化）'
AS (
    SELECT SALES_ID, COMPANY_NAME, COMPANY_CANONICAL, AMOUNT, SALES_DATE
    FROM SANDBOX_DB.WORK.SALES_INFO
);

-- ============================================================
-- 状態確認（ACTIVE になるまで数分かかる場合がある）
-- STATUS が ACTIVE になったら 03_matching_analysis.sql へ進む
-- ============================================================
SHOW CORTEX SEARCH SERVICES LIKE 'COMPANY_NAME_SEARCH' IN SCHEMA CORTEX_DB.SEARCH_SERVICES;
