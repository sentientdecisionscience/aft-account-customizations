resource "aws_iam_role" "chatbot_role" {
  count = var.create_default_iam_role ? 1 : 0
  name  = "ChatBot-${var.chatbot_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "chatbot.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "ChatBot-${var.chatbot_name}-role"
  }
}

resource "aws_iam_policy" "chatbot_policy" {
  count       = var.create_default_iam_role ? 1 : 0
  name        = "ChatBot-${var.chatbot_name}-policy"
  description = "Policy for AWS Chatbot"
  policy      = data.aws_iam_policy_document.chatbot_default_policy.json
}

resource "aws_iam_role_policy_attachment" "chatbot_policy_attachment" {
  count      = var.create_default_iam_role ? 1 : 0
  role       = aws_iam_role.chatbot_role[0].name
  policy_arn = aws_iam_policy.chatbot_policy[0].arn
}

data "aws_iam_policy_document" "chatbot_default_policy" {

  # Monitoring permissions
  statement {
    actions = [
      "autoscaling:Describe*",
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*",
      "logs:Get*",
      "logs:List*",
      "logs:Describe*",
      "logs:TestMetricFilter",
      "logs:FilterLogEvents",
      "sns:Get*",
      "sns:List*",
      "securityhub:*"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    actions = [
      "cloudwatch:PutMetricData",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "sns:Publish"
    ]
    resources = ["*"]
  }
}
