output "aiservices_opt_out_policies" {
  description = "See the AISERVICES_OPT_OUT_POLICIES with the aggregated policy statements"
  value       = { for aiservices_opt_out_policy, config in var.aiservices_opt_out_policies : aiservices_opt_out_policy => jsondecode(aws_organizations_policy.aiservices_opt_out_policies[aiservices_opt_out_policy].content) }
}

output "backup_policies" {
  description = "See the BACKUP_POLICIES with the aggregated policy statements"
  value       = { for backup_policy, config in var.backup_policies : backup_policy => jsondecode(aws_organizations_policy.backup_policies[backup_policy].content) }
}

output "rcps" {
  description = "See the RCPs with the aggregated policy statements"
  value       = { for rcp, config in var.resource_control_policies : rcp => jsondecode(aws_organizations_policy.rcp[rcp].content) }
}

output "scps" {
  description = "See the SCPs with the aggregated policy statements"
  value       = { for scp, config in var.service_control_policies : scp => jsondecode(aws_organizations_policy.scp[scp].content) }
}

output "tag_policies" {
  description = "See the TAG_POLICYs with the aggregated policy statements"
  value       = { for tag_policy, config in var.tag_policies : tag_policy => jsondecode(aws_organizations_policy.tag_policies[tag_policy].content) }
}
