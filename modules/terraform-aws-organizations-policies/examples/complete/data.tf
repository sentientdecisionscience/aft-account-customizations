# Used to automatically grab the root ou id of your aws organization
data "aws_organizations_organization" "current" {}

# All direct Children OUs under Root
data "aws_organizations_organizational_units" "current" {
  parent_id = data.aws_organizations_organization.current.roots[0].id
}

data "aws_partition" "current" {}
