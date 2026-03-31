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

# Fetch all Level 1 OUs directly under the Root OU
data "aws_organizations_organizational_units" "level_1_ous" {
  parent_id = data.aws_organizations_organization.current.roots[0].id
}
