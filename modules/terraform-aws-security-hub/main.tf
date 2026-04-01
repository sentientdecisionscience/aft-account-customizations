#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_account
resource "aws_securityhub_account" "main" {
  count = var.organization_configuration.configuration_type == "LOCAL" ? 1 : 0
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_standards_subscription
resource "aws_securityhub_standards_subscription" "standards_subscription" {
  for_each = { for arn in var.enabled_standard_arns : arn => arn }

  standards_arn = each.value
  depends_on    = [aws_securityhub_account.main]
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_finding_aggregator
resource "aws_securityhub_finding_aggregator" "finding_aggregator" {
  count             = var.finding_aggregator != null ? 1 : 0
  linking_mode      = var.finding_aggregator.linking_mode
  specified_regions = var.finding_aggregator.specified_regions

  depends_on = [aws_securityhub_account.main]
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_organization_configuration
resource "aws_securityhub_organization_configuration" "organization_configuration" {
  count = var.organization_configuration.configuration_type == "CENTRAL" ? 1 : 0

  auto_enable           = var.organization_configuration.auto_enable
  auto_enable_standards = var.organization_configuration.auto_enable_standards

  organization_configuration {
    configuration_type = var.organization_configuration.configuration_type
  }

  depends_on = [aws_securityhub_finding_aggregator.finding_aggregator]
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_member
resource "aws_securityhub_member" "members" {
  for_each   = var.organization_configuration.configuration_type == "LOCAL" ? { for id in var.member_account_ids : id => id } : {}
  account_id = each.value

  lifecycle {
    ignore_changes = [email, invite]
  }

  depends_on = [aws_securityhub_account.main]
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_configuration_policy
resource "aws_securityhub_configuration_policy" "config_policy" {
  for_each = {
    for policy in var.configuration_policy : policy.target_id != null ? policy.target_id : "default" => policy
  }

  name        = "${each.key}-configuration-policy"
  description = each.key == "default" ? "Default configuration policy for all accounts without specific targets" : "Configuration policy for target ${each.key}"

  configuration_policy {
    service_enabled       = each.value.service_enabled
    enabled_standard_arns = each.value.enabled_standard_arns

    # Optional security controls configuration
    dynamic "security_controls_configuration" {
      for_each = each.value.security_controls_configuration != null && each.value.service_enabled != false ? [each.value.security_controls_configuration] : []
      content {
        disabled_control_identifiers = security_controls_configuration.value.disabled_control_identifiers
        enabled_control_identifiers  = security_controls_configuration.value.enabled_control_identifiers

        # Nested parameters for custom controls
        dynamic "security_control_custom_parameter" {
          for_each = security_controls_configuration.value.security_control_custom_parameters != null ? security_controls_configuration.value.security_control_custom_parameters : []
          content {
            security_control_id = security_control_custom_parameter.value.security_control_id
            dynamic "parameter" {
              for_each = security_control_custom_parameter.value.parameter
              content {
                name       = parameter.value.name
                value_type = parameter.value.value_type
                dynamic "bool" {
                  for_each = parameter.value.bool != null ? [parameter.value.bool] : []
                  content {
                    value = bool.value
                  }
                }
                dynamic "double" {
                  for_each = parameter.value.double != null ? [parameter.value.double] : []
                  content {
                    value = double.value
                  }
                }
                dynamic "enum" {
                  for_each = parameter.value.enum != null ? [parameter.value.enum] : []
                  content {
                    value = enum.value
                  }
                }
                dynamic "enum_list" {
                  for_each = parameter.value.enum_list != null ? [parameter.value.enum_list] : []
                  content {
                    value = enum_list.value
                  }
                }
                dynamic "int" {
                  for_each = parameter.value.int != null ? [parameter.value.int] : []
                  content {
                    value = int.value
                  }
                }
                dynamic "int_list" {
                  for_each = parameter.value.int_list != null ? [parameter.value.int_list] : []
                  content {
                    value = int_list.value
                  }
                }
                dynamic "string" {
                  for_each = parameter.value.string != null ? [parameter.value.string] : []
                  content {
                    value = string.value
                  }
                }
                dynamic "string_list" {
                  for_each = parameter.value.string_list != null ? [parameter.value.string_list] : []
                  content {
                    value = string_list.value
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  depends_on = [aws_securityhub_organization_configuration.organization_configuration]
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_configuration_policy_association
resource "aws_securityhub_configuration_policy_association" "policy_association" {
  for_each = tomap({
    for idx, policy in var.configuration_policy :
    policy.target_id => policy if policy.target_id != null
  })

  policy_id = aws_securityhub_configuration_policy.config_policy[each.key].id
  target_id = each.key

  timeouts {
    create = "10m"
    update = "10m"
  }

  depends_on = [aws_securityhub_configuration_policy.config_policy]
}
