variable "environment" {
  type        = string
  description = "Target deployment environment (e.g., prod, dev, staging)"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to ECR resources"
  default     = {}
}
