output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "ARN of the Target Group routing traffic to TaskFlow containers"
  value       = aws_lb_target_group.app.arn
}

output "target_group_name" {
  description = "Name of the Target Group"
  value       = aws_lb_target_group.app.name
}
