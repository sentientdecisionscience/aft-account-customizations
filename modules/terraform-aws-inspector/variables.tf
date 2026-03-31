variable "disable_inspector_members" {
  description = "Set to true before removing the module to properly disassociate member accounts"
  type        = bool
  default     = false
}

variable "enable_organization_configuration" {
  description = "If you want to manage Inspector across accounts in an AWS Organization"
  type        = bool
  default     = true
}

variable "auto_enable" {
  description = "(Optional) Enable Inspector for accounts that newly join the AWS Organization."
  type        = bool
  default     = true
}

variable "resource_scan_types" {
  description = "(Required) Type of resources to scan. Valid values are EC2, ECR, LAMBDA, and LAMBDA_CODE. At least one item is required."
  type        = list(string)
  default     = []

  validation {
    condition     = !contains(var.resource_scan_types, "LAMBDA_CODE") || contains(var.resource_scan_types, "LAMBDA")
    error_message = "LAMBDA_CODE scanning requires LAMBDA scanning to be enabled. Please add LAMBDA to resource_scan_types."
  }
}

variable "excluded_accounts" {
  description = "List of account IDs to exclude from Inspector."
  type        = list(string)
  default     = []
}
