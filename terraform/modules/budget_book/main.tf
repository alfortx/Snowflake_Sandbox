# =============================================================================
# budget_book モジュール: 家計簿データ (MoneyForward)
#
# 作成するリソース:
#   RAW_DB.BUDGET_BOOK スキーマ + ステージ + ファイルフォーマット + テーブル
# =============================================================================

resource "snowflake_schema" "budget_book" {
  provider = snowflake.sysadmin

  database = var.raw_db_name
  name     = var.budget_book_schema_name
  comment  = "家計簿CSVデータ格納用スキーマ"
}

resource "snowflake_stage" "budget_book_stage" {
  provider = snowflake.sysadmin

  database  = var.raw_db_name
  schema    = snowflake_schema.budget_book.name
  name      = "BUDGET_BOOK_STAGE"
  directory = "ENABLE = true"
  comment   = "家計簿CSVファイルのPUT/COPY用内部ステージ"

  depends_on = [snowflake_schema.budget_book]
}

resource "snowflake_file_format" "budget_book_csv_format" {
  provider = snowflake.sysadmin

  database                     = var.raw_db_name
  schema                       = snowflake_schema.budget_book.name
  name                         = "BUDGET_BOOK_CSV_FORMAT"
  format_type                  = "CSV"
  encoding                     = "SHIFT_JIS"
  skip_header                  = 1
  field_optionally_enclosed_by = "\""
  null_if                      = [""]
  comment                      = "家計簿CSV用フォーマット（CP932エンコード、ダブルクォート囲み）"

  depends_on = [snowflake_schema.budget_book]
}

resource "snowflake_table" "budget_book_transactions" {
  provider = snowflake.sysadmin

  database = var.raw_db_name
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
# 自動ロードパイプライン: ステージ → STAGING → TRANSACTIONS（UPSERT）
# =============================================================================

resource "snowflake_table" "transactions_staging" {
  provider = snowflake.sysadmin

  database = var.raw_db_name
  schema   = snowflake_schema.budget_book.name
  name     = "TRANSACTIONS_STAGING"
  comment  = "自動ロードパイプラインの中間テーブル（COPY INTO後にMERGEのソースとして使用）"

  column {
    name     = "ID"
    type     = "VARCHAR(50)"
    nullable = true
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
    comment  = "取引日"
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
    comment  = "金額（円）"
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
    comment  = "大項目カテゴリ"
  }
  column {
    name     = "MINOR_CATEGORY"
    type     = "VARCHAR(100)"
    nullable = true
    comment  = "中項目カテゴリ"
  }
  column {
    name     = "MEMO"
    type     = "VARCHAR(500)"
    nullable = true
    comment  = "メモ"
  }
  column {
    name     = "TRANSFER_FLAG"
    type     = "NUMBER(1,0)"
    nullable = true
    comment  = "振替フラグ（1=振替取引, 0=通常取引）"
  }

  depends_on = [snowflake_schema.budget_book]
}

resource "snowflake_execute" "budget_book_stage_stream" {
  provider   = snowflake.sysadmin
  depends_on = [snowflake_stage.budget_book_stage]

  execute = "CREATE OR REPLACE STREAM \"${var.raw_db_name}\".\"${snowflake_schema.budget_book.name}\".\"BUDGET_BOOK_STAGE_STREAM\" ON STAGE \"${var.raw_db_name}\".\"${snowflake_schema.budget_book.name}\".\"${snowflake_stage.budget_book_stage.name}\" COMMENT = 'ステージへのファイル追加・更新を検知するディレクトリStream'"
  revert  = "DROP STREAM IF EXISTS \"${var.raw_db_name}\".\"${snowflake_schema.budget_book.name}\".\"BUDGET_BOOK_STAGE_STREAM\""
}

resource "snowflake_execute" "load_budget_book_task" {
  provider = snowflake.sysadmin
  depends_on = [
    snowflake_table.transactions_staging,
    snowflake_execute.budget_book_stage_stream,
  ]

  execute = <<-EOT
    CREATE OR REPLACE TASK "${var.raw_db_name}"."${snowflake_schema.budget_book.name}"."LOAD_BUDGET_BOOK_TASK"
      WAREHOUSE = ${var.sandbox_wh_name}
      SCHEDULE = '1 minute'
      COMMENT = 'ステージのCSV変化を検知してTRANSACTIONSへUPSERT（ID重複はUPDATE、新規はINSERT）'
      WHEN SYSTEM$STREAM_HAS_DATA('${var.raw_db_name}.${snowflake_schema.budget_book.name}.BUDGET_BOOK_STAGE_STREAM')
    AS
    BEGIN
      TRUNCATE TABLE "${var.raw_db_name}"."${snowflake_schema.budget_book.name}"."${snowflake_table.transactions_staging.name}";

      COPY INTO "${var.raw_db_name}"."${snowflake_schema.budget_book.name}"."${snowflake_table.transactions_staging.name}" (
        ID, CALCULATION_TARGET, TRANSACTION_DATE, DESCRIPTION, AMOUNT,
        INSTITUTION, MAJOR_CATEGORY, MINOR_CATEGORY, MEMO, TRANSFER_FLAG
      )
      FROM (
        SELECT
          $10,
          TRY_TO_NUMBER($1),
          TRY_TO_DATE($2, 'YYYY/MM/DD'),
          $3,
          TRY_TO_NUMBER($4),
          $5, $6, $7, $8,
          TRY_TO_NUMBER($9)
        FROM @"${var.raw_db_name}"."${snowflake_schema.budget_book.name}"."${snowflake_stage.budget_book_stage.name}"
      )
      FILE_FORMAT = (FORMAT_NAME = '"${var.raw_db_name}"."${snowflake_schema.budget_book.name}"."${snowflake_file_format.budget_book_csv_format.name}"')
      FORCE = TRUE
      ON_ERROR = 'CONTINUE';

      MERGE INTO "${var.raw_db_name}"."${snowflake_schema.budget_book.name}"."${snowflake_table.budget_book_transactions.name}" AS t
      USING "${var.raw_db_name}"."${snowflake_schema.budget_book.name}"."${snowflake_table.transactions_staging.name}" AS s
      ON t.ID = s.ID
      WHEN MATCHED THEN UPDATE SET
        t.CALCULATION_TARGET = s.CALCULATION_TARGET,
        t.TRANSACTION_DATE   = s.TRANSACTION_DATE,
        t.DESCRIPTION        = s.DESCRIPTION,
        t.AMOUNT             = s.AMOUNT,
        t.INSTITUTION        = s.INSTITUTION,
        t.MAJOR_CATEGORY     = s.MAJOR_CATEGORY,
        t.MINOR_CATEGORY     = s.MINOR_CATEGORY,
        t.MEMO               = s.MEMO,
        t.TRANSFER_FLAG      = s.TRANSFER_FLAG
      WHEN NOT MATCHED THEN INSERT (
        ID, CALCULATION_TARGET, TRANSACTION_DATE, DESCRIPTION, AMOUNT,
        INSTITUTION, MAJOR_CATEGORY, MINOR_CATEGORY, MEMO, TRANSFER_FLAG
      ) VALUES (
        s.ID, s.CALCULATION_TARGET, s.TRANSACTION_DATE, s.DESCRIPTION, s.AMOUNT,
        s.INSTITUTION, s.MAJOR_CATEGORY, s.MINOR_CATEGORY, s.MEMO, s.TRANSFER_FLAG
      );
    END
  EOT
  revert = "ALTER TASK IF EXISTS \"${var.raw_db_name}\".\"${snowflake_schema.budget_book.name}\".\"LOAD_BUDGET_BOOK_TASK\" SUSPEND"
}

resource "snowflake_execute" "grant_execute_task_to_sysadmin" {
  provider = snowflake.accountadmin

  execute = "GRANT EXECUTE TASK ON ACCOUNT TO ROLE SYSADMIN"
  revert  = "REVOKE EXECUTE TASK ON ACCOUNT FROM ROLE SYSADMIN"
}

resource "snowflake_execute" "load_budget_book_task_resume" {
  provider = snowflake.sysadmin
  depends_on = [
    snowflake_execute.load_budget_book_task,
    snowflake_execute.grant_execute_task_to_sysadmin,
  ]

  execute = "ALTER TASK \"${var.raw_db_name}\".\"${snowflake_schema.budget_book.name}\".\"LOAD_BUDGET_BOOK_TASK\" RESUME"
  revert  = "ALTER TASK IF EXISTS \"${var.raw_db_name}\".\"${snowflake_schema.budget_book.name}\".\"LOAD_BUDGET_BOOK_TASK\" SUSPEND"
}
