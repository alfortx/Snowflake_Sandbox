-- ============================================================
-- 01_setup_tables.sql
-- 企業名名寄せ実験用テーブル作成 + サンプルデータ投入
-- ============================================================

USE ROLE DEVELOPER_ROLE;
USE WAREHOUSE SANDBOX_WH;
USE DATABASE SANDBOX_DB;
USE SCHEMA WORK;

-- ============================================================
-- テーブル1: SALES_INFO（売上情報）
-- 会計システムに多い「正式名称」寄りの表記
-- ★ COMPANY_NAME が Cortex Search Service のインデックス対象になる
-- ============================================================
CREATE OR REPLACE TABLE SALES_INFO (
    SALES_ID          NUMBER        AUTOINCREMENT PRIMARY KEY,
    COMPANY_NAME      VARCHAR(200)  NOT NULL,   -- ★インデックス対象
    COMPANY_CANONICAL VARCHAR(100),             -- 正規化社名（グループ集計用）
    AMOUNT            NUMBER(12, 0) NOT NULL,   -- 売上金額（円）
    SALES_DATE        DATE          NOT NULL,   -- 売上日
    PRODUCT           VARCHAR(100)              -- 商品・サービス名
);

INSERT INTO SALES_INFO (COMPANY_NAME, COMPANY_CANONICAL, AMOUNT, SALES_DATE, PRODUCT) VALUES
    -- トヨタグループ
    ('株式会社トヨタ自動車',          'トヨタ自動車', 5000000, '2025-01-15', 'ERP導入'),
    ('トヨタ自動車株式会社',          'トヨタ自動車', 3200000, '2025-02-20', 'クラウド移行'),
    ('株式会社デンソー',              'デンソー',     1800000, '2025-01-28', 'IoTシステム'),
    -- 三菱UFJグループ
    ('三菱UFJ銀行',                   '三菱UFJ',      4500000, '2025-01-10', 'セキュリティ監査'),
    ('三菱UFJフィナンシャルグループ',  '三菱UFJ',      2100000, '2025-03-05', 'データ基盤構築'),
    -- NTTグループ
    ('株式会社NTTデータ',             'NTTデータ',    6700000, '2025-02-01', 'システム開発'),
    ('NTTデータ株式会社',             'NTTデータ',     890000, '2025-02-15', '保守契約'),
    ('日本電信電話株式会社',          'NTT',          3300000, '2025-01-20', 'ネットワーク'),
    -- ソニーグループ
    ('ソニーグループ株式会社',        'ソニー',        2200000, '2025-03-10', 'AI開発'),
    ('株式会社ソニー',                'ソニー',        1500000, '2025-01-05', 'ハードウェア'),
    -- 楽天グループ
    ('楽天グループ株式会社',          '楽天',          980000, '2025-02-28', 'EC連携'),
    ('楽天株式会社',                  '楽天',          750000, '2025-03-15', 'API開発'),
    -- 外資系
    ('Amazon Japan合同会社',          'Amazon',       4200000, '2025-01-12', 'AWS導入'),
    ('Googleアジアパシフィック合同会社', 'Google',     3800000, '2025-02-10', 'GCP移行'),
    ('Microsoft Japan株式会社',       'Microsoft',    2900000, '2025-03-01', 'Azure構築');

-- ============================================================
-- テーブル2: SALES_ACTIVITY（営業活動情報）
-- SFA/CRM に多い「略称・通称・英語表記」の表記
-- ★ COMPANY_NAME を Search Service へのクエリ文字列として使う
-- ============================================================
CREATE OR REPLACE TABLE SALES_ACTIVITY (
    ACTIVITY_ID   NUMBER        AUTOINCREMENT PRIMARY KEY,
    COMPANY_NAME  VARCHAR(200)  NOT NULL,  -- ★クエリ文字列（表記揺れあり）
    ACTIVITY_TYPE VARCHAR(50)   NOT NULL,  -- 商談 / 電話 / メール / 訪問
    ACTIVITY_DATE DATE          NOT NULL,
    MEMO          VARCHAR(500)
);

INSERT INTO SALES_ACTIVITY (COMPANY_NAME, ACTIVITY_TYPE, ACTIVITY_DATE, MEMO) VALUES
    -- トヨタグループ（表記揺れ）
    ('トヨタ自動車(株)',              '商談',   '2025-01-14', '次期ERP更新の相談'),
    ('Toyota Motor Corporation',      'メール', '2025-02-18', 'Cloud migration follow-up'),
    ('デンソー',                       '訪問',   '2025-01-27', 'IoT追加提案'),
    -- 三菱UFJグループ（表記揺れ）
    ('三菱UFJ',                        '電話',   '2025-01-09', 'セキュリティ提案フォロー'),
    ('MUFG',                           'メール', '2025-03-04', 'Data infrastructure proposal'),
    ('三菱UFJフィナンシャル',           '商談',   '2025-02-20', '追加案件相談'),
    -- NTTグループ（表記揺れ）
    ('NTTデータ',                      '訪問',   '2025-01-31', '開発要件ヒアリング'),
    ('NTT Data',                       'メール', '2025-02-14', 'Maintenance contract renewal'),
    ('NTT',                            '電話',   '2025-01-19', '次期案件相談'),
    -- ソニーグループ（表記揺れ）
    ('ソニー',                         '商談',   '2025-03-09', 'AI PoC提案'),
    ('Sony',                           'メール', '2025-01-04', 'Hardware renewal'),
    -- 楽天グループ（表記揺れ）
    ('Rakuten',                        '訪問',   '2025-02-27', 'EC platform review'),
    ('楽天',                           '電話',   '2025-03-14', 'API仕様確認'),
    -- 外資系（表記揺れ）
    ('Amazon Web Services',            '商談',   '2025-01-11', 'AWS活用相談'),
    ('Google Cloud',                   'メール', '2025-02-09', 'GCP提案フォロー'),
    ('マイクロソフト',                  '訪問',   '2025-02-28', 'Azure導入支援'),
    -- 意図的な非マッチ（精度評価用）
    ('株式会社日立製作所',             '商談',   '2025-03-20', '新規案件'),
    ('富士通株式会社',                 '電話',   '2025-03-18', '見積もり依頼');

-- ============================================================
-- テーブル3: COMPANY_MATCH_RESULT（名寄せ結果テーブル）
-- 03_matching_analysis.sql の INSERT 先
-- ============================================================
CREATE OR REPLACE TABLE COMPANY_MATCH_RESULT (
    ACTIVITY_ID       NUMBER,                              -- SALES_ACTIVITY の ID
    ACTIVITY_COMPANY  VARCHAR(200),                       -- 元の表記揺れ社名
    MATCHED_SALES_ID  NUMBER,                             -- マッチした SALES_INFO の ID
    MATCHED_COMPANY   VARCHAR(200),                       -- SALES_INFO 側の社名
    RELEVANCE_SCORE   FLOAT,                              -- Search Service スコア（0〜1）
    MATCH_RANK        NUMBER,                             -- 1=ベストマッチ, 2=次点, ...
    MATCHED_AT        TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================
-- 確認クエリ
-- ============================================================
SELECT 'SALES_INFO'          AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM SALES_INFO
UNION ALL
SELECT 'SALES_ACTIVITY',                    COUNT(*)              FROM SALES_ACTIVITY
UNION ALL
SELECT 'COMPANY_MATCH_RESULT',              COUNT(*)              FROM COMPANY_MATCH_RESULT;
