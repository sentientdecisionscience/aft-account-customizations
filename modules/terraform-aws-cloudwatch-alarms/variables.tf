variable "log_group_name" {
  type    = string
  default = "aws-controltower/CloudTrailLogs"
}

variable "metric_namespace" {
  type    = string
  default = "aft-catalyst-alarms"
}

variable "alarm_sns_topic" {
  type    = string
  default = "aft-catalyst-alarms"
}

variable "alarms_destination_email" {}
variable "cloudtrail_alarm" {}
variable "security_group_alarm" {}
variable "nacl_alarm" {}
variable "igw_alarm" {}
variable "vpc_alarm" {}
variable "route_table_alarm" {}
variable "config_alarm" {}
variable "console_failure_alarm" {}
variable "root_account_alarm" {}
variable "organizations_alarm" {}
variable "mfa_alarm" {}
