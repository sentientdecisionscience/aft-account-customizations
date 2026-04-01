#################################################### IMPORTANT #####################################################
# We delegate administration of Security Hub to the Audit account
#
# This deployment is a pre-requisite before deploying `security-hub.tf`
# in the audit account customizations.
#
# Actual service delegation needs to be done through the CLI or with the code below.
#
# See https://docs.aws.amazon.com/organizations/latest/userguide/services-that-can-integrate-securityhub.html
#
# A pre-requisite to creating a delegated Administrator for Security Hub is 
# to enable trusted access manually here: https://console.aws.amazon.com/organizations/v2/home/services/Security%20Hub
####################################################################################################################

# Delegate Administration of Security Hub to the Audit Account
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_delegated_administrator
resource "aws_organizations_delegated_administrator" "securityhub_delegated_administrator" {
  service_principal = "securityhub.amazonaws.com"
  account_id        = local.account_map["audit_account"]
}

# Set the Audit Account as the Administrator of Security Hub
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_organization_admin_account
resource "aws_securityhub_organization_admin_account" "securityhub_admin_account" {
  depends_on = [aws_organizations_delegated_administrator.securityhub_delegated_administrator]

  admin_account_id = local.account_map["audit_account"]
}
