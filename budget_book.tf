# =============================================================================
# 家計簿データ (MoneyForward) - RAW_DB リソース
#
# 構成:
#   RAW_DB
#   └── BUDGET_BOOK スキーマ
#       ├── BUDGET_BOOK_STAGE          (内部ステージ: PUT→COPYワークフロー)
#       ├── BUDGET_BOOK_CSV_FORMAT     (CP932, comma, double-quote, header skip)
#       └── TRANSACTIONS               (家計簿テーブル: 列名は英語化しsynonymで日本語対応)
#
# データロードワークフロー:
#   1. PUT file:///path/to/*.csv @RAW_DB.BUDGET_BOOK.BUDGET_BOOK_STAGE AUTO_COMPRESS=FALSE
#   2. COPY INTO TRANSACTIONS ... FILE_FORMAT = BUDGET_BOOK_CSV_FORMAT
#      ※ 日付列は TRY_TO_DATE($2, 'YYYY/MM/DD') でDATE型に変換
# =============================================================================

# -----------------------------------------------------------------------------
# BUDGET_BOOK スキーマ
# -----------------------------------------------------------------------------
resource "snowflake_schema" "budget_book" {
  provider = snowflake.sysadmin

  database = snowflake_database.raw_db.name
  name     = var.budget_book_schema_name
  comment  = "家計簿CSVデータ格納用スキーマ"
}

# -----------------------------------------------------------------------------
# 内部ステージ: ローカルCSVファイルのアップロード先
#   URLを指定しないと内部ステージになる（S3等の外部ステージではない）
#   操作: PUT でアップロード → COPY INTO でテーブルへロード
# -----------------------------------------------------------------------------
resource "snowflake_stage" "budget_book_stage" {
  provider = snowflake.sysadmin

  database  = snowflake_database.raw_db.name
  schema    = snowflake_schema.budget_book.name
  name      = "BUDGET_BOOK_STAGE"
  directory = "ENABLE = true"
  comment   = "家計簿CSVファイルのPUT/COPY用内部ステージ"

  depends_on = [snowflake_schema.budget_book]
}

# -----------------------------------------------------------------------------
# ファイルフォーマット: CP932（Shift_JIS）対応
#   MoneyForwardのCSVエクスポートはCP932（Windows日本語）エンコード
#   全フィールドがダブルクォートで囲まれている
# -----------------------------------------------------------------------------
resource "snowflake_file_format" "budget_book_csv_format" {
  provider = snowflake.sysadmin

  database                     = snowflake_database.raw_db.name
  schema                       = snowflake_schema.budget_book.name
  name                         = "BUDGET_BOOK_CSV_FORMAT"
  format_type                  = "CSV"
  encoding                     = "SHIFT_JIS" # CP932と互換
  skip_header                  = 1
  field_optionally_enclosed_by = "\""
  null_if                      = [""]
  comment                      = "家計簿CSV用フォーマット（CP932エンコード、ダブルクォート囲み）"

  depends_on = [snowflake_schema.budget_book]
}

# -----------------------------------------------------------------------------
# TRANSACTIONSテーブル
#   列名は英語化し、セマンティックビューでsynonymを付与して日本語対応
#   CSVの列順: 計算対象, 日付, 内容, 金額（円）, 保有金融機関, 大項目, 中項目, メモ, 振替, ID
# -----------------------------------------------------------------------------
resource "snowflake_table" "budget_book_transactions" {
  provider = snowflake.sysadmin

  database = snowflake_database.raw_db.name
  schema   = snowflake_schema.budget_book.name
  name     = "TRANSACTIONS"
  comment  = "家計簿データ（CP932 CSVからCOPY INTO）"

  column {
    name     = "ID"
    type     = "VARCHAR(50)"
    nullable = false
    comment  = "マネーフォワード固有のトランザクションID"
  }

  column {
    name     = "CALCULATION_TARGET"
    type     = "NUMBER(1,0)"
    nullable = true
    comment  = "計算対象フラグ（1=対象, 0=対象外）"
  }

  column {
    name     = "TRANSACTION_DATE"
    type     = "DATE"
    nullable = true
    comment  = "取引日（CSVのYYYY/MM/DD文字列をDATEに変換）"
  }

  column {
    name     = "DESCRIPTION"
    type     = "VARCHAR(500)"
    nullable = true
    comment  = "取引内容・店舗名等"
  }

  column {
    name     = "AMOUNT"
    type     = "NUMBER(15,0)"
    nullable = true
    comment  = "金額（円）。負数=支出、正数=収入"
  }

  column {
    name     = "INSTITUTION"
    type     = "VARCHAR(200)"
    nullable = true
    comment  = "保有金融機関・カード名"
  }

  column {
    name     = "MAJOR_CATEGORY"
    type     = "VARCHAR(100)"
    nullable = true
    comment  = "大項目カテゴリ（食費・交通費等）"
  }

  column {
    name     = "MINOR_CATEGORY"
    type     = "VARCHAR(100)"
    nullable = true
    comment  = "中項目カテゴリ（外食・コンビニ等）"
  }

  column {
    name     = "MEMO"
    type     = "VARCHAR(500)"
    nullable = true
    comment  = "メモ（ほぼ空）"
  }

  column {
    name     = "TRANSFER_FLAG"
    type     = "NUMBER(1,0)"
    nullable = true
    comment  = "振替フラグ（1=振替取引, 0=通常取引）"
  }

  depends_on = [snowflake_schema.budget_book]
}

# =============================================================================
# DEVELOPER_ROLE への権限付与（RAW_DB.BUDGET_BOOK）
# =============================================================================

# BUDGET_BOOK スキーマの権限（読み書き）
resource "snowflake_grant_privileges_to_account_role" "sandbox_budget_book_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.developer_role.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW", "CREATE STAGE"]

  on_schema {
    schema_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.budget_book.name}\""
  }
}

# TRANSACTIONS テーブルへの権限（読み書き）
resource "snowflake_grant_privileges_to_account_role" "sandbox_budget_book_transactions" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.developer_role.name
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]

  on_schema_object {
    object_type = "TABLE"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.budget_book.name}\".\"${snowflake_table.budget_book_transactions.name}\""
  }
}

# 将来作成されるテーブルへの FUTURE GRANT（読み書き）
resource "snowflake_grant_privileges_to_account_role" "sandbox_budget_book_future_tables" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.developer_role.name
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.budget_book.name}\""
    }
  }
}

# BUDGET_BOOK_STAGE への READ/WRITE 権限（PUT/COPY操作に必要）
resource "snowflake_grant_privileges_to_account_role" "sandbox_budget_book_stage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.developer_role.name
  privileges        = ["READ", "WRITE"]

  on_schema_object {
    object_type = "STAGE"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.budget_book.name}\".\"${snowflake_stage.budget_book_stage.name}\""
  }
}

# BUDGET_BOOK_CSV_FORMAT への USAGE 権限
resource "snowflake_grant_privileges_to_account_role" "sandbox_budget_book_file_format" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.developer_role.name
  privileges        = ["USAGE"]

  on_schema_object {
    object_type = "FILE FORMAT"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.budget_book.name}\".\"${snowflake_file_format.budget_book_csv_format.name}\""
  }
}

# =============================================================================
# ANALYST_ROLE への権限付与（RAW_DB.BUDGET_BOOK）
# =============================================================================

# BUDGET_BOOK スキーマの権限（読み取りのみ）
resource "snowflake_grant_privileges_to_account_role" "analyst_budget_book_schema" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.analyst_role.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.budget_book.name}\""
  }
}

# TRANSACTIONS テーブルへの権限（読み取りのみ）
resource "snowflake_grant_privileges_to_account_role" "analyst_budget_book_transactions" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.analyst_role.name
  privileges        = ["SELECT"]

  on_schema_object {
    object_type = "TABLE"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.budget_book.name}\".\"${snowflake_table.budget_book_transactions.name}\""
  }
}

# 将来作成されるテーブルへの FUTURE GRANT（読み取りのみ）
resource "snowflake_grant_privileges_to_account_role" "analyst_budget_book_future_tables" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.analyst_role.name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.budget_book.name}\""
    }
  }
}

# BUDGET_BOOK_STAGE への READ 権限のみ（ダウンロードのみ、アップロード不可）
resource "snowflake_grant_privileges_to_account_role" "analyst_budget_book_stage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.analyst_role.name
  privileges        = ["READ"]

  on_schema_object {
    object_type = "STAGE"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.budget_book.name}\".\"${snowflake_stage.budget_book_stage.name}\""
  }
}

# BUDGET_BOOK_CSV_FORMAT への USAGE 権限
resource "snowflake_grant_privileges_to_account_role" "analyst_budget_book_file_format" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.analyst_role.name
  privileges        = ["USAGE"]

  on_schema_object {
    object_type = "FILE FORMAT"
    object_name = "\"${snowflake_database.raw_db.name}\".\"${snowflake_schema.budget_book.name}\".\"${snowflake_file_format.budget_book_csv_format.name}\""
  }
}
