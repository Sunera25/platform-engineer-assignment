output "service_name" {
  description = "Name of the ECS Service"
  value       = aws_ecs_service.app.name
}

output "service_arn" {
  description = "ARN of the ECS Service"
  value       = aws_ecs_service.app.id
}

output "task_definition_arn" {
  description = "ARN of the active ECS Task Definition revision"
  value       = aws_ecs_task_definition.app.arn
}

output "task_definition_family" {
  description = "Family name of the ECS Task Definition"
  value       = aws_ecs_task_definition.app.family
}
