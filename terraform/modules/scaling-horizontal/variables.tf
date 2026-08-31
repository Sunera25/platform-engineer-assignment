variable "environment" {
  type        = string
  description = "Target deployment environment (e.g., prod, dev, staging)"
}

variable "cluster_name" {
  type        = string
  description = "ECS Cluster name for horizontal task scaling"
}

variable "service_name" {
  type        = string
  description = "ECS Service name for horizontal task scaling"
}

variable "min_capacity" {
  type        = number
  description = "Minimum number of ECS tasks to maintain"
  default     = 2
}

variable "max_capacity" {
  type        = number
  description = "Maximum number of ECS tasks to scale out to"
  default     = 10
}

variable "target_cpu_utilization" {
  type        = number
  description = "Target average CPU utilization percentage (e.g., 50.0)"
  default     = 50.0
}

variable "scale_in_cooldown" {
  type        = number
  description = "Cooldown in seconds before removing tasks on scale-in"
  default     = 300
}

variable "scale_out_cooldown" {
  type        = number
  description = "Cooldown in seconds before adding tasks on scale-out"
  default     = 60
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to horizontal scaling resources"
  default     = {}
}
