#################################################### IMPORTANT #####################################################
# We delegate administration of AWS Config to the Audit account
# to be able to centrally deploy Conformance Packs from there
#
# This deployment is a pre-requisite before deploying the `config.tf`
# in the audit account customizations.
#
# Actual service delegation needs to be done through the CLI or with the code below.
#
# See https://docs.aws.amazon.com/config/latest/developerguide/aggregated-register-delegated-administrator.html
# And https://docs.aws.amazon.com/config/latest/developerguide/conformance-pack-organization-apis.html
# And https://docs.aws.amazon.com/organizations/latest/userguide/services-that-can-integrate-config.html
#
# A pre-requisite to creating a delegated Administrator for Config is 
# to enable trusted access manually here: https://console.aws.amazon.com/organizations/v2/home/services/Config
#
# We don't need to worry about service-linked roles because these are dealt by Control Tower during account factory.
# Same applies to the aggregator configuration in the Audit account.
####################################################################################################################

# Delegate Administration of Config to the Audit Account
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_delegated_administrator
resource "aws_organizations_delegated_administrator" "config" {
  account_id        = local.account_map["audit"]
  service_principal = "config.amazonaws.com"
}

# Delegate Administration of Config Multi-Account Setup to the Audit Account
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_delegated_administrator
# resource "aws_organizations_delegated_administrator" "config_multiaccountsetup" {
#   account_id        = local.account_map["audit"]
#   service_principal = "config-multiaccountsetup.amazonaws.com"
# }
