data "aws_organizations_organization" "org" {}

data "aws_region" "main" {}

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

# Additional level of nested OU
# data "aws_organizations_organizational_units" "level_4_children" {
#   for_each = toset(flatten([
#     for nested in data.aws_organizations_organizational_units.level_3_children : nested.children[*].id
#   ]))

#   parent_id = each.value
# }
