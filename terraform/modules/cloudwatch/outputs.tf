# ==============================================================================
# Module: CloudWatch - Outputs
# Description: Exports EC2 and ECS Log Group names, ARNs, and Alarm ARNs for 
#              downstream service integration and Lambda permission configuration.
# ==============================================================================

# Output exporting EC2 Log Group Name
output "ec2_log_group_name" {
  # Value reference to EC2 Log Group Name
  value = aws_cloudwatch_log_group.ec2.name
  # Output description
  description = "The Name of the CloudWatch Log Group for EC2 host logs"
}

# Output exporting ECS Log Group Name
output "ecs_log_group_name" {
  # Value reference to ECS Log Group Name
  value = aws_cloudwatch_log_group.ecs.name
  # Output description specifying usage by ECS task definition awslogs log driver
  description = "The Name of the CloudWatch Log Group for ECS container logs"
}

# Output exporting ECS Log Group ARN
output "ecs_log_group_arn" {
  # Value reference to ECS Log Group ARN
  value = aws_cloudwatch_log_group.ecs.arn
  # Output description
  description = "The ARN of the CloudWatch Log Group for ECS container logs"
}

# Output exporting CPU High Alarm ARN
output "cpu_high_alarm_arn" {
  # Value reference to CPU Alarm ARN
  value = aws_cloudwatch_metric_alarm.cpu_high.arn
  # Output description specifying usage by scaling trigger permissions
  description = "The ARN of the High CPU Utilization CloudWatch Alarm"
}

# Output exporting Memory High Alarm ARN
output "memory_high_alarm_arn" {
  # Value reference to Memory Alarm ARN
  value = aws_cloudwatch_metric_alarm.memory_high.arn
  # Output description specifying usage by scaling trigger permissions
  description = "The ARN of the High Memory Utilization CloudWatch Alarm"
}
