data "aws_partition" "this" {}
data "aws_caller_identity" "this" {}
data "aws_region" "this" {}
data "aws_organizations_organization" "this" {}

locals {

  account   = data.aws_caller_identity.this.account_id
  partition = data.aws_partition.this.partition
  region    = data.aws_region.this.name

  root_ou_id      = "r-example"
  sandbox_ou_id   = "ou-example"
  security_ou_id  = "ou-example-security"
  suspended_ou_id = "ou-example-suspended"

  security_standards = {
    "aws-foundational-security-best-practices" = provider::aws::arn_build(local.partition, "securityhub", local.region, "", "standards/aws-foundational-security-best-practices/v/1.0.0")
    "cis-aws-foundations-benchmark-v1.2.0"     = provider::aws::arn_build(local.partition, "securityhub", local.region, "", "ruleset/cis-aws-foundations-benchmark/v/1.2.0")
    "cis-aws-foundations-benchmark-v1.4.0"     = provider::aws::arn_build(local.partition, "securityhub", local.region, "", "standards/cis-aws-foundations-benchmark/v/1.4.0")
    "cis-aws-foundations-benchmark-v3.0.0"     = provider::aws::arn_build(local.partition, "securityhub", local.region, "", "standards/cis-aws-foundations-benchmark/v/3.0.0")
    "nist-800-53-rev5"                         = provider::aws::arn_build(local.partition, "securityhub", local.region, "", "standards/nist-800-53/v/5.0.0")
    "pci-dss-v3.2.1"                           = provider::aws::arn_build(local.partition, "securityhub", local.region, "", "standards/pci-dss/v/3.2.1")
    "pci-dss-v4.0.1"                           = provider::aws::arn_build(local.partition, "securityhub", local.region, "", "standards/pci-dss/v/4.0.1")
  }

}

module "security_hub" {
  source = "../../../"

  # Security Hub Organization Configuration
  organization_configuration = {
    auto_enable           = false
    auto_enable_standards = "NONE"
    configuration_type    = "CENTRAL"
  }

  ###################################################################################################################
  # Finding aggregator is required if the `organization configuration type` is set to `CENTRAL`.                   ##
  # Security Hub must be enabled in the specified regions in order for the aggregator to to pull through findings. ##
  ###################################################################################################################
  finding_aggregator = {
    linking_mode = "SPECIFIIED_REGIONS"
    regions      = ["us-west-2"]
  }

  configuration_policy = [
    # Default Policy
    {
      service_enabled = true
      enabled_standard_arns = [
        local.security_standards["aws-foundational-security-best-practices"]
      ]
    },

    ###################################################################################################################
    # Policies that target specific OUs or Accounts take precedence over the Root OU & Default Policy.
    ###################################################################################################################
    # Root OU Target-Specific Policy
    {
      target_id       = local.root_ou_id
      service_enabled = true
      enabled_standard_arns = [
        local.security_standards["aws-foundational-security-best-practices"],
        local.security_standards["cis-aws-foundations-benchmark-v3.0.0"],
        local.security_standards["nist-800-53-rev5"]
      ],
      security_controls_configuration = {
        disabled_control_identifiers = [["KMS.3"]]
      }
    },
    # Sandbox OU Target-Specific Policy
    {
      target_id       = local.sandbox_ou_id
      service_enabled = true
      enabled_standard_arns = [
        local.security_standards["pci-dss-v4.0.1"]
      ]
    },
    # Specific Account Policy
    {
      target_id       = "340298760000"
      service_enabled = true
      enabled_standard_arns = [
        local.security_standards["aws-foundational-security-best-practices"]
      ]
    },
    # Policy to Disable Security Hub
    {
      target_id             = local.suspended_ou_id
      service_enabled       = false
      enabled_standard_arns = []
    },
    {
      target_id       = local.security_ou_id
      service_enabled = true


      ########################################################################################################################################################################
      # For the list of available Standards, refer to the AWS Security Hub documentation: https://docs.aws.amazon.com/securityhub/latest/userguide/standards-reference.html ##
      # and running `aws securityhub describe-standards` using `aws cli` to get more information about the standards including their ARNs.                                  ##
      ########################################################################################################################################################################
      enabled_standard_arns = [
        local.security_standards["aws-foundational-security-best-practices"],
        local.security_standards["cis-aws-foundations-benchmark-v3.0.0"],
        local.security_standards["nist-800-53-rev5"],
        local.security_standards["pci-dss-v4.0.1"],
        local.security_standards["pci-dss-v3.2.1"]
      ],


      #############################################################################################################################################################################################################################
      # For the list of controls configuration that can be enabled or disabled, check out https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-controls-reference.html                                           ##
      # You can also check the current control parameter values by following https://docs.aws.amazon.com/securityhub/latest/userguide/view-control-parameters.html and customize them using `security_control_custom_parameters` ##
      #############################################################################################################################################################################################################################
      security_controls_configuration = {

        #############################################################################################################################################
        # Specifying `enabled_control_identifiers` will disable all controls that are not explicitly enabled in the list.                          ##
        # and specifying `disabled_control_identifiers` will enable all controls that are not explicitly disabled in the list.                     ##
        #############################################################################################################################################
        enabled_control_identifiers = [
          "APIGateway.1",
          "IAM.7",
          "IAM.1"
        ]
        security_control_custom_parameters = [
          {
            security_control_id = "APIGateway.1"
            parameter = [
              {
                name       = "loggingLevel"
                value_type = "CUSTOM"
                enum       = "INFO"
              }
            ]
          },
          {
            security_control_id = "IAM.7"
            parameter = [
              {
                name       = "RequireLowercaseCharacters"
                value_type = "CUSTOM"
                bool       = false
              },
              {
                name       = "MaxPasswordAge"
                value_type = "CUSTOM"
                int        = 60
              }
            ]
          }
        ]
      }
    }
  ]
}
