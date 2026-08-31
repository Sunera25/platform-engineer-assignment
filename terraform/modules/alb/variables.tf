variable "environment" {
  type        = string
  description = "Target deployment environment (e.g., prod, dev, staging)"
}

variable "vpc_id" {
  type        = string
  description = "ID of the custom VPC"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for ALB placement across minimum 2 AZs"
}

variable "alb_security_group_id" {
  type        = string
  description = "Security Group ID assigned to the Application Load Balancer"
}

variable "app_port" {
  type        = number
  description = "Application container HTTP listening port"
  default     = 8080
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to ALB resources"
  default     = {}
}
