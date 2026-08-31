module "ecs_service" {
  source = "../../modules/ecs-service"

  environment                 = var.environment
  aws_region                  = var.aws_region
  cluster_id                  = module.ecs_cluster.cluster_id
  ecs_task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  ecs_task_role_arn           = module.iam.ecs_task_role_arn
  ecr_repository_url          = module.ecr.repository_url
  image_tag                   = var.image_tag
  target_group_arn            = module.alb.target_group_arn
  app_port                    = var.app_port
  task_cpu                    = var.task_cpu
  task_memory                 = var.task_memory
  desired_count               = var.ecs_desired_count
  db_host                     = module.rds.db_address
  db_port                     = module.rds.db_port
  db_name                     = var.db_name
  secret_arn                  = module.secrets.secret_arn
  log_group_name              = module.cloudwatch.ecs_log_group_name
  log_level                   = var.log_level

  tags = {
    Project     = "taskflow"
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "ecs-service"
  }
}
