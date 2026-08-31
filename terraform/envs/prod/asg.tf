module "ecs_cluster" {
  source = "../../modules/ecs-cluster"

  environment                    = var.environment
  private_subnet_ids             = module.networking.private_subnet_ids
  ecs_instance_security_group_id = module.networking.ecs_instance_security_group_id
  ec2_instance_profile_name      = module.iam.ec2_instance_profile_name
  instance_type                  = var.instance_type
  desired_capacity               = var.asg_desired_capacity
  min_size                       = var.asg_min_size
  max_size                       = var.asg_max_size

  tags = {
    Project        = "taskflow"
    Environment    = var.environment
    ManagedBy      = "terraform"
    Component      = "ecs-host"
    AnsibleManaged = "true"
  }
}
