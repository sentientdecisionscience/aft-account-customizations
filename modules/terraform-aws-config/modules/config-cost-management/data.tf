# Current AWS account information
data "aws_caller_identity" "current" {}

# Current AWS region
data "aws_region" "current" {}
