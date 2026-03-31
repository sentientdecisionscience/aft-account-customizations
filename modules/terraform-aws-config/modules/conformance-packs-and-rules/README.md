# AWS Config Rule and Conformance Pack Sub-module

This sub-module is for creating conformance packs and configuration rules in AWS Config

## Key Features

* Create organizational or local conformance packs and configuration rules
* Conformance packs can be created from:
    * template string
    * local YAML file
    * URL containing the raw template
    * S3 URI
* Configuration rules can be created from:
    * AWS Managed rules
    * Customer policy template
    * Custom rule using Lambda

## Usage

### Minimum Required Configuration
```
module "config" {
  source = "../../"

  enable_recorder = true
  create_delivery_bucket = true
  delivery_frequency = "TwentyFour_Hours"

  recording_group = {
    include_global_resource_types = false
    resource_types = ["AWS::EC2::Instance"]
  }

  recording_mode = {
    recording_frequency = "DAILY"
  }
}

module "conformance_packs_and_rules" {
  source = "../../modules/conformance-packs-and-rules"

  delivery_bucket_name = module.config.s3_delivery_bucket_name

  conformance_packs = [
    {
      name            = "conformance-pack-custom-template"
      deployment_mode = "LOCAL"
      template        = <<EOT
  Parameters:
    AccessKeysRotatedParameterMaxAccessKeyAge:
      Type: String
  Resources:
    IAMPasswordPolicy:
      Properties:
        ConfigRuleName: IAMPasswordPolicy
        Source:
          Owner: AWS
          SourceIdentifier: IAM_PASSWORD_POLICY
      Type: AWS::Config::ConfigRule
  EOT
      input_parameters = {
        "AccessKeysRotatedParameterMaxAccessKeyAge" = "90"
      }
    }
  ]

  config_rules = [
    {
      name            = "s3-bucket-versioning-enabled"
      description     = "Checks whether the versioning is enabled for the S3 buckets"
      deployment_mode = "ORGANIZATION"

      evaluation_mode      = "DETECTIVE"
      include_mgmt_account = false
      source = {
        owner             = "AWS"
        source_identifier = "S3_BUCKET_VERSIONING_ENABLED"
      }
      scope = {
        compliance_resource_types = ["AWS::S3::Bucket"]
      }
    }
  ]
}
```
*Check out the examples folder for a more comprehensive and complete usage of the module.*

> [!IMPORTANT]
> * The default deployment mode for a conformance pack and config rule is `LOCAL`.
> * If you want to deploy a conformance pack or a config rule in the organization, explicitly set the `deployment_mode` to `ORGANIZATION`.
> * This sub-module must be run from either a management account or a delegated administrator account if the deployment mode is `ORGANIZATION`
>    * To delegate an administrator, visit the [AWS Official Documentation](https://docs.aws.amazon.com/config/latest/developerguide/aggregated-register-delegated-administrator.html)
> * The management account are excluded by default from conformance pack and config rule deployment. If you want to include it, set the `include_mgmt_account` parameter to `true`.
>

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_http"></a> [http](#provider\_http) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_config_config_rule.config_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_config_rule) | resource |
| [aws_config_conformance_pack.conformance_pack](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_conformance_pack) | resource |
| [aws_config_organization_conformance_pack.org_conformance_pack](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_organization_conformance_pack) | resource |
| [aws_config_organization_custom_policy_rule.org_custom_config_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_organization_custom_policy_rule) | resource |
| [aws_config_organization_custom_rule.org_custom_lambda_config_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_organization_custom_rule) | resource |
| [aws_config_organization_managed_rule.org_managed_config_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_organization_managed_rule) | resource |
| [aws_organizations_organization.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [http_http.main](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_config_rules"></a> [config\_rules](#input\_config\_rules) | The AWS Config rules to enable | <pre>list(object({<br>    name                        = string<br>    description                 = optional(string)<br>    evaluation_mode             = optional(string)<br>    deployment_mode             = optional(string, "LOCAL")<br>    include_mgmt_account        = optional(bool, false)<br>    excluded_accounts           = optional(list(string), [])<br>    maximum_execution_frequency = optional(string)<br>    scope = optional(object({<br>      compliance_resource_id    = optional(string)<br>      compliance_resource_types = optional(list(string), [])<br>      tag_key                   = optional(string, null)<br>      tag_value                 = optional(string, null)<br>    }), {})<br>    source = optional(object({<br>      owner             = optional(string)<br>      source_identifier = optional(string)<br>      source_detail = optional(object({<br>        event_source                = optional(string, null)<br>        message_type                = optional(string, null)<br>        maximum_execution_frequency = optional(string, null)<br>      }), null)<br>      custom_policy_details = optional(object({<br>        policy_text               = optional(string, null)<br>        policy_runtime            = optional(string, null)<br>        enable_debug_log_delivery = optional(map(string), {})<br>      }), null)<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_conformance_packs"></a> [conformance\_packs](#input\_conformance\_packs) | The AWS Config conformance packs to enable | <pre>list(object({<br>    name                 = string<br>    include_mgmt_account = optional(bool, false)<br>    deployment_mode      = optional(string, "LOCAL")<br>    excluded_accounts    = optional(list(string), [])<br>    template             = optional(string, null)<br>    template_s3_uri      = optional(string, null)<br>    template_url         = optional(string, null)<br>    input_parameters     = optional(map(string), {})<br>  }))</pre> | `[]` | no |
| <a name="input_delivery_bucket_name"></a> [delivery\_bucket\_name](#input\_delivery\_bucket\_name) | The name of the S3 bucket used to store the configuration history. | `string` | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
