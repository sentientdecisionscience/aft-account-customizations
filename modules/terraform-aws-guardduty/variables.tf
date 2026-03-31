variable "disable_guardduty_members" {
  description = "Flag to disable GuardDuty and remove all member accounts"
  type        = bool
  default     = false
}

variable "enable_organization_configuration" {
  description = "Determines whether organization-wide features are enabled for AWS GuardDuty."
  type        = bool
  default     = true
}

variable "guardduty_auto_enable_organization_members" {
  description = "Controls whether new AWS organization accounts are automatically added as GuardDuty member accounts under the delegated administrator in the specified AWS region. Valid values: ALL, NEW, NONE."
  type        = string
  default     = "NONE"
}

variable "enable_guardduty_findings_export_to_s3" {
  description = "Determines whether GuardDuty will export its findings."
  type        = bool
  default     = false
}

variable "findings_export_s3_bucket_arn" {
  description = "ARN and prefix (optional) of the S3 bucket under which GuardDuty will export its findings to. Bucket ARN is required, the prefix is optional and will be s3://BucketName/AWSLogs/[Account-ID]/GuardDuty/[Region]/ if not provided."
  type        = string
  default     = null
}

variable "findings_export_kms_key_arn" {
  description = "ARN of the KMS key GuardDuty will use when exporting its findings."
  type        = string
  default     = null
}

variable "guardduty_admin_account_features" {
  description = <<EOF
    Defines which GuardDuty features are enabled in the delegated administrator account.
    For RUNTIME_MONITORING feature, additional_configuration must be specified in exact order:
    - EKS_ADDON_MANAGEMENT
    - ECS_FARGATE_AGENT_MANAGEMENT
    - EC2_AGENT_MANAGEMENT
EOF
  type = map(object({
    enabled = bool
    additional_configuration = optional(list(object({
      name   = string
      status = string
    })))
  }))

  default = {
    S3_DATA_EVENTS         = { enabled = false }
    EKS_AUDIT_LOGS         = { enabled = false }
    EBS_MALWARE_PROTECTION = { enabled = false }
    RDS_LOGIN_EVENTS       = { enabled = false }
    LAMBDA_NETWORK_LOGS    = { enabled = false }
    RUNTIME_MONITORING = {
      enabled = false
      additional_configuration = [
        {
          name   = "EKS_ADDON_MANAGEMENT"
          status = "DISABLED"
        },
        {
          name   = "ECS_FARGATE_AGENT_MANAGEMENT"
          status = "DISABLED"
        },
        {
          name   = "EC2_AGENT_MANAGEMENT"
          status = "DISABLED"
        }
      ]
    }
  }
}

variable "guardduty_organization_features" {
  description = <<EOF
    Defines which GuardDuty features are enabled with individual auto-enable configurations.

    Each feature includes:
    - `enabled` (bool): Specifies if the GuardDuty feature should be enabled.
    - `auto_enable_feature_configuration` (string): Determines whether the GuardDuty feature is enabled for new organization members.
      Allowed values: "ALL", "NEW", "NONE".
    - `additional_configuration` (list of objects, optional): Additional settings for the feature.
      - `name` (string): Name of the additional configuration. Allowed values: "EC2_AGENT_MANAGEMENT", "ECS_FARGATE_AGENT_MANAGEMENT", "EKS_ADDON_MANAGEMENT".
      - `auto_enable` (string, optional): By default, inherits the value from auto_enable_feature_configuration. Set to "NONE" to explicitly disable.

    Note for RUNTIME_MONITORING feature:
    1. The additional_configuration items must be specified in this exact order:
       - ECS_FARGATE_AGENT_MANAGEMENT
       - EC2_AGENT_MANAGEMENT
       - EKS_ADDON_MANAGEMENT
    2. Each configuration will inherit its auto_enable value from auto_enable_feature_configuration unless explicitly set to "NONE"
EOF

  type = map(object({
    enabled                           = bool
    auto_enable_feature_configuration = string
    additional_configuration = optional(list(object({
      name        = string
      auto_enable = optional(string) # Will inherit from auto_enable_feature_configuration if not specified
    })))
  }))

  default = {
    S3_DATA_EVENTS         = { enabled = false, auto_enable_feature_configuration = "NONE" }
    EKS_AUDIT_LOGS         = { enabled = false, auto_enable_feature_configuration = "NONE" }
    EBS_MALWARE_PROTECTION = { enabled = false, auto_enable_feature_configuration = "NONE" }
    RDS_LOGIN_EVENTS       = { enabled = false, auto_enable_feature_configuration = "NONE" }
    LAMBDA_NETWORK_LOGS    = { enabled = false, auto_enable_feature_configuration = "NONE" }
    RUNTIME_MONITORING = {
      enabled                           = false
      auto_enable_feature_configuration = "NONE"
      additional_configuration = [
        {
          name   = "EKS_ADDON_MANAGEMENT"
          status = "NONE"
        },
        {
          name   = "ECS_FARGATE_AGENT_MANAGEMENT"
          status = "NONE"
        },
        {
          name   = "EC2_AGENT_MANAGEMENT"
          status = "NONE"
        }
      ]
    }
  }
}

variable "filter_config" {
  description = <<EOF
Defines AWS GuardDuty filter configurations. Each filter contains:
  - `name` (string): The name of the filter.
  - `description` (optional, string): Description of the filter.
  - `rank` (number): The priority rank of the filter, determining the order in which it is applied.
  - `action` (string): The action to apply to matched findings. Valid values: ARCHIVE or NOOP.
  - `criterion` (list of objects): Defines the filtering criteria with:
      - `field` (string): The field to filter on.
      - `equals`, `not_equals` (optional, list of strings): Exact match conditions.
      - `greater_than`, `greater_than_or_equal`, `less_than`, `less_than_or_equal` (optional, number): Numeric comparison conditions.
EOF

  type = list(object({
    name        = string
    description = optional(string)
    rank        = number
    action      = string
    criterion = list(object({
      field                 = string
      equals                = optional(list(string))
      not_equals            = optional(list(string))
      greater_than          = optional(number)
      greater_than_or_equal = optional(number)
      less_than             = optional(number)
      less_than_or_equal    = optional(number)
    }))
  }))

  default = []
}


# Configuration for GuardDuty ThreatIntelSet.
variable "threatintelset_config" {
  description = <<EOF
Defines AWS GuardDuty ThreatIntelSet configuration. Each ThreatIntelSet contains:
  - `activate` (bool): Specifies if GuardDuty should start using the uploaded ThreatIntelSet.
  - `name` (string): The friendly name to identify the ThreatIntelSet.
  - `format` (string): Format of the file. Valid values: TXT, STIX, OTX_CSV, ALIEN_VAULT, PROOF_POINT, FIRE_EYE.
  - `bucket_id` (string): ID of S3 Bucket containing the ThreatIntelSet.
  - `file_path` (string): Path to the file containing the ThreatIntelSet content.
  - `key` (string): Name of the object stored in the S3 bucket.
  - `object_acl` (string): Canned ACL to apply. Valid values: private, public-read, public-read-write, aws-exec-read, authenticated-read, bucket-owner-read, bucket-owner-full-control.
EOF
  type = list(object({
    activate   = bool
    name       = string
    format     = string
    bucket_id  = string
    file_path  = string
    key        = string
    object_acl = string
  }))
  default = []
}

# Configuration for GuardDuty IPSet.
variable "ipset_config" {
  description = <<EOF
Defines AWS GuardDuty IPSet configuration. Each IPSet contains:
  - `activate` (bool): Specifies if GuardDuty should start using the uploaded IPSet.
  - `name` (string): The friendly name to identify the IPSet.
  - `format` (string): Format of the IPSet file. Valid values: TXT, STIX, OTX_CSV, ALIEN_VAULT, PROOF_POINT, FIRE_EYE.
  - `bucket_id` (string): ID of S3 Bucket containing the IPSet.
  - `file_path` (string): Path to the file containing the IPSet content.
  - `key` (string): Name of the object stored in the S3 bucket.
EOF
  type = list(object({
    activate  = bool
    name      = string
    format    = string
    bucket_id = string
    file_path = string
    key       = string
  }))
  default = []
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "finding_publishing_frequency" {
  description = "Specifies how often GuardDuty findings are published. Allowed values: FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS."
  type        = string
  default     = "SIX_HOURS"

  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.finding_publishing_frequency)
    error_message = "Invalid value. Allowed values are: FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS."
  }
}
