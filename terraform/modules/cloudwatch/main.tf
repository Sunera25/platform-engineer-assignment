resource "aws_cloudwatch_log_group" "ec2" {
  name              = "/aws/ec2/${var.environment}-taskflow"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.environment}-taskflow-ec2-logs"
  })
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/aws/ecs/${var.environment}-taskflow"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.environment}-taskflow-ecs-logs"
  })
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.environment}-taskflow-cpu-utilization-high"
  alarm_description   = "Triggers vertical scaling Lambda when ECS CPU exceeds threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.cpu_threshold

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

  alarm_actions = var.lambda_arn != "" ? [var.lambda_arn] : []

  tags = merge(var.tags, {
    Name = "${var.environment}-taskflow-cpu-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.environment}-taskflow-memory-utilization-high"
  alarm_description   = "Triggers vertical scaling Lambda when ECS memory exceeds threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.memory_threshold

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

  alarm_actions = var.lambda_arn != "" ? [var.lambda_arn] : []

  tags = merge(var.tags, {
    Name = "${var.environment}-taskflow-memory-alarm"
  })
}
