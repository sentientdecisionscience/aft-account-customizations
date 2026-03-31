variable "conformance_packs" {
  description = "The AWS Config conformance packs to enable"
  type = list(object({
    name                 = string
    include_mgmt_account = optional(bool, false)
    deployment_mode      = optional(string, "LOCAL")
    excluded_accounts    = optional(list(string), [])
    template             = optional(string, null)
    template_s3_uri      = optional(string, null)
    template_url         = optional(string, null)
    input_parameters     = optional(map(string), {})
  }))
  default = []
  validation {
    condition     = alltrue([for pack in var.conformance_packs : contains(["LOCAL", "ORGANIZATION"], pack.deployment_mode)])
    error_message = "deployment_mode must be either LOCAL or ORGANIZATION"
  }
}

variable "delivery_bucket_name" {
  description = "The name of the S3 bucket used to store the configuration history."
  type        = string
  default     = null
}

variable "config_rules" {
  description = "The AWS Config rules to enable"
  type = list(object({
    name                        = string
    description                 = optional(string)
    evaluation_mode             = optional(string)
    deployment_mode             = optional(string, "LOCAL")
    include_mgmt_account        = optional(bool, false)
    excluded_accounts           = optional(list(string), [])
    maximum_execution_frequency = optional(string)
    scope = optional(object({
      compliance_resource_id    = optional(string)
      compliance_resource_types = optional(list(string), [])
      tag_key                   = optional(string, null)
      tag_value                 = optional(string, null)
    }), {})
    source = optional(object({
      owner             = optional(string)
      source_identifier = optional(string)
      source_detail = optional(object({
        event_source                = optional(string, null)
        message_type                = optional(string, null)
        maximum_execution_frequency = optional(string, null)
      }), null)
      custom_policy_details = optional(object({
        policy_text               = optional(string, null)
        policy_runtime            = optional(string, null)
        enable_debug_log_delivery = optional(map(string), {})
      }), null)
    }))
  }))
  default = []
  validation {
    condition     = alltrue([for rule in var.config_rules : contains(["LOCAL", "ORGANIZATION"], rule.deployment_mode)])
    error_message = "deployment_mode must be either LOCAL or ORGANIZATION"
  }
}
