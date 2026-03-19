-- ============================================================
-- 03_matching_analysis.sql
-- 名寄せ実行 + 結果分析
--
-- 前提: 02_create_search_service.sql を実行済みで
--       COMPANY_NAME_SEARCH が ACTIVE であること
-- ============================================================

USE ROLE DEVELOPER_ROLE;
USE WAREHOUSE SANDBOX_WH;
USE DATABASE SANDBOX_DB;
USE SCHEMA WORK;

-- ============================================================
-- STEP 1: 個別クエリで動作確認
-- 1件ずつ手動でテストして、期待通りの候補が返るか確認する
-- ============================================================

-- テスト1: 日本語略称（株式会社トヨタ自動車 にマッチするか）
SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'CORTEX_DB.SEARCH_SERVICES.COMPANY_NAME_SEARCH',
        '{
            "query":   "トヨタ自動車(株)",
            "columns": ["SALES_ID", "COMPANY_NAME", "COMPANY_CANONICAL"],
            "limit":   3
        }'
    )
) AS RESULTS;

-- テスト2: 英語表記（株式会社NTTデータ にマッチするか）
SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'CORTEX_DB.SEARCH_SERVICES.COMPANY_NAME_SEARCH',
        '{
            "query":   "NTT Data",
            "columns": ["SALES_ID", "COMPANY_NAME", "COMPANY_CANONICAL"],
            "limit":   3
        }'
    )
) AS RESULTS;

-- テスト3: 非マッチ確認（日立製作所は SALES_INFO にない）
SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'CORTEX_DB.SEARCH_SERVICES.COMPANY_NAME_SEARCH',
        '{
            "query":   "株式会社日立製作所",
            "columns": ["SALES_ID", "COMPANY_NAME"],
            "limit":   3
        }'
    )
) AS RESULTS;

-- ============================================================
-- STEP 2: SALES_ACTIVITY 全件を一括クエリ
--         → COMPANY_MATCH_RESULT テーブルへ保存
--
-- [注意] SEARCH_PREVIEW の第2引数はコンパイル時定数でなければならない。
-- 列参照（sa.COMPANY_NAME）を直接渡すとエラーになるため、
-- JavaScript ストアドプロシージャで1行ずつ動的SQLを構築して実行する。
-- ============================================================

-- STEP 2-1: ストアドプロシージャの作成
CREATE OR REPLACE PROCEDURE SANDBOX_DB.WORK.MATCH_ALL_COMPANIES()
RETURNS VARCHAR
LANGUAGE JAVASCRIPT
AS
$$
    // COMPANY_MATCH_RESULT をリセット
    snowflake.execute({ sqlText: "TRUNCATE TABLE SANDBOX_DB.WORK.COMPANY_MATCH_RESULT" });

    // SALES_ACTIVITY を全件取得
    var rows = snowflake.execute({
        sqlText: "SELECT ACTIVITY_ID, COMPANY_NAME FROM SANDBOX_DB.WORK.SALES_ACTIVITY ORDER BY ACTIVITY_ID"
    });

    var count = 0;
    while (rows.next()) {
        var actId   = rows.getColumnValue(1);
        var company = rows.getColumnValue(2);

        // JSON を文字列として組み立て（SQL に埋め込む前にシングルクォートをエスケープ）
        var queryJson = JSON.stringify({
            query:   company,
            columns: ["SALES_ID", "COMPANY_NAME"],
            limit:   3
        }).replace(/'/g, "''");

        var safeCompany = company.replace(/'/g, "''");

        // SEARCH_PREVIEW の引数が文字列リテラルになるよう動的 SQL を構築
        // RELEVANCE_SCORE: @scores.cosine_similarity を使用
        //   （_relevance_score は SQL パスでは取得不可のため）
        // MATCH_RANK: SEARCH_PREVIEW の返却順（r.index）がそのまま関連度順
        var sql = `
            INSERT INTO SANDBOX_DB.WORK.COMPANY_MATCH_RESULT
                (ACTIVITY_ID, ACTIVITY_COMPANY, MATCHED_SALES_ID, MATCHED_COMPANY, RELEVANCE_SCORE, MATCH_RANK)
            SELECT
                ${actId}           AS ACTIVITY_ID,
                '${safeCompany}'   AS ACTIVITY_COMPANY,
                r.value:SALES_ID::NUMBER                            AS MATCHED_SALES_ID,
                r.value:COMPANY_NAME::TEXT                          AS MATCHED_COMPANY,
                r.value:"@scores":"cosine_similarity"::FLOAT        AS RELEVANCE_SCORE,
                r.index + 1                                         AS MATCH_RANK
            FROM LATERAL FLATTEN(
                INPUT => PARSE_JSON(
                    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
                        'CORTEX_DB.SEARCH_SERVICES.COMPANY_NAME_SEARCH',
                        '${queryJson}'
                    )
                ):results
            ) r
        `;

        snowflake.execute({ sqlText: sql });
        count++;
    }

    return 'Processed ' + count + ' companies.';
$$;

-- STEP 2-2: プロシージャを実行
CALL SANDBOX_DB.WORK.MATCH_ALL_COMPANIES();

-- 件数確認
SELECT COUNT(*) AS TOTAL_ROWS FROM COMPANY_MATCH_RESULT;

-- ============================================================
-- STEP 3: 分析クエリ
-- ============================================================

-- 3-1. ベストマッチ一覧（MATCH_RANK = 1）
--      表記揺れ社名が何にマッチしたか一覧で確認
SELECT
    ACTIVITY_COMPANY                   AS "営業側社名",
    MATCHED_COMPANY                    AS "売上側社名",
    ROUND(RELEVANCE_SCORE, 4)          AS "スコア"
FROM COMPANY_MATCH_RESULT
WHERE MATCH_RANK = 1
ORDER BY RELEVANCE_SCORE DESC;

-- 3-2. スコア分布（信頼度の目安）
--      スコアが高い = 確実なマッチ、低い = 怪しいマッチ
SELECT
    CASE
        WHEN RELEVANCE_SCORE >= 0.9 THEN '0.9以上（確実）'
        WHEN RELEVANCE_SCORE >= 0.7 THEN '0.7〜0.9（高信頼）'
        WHEN RELEVANCE_SCORE >= 0.5 THEN '0.5〜0.7（要確認）'
        ELSE '0.5未満（低信頼）'
    END AS SCORE_RANGE,
    COUNT(*) AS CNT
FROM COMPANY_MATCH_RESULT
WHERE MATCH_RANK = 1
GROUP BY SCORE_RANGE
ORDER BY SCORE_RANGE;

-- 3-3. グループ別 売上合計 × 商談件数 クロス集計
--      名寄せ結果を使って2テーブルの情報を紐付けた分析
SELECT
    si.COMPANY_CANONICAL                AS "企業グループ",
    SUM(si.AMOUNT)                      AS "売上合計",
    COUNT(DISTINCT sa.ACTIVITY_ID)      AS "営業活動件数",
    LISTAGG(DISTINCT sa.ACTIVITY_TYPE, ' / ')
        WITHIN GROUP (ORDER BY sa.ACTIVITY_TYPE) AS "活動タイプ"
FROM COMPANY_MATCH_RESULT mr
JOIN SALES_ACTIVITY sa ON sa.ACTIVITY_ID = mr.ACTIVITY_ID
JOIN SALES_INFO     si ON si.SALES_ID    = mr.MATCHED_SALES_ID
WHERE mr.MATCH_RANK = 1
GROUP BY si.COMPANY_CANONICAL
ORDER BY "売上合計" DESC;

-- 3-4. 非マッチ確認（日立・富士通のスコアが低いことを確認）
--      これらは SALES_INFO にないので、スコアが低くなるはず
SELECT
    ACTIVITY_COMPANY,
    MATCHED_COMPANY,
    ROUND(RELEVANCE_SCORE, 4) AS RELEVANCE_SCORE,
    MATCH_RANK
FROM COMPANY_MATCH_RESULT
WHERE ACTIVITY_COMPANY IN ('株式会社日立製作所', '富士通株式会社')
ORDER BY ACTIVITY_COMPANY, MATCH_RANK;
