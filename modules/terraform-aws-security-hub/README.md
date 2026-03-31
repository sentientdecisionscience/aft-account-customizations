# AWS Security Hub

## Overview

AWS Security Hub is a powerful security service provided by Amazon Web Services (AWS) designed to help you manage and monitor the security of your AWS environment. It serves as a central hub for collecting, prioritizing, and managing security findings from various sources across your AWS infrastructure.

## Key Features
* Supports local and central deployment.

* Local deployment:
    * Enable Security Hub in a single AWS account
    * Enable security standards in your local AWS account
    * Consolidate findings from multiple regions using finding aggregator

* Central deployment:
    * Enable Security Hub to any AWS account within the organization from the delegated administrator account
    * Enable security standards and apply organization configuration policies to any of the member account
    * Centrally gather the findings from all the member account's enabled regions with finding aggregator

## Deploy Security Hub

### Set up Security Hub Delegated Administrator

When deploying Security Hub in `CENTRAL` mode, Security Hub will manage all organization member accounts based on your module configuration.

Using Terraform to delegate Administration for Security Hub, create the `aws_organizations_delegated_administrator` & `securityhub_admin_account` resources:

```hcl
locals {

  account_map = {
    "audit" = "123456789012"
  }

}

# Delegate Administration of Security Hub to the Audit Account
resource "aws_organizations_delegated_administrator" "securityhub_delegated_administrator" {
  service_principal = "securityhub.amazonaws.com"
  account_id        = local.account_map["audit"]
}

# Set the Audit Account as the Administrator of Security Hub
resource "aws_securityhub_organization_admin_account" "securityhub_admin_account" {
  depends_on = [aws_organizations_delegated_administrator.securityhub_delegated_administrator]

  admin_account_id = local.account_map["audit"]
}
```

### Minimum Required Configuration

If you're configuring SecurityHub in `CENTRAL` mode, make sure that you have already delegated an administrator account for Security Hub from your organization's management account before running this module. Check [AWS official documentation](https://docs.aws.amazon.com/securityhub/latest/userguide/designate-orgs-admin-account.html#designate-admin-instructions) to see how you can delegate an administrator

* Below is the minimum required configuration for **deploying Security Hub in an independent account**:

```
module "security_hub" {
  source = "../../"

}
```

* Below is the minimum required configuration for **centrally managed Security Hub deployment**:

```
module "security_hub" {
  source = "../../"

  organization_configuration = {
    configuration_type = "CENTRAL"
  }

  finding_aggregator = {
    linking_mode = "SPECIFIED_REGION"
    specified_regions = ["us-west-2"]
  }
}
```

*Check out the `examples` folder for a more comprehensive and complete usage of the module.*

### Important Notes
- This module must be run from the delegated administrator account. Otherwise, you will have an issue with the permission to apply the resources from this module.

- `finding_aggregator` is required if the `configuration_type` from `organization_configuration` map is set to `CENTRAL` and is optional if `configuration_type` is `LOCAL`

- When using `finding_aggregator` the region that you specify using `specified_regions` is applied to all the member accounts.

- When using `configuration_policy`, a policy map that is defined without a `target_id` will be treated as a default policy. The module will read the `configuration_policy` variable, identify which members have a defined policy and apply it to them, then the module will apply the default policy, if specified, to the other member accounts with no specific policies defined, for example:

```
  configuration_policy = [
    {
      service_enabled = true,
      enabled_standard_arns = [
        "arn:aws:securityhub:us-east-1::standards/aws-resource-tagging-standard/v/1.0.0"
      ]
    }
  ]
```

- When using `configuration_policy` you cannot define more than one map for a default policy and/or more than one map that has the same `target_id`. This is because in Security Hub, you can only apply one policy to each member accounts.

- When using `enabled_standard_arns` or `disabled_standard_arns` for enabling/disabling standards for a target account using the `configuration_policy` map, use `aws cli` command `aws securityhub describe-standards` to find the standard ARN/s that you want to enable or disable.

- Specifying `enabled_control_identifiers` will disable all controls that are not explicitly enabled in the list while `disabled_control_identifiers` enable those that are not in the list.

## Automation Rules

Security Hub automation rules allow you to automatically manage findings based on criteria you define. This module includes support for automation rules through a dedicated submodule.

### Key Features
* Create rules to automatically suppress or update findings
* Filter findings by severity, resource type, account ID, and more
* Apply rules in order of priority
* Organization-wide rules when deployed in the delegated administrator account

### Usage Example

```hcl
module "automation_rules" {
  source = "git::https://github.com/caylent/terraform-aws-security-hub.git//modules/automation-rules"

  automation_rules = [
    {
      rule_name       = "suppress-low-severity-findings"
      description     = "Automatically suppress all low severity findings"
      rule_order      = 1
      severity_labels = ["LOW"]
      action_type     = "FINDING_FIELDS_UPDATE"
      finding_fields_update = {
        workflow_status = "SUPPRESSED"
      }
    }
  ]
}
```

### Important Notes
- Rules are processed in order based on the rule_order value
- Rules are region-specific and must be deployed in each region where Security Hub is enabled
- When deployed in the delegated administrator account, rules apply to findings from all member accounts
- Rules are processed when new findings are created or existing findings are updated

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.34.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.34.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_securityhub_account.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_account) | resource |
| [aws_securityhub_configuration_policy.config_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_configuration_policy) | resource |
| [aws_securityhub_configuration_policy_association.policy_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_configuration_policy_association) | resource |
| [aws_securityhub_finding_aggregator.finding_aggregator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_finding_aggregator) | resource |
| [aws_securityhub_member.members](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_member) | resource |
| [aws_securityhub_organization_configuration.organization_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_organization_configuration) | resource |
| [aws_securityhub_standards_subscription.standards_subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_standards_subscription) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_configuration_policy"></a> [configuration\_policy](#input\_configuration\_policy) | The Security Hub configuration policy to be applied to each target account. | <pre>list(object({<br>    target_id             = optional(string)<br>    service_enabled       = optional(bool, false)<br>    enabled_standard_arns = optional(list(string), [])<br>    security_controls_configuration = optional(object({<br>      disabled_control_identifiers = optional(list(string), null)<br>      enabled_control_identifiers  = optional(list(string), null)<br>      security_control_custom_parameters = optional(list(object({<br>        parameter = list(object({<br>          name        = string<br>          value_type  = string<br>          bool        = optional(bool, null)<br>          double      = optional(number, null)<br>          enum        = optional(string, null)<br>          enum_list   = optional(list(string), null)<br>          int         = optional(number, null)<br>          int_list    = optional(list(number), null)<br>          string      = optional(string, null)<br>          string_list = optional(list(string), null)<br>        }))<br>        security_control_id = string<br>      })))<br>    }), {})<br>  }))</pre> | `[]` | no |
| <a name="input_enabled_standard_arns"></a> [enabled\_standard\_arns](#input\_enabled\_standard\_arns) | The list of enabled standard ARNs for individually managed deployments. | `list(string)` | `[]` | no |
| <a name="input_finding_aggregator"></a> [finding\_aggregator](#input\_finding\_aggregator) | The finding aggregator configuration to be applied to the Security Hub. The default linking\_mode is SPECIFIED\_REGIONS. | <pre>object({<br>    linking_mode      = optional(string, "SPECIFIED_REGIONS")<br>    specified_regions = optional(list(string), null)<br>  })</pre> | `null` | no |
| <a name="input_member_account_ids"></a> [member\_account\_ids](#input\_member\_account\_ids) | The list of account IDs of the AWS accounts to be added as a member account. | `list(string)` | `[]` | no |
| <a name="input_organization_configuration"></a> [organization\_configuration](#input\_organization\_configuration) | The Security Hub organization configuration. | <pre>object({<br>    auto_enable           = optional(bool, false)<br>    auto_enable_standards = optional(string, "NONE")<br>    configuration_type    = string<br>  })</pre> | <pre>{<br>  "auto_enable": false,<br>  "auto_enable_standards": "NONE",<br>  "configuration_type": "LOCAL"<br>}</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
