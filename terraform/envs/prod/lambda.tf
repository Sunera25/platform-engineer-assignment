module "scaling_vertical" {
  source = "../../modules/scaling-vertical"

  environment               = var.environment
  cluster_name              = module.ecs_cluster.cluster_name
  service_name              = module.ecs_service.service_name
  lambda_execution_role_arn = module.iam.lambda_execution_role_arn

  tags = {
    Project     = "taskflow"
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "scaling-vertical"
  }
}
