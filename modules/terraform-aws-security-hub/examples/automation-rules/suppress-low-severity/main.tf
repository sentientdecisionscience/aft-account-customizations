provider "aws" {
  region = "us-east-1"
}

module "automation_rules" {
  source = "../../../modules/automation-rules"

  automation_rules = [
    {
      rule_name       = "suppress-low-severity-findings"
      description     = "Automatically suppress all low severity findings"
      rule_order      = 1
      severity_labels = ["LOW"]
      action_type     = "FINDING_FIELDS_UPDATE"
      finding_fields_update = {
        workflow_status = "SUPPRESSED"
      }
    }
  ]
}
