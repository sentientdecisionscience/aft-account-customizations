#################################################### IMPORTANT #####################################################
# Security Hub is deployed here with a central configuration (organization configuration).
#
# Security Hub is a REGIONAL service, but deploying it using a CENTRAL configuration allows you to manage ALL REGIONS
# from your HOME REGION.
#
# A pre-requisite to this deployment style is to first go to the Organization Management account and
# delegate administration of Security Hub to this (Audit) account
#
# Please refer to the module README for more information & all available features.
####################################################################################################################
module "security_hub" {
  source = "../../../modules/terraform-aws-security-hub"

  # Security Hub Organization Configuration
  organization_configuration = {
    auto_enable           = false
    auto_enable_standards = "NONE"
    configuration_type    = "CENTRAL"
  }

  ####################################################################################################################
  # Finding aggregator is required if the `organization_configuration` type is set to `CENTRAL`.                    ##
  # Security Hub must be enabled in the specified regions in order for the aggregator to aggreate findings in the   ##
  # additional regions.                                                                                             ##
  # Do not to add your home region to `finding_aggregator.specified_regions`, this will cause an error, it is added ##
  # by default.                                                                                                     ##
  # Also remember that Security Hub depends on Config, so all specified regions must have Config enabled.           ##
  ####################################################################################################################
  finding_aggregator = {
    linking_mode      = "SPECIFIED_REGIONS"
    specified_regions = ["us-west-1"]
  }

  # Configuration Policy Hierarchy: left to right | highest to lowest precedence
  # Account Target-Specific Policy -> OU Target-Specific Policy -> Root OU Policy -> Default Policy

  configuration_policy = [
    # Root OU Policy
    {
      target_id       = local.ou_map["root"]
      service_enabled = true
      enabled_standard_arns = [
        local.security_standards["aws-foundational-security-best-practices"],
        local.security_standards["cis-aws-foundations-benchmark-v3.0.0"]
      ],
    },

    ###################################################################################################################
    # Policies that target specific OUs or Accounts take precedence over the Root OU & Default Policy.
    ###################################################################################################################

    # Security OU Target-Specific Policy
    {
      target_id       = local.ou_map["security"]
      service_enabled = true
      enabled_standard_arns = [
        local.security_standards["aws-foundational-security-best-practices"]
      ],
      security_controls_configuration = {
        disabled_control_identifiers = ["KMS.3"]
      }
    },
    # Workloads Target-Specific Policy
    {
      target_id       = local.ou_map["workloads"]
      service_enabled = true
      enabled_standard_arns = [
        local.security_standards["aws-foundational-security-best-practices"],
        local.security_standards["cis-aws-foundations-benchmark-v3.0.0"]
      ],
    },
    # Infrastructure Target-Specific Policy
    {
      target_id       = local.ou_map["infrastructure"]
      service_enabled = true
      enabled_standard_arns = [
        local.security_standards["aws-foundational-security-best-practices"],
        local.security_standards["cis-aws-foundations-benchmark-v3.0.0"]
      ],
    },
    # Policies to Disable Security Hub
    {
      target_id             = local.ou_map["suspended"]
      service_enabled       = false
      enabled_standard_arns = []
    },
    {
      target_id             = local.ou_map["aft"]
      service_enabled       = false
      enabled_standard_arns = []
    },
    {
      target_id             = local.account_map["organization_management"]
      service_enabled       = false
      enabled_standard_arns = []
    }
  ]
}
