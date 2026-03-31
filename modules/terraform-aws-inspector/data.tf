# Getting current aws organization information
data "aws_organizations_organization" "current" {}

# Get current account information
data "aws_caller_identity" "current" {}

# Get current region
data "aws_region" "current" {}
