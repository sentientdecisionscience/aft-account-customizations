# Suppress Low Severity Findings

This example demonstrates how to create an automation rule that automatically suppresses all low severity findings in Security Hub.

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Explanation

This example creates a single automation rule that:

1. Targets all findings with a severity label of "LOW"
2. Automatically changes their workflow status to "SUPPRESSED"
3. Applies to all new and updated findings that match the criteria

This helps reduce noise in Security Hub by automatically suppressing low-risk findings that may not require immediate attention.
