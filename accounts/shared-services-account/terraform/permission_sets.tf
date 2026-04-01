# Administrator Permission Set
resource "aws_ssoadmin_permission_set" "admin" {
  instance_arn     = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  name             = "${local.permission_sets_prefix}AdministratorAccess"
  description      = "Provides full administrative access"
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "admin_policy" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
}

# Billing Permission Set
resource "aws_ssoadmin_permission_set" "billing" {
  instance_arn     = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  name             = "${local.permission_sets_prefix}Billing"
  description      = "Grants permissions for billing and cost management. This includes viewing account usage and viewing and modifying budgets and payment methods."
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "billing_policy" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/job-function/Billing"
  permission_set_arn = aws_ssoadmin_permission_set.billing.arn
}

# Power User Permission Set
resource "aws_ssoadmin_permission_set" "power_user" {
  instance_arn     = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  name             = "${local.permission_sets_prefix}PowerUserAccess"
  description      = "Provides full access to AWS services and resources, but does not allow management of Users and groups."
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "power_user_policy" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
  permission_set_arn = aws_ssoadmin_permission_set.power_user.arn
}

# Network Administrator Permission Set
resource "aws_ssoadmin_permission_set" "network_administrator" {
  instance_arn     = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  name             = "${local.permission_sets_prefix}NetworkAdministrator"
  description      = "Grants full access permissions to AWS services and actions required to set up and configure AWS network resources."
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "network_administrator_policy" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/job-function/NetworkAdministrator"
  permission_set_arn = aws_ssoadmin_permission_set.network_administrator.arn
}

# Database Administrator Permission Set
resource "aws_ssoadmin_permission_set" "database_admin" {
  instance_arn     = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  name             = "${local.permission_sets_prefix}DatabaseAdministrator"
  description      = "Grants full access permissions to AWS services and actions required to set up and configure AWS database services."
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "database_admin_policy" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/job-function/DatabaseAdministrator"
  permission_set_arn = aws_ssoadmin_permission_set.database_admin.arn
}

# Security Audit Permission Set
resource "aws_ssoadmin_permission_set" "security_audit" {
  instance_arn     = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  name             = "${local.permission_sets_prefix}SecurityAudit"
  description      = "The security audit template grants access to read security configuration metadata. It is useful for software that audits the configuration of an AWS account."
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "security_audit_policy" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
  permission_set_arn = aws_ssoadmin_permission_set.security_audit.arn
}

# SupportAccess Permission Set
resource "aws_ssoadmin_permission_set" "support_access" {
  instance_arn     = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  name             = "${local.permission_sets_prefix}SupportAccess"
  description      = "Allows users to access the AWS Support Center."
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "support_access_policy" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/AWSSupportAccess"
  permission_set_arn = aws_ssoadmin_permission_set.support_access.arn
}

# System Administrator Permission Set
resource "aws_ssoadmin_permission_set" "system_admin" {
  instance_arn     = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  name             = "${local.permission_sets_prefix}SystemAdministrator"
  description      = "Grants full access permissions necessary for resources required for application and development operations."
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "system_admin_policy" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/job-function/SystemAdministrator"
  permission_set_arn = aws_ssoadmin_permission_set.system_admin.arn
}


# Read Only  Permission Set
resource "aws_ssoadmin_permission_set" "read_only" {
  instance_arn     = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  name             = "${local.permission_sets_prefix}ReadOnlyAccess"
  description      = "Provides read-only access to AWS services and resources."
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "read_only_policy" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  permission_set_arn = aws_ssoadmin_permission_set.read_only.arn
}
