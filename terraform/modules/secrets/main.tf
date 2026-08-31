resource "random_password" "db_password" {
  length  = 16
  special = true
  # Restrict special chars to avoid URL-encoding issues in DB connection strings
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = "${var.environment}-taskflow-rds-credentials"
  description = "RDS PostgreSQL master credentials for TaskFlow"

  tags = merge(var.tags, {
    Name = "${var.environment}-taskflow-rds-credentials"
  })
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    engine   = "postgres"
    dbname   = var.db_name
    port     = 5432
  })
}
