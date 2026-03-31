# #####################################################################
# RCPs
# #####################################################################
locals {
  # Processes and combines all JSON policies to be added to the RCPs as a list of statements
  rcp_standard_policies = {
    for rcp, config in var.resource_control_policies : rcp => flatten([
      for policy_name in config.policies : [jsondecode(file("./${var.json_policies_folders.resource_control_policy}/${policy_name}${var.json_file_suffix.resource_control_policy}"))]
    ])
  }

  # Processes and combines all JSON template policies to be added to the RCPs as a list of statements
  # Template vars passed at the RCP level take precedence over the global template_vars
  rcp_templated_policies = {
    for rcp, config in var.resource_control_policies : rcp => flatten([
      for template_name in config.template_policies : [
        jsondecode(templatefile(
          "./${var.template_policies_folders.resource_control_policy}/${template_name}${var.template_file_suffix.resource_control_policy}",
          merge(var.template_vars, config.template_vars)
        ))
      ]
    ])
  }

  # Combine standard_policies & templated_policies lists to create the final Statement array for each RCP
  rcp_combined_policies = {
    for rcp, config in var.resource_control_policies : rcp => concat(local.rcp_standard_policies[rcp], local.rcp_templated_policies[rcp])
  }

  # Pre-proccess & build rcp attachments and rcp target pairings
  rcp_attachments = flatten([
    for rcp, config in var.resource_control_policies : [
      for ou in config.target : {
        rcp_name = rcp
        target   = ou
      }
    ]
  ])
}

# Terraform Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy
resource "aws_organizations_policy" "rcp" {
  for_each = var.resource_control_policies

  name        = each.value.name
  description = each.value.description
  type        = "RESOURCE_CONTROL_POLICY"

  # Use resource_control_policy_template.json.tpl to format the policy statements
  content = templatefile("${path.module}/policy-templates/control_policies_template.json.tpl", {
    statement = jsonencode(local.rcp_combined_policies[each.key])
  })
}


# Terraform Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment
# Attach each RCP to each specified target
resource "aws_organizations_policy_attachment" "rcp_attachment" {
  for_each = { for attachment in local.rcp_attachments : "${attachment.rcp_name}-${attachment.target}" => attachment }

  policy_id = aws_organizations_policy.rcp[each.value.rcp_name].id
  target_id = each.value.target
}
