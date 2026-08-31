variable "environment" {
  type        = string
  description = "Target deployment environment (e.g., prod, dev, staging)"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for ASG EC2 host placement"
}

variable "ecs_instance_security_group_id" {
  type        = string
  description = "Security Group ID assigned to ECS host EC2 instances"
}

variable "ec2_instance_profile_name" {
  type        = string
  description = "Name of the EC2 Instance Profile granting host permissions"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for host compute nodes"
  default     = "t3.micro"
}

variable "min_size" {
  type        = number
  description = "Minimum number of EC2 host instances in ASG"
  default     = 2
}

variable "max_size" {
  type        = number
  description = "Maximum number of EC2 host instances in ASG"
  default     = 5
}

variable "desired_capacity" {
  type        = number
  description = "Desired number of EC2 host instances in ASG"
  default     = 2
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to ECS cluster resources"
  default     = {}
}
