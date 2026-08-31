variable "environment" {
  type        = string
  description = "Target deployment environment (e.g., prod, dev, staging)"
}

variable "secret_arns" {
  type        = list(string)
  description = "Secrets Manager ARNs the ECS Task Execution role is permitted to read"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to all IAM resources"
  default     = {}
}
