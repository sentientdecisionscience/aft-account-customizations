output "detector_arn" {
  value = var.enable_organization_configuration ? data.aws_guardduty_detector.organization_detector[0].arn : aws_guardduty_detector.standalone_account_guardduty_detector[0].arn
}

output "detector_id" {
  value = var.enable_organization_configuration ? data.aws_guardduty_detector.organization_detector[0].id : aws_guardduty_detector.standalone_account_guardduty_detector[0].id
}
