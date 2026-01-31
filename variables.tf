variable "environment" {
  description = "環境名（例: sandbox, dev, prod）"
  type        = string
  default     = "sandbox"
}

variable "database_name" {
  description = "作成するデータベース名"
  type        = string
  default     = "SANDBOX_DB"
}

variable "schema_name" {
  description = "作成するスキーマ名"
  type        = string
  default     = "WORK"
}

variable "user_name" {
  description = "作成するユーザー名"
  type        = string
  default     = "sandbox_user"
}

variable "user_password" {
  description = "ユーザーのパスワード"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!" # 本番環境では必ず変更してください
}

variable "role_name" {
  description = "作成するロール名"
  type        = string
  default     = "SANDBOX_ROLE"
}

variable "database_comment" {
  description = "データベースのコメント"
  type        = string
  default     = "Snowflake学習用サンドボックスデータベース"
}

variable "schema_comment" {
  description = "スキーマのコメント"
  type        = string
  default     = "作業用スキーマ"
}

variable "warehouse_name" {
  description = "作成するウェアハウス名"
  type        = string
  default     = "SANDBOX_WH"
}

variable "warehouse_size" {
  description = "ウェアハウスのサイズ（X-Small, Small, Medium等）"
  type        = string
  default     = "X-Small"
}

variable "warehouse_auto_suspend" {
  description = "自動サスペンドまでの秒数（300秒=5分）"
  type        = number
  default     = 300
}

variable "warehouse_auto_resume" {
  description = "クエリ実行時に自動再開するか"
  type        = bool
  default     = true
}

variable "warehouse_comment" {
  description = "ウェアハウスのコメント"
  type        = string
  default     = "サンドボックス環境用のX-Smallウェアハウス"
}
