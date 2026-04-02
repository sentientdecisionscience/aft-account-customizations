module "budgets" {
  source = "../../../modules/terraform-aws-budgets"
  budgets = [
    {
      name         = "General Monthly Budget"
      budget_type  = "COST"
      limit_amount = 7000
      time_unit    = "MONTHLY"
      account_id   = local.account_map["organization_management"]

      notification = [
        {
          comparison_operator        = "GREATER_THAN"
          threshold                  = 80
          threshold_type             = "PERCENTAGE"
          notification_type          = "FORECASTED"
          subscriber_email_addresses = local.budget_alarm_email_addresses
        }
      ]
    }
  ]
}

module "important_budget" {
  source = "../../../modules/terraform-aws-budgets"
  budgets = [
    {
      name         = "Important Monthly Budget"
      budget_type  = "COST"
      limit_amount = 3000
      time_unit    = "MONTHLY"
      account_id   = local.account_map["organization_management"]

      notification = [
        {
          comparison_operator        = "GREATER_THAN"
          threshold                  = 80
          threshold_type             = "PERCENTAGE"
          notification_type          = "FORECASTED"
          subscriber_email_addresses = local.budget_alarm_email_addresses
        }
      ]
    }
  ]
}
