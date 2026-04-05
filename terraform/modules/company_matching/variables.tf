variable "raw_db_name" {
  description = "RAW_DB 名（covid19 モジュールから受け取る）"
  type        = string
}

variable "company_matching_schema_name" {
  description = "企業名名寄せ実験用スキーマ名"
  type        = string
}

variable "storage_integration_name" {
  description = "S3アクセス用 Storage Integration 名"
  type        = string
}

variable "s3_bucket_name" {
  description = "外部データ用 S3 バケット名"
  type        = string
}

variable "sandbox_wh_name" {
  description = "ウェアハウス名"
  type        = string
}

variable "ext_edinet_table_name" {
  description = "EDINET外部テーブル名"
  type        = string
}

variable "ext_jpx_table_name" {
  description = "JPX外部テーブル名"
  type        = string
}

variable "ext_nta_table_name" {
  description = "国税庁外部テーブル名"
  type        = string
}
