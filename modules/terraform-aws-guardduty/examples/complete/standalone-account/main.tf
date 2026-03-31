module "guardduty" {
  source = "../../../"

  # Deploys GuardDuty in standalone account
  enable_organization_configuration = false

  # Enable GuardDuty findings export to S3
  enable_guardduty_findings_export_to_s3 = true
  findings_export_s3_bucket_arn          = "arn:aws:s3:::guardduty-882382790229-us-east-1-findings-export"
  findings_export_kms_key_arn            = "arn:aws:kms:us-east-1:882382790229:key/40919225-f0a8-47c1-a2c6-5d1672558ee1"

  # Enable GuardDuty features
  guardduty_admin_account_features = {
    S3_DATA_EVENTS         = { status = "ENABLED" }
    EKS_AUDIT_LOGS         = { status = "ENABLED" }
    EBS_MALWARE_PROTECTION = { status = "ENABLED" }
    RDS_LOGIN_EVENTS       = { status = "ENABLED" }
    LAMBDA_NETWORK_LOGS    = { status = "ENABLED" }

    # EKS_RUNTIME_MONITORING or RUNTIME_MONITORING can be added, adding both features will cause an error.
    RUNTIME_MONITORING = {
      status = "ENABLED"
      additional_configuration = [
        {
          name   = "EKS_ADDON_MANAGEMENT"
          status = "DISABLED"
        },
        {
          name = "EC2_AGENT_MANAGEMENT"
        },
        {
          name   = "ECS_FARGATE_AGENT_MANAGEMENT"
          status = "DISABLED" # This disables the feature, remove this line to enable the feature
        }
      ]
    }
    # EKS_RUNTIME_MONITORING = {
    #   status = "ENABLED"
    #   additional_configuration = [
    #     {
    #       name = "EKS_ADDON_MANAGEMENT"
    #     }
    #   ]
    # }
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
