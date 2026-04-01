#################################################### IMPORTANT #####################################################
# GuardDuty is deployed here with an organization-wide configuration.
#
# GuardDuty is a REGIONAL service.
#
# A pre-requisite to this deployment style is to first go to the Organization Management account and
# delegate administration of GuardDuty to this (Audit) account.
#
# Not all module features are deployed, be sure to check the module for all available features & more information.
####################################################################################################################

module "guardduty" {
  source = "../../../modules/terraform-aws-guardduty"

  # This module input is defaulted to false and is shown here for visibility.
  # Set this input to true when removing GuardDuty from your organization.
  # Flag to disable all GuardDuty features and remove all member accounts
  # GuardDuty in memeber accounts will be left in a state of SUSPENDED
  # disable_guardduty_members = false

  # Enable GuardDuty for the entire AWS Organization
  enable_organization_configuration          = true
  guardduty_auto_enable_organization_members = "ALL"

  # Enable GuardDuty findings export to S3
  enable_guardduty_findings_export_to_s3 = true
  findings_export_s3_bucket_arn          = aws_s3_bucket.guardduty_bucket.arn
  findings_export_kms_key_arn            = aws_kms_key.guardduty_key.arn

  # Controls what GuardDuty features are enabled in the Organization Member accounts
  # You can omit or reduce this block depending on what features you want to set
  guardduty_organization_features = {
    S3_DATA_EVENTS = { enabled = true, auto_enable_feature_configuration = "ALL" }
    #EKS_AUDIT_LOGS        = { enabled = true, auto_enable_feature_configuration = "ALL" }
    EBS_MALWARE_PROTECTION = { enabled = true, auto_enable_feature_configuration = "ALL" }
    RDS_LOGIN_EVENTS       = { enabled = true, auto_enable_feature_configuration = "ALL" }
    LAMBDA_NETWORK_LOGS    = { enabled = true, auto_enable_feature_configuration = "ALL" }

  }

  # GuardDuty Filter - Example: Archive findings with severity < 2.0
  filter_config = [
    {
      name        = "LowSeverityArchive"
      description = "Archives findings with severity below 2"
      rank        = 1
      action      = "ARCHIVE"
      criterion = [
        {
          field     = "severity"
          less_than = 2
        }
      ]
    }
  ]

}
