variable "sandbox_account_id" {
  description = "AWS Account ID of the sandbox environment"
  type        = string
  default     = "123456789012" # Replace with actual account ID
}

variable "severity_levels" {
  description = "Severity levels to suppress for specific products"
  type        = list(string)
  default     = ["LOW"]
}

variable "product_names" {
  description = "Security product names to suppress findings from"
  type        = list(string)
  default     = ["GuardDuty", "Inspector"]
}
