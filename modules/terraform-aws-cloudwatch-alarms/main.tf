# ---------------------------------------------------------------------------------------------
# SNS Topic and Subscription
# ---------------------------------------------------------------------------------------------

resource "aws_sns_topic" "main" {
  name              = var.alarm_sns_topic
  kms_master_key_id = aws_kms_alias.main.name
}

resource "aws_sns_topic_subscription" "main" {
  topic_arn = aws_sns_topic.main.arn
  protocol  = "email"
  endpoint  = var.alarms_destination_email
}

# ---------------------------------------------------------------------------------------------
# SNS Policy
# ---------------------------------------------------------------------------------------------

resource "aws_sns_topic_policy" "main" {
  arn    = aws_sns_topic.main.arn
  policy = data.aws_iam_policy_document.main.json
}

#
# SNS - Policy Document
#
data "aws_iam_policy_document" "main" {
  statement {
    sid     = "AllowServices"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    resources = [
      aws_sns_topic.main.arn,
    ]
  }
}

# ---------------------------------------------------------------------------------------------
# SNS Encryption Key
# ---------------------------------------------------------------------------------------------

resource "aws_kms_key" "main" {
  description             = "KMS key used to encrypt/decrypt SNS topic ${var.alarm_sns_topic}"
  deletion_window_in_days = 10
  policy                  = data.aws_iam_policy_document.kms.json
  enable_key_rotation     = true
}

resource "aws_kms_alias" "main" {
  name          = "alias/aft-security-alerts"
  target_key_id = aws_kms_key.main.key_id
}

#
# SNS Encryption Key - Policy Document
#
data "aws_iam_policy_document" "kms" {
  statement {
    sid       = "AllowCloudWatchToUseKey"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
  }

  # Default KMS key policy (https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html)
  statement {
    sid       = "Enable IAM User Permissions"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.main.account_id}:root"]
    }
  }
}

# ---------------------------------------------------------------------------------------------
# Alarms
# ---------------------------------------------------------------------------------------------

#
# CloudTrail Actions
#
resource "aws_cloudwatch_log_metric_filter" "cloudtrail_action_metric_filter" {
  count          = var.cloudtrail_alarm ? 1 : 0
  name           = "CloudtrailActionMetricFilter"
  pattern        = "{ ($.eventName = CreateTrail) || ($.eventName = UpdateTrail) || ($.eventName = DeleteTrail) || ($.eventName = StartLogging) || ($.eventName = StopLogging) }"
  log_group_name = var.log_group_name

  metric_transformation {
    name      = "cloudtrail-actions"
    namespace = var.metric_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudtrail_action_cloudwatch_alarm" {
  count               = var.cloudtrail_alarm ? 1 : 0
  alarm_name          = "cloudtrail-action-alarm"
  alarm_description   = "Alarms when an API call is made to create, update, or delete Cloudtrail"
  alarm_actions       = [aws_sns_topic.main.arn]
  metric_name         = "cloudtrail-actions"
  namespace           = var.metric_namespace
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
}

#
# Security Group Actions
#
resource "aws_cloudwatch_log_metric_filter" "securitygroup_action_metric_filter" {
  count          = var.security_group_alarm ? 1 : 0
  name           = "SecurityGroupActionMetricFilter"
  pattern        = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }"
  log_group_name = var.log_group_name

  metric_transformation {
    name      = "security-group-actions"
    namespace = var.metric_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "securityGroup_action_cloudwatch_alarm" {
  count               = var.security_group_alarm ? 1 : 0
  alarm_name          = "security-group-action-alarm"
  alarm_description   = "Alarms when an API call is made to create, update, or delete security groups"
  alarm_actions       = [aws_sns_topic.main.arn]
  metric_name         = "security-group-actions"
  namespace           = var.metric_namespace
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
}

#
# NACL Actions
#
resource "aws_cloudwatch_log_metric_filter" "nacl_action_metric_filter" {
  count          = var.nacl_alarm ? 1 : 0
  name           = "NACLActionMetricFilter"
  pattern        = "{ ($.eventName = CreateNetworkAcl) || ($.eventName = CreateNetworkAclEntry) || ($.eventName = DeleteNetworkAcl) || ($.eventName = DeleteNetworkAclEntry) || ($.eventName = ReplaceNetworkAclEntry) || ($.eventName = ReplaceNetworkAclAssociation) }"
  log_group_name = var.log_group_name

  metric_transformation {
    name      = "nacl-actions"
    namespace = var.metric_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "nacl_action_cloudwatch_alarm" {
  count               = var.nacl_alarm ? 1 : 0
  alarm_name          = "nacl-action-alarm"
  alarm_description   = "Alarms when an API call is made to create, update, or delete nacls"
  alarm_actions       = [aws_sns_topic.main.arn]
  metric_name         = "nacl-actions"
  namespace           = var.metric_namespace
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
}

#
# IGW Actions
#
resource "aws_cloudwatch_log_metric_filter" "igw_action_metric_filter" {
  count          = var.igw_alarm ? 1 : 0
  name           = "IGWActionMetricFilter"
  pattern        = "{ ($.eventName = CreateCustomerGateway) || ($.eventName = DeleteCustomerGateway) || ($.eventName = AttachInternetGateway) || ($.eventName = CreateInternetGateway) || ($.eventName = DeleteInternetGateway) || ($.eventName = DetachInternetGateway) }"
  log_group_name = var.log_group_name

  metric_transformation {
    name      = "igw-actions"
    namespace = var.metric_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "igw_action_cloudwatch_alarm" {
  count               = var.igw_alarm ? 1 : 0
  alarm_name          = "igw-action-alarm"
  alarm_description   = "Alarms when an API call is made to create, update, or delete igws"
  alarm_actions       = [aws_sns_topic.main.arn]
  metric_name         = "igw-actions"
  namespace           = var.metric_namespace
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
}

#
# VPC Actions
#
resource "aws_cloudwatch_log_metric_filter" "vpc_action_metric_filter" {
  count          = var.vpc_alarm ? 1 : 0
  name           = "VPCActionMetricFilter"
  pattern        = "{ ($.eventName = CreateVpc) || ($.eventName = DeleteVpc) || ($.eventName = ModifyVpcAttribute) || ($.eventName = AcceptVpcPeeringConnection) || ($.eventName = CreateVpcPeeringConnection) || ($.eventName = DeleteVpcPeeringConnection) || ($.eventName = RejectVpcPeeringConnection) || ($.eventName = AttachClassicLinkVpc) || ($.eventName = DetachClassicLinkVpc) || ($.eventName = DisableVpcClassicLink) || ($.eventName = EnableVpcClassicLink) }"
  log_group_name = var.log_group_name

  metric_transformation {
    name      = "vpc-actions"
    namespace = var.metric_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "vpc_action_cloudwatch_alarm" {
  count               = var.vpc_alarm ? 1 : 0
  alarm_name          = "vpc-action-alarm"
  alarm_description   = "Alarms when an API call is made to create, update, or delete vpc"
  alarm_actions       = [aws_sns_topic.main.arn]
  metric_name         = "vpc-actions"
  namespace           = var.metric_namespace
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
}

#
# Config Actions
#
resource "aws_cloudwatch_log_metric_filter" "config_action_metric_filter" {
  count          = var.config_alarm ? 1 : 0
  name           = "ConfigActionMetricFilter"
  pattern        = "{ ($.eventSource = config.amazonaws.com) && (($.eventName = StopConfigurationRecorder)||($.eventName = DeleteDeliveryChannel)||($.eventName = PutDeliveryChannel)||($.eventName = PutConfigurationRecorder)) }"
  log_group_name = var.log_group_name

  metric_transformation {
    name      = "config-actions"
    namespace = var.metric_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "config_action_cloudwatch_alarm" {
  count               = var.config_alarm ? 1 : 0
  alarm_name          = "config-action-alarm"
  alarm_description   = "Alarms when an API call is made to create, update, or delete config"
  alarm_actions       = [aws_sns_topic.main.arn]
  metric_name         = "config-actions"
  namespace           = var.metric_namespace
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
}

#
# Route Table Actions
#
resource "aws_cloudwatch_log_metric_filter" "route_table_action_metric_filter" {
  count          = var.route_table_alarm ? 1 : 0
  name           = "RouteTableActionMetricFilter"
  pattern        = "{ ($.eventName = CreateRoute) || ($.eventName = CreateRouteTable) || ($.eventName = ReplaceRoute) || ($.eventName = ReplaceRouteTableAssociation) || ($.eventName = DeleteRouteTable) || ($.eventName = DeleteRoute) || ($.eventName = DisassociateRouteTable) }"
  log_group_name = var.log_group_name

  metric_transformation {
    name      = "route-table-actions"
    namespace = var.metric_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "route_table_action_cloudwatch_alarm" {
  count               = var.route_table_alarm ? 1 : 0
  alarm_name          = "route-table-action-alarm"
  alarm_description   = "Alarms when an API call is made to create, update, or delete route tables"
  alarm_actions       = [aws_sns_topic.main.arn]
  metric_name         = "route-table-actions"
  namespace           = var.metric_namespace
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
}

#
# Root Usage
#
resource "aws_cloudwatch_log_metric_filter" "root_usage_metric_filter" {
  count          = var.root_account_alarm ? 1 : 0
  name           = "RootUsageMetricFilter"
  pattern        = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"
  log_group_name = var.log_group_name

  metric_transformation {
    name      = "root-account-usage"
    namespace = var.metric_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "root_usage_cloudwatch_alarm" {
  count               = var.root_account_alarm ? 1 : 0
  alarm_name          = "root-account-usage-alarm"
  alarm_description   = "Alarms when an API calls are made from the root account"
  alarm_actions       = [aws_sns_topic.main.arn]
  metric_name         = "root-account-usage"
  namespace           = var.metric_namespace
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
}

#
# Console sign-in failure
#
resource "aws_cloudwatch_log_metric_filter" "console_signin_failures__metric_filter" {
  count          = var.console_failure_alarm ? 1 : 0
  name           = "ConsoleSignInFailuresMetricFilter"
  pattern        = "{ ($.eventName = ConsoleLogin) && ($.errorMessage = \"Failed authentication\") }"
  log_group_name = var.log_group_name

  metric_transformation {
    name      = "console-sign-in-failures"
    namespace = var.metric_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "console_signin_failures_cloudwatch_alarm" {
  count               = var.console_failure_alarm ? 1 : 0
  alarm_name          = "console-sign-in-failures-alarm"
  alarm_description   = "Alarms when console sign-in failures occur"
  alarm_actions       = [aws_sns_topic.main.arn]
  metric_name         = "console-sign-in-failures"
  namespace           = var.metric_namespace
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
}

#
# Organization actions
#
resource "aws_cloudwatch_log_metric_filter" "organization_actions_metric_filter" {
  count          = var.organizations_alarm ? 1 : 0
  name           = "OrganizationActionsMetricFilter"
  pattern        = "{ ($.eventName = ConsoleLogin) && ($.errorMessage = \"Failed authentication\") }"
  log_group_name = var.log_group_name

  metric_transformation {
    name      = "organization-actions"
    namespace = var.metric_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "organization_actions_cloudwatch_alarm" {
  count               = var.organizations_alarm ? 1 : 0
  alarm_name          = "organization-actions-alarm"
  alarm_description   = "Alarms when an API call is made to create, update, or delete organizations"
  alarm_actions       = [aws_sns_topic.main.arn]
  metric_name         = "organization-actions"
  namespace           = var.metric_namespace
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
}

#
# Console sign-in without MFA
#
resource "aws_cloudwatch_log_metric_filter" "console_signin_without_mfa_metric_filter" {
  count          = var.mfa_alarm ? 1 : 0
  name           = "ConsoleSignInWithoutMFAMetricFilter"
  pattern        = "{ $.eventName = \"ConsoleLogin\" && $.additionalEventData.MFAUsed = \"No\" && $.userIdentity.type = \"IAMUser\"}"
  log_group_name = var.log_group_name

  metric_transformation {
    name      = "console-sign-in-without-mfa"
    namespace = var.metric_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "console_signin_without_mfa_cloudwatch_alarm" {
  count               = var.mfa_alarm ? 1 : 0
  alarm_name          = "console-sign-in-without-mfa-alarm"
  alarm_description   = "Alarms when a user signs in without MFA"
  alarm_actions       = [aws_sns_topic.main.arn]
  metric_name         = "console-sign-in-without-mfa"
  namespace           = var.metric_namespace
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
}
