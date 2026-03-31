data "aws_organizations_organization" "current" {}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_organization_conformance_pack
resource "aws_config_organization_conformance_pack" "org_conformance_pack" {
  for_each = { for pack in var.conformance_packs : pack.name => pack if pack.deployment_mode == "ORGANIZATION" }

  name               = each.key
  delivery_s3_bucket = var.delivery_bucket_name
  template_body      = try(data.http.main[each.key].response_body, each.value.template)
  template_s3_uri    = each.value.template_s3_uri

  excluded_accounts = each.value.include_mgmt_account ? [for account in each.value.excluded_accounts : account if account != data.aws_organizations_organization.current.master_account_id] : toset(concat([data.aws_organizations_organization.current.master_account_id], each.value.excluded_accounts))
  dynamic "input_parameter" {
    for_each = each.value.input_parameters
    content {
      parameter_name  = input_parameter.key
      parameter_value = input_parameter.value
    }
  }
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_conformance_pack
resource "aws_config_conformance_pack" "conformance_pack" {
  for_each = { for pack in var.conformance_packs : pack.name => pack if pack.deployment_mode == "LOCAL" }

  name               = each.key
  delivery_s3_bucket = var.delivery_bucket_name
  template_body      = try(data.http.main[each.key].response_body, each.value.template)
  template_s3_uri    = each.value.template_s3_uri

  dynamic "input_parameter" {
    for_each = each.value.input_parameters
    content {
      parameter_name  = input_parameter.key
      parameter_value = input_parameter.value
    }
  }
}

data "http" "main" {
  # Loop through a merged list of conformance pack types with their enabled status.
  for_each = { for pack in var.conformance_packs : pack.name => pack.template_url if pack.template_url != null }

  # Retrieve the conformance pack YAML file from the URL based on the loop key.
  url = each.value

  # Set the expected file format.
  request_headers = {
    Accept = "application/yaml"
  }

  # Set a post-condition check to ensure the HTTP status code is 200.
  lifecycle {
    postcondition {
      condition     = contains([200], self.status_code)
      error_message = "Status code invalid. Please check conformaces pack names."
    }
  }
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_config_rule
resource "aws_config_config_rule" "config_rule" {
  for_each = { for rule in var.config_rules : rule.name => rule if rule.deployment_mode == "LOCAL" }

  name        = each.key
  description = each.value.description
  dynamic "evaluation_mode" {
    for_each = each.value.evaluation_mode != null ? [1] : []
    content {
      mode = each.value.evaluation_mode
    }
  }

  maximum_execution_frequency = each.value.maximum_execution_frequency
  dynamic "scope" {
    for_each = each.value.scope != null ? [1] : []
    content {
      compliance_resource_id    = each.value.scope.compliance_resource_id
      compliance_resource_types = each.value.scope.compliance_resource_types
      tag_key                   = each.value.scope.tag_key
      tag_value                 = each.value.scope.tag_value
    }
  }
  dynamic "source" {
    for_each = each.value.source != null ? [1] : []
    content {
      owner             = each.value.source.owner
      source_identifier = each.value.source.source_identifier
      dynamic "source_detail" {
        for_each = each.value.source.source_detail != null ? [1] : []
        content {
          event_source = each.value.source.source_detail.event_source
          message_type = each.value.source.source_detail.message_type
        }
      }
      dynamic "custom_policy_details" {
        for_each = each.value.source.custom_policy_details != null ? [1] : []
        content {
          policy_runtime = each.value.source.custom_policy_details.policy_runtime
          policy_text    = each.value.source.custom_policy_details.policy_text
        }
      }
    }
  }

}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_organization_managed_rule
resource "aws_config_organization_managed_rule" "org_managed_config_rule" {
  for_each = { for rule in var.config_rules : rule.name => rule if rule.deployment_mode == "ORGANIZATION" && rule.source.owner == "AWS" }

  name        = each.key
  description = each.value.description

  rule_identifier             = each.value.source.source_identifier
  maximum_execution_frequency = each.value.maximum_execution_frequency
  resource_id_scope           = each.value.scope.compliance_resource_id
  resource_types_scope        = each.value.scope.compliance_resource_types
  tag_key_scope               = each.value.scope.tag_key
  tag_value_scope             = each.value.scope.tag_value

  excluded_accounts = each.value.include_mgmt_account ? [for account in each.value.excluded_accounts : account if account != data.aws_organizations_organization.current.master_account_id] : toset(concat([data.aws_organizations_organization.current.master_account_id], each.value.excluded_accounts))
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_organization_custom_policy_rule
resource "aws_config_organization_custom_policy_rule" "org_custom_config_rule" {
  for_each = { for rule in var.config_rules : rule.name => rule if rule.deployment_mode == "ORGANIZATION" && rule.source.owner == "CUSTOM_POLICY" }

  name        = each.key
  description = each.value.description

  maximum_execution_frequency = each.value.maximum_execution_frequency
  resource_id_scope           = each.value.scope.compliance_resource_id
  resource_types_scope        = each.value.scope.compliance_resource_types
  tag_key_scope               = each.value.scope.tag_key
  tag_value_scope             = each.value.scope.tag_value
  trigger_types               = [each.value.source.source_detail.message_type]
  policy_text                 = each.value.source.custom_policy_details.policy_text
  policy_runtime              = each.value.source.custom_policy_details.policy_runtime

  excluded_accounts = each.value.include_mgmt_account ? [for account in each.value.excluded_accounts : account if account != data.aws_organizations_organization.current.master_account_id] : toset(concat([data.aws_organizations_organization.current.master_account_id], each.value.excluded_accounts))
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_organization_custom_rule
resource "aws_config_organization_custom_rule" "org_custom_lambda_config_rule" {
  for_each = { for rule in var.config_rules : rule.name => rule if rule.deployment_mode == "ORGANIZATION" && rule.source.owner == "CUSTOM_LAMBDA" }

  name        = each.key
  description = each.value.description

  lambda_function_arn         = each.value.source.source_identifier
  trigger_types               = [each.value.source.source_detail.message_type]
  maximum_execution_frequency = each.value.maximum_execution_frequency
  resource_id_scope           = each.value.scope.compliance_resource_id
  resource_types_scope        = each.value.scope.compliance_resource_types
  tag_key_scope               = each.value.scope.tag_key
  tag_value_scope             = each.value.scope.tag_value

  excluded_accounts = each.value.include_mgmt_account ? [for account in each.value.excluded_accounts : account if account != data.aws_organizations_organization.current.master_account_id] : toset(concat([data.aws_organizations_organization.current.master_account_id], each.value.excluded_accounts))
}
