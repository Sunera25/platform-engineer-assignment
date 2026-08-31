module "secrets" {
  source = "../../modules/secrets"

  environment = var.environment
  db_username = "taskflow_admin"
  db_name     = var.db_name

  tags = {
    Project     = "taskflow"
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "secrets"
  }
}
