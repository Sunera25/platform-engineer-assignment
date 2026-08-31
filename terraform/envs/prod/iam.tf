module "iam" {
  source = "../../modules/iam"

  environment = var.environment
  secret_arns = [module.secrets.secret_arn]

  tags = {
    Project     = "taskflow"
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "iam"
  }
}
