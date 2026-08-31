module "alb" {
  source = "../../modules/alb"

  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  alb_security_group_id = module.networking.alb_security_group_id
  app_port              = var.app_port

  tags = {
    Project     = "taskflow"
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "alb"
  }
}
