# GuardDuty Publishing Destination
resource "aws_guardduty_publishing_destination" "guardduty_publishing_destination" {
  count = var.enable_guardduty_findings_export_to_s3 ? 1 : 0

  detector_id      = var.enable_organization_configuration ? data.aws_guardduty_detector.organization_detector[0].id : aws_guardduty_detector.standalone_account_guardduty_detector[0].id
  destination_arn  = var.findings_export_s3_bucket_arn
  kms_key_arn      = var.findings_export_kms_key_arn
  destination_type = "S3"
}
