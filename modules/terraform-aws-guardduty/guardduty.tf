#######################################################################################################################
#                                             GuardDuty Detector
#
# A GuardDuty Detector is created automatically when the Management Account sets a GuardDuty Delegated Administrator
# This module assumes it will be run from the Delegated Administrator account when using the Organization configuration
#
# We create a GuardDuty Detector when running in a standalone account
#######################################################################################################################

# Retrieves the detector ID in Organization configuration
data "aws_guardduty_detector" "organization_detector" {
  count = var.enable_organization_configuration ? 1 : 0
}

# Creates GuardDuty Detector for standalone account
resource "aws_guardduty_detector" "standalone_account_guardduty_detector" {
  count = !var.enable_organization_configuration ? 1 : 0

  enable                       = true
  finding_publishing_frequency = var.finding_publishing_frequency
}

####################################################################################################################
#                                              GuardDuty Features
#
# Controls what Guardduty features are enabled in the delegated admin account or standalone account
####################################################################################################################

# Controls what Guardduty features are enabled in the delegated admin account or standalone account
resource "aws_guardduty_detector_feature" "guardduty_features" {
  for_each = { for key, value in var.guardduty_admin_account_features : key => value if value.enabled }

  detector_id = var.enable_organization_configuration ? data.aws_guardduty_detector.organization_detector[0].id : aws_guardduty_detector.standalone_account_guardduty_detector[0].id

  name   = each.key
  status = var.disable_guardduty_members ? "DISABLED" : "ENABLED"

  dynamic "additional_configuration" {
    for_each = each.value.additional_configuration != null ? { for idx, config in each.value.additional_configuration : idx => config } : {}
    content {
      name   = additional_configuration.value.name
      status = var.disable_guardduty_members ? "DISABLED" : additional_configuration.value.status
    }
  }
}

# Controls if Organization accounts have GuardDuty automatically enabled
resource "aws_guardduty_organization_configuration" "guardduty_organization_configuration" {
  count = var.enable_organization_configuration ? 1 : 0

  auto_enable_organization_members = var.disable_guardduty_members ? "NONE" : var.guardduty_auto_enable_organization_members
  detector_id                      = data.aws_guardduty_detector.organization_detector[0].id
}

# Controls what Guardduty features are enabled in the Organization accounts
resource "aws_guardduty_organization_configuration_feature" "organization_feature" {
  for_each    = var.enable_organization_configuration ? { for key, value in var.guardduty_organization_features : key => value if value.enabled } : {}
  detector_id = data.aws_guardduty_detector.organization_detector[0].id
  name        = each.key
  auto_enable = var.disable_guardduty_members ? "NONE" : each.value.auto_enable_feature_configuration

  dynamic "additional_configuration" {
    for_each = each.value.additional_configuration != null ? { for idx, config in each.value.additional_configuration : idx => config } : {}
    content {
      name        = additional_configuration.value.name
      auto_enable = var.disable_guardduty_members ? "NONE" : (additional_configuration.value.auto_enable == "NONE" ? "NONE" : each.value.auto_enable_feature_configuration)
    }
  }
}

####################################################################################################################
#                                              GuardDuty Filters
#
#                                      Create filters for GuardDuty Findings
####################################################################################################################
resource "aws_guardduty_filter" "guardduty_filter" {
  for_each = var.filter_config != null ? { for filter in var.filter_config : filter.name => filter } : {}

  detector_id = var.enable_organization_configuration ? data.aws_guardduty_detector.organization_detector[0].id : aws_guardduty_detector.standalone_account_guardduty_detector[0].id
  name        = each.value.name
  action      = each.value.action
  rank        = each.value.rank
  description = each.value.description

  finding_criteria {
    dynamic "criterion" {
      for_each = each.value.criterion
      content {
        field                 = criterion.value.field
        equals                = criterion.value.equals
        not_equals            = criterion.value.not_equals
        greater_than          = criterion.value.greater_than
        greater_than_or_equal = criterion.value.greater_than_or_equal
        less_than             = criterion.value.less_than
        less_than_or_equal    = criterion.value.less_than_or_equal
      }
    }
  }

  tags = var.tags
}
