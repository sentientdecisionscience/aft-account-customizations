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

  depends_on = [
    aws_s3_bucket_policy.guardduty_bucket_policy,
    aws_kms_key_policy.guardduty_kms_policy
  ]
}

#############################################################################
#        GuardDuty Export Findings Resources (S3 & KMS)
#############################################################################
data "aws_guardduty_detector" "home_region" {}

# S3 Bucket for GuardDuty Findings Export
resource "aws_s3_bucket" "guardduty_findings_export" {
  bucket        = "guardduty-${data.aws_region.current.region}-findings-export-${data.aws_caller_identity.current.account_id}"
  force_destroy = false
}

# Attach bucket policy
resource "aws_s3_bucket_policy" "guardduty_bucket_policy" {
  bucket = aws_s3_bucket.guardduty_findings_export.id

  policy = templatefile("${path.module}/guardduty/s3-bucket-policy.json.tftpl", {
    S3_BUCKET_ARN = aws_s3_bucket.guardduty_findings_export.arn
    KMS_KEY_ARN   = aws_kms_key.guardduty_findings_export.arn
    DETECTOR_ARN  = data.aws_guardduty_detector.home_region.arn
    REGION        = data.aws_region.current.region
    ACCOUNT_ID    = data.aws_caller_identity.current.account_id
  })

  depends_on = [aws_kms_key.guardduty_findings_export]
}

# Enable versioning on S3 bucket
resource "aws_s3_bucket_versioning" "guardduty_bucket_versioning" {
  bucket = aws_s3_bucket.guardduty_findings_export.id

  versioning_configuration {
    status = "Enabled"
  }
}

# SSE KMS Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "guardduty_bucket_encryption" {
  bucket = aws_s3_bucket.guardduty_findings_export.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.guardduty_findings_export.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# KMS Key for GuardDuty Encryption when exporting findings to S3
resource "aws_kms_key" "guardduty_findings_export" {
  description             = "KMS Key for encrypting GuardDuty Findings Exports to S3 in ${data.aws_region.current.region}."
  deletion_window_in_days = 7
  is_enabled              = true
  enable_key_rotation     = true
  multi_region            = false
}

# KMS Alias
resource "aws_kms_alias" "guardduty_findings_export_alias" {
  name          = "alias/guardduty-findings-export"
  target_key_id = aws_kms_key.guardduty_findings_export.id
}

# KMS Key Policy
resource "aws_kms_key_policy" "guardduty_kms_policy" {
  key_id = aws_kms_key.guardduty_findings_export.id

  policy = templatefile("${path.module}/guardduty/kms-key-policy.json.tftpl", {
    KMS_KEY_ARN  = aws_kms_key.guardduty_findings_export.arn
    DETECTOR_ARN = data.aws_guardduty_detector.home_region.arn
    REGION       = data.aws_region.current.region
    ACCOUNT_ID   = data.aws_caller_identity.current.account_id
  })
}
