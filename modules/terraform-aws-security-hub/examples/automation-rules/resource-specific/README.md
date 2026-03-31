# Resource-Specific Automation Rules

This example demonstrates how to create automation rules that target specific resource types.

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Explanation

This example creates two automation rules:

1. **suppress-low-priority-findings**: Suppresses all LOW and INFORMATIONAL severity findings regardless of resource type
2. **suppress-non-iam-medium-findings**: Suppresses MEDIUM severity findings only for specific resource types (EC2 instances, S3 buckets, RDS instances)
