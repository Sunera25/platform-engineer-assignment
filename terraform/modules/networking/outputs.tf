output "vpc_id" {
  description = "The ID of the custom VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of IDs for the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs for the private subnets"
  value       = aws_subnet.private[*].id
}

output "alb_security_group_id" {
  description = "Security Group ID assigned to the Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "ecs_instance_security_group_id" {
  description = "Security Group ID assigned to ECS EC2 host instances"
  value       = aws_security_group.ecs_instance.id
}

output "rds_security_group_id" {
  description = "Security Group ID assigned to the RDS PostgreSQL database"
  value       = aws_security_group.rds.id
}

output "lambda_security_group_id" {
  description = "Security Group ID assigned to the scaling Lambda function"
  value       = aws_security_group.lambda.id
}
