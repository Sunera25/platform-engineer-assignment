output "ec2_instance_profile_name" {
  description = "Name of the EC2 Instance Profile attached to ECS host instances"
  value       = aws_iam_instance_profile.ec2_instance_profile.name
}

output "ec2_instance_role_arn" {
  description = "ARN of the IAM role attached to EC2 host instances"
  value       = aws_iam_role.ec2_instance_role.arn
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS Task Execution Role used by the container agent"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS Task Role used by the running application container"
  value       = aws_iam_role.ecs_task_role.arn
}

output "lambda_execution_role_arn" {
  description = "ARN of the IAM Role used by the vertical scaling Lambda function"
  value       = aws_iam_role.lambda_execution_role.arn
}
