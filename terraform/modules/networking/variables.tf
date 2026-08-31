variable "environment" {
  type        = string
  description = "Target deployment environment (e.g., prod, dev, staging)"
}

variable "vpc_cidr" {
  type        = string
  description = "IPv4 CIDR block for the custom VPC"
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of Availability Zones for subnet distribution (minimum 2)"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks for public subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks for private subnets"
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "app_port" {
  type        = number
  description = "Application HTTP listening port"
  default     = 8080
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to all networking resources"
  default     = {}
}
