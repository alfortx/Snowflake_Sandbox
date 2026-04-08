# =============================================================================
# company_matching マテリアライズドビュー
#
# 外部テーブル（S3直接参照）はクエリのたびにファイルスキャンが発生するため、
# マテビューでキャッシュすることでクエリパフォーマンスを改善する。
#
# 対象:
#   MV_EDINET_COMPANIES  : EDINETコードリスト（13列）
#   MV_JPX_COMPANIES     : JPX上場銘柄一覧（10列）
#   MV_NTA_COMPANIES     : 国税庁法人番号公表データ（25列 / COL系不明列を除外）
# =============================================================================

locals {
  schema_ref = "${var.raw_db_name}.${snowflake_schema.company_matching.name}"
}

# -----------------------------------------------------------------------------
# マテビュー: EDINET（13列）
# -----------------------------------------------------------------------------

resource "snowflake_materialized_view" "mv_edinet_companies" {
  provider  = snowflake.sysadmin
  database  = var.raw_db_name
  schema    = snowflake_schema.company_matching.name
  name      = "MV_EDINET_COMPANIES"
  warehouse = var.sandbox_wh_name
  comment   = "EDINETコードリスト外部テーブルのマテビュー（クエリパフォーマンス改善用）"

  statement = <<-SQL
    SELECT
      EDINET_CODE,
      SUBMITTER_TYPE,
      LISTING_STATUS,
      CONSOLIDATED,
      CAPITAL,
      FISCAL_YEAR_END,
      COMPANY_NAME_JA,
      COMPANY_NAME_EN,
      COMPANY_NAME_KANA,
      ADDRESS,
      INDUSTRY,
      SECURITIES_CODE,
      CORPORATE_NUMBER
    FROM ${local.schema_ref}.${var.ext_edinet_table_name}
  SQL

  depends_on = [snowflake_external_table.ext_edinet_companies]
}

# -----------------------------------------------------------------------------
# マテビュー: JPX（10列）
# -----------------------------------------------------------------------------

resource "snowflake_materialized_view" "mv_jpx_companies" {
  provider  = snowflake.sysadmin
  database  = var.raw_db_name
  schema    = snowflake_schema.company_matching.name
  name      = "MV_JPX_COMPANIES"
  warehouse = var.sandbox_wh_name
  comment   = "JPX上場銘柄一覧外部テーブルのマテビュー（クエリパフォーマンス改善用）"

  statement = <<-SQL
    SELECT
      LISTED_DATE,
      SECURITIES_CODE,
      COMPANY_NAME,
      MARKET,
      INDUSTRY_33_CODE,
      INDUSTRY_33,
      INDUSTRY_17_CODE,
      INDUSTRY_17,
      SIZE_CODE,
      SIZE_NAME
    FROM ${local.schema_ref}.${var.ext_jpx_table_name}
  SQL

  depends_on = [snowflake_external_table.ext_jpx_companies]
}

# -----------------------------------------------------------------------------
# マテビュー: 国税庁（25列 / 用途不明のCOL系列を除外）
# -----------------------------------------------------------------------------

resource "snowflake_materialized_view" "mv_nta_companies" {
  provider  = snowflake.sysadmin
  database  = var.raw_db_name
  schema    = snowflake_schema.company_matching.name
  name      = "MV_NTA_COMPANIES"
  warehouse = var.sandbox_wh_name
  comment   = "国税庁法人番号公表データ外部テーブルのマテビュー（COL系不明列除外 / クエリパフォーマンス改善用）"

  statement = <<-SQL
    SELECT
      SEQ_NO,
      CORPORATE_NUMBER,
      PROCESS,
      CORRECT,
      UPDATE_DATE,
      CHANGE_DATE,
      COMPANY_NAME,
      COMPANY_NAME_KANA,
      COMPANY_NAME_FURIGANA,
      COMPANY_NAME_EN,
      COMPANY_TYPE,
      PREFECTURE,
      PREFECTURE_EN,
      MUNICIPALITY,
      ADDRESS1,
      ADDRESS2,
      ADDRESS_EN,
      PREF_CODE,
      CITY_CODE,
      POSTAL_CODE,
      CLOSED_DATE,
      CLOSED_REASON,
      REGISTRY_CLOSED_DATE,
      REGISTRY_CLOSED_REASON,
      CHANGE_REASON
    FROM ${local.schema_ref}.${var.ext_nta_table_name}
  SQL

  depends_on = [snowflake_external_table.ext_nta_companies]
}
