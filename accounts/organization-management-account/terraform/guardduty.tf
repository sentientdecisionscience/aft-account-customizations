#################################################### IMPORTANT #####################################################
# We delegate administration of AWS GuardDuty to the Audit account
#
# This deployment is a pre-requisite before deploying `guardduty.tf`
# in the audit account customizations.
#
# Actual service delegation needs to be done through the CLI or with the code below.
#
# See https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_organizations.html
#
# A pre-requisite to creating a delegated Administrator for GuardDuty is 
# to enable trusted access manually here: https://console.aws.amazon.com/organizations/v2/home/services/Amazon%20GuardDuty
####################################################################################################################

# Delegate Administration of GuardDuty to the Audit Account
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_delegated_administrator
resource "aws_organizations_delegated_administrator" "guardduty_delegated_administrator" {
  account_id        = local.account_map["audit"]
  service_principal = "guardduty.amazonaws.com"
}

# # Set the Audit Account as the Administrator of GuardDuty in the current (home) region
# # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_admin_account
resource "aws_guardduty_organization_admin_account" "guardduty_admin_account" {
  depends_on = [aws_organizations_delegated_administrator.guardduty_delegated_administrator]

  admin_account_id = local.account_map["audit"]
}
