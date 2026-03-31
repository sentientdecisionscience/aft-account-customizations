# #####################################################################
# AIServicesOptOutPolicy
# #####################################################################
locals {
  # Processes and combines all JSON policies to be added to the AISERVICES_OPT_OUT_POLICYs as a list of statements
  aiservices_opt_out_standard_policies = {
    for aiservices_opt_out_policy, config in var.aiservices_opt_out_policies : aiservices_opt_out_policy => merge(flatten([
      for policy_name in config.policies : [jsondecode(file("./${var.json_policies_folders.aiservices_opt_out_policy}/${policy_name}${var.json_file_suffix.aiservices_opt_out_policy}"))]
    ])...)
  }

  # Processes and combines all JSON template policies to be added to the AISERVICES_OPT_OUT_POLICYs as a list of statements
  # Template vars passed at the AISERVICES_OPT_OUT_POLICY level take precedence over the global template_vars
  aiservices_opt_out_templated_policies = {
    for aiservices_opt_out_policy, config in var.aiservices_opt_out_policies : aiservices_opt_out_policy => merge(flatten([
      for template_name in config.template_policies : [
        jsondecode(templatefile(
          "./${var.template_policies_folders.aiservices_opt_out_policy}/${template_name}${var.template_file_suffix.aiservices_opt_out_policy}",
          merge(var.template_vars, config.template_vars)
        ))
      ]
    ])...)
  }

  # Combine standard_policies & templated_policies lists to create the final Statement array for each AISERVICES_OPT_OUT_POLICY
  aiservices_opt_out_combined_policies = {
    for aiservices_opt_out_policy, config in var.aiservices_opt_out_policies : aiservices_opt_out_policy => merge([local.aiservices_opt_out_standard_policies[aiservices_opt_out_policy], local.aiservices_opt_out_templated_policies[aiservices_opt_out_policy]]...)
  }

  # Pre-proccess & build AISERVICES_OPT_OUT_POLICY attachments and AISERVICES_OPT_OUT_POLICY target pairings
  aiservices_opt_out_policy_attachments = flatten([
    for aiservices_opt_out_policy, config in var.aiservices_opt_out_policies : [
      for ou in config.target : {
        aiservices_opt_out_policy_name = aiservices_opt_out_policy
        target                         = ou
      }
    ]
  ])
}

# Terraform Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy
resource "aws_organizations_policy" "aiservices_opt_out_policies" {
  for_each = var.aiservices_opt_out_policies

  name        = each.value.name
  description = each.value.description
  type        = "AISERVICES_OPT_OUT_POLICY"

  # Use aiservices_opt_out_policy.json.tpl to format the policy statements
  content = templatefile("${path.module}/policy-templates/aiservices_opt_out_policy_template.json.tpl", {
    statement = jsonencode(local.aiservices_opt_out_combined_policies[each.key])
  })
}

# Terraform Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment
# Attach each AISERVICES_OPT_OUT_POLICY to each specified target
resource "aws_organizations_policy_attachment" "aiservices_opt_out_policy_attachment" {
  for_each = { for attachment in local.aiservices_opt_out_policy_attachments : "${attachment.aiservices_opt_out_policy_name}-${attachment.target}" => attachment }

  policy_id = aws_organizations_policy.aiservices_opt_out_policies[each.value.aiservices_opt_out_policy_name].id
  target_id = each.value.target
}
