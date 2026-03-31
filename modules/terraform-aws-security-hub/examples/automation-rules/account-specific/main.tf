provider "aws" {
  region = "us-east-1"
}

module "automation_rules" {
  source = "../../../modules/automation-rules"

  automation_rules = [
    {
      rule_name   = "suppress-findings-from-sandbox-account"
      description = "Automatically suppress all findings from the sandbox account"
      rule_order  = 1
      # Target specific AWS account
      aws_account_ids = [var.sandbox_account_id]
      # Only suppress failed findings
      compliance_status = "FAILED"
      action_type       = "FINDING_FIELDS_UPDATE"
      finding_fields_update = {
        workflow_status = "SUPPRESSED"
      }
    },
    {
      rule_name   = "suppress-specific-product-findings"
      description = "Suppress findings from specific security products"
      rule_order  = 2
      # Target specific security products
      product_names = var.product_names
      # Only for specified severity
      severity_labels = var.severity_levels
      action_type     = "FINDING_FIELDS_UPDATE"
      finding_fields_update = {
        workflow_status = "SUPPRESSED"
      }
    }
  ]
}
