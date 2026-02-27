# =============================================================================
# マテリアライズドビュー専用ウェアハウスの作成
# マテビューのリフレッシュは分析クエリと分離して管理する
# SYSADMIN: Warehouseの作成と管理
# =============================================================================
resource "snowflake_warehouse" "mv_wh" {
  provider = snowflake.sysadmin

  name           = "MV_WH"
  warehouse_size = "X-Small"
  comment        = "マテリアライズドビューのリフレッシュ専用ウェアハウス"

  auto_suspend        = 60   # 1分未使用で自動停止（リフレッシュ完了後すぐ停止）
  auto_resume         = true
  initially_suspended = true
}

# DEVELOPER_ROLE への MV_WH 使用権限
resource "snowflake_grant_privileges_to_account_role" "mv_wh_usage" {
  provider = snowflake.securityadmin

  account_role_name = snowflake_account_role.developer_role.name
  privileges        = ["USAGE", "OPERATE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.mv_wh.name
  }
}

# ANALYST_ROLE への MV_WH 使用権限
resource "snowflake_grant_privileges_to_account_role" "analyst_mv_wh_usage" {
  provider = snowflake.securityadmin

  account_role_name = snowflake_account_role.analyst_role.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.mv_wh.name
  }
}

# =============================================================================
# マテリアライズドビューの作成
# 外部テーブルの S3 スキャンをキャッシュし、クエリを高速化する
#
# 外部テーブルとの違い:
#   外部テーブル           → クエリのたびに S3 を読み込む（遅い）
#   マテリアライズドビュー → データを Snowflake 内部に保持する（速い）
#
# SYSADMIN: マテリアライズドビューの作成と管理
# =============================================================================

# =============================================================================
# MV_JHU_TIMESERIES
# EXT_JHU_TIMESERIES（JHU 時系列）のマテリアライズドビュー
# =============================================================================
resource "snowflake_materialized_view" "mv_jhu_timeseries" {
  provider = snowflake.sysadmin

  database  = snowflake_database.raw_db.name
  schema    = snowflake_schema.covid19.name
  name      = "MV_JHU_TIMESERIES"
  warehouse = snowflake_warehouse.mv_wh.name
  comment   = "EXT_JHU_TIMESERIES の高速クエリ用 MV（S3 スキャン不要）"

  statement = <<-SQL
    SELECT
      UID,
      FIPS,
      ISO2,
      ISO3,
      CODE3,
      ADMIN2,
      LATITUDE,
      LONGITUDE,
      PROVINCE_STATE,
      COUNTRY_REGION,
      DATE,
      CONFIRMED,
      DEATHS,
      RECOVERED
    FROM ${snowflake_database.raw_db.name}.${snowflake_schema.covid19.name}.${snowflake_external_table.ext_jhu_timeseries.name}
    WHERE DATE IS NOT NULL
  SQL

  depends_on = [
    snowflake_external_table.ext_jhu_timeseries,
    snowflake_warehouse.mv_wh,
  ]
}

# =============================================================================
# MV_COVID19_WORLD_TESTING
# EXT_COVID19_WORLD_TESTING（ワールドテスト・ワクチン）のマテリアライズドビュー
# =============================================================================
resource "snowflake_materialized_view" "mv_covid19_world_testing" {
  provider = snowflake.sysadmin

  database  = snowflake_database.raw_db.name
  schema    = snowflake_schema.covid19.name
  name      = "MV_COVID19_WORLD_TESTING"
  warehouse = snowflake_warehouse.mv_wh.name
  comment   = "EXT_COVID19_WORLD_TESTING の高速クエリ用 MV（S3 スキャン不要）"

  statement = <<-SQL
    SELECT
      ISO_CODE,
      CONTINENT,
      LOCATION,
      DATE,
      TOTAL_CASES,
      NEW_CASES,
      NEW_CASES_SMOOTHED,
      TOTAL_DEATHS,
      NEW_DEATHS,
      NEW_DEATHS_SMOOTHED,
      NEW_TESTS,
      TOTAL_TESTS,
      POSITIVE_RATE,
      TOTAL_VACCINATIONS,
      PEOPLE_VACCINATED,
      PEOPLE_FULLY_VACCINATED,
      TOTAL_BOOSTERS,
      ICU_PATIENTS,
      HOSP_PATIENTS,
      HOSPITAL_BEDS_PER_THOUSAND,
      POPULATION,
      POPULATION_DENSITY,
      MEDIAN_AGE,
      AGED_65_OLDER,
      AGED_70_OLDER,
      GDP_PER_CAPITA,
      DIABETES_PREVALENCE,
      CARDIOVASC_DEATH_RATE,
      LIFE_EXPECTANCY,
      HUMAN_DEVELOPMENT_INDEX
    FROM ${snowflake_database.raw_db.name}.${snowflake_schema.covid19.name}.${snowflake_external_table.ext_covid19_world_testing.name}
    WHERE DATE IS NOT NULL
  SQL

  depends_on = [
    snowflake_external_table.ext_covid19_world_testing,
    snowflake_warehouse.mv_wh,
  ]
}

# =============================================================================
# DEVELOPER_ROLE / ANALYST_ROLE へのマテリアライズドビュー SELECT 権限付与
# =============================================================================

# MV_JHU_TIMESERIES への SELECT 権限（DEVELOPER_ROLE）
resource "snowflake_grant_privileges_to_account_role" "mv_jhu_select" {
  provider = snowflake.securityadmin

  account_role_name = snowflake_account_role.developer_role.name
  privileges        = ["SELECT"]

  on_schema_object {
    object_type = "MATERIALIZED VIEW"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_materialized_view.mv_jhu_timeseries.name}\""
  }
}

# MV_COVID19_WORLD_TESTING への SELECT 権限（DEVELOPER_ROLE）
resource "snowflake_grant_privileges_to_account_role" "mv_world_testing_select" {
  provider = snowflake.securityadmin

  account_role_name = snowflake_account_role.developer_role.name
  privileges        = ["SELECT"]

  on_schema_object {
    object_type = "MATERIALIZED VIEW"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_materialized_view.mv_covid19_world_testing.name}\""
  }
}

# MV_JHU_TIMESERIES への SELECT 権限（ANALYST_ROLE）
resource "snowflake_grant_privileges_to_account_role" "analyst_mv_jhu_select" {
  provider = snowflake.securityadmin

  account_role_name = snowflake_account_role.analyst_role.name
  privileges        = ["SELECT"]

  on_schema_object {
    object_type = "MATERIALIZED VIEW"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_materialized_view.mv_jhu_timeseries.name}\""
  }
}

# MV_COVID19_WORLD_TESTING への SELECT 権限（ANALYST_ROLE）
resource "snowflake_grant_privileges_to_account_role" "analyst_mv_world_testing_select" {
  provider = snowflake.securityadmin

  account_role_name = snowflake_account_role.analyst_role.name
  privileges        = ["SELECT"]

  on_schema_object {
    object_type = "MATERIALIZED VIEW"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.covid19.name}\".\"${snowflake_materialized_view.mv_covid19_world_testing.name}\""
  }
}
