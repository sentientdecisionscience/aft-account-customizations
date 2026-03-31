variable "aiservices_opt_out_policies" {
  type = map(object({
    policies          = optional(list(string), []) # Standard JSON policies without variables
    template_policies = optional(list(string), []) # Templated policies that need variables injected
    template_vars     = optional(map(string), {})  # Takes precedence over var.template_vars
    target            = list(string)
    name              = string
    description       = string
  }))
  description = "Map of AISERVICES_OPT_OUT_POLICY with associated policies, template variables, targets, name and descriptions"
  default     = {}
}

variable "backup_policies" {
  type = map(object({
    policies          = optional(list(string), []) # Standard JSON policies without variables
    template_policies = optional(list(string), []) # Templated policies that need variables injected
    template_vars     = optional(map(string), {})  # Takes precedence over var.template_vars
    target            = list(string)
    name              = string
    description       = string
  }))
  description = "Map of BACKUP_POLICY with associated policies, template variables, targets, name and descriptions"
  default     = {}
}

variable "resource_control_policies" {
  type = map(object({
    policies          = optional(list(string), []) # Standard JSON policies without variables
    template_policies = optional(list(string), []) # Templated policies that need variables injected
    template_vars     = optional(map(string), {})  # Takes precedence over var.template_vars
    target            = list(string)
    name              = string
    description       = string
  }))
  description = "Map of RESOURCE_CONTROL_POLICY with associated policies, template variables, targets, name and descriptions"
  default     = {}
}

variable "service_control_policies" {
  type = map(object({
    policies          = optional(list(string), []) # Standard JSON policies without variables
    template_policies = optional(list(string), []) # Templated policies that need variables injected
    template_vars     = optional(map(string), {})  # Takes precedence over var.template_vars
    target            = list(string)
    name              = string
    description       = string
  }))
  description = "Map of SERVICE_CONTROL_POLICY with associated policies, template variables, targets, name and descriptions"
  default     = {}
}

variable "tag_policies" {
  type = map(object({
    policies          = optional(list(string), []) # Standard JSON policies without variables
    template_policies = optional(list(string), []) # Templated policies that need variables injected
    template_vars     = optional(map(string), {})  # Takes precedence over var.template_vars
    target            = list(string)
    name              = string
    description       = string
  }))
  description = "Map of TAG_POLICY with associated policies, template variables, targets, name and descriptions"
  default     = {}
}

variable "template_vars" {
  type        = map(string)
  description = <<-EOF
    Variables that will be replaced in all templated policies.
    Can be overridden by `template_vars` in the policy configuration maps
  EOF
  default     = {}
}

variable "json_policies_folders" {
  type = object({
    aiservices_opt_out_policy = optional(string, "./organization_policies/ai_policies/json_policies")
    backup_policy             = optional(string, "./organization_policies/backup_policies/json_policies")
    resource_control_policy   = optional(string, "./organization_policies/resource_control_policies/json_policies")
    service_control_policy    = optional(string, "./organization_policies/service_control_policies/json_policies")
    tag_policy                = optional(string, "./organization_policies/tag_policies/json_policies")
  })
  description = "Relative path to the folder containing JSON policies"
  default     = {}
}

variable "template_policies_folders" {
  type = object({
    aiservices_opt_out_policy = optional(string, "./organization_policies/ai_policies/template_policies")
    backup_policy             = optional(string, "./organization_policies/backup_policies/template_policies")
    resource_control_policy   = optional(string, "./organization_policies/resource_control_policies/template_policies")
    service_control_policy    = optional(string, "./organization_policies/service_control_policies/template_policies")
    tag_policy                = optional(string, "./organization_policies/tag_policies/template_policies")
  })
  description = "Relative path to the folder containing JSON template policies"
  default     = {}
}

variable "json_file_suffix" {
  type = object({
    aiservices_opt_out_policy = optional(string, ".json")
    backup_policy             = optional(string, ".json")
    resource_control_policy   = optional(string, ".json")
    service_control_policy    = optional(string, ".json")
    tag_policy                = optional(string, ".json")
  })
  description = "Suffix to append to the JSON policy file names"
  default     = {}
}

variable "template_file_suffix" {
  type = object({
    aiservices_opt_out_policy = optional(string, ".json.tpl")
    backup_policy             = optional(string, ".json.tpl")
    resource_control_policy   = optional(string, ".json.tpl")
    service_control_policy    = optional(string, ".json.tpl")
    tag_policy                = optional(string, ".json.tpl")
  })
  description = "Suffix to append to the template policy file names"
  default     = {}
}
