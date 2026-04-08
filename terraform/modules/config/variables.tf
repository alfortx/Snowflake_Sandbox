variable "database_name" {
  description = "設定・統合系リソース用データベース名"
  type        = string
}

variable "session_policies_schema" {
  description = "セッションポリシー用スキーマ名"
  type        = string
}

variable "session_policy_name" {
  description = "セッションポリシー名"
  type        = string
}
