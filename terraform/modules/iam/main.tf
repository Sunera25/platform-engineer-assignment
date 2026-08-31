data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_instance_role" {
  name               = "${var.environment}-taskflow-ec2-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.environment}-taskflow-ec2-instance-role"
  })
}

resource "aws_iam_role_policy_attachment" "ec2_instance_ecs" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

data "aws_iam_policy_document" "ec2_cloudwatch_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "ec2_cloudwatch" {
  name        = "${var.environment}-taskflow-ec2-cw-policy"
  description = "Allows EC2 hosts to ship logs to CloudWatch"
  policy      = data.aws_iam_policy_document.ec2_cloudwatch_policy.json
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.ec2_cloudwatch.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.environment}-taskflow-ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name

  tags = merge(var.tags, {
    Name = "${var.environment}-taskflow-ec2-instance-profile"
  })
}

data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.environment}-taskflow-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.environment}-taskflow-task-execution-role"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_standard" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_secrets_policy" {
  statement {
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    # Scope to specific secret ARNs when provided; fall back to * only as a safe default
    resources = var.secret_arns != null && length(var.secret_arns) > 0 ? var.secret_arns : ["*"]
  }
}

resource "aws_iam_policy" "ecs_secrets" {
  name        = "${var.environment}-taskflow-ecs-secrets-policy"
  description = "Allows ECS agent to retrieve DB credentials from Secrets Manager"
  policy      = data.aws_iam_policy_document.ecs_secrets_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_secrets" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_secrets.arn
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.environment}-taskflow-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.environment}-taskflow-task-role"
  })
}

data "aws_iam_policy_document" "ecs_task_app_policy" {
  statement {
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs_task_app" {
  name        = "${var.environment}-taskflow-task-app-policy"
  description = "Allows running container to publish custom CloudWatch metrics"
  policy      = data.aws_iam_policy_document.ecs_task_app_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_app" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_app.arn
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = "${var.environment}-taskflow-lambda-execution-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.environment}-taskflow-lambda-execution-role"
  })
}

data "aws_iam_policy_document" "lambda_scaling_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:DescribeTaskDefinition",
      "ecs:UpdateService",
      "ecs:DescribeServices",
    ]
    resources = ["*"]
  }

  statement {
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.ecs_task_execution_role.arn,
      aws_iam_role.ecs_task_role.arn,
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "lambda_scaling" {
  name        = "${var.environment}-taskflow-lambda-scaling-policy"
  description = "Allows vertical scaling Lambda to register new task definitions and trigger redeployments"
  policy      = data.aws_iam_policy_document.lambda_scaling_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_scaling" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_scaling.arn
}
