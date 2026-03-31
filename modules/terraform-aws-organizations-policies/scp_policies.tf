# #####################################################################
# SCPs
# #####################################################################
locals {
  # Processes and combines all JSON IAM policies to be added to the SCPs as a list of statements
  scp_standard_policies = {
    for scp, config in var.service_control_policies : scp => flatten([
      for policy_name in config.policies : [jsondecode(file("./${var.json_policies_folders.service_control_policy}/${policy_name}${var.json_file_suffix.service_control_policy}"))]
    ])
  }

  # Processes and combines all JSON template policies to be added to the SCPs as a list of statements
  # Template vars passed at the SCP level take precedence over the global template_vars
  scp_templated_policies = {
    for scp, config in var.service_control_policies : scp => flatten([
      for template_name in config.template_policies : [
        jsondecode(templatefile(
          "./${var.template_policies_folders.service_control_policy}/${template_name}${var.template_file_suffix.service_control_policy}",
          merge(var.template_vars, config.template_vars)
        ))
      ]
    ])
  }

  # Combine standard_policies & templated_policies lists to create the final Statement array for each SCP
  scp_combined_policies = {
    for scp, config in var.service_control_policies : scp => concat(local.scp_standard_policies[scp], local.scp_templated_policies[scp])
  }

  # Pre-proccess & build scp attachments and scp target pairings
  scp_attachments = flatten([
    for scp, config in var.service_control_policies : [
      for ou in config.target : {
        scp_name = scp
        target   = ou
      }
    ]
  ])
}

# Terraform Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy
resource "aws_organizations_policy" "scp" {
  for_each = var.service_control_policies

  name        = each.value.name
  description = each.value.description
  type        = "SERVICE_CONTROL_POLICY"

  # Use service_control_policy_template.json.tpl to format the policy statements
  content = templatefile("${path.module}/policy-templates/control_policies_template.json.tpl", {
    statement = jsonencode(local.scp_combined_policies[each.key])
  })
}

# Terraform Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment
# Attach each SCP to each specified target
resource "aws_organizations_policy_attachment" "scp_attachment" {
  for_each = { for attachment in local.scp_attachments : "${attachment.scp_name}-${attachment.target}" => attachment }

  policy_id = aws_organizations_policy.scp[each.value.scp_name].id
  target_id = each.value.target
}
