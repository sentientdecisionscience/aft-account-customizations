###############################################################################
#                            ⚠️ WARNING ⚠️                                    #
###############################################################################
#                                                                             #
# This file is intended to demonstrate the FEATURES and CAPABILITIES of the   #
# module only.                                                                #
#                                                                             #
# ❌ It should NOT be considered a RECOMMENDATION or BEST PRACTICE for how    #
# SERVICE CONTROL POLICIES should be structured or applied within your AWS    #
# ORGANIZATION.                                                               #
#                                                                             #
# ⚡ Each ORGANIZATION should:                                                #
#   1. Carefully evaluate their SECURITY REQUIREMENTS                         #
#   2. Develop SCPs that align with their specific GOVERNANCE needs           #
#   3. Ensure compliance with their COMPLIANCE REQUIREMENTS                   #
#                                                                             #
###############################################################################


locals {
  # Map of OUs to be used for target so users
  # don't have to remember or look up the OU IDs
  ou_map = {
    "org_root_ou" = data.aws_organizations_organization.current.roots[0].id
    "test_ou1"    = "ou-qyyj-yjcjcdoj"
    "test_ou2"    = "ou-qyyj-r5eaoka2"
    "test_ou3"    = "ou-qyyj-w0yw6krm"
    "test_ou4"    = "ou-qyyj-cuxntp0t"
  }

  account_map = {
    "sandbox-infra" = "085264297002"
  }

  # List of OUs that should not be restricted by SCP's
  unrestricted_ous = [
    local.ou_map["test_ou4"]
  ]

  # All the direct, Level 1 children OUs under Root, excluding OUs defined in local.unrestricted_ous
  filtered_level_1_ous = setsubtract([
    for ou in data.aws_organizations_organizational_units.current.children : ou.id
  ], local.unrestricted_ous)
}

module "organization_policies" {
  source = "../../"

  json_policies_folders = {
    aiservices_opt_out_policy = "../../organization_policies/ai_policies/json_policies"
    # backup_policy             = "../../organization_policies/backup_policies/json_policies"
    resource_control_policy = "../../organization_policies/resource_control_policies/json_policies"
    service_control_policy  = "../../organization_policies/service_control_policies/json_policies"
    tag_policy              = "../../organization_policies/tag_policies/json_policies"
  }
  template_policies_folders = {
    aiservices_opt_out_policy = "../../organization_policies/ai_policies/template_policies"
    backup_policy             = "../../organization_policies/backup_policies/template_policies"
    resource_control_policy   = "../../organization_policies/resource_control_policies/template_policies"
    service_control_policy    = "../../organization_policies/service_control_policies/template_policies"
    # tag_policy                = "../../organization_policies/tag_policies/template_policies"
  }

  ######################################################################
  # AIServices Opt Out Policies
  ######################################################################
  aiservices_opt_out_policies = {
    "root_ou" = {
      name        = "organization_root_aiservices_opt_out"
      description = "AIServicesOptOutPolicy inherited by all OUs in the organization"
      policies    = ["default"]
      target      = [local.ou_map["org_root_ou"]]
    }
  }

  ######################################################################
  # Backup Policies
  ######################################################################
  backup_policies = {

    ######################################################################
    # IMPORTANT:
    # Backup Policies require a Backup Vault and IAM Role to be created prior
    # to applying the policy.
    ######################################################################
    "root_ou" = {
      name              = "organization_root_backup"
      description       = "BackupPolicy inherited by all OUs in the organization"
      template_policies = ["pii_backup"]
      template_vars = {
        role_name         = "backup_role",
        backup_vault_name = "backup_vault",
        allowed_regions   = jsonencode(["us-east-1", "us-east-2"])
      }

      target = [local.ou_map["org_root_ou"]]
    }
  }

  ######################################################################
  # RCPs
  ######################################################################
  resource_control_policies = {

    ######################################################################
    # RCP applied to Root and Inherited by all OUs
    ######################################################################
    "root_ou" = {
      name              = "organization_root_rcp"
      description       = "RCP inherited by all OUs in the organization"
      policies          = ["https_only", "s3_enforce_kms", "s3_enforce_tls"]
      template_policies = ["cross_service_protection"]
      template_vars = {
        organization_id = local.ou_map["org_root_ou"]
      }
      target = [local.ou_map["org_root_ou"]]
    }
  }

  ######################################################################
  # SCPs
  ######################################################################
  service_control_policies = {

    ######################################################################
    # SCP applied to Root and Inherited by all OUs
    ######################################################################
    "root_ou" = {
      name        = "organization_root_scp"
      description = "SCP inherited by all OUs in the organization"
      policies    = ["deny_disabling_config"]
      target      = [local.ou_map["org_root_ou"]]
    }

    ######################################################################
    # SCP applied to Root and Inherited by all OUs local.unrestricted_ous
    ######################################################################
    "root_nonrestrictive_scp" = {
      name        = "nonrestrictive_root_test"
      policies    = ["deny_creating_iam_users", "deny_deleting_kms_keys", "deny_deleting_route53_zones"]
      target      = local.ou_map["filtered_level_1_ous"]
      description = "SCP applied to all OUs except the user specified non-restrictive OU"
    }

    ######################################################################
    # You can target accounts directly
    ######################################################################
    "sandbox_infra" = {
      name        = "sandbox-infra_restritive_scp"
      description = "SCP applied to the account sandbox-infra"
      policies    = ["deny_deleting_access_analyzer"]
      target      = [local.account_map["sandbox-infra"]]
    }

    ######################################################################
    # When building SCPs, you can specify:
    # 1. Only JSON policies
    # 2. Only templated policies
    # 3. A combination of JSON and templated policies
    ######################################################################
    "json_only_scp" = {
      name        = "json_files_only_scp"
      policies    = ["deny_creating_iam_users", "deny_deleting_cloudwatch_logs"]
      target      = [local.ou_map["test_ou3"]]
      description = "SCP created from only policies/json_policies/"
    }
    "template_only_scp" = {
      name              = "template_files_only_scp"
      template_policies = ["deny_unsupported_regions"]
      target            = [local.ou_map["test_ou2"]]
      description       = "SCP created from only policies/template_policies/"
    }
    "combined" = {
      name              = "json_and_template_file_scp"
      policies          = ["deny_creating_iam_users", "deny_deleting_cloudwatch_logs"]
      template_policies = ["deny_root_account_usage"]
      target            = [local.ou_map["test_ou1"]]
      description       = "SCP created from files in both policies/json_policies/ and policies/template_policies/"
    }

    ######################################################################
    # You can override the global template_vars for a specific SCP using
    # the template_vars argument which follows the same format
    ######################################################################
    "template_vars" = {
      name              = "template_vars_scp"
      description       = "Passing value to {allowed_regions} variable in the template, that is different than global value"
      template_policies = ["deny_unsupported_regions"]
      template_vars = {
        allowed_regions = jsonencode(["us-east-2", "us-west-2"])
      }
      target = [local.ou_map["test_ou4"]]
    }
  }


  ######################################################################
  # Tag Policies
  ######################################################################
  tag_policies = {
    "root_ou" = {
      name        = "organization_root_tag"
      description = "Tag policies inherited by all OUs in the organization"
      policies    = ["default_tag"]
      target      = [local.ou_map["org_root_ou"]]
    }
  }


  # Map of variables for templated policy files
  template_vars = {
    allowed_regions = jsonencode(["us-east-1", "us-east-2"])
    partition       = data.aws_partition.current.partition
  }
}
