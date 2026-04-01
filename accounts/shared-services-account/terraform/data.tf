# Fetch current AWS Session Information
data "aws_caller_identity" "current" {}

# Fetch current working AWS Partition
data "aws_partition" "current" {}

# Fetch current working AWS Region
data "aws_region" "current" {}

# Data source to get your Identity Center instance
data "aws_ssoadmin_instances" "this" {}
