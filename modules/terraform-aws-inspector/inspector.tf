# Enabling Ispector & Inspector features for delegate administrator account
resource "aws_inspector2_enabler" "inspector_enabler" {
  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = var.resource_scan_types
}

# Inspector Organization Configuration
# Enable Inspector features for all new accounts in the organization
resource "aws_inspector2_organization_configuration" "inspector_organization_configuration" {
  count = var.enable_organization_configuration ? 1 : 0

  auto_enable {
    ec2         = !var.disable_inspector_members && var.auto_enable && contains(var.resource_scan_types, "EC2")
    ecr         = !var.disable_inspector_members && var.auto_enable && contains(var.resource_scan_types, "ECR")
    lambda      = !var.disable_inspector_members && var.auto_enable && (contains(var.resource_scan_types, "LAMBDA") || contains(var.resource_scan_types, "LAMBDA_CODE"))
    lambda_code = !var.disable_inspector_members && var.auto_enable && contains(var.resource_scan_types, "LAMBDA_CODE")
  }
  depends_on = [aws_inspector2_enabler.inspector_enabler]
}

# Adding organization accounts as inspector member accounts
resource "aws_inspector2_member_association" "inspector_member_association" {
  for_each = var.enable_organization_configuration ? {
    for account, info in data.aws_organizations_organization.current.accounts : info.id => info.email
  if(info.id != data.aws_caller_identity.current.account_id && !contains(var.excluded_accounts, info.id) && info.status == "ACTIVE") } : {}

  account_id = each.key

  depends_on = [aws_inspector2_organization_configuration.inspector_organization_configuration[0]]
}
