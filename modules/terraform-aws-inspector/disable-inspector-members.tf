#
# The disable_inspector_members.py script disables all Inspector resource scan types in each member account.
# This results in Inspector being disabled in each member account.
#

# Lambda zip file
data "archive_file" "lambda_zip" {
  count = var.enable_organization_configuration && var.disable_inspector_members ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/lambda/disable_inspector_members.zip"

  source {
    content  = file("${path.module}/lambda/disable_inspector_members.py")
    filename = "disable_inspector_members.py"
  }
}

# Disable Inspector Members Lambda function
resource "aws_lambda_function" "disable_inspector_members" {
  count = var.enable_organization_configuration && var.disable_inspector_members ? 1 : 0

  filename      = data.archive_file.lambda_zip[0].output_path
  function_name = "disable-inspector-members"
  description   = "Disables Inspector in all member accounts in the organization configuration"
  role          = aws_iam_role.disable_inspector_members_role[0].arn
  handler       = "disable_inspector_members.lambda_handler"
  runtime       = "python3.13"
  timeout       = 900 # 15 minutes

  environment {
    variables = {
      DELEGATED_ADMIN_ID = data.aws_caller_identity.current.account_id
    }
  }

  depends_on = [
    aws_iam_role_policy.disable_inspector_members_policy[0]
  ]
}

# Trigger Lambda when disable_inspector_members is true
resource "aws_lambda_invocation" "disable_inspector_members_invoke_on_apply" {
  count = var.enable_organization_configuration && var.disable_inspector_members ? 1 : 0

  function_name = aws_lambda_function.disable_inspector_members[0].function_name

  input = jsonencode({
    key = "value"
  })

  depends_on = [
    aws_inspector2_member_association.inspector_member_association,
    aws_inspector2_organization_configuration.inspector_organization_configuration[0],
    aws_lambda_function.disable_inspector_members[0]
  ]
}

# Lambda IAM role
resource "aws_iam_role" "disable_inspector_members_role" {
  count = var.enable_organization_configuration && var.disable_inspector_members ? 1 : 0

  name = "disable-inspector-members-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Lambda IAM role policy
resource "aws_iam_role_policy" "disable_inspector_members_policy" {
  count = var.enable_organization_configuration && var.disable_inspector_members ? 1 : 0

  name = "disable-inspector-members-lambda-policy"
  role = aws_iam_role.disable_inspector_members_role[0].id

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
        Resource = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/disable-inspector-members:*"
      },
      {
        Effect = "Allow"
        Action = [
          "inspector2:ListMembers",
          "inspector2:Disable"
        ]
        Resource = "*"
      }
    ]
  })
}
