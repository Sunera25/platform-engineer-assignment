output "autoscaling_policy_name" {
  description = "Name of the target tracking CPU auto scaling policy"
  value       = aws_appautoscaling_policy.cpu.name
}

output "scalable_target_resource_id" {
  description = "Resource ID of the Application Auto Scaling target"
  value       = aws_appautoscaling_target.ecs.resource_id
}
