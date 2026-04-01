# ---------------------------------------------------------------------------------------------
# AWS CloudWatch Alarms
# ---------------------------------------------------------------------------------------------

# This module creates CloudWatch Alarms to enforce AWS security posture and compliance standards.
# It requires a set of input variables to specify which alarms are going to be enabled.
# The alarms are also customizable through the input variables.

module "cloudwatch_alarms" {
  source = "../../../modules/terraform-aws-cloudwatch-alarms"

  log_group_name = local.cloudwatch_log_group_name

  # Alarms when an API call is made to create, update, or delete Cloudtrail.
  cloudtrail_alarm = false
  # Alarms when an API call is made to create, update, or delete Security Groups.
  security_group_alarm = true
  # Alarms when an API call is made to create, update, or delete NACLs.
  nacl_alarm = true
  # Alarms when an API call is made to create, update, or delete IGWs.
  igw_alarm = true
  # Alarms when an API call is made to create, update, or delete VPCs.
  vpc_alarm = true
  # Alarms when an API call is made to create, update, or delete Route Tables.
  route_table_alarm = true
  # Alarms when an API call is made to create, update, or delete AWS Config.
  config_alarm = false
  # Alarms when an API calls are made from the root account.
  root_account_alarm = true
  # Alarms when console sign-in failures occur.
  console_failure_alarm = true
  # Alarms when an API call is made to create, update, or delete Organizations.
  organizations_alarm = false
  # Alarms when a user signs in without MFA.
  mfa_alarm = true
  # Destination email to send notifications to.
  alarms_destination_email = local.cloudwatch_alarm_destination_email
}
