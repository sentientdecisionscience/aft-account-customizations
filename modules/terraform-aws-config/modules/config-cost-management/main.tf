# Lambda zip file
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda/manage_config_resource_compliance.zip"

  source {
    content  = file("${path.module}/lambda/manage_config_resource_compliance.py")
    filename = "manage_config_resource_compliance.py"
  }
}

# Deploy Lambda Function
resource "aws_lambda_function" "config_resource_compliance" {
  function_name = "manage-config-resource-compliance"
  description   = "Enables or disables the AWS Config ResourceCompliance Recorder Resource Type in targeted member accounts"
  role          = aws_iam_role.lambda_role.arn
  handler       = "manage_config_resource_compliance.lambda_handler"
  runtime       = "python3.13"
  timeout       = 900
  filename      = data.archive_file.lambda_zip.output_path

  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }
}

# Invoke Lambda Automatically with Dynamic Inputs
resource "aws_lambda_invocation" "invoke_config_lambda" {
  function_name = aws_lambda_function.config_resource_compliance.function_name

  input = jsonencode({
    accounts     = var.account_ids
    default_role = var.target_iam_role_name
    mode         = var.lambda_function_mode
  })

  depends_on = [aws_lambda_function.config_resource_compliance]
}

# Lambda Execution Role
resource "aws_iam_role" "lambda_role" {
  name = "config-resource-compliance-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# IAM Policy for Lambda Execution Role
resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/manage-config-resource-compliance:*"
      },
      {
        Effect = "Allow"
        Action = ["sts:AssumeRole"]
        Resource = [
          for account in var.account_ids : "arn:aws:iam::${account}:role/${var.target_iam_role_name}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "config:DescribeConfigurationRecorders",
          "config:PutConfigurationRecorder"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:PutParameter",
          "ssm:GetParameter",
          "ssm:DeleteParameter"
        ]
        Resource = "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/config-recorder/settings/*"
      }
    ]
  })
}
