# RAWデータ設計書 — 企業名名寄せ実験

`RAW_DB.COMPANY_MATCHING` スキーマに格納する3種の公開データセットのテーブル定義と取得元情報。

---

## データセット一覧

| # | テーブル名 | データソース | 提供者 | 件数（目安） |
|---|-----------|------------|--------|------------|
| 1 | `EXT_EDINET_COMPANIES` | EDINETコードリスト | 金融庁 | 約11,259件 |
| 2 | `EXT_JPX_COMPANIES` | 東証上場銘柄一覧 | 日本取引所グループ（JPX） | 約4,440件 |
| 3 | `EXT_NTA_COMPANIES` | 法人番号公表データ | 国税庁 | 約600万件（都道府県別） |

---

## 1. EXT_EDINET_COMPANIES — EDINETコードリスト

### 取得元

- **提供者**: 金融庁（Financial Services Agency）
- **URL**: https://disclosure2.edinet-fsa.go.jp/WZEK0040.aspx （EDINETトップ → コードリストDL）
- **直接DL**: https://disclosure2dl.edinet-fsa.go.jp/searchdocument/codelist/Edinetcode.zip
- **ライセンス**: 金融庁ウェブサイト利用規約に基づき自由利用可（出所明記不要）
- **更新頻度**: 随時（上場・廃止に伴い更新）
- **ファイル形式**: ZIP内 `EdinetcodeDlInfo.csv`（CP932/SHIFT_JIS、1行目=ダウンロード日、2行目=ヘッダー）

### Snowflakeオブジェクト

| 項目 | 値 |
|------|---|
| データベース | `RAW_DB` |
| スキーマ | `COMPANY_MATCHING` |
| テーブル種別 | External Table |
| S3パス | `s3://snowflake-sandbox-external-data/company-matching/edinet/` |
| ファイルフォーマット | `EDINET_CSV_FORMAT`（SHIFT_JIS, skip_header=2） |

### サンプルデータ（実データより抜粋）

| EDINET_CODE | SUBMITTER_TYPE | LISTING_STATUS | CONSOLIDATED | CAPITAL | FISCAL_YEAR_END | COMPANY_NAME_JA | COMPANY_NAME_EN | COMPANY_NAME_KANA | ADDRESS | INDUSTRY | SECURITIES_CODE | CORPORATE_NUMBER |
|------------|---------------|---------------|-------------|---------|----------------|----------------|----------------|------------------|---------|---------|----------------|----------------|
| E00004 | 内国法人・組合 | 上場 | 有 | 1491 | 5月31日 | カネコ種苗株式会社 | KANEKO SEEDS CO., LTD. | カネコシュビョウカブシキガイシャ | 前橋市古市町一丁目５０番地１２ | 水産・農林業 | 13760 | 5070001000715 |
| E00006 | 内国法人・組合 | 上場 | 有 | 13500 | 5月31日 | 株式会社　サカタのタネ | SAKATA SEED CORPORATION | カブシキガイシャ　サカタノタネ | 横浜市都筑区仲町台２－７－１ | 水産・農林業 | 13770 | 6020001008662 |
| E00007 | 内国法人・組合 | 上場 | 有 | 100 | 3月31日 | ユキグニファクトリー株式会社 | YUKIGUNI FACTORY CO.,LTD. | ユニグニファクトリーカブシキガイシャ | 南魚沼市余川８９番地 | 水産・農林業 | 13750 | 1010001185037 |

### カラム定義

| # | カラム名 | 型 | 内容 |
|---|---------|-----|------|
| 1 | `EDINET_CODE` | VARCHAR(10) | EDINETコード（例: E00001） |
| 2 | `SUBMITTER_TYPE` | VARCHAR(100) | 提出者種別（内国法人・外国法人 等） |
| 3 | `LISTING_STATUS` | VARCHAR(20) | 上場区分（上場・非上場 等） |
| 4 | `CONSOLIDATED` | VARCHAR(5) | 連結の有無（有・無） |
| 5 | `CAPITAL` | NUMBER | 資本金（円） |
| 6 | `FISCAL_YEAR_END` | VARCHAR(10) | 決算期（例: 03月31日） |
| 7 | `COMPANY_NAME_JA` | VARCHAR(300) | **法人名（日本語）** ← 名寄せキー |
| 8 | `COMPANY_NAME_EN` | VARCHAR(300) | 法人名（英語） |
| 9 | `COMPANY_NAME_KANA` | VARCHAR(300) | 法人名（カナ） |
| 10 | `ADDRESS` | VARCHAR(500) | 所在地 |
| 11 | `INDUSTRY` | VARCHAR(100) | 業種区分 |
| 12 | `SECURITIES_CODE` | VARCHAR(10) | 証券コード（上場銘柄のみ） |
| 13 | `CORPORATE_NUMBER` | VARCHAR(20) | **法人番号**（13桁） ← 名寄せ結合キー |

---

## 2. EXT_JPX_COMPANIES — 東証上場銘柄一覧

### 取得元

- **提供者**: 株式会社日本取引所グループ（JPX）
- **URL**: https://www.jpx.co.jp/markets/statistics-equities/misc/01.html
- **ファイル**: 「上場銘柄一覧」→ `data_j.xls`（XLS形式）
- **ライセンス**: JPX利用規約に基づき非商用利用可
- **更新頻度**: 毎営業日更新
- **ファイル形式**: XLS → `convert_jpx.py` で UTF-8 CSV に変換してからS3アップロード

### 変換手順

```bash
python3 experiments/company_matching/convert_jpx.py
# 出力: ~/Downloads/data_j.csv
```

### Snowflakeオブジェクト

| 項目 | 値 |
|------|---|
| データベース | `RAW_DB` |
| スキーマ | `COMPANY_MATCHING` |
| テーブル種別 | External Table |
| S3パス | `s3://snowflake-sandbox-external-data/company-matching/jpx/` |
| ファイルフォーマット | `JPX_CSV_FORMAT`（UTF-8, skip_header=1） |

### サンプルデータ（実データより抜粋）

| LISTED_DATE | SECURITIES_CODE | COMPANY_NAME | MARKET | INDUSTRY_33_CODE | INDUSTRY_33 | INDUSTRY_17_CODE | INDUSTRY_17 | SIZE_CODE | SIZE_NAME |
|------------|----------------|-------------|--------|-----------------|------------|-----------------|------------|----------|----------|
| 20260228 | 1301 | 極洋 | プライム（内国株式） | 50 | 水産・農林業 | 1 | 食品 | 6 | TOPIX Small 1 |
| 20260228 | 1305 | ｉＦｒｅｅＥＴＦ　ＴＯＰＩＸ（年１回決算型） | ETF・ETN | - | - | - | - | - | - |
| 20260228 | 1306 | ＮＥＸＴ　ＦＵＮＤＳ　ＴＯＰＩＸ連動型上場投信 | ETF・ETN | - | - | - | - | - | - |

### カラム定義

| # | カラム名 | 型 | 内容 |
|---|---------|-----|------|
| 1 | `LISTED_DATE` | VARCHAR(10) | 上場日 |
| 2 | `SECURITIES_CODE` | VARCHAR(10) | **証券コード**（4桁 + 英数字混在あり） ← 名寄せ結合キー |
| 3 | `COMPANY_NAME` | VARCHAR(300) | **銘柄名** ← 名寄せキー |
| 4 | `MARKET` | VARCHAR(100) | 市場区分（プライム・スタンダード・グロース 等） |
| 5 | `INDUSTRY_33_CODE` | VARCHAR(10) | 業種コード（33業種分類） |
| 6 | `INDUSTRY_33` | VARCHAR(100) | 業種名（33業種分類） |
| 7 | `INDUSTRY_17_CODE` | VARCHAR(10) | 業種コード（17業種分類） |
| 8 | `INDUSTRY_17` | VARCHAR(100) | 業種名（17業種分類） |
| 9 | `SIZE_CODE` | VARCHAR(10) | 規模コード |
| 10 | `SIZE_NAME` | VARCHAR(100) | 規模区分（大型・中型・小型） |

---

## 3. EXT_NTA_COMPANIES — 国税庁法人番号公表データ

### 取得元

- **提供者**: 国税庁（National Tax Agency）
- **URL**: https://www.houjin-bangou.nta.go.jp/download/
- **ファイル**: 都道府県別 全件データ（例: `02_aomori_all_20260227.csv`）
- **ライセンス**: CC BY 4.0（出所明記の上で自由利用可）
- **更新頻度**: 月次
- **ファイル形式**: SHIFT_JIS CSV、ヘッダー行なし（skip_header=0）

### Snowflakeオブジェクト

| 項目 | 値 |
|------|---|
| データベース | `RAW_DB` |
| スキーマ | `COMPANY_MATCHING` |
| テーブル種別 | External Table |
| S3パス | `s3://snowflake-sandbox-external-data/company-matching/nta/` |
| ファイルフォーマット | `NTA_CSV_FORMAT`（SHIFT_JIS, skip_header=0） |

### サンプルデータ（実データより抜粋 — 青森県）

| SEQ_NO | CORPORATE_NUMBER | PROCESS | CORRECT | UPDATE_DATE | CHANGE_DATE | COMPANY_NAME | COMPANY_NAME_KANA | COMPANY_TYPE | PREFECTURE | MUNICIPALITY | ADDRESS1 | ... | COMPANY_NAME_EN | PREFECTURE_EN |
|--------|----------------|---------|---------|------------|------------|-------------|-----------------|-------------|-----------|------------|---------|-----|----------------|--------------|
| 1 | 1000012160145 | 01 | 1 | 2018-04-02 | 2015-10-05 | 弘前検察審査会 | ヒロサキケンサツシンサカイ | 101 | 青森県 | 弘前市 | 大字下白銀町７ | ... | Hirosaki Committee for the Inquest of Prosecution | Aomori |
| 2 | 1000013050378 | 01 | 1 | 2018-04-02 | 2015-10-05 | 鰺ヶ沢簡易裁判所 | アジガサワカンイサイバンショ | 101 | 青森県 | 西津軽郡鰺ヶ沢町 | 大字米町３８ | ... | Ajigasawa Summary Court | Aomori |
| 3 | 1000020022080 | 01 | 1 | 2020-09-02 | 2015-10-05 | むつ市 | ムツシ | 201 | 青森県 | むつ市 | 中央１丁目８－１ | ... | Mutsu City | Aomori |

### カラム定義

| # | カラム名 | 型 | 内容 |
|---|---------|-----|------|
| 1 | `SEQ_NO` | NUMBER | 連番 |
| 2 | `CORPORATE_NUMBER` | VARCHAR(20) | **法人番号**（13桁） ← 名寄せ結合キー |
| 3 | `PROCESS` | VARCHAR(5) | 処理区分（新規・変更・廃止 等） |
| 4 | `CORRECT` | VARCHAR(5) | 訂正区分 |
| 5 | `UPDATE_DATE` | VARCHAR(20) | 更新年月日 |
| 6 | `CHANGE_DATE` | VARCHAR(20) | 変更年月日 |
| 7 | `COMPANY_NAME` | VARCHAR(300) | **法人名** ← 名寄せキー |
| 8 | `COMPANY_NAME_KANA` | VARCHAR(300) | 法人名（フリガナ） |
| 9 | `COMPANY_TYPE` | VARCHAR(10) | 法人種別（株式会社・有限会社 等） |
| 10 | `PREFECTURE` | VARCHAR(50) | 都道府県名 |
| 11 | `MUNICIPALITY` | VARCHAR(100) | 市区町村名 |
| 12 | `ADDRESS1` | VARCHAR(300) | 丁目番地等 |
| 13 | `ADDRESS2` | VARCHAR(300) | その他住所 |
| 14 | `PREF_CODE` | VARCHAR(5) | 都道府県コード |
| 15 | `CITY_CODE` | VARCHAR(10) | 市区町村コード |
| 16 | `POSTAL_CODE` | VARCHAR(10) | 郵便番号 |
| 17 | `COL17` | VARCHAR(100) | （予備列） |
| 18 | `COL18` | VARCHAR(100) | （予備列） |
| 19 | `COL19` | VARCHAR(100) | （予備列） |
| 20 | `CLOSED_DATE` | VARCHAR(20) | 登記記録の閉鎖等年月日 |
| 21 | `CLOSED_REASON` | VARCHAR(5) | 登記記録の閉鎖等の事由 |
| 22 | `COL22` | VARCHAR(100) | （予備列） |
| 23 | `REGISTRY_CLOSED_DATE` | VARCHAR(20) | 登記記録の閉鎖年月日 |
| 24 | `REGISTRY_CLOSED_REASON` | VARCHAR(5) | 登記記録の閉鎖事由 |
| 25 | `COMPANY_NAME_EN` | VARCHAR(300) | 法人名（英語） |
| 26 | `PREFECTURE_EN` | VARCHAR(100) | 都道府県名（英語） |
| 27 | `ADDRESS_EN` | VARCHAR(500) | 住所（英語） |
| 28 | `COL28` | VARCHAR(100) | （予備列） |
| 29 | `COMPANY_NAME_FURIGANA` | VARCHAR(300) | 法人名（フリガナ） |
| 30 | `CHANGE_REASON` | VARCHAR(5) | 変更事由 |

---

## データセット間の結合キー

| 結合 | キー | 備考 |
|------|------|------|
| EDINET ↔ JPX | `SECURITIES_CODE` | 上場銘柄のみ結合可。非上場はNULL |
| EDINET ↔ NTA | `CORPORATE_NUMBER` | 法人番号で確実に結合可 |
| JPX ↔ NTA | `COMPANY_NAME`（名寄せ） | 直接の共通キーなし → Cortex Search で名寄せ |

---

## S3格納構造

```
snowflake-sandbox-external-data/
  company-matching/
    edinet/
      EdinetcodeDlInfo.csv        ← CP932のままアップロード
    jpx/
      data_j.csv                  ← convert_jpx.py で UTF-8 変換後
    nta/
      02_aomori_all_20260227.csv  ← SHIFT-JISのままアップロード
```
