#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_automation_rule
resource "aws_securityhub_automation_rule" "this" {
  for_each = { for rule in var.automation_rules : rule.rule_name => rule }

  rule_name   = each.value.rule_name
  description = each.value.description
  rule_order  = each.value.rule_order

  criteria {
    # AWS Account ID criteria
    dynamic "aws_account_id" {
      for_each = length(each.value.aws_account_ids) > 0 ? each.value.aws_account_ids : []
      content {
        comparison = "EQUALS"
        value      = aws_account_id.value
      }
    }

    # Severity label criteria
    dynamic "severity_label" {
      for_each = length(each.value.severity_labels) > 0 ? each.value.severity_labels : []
      content {
        comparison = "EQUALS"
        value      = severity_label.value
      }
    }

    # Resource type criteria
    dynamic "resource_type" {
      for_each = length(each.value.resource_types) > 0 ? each.value.resource_types : []
      content {
        comparison = "EQUALS"
        value      = resource_type.value
      }
    }

    # Generator ID criteria
    dynamic "generator_id" {
      for_each = length(each.value.generator_ids) > 0 ? each.value.generator_ids : []
      content {
        comparison = "PREFIX"
        value      = generator_id.value
      }
    }

    # Compliance status criteria
    dynamic "compliance_status" {
      for_each = each.value.compliance_status != null ? [each.value.compliance_status] : []
      content {
        comparison = "EQUALS"
        value      = compliance_status.value
      }
    }

    # Record state criteria
    dynamic "record_state" {
      for_each = each.value.record_state != null ? [each.value.record_state] : []
      content {
        comparison = "EQUALS"
        value      = record_state.value
      }
    }

    # Product name criteria
    dynamic "product_name" {
      for_each = length(each.value.product_names) > 0 ? each.value.product_names : []
      content {
        comparison = "EQUALS"
        value      = product_name.value
      }
    }

    # Product ARN criteria
    dynamic "product_arn" {
      for_each = length(each.value.product_arns) > 0 ? each.value.product_arns : []
      content {
        comparison = "EQUALS"
        value      = product_arn.value
      }
    }

    # Title criteria
    dynamic "title" {
      for_each = each.value.title != null ? [each.value.title] : []
      content {
        comparison = "PREFIX"
        value      = title.value
      }
    }

    # Description criteria
    dynamic "description" {
      for_each = each.value.description_criteria != null ? [each.value.description_criteria] : []
      content {
        comparison = "PREFIX"
        value      = description.value
      }
    }

    # Workflow status criteria
    dynamic "workflow_status" {
      for_each = each.value.workflow_status != null ? [each.value.workflow_status] : []
      content {
        comparison = "EQUALS"
        value      = workflow_status.value
      }
    }
  }

  actions {
    type = each.value.action_type
    finding_fields_update {
      workflow {
        status = each.value.finding_fields_update.workflow_status
      }
    }
  }
}
