# Used to automatically grab the root ou id of your aws organization
data "aws_organizations_organization" "org" {}

data "aws_organizations_organizational_units" "main" {
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

# Fetch nested children of the Root OU's direct children
data "aws_organizations_organizational_units" "level_2_children" {
  for_each = toset(data.aws_organizations_organizational_units.main.children[*].id)

  parent_id = each.value
}

# Fetch children of the nested children (level 3 OUs)
data "aws_organizations_organizational_units" "level_3_children" {
  for_each = toset(flatten([
    for nested in data.aws_organizations_organizational_units.level_2_children : nested.children[*].id
  ]))

  parent_id = each.value
}
