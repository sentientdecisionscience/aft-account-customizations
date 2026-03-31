provider "aws" {
  region = "us-east-1"
}

module "automation_rules" {
  source = "../../../modules/automation-rules"

  automation_rules = [
    {
      rule_name       = "suppress-low-priority-findings"
      description     = "Automatically suppress low and informational severity findings"
      rule_order      = 1
      severity_labels = ["LOW", "INFORMATIONAL"]
      action_type     = "FINDING_FIELDS_UPDATE"
      finding_fields_update = {
        workflow_status = "SUPPRESSED"
      }
    },
    {
      rule_name       = "suppress-non-iam-medium-findings"
      description     = "Suppress medium severity findings for specific resource types"
      rule_order      = 2
      severity_labels = ["MEDIUM"]
      resource_types  = ["AwsEc2Instance", "AwsS3Bucket", "AwsRdsDbInstance"]
      action_type     = "FINDING_FIELDS_UPDATE"
      finding_fields_update = {
        workflow_status = "SUPPRESSED"
      }
    }
  ]
}
