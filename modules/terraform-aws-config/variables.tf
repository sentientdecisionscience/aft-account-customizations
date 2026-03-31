# ---------------------------------------------------------------------------------------------
# AWS Config variables
# ---------------------------------------------------------------------------------------------
variable "aggregator" {
  description = "The AWS Config aggregator configuration"
  type = object({
    enabled            = optional(bool, false)
    aggregation_mode   = optional(string, null)
    member_account_ids = optional(list(string), [])
    all_regions        = optional(bool, false)
    scope_regions      = optional(any, null)
  })
  default = {}

  validation {
    condition     = var.aggregator.enabled == true && contains(["ORGANIZATION", "SPECIFIC_ACCOUNTS"], var.aggregator.aggregation_mode)
    error_message = "aggregation_mode must be either ORGANIZATION or SPECIFIC_ACCOUNTS"
  }

  validation {
    condition     = var.aggregator.enabled == false || var.aggregator.aggregation_mode != null
    error_message = "aggregation_mode must be specified when aggregator is enabled"
  }

  validation {
    condition     = var.aggregator.aggregation_mode == "SPECIFIC_ACCOUNTS" ? length(var.aggregator.member_account_ids) > 0 : true
    error_message = "member_account_ids must be specified when aggregation_mode is SPECIFIC_ACCOUNTS"
  }

  validation {
    condition     = var.aggregator.all_regions == true ? var.aggregator.scope_regions == null : var.aggregator.scope_regions != null #var.aggregator.all_regions == true && (var.aggregator.all_regions == false && var.aggregator.scope_regions != null)
    error_message = "Either `all_regions` or `scope_regions` must be specified. If `all_regions` is set to false, `scope_regions` must contain at least one region. If `all_regions` is set to true, `scope_regions` must be empty"
  }
}

variable "additional_policy_arns" {
  description = "A list of ARNs of IAM policies to attach to the AWS Config IAM role"
  type        = list(string)
  default     = []
}

variable "enable_recorder" {
  description = "Whether the configuration recorder should be enabled"
  type        = bool
  default     = true
}

variable "delivery_bucket_name" {
  description = "The name of the S3 bucket used to store the configuration history."
  type        = string
  default     = null
}

variable "create_delivery_bucket" {
  description = "Whether to create the S3 bucket used to store the configuration history."
  type        = bool
  default     = false
}

variable "delivery_bucket_prefix" {
  description = "The prefix to use for the specified S3 bucket"
  type        = string
  default     = "awsconfig-history"
}

variable "delivery_bucket_kms_key_arn" {
  description = "The ARN of the KMS key to used to encrypt the objects of the s3 bucket"
  type        = string
  default     = null
}

variable "delivery_sns_topic_arn" {
  description = "The ARN of the SNS topic that AWS Config delivers notifications to."
  type        = string
  default     = null
}

variable "delivery_frequency" {
  description = "The frequency with which AWS Config delivers configuration snapshots. Valid values are `One_Hour`, `Three_Hours`, `Six_Hours`, `Twelve_Hours`, or `TwentyFour_Hours`."
  type        = string
  default     = null

  validation {
    condition     = contains(["One_Hour", "Three_Hours", "Six_Hours", "Twelve_Hours", "TwentyFour_Hours"], var.delivery_frequency)
    error_message = "delivery_frequency must be one of `One_Hour`, `Three_Hours`, `Six_Hours`, `Twelve_Hours`, or `TwentyFour_Hours`"
  }
}

variable "recording_group" {
  description = "The configuration recorder's recording group"
  type = object({
    resource_types                = optional(list(string), [])
    excluded_resource_types       = optional(list(string), [])
    include_global_resource_types = optional(bool, true)
    recording_strategy            = optional(string, null)
  })
  default = {
    resource_types                = []
    excluded_resource_types       = []
    include_global_resource_types = true
  }
  validation {
    condition     = !(length(var.recording_group.resource_types) > 0 && length(var.recording_group.excluded_resource_types) > 0)
    error_message = "You can only define one or nothing of `resource_types` or `excluded_resource_types`"
  }
}

variable "recording_mode" {
  description = "The configuration recorder's recording mode"
  type = object({
    recording_frequency = optional(string)
    recording_mode_override = optional(list(object({
      description         = string
      resource_types      = list(string)
      recording_frequency = string
    })))
  })
  default = {
    recording_frequency     = null
    recording_mode_override = []
  }

  validation {
    condition     = var.recording_mode.recording_frequency == null || contains(["CONTINUOUS", "DAILY"], var.recording_mode.recording_frequency)
    error_message = "recording_frequency must be either CONTINUOUS or DAILY"
  }

  validation {
    condition     = length(var.recording_mode.recording_mode_override) > 0 ? alltrue([for override in var.recording_mode.recording_mode_override : contains(["CONTINUOUS", "DAILY"], override.recording_frequency) ? true : false]) : true
    error_message = "recording_mode_override must be either CONTINUOUS or DAILY"
  }
}
