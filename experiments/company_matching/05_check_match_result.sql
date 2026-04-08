-- =============================================================================
-- STEP 4 確認用: EDINET_JPX_MATCH_RESULT の SELECT 部分（10件サンプル）
-- 全件実行（4,440件）の前に LATERAL FLATTEN + SEARCH_PREVIEW の動作確認
-- =============================================================================

-- Search Service が ACTIVE か確認してから実行すること
-- SHOW CORTEX SEARCH SERVICES IN DATABASE CORTEX_DB;

SELECT
    j.SECURITIES_CODE                         AS JPX_SECURITIES_CODE,
    j.COMPANY_NAME                            AS JPX_NAME,
    f.value:COMPANY_NAME_JA::VARCHAR          AS MATCHED_EDINET_NAME,
    f.value:EDINET_CODE::VARCHAR              AS MATCHED_EDINET_CODE,
    f.value:SECURITIES_CODE::VARCHAR          AS MATCHED_SECURITIES_CODE,
    f.value:score::FLOAT                      AS RELEVANCE_SCORE,
    ROW_NUMBER() OVER (
        PARTITION BY j.SECURITIES_CODE
        ORDER BY f.value:score::FLOAT DESC
    )                                         AS MATCH_RANK
FROM (
    -- サンプル10件に絞って動作確認
    SELECT SECURITIES_CODE, COMPANY_NAME
    FROM RAW_DB.COMPANY_MATCHING.MV_JPX_COMPANIES
    WHERE SECURITIES_CODE IS NOT NULL AND SECURITIES_CODE != '-'
    LIMIT 10
) j,
LATERAL FLATTEN(
    INPUT => PARSE_JSON(
        SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
            'CORTEX_DB.SEARCH_SERVICES.EDINET_COMPANY_SEARCH',
            OBJECT_CONSTRUCT(
                'query',   j.COMPANY_NAME,
                'columns', ARRAY_CONSTRUCT('COMPANY_NAME_JA', 'EDINET_CODE', 'SECURITIES_CODE'),
                'limit',   3
            )::VARCHAR
        )
    ):results
) f
ORDER BY JPX_SECURITIES_CODE, MATCH_RANK;
