# Delegate SSO Identity Center to the Shared Services Account
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_delegated_administrator
resource "aws_organizations_delegated_administrator" "sso_delegated_administrator" {
  service_principal = "sso.amazonaws.com"
  account_id        = local.account_map["shared_services"]
}
