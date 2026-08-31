output "secret_arn" {
  description = "ARN of the Secrets Manager secret storing database credentials"
  value       = aws_secretsmanager_secret.rds_credentials.arn
}

output "secret_name" {
  description = "Name of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.rds_credentials.name
}

output "db_password" {
  description = "Auto-generated database master password"
  value       = random_password.db_password.result
  sensitive   = true
}

output "db_username" {
  description = "Database master username"
  value       = var.db_username
}
