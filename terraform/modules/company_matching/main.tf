# =============================================================================
# company_matching モジュール: 企業名名寄せ実験用実データ
#
# 作成するリソース:
#   RAW_DB.COMPANY_MATCHING スキーマ
#   ファイルフォーマット × 3（EDINET / JPX / 国税庁）
#   S3ステージ × 3（各データセット専用プレフィックス）
#   外部テーブル × 3（S3直接参照、COPY INTO不要）
# =============================================================================

# -----------------------------------------------------------------------------
# スキーマ
# -----------------------------------------------------------------------------

resource "snowflake_schema" "company_matching" {
  provider = snowflake.sysadmin

  database = var.raw_db_name
  name     = var.company_matching_schema_name
  comment  = "企業名名寄せ実験用 Raw データスキーマ（EDINET / JPX / 国税庁）"
}

# -----------------------------------------------------------------------------
# ファイルフォーマット
# -----------------------------------------------------------------------------

resource "snowflake_file_format" "edinet_csv" {
  provider = snowflake.sysadmin

  database                     = var.raw_db_name
  schema                       = snowflake_schema.company_matching.name
  name                         = "EDINET_CSV_FORMAT"
  format_type                  = "CSV"
  encoding                     = "SHIFT_JIS"
  skip_header                  = 2 # 1行目=ダウンロード日メタ情報, 2行目=ヘッダー
  field_optionally_enclosed_by = "\""
  null_if                      = ["", "NULL"]
  comment                      = "EDINETコードリスト用（CP932/SHIFT_JIS, skip_header=2）"

  depends_on = [snowflake_schema.company_matching]
}

resource "snowflake_file_format" "jpx_csv" {
  provider = snowflake.sysadmin

  database    = var.raw_db_name
  schema      = snowflake_schema.company_matching.name
  name        = "JPX_CSV_FORMAT"
  format_type = "CSV"
  encoding    = "UTF-8"
  skip_header = 1
  null_if     = ["-", "", "NULL"]
  comment     = "JPX上場銘柄一覧用（XLS→UTF-8 CSV変換後, skip_header=1）"

  depends_on = [snowflake_schema.company_matching]
}

resource "snowflake_file_format" "nta_csv" {
  provider = snowflake.sysadmin

  database                     = var.raw_db_name
  schema                       = snowflake_schema.company_matching.name
  name                         = "NTA_CSV_FORMAT"
  format_type                  = "CSV"
  encoding                     = "SHIFT_JIS"
  skip_header                  = 0 # ヘッダー行なし
  field_optionally_enclosed_by = "\""
  null_if                      = ["", "NULL"]
  comment                      = "国税庁法人番号公表データ用（SHIFT_JIS, ヘッダーなし）"

  depends_on = [snowflake_schema.company_matching]
}

# -----------------------------------------------------------------------------
# S3ステージ（既存 SANDBOX_S3_INTEGRATION を使用）
# -----------------------------------------------------------------------------

resource "snowflake_stage" "edinet_s3_stage" {
  provider = snowflake.sysadmin

  database            = var.raw_db_name
  schema              = snowflake_schema.company_matching.name
  name                = "EDINET_S3_STAGE"
  url                 = "s3://${var.s3_bucket_name}/company-matching/edinet/"
  storage_integration = var.storage_integration_name
  comment             = "EDINETコードリスト CSV格納先"

  depends_on = [snowflake_schema.company_matching]

  lifecycle { ignore_changes = [directory] }
}

resource "snowflake_stage" "jpx_s3_stage" {
  provider = snowflake.sysadmin

  database            = var.raw_db_name
  schema              = snowflake_schema.company_matching.name
  name                = "JPX_S3_STAGE"
  url                 = "s3://${var.s3_bucket_name}/company-matching/jpx/"
  storage_integration = var.storage_integration_name
  comment             = "JPX上場銘柄一覧 CSV格納先（XLS→CSV変換後）"

  depends_on = [snowflake_schema.company_matching]

  lifecycle { ignore_changes = [directory] }
}

resource "snowflake_stage" "nta_s3_stage" {
  provider = snowflake.sysadmin

  database            = var.raw_db_name
  schema              = snowflake_schema.company_matching.name
  name                = "NTA_S3_STAGE"
  url                 = "s3://${var.s3_bucket_name}/company-matching/nta/"
  storage_integration = var.storage_integration_name
  comment             = "国税庁法人番号公表データ CSV格納先"

  depends_on = [snowflake_schema.company_matching]

  lifecycle { ignore_changes = [directory] }
}

# -----------------------------------------------------------------------------
# 外部テーブル: EDINET（13列）
# -----------------------------------------------------------------------------

resource "snowflake_external_table" "ext_edinet_companies" {
  provider = snowflake.sysadmin

  database    = var.raw_db_name
  schema      = snowflake_schema.company_matching.name
  name        = var.ext_edinet_table_name
  location    = "@${var.raw_db_name}.${snowflake_schema.company_matching.name}.${snowflake_stage.edinet_s3_stage.name}/"
  file_format = "FORMAT_NAME = ${var.raw_db_name}.${snowflake_schema.company_matching.name}.${snowflake_file_format.edinet_csv.name}"
  comment     = "EDINETコードリスト外部テーブル（提出者名JA/EN/ヨミ・法人番号・業種）"

  column {
    name = "EDINET_CODE"
    type = "VARCHAR(10)"
    as   = "GET(VALUE, 'c1')::VARCHAR"
  }
  column {
    name = "SUBMITTER_TYPE"
    type = "VARCHAR(100)"
    as   = "GET(VALUE, 'c2')::VARCHAR"
  }
  column {
    name = "LISTING_STATUS"
    type = "VARCHAR(20)"
    as   = "GET(VALUE, 'c3')::VARCHAR"
  }
  column {
    name = "CONSOLIDATED"
    type = "VARCHAR(5)"
    as   = "GET(VALUE, 'c4')::VARCHAR"
  }
  column {
    name = "CAPITAL"
    type = "NUMBER"
    as   = "TRY_TO_NUMBER(GET(VALUE, 'c5')::VARCHAR)"
  }
  column {
    name = "FISCAL_YEAR_END"
    type = "VARCHAR(10)"
    as   = "GET(VALUE, 'c6')::VARCHAR"
  }
  column {
    name = "COMPANY_NAME_JA"
    type = "VARCHAR(300)"
    as   = "GET(VALUE, 'c7')::VARCHAR"
  }
  column {
    name = "COMPANY_NAME_EN"
    type = "VARCHAR(300)"
    as   = "GET(VALUE, 'c8')::VARCHAR"
  }
  column {
    name = "COMPANY_NAME_KANA"
    type = "VARCHAR(300)"
    as   = "GET(VALUE, 'c9')::VARCHAR"
  }
  column {
    name = "ADDRESS"
    type = "VARCHAR(500)"
    as   = "GET(VALUE, 'c10')::VARCHAR"
  }
  column {
    name = "INDUSTRY"
    type = "VARCHAR(100)"
    as   = "GET(VALUE, 'c11')::VARCHAR"
  }
  column {
    name = "SECURITIES_CODE"
    type = "VARCHAR(10)"
    as   = "GET(VALUE, 'c12')::VARCHAR"
  }
  column {
    name = "CORPORATE_NUMBER"
    type = "VARCHAR(20)"
    as   = "GET(VALUE, 'c13')::VARCHAR"
  }

  depends_on = [snowflake_stage.edinet_s3_stage, snowflake_file_format.edinet_csv]
}

# -----------------------------------------------------------------------------
# 外部テーブル: JPX（10列）
# -----------------------------------------------------------------------------

resource "snowflake_external_table" "ext_jpx_companies" {
  provider = snowflake.sysadmin

  database    = var.raw_db_name
  schema      = snowflake_schema.company_matching.name
  name        = var.ext_jpx_table_name
  location    = "@${var.raw_db_name}.${snowflake_schema.company_matching.name}.${snowflake_stage.jpx_s3_stage.name}/"
  file_format = "FORMAT_NAME = ${var.raw_db_name}.${snowflake_schema.company_matching.name}.${snowflake_file_format.jpx_csv.name}"
  comment     = "JPX東証上場銘柄一覧外部テーブル（銘柄名・市場・業種・規模）"

  column {
    name = "LISTED_DATE"
    type = "VARCHAR(10)"
    as   = "GET(VALUE, 'c1')::VARCHAR"
  }
  column {
    name = "SECURITIES_CODE"
    type = "VARCHAR(10)"
    as   = "GET(VALUE, 'c2')::VARCHAR"
  }
  column {
    name = "COMPANY_NAME"
    type = "VARCHAR(300)"
    as   = "GET(VALUE, 'c3')::VARCHAR"
  }
  column {
    name = "MARKET"
    type = "VARCHAR(100)"
    as   = "GET(VALUE, 'c4')::VARCHAR"
  }
  column {
    name = "INDUSTRY_33_CODE"
    type = "VARCHAR(10)"
    as   = "GET(VALUE, 'c5')::VARCHAR"
  }
  column {
    name = "INDUSTRY_33"
    type = "VARCHAR(100)"
    as   = "GET(VALUE, 'c6')::VARCHAR"
  }
  column {
    name = "INDUSTRY_17_CODE"
    type = "VARCHAR(10)"
    as   = "GET(VALUE, 'c7')::VARCHAR"
  }
  column {
    name = "INDUSTRY_17"
    type = "VARCHAR(100)"
    as   = "GET(VALUE, 'c8')::VARCHAR"
  }
  column {
    name = "SIZE_CODE"
    type = "VARCHAR(10)"
    as   = "GET(VALUE, 'c9')::VARCHAR"
  }
  column {
    name = "SIZE_NAME"
    type = "VARCHAR(100)"
    as   = "GET(VALUE, 'c10')::VARCHAR"
  }

  depends_on = [snowflake_stage.jpx_s3_stage, snowflake_file_format.jpx_csv]
}

# -----------------------------------------------------------------------------
# 外部テーブル: 国税庁（30列）
# -----------------------------------------------------------------------------

resource "snowflake_external_table" "ext_nta_companies" {
  provider = snowflake.sysadmin

  database    = var.raw_db_name
  schema      = snowflake_schema.company_matching.name
  name        = var.ext_nta_table_name
  location    = "@${var.raw_db_name}.${snowflake_schema.company_matching.name}.${snowflake_stage.nta_s3_stage.name}/"
  file_format = "FORMAT_NAME = ${var.raw_db_name}.${snowflake_schema.company_matching.name}.${snowflake_file_format.nta_csv.name}"
  comment     = "国税庁法人番号公表データ外部テーブル（法人名・住所・法人番号）"

  column {
    name = "SEQ_NO"
    type = "NUMBER"
    as   = "TRY_TO_NUMBER(GET(VALUE, 'c1')::VARCHAR)"
  }
  column {
    name = "CORPORATE_NUMBER"
    type = "VARCHAR(20)"
    as   = "GET(VALUE, 'c2')::VARCHAR"
  }
  column {
    name = "PROCESS"
    type = "VARCHAR(5)"
    as   = "GET(VALUE, 'c3')::VARCHAR"
  }
  column {
    name = "CORRECT"
    type = "VARCHAR(5)"
    as   = "GET(VALUE, 'c4')::VARCHAR"
  }
  column {
    name = "UPDATE_DATE"
    type = "VARCHAR(20)"
    as   = "GET(VALUE, 'c5')::VARCHAR"
  }
  column {
    name = "CHANGE_DATE"
    type = "VARCHAR(20)"
    as   = "GET(VALUE, 'c6')::VARCHAR"
  }
  column {
    name = "COMPANY_NAME"
    type = "VARCHAR(300)"
    as   = "GET(VALUE, 'c7')::VARCHAR"
  }
  column {
    name = "COMPANY_NAME_KANA"
    type = "VARCHAR(300)"
    as   = "GET(VALUE, 'c8')::VARCHAR"
  }
  column {
    name = "COMPANY_TYPE"
    type = "VARCHAR(10)"
    as   = "GET(VALUE, 'c9')::VARCHAR"
  }
  column {
    name = "PREFECTURE"
    type = "VARCHAR(50)"
    as   = "GET(VALUE, 'c10')::VARCHAR"
  }
  column {
    name = "MUNICIPALITY"
    type = "VARCHAR(100)"
    as   = "GET(VALUE, 'c11')::VARCHAR"
  }
  column {
    name = "ADDRESS1"
    type = "VARCHAR(300)"
    as   = "GET(VALUE, 'c12')::VARCHAR"
  }
  column {
    name = "ADDRESS2"
    type = "VARCHAR(300)"
    as   = "GET(VALUE, 'c13')::VARCHAR"
  }
  column {
    name = "PREF_CODE"
    type = "VARCHAR(5)"
    as   = "GET(VALUE, 'c14')::VARCHAR"
  }
  column {
    name = "CITY_CODE"
    type = "VARCHAR(10)"
    as   = "GET(VALUE, 'c15')::VARCHAR"
  }
  column {
    name = "POSTAL_CODE"
    type = "VARCHAR(10)"
    as   = "GET(VALUE, 'c16')::VARCHAR"
  }
  column {
    name = "COL17"
    type = "VARCHAR(100)"
    as   = "GET(VALUE, 'c17')::VARCHAR"
  }
  column {
    name = "COL18"
    type = "VARCHAR(100)"
    as   = "GET(VALUE, 'c18')::VARCHAR"
  }
  column {
    name = "COL19"
    type = "VARCHAR(100)"
    as   = "GET(VALUE, 'c19')::VARCHAR"
  }
  column {
    name = "CLOSED_DATE"
    type = "VARCHAR(20)"
    as   = "GET(VALUE, 'c20')::VARCHAR"
  }
  column {
    name = "CLOSED_REASON"
    type = "VARCHAR(5)"
    as   = "GET(VALUE, 'c21')::VARCHAR"
  }
  column {
    name = "COL22"
    type = "VARCHAR(100)"
    as   = "GET(VALUE, 'c22')::VARCHAR"
  }
  column {
    name = "REGISTRY_CLOSED_DATE"
    type = "VARCHAR(20)"
    as   = "GET(VALUE, 'c23')::VARCHAR"
  }
  column {
    name = "REGISTRY_CLOSED_REASON"
    type = "VARCHAR(5)"
    as   = "GET(VALUE, 'c24')::VARCHAR"
  }
  column {
    name = "COMPANY_NAME_EN"
    type = "VARCHAR(300)"
    as   = "GET(VALUE, 'c25')::VARCHAR"
  }
  column {
    name = "PREFECTURE_EN"
    type = "VARCHAR(100)"
    as   = "GET(VALUE, 'c26')::VARCHAR"
  }
  column {
    name = "ADDRESS_EN"
    type = "VARCHAR(500)"
    as   = "GET(VALUE, 'c27')::VARCHAR"
  }
  column {
    name = "COL28"
    type = "VARCHAR(100)"
    as   = "GET(VALUE, 'c28')::VARCHAR"
  }
  column {
    name = "COMPANY_NAME_FURIGANA"
    type = "VARCHAR(300)"
    as   = "GET(VALUE, 'c29')::VARCHAR"
  }
  column {
    name = "CHANGE_REASON"
    type = "VARCHAR(5)"
    as   = "GET(VALUE, 'c30')::VARCHAR"
  }

  depends_on = [snowflake_stage.nta_s3_stage, snowflake_file_format.nta_csv]
}
