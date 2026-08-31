variable "aws_region" {
  type        = string
  description = "AWS Region for deployment"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Target deployment environment (e.g., prod)"
  default     = "prod"
}

variable "vpc_cidr" {
  type        = string
  description = "IPv4 CIDR block for custom VPC"
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of Availability Zones for multi-AZ HA (minimum 2)"
  default     = ["us-east-1a", "us-east-1b"]
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
  description = "Application HTTP container listening port"
  default     = 8080
}

variable "image_tag" {
  type        = string
  description = "Container image tag — must be a Git commit SHA, never 'latest'"
  default     = "prod-commit-sha-12345"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for ECS host ASG"
  default     = "t3.micro"
}

variable "asg_desired_capacity" {
  type        = number
  description = "Desired number of EC2 host instances in ASG"
  default     = 2
}

variable "asg_min_size" {
  type        = number
  description = "Minimum number of EC2 host instances in ASG"
  default     = 2
}

variable "asg_max_size" {
  type        = number
  description = "Maximum number of EC2 host instances in ASG"
  default     = 5
}

variable "task_cpu" {
  type        = number
  description = "Initial CPU units allocated to TaskFlow ECS task"
  default     = 256
}

variable "task_memory" {
  type        = number
  description = "Initial memory allocated to TaskFlow ECS task in MiB"
  default     = 512
}

variable "ecs_desired_count" {
  type        = number
  description = "Desired number of running TaskFlow tasks"
  default     = 2
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  type        = number
  description = "RDS allocated storage in GB"
  default     = 20
}

variable "db_name" {
  type        = string
  description = "PostgreSQL initial database name"
  default     = "taskflow"
}

variable "log_level" {
  type        = string
  description = "Application log verbosity level"
  default     = "INFO"
}
