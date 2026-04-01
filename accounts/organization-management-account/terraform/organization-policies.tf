#################################################### IMPORTANT #####################################################
#
# Apply these policies VERY CAREFULLY. Before adding any new policy, you should:
#
# 1. Carefully evaluate your SECURITY REQUIREMENTS
# 2. check if it aligns with your specific GOVERNANCE needs
# 3. Evaluate your COMPLIANCE REQUIREMENTS
# 4. Ensure the POLICY will not cause unintentional disruption to existent workloads
# 5. Make surehange management processes are being followed
# 6. enable the Organization Policy type: https://docs.aws.amazon.com/organizations/latest/userguide/enable-policy-type.html
#
# Make sure before applying these examples that your organization has processes in place to handle the above.
#
# Please refer to the module for all available features. We only create SCP's here.
####################################################################################################################

module "organization_policies" {
  source = "../../../modules/terraform-aws-organizations-policies"

  json_policies_folders = {
    service_control_policy = "./organization_policies/service_control_policies/json_policies"
    tag_policy             = "./organization_policies/tag_policies/json_policies"
  }
  template_policies_folders = {
    service_control_policy = "./organization_policies/service_control_policies/template_policies"
  }

  service_control_policies = {

    ######################################################################
    # SCP applied to Root and Inherited by all OUs
    ######################################################################
    "root_ou" = {
      name        = "organization_root_scp"
      description = "SCP inherited by all OUs in the organization"
      policies    = ["deny_leaving_organization", "prevent_external_ram_shares"]
      target      = [local.ou_map["root"]]
    }
    ######################################################################
    # SCPs applied to all OUs except the filtered OU's
    ######################################################################
    "all_ou_scp" = {
      name        = "transversal_scp"
      description = "Custom SCP for all OUs except the root OU"
      policies = [
        "deny_deleting_cloudwatch_logs",
        "deny_disabling_guardduty",
        "deny_disabling_cloudtrail",
        "deny_deleting_route53_zones",
        "deny_deleting_kms_keys"
      ]
      template_policies = ["deny_disabling_ebs_encryption_by_default", "deny_s3_buckets_public_access"]
      target            = local.filtered_level_1_ous

      # template_vars can be overridden for any organization policy and will take precedence over the globally defined
      # template_vars = {}
    }

    # "require_nonempty_required_tags" = {
    #   name        = "require-nonempty-required-tags"
    #   description = "Deny selected create APIs when required tags are missing or empty"
    #   policies    = ["required_nonempty_tags"]
    #   target      = local.filtered_level_1_ous
    # }

  }

  # tag_policies = {
  #   required_tags_policy = {
  #     name        = "org-required-tags"
  #     description = "Standardize tag keys; constrain Environment values"
  #     policies    = ["required_tags"]
  #     target      = local.filtered_level_1_ous
  #   }
  # }

  template_vars = {
    partition = data.aws_partition.current.partition
  }
}
