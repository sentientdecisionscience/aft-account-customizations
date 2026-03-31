# AWS Security Hub Automation Rules

This module creates AWS Security Hub automation rules to automatically manage findings based on criteria you define.

## Overview

Security Hub automation rules allow you to automatically update findings based on criteria you define. This is useful for:

- Suppressing low-severity findings to reduce noise
- Automatically managing findings from specific resources or accounts
- Implementing consistent workflow processes for security findings

## Usage

Make sure you are in examples/<EXAMPLE_NAME> directory when running this module. Change the source to the correct path if not in examples/<EXAMPLE_NAME> directory.

```hcl
module "automation_rules" {
  source = "../../../modules/automation-rules"

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

## Examples

- [Suppress Low Severity Findings](../../examples/automation-rules/suppress-low-severity/): Example of suppressing low severity findings
- [Resource-Specific Rules](../../examples/automation-rules/Resource-specific/): Example of creating automation rules for specific resource types
- [Account-Specific Rules](../../examples/automation-rules/account-specific/): Example of creating rules that target specific AWS accounts
- [Suppress Development Findings](../../examples/automation-rules/suppress-dev-findings/): Example of suppressing findings from development environments

## Filter Criteria

Automation rules can filter findings based on various criteria:

| Criteria | Description | Example |
|----------|-------------|---------|
| aws_account_ids | Filter by AWS account IDs | `["123456789012"]` |
| severity_labels | Filter by severity labels | `["LOW", "MEDIUM"]` |
| resource_types | Filter by resource types | `["AwsEc2Instance", "AwsS3Bucket"]` |
| generator_ids | Filter by generator IDs | `["aws-foundational-security-best-practices"]` |
| compliance_status | Filter by compliance status | `"FAILED"` |
| record_state | Filter by record state | `"ACTIVE"` |
| product_names | Filter by product names | `["GuardDuty", "Inspector"]` |
| product_arns | Filter by product ARNs | `["arn:aws:securityhub:us-east-1::product/aws/guardduty"]` |
| title | Filter by finding title | `"S3 Bucket"` |
| description_criteria | Filter by finding description | `"publicly accessible"` |
| workflow_status | Filter by workflow status | `"NEW"` |

## Important Notes

- Rules are processed in order based on the rule_order value
- Rules are region-specific and must be deployed in each region where Security Hub is enabled
- When deployed in the delegated administrator account, rules apply to findings from all member accounts
- Rules are processed when new findings are created or existing findings are updated
- More information about the criteria can be found [here](https://docs.aws.amazon.com/securityhub/latest/userguide/automation-rules-criteria.html)

## Extending the Module

This section provides guidance on how to extend the module to support new criteria fields and actions.

### Adding New Criteria Fields

To add a new criteria field to the module:

1. **Update the variables.tf file**:
   Add the new field to the `automation_rules` variable object definition:

   ```hcl
   variable "automation_rules" {
     description = "List of Security Hub automation rules to create for finding suppression and workflow management"
     type = list(object({
       // Existing fields...
       new_criteria_field = optional(string)  # or appropriate type
       // Other fields...
     }))
     default = []
   }
   ```

2. **Update the main.tf file**:
   Add a new dynamic block for the criteria in the `criteria` block:

   ```hcl
   # New criteria field
   dynamic "new_criteria_field" {
     for_each = each.value.new_criteria_field != null ? [each.value.new_criteria_field] : []
     content {
       comparison = "EQUALS"  # or appropriate comparison
       value     = new_criteria_field.value
     }
   }
   ```

   For list types, use:
   ```hcl
   dynamic "new_criteria_field" {
     for_each = length(each.value.new_criteria_fields) > 0 ? each.value.new_criteria_fields : []
     content {
       comparison = "EQUALS"  # or appropriate comparison
       value     = new_criteria_field.value
     }
   }
   ```

3. **Update the README.md**:
   Add the new field to the Filter Criteria table.

### Adding New Action Types

Currently, the module supports the `FINDING_FIELDS_UPDATE` action type. To add support for new action types:

1. **Update the variables.tf file**:
   Modify the validation condition to include the new action type:

   ```hcl
   validation {
     condition = alltrue([
       for rule in var.automation_rules :
       contains(["FINDING_FIELDS_UPDATE", "NEW_ACTION_TYPE"], rule.action_type)
     ])
     error_message = "action_type must be FINDING_FIELDS_UPDATE or NEW_ACTION_TYPE"
   }
   ```

2. **Update the main.tf file**:
   Add conditional logic in the actions block:

   ```hcl
   actions {
     type = each.value.action_type

     dynamic "finding_fields_update" {
       for_each = each.value.action_type == "FINDING_FIELDS_UPDATE" ? [1] : []
       content {
         workflow {
           status = each.value.finding_fields_update.workflow_status
         }
       }
     }

     dynamic "new_action_type" {
       for_each = each.value.action_type == "NEW_ACTION_TYPE" ? [1] : []
       content {
         // New action type configuration
       }
     }
   }
   ```

3. **Update the variables.tf file** to support the new action type's configuration:
   ```hcl
   variable "automation_rules" {
     description = "List of Security Hub automation rules to create for finding suppression and workflow management"
     type = list(object({
       // Existing fields...
       action_type            = string
       finding_fields_update  = optional(object({
         workflow_status = string
       }))
       new_action_config      = optional(object({
         // New action type configuration fields
       }))
     }))
     default = []
   }
   ```

### Extending Finding Fields Update

To add new fields under the existing `finding_fields_update` action:

1. **Update the variables.tf file**:
   Add the new field to the `finding_fields_update` object:

   ```hcl
   finding_fields_update  = object({
     workflow_status = string
     new_field       = optional(string)
     // Other fields...
   })
   ```

2. **Update the main.tf file**:
   Add the new field to the finding_fields_update block:

   ```hcl
   finding_fields_update {
     workflow {
       status = each.value.finding_fields_update.workflow_status
     }

     dynamic "new_field_block" {
       for_each = each.value.finding_fields_update.new_field != null ? [each.value.finding_fields_update.new_field] : []
       content {
         // New field configuration
       }
     }
   }
   ```

### Testing New Extensions

Always test new extensions thoroughly:

1. Create a test example in the examples directory
2. Verify that the Terraform plan shows the expected configuration
3. Apply the changes and verify that the automation rule works as expected
4. Document the new functionality in the README.md

### Reference Documentation

For extending this module, refer to these official resources:

- **AWS Documentation**:
  - [Security Hub Automation Rules Overview](https://docs.aws.amazon.com/securityhub/latest/userguide/automation-rules.html)
  - [Available Action and Criteria Fields](https://docs.aws.amazon.com/securityhub/latest/userguide/automation-rules.html#automation-rules-criteria-actions)

- **Terraform Resources**:
  - [aws_securityhub_automation_rule Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_automation_rule)
  - [Security Hub Resources Overview](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_account)

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
| [aws_securityhub_automation_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_automation_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_automation_rules"></a> [automation\_rules](#input\_automation\_rules) | List of Security Hub automation rules to create for finding suppression and workflow management | <pre>list(object({<br>    rule_name              = string<br>    description            = string<br>    rule_order             = number<br>    aws_account_ids        = optional(list(string), [])<br>    severity_labels        = optional(list(string), [])<br>    resource_types         = optional(list(string), [])<br>    generator_ids          = optional(list(string), [])<br>    compliance_status      = optional(string)<br>    record_state           = optional(string)<br>    product_names          = optional(list(string), [])<br>    product_arns           = optional(list(string), [])<br>    title                  = optional(string)<br>    description_criteria   = optional(string)<br>    workflow_status        = optional(string)<br>    action_type            = string<br>    finding_fields_update  = object({<br>      workflow_status = string<br>    })<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_automation_rules"></a> [automation\_rules](#output\_automation\_rules) | Map of created Security Hub automation rules |
<!-- END_TF_DOCS -->
