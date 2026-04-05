variable "cortex_db_name" {
  type = string
}

variable "semantic_models_schema_name" {
  type = string
}

variable "mcp_server_name" {
  type    = string
  default = "ANALYST_MCP"
}

variable "covid19_semantic_view_name" {
  type = string
}

variable "budget_book_semantic_view_name" {
  type = string
}

variable "developer_role_name" {
  type = string
}
