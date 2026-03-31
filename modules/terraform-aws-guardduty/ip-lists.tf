#
# This file contains all resources for GuarDuty's IPSet & ThreatIntelSet Features
#

#############################################################################
#                                     IPSet
#                         List of trusted IP addresses
#############################################################################

locals {

  # Mapping of IPSets for resource creation
  ipset_map = var.ipset_config != null ? {
    for ipset in var.ipset_config : ipset.name => ipset
  } : {}

}

# GuardDuty IPSet
resource "aws_guardduty_ipset" "guardduty_ipset" {
  for_each = local.ipset_map

  detector_id = var.enable_organization_configuration ? data.aws_guardduty_detector.organization_detector[0].id : aws_guardduty_detector.standalone_account_guardduty_detector[0].id
  activate    = each.value.activate
  name        = each.value.name
  format      = each.value.format
  location    = "https://s3.amazonaws.com/${aws_s3_object.ipset_object[each.key].bucket}/${each.value.key}"
  tags        = var.tags
}

# IP Set S3 Object
resource "aws_s3_object" "ipset_object" {
  for_each = local.ipset_map

  bucket = each.value.bucket_id
  key    = each.value.key
  source = each.value.file_path
  tags   = var.tags
}

#############################################################################
#                               ThreatIntelSet
#                     List of known malicious IP addresses
#############################################################################

locals {

  # Mapping of ThreatIntelSets for resource creation
  threatintelset_map = var.threatintelset_config != null ? {
    for threatintelset in var.threatintelset_config : threatintelset.name => threatintelset
  } : {}

}

# GuardDuty ThreatIntelSet
resource "aws_guardduty_threatintelset" "guardduty_threatintelset" {
  for_each = local.threatintelset_map

  detector_id = var.enable_organization_configuration ? data.aws_guardduty_detector.organization_detector[0].id : aws_guardduty_detector.standalone_account_guardduty_detector[0].id
  activate    = each.value.activate
  name        = each.value.name
  format      = each.value.format
  location    = "https://s3.amazonaws.com/${aws_s3_object.threatintelset_object[each.key].bucket}/${each.value.key}"
  tags        = var.tags
}

# ThreatIntelSet S3 Object
resource "aws_s3_object" "threatintelset_object" {
  for_each = local.threatintelset_map

  bucket = each.value.bucket_id
  key    = each.value.key
  source = each.value.file_path
  tags   = var.tags
}
