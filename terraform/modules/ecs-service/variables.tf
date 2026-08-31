variable "environment" {
  type        = string
  description = "Target deployment environment (e.g., prod, dev, staging)"
}

variable "aws_region" {
  type        = string
  description = "AWS Region for CloudWatch logs integration"
}

variable "cluster_id" {
  type        = string
  description = "ID of the target ECS Cluster"
}

variable "ecs_task_execution_role_arn" {
  type        = string
  description = "ARN of the ECS Task Execution Role"
}

variable "ecs_task_role_arn" {
  type        = string
  description = "ARN of the ECS Task Role"
}

variable "ecr_repository_url" {
  type        = string
  description = "ECR repository URL"
}

variable "image_tag" {
  type        = string
  description = "Container image tag — must be a Git commit SHA"
  default     = "initial-v1"
}

variable "target_group_arn" {
  type        = string
  description = "ARN of the ALB Target Group"
}

variable "app_port" {
  type        = number
  description = "Application HTTP container port"
  default     = 8080
}

variable "task_cpu" {
  type        = number
  description = "CPU units allocated to ECS task (configurable for vertical scaling)"
  default     = 256
}

variable "task_memory" {
  type        = number
  description = "Memory allocated to ECS task in MiB (configurable for vertical scaling)"
  default     = 512
}

variable "desired_count" {
  type        = number
  description = "Desired number of running ECS tasks"
  default     = 2
}

variable "db_host" {
  type        = string
  description = "Database host connection address"
}

variable "db_port" {
  type        = number
  description = "Database connection port"
  default     = 5432
}

variable "db_name" {
  type        = string
  description = "Database schema name"
  default     = "taskflow"
}

variable "secret_arn" {
  type        = string
  description = "ARN of the Secrets Manager secret storing DB credentials"
}

variable "log_group_name" {
  type        = string
  description = "CloudWatch log group name for container logs"
}

variable "log_level" {
  type        = string
  description = "Application logging level (e.g., INFO, DEBUG)"
  default     = "INFO"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to ECS service resources"
  default     = {}
}
