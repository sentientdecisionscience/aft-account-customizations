# #####################################################################
# Backup Policies
# #####################################################################
locals {
  # Processes and combines all JSON policies to be added to the BACKUP_POLICYs as a list of statements
  backup_standard_policies = {
    for backup_policy, config in var.backup_policies : backup_policy => merge(flatten([
      for policy_name in config.policies : [jsondecode(file("./${var.json_policies_folders.backup_policy}/${policy_name}${var.json_file_suffix.backup_policy}"))]
    ])...)
  }

  # Processes and combines all JSON template policies to be added to the BACKUP_POLICYs as a list of statements
  # Template vars passed at the BACKUP_POLICY level take precedence over the global template_vars
  backup_templated_policies = {
    for backup_policy, config in var.backup_policies : backup_policy => merge(flatten([
      for template_name in config.template_policies : [
        jsondecode(templatefile(
          "./${var.template_policies_folders.backup_policy}/${template_name}${var.template_file_suffix.backup_policy}",
          merge(var.template_vars, config.template_vars)
        ))
      ]
    ])...)
  }

  # Combine standard_policies & templated_policies lists to create the final Statement array for each BACKUP_POLICY
  backup_combined_policies = {
    for backup_policy, config in var.backup_policies : backup_policy => merge([local.backup_standard_policies[backup_policy], local.backup_templated_policies[backup_policy]]...)
  }

  # Pre-proccess & build BACKUP_POLICY attachments and BACKUP_POLICY target pairings
  backup_policy_attachments = flatten([
    for backup_policy, config in var.backup_policies : [
      for ou in config.target : {
        backup_policy_name = backup_policy
        target             = ou
      }
    ]
  ])
}

# Terraform Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy
resource "aws_organizations_policy" "backup_policies" {
  for_each = var.backup_policies

  name        = each.value.name
  description = each.value.description
  type        = "BACKUP_POLICY"

  # Use backup_policy_template.json.tpl to format the policy statements
  content = templatefile("${path.module}/policy-templates/backup_policy_template.json.tpl", {
    statement = jsonencode(local.backup_combined_policies[each.key])
  })
}

# Terraform Resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment
# Attach each BACKUP_POLICY to each specified target
resource "aws_organizations_policy_attachment" "backup_policy_attachment" {
  for_each = { for attachment in local.backup_policy_attachments : "${attachment.backup_policy_name}-${attachment.target}" => attachment }

  policy_id = aws_organizations_policy.backup_policies[each.value.backup_policy_name].id
  target_id = each.value.target
}
