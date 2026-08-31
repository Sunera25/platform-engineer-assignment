# ==============================================================================
# Environment: Production - Variable Values
# File: terraform/envs/prod/terraform.tfvars
# Responsibility: Provides default environment variable values for production.
# ==============================================================================

aws_region           = "us-east-1"
environment          = "prod"
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
app_port             = 8080
image_tag            = "prod-commit-sha-12345"
instance_type        = "t3.micro"
asg_desired_capacity = 2
asg_min_size         = 2
asg_max_size         = 5
task_cpu             = 256
task_memory          = 512
ecs_desired_count    = 2
db_instance_class    = "db.t4g.micro"
db_allocated_storage = 20
db_name              = "taskflow"
log_level            = "INFO"
