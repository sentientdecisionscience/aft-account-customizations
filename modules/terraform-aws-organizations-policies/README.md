# AWS Organizations Policy Module

> [!WARNING]
>
> ❌ Examples provided should NOT be considered a RECOMMENDATION or BEST PRACTICE for how ORGANIZATIONS POLICIES should be structured or applied within your AWS ORGANIZATION.
>
> ⚡ Each ORGANIZATION should:
> 1. Carefully evaluate their SECURITY REQUIREMENTS
> 2. Develop ORGANIZATIONS POLICIES that align with their specific GOVERNANCE needs
> 3. Evaluate their COMPLIANCE REQUIREMENTS
> 4. Ensure ORGANIZATIONS POLICIES will not cause unintentional disruption to existent workloads
> 5. Change management processes are being followed
> 6. [Enable Organization Policy](https://docs.aws.amazon.com/organizations/latest/userguide/enable-policy-type.html) per Policy type outside of this module
>
> Make sure before applying these examples that your organization has processes in place to handle the above.

## Overview

This Terraform module enables the creation and attachment of [AWS Organizations Policies](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies.html). They are used to enforce governance and compliance controls across the organization, and their types include:

> [!NOTE]
>
> These policies are not enabled by default in your organization. You must enable them through the [AWS Console or the AWS CLI](https://docs.aws.amazon.com/organizations/latest/userguide/enable-policy-type.html) before applying this module.

- [AIServices Opt Out Policies](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_ai-opt-out.html) allow you to control data collection for AWS AI services for all the accounts in an organization.
- [Backup Policies](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_backup.html) allow you to centrally manage and apply backup plans to the AWS resources across an organization's accounts.
- [Resource Control Policies (RCPs)](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_rcps.html) are policies that specify the maximum permissions for resources within an AWS Account, which are the targets for RCP attachments.
- [Service Control Policies (SCPs)](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html) are policies that specify the maximum permissions for entities within an Organization Unit or AWS Account, which are the targets for SCP attachments.
- [Tag Policies](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html) are used to enforce tagging policies across the organization.

This module's functionality includes:

1. Reusable JSON and JSON Template policies to build Organizations Policies;
2. Deploy Organizations Policies to an arbitrary number of targets, being them Organization Units (OUs) or AWS Accounts;
3. Use JSON templates to dynamically inject variables into policy statements, both at a global level and at an Organizations Policy level;

### JSON and Template File Policies

To create Organization Policies you'll define policy statements using JSON and/or JSON templates to make use of Terraform's [templating feature](https://developer.hashicorp.com/terraform/language/functions/templatefile).

When using normal JSON policies, they will simply be concatenated into the Organization Policies. When using JSON template files, Terraform will inject variables into the policy statements to make them dynamic and parametrizable through the `template_vars` variable and then also concatenate them into the Organization Policies.

The module expects you to define your policies in a separate folder or multiple separate folders, and then specify the path to that folder in the `json_policies_folders` and `template_policies_folders` variables. See the [example](./examples/complete) and notice how we've decided to put the policies in a folder called `organization_policies/`, separated by POLICY TYPE and JSON and JSON template files with the `.json.tpl` suffix.

```hcl

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
```

Note that you can also define your policies in the same folder, and use any arbitrary suffix defined in the `template_file_suffix` variable:

```hcl
template_file_suffix = {
    aiservices_opt_out_policy = ".json.tpl"
    backup_policy             = ".json.tpl"
    resource_control_policy   = ".json.tpl"
    service_control_policy    = ".json.tpl"
    tag_policy                = ".json.tpl"
}
```

For each policy type, you're expected to pass JSON policies to the `policies` property and the JSON template files to the `template_policies` property. Hence, you don't need to specify file extensions in the `policies` and `template_policies` variables. See [variables.tf](./variables.tf) for more details. The policy types are defined as:

- `aiservices_opt_out_policies`
- `backup_policies`
- `resource_control_policies`
- `service_control_policies`
- `tag_policies`


Here's an example of how a full module call can look like:

```hcl
module "scp" {
  source = "../../"

  json_policies_folders = "../policies/json_policies"
  template_policies_folders = "../policies/template_policies"

  service_control_policies = {
    "deny_unsupported_regions" = {
      name              = "deny_unsupported_regions"
      description       = "Deny usage of unsupported regions"
      template_policies = ["deny_unsupported_regions"] # JSON template file name without suffix

      # Overrides the global template_vars for this SCP to allow all US regions
      template_vars = {
        allowed_regions = jsonencode(["us-east-1", "us-east-2", "us-west-1", "us-west-2"])
      }
      target = ["ou-qyyj-w0yg6krm"] # OU ID
    }
  }

  # Map of variables for JSON template policy files
  template_vars = {
    allowed_regions = jsonencode(["us-east-1", "us-east-2"])
    partition       = data.aws_partition.current.partition
  }
}
```

> [!TIP]
> Organization Policies can be created without specifying a target if you just want to create the SCP without attaching it to any OU or AWS Account. Simply set `target = []` in the Organization Policies configuration.


## Usage & Recommendations

> [!NOTE]
> - The `${partition}` variable across the policies templates has to be filled with the group of AWS Regions that corresponds. These could be `aws`, `aws-cn` or `aws-us-gov`. [Docs here](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference-arns.html)
> - The exception for the `AWSAFTExecution` role allows automated account provisioning processes to function properly without compromising overall security. [Related docs](https://docs.aws.amazon.com/controltower/latest/userguide/aft-provisioning-framework.html)

Make sure you check the [example](./examples/complete)! It contains several Organizational Policies definitions and a full example of how to use the module with different scenarios and targets, such as non-restrictive OUs.

Also, use the locals block to keep track of the OU and Account IDs used when defining the `target` to apply SCPs to:

```hcl
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
    sandbox-infra = "085264297002"
    network-pod   = "045258900906"
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
```

## Design Choices

### The `policy-templates/*_template.json.tpl` file

The `aiservices_opt_out_policy_template.json.tpl`, `backup_policy_template`, `control_policies_template.json.tpl`, `tag_policy_template.json.tpl` files are used to standardize the beginning format of each Policy document.

### The main.tf file

We have intentionally made a flat `main.tf` file to make it easier to understand and maintain. Sure, we could have abstracted more and have a single instance of `resource "aws_organizations_policy"`, but this would make the module unecessarily complex.

## Known AWS Organization Policy Limitations

- **Maximum size of a policy document**:
  - Service control policies: 5120 characters
  - Resource control policies: 5120 characters
  - Backup policies: 10,000 characters
  - AI services opt-out policies: 2500 characters
  - Tag policies: 10,000 characters

- **Target Attachment**: The AWS Organizations service has a hard limit of 5 directly attached (not inherited) SCPs per account and OU. If you attached too many SCPs to an account, OU, or root, then you might receive the `ConstraintViolationException` error.


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
| [aws_organizations_policy.aiservices_opt_out_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy) | resource |
| [aws_organizations_policy.backup_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy) | resource |
| [aws_organizations_policy.rcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy) | resource |
| [aws_organizations_policy.scp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy) | resource |
| [aws_organizations_policy.tag_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy) | resource |
| [aws_organizations_policy_attachment.aiservices_opt_out_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |
| [aws_organizations_policy_attachment.backup_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |
| [aws_organizations_policy_attachment.rcp_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |
| [aws_organizations_policy_attachment.scp_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |
| [aws_organizations_policy_attachment.tag_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aiservices_opt_out_policies"></a> [aiservices\_opt\_out\_policies](#input\_aiservices\_opt\_out\_policies) | Map of AISERVICES\_OPT\_OUT\_POLICY with associated policies, template variables, targets, name and descriptions | <pre>map(object({<br>    policies          = optional(list(string), []) # Standard JSON policies without variables<br>    template_policies = optional(list(string), []) # Templated policies that need variables injected<br>    template_vars     = optional(map(string), {})  # Takes precedence over var.template_vars<br>    target            = list(string)<br>    name              = string<br>    description       = string<br>  }))</pre> | `{}` | no |
| <a name="input_backup_policies"></a> [backup\_policies](#input\_backup\_policies) | Map of BACKUP\_POLICY with associated policies, template variables, targets, name and descriptions | <pre>map(object({<br>    policies          = optional(list(string), []) # Standard JSON policies without variables<br>    template_policies = optional(list(string), []) # Templated policies that need variables injected<br>    template_vars     = optional(map(string), {})  # Takes precedence over var.template_vars<br>    target            = list(string)<br>    name              = string<br>    description       = string<br>  }))</pre> | `{}` | no |
| <a name="input_json_file_suffix"></a> [json\_file\_suffix](#input\_json\_file\_suffix) | Suffix to append to the JSON policy file names | <pre>object({<br>    aiservices_opt_out_policy = optional(string, ".json")<br>    backup_policy             = optional(string, ".json")<br>    resource_control_policy   = optional(string, ".json")<br>    service_control_policy    = optional(string, ".json")<br>    tag_policy                = optional(string, ".json")<br>  })</pre> | `{}` | no |
| <a name="input_json_policies_folders"></a> [json\_policies\_folders](#input\_json\_policies\_folders) | Relative path to the folder containing JSON policies | <pre>object({<br>    aiservices_opt_out_policy = optional(string, "./organization_policies/ai_policies/json_policies")<br>    backup_policy             = optional(string, "./organization_policies/backup_policies/json_policies")<br>    resource_control_policy   = optional(string, "./organization_policies/resource_control_policies/json_policies")<br>    service_control_policy    = optional(string, "./organization_policies/service_control_policies/json_policies")<br>    tag_policy                = optional(string, "./organization_policies/tag_policies/json_policies")<br>  })</pre> | `{}` | no |
| <a name="input_resource_control_policies"></a> [resource\_control\_policies](#input\_resource\_control\_policies) | Map of RESOURCE\_CONTROL\_POLICY with associated policies, template variables, targets, name and descriptions | <pre>map(object({<br>    policies          = optional(list(string), []) # Standard JSON policies without variables<br>    template_policies = optional(list(string), []) # Templated policies that need variables injected<br>    template_vars     = optional(map(string), {})  # Takes precedence over var.template_vars<br>    target            = list(string)<br>    name              = string<br>    description       = string<br>  }))</pre> | `{}` | no |
| <a name="input_service_control_policies"></a> [service\_control\_policies](#input\_service\_control\_policies) | Map of SERVICE\_CONTROL\_POLICY with associated policies, template variables, targets, name and descriptions | <pre>map(object({<br>    policies          = optional(list(string), []) # Standard JSON policies without variables<br>    template_policies = optional(list(string), []) # Templated policies that need variables injected<br>    template_vars     = optional(map(string), {})  # Takes precedence over var.template_vars<br>    target            = list(string)<br>    name              = string<br>    description       = string<br>  }))</pre> | `{}` | no |
| <a name="input_tag_policies"></a> [tag\_policies](#input\_tag\_policies) | Map of TAG\_POLICY with associated policies, template variables, targets, name and descriptions | <pre>map(object({<br>    policies          = optional(list(string), []) # Standard JSON policies without variables<br>    template_policies = optional(list(string), []) # Templated policies that need variables injected<br>    template_vars     = optional(map(string), {})  # Takes precedence over var.template_vars<br>    target            = list(string)<br>    name              = string<br>    description       = string<br>  }))</pre> | `{}` | no |
| <a name="input_template_file_suffix"></a> [template\_file\_suffix](#input\_template\_file\_suffix) | Suffix to append to the template policy file names | <pre>object({<br>    aiservices_opt_out_policy = optional(string, ".json.tpl")<br>    backup_policy             = optional(string, ".json.tpl")<br>    resource_control_policy   = optional(string, ".json.tpl")<br>    service_control_policy    = optional(string, ".json.tpl")<br>    tag_policy                = optional(string, ".json.tpl")<br>  })</pre> | `{}` | no |
| <a name="input_template_policies_folders"></a> [template\_policies\_folders](#input\_template\_policies\_folders) | Relative path to the folder containing JSON template policies | <pre>object({<br>    aiservices_opt_out_policy = optional(string, "./organization_policies/ai_policies/template_policies")<br>    backup_policy             = optional(string, "./organization_policies/backup_policies/template_policies")<br>    resource_control_policy   = optional(string, "./organization_policies/resource_control_policies/template_policies")<br>    service_control_policy    = optional(string, "./organization_policies/service_control_policies/template_policies")<br>    tag_policy                = optional(string, "./organization_policies/tag_policies/template_policies")<br>  })</pre> | `{}` | no |
| <a name="input_template_vars"></a> [template\_vars](#input\_template\_vars) | Variables that will be replaced in all templated policies.<br>Can be overridden by `template_vars` in the policy configuration maps | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aiservices_opt_out_policies"></a> [aiservices\_opt\_out\_policies](#output\_aiservices\_opt\_out\_policies) | See the AISERVICES\_OPT\_OUT\_POLICIES with the aggregated policy statements |
| <a name="output_backup_policies"></a> [backup\_policies](#output\_backup\_policies) | See the BACKUP\_POLICIES with the aggregated policy statements |
| <a name="output_rcps"></a> [rcps](#output\_rcps) | See the RCPs with the aggregated policy statements |
| <a name="output_scps"></a> [scps](#output\_scps) | See the SCPs with the aggregated policy statements |
| <a name="output_tag_policies"></a> [tag\_policies](#output\_tag\_policies) | See the TAG\_POLICYs with the aggregated policy statements |
<!-- END_TF_DOCS -->
