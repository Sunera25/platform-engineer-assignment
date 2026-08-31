module "networking" {
  source = "../../modules/networking"

  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  app_port             = var.app_port

  tags = {
    Project     = "taskflow"
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "networking"
  }
}
