create or replace semantic view CORTEX_DB.SEMANTIC_MODELS.COVID19_SEMANTIC
	tables (
		JHU_TIMESERIES as RAW_DB.COVID19.MV_JHU_TIMESERIES primary key (ISO3,DATE),
		WORLD_TESTING as RAW_DB.COVID19.MV_COVID19_WORLD_TESTING primary key (ISO_CODE,DATE)
	)
	relationships (
		JHU_TO_WORLD as JHU_TIMESERIES(ISO3,DATE) references WORLD_TESTING(ISO_CODE,DATE)
	)
	facts (
		JHU_TIMESERIES.CONFIRMED as CONFIRMED with synonyms=('cases','感染者数','陽性者数','累計感染者数') comment='累計感染確認者数',
		JHU_TIMESERIES.DEATHS as DEATHS with synonyms=('fatalities','死者数','死亡者数','累計死者数') comment='累計死者数',
		JHU_TIMESERIES.RECOVERED as RECOVERED with synonyms=('recoveries','回復者数','完治者数') comment='累計回復者数',
		WORLD_TESTING.GDP_PER_CAPITA as GDP_PER_CAPITA with synonyms=('GDP','一人当たりGDP') comment='一人当たりGDP',
		WORLD_TESTING.NEW_CASES as NEW_CASES with synonyms=('daily cases','新規感染者数','日次感染者数') comment='日次新規感染者数',
		WORLD_TESTING.NEW_DEATHS as NEW_DEATHS with synonyms=('daily deaths','新規死者数') comment='日次新規死者数',
		WORLD_TESTING.PEOPLE_FULLY_VACCINATED as PEOPLE_FULLY_VACCINATED with synonyms=('fully vaccinated','ワクチン完全接種者数','完全接種者数') comment='ワクチン接種完了者数',
		WORLD_TESTING.POPULATION as POPULATION with synonyms=('population','人口','総人口') comment='国の総人口',
		WORLD_TESTING.TOTAL_TESTS as TOTAL_TESTS with synonyms=('総検査数','累計検査数') comment='累計検査数',
		WORLD_TESTING.TOTAL_VACCINATIONS as TOTAL_VACCINATIONS with synonyms=('ワクチン接種総数','累計ワクチン接種数') comment='ワクチン接種総回数'
	)
	dimensions (
		JHU_TIMESERIES.COUNTRY_REGION as COUNTRY_REGION with synonyms=('country','nation','国','国名','地域') comment='国または地域の名前',
		JHU_TIMESERIES.ISO3_CODE as ISO3 with synonyms=('country code','iso code','国コード') comment='ISO 3文字国コード',
		JHU_TIMESERIES.PROVINCE_STATE as PROVINCE_STATE with synonyms=('province','state','州','省') comment='州・省の名前。NULLは国全体',
		JHU_TIMESERIES.RECORD_DATE as DATE comment='記録日',
		WORLD_TESTING.CONTINENT as CONTINENT with synonyms=('continent','大陸','地域区分') comment='大陸名'
	)
	metrics (
		JHU_TIMESERIES.CASE_FATALITY_RATE as CASE WHEN SUM(CONFIRMED) > 0 
                 THEN ROUND(SUM(DEATHS) / SUM(CONFIRMED) * 100, 2) 
                 ELSE NULL END with synonyms=('CFR','fatality rate','死亡率','致死率') comment='致死率（%）',
		WORLD_TESTING.VACCINATION_RATE_PCT as CASE WHEN SUM(POPULATION) > 0 
                 THEN ROUND(SUM(PEOPLE_FULLY_VACCINATED) / SUM(POPULATION) * 100, 1) 
                 ELSE NULL END with synonyms=('vaccination rate','ワクチン接種率','完全接種率') comment='ワクチン接種率（%）'
	)
	comment='COVID-19分析用セマンティックビュー'
	with extension (CA='{"tables":[{"name":"JHU_TIMESERIES","dimensions":[{"name":"COUNTRY_REGION"},{"name":"ISO3_CODE"},{"name":"PROVINCE_STATE"},{"name":"RECORD_DATE"}],"facts":[{"name":"CONFIRMED"},{"name":"DEATHS"},{"name":"RECOVERED"}],"metrics":[{"name":"CASE_FATALITY_RATE"}]},{"name":"WORLD_TESTING","dimensions":[{"name":"CONTINENT"}],"facts":[{"name":"GDP_PER_CAPITA"},{"name":"NEW_CASES"},{"name":"NEW_DEATHS"},{"name":"PEOPLE_FULLY_VACCINATED"},{"name":"POPULATION"},{"name":"TOTAL_TESTS"},{"name":"TOTAL_VACCINATIONS"}],"metrics":[{"name":"VACCINATION_RATE_PCT"}]}],"relationships":[{"name":"JHU_TO_WORLD"}],"verified_queries":[{"name":"japan_monthly_trend","sql":"SELECT\\n  DATE_TRUNC(''month'', DATE) AS month,\\n  MAX(CONFIRMED) AS cumulative_confirmed,\\n  MAX(DEATHS) AS cumulative_deaths\\nFROM RAW_DB.COVID19.MV_JHU_TIMESERIES\\nWHERE COUNTRY_REGION = ''Japan'' AND PROVINCE_STATE IS NULL\\nGROUP BY 1\\nORDER BY 1\\n","question":"日本のCOVID-19感染者数と死者数の月別推移を教えてください","verified_at":1771545600,"verified_by":"admin","use_as_onboarding_question":true},{"name":"top10_vaccination_rate","sql":"SELECT\\n  LOCATION AS country,\\n  MAX(PEOPLE_FULLY_VACCINATED) AS fully_vaccinated,\\n  MAX(POPULATION) AS population,\\n  ROUND(MAX(PEOPLE_FULLY_VACCINATED) / NULLIF(MAX(POPULATION), 0) * 100, 1) AS vaccination_rate_pct\\nFROM RAW_DB.COVID19.MV_COVID19_WORLD_TESTING\\nWHERE PEOPLE_FULLY_VACCINATED IS NOT NULL AND POPULATION > 1000000\\nGROUP BY LOCATION\\nORDER BY vaccination_rate_pct DESC\\nLIMIT 10\\n","question":"ワクチン完全接種率が高い国のトップ10は？","verified_at":1771545600,"verified_by":"admin","use_as_onboarding_question":true},{"name":"continent_comparison","sql":"SELECT\\n  CONTINENT,\\n  SUM(TOTAL_CASES) AS total_cases,\\n  SUM(TOTAL_DEATHS) AS total_deaths,\\n  ROUND(SUM(TOTAL_DEATHS) / NULLIF(SUM(TOTAL_CASES), 0) * 100, 2) AS fatality_rate_pct\\nFROM RAW_DB.COVID19.MV_COVID19_WORLD_TESTING\\nWHERE CONTINENT IS NOT NULL\\nGROUP BY CONTINENT\\nORDER BY total_cases DESC\\n","question":"大陸ごとの感染者数と致死率を比較してください","verified_at":1771545600,"verified_by":"admin","use_as_onboarding_question":true},{"name":"highest_positive_rate","sql":"SELECT\\n  LOCATION AS country,\\n  ROUND(AVG(POSITIVE_RATE) * 100, 2) AS avg_positive_rate_pct\\nFROM RAW_DB.COVID19.MV_COVID19_WORLD_TESTING\\nWHERE POSITIVE_RATE IS NOT NULL\\nGROUP BY LOCATION\\nHAVING AVG(POSITIVE_RATE) > 0\\nORDER BY avg_positive_rate_pct DESC\\nLIMIT 10\\n","question":"検査陽性率が高い国はどこですか？","verified_at":1771545600,"verified_by":"admin","use_as_onboarding_question":false},{"name":"cases_per_capita","sql":"SELECT\\n  LOCATION AS country,\\n  MAX(TOTAL_CASES) AS total_cases,\\n  MAX(POPULATION) AS population,\\n  ROUND(MAX(TOTAL_CASES) / NULLIF(MAX(POPULATION), 0) * 100000, 1) AS cases_per_100k\\nFROM RAW_DB.COVID19.MV_COVID19_WORLD_TESTING\\nWHERE TOTAL_CASES IS NOT NULL AND POPULATION > 1000000\\nGROUP BY LOCATION\\nORDER BY cases_per_100k DESC\\nLIMIT 10\\n","question":"人口あたりの感染者数が多い国は？","verified_at":1771545600,"verified_by":"admin","use_as_onboarding_question":false},{"name":"asia_countries_ranking","sql":"SELECT\\n  LOCATION AS country,\\n  MAX(TOTAL_CASES) AS total_cases,\\n  MAX(TOTAL_DEATHS) AS total_deaths,\\n  MAX(PEOPLE_FULLY_VACCINATED) AS fully_vaccinated\\nFROM RAW_DB.COVID19.MV_COVID19_WORLD_TESTING\\nWHERE CONTINENT = ''Asia''\\nGROUP BY LOCATION\\nORDER BY total_cases DESC\\nLIMIT 15\\n","question":"アジア各国の感染者数ランキングを教えてください","verified_at":1771545600,"verified_by":"admin","use_as_onboarding_question":true},{"name":"deaths_by_country","sql":"SELECT\\n  LOCATION AS country,\\n  MAX(TOTAL_DEATHS) AS total_deaths,\\n  MAX(TOTAL_CASES) AS total_cases,\\n  ROUND(MAX(TOTAL_DEATHS) / NULLIF(MAX(TOTAL_CASES), 0) * 100, 2) AS fatality_rate_pct\\nFROM RAW_DB.COVID19.MV_COVID19_WORLD_TESTING\\nWHERE TOTAL_DEATHS IS NOT NULL\\nGROUP BY LOCATION\\nORDER BY total_deaths DESC\\nLIMIT 10\\n","question":"死者数が多い国のトップ10は？","verified_at":1771545600,"verified_by":"admin","use_as_onboarding_question":false}]}');