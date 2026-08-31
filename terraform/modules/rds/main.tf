resource "aws_db_subnet_group" "main" {
  name        = "${var.environment}-taskflow-db-subnet-group"
  subnet_ids  = var.private_subnet_ids
  description = "Private subnet group for TaskFlow RDS PostgreSQL instance"

  tags = merge(var.tags, {
    Name = "${var.environment}-taskflow-db-subnet-group"
  })
}

resource "aws_db_instance" "main" {
  identifier        = "${var.environment}-taskflow-db"
  engine            = "postgres"
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  db_name           = var.db_name
  username          = var.db_username
  password          = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]
  publicly_accessible    = false

  backup_retention_period = 0
  skip_final_snapshot     = true

  tags = merge(var.tags, {
    Name = "${var.environment}-taskflow-rds"
  })
}
