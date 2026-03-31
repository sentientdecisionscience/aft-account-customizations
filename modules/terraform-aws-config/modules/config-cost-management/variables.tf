variable "account_ids" {
  description = "List of AWS account IDs to update the AWS Config ResourceCompliance resource type"
  type        = list(string)

  validation {
    condition     = alltrue([for id in var.account_ids : can(regex("^\\d{12}$", id))])
    error_message = "All AWS account IDs must be exactly 12 digits long."
  }
}

variable "target_iam_role_name" {
  description = "IAM role to assume in target accounts. This role must be available for the lambda function to assume in each target account."
  type        = string
}

variable "lambda_function_mode" {
  description = "Define the mode for the lambda function to execute in: enable or disable"
  type        = string

  validation {
    condition     = contains(["enable", "disable"], var.lambda_function_mode)
    error_message = "The lambda_function_mode value must be either 'enable' or 'disable'."
  }
}
