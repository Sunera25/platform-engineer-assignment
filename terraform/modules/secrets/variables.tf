variable "environment" {
  type        = string
  description = "Target deployment environment (e.g., prod, dev, staging)"
}

variable "db_username" {
  type        = string
  description = "Master database username stored in Secrets Manager"
  default     = "taskflow_admin"
}

variable "db_name" {
  type        = string
  description = "PostgreSQL initial database name"
  default     = "taskflow"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to Secrets Manager resources"
  default     = {}
}
