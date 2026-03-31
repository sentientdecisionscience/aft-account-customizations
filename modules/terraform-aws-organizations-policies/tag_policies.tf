# #####################################################################
# Tag Policies
# #####################################################################
locals {
  # Processes and combines all JSON IAM policies to be added to the TAG_POLICYs as a list of statements
  tag_policy_standard_policies = {
    for tag_policy, config in var.tag_policies : tag_policy => merge(flatten([
      for policy_name in config.policies : [jsondecode(file("./${var.json_policies_folders.tag_policy}/${policy_name}${var.json_file_suffix.tag_policy}"))]
    ])...)
  }

  # Processes and combines all JSON template policies to be added to the TAG_POLICYs as a list of statements
  # Template vars passed at the TAG_POLICY level take precedence over the global template_vars
  tag_policy_templated_policies = {
    for tag_policy, config in var.tag_policies : tag_policy => merge(flatten([
      for template_name in config.template_policies : [
        jsondecode(templatefile(
          "./${var.template_policies_folders.tag_policy}/${template_name}${var.template_file_suffix.tag_policy}",
          merge(var.template_vars, config.template_vars)
        ))
      ]
    ])...)
  }

  # Combine standard_policies & templated_policies lists to create the final Statement array for each TAG_POLICY
  tag_policy_combined_policies = {
    for tag_policy, config in var.tag_policies : tag_policy => merge([local.tag_policy_standard_policies[tag_policy], local.tag_policy_templated_policies[tag_policy]]...)
  }

  # Pre-proccess & build TAG_POLICY attachments and TAG_POLICY target pairings
  tag_policy_attachments = flatten([
    for tag_policy, config in var.tag_policies : [
      for ou in config.target : {
        tag_policy_name = tag_policy
        target          = ou
      }
    ]
  ])
}

# Terraform Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy
resource "aws_organizations_policy" "tag_policies" {
  for_each = var.tag_policies

  name        = each.value.name
  description = each.value.description
  type        = "TAG_POLICY"

  # Use tag_policy_template.json.tpl to format the policy statements
  content = templatefile("${path.module}/policy-templates/tag_policy_template.json.tpl", {
    statement = jsonencode(local.tag_policy_combined_policies[each.key])
  })
}

# Terraform Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment
# Attach each TAG_POLICY to each specified target
resource "aws_organizations_policy_attachment" "tag_policy_attachment" {
  for_each = { for attachment in local.tag_policy_attachments : "${attachment.tag_policy_name}-${attachment.target}" => attachment }

  policy_id = aws_organizations_policy.tag_policies[each.value.tag_policy_name].id
  target_id = each.value.target
}
