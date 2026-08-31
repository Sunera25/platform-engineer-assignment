terraform {
  backend "s3" {
    bucket         = "taskflow-terraform-state-225076308692"
    key            = "envs/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "taskflow-terraform-locks"
    encrypt        = true
  }
}
