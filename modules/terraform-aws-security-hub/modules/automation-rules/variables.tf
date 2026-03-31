variable "automation_rules" {
  description = "List of Security Hub automation rules to create for finding suppression and workflow management"
  type = list(object({
    rule_name            = string
    description          = string
    rule_order           = number
    aws_account_ids      = optional(list(string), [])
    severity_labels      = optional(list(string), [])
    resource_types       = optional(list(string), [])
    generator_ids        = optional(list(string), [])
    compliance_status    = optional(string)
    resource_tags        = optional(map(string))
    record_state         = optional(string)
    product_names        = optional(list(string), [])
    product_arns         = optional(list(string), [])
    title                = optional(string)
    description_criteria = optional(string)
    workflow_status      = optional(string)
    action_type          = string
    finding_fields_update = object({
      workflow_status = string
    })
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.automation_rules :
      contains(["FINDING_FIELDS_UPDATE"], rule.action_type)
    ])
    error_message = "action_type must be FINDING_FIELDS_UPDATE"
  }
}
