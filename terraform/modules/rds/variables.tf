variable "environment" {
  type        = string
  description = "Target deployment environment (e.g., prod, dev, staging)"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for DB Subnet Group placement"
}

variable "rds_security_group_id" {
  type        = string
  description = "Security Group ID allowing inbound PostgreSQL traffic on port 5432"
}

variable "db_name" {
  type        = string
  description = "Initial PostgreSQL database name"
  default     = "taskflow"
}

variable "db_username" {
  type        = string
  description = "Master database username sourced from Secrets Manager"
}

variable "db_password" {
  type        = string
  description = "Master database password sourced from Secrets Manager"
  sensitive   = true
}

variable "db_engine_version" {
  type        = string
  description = "PostgreSQL engine version"
  default     = "15.7"
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class (e.g., db.t4g.micro)"
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  type        = number
  description = "Allocated storage size in GB"
  default     = 20
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to RDS resources"
  default     = {}
}
