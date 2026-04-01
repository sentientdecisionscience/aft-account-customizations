#################################################### IMPORTANT #####################################################
# The Config Conformance Pack is deployed here with an organization-wide configuration.
#
# Control Tower automatically enables Config in all accounts, in all actively governed regions.
#
# See https://docs.aws.amazon.com/config/latest/developerguide/aggregated-register-delegated-administrator.html
# And https://docs.aws.amazon.com/config/latest/developerguide/conformance-pack-organization-apis.html
# And https://docs.aws.amazon.com/organizations/latest/userguide/services-that-can-integrate-config.html
#
# Not all module features are deployed, be sure to check the module for all available features.
#
#       *************BE AWARE OF COSTS ASSOCIATED WITH REMOVING CONFORMANCE PACKS/RULES*************
# Before disabling a Conformance Pack or Config Rule, see the module README for information to avoid unwanted costs.
####################################################################################################################
module "conformance_packs" {
  count  = length(local.hipaa_account_ids) > 0 ? 1 : 0
  source = "../../../modules/terraform-aws-config/modules/conformance-packs-and-rules"

  #### IMPORTANT NOTE ON TERRAFORM APPLY TIME ####
  # Conformance packs can take 5 minutes or more to apply. Same is true for terraform destroy.
  conformance_packs = [
    {
      name = "organization-hipaa-conformance-pack"
      # This is an abstraction of this resource:
      # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_organization_conformance_pack
      deployment_mode      = "ORGANIZATION"
      excluded_accounts    = local.non_hipaa_account_ids
      include_mgmt_account = false
      # We recommend using a specific commit hash for the template URL. If you want to live on the edge, use instead:
      # https://raw.githubusercontent.com/awslabs/aws-config-rules/refs/heads/master/aws-config-conformance-packs/Operational-Best-Practices-for-HIPAA-Security.yaml
      template_url = "https://raw.githubusercontent.com/awslabs/aws-config-rules/d51caecc74f6b23085476b23f2479c565c415b27/aws-config-conformance-packs/Operational-Best-Practices-for-HIPAA-Security.yaml"
      input_parameters = {
        "IamPasswordPolicyParamMaxPasswordAge"        = "90",
        "IamPasswordPolicyParamMinimumPasswordLength" = "14",
      }
    }
  ]
}
