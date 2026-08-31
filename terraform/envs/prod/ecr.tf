module "ecr" {
  source = "../../modules/ecr"

  environment = var.environment

  tags = {
    Project     = "taskflow"
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "ecr"
  }
}
