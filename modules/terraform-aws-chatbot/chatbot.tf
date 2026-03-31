resource "aws_chatbot_slack_channel_configuration" "slack_channels" {
  for_each = var.slack_channel_configurations != null ? var.slack_channel_configurations : {}

  configuration_name    = each.value.configuration_name
  iam_role_arn          = var.create_default_iam_role ? aws_iam_role.chatbot_role[0].arn : each.value.iam_role_arn
  slack_channel_id      = each.value.slack_channel_id
  slack_team_id         = each.value.slack_team_id
  guardrail_policy_arns = each.value.guardrail_policy_arns
  logging_level         = each.value.logging_level
  sns_topic_arns        = each.value.sns_topic_arns

  tags = {
    Name = each.value.configuration_name
  }
}

resource "aws_chatbot_teams_channel_configuration" "teams_channels" {
  for_each = var.teams_channel_configurations != null ? var.teams_channel_configurations : {}

  configuration_name    = each.value.configuration_name
  iam_role_arn          = var.create_default_iam_role ? aws_iam_role.chatbot_role[0].arn : each.value.iam_role_arn
  channel_id            = each.value.channel_id
  team_id               = each.value.team_id
  tenant_id             = each.value.tenant_id
  guardrail_policy_arns = each.value.guardrail_policy_arns
  logging_level         = each.value.logging_level
  sns_topic_arns        = each.value.sns_topic_arns

  tags = {
    Name = each.value.configuration_name
  }
}
