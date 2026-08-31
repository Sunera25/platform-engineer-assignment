resource "aws_ecs_task_definition" "app" {
  family                   = "${var.environment}-taskflow"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn
  requires_compatibilities = ["EC2"]
  # bridge mode required for EC2 launch type with static port mapping
  network_mode = "bridge"
  cpu          = tostring(var.task_cpu)
  memory       = tostring(var.task_memory)

  container_definitions = jsonencode([
    {
      name      = "taskflow-app"
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      cpu       = var.task_cpu
      memory    = var.task_memory
      essential = true

      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
          protocol      = "tcp"
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.app_port}/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      # 12-factor: all config from environment variables
      environment = [
        { name = "DB_HOST",     value = var.db_host },
        { name = "DB_PORT",     value = tostring(var.db_port) },
        { name = "DB_NAME",     value = var.db_name },
        { name = "LOG_LEVEL",   value = var.log_level },
        { name = "PORT",        value = tostring(var.app_port) },
        { name = "ENVIRONMENT", value = var.environment },
      ]

      # Credentials injected from Secrets Manager at task launch — never hard-coded
      secrets = [
        { name = "DB_USER",     valueFrom = "${var.secret_arn}:username::" },
        { name = "DB_PASSWORD", valueFrom = "${var.secret_arn}:password::" },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = merge(var.tags, {
    Name = "${var.environment}-taskflow-task-def"
  })
}

resource "aws_ecs_service" "app" {
  name                              = "${var.environment}-taskflow-service"
  cluster                           = var.cluster_id
  task_definition                   = aws_ecs_task_definition.app.arn
  desired_count                     = var.desired_count
  launch_type                       = "EC2"
  health_check_grace_period_seconds = 60

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "taskflow-app"
    container_port   = var.app_port
  }

  # Ignore changes so external scaling (horizontal Auto Scaling + vertical Lambda)
  # can manage desired_count and task_definition without Terraform drift
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-taskflow-service"
  })
}
