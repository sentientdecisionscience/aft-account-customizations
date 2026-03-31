locals {
  # Map direct children of the Root OU
  root_ou_map = {
    for ou in data.aws_organizations_organizational_units.main.children : ou.id => ou.arn
  }

  # Extract and map nested children (level 2 OUs)
  level_2_ou_list = flatten([
    for level_2_set in data.aws_organizations_organizational_units.level_2_children : [
      for ou in level_2_set.children : {
        id  = ou.id
        arn = ou.arn
      }
    ]
  ])
  level_2_ou_map = { for ou in local.level_2_ou_list : ou.id => ou.arn }

  # Extract and map level 3 children
  level_3_ou_list = flatten([
    for level_3_set in data.aws_organizations_organizational_units.level_3_children : [
      for ou in level_3_set.children : {
        id  = ou.id
        arn = ou.arn
      }
    ]
  ])
  level_3_ou_map = { for ou in local.level_3_ou_list : ou.id => ou.arn }

  # If you need level 4 OUs
  # Extract and map level 4 children
  # level_4_ou_list = flatten([
  #   for level_3_set in data.aws_organizations_organizational_units.level_4_children : [
  #     for ou in level_3_set.children : {
  #       id  = ou.id
  #       arn = ou.arn
  #     }
  #   ]
  # ])
  # level_4_ou_map = { for ou in local.level_4_ou_list : ou.id => ou.arn }

  # Combine direct, nested, and level 3 children (add more levels if required) into a single map
  all_ou_map = merge(local.root_ou_map, local.level_2_ou_map, local.level_3_ou_map)

  # Build the OU control configurations
  ou_control_configs = distinct(flatten([
    for map_name, map_config in var.map_ous_controls : [
      for ou_id in map_config.ou_ids : [
        for control in concat(
          map_config.strongly_recommended_controls ? keys(local.available_controls.strongly_recommended_controls) : [],
          map_config.elective_controls ? keys(local.available_controls.elective_controls) : [],
          map_config.data_residency_controls ? keys(local.available_controls.data_residency_controls) : [],
          map_config.individual_controls
          ) : {
          control_identifier = (
            startswith(control, "arn:aws:controlcatalog:::control/")
            ? control # Already a valid ARN
            : (
              lookup(local.available_controls.all_controls, control, null) != null
              ? "arn:aws:controlcatalog:::control/${lookup(local.available_controls.all_controls, control, null)}"
              : "arn:aws:controlcatalog:::control/${control}"
            )
          ),
          target_identifier = lookup(local.all_ou_map, ou_id)
        }
      ]
    ]
  ]))
}

# Split the control_identifier to use the target and global key as the tf resource index
resource "aws_controltower_control" "main" {
  for_each = {
    for control in local.ou_control_configs :
    "${control.target_identifier}/${control.control_identifier}" => control
  }

  control_identifier = each.value.control_identifier
  target_identifier  = each.value.target_identifier
}
