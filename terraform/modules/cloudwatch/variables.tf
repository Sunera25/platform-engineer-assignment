variable "environment" {
  type        = string
  description = "Target deployment environment (e.g., prod, dev, staging)"
}

variable "cluster_name" {
  type        = string
  description = "ECS Cluster name for alarm metric dimensions"
}

variable "service_name" {
  type        = string
  description = "ECS Service name for alarm metric dimensions"
}

variable "log_retention_days" {
  type        = number
  description = "Retention period in days for CloudWatch Log Groups"
  default     = 30
}

variable "cpu_threshold" {
  type        = number
  description = "CPU utilization percentage threshold for alarm trigger"
  default     = 70
}

variable "memory_threshold" {
  type        = number
  description = "Memory utilization percentage threshold for alarm trigger"
  default     = 70
}

variable "lambda_arn" {
  type        = string
  description = "ARN of the vertical scaling Lambda triggered on alarm state"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to CloudWatch resources"
  default     = {}
}
