#################################################### IMPORTANT #####################################################
# Utilize this locals block to track all Organization Account IDs and OU IDs.
#
# This allows us to reference all accounts & OUs in an easily identifiable and consistent manner throughout TF.
######################################################################################################################

locals {

  account_map = {
    "organization_management" = "704601633428"
    "log_archive"             = "931409206927"
    "audit"                   = "587402079603"
    "aft_management"          = "308471216192"
    "shared_services"         = "172201861437"
    "sandbox"                 = "513750743324"
    "networking"              = "627917840657"
    "development"             = "530310462919"
    "production"              = "739272173599"
  }

  ou_map = {
    "root"           = data.aws_organizations_organization.current.roots[0].id
    "security"       = "ou-v919-afmjp2rj"
    "suspended"      = "ou-v919-3gsfdalr"
    "aft"            = "ou-v919-hprwkjd6"
    "sandbox"        = "ou-v919-u3zg7y39"
    "workloads"      = "ou-v919-xyg1342j"
    "infrastructure" = "ou-v919-1abjeb6l"
  }

  # Organization SCP Restricted OUs
  unrestricted_ous = [
    local.ou_map["sandbox"],
    local.ou_map["suspended"]
  ]

  filtered_level_1_ous = setsubtract([
    for ou in data.aws_organizations_organizational_units.level_1_ous.children : ou.id
  ], local.unrestricted_ous)

  # Budget Alarms
  budget_alarm_email_addresses = [
    "aws.billing-alarms@sentientdecisionscience.com"
  ]

  # Cloudwatch Alarms
  cloudwatch_log_group_name          = "aws-controltower/CloudTrailLogs-c9n-gze"
  cloudwatch_alarm_destination_email = "aws.security-alerts@sentientdecisionscience.com"

  all_account_ids = [
    for acc in data.aws_organizations_organization.current.accounts : acc.id
  ]

  # Compliance organizations for HIPAA
  hipaa_account_ids = [

  ]

  non_hipaa_account_ids = [
    for id in local.all_account_ids :
    id if contains(local.hipaa_account_ids, id) == false
  ]

}
