locals {

  account_map = {
    "networking"  = "111111111111"
    "log_archive" = "222222222222"
  }

}

module "config_cost_management" {
  source = "../../modules/config-cost-management"

  # List of account ids to enable or disable the AWS Config ResourceCompliance resource type
  account_ids = [local.account_map["networking"], local.account_map["log_archive"]]

  # Name of the IAM role the lambda function will assume in the target accounts
  # to update the AWS Config ResourceCompliance Recorder Resource
  target_iam_role_name = "AWSControlTowerExecution"

  # Mode that the manage-config-resource-compliance lambda function will execute in
  # Set to "enable" to enable the AWS Config ResourceCompliance resource type
  # Set to "disable" to disable the AWS Config ResourceCompliance resource type
  lambda_function_mode = "enable"
}
