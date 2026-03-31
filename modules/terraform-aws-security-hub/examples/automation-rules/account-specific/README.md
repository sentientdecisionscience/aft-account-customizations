# Account-Specific Automation Rules

This example demonstrates how to create automation rules that target findings from specific AWS accounts.

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Explanation

This example creates two automation rules:

1. **suppress-findings-from-sandbox-account**: Suppresses all findings from a specific sandbox account
2. **suppress-specific-product-findings**: Suppresses findings from specific security products (GuardDuty, Inspector) with LOW severity

This approach is useful for organizations that want to apply different automation rules to different accounts based on their environment type or security requirements.
