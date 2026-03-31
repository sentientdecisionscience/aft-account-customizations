module "security_hub" {
  source = "../../../"

  finding_aggregator = {
    linking_mode      = "SPECIFIED_REGIONS"
    specified_regions = ["us-west-2"]
  }

  enabled_standard_arns = ["arn:aws:securityhub:us-east-1::standards/aws-resource-tagging-standard/v/1.0.0"]
}
