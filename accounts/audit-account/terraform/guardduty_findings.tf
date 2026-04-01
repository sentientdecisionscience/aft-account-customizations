# Retrieves the detector ID in Organization configuration
data "aws_guardduty_detector" "organization_detector" {}

# S3 Bucket for GuardDuty Findings Export
resource "aws_s3_bucket" "guardduty_bucket" {
  bucket        = "guardduty-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-findings-export"
  force_destroy = false
}

# Enable versioning on S3 bucket
resource "aws_s3_bucket_versioning" "guardduty_bucket_versioning" {
  bucket = aws_s3_bucket.guardduty_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# SSE KMS Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "guardduty_bucket_encryption" {
  bucket = aws_s3_bucket.guardduty_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.guardduty_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Attach bucket policy
resource "aws_s3_bucket_policy" "guardduty_bucket_policy" {
  bucket = aws_s3_bucket.guardduty_bucket.id
  policy = data.aws_iam_policy_document.guardduty_findings_export_bucket_policy.json
}

# Apply Public Access Block settings
resource "aws_s3_bucket_public_access_block" "guardduty_bucket_public_access_block" {
  bucket = aws_s3_bucket.guardduty_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy
data "aws_iam_policy_document" "guardduty_findings_export_bucket_policy" {
  statement {
    sid    = "AllowGuardDutyGetBucketLocation"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }

    actions   = ["s3:GetBucketLocation"]
    resources = [aws_s3_bucket.guardduty_bucket.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values = [
        data.aws_guardduty_detector.organization_detector.arn
      ]
    }
  }

  statement {
    sid    = "AllowGuardDutyPutObject"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.guardduty_bucket.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values = [
        data.aws_guardduty_detector.organization_detector.arn
      ]
    }
  }

  statement {
    sid    = "DenyUnencryptedObjectUploads"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.guardduty_bucket.arn}/*"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }

  statement {
    sid    = "DenyIncorrectEncryptionHeader"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.guardduty_bucket.arn}/*"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [aws_kms_key.guardduty_key.arn]
    }
  }

  statement {
    sid    = "DenyNonHTTPSAccess"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:*"]
    resources = ["${aws_s3_bucket.guardduty_bucket.arn}/*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

#############################################################################
#                               KMS
#############################################################################
# KMS Key for GuardDuty Encryption when exporting findings to S3
resource "aws_kms_key" "guardduty_key" {
  description             = "AWS KMS Key for Amazon GuardDuty Bucket encryption in ${data.aws_region.current.region}."
  deletion_window_in_days = 7
  is_enabled              = true
  enable_key_rotation     = true
  multi_region            = false
}

# KMS Key Policy (Attach Policy Separately to Avoid Circular Dependency)
resource "aws_kms_key_policy" "guardduty_kms_policy" {
  key_id = aws_kms_key.guardduty_key.id
  policy = data.aws_iam_policy_document.guardduty_kms_policy.json
}

# Create KMS Alias for Easier Management
resource "aws_kms_alias" "guardduty_key_alias" {
  name          = "alias/guardduty-${data.aws_region.current.region}"
  target_key_id = aws_kms_key.guardduty_key.id
}

# KMS Key Policy
data "aws_iam_policy_document" "guardduty_kms_policy" {
  statement {
    sid    = "AllowRootAccountAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = [aws_kms_key.guardduty_key.arn]
  }

  statement {
    sid    = "AllowGuardDutyToUseKey"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }

    actions = [
      "kms:GenerateDataKey"
    ]

    resources = [aws_kms_key.guardduty_key.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values = [
        data.aws_guardduty_detector.organization_detector.arn
      ]
    }
  }

  statement {
    sid    = "AllowS3ToUseKey"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = [aws_kms_key.guardduty_key.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}
