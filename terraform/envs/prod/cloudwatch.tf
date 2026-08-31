module "cloudwatch" {
  source = "../../modules/cloudwatch"

  environment        = var.environment
  cluster_name       = module.ecs_cluster.cluster_name
  service_name       = module.ecs_service.service_name
  log_retention_days = 30
  cpu_threshold      = 70
  memory_threshold   = 70
  lambda_arn         = module.scaling_vertical.lambda_function_arn

  tags = {
    Project     = "taskflow"
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "cloudwatch"
  }
}
