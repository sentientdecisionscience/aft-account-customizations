data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

module "guardduty" {
  source = "../../"

  # Enable GuardDuty for the entire AWS Organization
  enable_organization_configuration          = true
  guardduty_auto_enable_organization_members = "ALL"

  # Enable GuardDuty findings export to S3
  enable_guardduty_findings_export_to_s3 = true
  findings_export_s3_bucket_arn          = aws_s3_bucket.guardduty_findings_export_bucket.arn
  findings_export_kms_key_arn            = aws_kms_key.guardduty_findings_export_key.arn

  # Controls what GuardDuty features are enabled in the Organization Member accounts
  guardduty_organization_features = {
    S3_DATA_EVENTS         = { enabled = true, auto_enable_feature_configuration = "NEW" }
    EKS_AUDIT_LOGS         = { enabled = true, auto_enable_feature_configuration = "NEW" }
    EBS_MALWARE_PROTECTION = { enabled = true, auto_enable_feature_configuration = "NEW" }
    RDS_LOGIN_EVENTS       = { enabled = true, auto_enable_feature_configuration = "NEW" }
    LAMBDA_NETWORK_LOGS    = { enabled = true, auto_enable_feature_configuration = "NEW" }
  }

  # Create Trusted IP list
  # You can add Individual IPs or IP Ranges in trusted-ips.txt
  # to create a list of trusted IPs in the organization
  ipset_config = [
    {
      activate  = true
      name      = "example-ipset"
      format    = "TXT"
      bucket_id = aws_s3_bucket.guardduty_ip_lists_bucket.id
      file_path = "${path.module}/guardduty/ip-sets/trusted-ips.txt"
      key       = "IPSet/example-ipset.txt"
    }
  ]

  # Create Known Malicious IP list
  # You can add Individual IPs or IP Ranges in known-malicious-ips.txt
  # to create a list of known malicious IPs to monitor for in the organization
  threatintelset_config = [
    {
      activate   = true
      name       = "example-threatintelset"
      format     = "TXT"
      bucket_id  = aws_s3_bucket.guardduty_ip_lists_bucket.id
      file_path  = "${path.module}/guardduty/threat-intel-sets/known-malicious-ips.txt"
      key        = "ThreatIntelSet/example-threatintelset.txt"
      object_acl = "private"
    }
  ]

  depends_on = [
    aws_s3_bucket_policy.guardduty_ip_lists_bucket_policy
  ]
}

#############################################################################
#                       IPSet & ThreatIntelSet Bucket
#############################################################################

# IP Lists S3 Bucket
resource "aws_s3_bucket" "guardduty_ip_lists_bucket" {
  bucket        = "guardduty-${data.aws_region.current.region}-ip-lists-${data.aws_caller_identity.current.account_id}"
  force_destroy = false
}

# Bucket Policy Definition
resource "aws_s3_bucket_policy" "guardduty_ip_lists_bucket_policy" {
  bucket = aws_s3_bucket.guardduty_ip_lists_bucket.id
  policy = templatefile("${path.module}/guardduty/ip-lists/s3-bucket-policy.json.tftpl", {
    S3_BUCKET_ARN = aws_s3_bucket.guardduty_ip_lists_bucket.arn
  })
}

# Enable versioning
resource "aws_s3_bucket_versioning" "guardduty_ip_lists_bucket_versioning" {
  bucket = aws_s3_bucket.guardduty_ip_lists_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server side encryption on IPset bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "guardduty_ip_lists_bucket_encryption" {
  bucket = aws_s3_bucket.guardduty_ip_lists_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
