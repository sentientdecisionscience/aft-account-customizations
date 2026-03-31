variable "member_account_ids" {
  type        = list(string)
  description = "The list of account IDs of the AWS accounts to be added as a member account."
  default     = []
}

variable "enabled_standard_arns" {
  type        = list(string)
  description = "The list of enabled standard ARNs for individually managed deployments."
  default     = []
}

variable "finding_aggregator" {
  type = object({
    linking_mode      = optional(string, "SPECIFIED_REGIONS")
    specified_regions = optional(list(string), null)
  })
  description = "The finding aggregator configuration to be applied to the Security Hub. The default linking_mode is SPECIFIED_REGIONS."
  default     = null

  validation {
    condition = var.finding_aggregator.linking_mode == "ALL_REGIONS" ? var.finding_aggregator.specified_regions == null : (
      var.finding_aggregator.linking_mode == "ALL_REGIONS_EXCEPT_SPECIFIED" ||
      var.finding_aggregator.linking_mode == "SPECIFIED_REGIONS"
    ) && var.finding_aggregator.specified_regions != null
    error_message = "ERROR: specified_regions must be empty when linking_mode is set to ALL_REGIONS, and it must not be empty if linking_mode is set to SPECIFIED_REGIONS or ALL_REGIONS_EXCEPT_SPECIFIED."
  }
}

variable "organization_configuration" {
  type = object({
    auto_enable           = optional(bool, false)
    auto_enable_standards = optional(string, "NONE")
    configuration_type    = string
  })
  description = "The Security Hub organization configuration."
  default = {
    auto_enable           = false
    auto_enable_standards = "NONE"
    configuration_type    = "LOCAL"
  }

  validation {
    condition     = contains(["NONE", "DEFAULT"], var.organization_configuration.auto_enable_standards)
    error_message = "ERROR: Invalid values for `auto_enable_standards`. Value must be either `NONE` or `DEFAULT`"
  }

  validation {
    condition     = contains(["LOCAL", "CENTRAL"], var.organization_configuration.configuration_type)
    error_message = "ERROR: Invalid values for `organization_configuration_type`. Value must be either `LOCAL` or `CENTRAL`"
  }
}

variable "configuration_policy" {
  type = list(object({
    target_id             = optional(string)
    service_enabled       = optional(bool, false)
    enabled_standard_arns = optional(list(string), [])
    security_controls_configuration = optional(object({
      disabled_control_identifiers = optional(list(string), null)
      enabled_control_identifiers  = optional(list(string), null)
      security_control_custom_parameters = optional(list(object({
        parameter = list(object({
          name        = string
          value_type  = string
          bool        = optional(bool, null)
          double      = optional(number, null)
          enum        = optional(string, null)
          enum_list   = optional(list(string), null)
          int         = optional(number, null)
          int_list    = optional(list(number), null)
          string      = optional(string, null)
          string_list = optional(list(string), null)
        }))
        security_control_id = string
      })))
    }), {})
  }))
  description = "The Security Hub configuration policy to be applied to each target account."
  default     = []

  validation {
    condition     = length([for policy in var.configuration_policy : policy if policy.target_id == null]) <= 1
    error_message = "ERROR: Only one default policy can be defined. Configuration policies without target are marked as default, which is applied to all members."
  }
  validation {
    condition     = length([for policy in var.configuration_policy : policy.target_id if policy.target_id != null]) == length(distinct([for policy in var.configuration_policy : policy.target_id if policy.target_id != null]))
    error_message = "ERROR: Only one policy can be applied to the same `target_id`."
  }
}
