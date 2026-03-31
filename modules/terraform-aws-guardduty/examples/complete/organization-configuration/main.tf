module "guardduty" {
  source = "../../../"

  # Flag to disable all GuardDuty features and remove all member accounts
  # GuardDuty in memeber accounts will be left in a state of SUSPENDED
  disable_guardduty_members = false

  # Enable GuardDuty for the entire AWS Organization
  enable_organization_configuration          = true
  guardduty_auto_enable_organization_members = "ALL"

  # Enable GuardDuty findings export to S3
  enable_guardduty_findings_export_to_s3 = true
  findings_export_s3_bucket_arn          = "arn:aws:s3:::guardduty-882382790229-us-east-1-findings-export"
  findings_export_kms_key_arn            = "arn:aws:kms:us-east-1:882382790229:key/40919225-f0a8-47c1-a2c6-5d1672558ee1"


  # Controls what GuardDuty features are enabled in the Organization Member accounts
  # You can omit or reduce this block depending on what features you want to set
  guardduty_organization_features = {
    S3_DATA_EVENTS         = { enabled = true, auto_enable_feature_configuration = "NEW" }
    EKS_AUDIT_LOGS         = { enabled = true, auto_enable_feature_configuration = "NEW" }
    EBS_MALWARE_PROTECTION = { enabled = true, auto_enable_feature_configuration = "NEW" }
    RDS_LOGIN_EVENTS       = { enabled = true, auto_enable_feature_configuration = "NEW" }
    LAMBDA_NETWORK_LOGS    = { enabled = true, auto_enable_feature_configuration = "NEW" }

    # EKS_RUNTIME_MONITORING or RUNTIME_MONITORING can be added, adding both features will cause an error.
    RUNTIME_MONITORING = {
      enabled                           = true
      auto_enable_feature_configuration = "NEW"
      additional_configuration = [
        {
          name = "ECS_FARGATE_AGENT_MANAGEMENT"
        },
        {
          name = "EC2_AGENT_MANAGEMENT"
        },
        {
          name        = "EKS_ADDON_MANAGEMENT"
          auto_enable = "NONE" # This disables the feature, remove this line to enable the feature
        }
      ]
    }
    # EKS_RUNTIME_MONITORING = {
    #   enabled = true
    #   auto_enable_feature_configuration = "NEW"
    #   additional_configuration = [
    #     {
    #       name = "EKS_ADDON_MANAGEMENT"
    #     }
    #   ]
    # }
  }

  # If you want to set features for the delegated admin account
  # that are different from the organization features,
  # you can do so here.
  #
  # This is useful if you want to disable/enable features explicitly for the delegated admin account
  # but usually you will want to use the same features that are set in guardduty_organization_features
  guardduty_admin_account_features = {
    S3_DATA_EVENTS         = { enabled = false }
    EKS_AUDIT_LOGS         = { enabled = false }
    EBS_MALWARE_PROTECTION = { enabled = false }
    RDS_LOGIN_EVENTS       = { enabled = false }
    LAMBDA_NETWORK_LOGS    = { enabled = false }

    # EKS_RUNTIME_MONITORING or RUNTIME_MONITORING can be added, adding both features will cause an error.
    RUNTIME_MONITORING = {
      enabled = false
      additional_configuration = [
        {
          name   = "EKS_ADDON_MANAGEMENT"
          status = "DISABLED"
        },
        {
          name   = "ECS_FARGATE_AGENT_MANAGEMENT"
          status = "DISABLED"
        },
        {
          name   = "EC2_AGENT_MANAGEMENT"
          status = "DISABLED"
        }
      ]
    }
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

  # Create Trusted IP list
  # You can add Individual IPs or IP Ranges in trusted-ips.txt
  # to create a list of trusted IPs in the organization
  # ipset_config = [
  #   {
  #     activate  = true
  #     name      = "test-ipset"
  #     format    = "TXT"
  #     bucket_id = "test-ipset-s3-bucket"
  #     file_path = "${path.module}/guardduty/trusted-ips.txt"
  #     key       = "test-ipset.txt"
  #   }
  # ]

  # Create Known Malicious IP list
  # You can add Individual IPs or IP Ranges in known-malicious-ips.txt
  # to create a list of known malicious IPs to monitor for in the organization
  # threatintelset_config = [
  #   {
  #     activate   = true
  #     name       = "test-threatintelset"
  #     format     = "TXT"
  #     bucket_id  = "test-threatintelset-s3-bucket"
  #     file_path  = "${path.module}/guardduty/known-malicious-ips.txt"
  #     key        = "test-threatintelset.txt"
  #     object_acl = "private"
  #   }
  # ]

  # Apply tags
  tags = {
    Environment = "Test"
    Project     = "GuardDuty Testing"
  }
}
