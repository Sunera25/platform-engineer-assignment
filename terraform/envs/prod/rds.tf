module "rds" {
  source = "../../modules/rds"

  environment           = var.environment
  private_subnet_ids    = module.networking.private_subnet_ids
  rds_security_group_id = module.networking.rds_security_group_id
  db_name               = var.db_name
  db_username           = module.secrets.db_username
  db_password           = module.secrets.db_password
  db_instance_class     = var.db_instance_class
  allocated_storage     = var.db_allocated_storage

  tags = {
    Project     = "taskflow"
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "rds"
  }
}
