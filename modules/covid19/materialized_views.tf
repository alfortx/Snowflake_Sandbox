# =============================================================================
# マテリアライズドビュー専用ウェアハウスとマテリアライズドビュー
# =============================================================================

resource "snowflake_warehouse" "mv_wh" {
  provider = snowflake.sysadmin

  name           = "MV_WH"
  warehouse_size = "X-Small"
  comment        = "マテリアライズドビューのリフレッシュ専用ウェアハウス"

  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
}

resource "snowflake_materialized_view" "mv_jhu_timeseries" {
  provider = snowflake.sysadmin

  database  = snowflake_database.raw_db.name
  schema    = snowflake_schema.covid19.name
  name      = "MV_JHU_TIMESERIES"
  warehouse = snowflake_warehouse.mv_wh.name
  comment   = "EXT_JHU_TIMESERIES の高速クエリ用 MV（S3 スキャン不要）"

  statement = <<-SQL
    SELECT
      UID, FIPS, ISO2, ISO3, CODE3, ADMIN2,
      LATITUDE, LONGITUDE, PROVINCE_STATE, COUNTRY_REGION,
      DATE, CONFIRMED, DEATHS, RECOVERED
    FROM ${snowflake_database.raw_db.name}.${snowflake_schema.covid19.name}.${snowflake_external_table.ext_jhu_timeseries.name}
    WHERE DATE IS NOT NULL
  SQL

  depends_on = [snowflake_external_table.ext_jhu_timeseries, snowflake_warehouse.mv_wh]
}

resource "snowflake_materialized_view" "mv_covid19_world_testing" {
  provider = snowflake.sysadmin

  database  = snowflake_database.raw_db.name
  schema    = snowflake_schema.covid19.name
  name      = "MV_COVID19_WORLD_TESTING"
  warehouse = snowflake_warehouse.mv_wh.name
  comment   = "EXT_COVID19_WORLD_TESTING の高速クエリ用 MV（S3 スキャン不要）"

  statement = <<-SQL
    SELECT
      ISO_CODE, CONTINENT, LOCATION, DATE,
      TOTAL_CASES, NEW_CASES, NEW_CASES_SMOOTHED,
      TOTAL_DEATHS, NEW_DEATHS, NEW_DEATHS_SMOOTHED,
      NEW_TESTS, TOTAL_TESTS, POSITIVE_RATE,
      TOTAL_VACCINATIONS, PEOPLE_VACCINATED, PEOPLE_FULLY_VACCINATED, TOTAL_BOOSTERS,
      ICU_PATIENTS, HOSP_PATIENTS, HOSPITAL_BEDS_PER_THOUSAND,
      POPULATION, POPULATION_DENSITY, MEDIAN_AGE, AGED_65_OLDER, AGED_70_OLDER,
      GDP_PER_CAPITA, DIABETES_PREVALENCE, CARDIOVASC_DEATH_RATE,
      LIFE_EXPECTANCY, HUMAN_DEVELOPMENT_INDEX
    FROM ${snowflake_database.raw_db.name}.${snowflake_schema.covid19.name}.${snowflake_external_table.ext_covid19_world_testing.name}
    WHERE DATE IS NOT NULL
  SQL

  depends_on = [snowflake_external_table.ext_covid19_world_testing, snowflake_warehouse.mv_wh]
}
