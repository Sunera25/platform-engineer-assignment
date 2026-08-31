output "alb_dns_name" {
  description = "Public DNS endpoint of the TaskFlow Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "vpc_id" {
  description = "Custom VPC ID"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs hosting EC2 hosts and RDS"
  value       = module.networking.private_subnet_ids
}

output "ecr_repository_url" {
  description = "ECR image repository URL"
  value       = module.ecr.repository_url
}

output "rds_endpoint" {
  description = "RDS PostgreSQL connection endpoint"
  value       = module.rds.db_endpoint
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret storing database credentials"
  value       = module.secrets.secret_arn
}

output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value       = module.ecs_cluster.cluster_name
}

output "ecs_service_name" {
  description = "ECS Service name"
  value       = module.ecs_service.service_name
}
