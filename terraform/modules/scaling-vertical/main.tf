data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "vertical_scaling" {
  function_name    = "${var.environment}-taskflow-vertical-scaling"
  role             = var.lambda_execution_role_arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 60
  memory_size      = 128

  environment {
    variables = {
      CLUSTER_NAME = var.cluster_name
      SERVICE_NAME = var.service_name
    }
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-taskflow-vertical-scaling-lambda"
  })
}

resource "aws_lambda_permission" "cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatchAlarms"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.vertical_scaling.function_name
  # Correct principal for CloudWatch Alarms direct Lambda invocation (not alarms.amazonaws.com)
  principal = "lambda.alarms.cloudwatch.amazonaws.com"
}
