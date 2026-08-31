terraform {
  backend "s3" {
    bucket         = "taskflow-terraform-state-prod"
    key            = "envs/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "taskflow-terraform-locks-prod"
    encrypt        = true
  }
}
