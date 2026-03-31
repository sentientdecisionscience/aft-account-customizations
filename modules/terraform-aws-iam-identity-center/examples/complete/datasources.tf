
data "aws_organizations_organization" "org" {}

data "aws_iam_policy_document" "S3Access" {
  statement {
    sid    = "AllowS3Access"
    effect = "Allow"
    actions = [
      "s3:*",
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "EC2Access" {
  statement {
    sid    = "AllowEC2Access"
    effect = "Allow"
    actions = [
      "ec2:*",
    ]
    resources = [
      "*"
    ]
  }
}
