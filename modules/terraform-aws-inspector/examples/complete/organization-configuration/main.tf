locals {

  account_map = {
    audit                   = "123456789012"
    organization_management = "123456789013"
  }

}

module "inspector" {
  source = "../../../"

  # Defaulted to false, set to true when removing Inspector from your organization.
  # See README for more information on how to remove Inspector from all accounts
  # in your organization.
  # disable_inspector_members = false

  enable_organization_configuration = true

  # Defaulted to true, which allows all new AWS accounts within the organization
  # to have Inspector enabled automatically.
  # auto_enable = true

  # Accounts to exclude from Inspector enrollment
  # Including the management account in inspectors enrollement will NOT cause an error.
  # It is best practice to not have any resources running in the management account, so theres
  # no reason to enable Inspector in it.
  excluded_accounts = [local.account_map["organization_management"]]

  resource_scan_types = ["EC2", "ECR", "LAMBDA", "LAMBDA_CODE"]
}

# Enable Inspector in the us-east-2 region
module "inspector_use2" {
  source = "../../../"

  providers = {
    aws = aws.aws-use2
  }

  # Defaulted to false, set to true when removing Inspector from your organization.
  # See README for more information on how to remove Inspector from all accounts
  # in your organization.
  # disable_inspector_members = false

  enable_organization_configuration = true

  # Defaulted to true, which allows all new AWS accounts within the organization
  # to have Inspector enabled automatically.
  # auto_enable = true

  # Accounts to exclude from Inspector enrollment
  # Including the management account in inspectors enrollement will NOT cause an error.
  # It is best practice to not have any resources running in the management account, so theres
  # no reason to enable Inspector in it.
  excluded_accounts = [local.account_map["organization_management"]]

  resource_scan_types = ["EC2", "ECR", "LAMBDA"]
}
