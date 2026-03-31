# terraform-aws-config

This Terraform module enables the creation of AWS resources to get started with AWS Config.

## Key Features

- Create an AWS Config recorder
- Customize recording strategy
- Create an aggregator to collect findings from member accounts
- Optionally create a generic S3 bucket as a delivery channel
- Supports config rule and conformance pack with sub-module
- Enable & Disable the `AWS::Config::ResourceCompliance` Recorder Resource Type in member accounts

## Table of Contents

- [Deploy Config](#deploy-config)
  - [Set up AWS Config Delegated Administrator](#set-up-aws-config-delegated-administrator)
  - [Minimum Required Module Configuration](#minimum-required-module-configuration)
- [Config Cost Management](#config-cost-management)
  - [Step 1: Disable the AWS Config ResourceCompliance Recorder Resource Type](#step-1-disable-the-aws-config-resourcecompliance-recorder-resource-type)
  - [Step 2: Verify the AWS Config ResourceCompliance Recorder Resource Type is disabled](#step-2-verify-the-aws-config-resourcecompliance-recorder-resource-type-is-disabled)
  - [Step 3: Delete the AWS Config Conformance Pack or Rule](#step-3-delete-the-aws-config-conformance-pack-or-rule)
  - [Step 4: Re-enable the AWS Config ResourceCompliance Recorder Resource Type](#step-4-re-enable-the-aws-config-resourcecompliance-recorder-resource-type)
  - [Step 5: Verify the AWS Config ResourceCompliance Recorder Resource Type is enabled](#step-5-verify-the-aws-config-resourcecompliance-recorder-resource-type-is-enabled)

## Deploy Config

### Set up AWS Config Delegated Administrator

If you are deploying the module within an AWS Organization, it is best practice to deleagted the administration of the AWS Config service to a specific member account. To set the AWS Config Delegated Administrator, create the `aws_organizations_delegated_administrator` resources for the `config.amazonaws.com` & `config-multiaccountsetup.amazonaws.com` in the Organization's Management Account like the following:

```hcl
#####################
# Management Account
#####################
locals {

  account_map = {
    "audit" = "123456789012"
  }

}

# Delegate Administration of AWS Config to the Audit Account
resource "aws_organizations_delegated_administrator" "config" {
  account_id        = local.account_map["audit"]
  service_principal = "config.amazonaws.com"
}

# Delegate Administration of AWS Config Multi Account Setup to the Audit Account
resource "aws_organizations_delegated_administrator" "config_multiaccountsetup" {
  account_id        = local.account_map["audit"]
  service_principal = "config-multiaccountsetup.amazonaws.com"
}
```

### Minimum Required Module Configuration

From your Organization's Delegated Administrator Account for AWS Config, you can deploy config with the following minimum required configuration:

```hcl
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
```
*Check out the examples folder for a more comprehensive and complete usage of the module.*

> [!IMPORTANT]
> * The `aggregator` object can only be specified if you are running this module from the management account or a delegated admin account.
> * The `create_delivery_bucket` parameter creates just a generic S3 bucket. If you want a customized bucket, use the `delivery_bucket_name` to define an already existing one.
> * You can only specify one or nothing of the following in the `resource_group` parameter:
>   `resource_types` or `excluded_resource_types`
>    * If `resource_types` is specified, only the specified resource types are going to be included in the recording.
>    * If `excluded_resource_types` is specified, all resource types except the specified ones going to be included in the recording.
>    * If none of them is specified, all supported resource types are included in the recording.
>    * If none of them is specified and include_global_resource_types is true, all supported resource types and global resource types are included in the recording.
>

## Config Cost Management

### Context

If you remove an AWS Config Conformance Pack or Rule without first disabling the `AWS::Config::ResourceCompliance` Recorder Resource Type, you will incur unexpected costs. You can find more information about this [here](https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config.html#config-cost-considerations).

### Step 1: Disable the AWS Config ResourceCompliance Recorder Resource Type

From the Organization's Management Account, call the `config-cost-management` sub module & pass in the `account_ids` of the member accounts that you need to delete config conformance packs or config rules from. Set the `lambda_function_mode` to `disable`.

```hcl
module "config_cost_management" {
  source = "../../modules/config-cost-management"

  # List of account ids to enable or disable the AWS Config ResourceCompliance resource type
  account_ids = ["111111111111", "222222222222"]

  # Name of the IAM role the lambda function will assume in the target accounts
  # to update the AWS Config ResourceCompliance Recorder Resource
  target_iam_role_name = "AWSControlTowerExecution"

  # Mode that the manage-config-resource-compliance lambda function will execute in
  # Set to "enable" to enable the AWS Config ResourceCompliance resource type
  # Set to "disable" to disable the AWS Config ResourceCompliance resource type
  lambda_function_mode = "disable"
}
```

Run `terraform apply`.

### Step 2: Verify the AWS Config ResourceCompliance Recorder Resource Type is disabled

You can verify if the AWS Config ResourceCompliance Recorder Resource Type is disabled by running the following cli command inside the target accounts or view the most recent execution of  the `manage-config-resource-compliance` lambda function in the CloudWatch Logs Group `/aws/lambda/manage-config-resource-compliance`.

```bash
aws configservice describe-configuration-recorders --query "ConfigurationRecorders[0].recordingGroup"
```

**Expected output:**

```json
{
    "allSupported": false,
    "includeGlobalResourceTypes": false,
    "resourceTypes": [],
    "exclusionByResourceTypes": {
        "resourceTypes": [
            "AWS::Config::ResourceCompliance"
        ]
    },
    "recordingStrategy": {
        "useOnly": "EXCLUSION_BY_RESOURCE_TYPES"
    }
}
```

### Step 3: Delete the AWS Config Conformance Pack or Rule

From the Delegated Administrator Account of AWS Config, modify the conformance pack or rule configuration from your module call and run `terraform apply`.

### Step 4: Re-enable the AWS Config ResourceCompliance Recorder Resource Type

Back in the Organization's Management Account, using the same module call to the `config-cost-management`, set the `lambda_function_mode` variable to `enable`.

```hcl
module "config_cost_management" {
  source = "../../modules/config-cost-management"

  # List of account ids to enable or disable the AWS Config ResourceCompliance resource type
  account_ids = ["111111111111", "222222222222"]

  # Name of the IAM role the lambda function will assume in the target accounts
  # to update the AWS Config ResourceCompliance Recorder Resource
  target_iam_role_name = "AWSControlTowerExecution"

  # Mode that the manage-config-resource-compliance lambda function will execute in
  # Set to "enable" to enable the AWS Config ResourceCompliance resource type
  # Set to "disable" to disable the AWS Config ResourceCompliance resource type
  lambda_function_mode = "enable"
}
```

Run `terraform apply`.

### Step 5: Verify the AWS Config ResourceCompliance Recorder Resource Type is enabled

You can verify if the AWS Config ResourceCompliance Recorder Resource Type is enabled by running the following cli command inside the target accounts or view the most recent execution of  the `manage-config-resource-compliance` lambda function in the CloudWatch Logs Group `/aws/lambda/manage-config-resource-compliance`.

```bash
aws configservice describe-configuration-recorders --query "ConfigurationRecorders[0].recordingGroup"
```

**Expected output:**

```json
{
    "allSupported": true,
    "includeGlobalResourceTypes": true,
    "resourceTypes": [],
    "exclusionByResourceTypes": {
        "resourceTypes": []
    },
    "recordingStrategy": {
        "useOnly": "ALL_SUPPORTED_RESOURCE_TYPES"
    }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.34.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.34.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_config_configuration_aggregator.aggregator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_aggregator) | resource |
| [aws_config_configuration_recorder.config_recorder](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder) | resource |
| [aws_config_configuration_recorder_status.config_recorder_status](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder_status) | resource |
| [aws_config_delivery_channel.delivery_channel](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_delivery_channel) | resource |
| [aws_iam_role.config_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.delivery_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.config_role_additional_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.organization_aggregation_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.delivery_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_versioning.delivery_bucket_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [random_string.config_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_iam_policy_document.config_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.config_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_policy_arns"></a> [additional\_policy\_arns](#input\_additional\_policy\_arns) | A list of ARNs of IAM policies to attach to the AWS Config IAM role | `list(string)` | `[]` | no |
| <a name="input_aggregator"></a> [aggregator](#input\_aggregator) | The AWS Config aggregator configuration | <pre>object({<br>    enabled            = optional(bool, false)<br>    aggregation_mode   = optional(string, null)<br>    member_account_ids = optional(list(string), [])<br>    all_regions        = optional(bool, false)<br>    scope_regions      = optional(any, null)<br>  })</pre> | `{}` | no |
| <a name="input_create_delivery_bucket"></a> [create\_delivery\_bucket](#input\_create\_delivery\_bucket) | Whether to create the S3 bucket used to store the configuration history. | `bool` | `false` | no |
| <a name="input_delivery_bucket_kms_key_arn"></a> [delivery\_bucket\_kms\_key\_arn](#input\_delivery\_bucket\_kms\_key\_arn) | The ARN of the KMS key to used to encrypt the objects of the s3 bucket | `string` | `null` | no |
| <a name="input_delivery_bucket_name"></a> [delivery\_bucket\_name](#input\_delivery\_bucket\_name) | The name of the S3 bucket used to store the configuration history. | `string` | `null` | no |
| <a name="input_delivery_bucket_prefix"></a> [delivery\_bucket\_prefix](#input\_delivery\_bucket\_prefix) | The prefix to use for the specified S3 bucket | `string` | `"awsconfig-history"` | no |
| <a name="input_delivery_frequency"></a> [delivery\_frequency](#input\_delivery\_frequency) | The frequency with which AWS Config delivers configuration snapshots. Valid values are `One_Hour`, `Three_Hours`, `Six_Hours`, `Twelve_Hours`, or `TwentyFour_Hours`. | `string` | `null` | no |
| <a name="input_delivery_sns_topic_arn"></a> [delivery\_sns\_topic\_arn](#input\_delivery\_sns\_topic\_arn) | The ARN of the SNS topic that AWS Config delivers notifications to. | `string` | `null` | no |
| <a name="input_enable_recorder"></a> [enable\_recorder](#input\_enable\_recorder) | Whether the configuration recorder should be enabled | `bool` | `true` | no |
| <a name="input_recording_group"></a> [recording\_group](#input\_recording\_group) | The configuration recorder's recording group | <pre>object({<br>    resource_types                = optional(list(string), [])<br>    excluded_resource_types       = optional(list(string), [])<br>    include_global_resource_types = optional(bool, true)<br>    recording_strategy            = optional(string, null)<br>  })</pre> | <pre>{<br>  "excluded_resource_types": [],<br>  "include_global_resource_types": true,<br>  "resource_types": []<br>}</pre> | no |
| <a name="input_recording_mode"></a> [recording\_mode](#input\_recording\_mode) | The configuration recorder's recording mode | <pre>object({<br>    recording_frequency = optional(string)<br>    recording_mode_override = optional(list(object({<br>      description         = string<br>      resource_types      = list(string)<br>      recording_frequency = string<br>    })))<br>  })</pre> | <pre>{<br>  "recording_frequency": null,<br>  "recording_mode_override": []<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_s3_delivery_bucket_name"></a> [s3\_delivery\_bucket\_name](#output\_s3\_delivery\_bucket\_name) | The name of the S3 bucket used to store the configuration history. |
<!-- END_TF_DOCS -->
