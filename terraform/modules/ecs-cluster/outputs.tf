output "cluster_id" {
  description = "ID of the ECS Cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "Name of the ECS Cluster"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the ECS Cluster"
  value       = aws_ecs_cluster.main.arn
}

output "autoscaling_group_name" {
  description = "Name of the EC2 Auto Scaling Group hosting ECS instances"
  value       = aws_autoscaling_group.ecs.name
}
