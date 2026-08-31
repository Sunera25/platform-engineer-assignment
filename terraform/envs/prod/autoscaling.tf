module "scaling_horizontal" {
  source = "../../modules/scaling-horizontal"

  environment            = var.environment
  cluster_name           = module.ecs_cluster.cluster_name
  service_name           = module.ecs_service.service_name
  min_capacity           = 2
  max_capacity           = 10
  target_cpu_utilization = 50.0
  scale_in_cooldown      = 300
  scale_out_cooldown     = 60

  tags = {
    Project     = "taskflow"
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "scaling-horizontal"
  }
}
