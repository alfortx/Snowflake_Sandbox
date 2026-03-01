variable "environment" {
  type = string
}

variable "database_name" {
  type = string
}

variable "schema_name" {
  type = string
}

variable "user_name" {
  type = string
}

variable "user_password" {
  type      = string
  sensitive = true
}

variable "developer_role_name" {
  type = string
}

variable "viewer_role_name" {
  type = string
}

variable "database_comment" {
  type = string
}

variable "schema_comment" {
  type = string
}

variable "warehouse_name" {
  type = string
}

variable "warehouse_size" {
  type = string
}

variable "warehouse_auto_suspend" {
  type = number
}

variable "warehouse_auto_resume" {
  type = bool
}

variable "warehouse_comment" {
  type = string
}
