# ---------------------------------------------------------------------------------------------
# Datasources
# ---------------------------------------------------------------------------------------------

# Fetch current AWS Session Information
data "aws_caller_identity" "current" {}

# Fetch current working AWS Partition
data "aws_partition" "current" {}

# Fetch current working AWS Region
data "aws_region" "current" {}

# Fetch current AWS Organization Information
data "aws_organizations_organization" "current" {}
