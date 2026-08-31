output "lambda_function_arn" {
  description = "ARN of the vertical scaling Lambda function (used as CloudWatch alarm action)"
  value       = aws_lambda_function.vertical_scaling.arn
}

output "lambda_function_name" {
  description = "Name of the vertical scaling Lambda function"
  value       = aws_lambda_function.vertical_scaling.function_name
}
