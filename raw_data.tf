# =============================================================================
# RAW_DB データベースの作成
# COVID-19 Data Lake からのRawデータ格納用
# SYSADMIN: Database, Schema, Warehouseなどのオブジェクト管理
# =============================================================================
resource "snowflake_database" "raw_db" {
  provider = snowflake.sysadmin

  name    = "RAW_DB"
  comment = "COVID-19 Data Lake からのRawデータ格納用データベース"
}

# =============================================================================
# COVID19 スキーマの作成
# SYSADMIN: Database配下のSchemaを作成
# =============================================================================
resource "snowflake_schema" "covid19" {
  provider = snowflake.sysadmin

  database = snowflake_database.raw_db.name
  name     = "COVID19"
  comment  = "JHU COVID-19 時系列データ用スキーマ"
}

# =============================================================================
# CSV ファイルフォーマットの作成
# SYSADMIN: ファイルフォーマットの作成（preview機能）
# =============================================================================
resource "snowflake_file_format" "csv_format" {
  provider = snowflake.sysadmin

  database                     = snowflake_database.raw_db.name
  schema                       = snowflake_schema.covid19.name
  name                         = "CSV_FORMAT"
  format_type                  = "CSV"
  skip_header                  = 1
  field_optionally_enclosed_by = "\""
  null_if                      = ["", "NA", "NULL"]
  comment                      = "CSV format for COVID-19 Data Lake (JHU timeseries)"
}

# =============================================================================
# 外部ステージの作成（公開S3バケット・認証不要）
# SYSADMIN: 外部ステージの作成（preview機能）
# =============================================================================
resource "snowflake_stage" "covid19_s3_stage" {
  provider = snowflake.sysadmin

  database    = snowflake_database.raw_db.name
  schema      = snowflake_schema.covid19.name
  name        = "COVID19_S3_STAGE"
  url         = "s3://covid19-lake/enigma-jhu-timeseries/csv/"
  file_format = "FORMAT_NAME = RAW_DB.COVID19.CSV_FORMAT"
  comment     = "Public S3 stage for JHU COVID-19 timeseries (no credentials required)"

  depends_on = [snowflake_file_format.csv_format]

  # directory は ALTER STAGE で有効化済み（snowflake_execute.covid19_s3_stage_directory）
  # Terraform定義に含めると外部テーブルが存在するため DROP できず失敗するため ignore_changes で管理
  lifecycle {
    ignore_changes = [directory]
  }
}

# 外部テーブルが存在するためDROPできないので ALTER STAGE でディレクトリテーブルを有効化
resource "snowflake_execute" "covid19_s3_stage_directory" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_stage.covid19_s3_stage]

  execute = "ALTER STAGE \"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_stage.covid19_s3_stage.name}\" SET DIRECTORY = (ENABLE = TRUE)"
  revert  = "ALTER STAGE \"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_stage.covid19_s3_stage.name}\" SET DIRECTORY = (ENABLE = FALSE)"
}

# =============================================================================
# COVID-19 World Testing 外部ステージの作成（公開S3バケット・認証不要）
# SYSADMIN: 外部ステージの作成（preview機能）
# =============================================================================
resource "snowflake_stage" "covid19_world_testing_stage" {
  provider = snowflake.sysadmin

  database    = snowflake_database.raw_db.name
  schema      = snowflake_schema.covid19.name
  name        = "COVID19_WORLD_TESTING_STAGE"
  url         = "s3://covid19-lake/rearc-covid-19-world-cases-deaths-testing/csv/"
  file_format = "FORMAT_NAME = RAW_DB.COVID19.CSV_FORMAT"
  comment     = "COVID-19 world cases, deaths, testing, vaccination data (JHUと結合可能)"

  depends_on = [snowflake_file_format.csv_format]

  # directory は ALTER STAGE で有効化済み（snowflake_execute.covid19_world_testing_stage_directory）
  # Terraform定義に含めると外部テーブルが存在するため DROP できず失敗するため ignore_changes で管理
  lifecycle {
    ignore_changes = [directory]
  }
}

# 外部テーブルが存在するためDROPできないので ALTER STAGE でディレクトリテーブルを有効化
resource "snowflake_execute" "covid19_world_testing_stage_directory" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_stage.covid19_world_testing_stage]

  execute = "ALTER STAGE \"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_stage.covid19_world_testing_stage.name}\" SET DIRECTORY = (ENABLE = TRUE)"
  revert  = "ALTER STAGE \"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_stage.covid19_world_testing_stage.name}\" SET DIRECTORY = (ENABLE = FALSE)"
}

# =============================================================================
# 外部テーブルの作成（S3を直接参照・COPY不要）
# SYSADMIN: 外部テーブルの作成（preview機能）
# =============================================================================
resource "snowflake_external_table" "ext_jhu_timeseries" {
  provider = snowflake.sysadmin

  database = snowflake_database.raw_db.name
  schema   = snowflake_schema.covid19.name
  name     = "EXT_JHU_TIMESERIES"
  comment  = "JHU COVID-19 時系列データ"

  location    = "@${snowflake_database.raw_db.name}.${snowflake_schema.covid19.name}.${snowflake_stage.covid19_s3_stage.name}/"
  file_format = "FORMAT_NAME = ${snowflake_database.raw_db.name}.${snowflake_schema.covid19.name}.${snowflake_file_format.csv_format.name}"

  column {
    name = "UID"
    type = "NUMBER(38,0)"
    as   = "TRY_TO_NUMBER(GET(VALUE, 'c1')::VARCHAR)"
  }

  column {
    name = "FIPS"
    type = "NUMBER(38,0)"
    as   = "TRY_TO_NUMBER(GET(VALUE, 'c2')::VARCHAR)"
  }

  column {
    name = "ISO2"
    type = "VARCHAR(2)"
    as   = "GET(VALUE, 'c3')::VARCHAR"
  }

  column {
    name = "ISO3"
    type = "VARCHAR(3)"
    as   = "GET(VALUE, 'c4')::VARCHAR"
  }

  column {
    name = "CODE3"
    type = "NUMBER(38,0)"
    as   = "TRY_TO_NUMBER(GET(VALUE, 'c5')::VARCHAR)"
  }

  column {
    name = "ADMIN2"
    type = "VARCHAR(100)"
    as   = "GET(VALUE, 'c6')::VARCHAR"
  }

  column {
    name = "LATITUDE"
    type = "FLOAT"
    as   = "TRY_TO_DOUBLE(GET(VALUE, 'c7')::VARCHAR)"
  }

  column {
    name = "LONGITUDE"
    type = "FLOAT"
    as   = "TRY_TO_DOUBLE(GET(VALUE, 'c8')::VARCHAR)"
  }

  column {
    name = "PROVINCE_STATE"
    type = "VARCHAR(100)"
    as   = "GET(VALUE, 'c9')::VARCHAR"
  }

  column {
    name = "COUNTRY_REGION"
    type = "VARCHAR(100)"
    as   = "GET(VALUE, 'c10')::VARCHAR"
  }

  column {
    name = "DATE"
    type = "DATE"
    as   = "TRY_TO_DATE(GET(VALUE, 'c11')::VARCHAR)"
  }

  column {
    name = "CONFIRMED"
    type = "NUMBER(38,0)"
    as   = "TRY_TO_NUMBER(GET(VALUE, 'c12')::VARCHAR)"
  }

  column {
    name = "DEATHS"
    type = "NUMBER(38,0)"
    as   = "TRY_TO_NUMBER(GET(VALUE, 'c13')::VARCHAR)"
  }

  column {
    name = "RECOVERED"
    type = "NUMBER(38,0)"
    as   = "TRY_TO_NUMBER(GET(VALUE, 'c14')::VARCHAR)"
  }

  depends_on = [
    snowflake_stage.covid19_s3_stage,
    snowflake_file_format.csv_format
  ]
}

# =============================================================================
# COVID-19 World Testing 外部テーブルの作成（S3を直接参照・COPY不要）
# SYSADMIN: 外部テーブルの作成（preview機能）
# 主要カラムのみ定義（全60カラム中、分析に有用な30カラム）
# =============================================================================
resource "snowflake_external_table" "ext_covid19_world_testing" {
  provider = snowflake.sysadmin

  database = snowflake_database.raw_db.name
  schema   = snowflake_schema.covid19.name
  name     = "EXT_COVID19_WORLD_TESTING"
  comment  = "COVID-19 world testing, vaccination, hospital data (TRY_*で空文字列対応)"

  location    = "@${snowflake_database.raw_db.name}.${snowflake_schema.covid19.name}.${snowflake_stage.covid19_world_testing_stage.name}"
  file_format = "FORMAT_NAME = ${snowflake_database.raw_db.name}.${snowflake_schema.covid19.name}.${snowflake_file_format.csv_format.name}"

  # 結合キー
  column {
    name = "ISO_CODE"
    type = "VARCHAR(10)"
    as   = "GET(VALUE, 'c1')::VARCHAR"
  }

  column {
    name = "CONTINENT"
    type = "VARCHAR(50)"
    as   = "GET(VALUE, 'c2')::VARCHAR"
  }

  column {
    name = "LOCATION"
    type = "VARCHAR(100)"
    as   = "GET(VALUE, 'c3')::VARCHAR"
  }

  column {
    name = "DATE"
    type = "DATE"
    as   = "TRY_TO_DATE(GET(VALUE, 'c4')::VARCHAR)"
  }

  # 症例データ
  column {
    name = "TOTAL_CASES"
    type = "NUMBER"
    as   = "TRY_TO_NUMBER(GET(VALUE, 'c5')::VARCHAR)"
  }

  column {
    name = "NEW_CASES"
    type = "NUMBER"
    as   = "TRY_TO_NUMBER(GET(VALUE, 'c6')::VARCHAR)"
  }

  column {
    name = "NEW_CASES_SMOOTHED"
    type = "FLOAT"
    as   = "TRY_TO_DOUBLE(GET(VALUE, 'c7')::VARCHAR)"
  }

  column {
    name = "TOTAL_DEATHS"
    type = "NUMBER"
    as   = "TRY_TO_NUMBER(GET(VALUE, 'c8')::VARCHAR)"
  }

  column {
    name = "NEW_DEATHS"
    type = "NUMBER"
    as   = "TRY_TO_NUMBER(GET(VALUE, 'c9')::VARCHAR)"
  }

  column {
    name = "NEW_DEATHS_SMOOTHED"
    type = "FLOAT"
    as   = "TRY_TO_DOUBLE(GET(VALUE, 'c10')::VARCHAR)"
  }

  # 検査データ
  column {
    name = "NEW_TESTS"
    type = "NUMBER"
    as   = "TRY_TO_NUMBER(GET(VALUE, 'c26')::VARCHAR)"
  }

  column {
    name = "TOTAL_TESTS"
    type = "NUMBER"
    as   = "TRY_TO_NUMBER(GET(VALUE, 'c27')::VARCHAR)"
  }

  column {
    name = "POSITIVE_RATE"
    type = "FLOAT"
    as   = "TRY_TO_DOUBLE(GET(VALUE, 'c32')::VARCHAR)"
  }

  # ワクチンデータ
  column {
    name = "TOTAL_VACCINATIONS"
    type = "NUMBER"
    as   = "TRY_TO_NUMBER(GET(VALUE, 'c35')::VARCHAR)"
  }

  column {
    name = "PEOPLE_VACCINATED"
    type = "NUMBER"
    as   = "TRY_TO_NUMBER(GET(VALUE, 'c36')::VARCHAR)"
  }

  column {
    name = "PEOPLE_FULLY_VACCINATED"
    type = "NUMBER"
    as   = "TRY_TO_NUMBER(GET(VALUE, 'c37')::VARCHAR)"
  }

  column {
    name = "TOTAL_BOOSTERS"
    type = "NUMBER"
    as   = "TRY_TO_NUMBER(GET(VALUE, 'c38')::VARCHAR)"
  }

  # 医療データ
  column {
    name = "ICU_PATIENTS"
    type = "NUMBER"
    as   = "TRY_TO_NUMBER(GET(VALUE, 'c18')::VARCHAR)"
  }

  column {
    name = "HOSP_PATIENTS"
    type = "NUMBER"
    as   = "TRY_TO_NUMBER(GET(VALUE, 'c20')::VARCHAR)"
  }

  column {
    name = "HOSPITAL_BEDS_PER_THOUSAND"
    type = "FLOAT"
    as   = "TRY_TO_DOUBLE(GET(VALUE, 'c58')::VARCHAR)"
  }

  # 人口統計
  column {
    name = "POPULATION"
    type = "NUMBER"
    as   = "TRY_TO_NUMBER(GET(VALUE, 'c46')::VARCHAR)"
  }

  column {
    name = "POPULATION_DENSITY"
    type = "FLOAT"
    as   = "TRY_TO_DOUBLE(GET(VALUE, 'c47')::VARCHAR)"
  }

  column {
    name = "MEDIAN_AGE"
    type = "FLOAT"
    as   = "TRY_TO_DOUBLE(GET(VALUE, 'c48')::VARCHAR)"
  }

  column {
    name = "AGED_65_OLDER"
    type = "FLOAT"
    as   = "TRY_TO_DOUBLE(GET(VALUE, 'c49')::VARCHAR)"
  }

  column {
    name = "AGED_70_OLDER"
    type = "FLOAT"
    as   = "TRY_TO_DOUBLE(GET(VALUE, 'c50')::VARCHAR)"
  }

  # 経済・健康指標
  column {
    name = "GDP_PER_CAPITA"
    type = "FLOAT"
    as   = "TRY_TO_DOUBLE(GET(VALUE, 'c51')::VARCHAR)"
  }

  column {
    name = "DIABETES_PREVALENCE"
    type = "FLOAT"
    as   = "TRY_TO_DOUBLE(GET(VALUE, 'c54')::VARCHAR)"
  }

  column {
    name = "CARDIOVASC_DEATH_RATE"
    type = "FLOAT"
    as   = "TRY_TO_DOUBLE(GET(VALUE, 'c53')::VARCHAR)"
  }

  column {
    name = "LIFE_EXPECTANCY"
    type = "FLOAT"
    as   = "TRY_TO_DOUBLE(GET(VALUE, 'c59')::VARCHAR)"
  }

  column {
    name = "HUMAN_DEVELOPMENT_INDEX"
    type = "FLOAT"
    as   = "TRY_TO_DOUBLE(GET(VALUE, 'c60')::VARCHAR)"
  }

  depends_on = [
    snowflake_stage.covid19_world_testing_stage,
    snowflake_file_format.csv_format
  ]
}


# =============================================================================
# EXT_JHU_TIMESERIES 外部テーブルの所有権を SYSADMIN に移譲
# ACCOUNTADMIN: 所有権の変更
# =============================================================================
resource "snowflake_grant_ownership" "ext_jhu_timeseries_to_sysadmin" {
  provider = snowflake.accountadmin

  account_role_name = "SYSADMIN"

  on {
    object_type = "EXTERNAL TABLE"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_external_table.ext_jhu_timeseries.name}\""
  }
}
