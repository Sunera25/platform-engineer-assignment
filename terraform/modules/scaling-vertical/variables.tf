variable "environment" {
  type        = string
  description = "Target deployment environment (e.g., prod, dev, staging)"
}

variable "cluster_name" {
  type        = string
  description = "ECS Cluster name managed by the vertical scaling Lambda"
}

variable "service_name" {
  type        = string
  description = "ECS Service name managed by the vertical scaling Lambda"
}

variable "lambda_execution_role_arn" {
  type        = string
  description = "IAM Role ARN granted to the vertical scaling Lambda function"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to vertical scaling resources"
  default     = {}
}
