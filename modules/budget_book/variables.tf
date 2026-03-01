variable "raw_db_name" {
  description = "RAW_DB 名（covid19 モジュールから受け取る）"
  type        = string
}

variable "budget_book_schema_name" {
  type = string
}

variable "budget_book_semantic_view_name" {
  type = string
}

variable "budget_book_search_service_name" {
  type = string
}

variable "budget_book_agent_name" {
  type = string
}

variable "cortex_db_name" {
  type = string
}

variable "semantic_models_schema_name" {
  type = string
}

variable "search_services_schema_name" {
  type = string
}

variable "agents_schema_name" {
  type = string
}

variable "sandbox_wh_name" {
  type = string
}

variable "fr_cortex_admin_role_name" {
  type = string
}

variable "fr_cortex_use_role_name" {
  type = string
}
