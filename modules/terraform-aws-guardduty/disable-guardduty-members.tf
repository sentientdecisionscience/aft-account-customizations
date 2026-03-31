#
# The disable_guardduty_members.py script leaves all member accounts in a SUSPENDED state. Malware Protection for S3 plans are left
# intact & have to be deleted manually.
#

# Lambda zip file
data "archive_file" "lambda_zip" {
  count = var.enable_organization_configuration && var.disable_guardduty_members ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/lambda/disable_guardduty_members.zip"

  source {
    content  = file("${path.module}/lambda/disable_guardduty_members.py")
    filename = "disable_guardduty_members.py"
  }
}

# Lambda function
resource "aws_lambda_function" "disable_guardduty_members" {
  count = var.enable_organization_configuration && var.disable_guardduty_members ? 1 : 0

  filename      = data.archive_file.lambda_zip[0].output_path
  function_name = "disable-guardduty-members"
  description   = "Dissociates and deletes all GuardDuty members from the organization configuration, leaving GuardDuty SUSPENDED in all member accounts"
  role          = aws_iam_role.disable_guardduty_members_role[0].arn
  handler       = "disable_guardduty_members.lambda_handler"
  runtime       = "python3.13"
  timeout       = 900 # 15 minutes

  environment {
    variables = {
      DETECTOR_ID = data.aws_guardduty_detector.organization_detector[0].id
    }
  }

  depends_on = [
    aws_iam_role_policy.disable_guardduty_members_policy[0]
  ]
}

# Trigger Lambda when disable_guardduty_members is true
resource "aws_lambda_invocation" "disable_guardduty_members_invoke_on_apply" {
  count = var.enable_organization_configuration && var.disable_guardduty_members ? 1 : 0

  function_name = aws_lambda_function.disable_guardduty_members[0].function_name

  input = jsonencode({
    key = "value"
  })

  depends_on = [
    aws_guardduty_organization_configuration.guardduty_organization_configuration,
    aws_guardduty_organization_configuration_feature.organization_feature,
    aws_lambda_function.disable_guardduty_members[0]
  ]
}

# Lambda role
resource "aws_iam_role" "disable_guardduty_members_role" {
  count = var.enable_organization_configuration && var.disable_guardduty_members ? 1 : 0

  name = "disable-guardduty-members-role"

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

# Lambda role permissions
resource "aws_iam_role_policy" "disable_guardduty_members_policy" {
  count = var.enable_organization_configuration && var.disable_guardduty_members ? 1 : 0

  name = "disable-guardduty-members-lambda-policy"
  role = aws_iam_role.disable_guardduty_members_role[0].id

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
        Resource = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/disable-guardduty-members:*"
      },
      {
        Effect = "Allow"
        Action = [
          "guardduty:ListMembers",
          "guardduty:DisassociateMembers",
          "guardduty:DeleteMembers",
          "guardduty:StopMonitoringMembers"
        ]
        Resource = "*"
      }
    ]
  })
}
